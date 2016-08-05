
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
