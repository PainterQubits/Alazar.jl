export AlazarDSPGetModules, AlazarDSPGetInfo, AlazarDSPGenerateWindowFunction
export AlazarDSPGetBuffer, AlazarDSPAbortCapture, AlazarFFTSetWindowFunction
export AlazarFFTVerificationMode, AlazarFFTSetup

AlazarDSPGetModules(handle::U32, numEntries, modules, numModules) =
    ccall((:AlazarDSPGetModules,ats), U32,
        (U32, U32, Ptr{dsp_module_handle}, Ptr{U32}),
        handle, numEntries, modules, numModules)

AlazarDSPGetInfo(handle::dsp_module_handle, dspModuleId,
        versionMajor, versionMinor, maxLength, reserved0, reserved1) =
    ccall((:AlazarDSPGetInfo,ats), U32, (dsp_module_handle, Ptr{U32},
        Ptr{U16}, Ptr{U16}, Ptr{U32}, Ptr{U32}, Ptr{U32}), handle, dspModuleId,
        versionMajor, versionMinor, maxLength, reserved0, reserved1)

AlazarDSPGenerateWindowFunction(windowType, window,
        windowLength_samples, paddingLength_samples) =
    ccall((:AlazarDSPGenerateWindowFunction,ats), U32,
        (U32, Ptr{Cfloat}, U32, U32), windowType, window,
        windowLength_samples, paddingLength_samples)

AlazarFFTSetWindowFunction(handle::dsp_module_handle,
        samplesPerRecord, reArray, imArray) =
    ccall((:AlazarFFTSetWindowFunction,ats), U32,
        (dsp_module_handle, U32, Ptr{Cfloat}, Ptr{Cfloat}),
        handle, samplesPerRecord, reArray, imArray)

# Undocumented in API.
AlazarFFTVerificationMode(handle::dsp_module_handle, enable,
        reArray, imArray, recordLength_samples) =
    ccall((:AlazarFFTVerificationMode,ats), U32,
        (dsp_module_handle, Bool, Ptr{S16}, Ptr{S16}, Csize_t),
        handle, enable, reArray, imArray, recordLength_samples)

AlazarFFTSetup(handle::dsp_module_handle, channel, recordLength_samples,
        fftLength_samples, outputFormat, reserved, footer, bytesPerOutputRecord) =
    ccall((:AlazarFFTSetup,ats), U32,
        (dsp_module_handle, U16, U32, U32, U32, U32, U32, Ptr{U32}),
        handle, CHANNEL_A, recordLength_samples, fftLength_samples,
        outputFormat, footer, reserved, bytesPerOutputRecord)

AlazarDSPGetBuffer(handle::U32, buffer, timeout_ms) =
    ccall((:AlazarDSPGetBuffer,ats), U32, (U32, Ptr{Void}, U32),
    handle, buffer, timeout_ms)

AlazarDSPAbortCapture(handle::U32) =
    ccall((:AlazarDSPAbortCapture,ats), U32, (U32,), handle)
