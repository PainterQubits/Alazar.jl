__precompile__(true)
module Alazar

# Type aliases go here
export U32, U16, U8, S32, S16
export dsp_module_handle
export AlazarBits, Alazar8Bit, Alazar12Bit, Alazar16Bit
export AlazarFFTBits, U16Log, U16Amp2, U8Log, U8Amp2
export S32Real, S32Imag, FloatLog, FloatAmp2

export alazaropen

const U32 = Culong
const U16 = Cushort
const U8  = Cuchar
const S32 = Clong
const S16 = Cshort
const dsp_module_handle = Ptr{Void}

abstract type AlazarBits end
abstract type AlazarFFTBits <: AlazarBits end

struct Alazar8Bit <: AlazarBits
    b::U8
end
struct Alazar12Bit <: AlazarBits
    b::U16
end
struct Alazar16Bit <: AlazarBits
    b::U16
end
struct U16Log <: AlazarFFTBits
    b::U16
end
struct U16Amp2 <: AlazarFFTBits
    b::U16
end
struct U8Log <: AlazarFFTBits
    b::U8
end
struct U8Amp2 <: AlazarFFTBits
    b::U8
end
struct S32Real <: AlazarFFTBits
    b::S32
end
struct S32Imag <: AlazarFFTBits
    b::S32
end
struct FloatLog <: AlazarFFTBits
    b::Cfloat
end
struct FloatAmp2 <: AlazarFFTBits
    b::Cfloat
end

Base.convert(::Type{UInt8}, x::Alazar8Bit) = ltoh(convert(UInt8, x.b))
Base.convert(::Type{T}, x::Alazar8Bit) where {T <: Integer} = convert(T, convert(UInt8, x))
Base.convert(::Type{T}, x::Alazar8Bit) where {T <: AbstractFloat} = T(convert(UInt8,x)/0xFF*2-1)

Base.convert(::Type{UInt16}, x::Alazar12Bit) = ltoh(convert(UInt16, x.b)) >> 4
Base.convert(::Type{T}, x::Alazar12Bit) where {T <: Integer} = convert(T, convert(UInt16, x))
Base.convert(::Type{T}, x::Alazar12Bit) where {T <: AbstractFloat} = T(convert(UInt16,x)/0xFFF*2-1)

Base.convert(::Type{UInt16}, x::Alazar16Bit) = ltoh(convert(UInt16, x.b))
Base.convert(::Type{T}, x::Alazar16Bit) where {T <: Integer} = convert(T, convert(UInt16, x))
Base.convert(::Type{T}, x::Alazar16Bit) where {T <: AbstractFloat} = T(convert(UInt16,x)/0xFFFF*2-1)

Base.convert(::Type{S}, x::T) where {S <: Real,T <: AlazarBits} = convert(S, x.b)
Base.convert(::Type{S}, x::T) where {S <: Complex,T <: S32Real} = S(x.b,0)
Base.convert(::Type{S}, x::T) where {S <: Complex,T <: S32Imag} = S(0,x.b)
Base.convert(::Type{T}, x::T) where {T <: AlazarBits} = x
Base.convert(::Type{S}, x::T) where {S <: AlazarBits,T <: AlazarBits} = S(x.b)

# Constants and exceptions go here
include("constants.jl")

# Load libraries
const ats = is_windows() ? "ATSApi.dll" : "libATSApi.so"
const linux_libc = "libc.so.6"
# The library should only be loaded once. We don't load it automatically because
# if another worker process loads this module, there could be problems.
#
# Instead the library should be given the chance to load (if it hasn't already)
# whenever Julia objects representing instruments are created.
alazaropen() = begin
    @static is_windows()? begin
        atsHandle = Libdl.dlopen(ats)
        atexit(()->Libdl.dlclose(atsHandle))
    end : (@static is_linux()? begin
        atsHandle = Libdl.dlopen(ats)
        libcHandle = Libdl.dlopen(linux_libc)
        atexit(()->begin
            Libdl.dlclose(atsHandle)
            Libdl.dlclose(libcHandle)
        end)
    end : error("OS not supported"))
end

include("buffer.jl")
include("errors.jl")
include("api.jl")
include("dsp.jl")

end
