# WRF

WRF is a numerical weather prediction model. The CONUS 12km benchmark runs a forecast over the continental United States.

**Goal**: run the CONUS 12km benchmark as fast as possible

**Metric**: timestep (higher is better), from `rsl.error.0000`

**Requirement**: run reaches "SUCCESS COMPLETE WRF"

## Build

**Dependencies:**
- GCC 14 (`gcc-native/14`): C/Fortran compilation
- `craype-arm-grace`: Grace target module
- `cray-hdf5/1.14.3.9`
- `cray-netcdf/4.9.2.3`

Serial `cray-netcdf` is used rather than `cray-netcdf-hdf5parallel`, because no GNU build of the parallel variant exists on this system.

**Source**: https://github.com/wrf-model/WRF.git

Build wrf.exe:
```
module load PrgEnv-gnu gcc-native/14 craype-arm-grace cray-hdf5/1.14.3.9 cray-netcdf/4.9.2.3

git clone https://github.com/wrf-model/WRF.git

export NETCDF=$NETCDF_DIR
export NETCDF_classic=1

cd WRF
./configure
# 16 - GCC Aarch64
# 1  - basic nesting (default)

./compile em_real -j 8 2>&1 | tee compile.log
```

`NETCDF_classic=1` is required: WRF's netCDF-4 detection test fails against Cray's netCDF despite it reporting NetCDF-4 support, and configure then deletes `configure.wrf` and exits.

Compile takes around 16 minutes.

Get benchmark data:
```
wget https://www2.mmm.ucar.edu/wrf/users/benchmark/v44/v4.4_bench_conus12km.tar.gz
tar xzf v4.4_bench_conus12km.tar.gz

cd WRF/test/em_real
ln -sf ../../../v4.4_bench_conus12km/*.dat .
ln -sf ../../../v4.4_bench_conus12km/wrfinput_d01 .
ln -sf ../../../v4.4_bench_conus12km/wrfbdy_d01 .
cp ../../../v4.4_bench_conus12km/namelist.input .
```

The large inputs are symlinked rather than copied. `namelist.input` is copied because it gets edited, and editing a symlink would modify the original data.

## Run Baseline

**Results**: 600

This baseline uses four nodes, 36 MPI ranks per node, 4 OpenMP threads per rank.

Create `WRF/test/em_real/run.sh`:
```
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
```

Timings are written to `rsl.error.0000`, not to the job output file:
```
grep "Timing for main" rsl.error.0000
```
