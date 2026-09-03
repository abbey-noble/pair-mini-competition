# Quantum ESPRESSO

## Week 2 configurations tested

BASELINE: 614s

**-nk**: Splits ranks into pools. Pools don't have the ability to talk to one another. 

**-nb**: How many orbitals in each band group 

**-nd**: the shape of the matrix

**-nt**: 

| --ntasks-per-node | --cpus-per-task | -nk | -nb | -nd | -nt | runtime (s) | memory (GB) |
| ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| 36 | 4 | 2 | -  | -  | -  |643 | 230.2 |
| 24 | 6 | 2 | -  | -  | -  | 665 | 226.7 |
| 48 | 3 | 2 | 2  | -  | -  | -   | -     |
| 48 | 3 | 2 | 4  | -  | -  | -   | -     |
| 48 | 3 | 2 | -  | 4  | -  | -   | -     |
| 48 | 3 | 2 | -  | 16 | -  | -   | -     |
| 48 | 3 | 2 | -  | - | 2  | -   | -     |
| 48 | 3 | 2 | -  | - | 4  | -   | -     |

## Run
```
#!/bin/bash
#SBATCH --job-name=qe
#SBATCH --partition=grace
#SBATCH --nodes=2
#SBATCH --ntasks-per-node=48
#SBATCH --cpus-per-task=3
#SBATCH --exclusive
#SBATCH --time=01:00:00
#SBATCH --output=qe-%j.out

module reset
module load PrgEnv-gnu cray-libsci cray-fftw

export OMP_NUM_THREADS="$SLURM_CPUS_PER_TASK"
export OMP_PLACES=cores
export OMP_PROC_BIND=close

srun --cpu-bind=cores ../bin/pw.x -nk 2 -nd 16 -in grir443.in

## Best results
