# Alazar.jl
[AlazarTech](http://www.alazartech.com) API wrapper for Julia, bare bones.

Adapted from the C and Python APIs by Andrew Keller (andrew.keller.09@gmail.com)

## Usage

```
Pkg.clone("https://www.github.com/ajkeller34/Alazar.jl.git")
using Alazar
```

## Description
This module provides a thin wrapper on top of the AlazarTech C
API. Nearly all the exported methods directly map to underlying C
functions. Please see the ATS-SDK Guide for detailed specification of
these functions. It is up to the user to provide error handling.

`alazaropen()` must be called once and only once after loading this package. Do
not call it from Julia workers or undefined behavior may occur. No manual
cleanup is necessary upon exiting Julia.

## Types
### Type aliases
`U32`, `U16`, `U8`, `S32`, `S16`, `dsp_module_handle` aliased to their
respective C types.
### DMABufferArray
An indexable, iterable type where each index is a pointer to a page-aligned
chunk of memory suitable for DMA transfer. The memory is all contiguous and
backed by a `SharedArray`. The end user is responsible for ensuring that the
nth buffer in the array falls on a page boundary, but we warn about it.
### AlazarBits
`Alazar8Bit`, `Alazar12Bit`, `Alazar16Bit`.
These encapsulate 8-bit, 12-bit, and 16-bit UInts. They have very little
overhead being declared immutable, but have the advantage that 12-bit and 16-bit
formats are distinguishable by type.
### AlazarFFTOutputFormat
`U16Log`, `U16Amp2`, `U8Log`, `U8Amp2`,
`S32Real`, `S32Imag`, `FloatLog`, `FloatAmp2`.
Similar strategy as for `AlazarBits` types. Permits efficient encoding of
FFT output data while distinguishing between e.g. `S32Real` and `S32Imag`.

## To do

- Replace ugly dependency code with BinDeps
- Put all the constants into a `baremodule`?
