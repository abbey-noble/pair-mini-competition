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

Will publish once jobs exit queue!
