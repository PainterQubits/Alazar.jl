[![Build Status](https://travis-ci.org/PainterQubits/Alazar.jl.svg?branch=master)](https://travis-ci.org/PainterQubits/Alazar.jl)
[![Coverage Status](https://coveralls.io/repos/PainterQubits/Alazar.jl/badge.svg?branch=master&service=github)](https://coveralls.io/github/PainterQubits/Alazar.jl?branch=master)
[![codecov.io](http://codecov.io/github/PainterQubits/Alazar.jl/coverage.svg?branch=master)](http://codecov.io/github/PainterQubits/Alazar.jl?branch=master)

# Alazar.jl

[AlazarTech](http://www.alazartech.com) API wrapper for Julia, bare bones.

Adapted from the C and Python APIs by Andrew Keller (andrew.keller.09@gmail.com)

## Usage

```jl
Pkg.clone("https://www.github.com/PainterQubits/Alazar.jl.git")
using Alazar
```

## Description

This module provides a thin wrapper on top of the AlazarTech C API. Nearly all the exported
methods directly map to underlying C functions. Please see the ATS-SDK Guide for detailed
specification of these functions. It is up to the user to provide error handling.

`alazaropen()`, which loads the shared libraries, must be called once and only once after
loading this package. When using multiple Julia worker processes, do not call it from
workers or undefined behavior may occur. No manual cleanup is necessary upon exiting Julia.

## Types introduced

### DMABufferArray

```
    struct DMABufferVector{S,T} <: AbstractVector{S}
```

AlazarTech digitizers use direct memory access (DMA) to transfer data from digitizers to
the computer's main memory. This struct abstracts memory buffers on the host. The elements
of a `DMABufferVector` are pointers to the individual buffers, which are each page-aligned,
provided a page-aligned backing array is used (e.g. `Base.SharedVector` or
`Alazar.PageAlignedVector`).

`DMABufferVector` may be constructed as, for example,
`DMABufferVector(SharedVector{UInt8}, bytes_buf, n_buf)` or
`DMABufferVector(Alazar.PageAlignedArray{UInt8}, bytes_buf, n_buf)`.

The fields of a `DMABufferVector{S,T}` are:
- `bytes_buf::Int`: The number of bytes per buffer. If there is more than one buffer it
  should be a multiple of Base.Mmap.PAGESIZE. This is enforced in the inner constructor.
- `n_buf::Int`: The number of buffers to allocate.
- `backing::T`: The page-aligned backing array. `S` is `Ptr{eltype(T)}`.

This code may not support 32-bit systems.

### PageAlignedArray

```
    mutable struct PageAlignedArray{T,N} <: AbstractArray{T,N}
```

An `N`-dimensional array of eltype `T` which is guaranteed to have its memory be
page-aligned. This has to be a mutable struct because finalizers are used to clean up the
memory allocated by C calls when there remain no references to the PageAlignedArray object
in Julia.

### Type aliases

- `PageAlignedVector{T} = PageAlignedArray{T,1}`.

- `U32`, `U16`, `U8`, `S32`, `S16` are aliased to their respective unsigned and signed
N-bit C types.

- `dsp_module_handle = Ptr{Void}`.

### AlazarBits

- `Alazar8Bit`, `Alazar12Bit`, `Alazar16Bit`. These encapsulate 8-bit, 12-bit, and 16-bit
  unsigned integers in the Alazar format. They have very little overhead being declared
  immutable, but have the advantage that 12-bit and 16-bit formats are distinguishable by
  type.

### AlazarFFTOutputFormat

- `U16Log`, `U16Amp2`, `U8Log`, `U8Amp2`, `S32Real`, `S32Imag`, `FloatLog`, `FloatAmp2`.
  Similar strategy as for `AlazarBits` types. Permits efficient encoding of FFT output data
  while distinguishing between e.g. `S32Real` and `S32Imag`.
