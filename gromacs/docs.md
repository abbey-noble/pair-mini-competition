# GROMACS

BenchMEM simulates an 82000 atom membrane protein surrounded by water using `gmx_mpi mdrun`.

**Goal**: maximise performance in ns/day for the benchMEM benchmark using two nodes

**Metric**: `Performance:` simulated ns/day (higher is better)

**Requirement**: all 10,000 steps complete

## Build

**Dependencies:**
- GCC: For C/C++ compilation
- Cray MPICH: For MPI
- Cray FFTW: For FFTs
- CMake: For build configuration

**Source**: https://gitlab.com/gromacs/gromacs.git

Build gmx_mpi:
```
module load PrgEnv-gnu cray-fftw

git clone https://gitlab.com/gromacs/gromacs.git

cd gromacs

cmake -S . -B build -DCMAKE_BUILD_TYPE=Release -DCMAKE_C_COMPILER=cc -DCMAKE_CXX_COMPILER=CC -DCMAKE_C_FLAGS="-mcpu=neoverse-v2"  -DCMAKE_CXX_FLAGS="-mcpu=neoverse-v2" -DGMX_MPI=ON -DGMX_OPENMP=ON -DGMX_SIMD=ARM_NEON_ASIMD -DGMX_FFT_LIBRARY=fftw3
cmake --build build -j8
```

Get benchMEM:
```
mkdir benchmark run-baseline

wget https://www.mpinat.mpg.de/benchMEM -O benchmark/benchMEM.zip
unzip benchmark/benchMEM.zip -d benchmark
```

## Run Baseline

**Results**: 268.229 ns/day, 6.443 s, 0.644 ms/step

This baseline uses two nodes, 72 MPI ranks per node, 2 OpenMP threads per rank, 36 auto-selected PME ranks.

Create `run-baseline/run.sh`:
```
#!/bin/bash
#SBATCH --job-name=gmx-baseline
#SBATCH --partition=grace
#SBATCH --nodes=2
#SBATCH --ntasks-per-node=72
#SBATCH --cpus-per-task=2
#SBATCH --exclusive
#SBATCH --time=00:10:00
#SBATCH --output=baseline-72x2-%j.out

module reset
module load PrgEnv-gnu cray-fftw

export OMP_NUM_THREADS="$SLURM_CPUS_PER_TASK"
export OMP_PLACES=cores
export OMP_PROC_BIND=close

srun --cpu-bind=cores ../build/bin/gmx_mpi mdrun -s ../benchmark/benchMEM.tpr -ntomp "$OMP_NUM_THREADS"
```

## Optimisations

Will publish once jobs exit queue!
