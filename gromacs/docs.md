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
Atoms are divided between PP ranks for short range bond calculations and PME ranks for long range calculations which uses a distributed grid and FFTs.

### Parameters to tune
- **MPI ranks**: More ranks = more spatial domains: parallelises more work but requires more communication between those domains.
- **OpenMP threads**: More threads = more work is shared within each MPI rank: reduces MPI communication but creates fewer spatial domains.
- `-npme`: Sets the number of MPI ranks which are used for PME (speed up FFT work).
- `-dlb`: Dynamic load balancing: changes the domain size at runtime to balance uneven work between PP ranks.
- `-dd`: Changes the domain size. smaller, more domains = less calculation per rank, more parallelism, but more communication at the boundaries. larger, fewer domains = more calculation per rank, less MPI communication, but less parallelism. -dd is usually automatically set by how you tune -dlb.
- **Step count**: Increase step count to measure more stable performance (I only did 10000 steps, so I recommend trying this).

### Best Result

299.737 ns/day with:

- 144 MPI ranks per node (288 total)
- 1 OpenMP thread per rank
- 72 automatically selected PME ranks, 216 PP ranks
- 6x6x6 domain-decomposition grid

### Configurations tested

- 18 MPI ranks per node (36 total), 8 threads, 9–16 PME ranks total: 220.141 ns/day
- 24 MPI ranks per node (48 total), 6 threads, 12–18 PME ranks total: 247.533 ns/day
- 36 MPI ranks per node (72 total), 4 threads, 18–30 PME ranks total: 263.340 ns/day
- 48 MPI ranks per node (96 total), 3 threads, 24–36 PME ranks total: 274.245 ns/day
- 72 MPI ranks per node (144 total), 2 threads, 36–54 PME ranks total: 286.885 ns/day
- 144 MPI ranks per node (288 total), 1 thread, 72 automatically selected PME ranks total: 299.737 ns/day
