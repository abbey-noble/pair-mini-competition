# miniBUDE

miniBUDE is the mini-app version of the Bristol University Docking Engine.

**Goal**: highest throughput on a single node

**Metric**: iterations/hour (higher is better)
avg_ms is the time for one iteration, in milliseconds. Two steps:
Convert to seconds: divide by 1000
Divide 3600 seconds (one hour) by that

## Build

**Dependencies:**
- GCC 14 (`gcc-native/14`): C++ compilation
- Cray compiler wrappers (`CC`)
- `craype-arm-grace`: Grace target module
- CMake

**Source**: https://github.com/UoB-HPC/miniBUDE.git

Build omp-bude:
```
module load PrgEnv-gnu gcc-native/14 craype-arm-grace

git clone https://github.com/UoB-HPC/miniBUDE.git
cd miniBUDE

cmake -Bbuild -H. -DMODEL=omp -DCMAKE_CXX_COMPILER=CC -DCXX_EXTRA_FLAGS=-mcpu=neoverse-v2
cmake --build build -j 8
```

Benchmark decks ship in the repository, so there is no separate data download.

## Run Baseline

**Results**: 

This baseline uses one node and sweeps OpenMP thread counts from 144, running the bm2 deck for 8 iterations across all poses-per-work-item variants. 939 iterations/hour is the baseline I got. 

Create `miniBUDE/run.sh`:
```
#!/bin/bash
#SBATCH --job-name=dilara-bude
#SBATCH --nodes=1
#SBATCH --exclusive
#SBATCH --time=02:00:00 # 1 hour is not enough for all thread counts
#SBATCH --output=dilara-bude-%j.out

module load PrgEnv-gnu
module load gcc-native/14
module load craype-arm-grace

echo "### host: $(hostname)"
echo "### date: $(date)"
echo "### modules:"
module list 2>&1
echo

export OMP_PROC_BIND=close
export OMP_PLACES=cores
export OMP_NUM_THREADS=144

./build/omp-bude --deck data/bm2 -n 0 -i 2 -p all --csv

```

