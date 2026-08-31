# Quantum ESPRESSO

GRIR443 runs one SCF iteration of a 443 atom system using `pw.x`.

**Goal**: run GRIR443 as fast as possible using up to two nodes

**Metric**: final PWSCF WALL time (lower is better)

**Requirement**: run finishes with 'JOB DONE' and total energy is consistent

## Build

**Dependencies:**
- GCC: For C/Fortran compilation
- Cray MPICH: For MPI
- Cray LibSCI: For BLAS, LAPACK, ScaLAPACK
- Cray FFTW: For FFTW
- FoX, MBD, devxlib: QE source dependencies

**Source**: https://github.com/QEF/q-e.git

Build pw.x:
```
module load PrgEnv-gnu cray-fftw

git clone --branch qe-7.6 https://github.com/QEF/q-e.git
git -C q-e submodule update --init external/fox external/mbd external/devxlib

mkdir build && cd build
../q-e/configure MPIF90=ftn CC=cc F77=ftn F90=ftn --enable-openmp
make -j8 pw
```

Get benchmark data:
```
git clone https://github.com/QEF/benchmarks.git

mkdir run-baseline

cp benchmarks/GRIR443/grir443.in benchmarks/GRIR443/C.pbe-paw_kj-x.UPF benchmarks/GRIR443/Ir.pbe-paw_kj.UPF run-baseline
```

## Run Baseline

**Results**: 717.67 s, −179017.84902409 Ry

This baseline uses two nodes, 36 MPI ranks per node, 4 OpenMP threads per rank, 1 k-point pool.

Create `run-baseline/run.sh`:
```
#!/bin/bash
#SBATCH --job-name=qe-baseline
#SBATCH --partition=grace
#SBATCH --nodes=2
#SBATCH --ntasks-per-node=36
#SBATCH --cpus-per-task=4
#SBATCH --exclusive
#SBATCH --time=00:15:00
#SBATCH --output=qe-baseline-%j.out

module reset
module load PrgEnv-gnu cray-fftw

export OMP_NUM_THREADS="$SLURM_CPUS_PER_TASK"
export OMP_PLACES=cores
export OMP_PROC_BIND=close

srun --cpu-bind=cores ../build/bin/pw.x -nk 1 -in grir443.in
```

## Optimisations

Performance is mostly dependent on how k-points, FFT grids, and diagonalisation gets distributed across MPI ranks and OpenMP threads.

### Parameters to tune
- MPI ranks: More ranks = more FFT work and plane-wave work parallelised, but requires more communication and duplicated process memory
- OpenMP threads: More threads = more work is shared within each MPI rank: reduces MPI communication but only the threaded parts of QE actually benefit
- `-nk N`: Splits k-points between N pools, which are groups within MPI ranks. Pools process different k-points concurrently with little communication between them. Can increase memory usage.
- `diago_david_ndim`: Sets the Davidson diagonalisation workspace size. Larger values may reduce iterations but require more memory.
- `-ntg`: Divides ranks into FFT task groups.
- `nd`: Distributes diagonalisation matrices across a square grid of MPI ranks.

### Best result

614.01 s with:

- 48 MPI ranks per node (96 total)
- 3 OpenMP threads per rank
- 2 k-point pools (48 ranks per pool)
- Default Davidson workspace

### Configurations tested

- 36 MPI ranks per node (72 total), 4 threads, 1 pool: 717.67 s
- 48 MPI ranks per node (96 total), 3 threads, 2 pools: 614.01 s
- 48 MPI ranks per node (96 total), 3 threads, 4 pools: out of memory
- 64 MPI ranks per node (128 total), 2 threads, 4 pools: out of memory
- 48 MPI ranks per node (96 total), 3 threads, 2 pools, `diago_david_ndim=4`: out of memory

Be wary of OOMs!

