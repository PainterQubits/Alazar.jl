__precompile__(true)
module Alazar

import Base: size, linearindexing, getindex, length, show, convert

# Type aliases go here
export U32, U16, U8, S32, S16
export dsp_module_handle
export AlazarBits, Alazar8Bit, Alazar12Bit, Alazar16Bit
export AlazarFFTBits, U16Log, U16Amp2, U8Log, U8Amp2
export S32Real, S32Imag, FloatLog, FloatAmp2

export alazaropen

typealias U32 Culong
typealias U16 Cushort
typealias U8 Cuchar
typealias S32 Clong
typealias S16 Cshort
typealias dsp_module_handle Ptr{Void}

abstract AlazarBits
abstract AlazarFFTBits <: AlazarBits

immutable Alazar8Bit <: AlazarBits
    b::U8
end
immutable Alazar12Bit <: AlazarBits
    b::U16
end
immutable Alazar16Bit <: AlazarBits
    b::U16
end
immutable U16Log <: AlazarFFTBits
    b::U16
end
immutable U16Amp2 <: AlazarFFTBits
    b::U16
end
immutable U8Log <: AlazarFFTBits
    b::U8
end
immutable U8Amp2 <: AlazarFFTBits
    b::U8
end
immutable S32Real <: AlazarFFTBits
    b::S32
end
immutable S32Imag <: AlazarFFTBits
    b::S32
end
immutable FloatLog <: AlazarFFTBits
    b::Cfloat
end
immutable FloatAmp2 <: AlazarFFTBits
    b::Cfloat
end

convert(::Type{UInt8}, x::Alazar8Bit) = ltoh(convert(UInt8, x.b))
convert{T<:Integer}(::Type{T}, x::Alazar8Bit) = convert(T, convert(UInt8, x))
convert{T<:AbstractFloat}(::Type{T}, x::Alazar8Bit) = T(convert(UInt8,x)/0xFF*2-1)

convert(::Type{UInt16}, x::Alazar12Bit) = ltoh(convert(UInt16, x.b)) >> 4
convert{T<:Integer}(::Type{T}, x::Alazar12Bit) = convert(T, convert(UInt16, x))
convert{T<:AbstractFloat}(::Type{T}, x::Alazar12Bit) = T(convert(UInt16,x)/0xFFF*2-1)

convert(::Type{UInt16}, x::Alazar16Bit) = ltoh(convert(UInt16, x.b))
convert{T<:Integer}(::Type{T}, x::Alazar16Bit) = convert(T, convert(UInt16, x))
convert{T<:AbstractFloat}(::Type{T}, x::Alazar16Bit) = T(convert(UInt16,x)/0xFFFF*2-1)

convert{S<:Real,T<:AlazarBits}(::Type{S}, x::T) = convert(S, x.b)
convert{S<:Complex,T<:S32Real}(::Type{S}, x::T) = S(x.b,0)
convert{S<:Complex,T<:S32Imag}(::Type{S}, x::T) = S(0,x.b)
convert{T<:AlazarBits}(::Type{T}, x::T) = x
convert{S<:AlazarBits,T<:AlazarBits}(::Type{S}, x::T) = S(x.b)

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

include("AlazarBuffer.jl")
include("AlazarErrors.jl")
include("AlazarAPI.jl")
include("AlazarDSP.jl")

end
