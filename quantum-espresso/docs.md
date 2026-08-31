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

Atoms are divided between PP ranks for short range bond calculations and PME ranks for long range calculations which uses a distributed grid and FFTs.

### Parameters to tune
- **MPI ranks**: More ranks = more spatial domains: parallelises more work but requires more communication between those domains.
- **OpenMP threads**: More threads = more work is shared within each MPI rank: reduces MPI communication but creates fewer spatial domains.
- `-npme`: Sets the number of MPI ranks which are used for PME (speed up FFT work).
- `-dlb`: Dynamic load balancing: changes the domain size at runtime to balance uneven work between PP ranks.
- `-dd`: Changes the domain size. smaller, more domains = less calculation per rank, more parallelism, but more communication at the boundaries. larger, fewer domains = more calculation per rank, less MPI communication, but less parallelism. `-dd` is usually automatically set by how you tune `-dlb`.
- **Step count**: Increase step count to measure more stable performance (I only did 10000 steps, so I recommend trying this).

### Best Result

**299.737 ns/day** with:
- 144 MPI ranks per node
- 1 OpenMP thread per rank
- 72 (automatically selected) PME ranks/216 PP ranks
- 6x6x6 domain-decomposition grid
