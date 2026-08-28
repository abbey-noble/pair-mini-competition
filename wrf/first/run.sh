#!/bin/bash
#SBATCH --job-name=dilara-wrf
#SBATCH --nodes=4
#SBATCH --ntasks-per-node=36
#SBATCH --cpus-per-task=4
#SBATCH --exclusive
#SBATCH --time=00:40:00
#SBATCH --output=dilara-wrf-%j.out

module load PrgEnv-gnu gcc-native/14 craype-arm-grace cray-hdf5/1.14.3.9 cray-netcdf/4.9.2.3

export OMP_NUM_THREADS=4
export OMP_PROC_BIND=close
export OMP_PLACES=cores

echo "### $(hostname) $(date)"
srun --cpu-bind=cores ./wrf.exe