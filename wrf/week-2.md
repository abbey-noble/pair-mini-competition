# WRF optimisation

**Goal**: minimise the total time for 600 CONUS 12 km timesteps on 4 nodes (sum the 600 `Timing for main` values)

## Tuning

- **MPI ranks**: divide the model domain into patches. More ranks = smaller patches but increase halo communication.
- **OpenMP threads**: share each patch between cores. More threads reduce the number of MPI patches and communication.
- **Process grid**: `nproc_x × nproc_y` controls the shape and placement of MPI patches, affecting communication and cache locality.
- **Tiles**: divide each MPI patch into smaller OpenMP work regions. Additional tiles = improve load balance but add overhead.

## Configurations tested

| MPI ranks/node | Threads/rank | Process grid | Tiles | Mean time/step (s) | Total for 600 (s) |
| -------------- | ------------ | ------------ | ----- | ------------------ | ----------------- |
| **36**| **4**| **9×16** | **Default** | **0.103650**      | **62.190**        |
| 36             | 4            | 16×9         | Default | 0.106347          | 63.808            |
| 36             | 4            | Automatic    | Default | 0.106439          | 63.863            |
| 36             | 4            | Automatic    | 8       | 0.107039          | 64.223            |
| 48             | 3            | Automatic    | Default | 0.110329          | 66.197            |
| 72             | 2            | Automatic    | Default | 0.111872          | 67.123            |
| 144            | 1            | Automatic    | Default | 0.119667          | 71.800            |


## Best result

62.190 seconds for 600 timesteps with:

- 4 nodes
- 36 MPI ranks per node, 144 total
- 4 OpenMP threads per rank
- `nproc_x=9`, `nproc_y=16`
- default tiling
- mean 0.103650 seconds per timestep
