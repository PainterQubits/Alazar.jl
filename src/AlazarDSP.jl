export AlazarDSPNumModules, AlazarDSPModules, AlazarDSPGetModuleHandles
export AlazarDSPGetInfo, AlazarDSPGenerateWindowFunction, AlazarDSPGetBuffer
export AlazarDSPAbortCapture, AlazarFFTSetWindowFunction
export AlazarFFTVerificationMode, AlazarFFTSetup

AlazarDSPNumModules(handle::U32) = ccall((:AlazarDSPGetModules,ats), U32,
    (U32, U32, Ptr{DSPModuleHandle}, Ptr{U32}), handle, 0, C_NULL, numModules)

AlazarDSPGetModuleHandles(handle::U32) = ccall((:AlazarDSPGetModules,ats), U32,
    (U32,U32,Ptr{DSPModuleHandle},Ptr{U32}), handle, numModules, modules, C_NULL)

AlazarDSPGetInfo(handle::DSPModuleHandle) = ccall((:AlazarDSPGetInfo,ats), U32,
    (DSPModuleHandle,Ptr{U32},Ptr{U16},Ptr{U16},Ptr{U32},Ptr{U32},Ptr{U32}),
    handle, dspModuleId, versionMajor, versionMinor, maxLength, C_NULL, C_NULL)

AlazarDSPGenerateWindowFunction(windowType, window,
        windowLength_samples, paddingLength_samples) =
    ccall((:AlazarDSPGenerateWindowFunction,ats), U32,
        (U32, Ptr{Cfloat}, U32, U32), windowType, window,
        windowLength_samples, paddingLength_samples)

AlazarFFTSetWindowFunction(handle::DSPModuleHandle,
        samplesPerRecord, reArray, imArray) =
    ccall((:AlazarFFTSetWindowFunction,ats), U32,
        (DSPModuleHandle, U32, Ptr{Cfloat}, Ptr{Cfloat}),
        handle, samplesPerRecord, reArray, imArray)

# Undocumented in API.
AlazarFFTVerificationMode(dspModule::DSPModule, enable,
        reArray, imArray, recordLength_samples) =
    ccall((:AlazarFFTVerificationMode,ats), U32,
        (DSPModuleHandle, Bool, Ptr{S16}, Ptr{S16}, Csize_t),
        dspModule.handle, enable, reArray, imArray, recordLength_samples)

AlazarFFTSetup(dspModule::DSPModule, channel, recordLength_samples, fftLength_samples,
        outputFormat, reserved, footer, bytesPerOutputRecord) =
    ccall((:AlazarFFTSetup,ats), U32,
        (DSPModuleHandle, U16, U32, U32, U32, U32, U32, Ptr{U32}),
        dspModule.handle, CHANNEL_A, recordLength_samples, fftLength_samples,
        outputFormat, footer, reserved, bytesPerOutputRecord)

AlazarDSPGetBuffer(handle::U32, buffer, timeout_ms) =
    ccall((:AlazarDSPGetBuffer,ats), U32, (U32, Ptr{Void}, U32),
    handle, buffer, timeout_ms)

AlazarDSPAbortCapture(handle::U32) =
    ccall((:AlazarDSPAbortCapture,ats), U32, (U32,), handle)
