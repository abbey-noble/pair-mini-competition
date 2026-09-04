# GROMACS

## Week 2 configurations tested

BASELINE: 299.737 ns/day 

### Individual runs

| ranks/node | threads | -npme | -dlb | hugepages | DD grid | ns/day | reps |
| ---: | ---: | ---: | :--- | :--- | :--- | ---: | ---: |
| 144 | 1 | 96 | yes | yes | 8×6×4 | **341.7** | 6 |
| 144 | 1 | auto (72) | yes | yes | 6×6×6 | 335.5 | 7 |
| 144 | 1 | auto (72) | auto | yes | 6×6×6 | 333.6 | 5 |
| 144 | 1 | auto (72) | auto | ? | 6×6×6 | 333.3 | 1 |
| 144 | 1 | 78 | yes | yes | 6×7×5 | 307.6 | 3 |
| 144 | 1 | auto (72) | auto | ? | 6×6×6 | 296.0 | 1 |
| 144 | 1 | auto (72) | auto | ? | 6×6×6 | 288.4 | 1 |
| 144 | 1 | auto (72) | auto | yes | 6×6×6 | 269.8 | 1 |
| 144 | 1 | 48 | auto | yes | 8×6×5 | 229.0 | 1 |

`?` = module environment not recorded in that job's output.
`-dlb yes` does not speed the run up, it makes it reproducible.

## Run
```
#!/bin/bash
#SBATCH --job-name=gmx-best
#SBATCH --partition=grace
#SBATCH --nodes=2
#SBATCH --ntasks-per-node=144
#SBATCH --cpus-per-task=1
#SBATCH --exclusive
#SBATCH --time=00:10:00
#SBATCH --output=gmx-best-%j.out

module reset
module load PrgEnv-gnu cray-fftw craype-hugepages2M

export OMP_NUM_THREADS="$SLURM_CPUS_PER_TASK"
export OMP_PLACES=cores
export OMP_PROC_BIND=close

srun --cpu-bind=cores ../build/bin/gmx_mpi mdrun -s ../benchmark/benchMEM.tpr -ntomp "$OMP_NUM_THREADS" -deffnm npme48 -noconfout -npme 96
```

## Best results
341.746 ns/day with:

- 144 MPI ranks per node (288 total)
- 1 OpenMP thread per rank
- 96 explicitly requested PME ranks (`-npme 96`), 192 PP ranks
- 8x6x4 domain-decomposition grid (chosen automatically)