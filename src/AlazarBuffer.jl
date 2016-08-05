export DMABufferArray

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
type DMABufferArray{sample_type} <: AbstractArray{Ptr{sample_type},1}

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

bytespersample{T}(buf_array::DMABufferArray{T}) = sizeof(T)
sampletype{T}(buf_array::DMABufferArray{T}) = T

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
