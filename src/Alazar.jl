"""
# Julia interface to the AlazarTech SDK.

Adapted from the C and Python APIs by Andrew Keller (andrew.keller.09@gmail.com)

## Description
This module provides a thin wrapper on top of the AlazarTech C
API. All the exported methods directly map to underlying C
functions. Please see the ATS-SDK Guide for detailed specification of
these functions.

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
"""

module Alazar

import Base: size, linearindexing, getindex, length, show, convert

# Type aliases go here
export U32, U16, U8, S32, S16
export dsp_module_handle
export AlazarBits, Alazar8Bit, Alazar12Bit, Alazar16Bit
export AlazarFFTOutputFormat
export U16Log, U16Amp2, U8Log, U8Amp2
export S32Real, S32Imag, FloatLog, FloatAmp2
export DMABufferArray

export alazaropen

typealias U32 Culong
typealias U16 Cushort
typealias U8 Cuchar
typealias S32 Clong
typealias S16 Cshort
typealias dsp_module_handle Ptr{Void}

abstract AlazarBits
immutable Alazar8Bit <: AlazarBits
    b::UInt8
end
immutable Alazar12Bit <: AlazarBits
    b::UInt16
end
immutable Alazar16Bit <: AlazarBits
    b::UInt16
end

show{T<:AlazarBits}(io::IO, bit::T) = show(io, bit.b)
convert{S<:Number, T<:AlazarBits}(::Type{S}, x::T)  = convert(S, x.b)

abstract  AlazarFFTOutputFormat
immutable U16Log <: AlazarFFTOutputFormat
    b::U16
end
immutable U16Amp2 <: AlazarFFTOutputFormat
    b::U16
end
immutable U8Log <: AlazarFFTOutputFormat
    b::U8
end
immutable U8Amp2 <: AlazarFFTOutputFormat
    b::U8
end
immutable S32Real <: AlazarFFTOutputFormat
    b::S32
end
immutable S32Imag <: AlazarFFTOutputFormat
    b::S32
end
immutable FloatLog <: AlazarFFTOutputFormat
    b::Cfloat
end
immutable FloatAmp2 <: AlazarFFTOutputFormat
    b::Cfloat
end

show{T<:AlazarFFTOutputFormat}(io::IO, v::T) = show(io, v.b)
convert{S<:Real,T<:AlazarFFTOutputFormat}(::Type{S}, x::T) = convert(S, x.b)
convert{S<:Complex,T<:S32Real}(::Type{S}, x::T) = S(x.b,0)
convert{S<:Complex,T<:S32Imag}(::Type{S}, x::T) = S(0,x.b)

# Constants and exceptions go here
include("AlazarConstants.jl")

# Load libraries
# DL_LOAD_PATH = @windows? "C:\\Users\\Discord\\Documents\\" : "/usr/local/lib/"
const ats = @windows? "ATSApi.dll" : "libATSApi.so"
const libc = "libc.so.6"

# The library should only be loaded once. We don't load it automatically because
# if another worker process loads this module, there could be problems.
#
# Instead the library should be given the chance to load (if it hasn't already)
# whenever Julia objects representing instruments are created.
alazaropen() = begin
    @windows? begin
        atsHandle = Libdl.dlopen(ats)
        atexit(()->Libdl.dlclose(atsHandle))
    end : (@linux? begin
        atsHandle = Libdl.dlopen(ats)
        libcHandle = Libdl.dlopen(libc)
        atexit(()->begin
            Libdl.dlclose(atsHandle)
            Libdl.dlclose(libcHandle)
        end)
    end : throw(SystemError("OS not supported")))
end

