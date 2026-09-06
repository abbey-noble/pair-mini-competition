#!/bin/bash

set -e

sed -i 's/devices\.template emplace_back/devices.emplace_back/' src/omp/fasten.hpp

module reset
module load PrgEnv-gnu gcc-native/14

cmake -S . -B build -DMODEL=omp -DPPWI=16 -DCMAKE_CXX_COMPILER=CC -DCXX_EXTRA_FLAGS=-mcpu=neoverse-v2
cmake --build build -j 8

cmake -S . -B build-gcc-grace -DMODEL=omp -DPPWI=8,16,32 -DCMAKE_CXX_COMPILER=CC -DCXX_EXTRA_FLAGS=-mcpu=grace
cmake --build build-gcc-grace -j 8

cmake -S . -B build-gcc-grace-sve128 -DMODEL=omp -DPPWI=8,16,32 -DCMAKE_CXX_COMPILER=CC -DCXX_EXTRA_FLAGS="-mcpu=grace -msve-vector-bits=128"
cmake --build build-gcc-grace-sve128 -j 8

cmake -S . -B build-gcc-grace-ofast-sve128 -DMODEL=omp -DPPWI=8,16,32 -DCMAKE_CXX_COMPILER=CC -DRELEASE_FLAGS=-Ofast -DCXX_EXTRA_FLAGS="-mcpu=grace -msve-vector-bits=128"
cmake --build build-gcc-grace-ofast-sve128 -j 8

cmake -S . -B build-gcc-low-sqrt -DMODEL=omp -DPPWI=8,16,32 -DCMAKE_CXX_COMPILER=CC -DCXX_EXTRA_FLAGS="-mcpu=neoverse-v2 -mlow-precision-sqrt"
cmake --build build-gcc-low-sqrt -j 8

cmake -S . -B build-gcc-low-sqrt-div -DMODEL=omp -DPPWI=8,16,32 -DCMAKE_CXX_COMPILER=CC -DCXX_EXTRA_FLAGS="-mcpu=neoverse-v2 -mlow-precision-sqrt -mlow-precision-div"
cmake --build build-gcc-low-sqrt-div -j 8

cmake -S . -B build-gcc-lto -DMODEL=omp -DPPWI=16 -DCMAKE_CXX_COMPILER=CC -DCXX_EXTRA_FLAGS="-mcpu=neoverse-v2 -flto"
cmake --build build-gcc-lto -j 8

cmake -S . -B build-gcc-low-sqrt-lto -DMODEL=omp -DPPWI=16 -DCMAKE_CXX_COMPILER=CC -DCXX_EXTRA_FLAGS="-mcpu=neoverse-v2 -mlow-precision-sqrt -flto"
cmake --build build-gcc-low-sqrt-lto -j 8

module reset
module load PrgEnv-nvidia

cmake -S . -B build-nvidia -DMODEL=omp -DPPWI=8,16,32 -DCMAKE_CXX_COMPILER=CC
cmake --build build-nvidia -j 8

module reset
module load PrgEnv-cray

cmake -S . -B build-cray -DMODEL=omp -DPPWI=8,16,32,64,128 -DCMAKE_CXX_COMPILER=CC
cmake --build build-cray -j 8

cmake -S . -B build-cray-vector3 -DMODEL=omp -DPPWI=32 -DCMAKE_CXX_COMPILER=CC -DCXX_EXTRA_FLAGS=-hvector3
cmake --build build-cray-vector3 -j 8

cmake -S . -B build-cray-lto -DMODEL=omp -DPPWI=32 -DCMAKE_CXX_COMPILER=CC -DCXX_EXTRA_FLAGS=-flto
cmake --build build-cray-lto -j 8

cmake -S . -B build-cray-ofast -DMODEL=omp -DPPWI=32 -DCMAKE_CXX_COMPILER=CC -DRELEASE_FLAGS=-Ofast
cmake --build build-cray-ofast -j 8
