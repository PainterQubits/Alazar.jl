"""
Julia interface to the AlazarTech SDK.
Adapted from the C and Python APIs by Andrew Keller (andrew.keller.09@gmail.com)

This module provides a thin wrapper on top of the AlazarTech C
API. All the exported methods directly map to underlying C
functions. Please see the ATS-SDK Guide for detailed specification of
these functions. In addition, this module provides a few classes for
convenience.

Types

InstrumentAlazar: Represents a digitizer. Abstract type.
AlazarATS9360: Concrete type.

DMABuffer: Holds a memory buffer suitable for data transfer with digitizers.
"""

module Alazar

# Type aliases go here
export U32, U16, S16, U8
export DSPModuleHandle

export DMABuffer

typealias U32 Culong
typealias U16 Cushort
typealias S16 Cshort
typealias U8 Cuchar
typealias DSPModuleHandle Ptr{Void}

# Constants and exceptions go here
include("AlazarConstants.jl")

# Load libraries
# DL_LOAD_PATH = @windows? "C:\\Users\\Discord\\Documents\\" : "/usr/local/lib/"
const ats = @windows? "ATSApi.dll" : "libATSApi.so"
const libc = "libc.so.6"

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


"""
Buffer suitable for DMA transfers.

AlazarTech digitizers use direct memory access (DMA) to transfer
data from digitizers to the computer's main memory. This class
abstracts a memory buffer on the host, and ensures that all the
requirements for DMA transfers are met.

DMABuffers export a 'buffer' member, which is a Julia Array
of the underlying memory buffer

Args:

  bytesPerSample (int): The number of bytes per samples of the
  data. This varies with digitizer models and configurations.

  sizeBytes (int): The size of the buffer to allocate, in bytes.

*Something to watch out for: this code does not support 32-bit systems!*
"""
type DMABuffer{cSampleType <: Union{UInt16,UInt8}}
    bytesPerSample::Culonglong
    sizeBytes::Culonglong
    addr::Ptr{cSampleType}
    array::Array{cSampleType}

    DMABuffer(bytesPerSample, sizeBytes) = begin
    if (typeof(bytesPerSample) != Culonglong || typeof(sizeBytes) != Culonglong)
        throw(ArgumentError("You should be more careful using inner constructors..."))
    end

    # Only Windows or UNIX supported, not OS X...?
    @windows? begin
        MEM_COMMIT = U32(0x1000)
        PAGE_READWRITE = U32(0x4)
        addr = ccall((:VirtualAlloc,"Kernel32"), Ptr{cSampleType},
            (Ptr{Void},Culonglong,Culong,Culong),
            C_NULL, sizeBytes, MEM_COMMIT, PAGE_READWRITE)
    end : (@linux? begin
        addr = ccall((:valloc,libc), Ptr{cSampleType}, (Culonglong,), sizeBytes)    #Culong, ?
    end : throw(SystemError()))

    if (addr == C_NULL)
        throw(OutOfMemoryError())
    end

    buffer = pointer_to_array(addr, fld(sizeBytes, bytesPerSample), false)
    dmabuf = new(bytesPerSample, sizeBytes, addr, buffer)

    finalizer(dmabuf, destroy)
    return dmabuf
    end
end

DMABuffer(bytesPerSample::Culonglong, sizeBytes::Culonglong) =
    (bytesPerSample > 1) ? DMABuffer{UInt16}(bytesPerSample, sizeBytes) :
                           DMABuffer{UInt8}(bytesPerSample, sizeBytes)

DMABuffer(a, b) = DMABuffer(convert(Culonglong,a),convert(Culonglong,b))

# Not to be called by the user!
destroy(buf::DMABuffer) = begin
    @windows? begin
        MEM_RELEASE = 0x8000
        ccall((:VirtualFree,"Kernel32"),Cint,(Ptr{Void},Culonglong,Culong),
            buf.addr,Culonglong(0),MEM_RELEASE)
    end : (@linux? begin
        ccall((:free,"libc"),Void,(Ptr{Void},),buf.addr)
    end : throw(SystemError()))
end

include("AlazarErrors.jl")

export AlazarAbortAsyncRead, AlazarAbortCapture, AlazarBeforeAsyncRead
export AlazarBoardsInSystemBySystemID, AlazarBusy, AlazarConfigureAuxIO
export AlazarConfigureLSB, AlazarConfigureRecordAverage, AlazarForceTrigger
export AlazarForceTriggerEnable, AlazarGetChannelInfo, AlazarGetChannelInfo_unsafe
export AlazarInputControl, AlazarNumOfSystems, AlazarPostAsyncBuffer, AlazarRead
export AlazarReadEx, AlazarResetTimeStamp, AlazarSetBWLimit
export AlazarSetCaptureClock, AlazarSetExternalClockLevel, AlazarSetExternalTrigger
export AlazarSetLED, AlazarSetParameter, AlazarSetParameterUL, AlazarSetRecordCount
export AlazarSetRecordSize, AlazarSetTriggerDelaySamples, AlazarSetTriggerOperation
export AlazarSetTriggerTimeout, AlazarSetTriggerTimeoutTicks, AlazarSleepDevice
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

AlazarGetChannelInfo(handle::U32) =
    ccall((:AlazarGetChannelInfo,ats), U32, (U32, Ptr{U32}, Ptr{U8}),
        handle, memorySize_samples, bitsPerSample)

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
    ccall((:AlazarSetParameter,ats), U32, (U32, U8, U32, Ptr{Clong}),
        handle, channelId, parameterId, value)

AlazarSetParameterUL(handle::U32, channelId, parameterId, value) =
    ccall((:AlazarSetParameterUL,ats), U32, (U32, U8, U32, Ptr{U32}),
        handle, channelId, parameterId, value)

AlazarSetRecordCount(handle::U32, count) =
    ccode((:AlazarSetRecordCount,ats), U32, (U32, U32), handle, count)

AlazarSetRecordSize(handle::U32, preTriggerSamples, postTriggerSamples) =
    ccall((:AlazarSetRecordSize,ats), U32, (U32, U32, U32),
        handle, preTriggerSamples, postTriggerSamples)

AlazarSetTriggerDelaySamples(handle::U32, delay_samples) =
    ccall((:AlazarSetTriggerDelay,ats),U32,(U32,U32),handle, delay_samples)

AlazarSetTriggerOperation(handle::U32, operation,
        engine1, source1, slope1, level1, engine2, source2, slope2, level2) =
    ccall((:AlazarSetTriggerOperation,ats), U32,
        (U32, U32, U32, U32, U32, U32, U32, U32, U32, U32),
        handle, operation, engine1, source1, slope1, level1,
        engine2, source2, slope2, level2)

AlazarSetTriggerTimeoutTicks(handle::U32, timeout_clocks) =
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