"""
Buffer suitable for DMA transfers.

AlazarTech digitizers use direct memory access (DMA) to transfer
data from digitizers to the computer's main memory. This class
abstracts a memory buffer on the host, and ensures that all the
requirements for DMA transfers are met.

Args:

  bytes_buf: The number of bytes per buffer. If there is more than one
  buffer it should be a multiple of Base.Mmap.PAGESIZE.

  n_buf: The size of the buffer to allocate, in bytes.

*Something to watch out for: this code does not support 32-bit systems!*
"""
type DMABufferArray{sample_type <: AlazarBits} <:
        AbstractArray{Ptr{sample_type},1}

    bytes_buf::Int
    n_buf::Int
    backing::SharedArray{sample_type}

    DMABufferArray(bytes_buf, n_buf) = begin
        # Old version used valloc:
        # addr = virtualalloc(size_bytes, sample_type)
        #
        # buffer = pointer_to_array(addr, fld(size_bytes, bytes_per_sample), false)
        # dmabuf = new(Culonglong(bytes_per_sample), Culonglong(size_bytes), addr, buffer)
        #
        # finalizer(dmabuf, destroy)

        # Allocate an uninitialized shared array
        # Conveniently, SharedArrays use mmap which returns page-aligned memory.
        # They will also let us process the data faster.

        n_buf > 1 && bytes_buf % Base.Mmap.PAGESIZE != 0 &&
            error("Bytes per buffer must be a multiple of Base.Mmap.PAGESIZE when ",
                  "there is more than one buffer.")

        backing = SharedArray(sample_type,
                        Int((bytes_buf * n_buf) / sizeof(sample_type)))

        dmabuf = new(bytes_buf,
                     n_buf,
                     backing)

        return dmabuf
    end

end

Base.size(dma::DMABufferArray) = (dma.n_buf,)
Base.linearindexing(::Type{DMABufferArray}) = Base.LinearFast()
Base.getindex(dma::DMABufferArray, i::Int) =
    pointer(dma.backing) + (i-1) * dma.bytes_buf
Base.length(dma::DMABufferArray) = dma.n_buf

DMABufferArray(bits, bytes_buf, n_buf) =
    DMABufferArray{sample_type(bits)}(bytes_buf, n_buf)

sample_type(bits) = begin
    bits == 8 ? Alazar8Bit :
    (bits == 12 ? Alazar12Bit : Alazar16Bit)
end

bytes_per_sample{T}(buf_array::DMABufferArray{T}) = sizeof(T)

# ====Deprecated====
#
# Not to be called by the user!
# function destroy(buf::DMABuffer)
#     virtualfree(buf.addr)
# end
#
# function virtualalloc{T<:Union{UInt8,UInt16}}(size_bytes::Integer, ::Type{T})
#     @windows? begin
#         MEM_COMMIT = U32(0x1000)
#         PAGE_READWRITE = U32(0x4)
#         addr = ccall((:VirtualAlloc, "Kernel32"), Ptr{T},
#             (Ptr{Void}, Culonglong, Culong, Culong),
#             C_NULL, size_bytes, MEM_COMMIT, PAGE_READWRITE)
#     end : (@linux? begin
#         addr = ccall((:valloc, libc), Ptr{T}, (Culonglong,), size_bytes)
#     end : throw(SystemError()))
#
#     addr == C_NULL && throw(OutOfMemoryError())
#
#     addr::Ptr{T}
# end
#
# function virtualfree{T<:Union{UInt16,UInt8}}(addr::Ptr{T})
#     @windows? begin
#         MEM_RELEASE = 0x8000
#         ccall((:VirtualFree, "Kernel32"), Cint, (Ptr{Void}, Culonglong, Culong),
#             addr, Culonglong(0), MEM_RELEASE)
#     end : (@linux? begin
#         ccall((:free, "libc"), Void, (Ptr{Void},), addr)
#     end : throw(SystemError()))
#     nothing
# end

include("AlazarErrors.jl")

