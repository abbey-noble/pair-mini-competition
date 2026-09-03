# Quantum ESPRESSO

## Week 2 results

--nodes = 2
BASELINE: 614s

**-nk**: Splits ranks int pools. Pools don't have the ability to talk to one another. 

**-nb**: How many orbitals in each band group 

**-nd**: the shape of the matrix

| --ntasks-per-node | --cpus-per-task | -nk | -nb | -nd | results (s) | memory (GB) |
| ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| 36 | 4 | 2 | -  | -  | 643 | 230.2 |
| 24 | 6 | 2 | -  | -  | 665 | 226.7 |
| 48 | 3 | 2 | 2  | -  | -   | -     |
| 48 | 3 | 2 | 4  | -  | -   | -     |
| 48 | 3 | 2 | -  | 4  | -   | -     |
| 48 | 3 | 2 | -  | 16 | -   | -     |
