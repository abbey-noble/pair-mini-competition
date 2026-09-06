# miniBUDE optimisation

**Goal**: maximise iterations/hour for `bm2` on one node

## Tuning

- **Compiler**: GCC, NVIDIA and Cray generate different vectorised machine code.
- **Compiler flags**: test for CPU arch, SIMD width, floating-point operations and link-time.
- **PPWI**: poses per work item. Larger values = more independent poses calculated together (improve vectorisation), but increase register and cache pressure.
- **OpenMP threads**: divide work items between CPU cores.
- **Thread binding**: control placement between Grace's two NUMA regions.

## Configurations tested

### GCC

| Flags | Threads | Binding | PPWI | Iterations/hour |
|---|---:|---|---:|---:|
| `-mcpu=neoverse-v2` | 72 | close | 16 | 487.990 |
| `-mcpu=neoverse-v2` | 72 | spread | 16 | 488.639 |
| `-mcpu=neoverse-v2` | 128 | close | 16 | 863.705 |
| `-mcpu=neoverse-v2` | 136 | spread | 16 | 892.544 |
| `-mcpu=neoverse-v2` | 140 | spread | 16 | 921.402 |
| `-mcpu=neoverse-v2` | 144 | close | 16 | 953.818 |
| `-mcpu=grace` | 144 | close | 8 | 787.517 |
| `-mcpu=grace` | 144 | close | 16 | 951.017 |
| `-mcpu=grace` | 144 | close | 32 | 837.926 |
| `-mcpu=grace -msve-vector-bits=128` | 144 | close | 8 | 787.243 |
| `-mcpu=grace -msve-vector-bits=128` | 144 | close | 16 | 944.321 |
| `-mcpu=grace -msve-vector-bits=128` | 144 | close | 32 | 832.489 |
| `-Ofast -mcpu=grace -msve-vector-bits=128` | 144 | close | 8 | 780.831 |
| `-Ofast -mcpu=grace -msve-vector-bits=128` | 144 | close | 16 | 940.584 |
| `-Ofast -mcpu=grace -msve-vector-bits=128` | 144 | close | 32 | 830.887 |
| `-mlow-precision-sqrt` | 144 | close | 8 | 697.751 |
| **`-mlow-precision-sqrt`** | **144** | **close** | **16** | **954.349** |
| `-mlow-precision-sqrt` | 144 | close | 32 | 700.399 |
| `-mlow-precision-sqrt -mlow-precision-div` | 144 | close | 8 | 669.202 |
| `-mlow-precision-sqrt -mlow-precision-div` | 144 | close | 16 | 933.583 |
| `-mlow-precision-sqrt -mlow-precision-div` | 144 | close | 32 | 700.023 |
| `-flto` | 144 | close | 16 | 975.196 |
| `-mlow-precision-sqrt -flto` | 144 | close | 16 | 928.596 |

### NVIDIA

| Flags | Threads | Binding | PPWI | Iterations/hour |
|---|---:|---|---:|---:|
|  | 144 | close | 8 | 721.158 |
|  | 144 | close | 16 | 801.257 |
|  | **144** | **close** | **32** | **831.221** |

### Cray


| Flags | Threads | Binding | PPWI | Iterations/hour |
|---|---:|---|---:|---:|
| `-O3 -ffast-math` | 144 | close | 8 | 821.577 |
| `-O3 -ffast-math` | 144 | close | 16 | 1066.053 |
| `-O3 -ffast-math` | 144 | close | 32 | 1200.731 |
| `-O3 -ffast-math`| 144 | close | 64 | 1015.431 |
| `-O3 -ffast-math` | 144 | close | 128 | 1039.032 |
| `-O3 -ffast-math -hvector3` | 144 | close | 32 | 1194.944 |
| `-O3 -ffast-math -flto` | 144 | close | 32 | 1139.516 |
| `-O3 -ffast-math -Ofast` | 144 | close | 32 | 1196.203 |
| `-O3 -ffast-math` | 140 | close | 32 | 1200.219 |
| **`-O3 -ffast-math`** | **137** | **close** | **32** | **1205.900** |

## Best result

1205.900 iterations/hour with:

- Cray compiler
- `-O3 -ffast-math`
- 137 OpenMP threads
- Close thread binding
- PPWI 32

Other metrics:
- 2985.323 ms per iteration
- 4752.041 GFLOP/s