export AlazarAbortAsyncRead, AlazarAbortCapture, AlazarBeforeAsyncRead
export AlazarBoardsInSystemBySystemID, AlazarBusy, AlazarConfigureAuxIO
export AlazarConfigureLSB, AlazarConfigureRecordAverage, AlazarForceTrigger
export AlazarForceTriggerEnable, AlazarGetBoardBySystemID, AlazarGetBoardKind
export AlazarGetChannelInfo, AlazarInputControl, AlazarNumOfSystems
export AlazarGetParameter, AlazarGetParameterUL
export AlazarPostAsyncBuffer, AlazarRead, AlazarReadEx, AlazarResetTimeStamp
export AlazarSetBWLimit, AlazarSetCaptureClock, AlazarSetExternalClockLevel
export AlazarSetExternalTrigger, AlazarSetLED, AlazarSetParameter
export AlazarSetParameterUL, AlazarSetRecordCount, AlazarSetRecordSize
export AlazarSetTriggerDelay, AlazarSetTriggerOperation, AlazarSetTriggerTimeOut
export AlazarSetTriggerTimeoutTicks, AlazarSleepDevice
export AlazarStartCapture, AlazarTriggered, AlazarWaitAsyncBufferComplete

AlazarAbortAsyncRead(handle::U32) =
    ccall((:AlazarAbortAsyncRead,ats), U32, (U32,), handle)

AlazarAbortCapture(handle::U32) =
    ccall((:AlazarAbortCapture,ats), U32, (U32,), handle)

AlazarBeforeAsyncRead(handle::U32, channels, transferOffset, samplesPerRecord,
        recordsPerBuffer, recordsPerAcquisition, flags) =
    ccall((:AlazarBeforeAsyncRead,ats), U32, (U32, U32, Clong, U32, U32, U32, U32),
        handle, channels, transferOffset, samplesPerRecord, recordsPerBuffer,
        recordsPerAcquisition, flags)

AlazarBoardsInSystemBySystemID(sid::Integer) =
    ccall((:AlazarBoardsInSystemBySystemID,ats),Culong,(Culong,),sid)

AlazarBusy(handle::U32) = ccall((:AlazarBusy,ats), U32, (U32,), handle)

AlazarConfigureAuxIO(handle::U32, mode, parameter) =
    ccall((:AlazarConfigureAuxIO,ats), U32, (U32, U32, U32), handle, mode, parameter)

AlazarConfigureLSB(handle::U32, valueLSB0, valueLSB1) =
    ccall((:AlazarConfigureLSB,ats), U32, (U32, U32, U32), handle, valueLSB0, valueLSB1)

AlazarConfigureRecordAverage(handle::U32, mode, samplesPerRecord,
        recordsPerAverage, options) =
    ccall((:AlazarConfigureRecordAverage,ats), U32, (U32, U32, U32, U32, U32),
        handle, mode, samplesPerRecord, recordsPerAverage, options)

AlazarForceTrigger(handle::U32) =
    ccall((:AlazarForceTrigger,ats),U32,(U32,),handle)

AlazarForceTriggerEnable(handle::U32) =
    ccall((:AlazarForceTriggerEnable,ats),U32,(U32,),handle)

AlazarGetBoardKind(handle::U32) =
    ccall((:AlazarGetBoardKind,ats),U32,(U32,),handle)

AlazarGetBoardBySystemID(systemID, boardID) =
    ccall((:AlazarGetBoardBySystemID,ats),U32,(U32,U32),systemID,boardID)

AlazarGetChannelInfo(handle::U32, memorySize_samples, bitsPerSample) =
    ccall((:AlazarGetChannelInfo,ats), U32, (U32, Ptr{U32}, Ptr{U8}),
        handle, memorySize_samples, bitsPerSample)

AlazarGetParameter(handle::U32, channel, parameter, value) =
    ccall((:AlazarGetParameter,ats), U32, (U32, U8, U32, Ptr{Clong}),
        handle, channel, parameter, value)

AlazarGetParameterUL(handle::U32, channel, parameter, value) =
    ccall((:AlazarGetParameterUL,ats), U32, (U32, U8, U32, Ptr{U32}),
        handle, channel, parameter, value)

AlazarInputControl(handle::U32, channel, coupling, inputRange, impedance) =
    ccall((:AlazarInputControl,ats), U32, (U32, U8, U32, U32, U32),
        handle, channel, coupling, inputRange, impedance)

AlazarNumOfSystems() = ccall((:AlazarNumOfSystems,ats),U32,())

AlazarPostAsyncBuffer(handle::U32, buffer, bufferLength) =
    ccall((:AlazarPostAsyncBuffer,ats), U32, (U32, Ptr{Void}, U32),
        handle, buffer, bufferLength)

