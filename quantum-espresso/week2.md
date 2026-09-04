# Quantum ESPRESSO

## Week 2 configurations tested

BASELINE: 614s

**-nk**: Splits ranks into pools. Pools don't have the ability to talk to one another. 

**-nb**: How many orbitals in each band group 

**-nd**: The shape of the matrix

**-nt**: Splits the ranks in a pool into subgroups

| --ntasks-per-node | --cpus-per-task | -nk | -nb | -nd | -nt | runtime (s) | memory (GB) |
| ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| 36 | 4 | 2 | -  | -  | -  |643 | 230.2 |
| 24 | 6 | 2 | -  | -  | -  | 665 | 226.7 |
| 72 | 2 | 2 | -  | -  | -  | OOM | 242 |
| 144 | 1 | 2 | -  | -  | -  | OOM | 265 |
| 48 | 3 | 2 | 2  | -  | -  | OOM   | 453 |
| 48 | 3 | 2 | 4  | -  | -  | OOM   | 891 |
| 48 | 3 | 2 | -  | 4  | -  | 913   | 247 |
| 48 | 3 | 2 | -  | 16 | -  | 662   | 236 |
| 48 | 3 | 2 | -  | 25 | -  | 634 | 234 |
| 48 | 3 | 2 | -  | 49 | -  | **618** | 234 |
| 36 | 4 | 2 | -  | 49 | -  |  |  |
| 72 | 2 | 2 | -  | 49 | -  | OOM | 242 |
| 48 | 3 | 2 | -  | - | 2  | 826   | 234 |
| 48 | 3 | 2 | -  | - | 4  | 650   | 234 |
| 48 | 3 | 2 | -  | - | 8  | 922  | 234 |
| 72 | 2 | 2 | -  | - | 2  | OOM  | 265 |

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
```

## Best results
618s with:

- 48 MPI ranks per node (96 total)
- 3 OpenMP threads per rank
- 2 k-point pools (48 ranks per pool)
- size of sub-group: 7* 7 procs
- Default Davidson workspace