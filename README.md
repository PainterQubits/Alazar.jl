# Alazar.jl

Alazar API wrapper for Julia, bare bones.

We introduce a single type, DMABuffer, that allocates memory for DMA transfers in accordance with the requirements imposed by hardware. Otherwise, this is just a wrapper for the C API. It is up to the user to provide error handling.


## Usage

```
Pkg.clone("https://www.github.com/ajkeller34/Alazar.jl.git")
using Alazar
```

## To do

- Replace ugly dependency code with BinDeps
- Put all the constants into a `baremodule`?
