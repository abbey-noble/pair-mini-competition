#!/bin/bash
#SBATCH --job-name=wrf-sweep
#SBATCH --partition=grace
#SBATCH --nodes=4
#SBATCH --ntasks-per-node=144
#SBATCH --cpus-per-task=1
#SBATCH --exclusive
#SBATCH --time=01:00:00
#SBATCH --output=wrf-sweep-%j.out

module reset
module load PrgEnv-gnu gcc-native/14 craype-arm-grace cray-hdf5/1.14.3.9 cray-netcdf/4.9.2.3

run_dir="$SLURM_SUBMIT_DIR/../WRF/test/em_real"

if [[ ! -e "$run_dir/wrfinput_d01" || ! -e "$run_dir/wrfbdy_d01" || ! -f "$run_dir/namelist.input" ]]
then
echo "Missing CONUS benchmark inputs"
exit 1
fi

mkdir "sweep-$SLURM_JOB_ID"
cd "sweep-$SLURM_JOB_ID"

export OMP_PLACES=cores
export OMP_PROC_BIND=close
export OMP_DYNAMIC=false
export OMP_STACKSIZE=1G

run_case() {
local name=$1
local ranks=$2
local threads=$3
local nproc_x=$4
local nproc_y=$5
local tiles=$6
local log
local status

echo "$name"

mkdir "$name"
find "$run_dir" -maxdepth 1 -type l ! -name namelist.input -exec ln -s {} "$name" \;
cp "$run_dir/namelist.input" "$name"

if [[ "$nproc_x" != auto ]]
then
sed -i '/^[[:space:]]*nproc_x[[:space:]]*=/d; /^[[:space:]]*nproc_y[[:space:]]*=/d' "$name/namelist.input"
sed -i "/^[[:space:]]*&domains/a nproc_x = $nproc_x, nproc_y = $nproc_y," "$name/namelist.input"
fi

if [[ "$tiles" != auto ]]
then
sed -i '/^[[:space:]]*numtiles[[:space:]]*=/d' "$name/namelist.input"
sed -i "/^[[:space:]]*&domains/a numtiles = $tiles," "$name/namelist.input"
fi

cd "$name"
OMP_NUM_THREADS="$threads" srun --nodes=4 --ntasks-per-node="$ranks" --cpus-per-task="$threads" --exact --distribution=block:block --cpu-bind=cores --kill-on-bad-exit=1 --time=00:08:00 ./wrf.exe > slurm.out 2>&1

echo "case=$name ranks_per_node=$ranks threads=$threads nproc_x=$nproc_x nproc_y=$nproc_y numtiles=$tiles" > "../$name.out"
echo "=== srun ===" >> "../$name.out"
cat slurm.out >> "../$name.out"
echo "=== rsl.out.0000 ===" >> "../$name.out"
cat rsl.out.0000 >> "../$name.out" 2>/dev/null
echo "=== rsl.error.0000 ===" >> "../$name.out"
cat rsl.error.0000 >> "../$name.out" 2>/dev/null

if grep -q "Timing for main:" rsl.error.0000 2>/dev/null
then
log=rsl.error.0000
else
log=rsl.out.0000
fi

if grep -q "FATAL CALLED" rsl.error.0000 2>/dev/null
then
echo "$name,FAIL,0," >> ../ranking.tmp
elif grep -q "SUCCESS COMPLETE WRF" rsl.out.0000 rsl.error.0000 2>/dev/null
then
status=COMPLETE
awk -v name="$name" -v status="$status" '/Timing for main:/{sum+=$(NF-2); count++} END{printf "%s,%s,%d,%.6f\n",name,status,count,sum/count}' "$log" >> ../ranking.tmp
elif grep -q "Timing for main:" "$log" 2>/dev/null
then
status=MEASURED
awk -v name="$name" -v status="$status" '/Timing for main:/{sum+=$(NF-2); count++} END{printf "%s,%s,%d,%.6f\n",name,status,count,sum/count}' "$log" >> ../ranking.tmp
else
echo "$name,FAIL,0," >> ../ranking.tmp
fi

cd ..
rm -rf "$name"
}

run_case r36t4-auto 36 4 auto auto auto
run_case r48t3-auto 48 3 auto auto auto
run_case r72t2-auto 72 2 auto auto auto
run_case r144t1-auto 144 1 auto auto auto
run_case r36t4-p9x16 36 4 9 16 auto
run_case r36t4-p16x9 36 4 16 9 auto
run_case r36t4-tiles8 36 4 auto auto 8

echo "case,status,completed_timesteps_in_8_minutes,mean_seconds_per_timestep" > ranking.csv
sort -t, -k3,3nr -k4,4n ranking.tmp >> ranking.csv
rm ranking.tmp

cat ranking.csv