AlazarRead(handle::U32, channelId, buffer, elementSize, record,
        transferOffset, transferLength) =
    ccall((:AlazarRead,ats), U32, (U32, U32, Ptr{Void}, Cint, Clong, Clong, U32),
        handle, channelId, buffer, elementSize, record,
        transferOffset, transferLength)

AlazarReadEx(handle::U32, channelId, buffer, elementSize, record,
        transferOffset, transferLength) =
    ccall((:AlazarReadEx,ats), U32, (U32, U32, Ptr{Void}, Cint, Clong, Clonglong, U32),
    handle, channelId, buffer, elementSize, record, transferOffset, transferLength)

AlazarResetTimeStamp(handle::U32, option) =
    ccall((:AlazarResetTimeStamp,ats),U32,(U32,U32),handle, option)

AlazarSetBWLimit(handle::U32, channel, enable) =
    ccall((:AlazarSetBWLimit,ats), U32, (U32, U32, U32), handle, channel, enable)

AlazarSetCaptureClock(handle::U32, source, rate, edge, decimation) =
    ccall((:AlazarSetCaptureClock,ats), U32, (U32, U32, U32, U32, U32),
        handle, source, rate, edge, decimation) #int(source), int(rate), int(edge)

AlazarSetExternalClockLevel(handle::U32, level_percent) =
    ccall((:AlazarSetExternalClockLevel,ats), U32, (U32, Cfloat),
        handle, level_percent)

AlazarSetExternalTrigger(handle::U32, coupling, range) =
    ccall((:AlazarSetExternalTrigger,ats), U32, (U32,U32,U32),
        handle, coupling, range)

AlazarSetLED(handle::U32, ledState) =
    ccall((:AlazarSetLED,ats), U32, (U32, U32), handle, ledState)

AlazarSetParameter(handle::U32, channelId, parameterId, value) =
    ccall((:AlazarSetParameter,ats), U32, (U32, U8, U32, Clong),
        handle, channelId, parameterId, value)

AlazarSetParameterUL(handle::U32, channelId, parameterId, value) =
    ccall((:AlazarSetParameterUL,ats), U32, (U32, U8, U32, U32),
        handle, channelId, parameterId, value)

AlazarSetRecordCount(handle::U32, count) =
    ccode((:AlazarSetRecordCount,ats), U32, (U32, U32), handle, count)

AlazarSetRecordSize(handle::U32, preTriggerSamples, postTriggerSamples) =
    ccall((:AlazarSetRecordSize,ats), U32, (U32, U32, U32),
        handle, preTriggerSamples, postTriggerSamples)

AlazarSetTriggerDelay(handle::U32, delay_samples) =
    ccall((:AlazarSetTriggerDelay,ats),U32,(U32,U32),handle, delay_samples)

AlazarSetTriggerOperation(handle::U32, operation,
        engine1, source1, slope1, level1, engine2, source2, slope2, level2) =
    ccall((:AlazarSetTriggerOperation,ats), U32,
        (U32, U32, U32, U32, U32, U32, U32, U32, U32, U32),
        handle, operation, engine1, source1, slope1, level1,
        engine2, source2, slope2, level2)

AlazarSetTriggerTimeOut(handle::U32, timeout_clocks) =
    ccall((:AlazarSetTriggerTimeOut,ats), U32, (U32, U32), handle, timeout_clocks)

AlazarSleepDevice(handle::U32, sleepState) =
    ccall((:AlazarSleepDevice,ats), U32, (U32, U32), handle, sleepState)

AlazarStartCapture(handle::U32) = ccall((:AlazarStartCapture,ats), U32, (U32,), handle)

AlazarTriggered(handle::U32) = ccall((:AlazarTriggered,ats), U32, (U32,), handle)

AlazarWaitAsyncBufferComplete(handle::U32, buffer, timeout_ms) =
    ccall((:AlazarWaitAsyncBufferComplete,ats), U32, (U32, Ptr{Void}, U32),
        handle, buffer, timeout_ms)

include("AlazarDSP.jl")

end
