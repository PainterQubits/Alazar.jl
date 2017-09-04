export DMABufferVector, PageAlignedArray, PageAlignedVector

"""
    struct DMABufferVector{S,T} <: AbstractVector{S}

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
"""
struct DMABufferVector{S,T} <: AbstractVector{S}
    bytes_buf::Int
    n_buf::Int
    backing::T

    function DMABufferVector{S,T}(bytes_buf::Integer, n_buf::Integer) where {S,T<:AbstractVector}
        @assert n_buf >= 0
        @assert bytes_buf * n_buf % sizeof(eltype(T)) == 0
        n_buf > 1 && bytes_buf % Base.Mmap.PAGESIZE != 0 &&
            error("bytes per buffer must be a multiple of Base.Mmap.PAGESIZE when ",
                  "there is more than one buffer.")

        backing = T(div(bytes_buf * n_buf, sizeof(eltype(T))))
        Integer(pointer(backing)) % Base.Mmap.PAGESIZE != 0 &&
            error("array type $T is not page-aligned.")

        return new{S,T}(bytes_buf, n_buf, backing)
    end
end
DMABufferVector(::Type{T}, bytes_buf::Integer, n_buf::Integer) where {S, T<:AbstractVector{S}} =
    DMABufferVector{Ptr{S}, T}(bytes_buf, n_buf)

### DMABufferVector interface

bytespersample(buf_array::DMABufferVector{Ptr{T}}) where {T} = sizeof(T)
sampletype(buf_array::DMABufferVector{Ptr{T}}) where {T} = T

### AbstractArray methods

Base.size(dma::DMABufferVector) = (dma.n_buf,)
Base.IndexStyle(::Type{<:DMABufferVector}) = Base.IndexLinear()
Base.getindex(dma::DMABufferVector, i::Int) =
    pointer(dma.backing) + (i-1) * dma.bytes_buf
Base.length(dma::DMABufferVector) = dma.n_buf

## PageAlignedArray definitions

"""
    mutable struct PageAlignedArray{T,N} <: AbstractArray{T,N}

An `N`-dimensional array of eltype `T` which is guaranteed to have its memory be page-aligned.

This has to be a mutable struct because finalizers are used to clean up the memory allocated
by C calls when there remain no references to the PageAlignedArray object in Julia.
"""
mutable struct PageAlignedArray{T,N} <: AbstractArray{T,N}
    backing::Array{T,N}
    addr::Ptr{T}

    PageAlignedArray{T,0}() where {T} = PageAlignedArray{T,0}(())
    PageAlignedArray{T,1}(a::Integer) where {T} = PageAlignedArray{T,1}((a,))
    PageAlignedArray{T,2}(a::Integer, b::Integer) where {T} = PageAlignedArray{T,0}((a,b))
    PageAlignedArray{T,3}(a::Integer, b::Integer, c::Integer) where {T} =
        PageAlignedArray{T,3}((a,b,c))

    function PageAlignedArray{T,N}(dims::NTuple{N,Integer}) where {T,N}
        n = N == 0 ? 1 : reduce(*, dims)
        addr = virtualalloc(sizeof(T) * n, T)
        backing = unsafe_wrap(Array, addr, dims, false)
        array = new{T,N}(backing, addr)
        finalizer(array, x->virtualfree(x.addr))
        return array
    end
end
PageAlignedArray{T}(dims::Integer...) where {T} = PageAlignedArray{T,length(dims)}(dims)
const PageAlignedVector{T} = PageAlignedArray{T,1}

Base.size(A::PageAlignedArray) = size(A.backing)
Base.IndexStyle(::Type{<:PageAlignedArray}) = Base.IndexLinear()
Base.getindex(A::PageAlignedArray, idx...) = A.backing[idx...]
Base.setindex!(A::PageAlignedArray, v, idx...) = setindex!(A.backing, v, idx...)
Base.length(A::PageAlignedArray) = length(A.backing)
Base.unsafe_convert(::Type{Ptr{T}}, A::PageAlignedArray{T}) where {T} =
    Base.unsafe_convert(Ptr{T}, A.backing)

"""
    virtualalloc(size_bytes::Integer, ::Type{T}) where {T}

Allocate page-aligned memory and return a `Ptr{T}` to the allocation. The caller is
responsible for de-allocating the memory using `virtualfree`, otherwise it will leak.
"""
function virtualalloc(size_bytes::Integer, ::Type{T}) where {T}
    @static is_windows() ? begin
        MEM_COMMIT = 0x1000
        PAGE_READWRITE = 0x4
        addr = ccall((:VirtualAlloc, "Kernel32"), Ptr{T},
            (Ptr{Void}, Culonglong, Culong, Culong),
            C_NULL, size_bytes, MEM_COMMIT, PAGE_READWRITE)
    end : @static is_linux() ? begin
        addr = ccall((:valloc, linux_libc), Ptr{T}, (Culonglong,), size_bytes)
    end : @static is_apple() ? begin
        addr = ccall((:valloc, "libSystem.dylib"), Ptr{T}, (Culonglong,), size_bytes)
    end : throw(SystemError())

    addr == C_NULL && throw(OutOfMemoryError())
    return addr::Ptr{T}
end

"""
    virtualfree(addr::Ptr{T}) where {T}

Free memory that has been allocated using `virtualalloc`. Undefined, likely very bad
behavior if called on a pointer coming from elsewhere.
"""
function virtualfree(addr::Ptr{T}) where {T}
    @static is_windows() ? begin
        MEM_RELEASE = 0x8000
        return ccall((:VirtualFree, "Kernel32"), Cint, (Ptr{Void}, Culonglong, Culong),
            addr, 0, MEM_RELEASE)
    end : @static is_linux() ? begin
        return ccall((:free, linux_libc), Void, (Ptr{Void},), addr)
    end : @static is_apple() ? begin
        return ccall((:free, "libSystem.dylib"), Void, (Ptr{Void},), addr)
    end : error("OS not supported")
end
