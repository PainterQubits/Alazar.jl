using Alazar
using Base.Test

@test Alazar.alazar_exception(512) == "ApiNoError"
@test Alazar.alazar_exception(579) == "ApiWaitTimeout"

p = PageAlignedVector{Int}(512)
@test eltype(p) == Int
@test Integer(pointer(p)) % Base.Mmap.PAGESIZE == 0
@test (p[:] = 1) == 1
@test all(p .== 1)
@test length(p) == 512
@test size(p) == (512,)
@test Base.IndexStyle(p) == Base.IndexLinear()

# Should assert n_buf >= 0
@test_throws AssertionError DMABufferVector(PageAlignedVector{Int}, -1, 10)

# Should assert bytes_buf * n_buf % sizeof(eltype(T)) == 0
@test_throws AssertionError DMABufferVector(PageAlignedVector{Int}, 3, 3)

# Should throw an error if bytes_buf % Base.Mmap.PAGESIZE != 0 && n_buf > 1
@test_throws ErrorException DMABufferVector(PageAlignedVector{Int}, 64, 10)

# Should throw an error if a non-page-aligned AbstractVector type is used.
# However, sometimes a Vector may be page-aligned, by chance. Not sure how to ensure
# this test will pass in general.
# @test_throws ErrorException DMABufferVector(Vector{Int}, 512, 1)

# Should throw an error if anything but an AbstractVector type is used.
@test_throws MethodError DMABufferVector(Array{Int,2}, 512, 1)
@test_throws MethodError DMABufferVector(Array{Int}, 512, 1)

dma = DMABufferVector(PageAlignedVector{Int}, Base.Mmap.PAGESIZE, 10)
@test eltype(dma) == Ptr{Int}
@test length(dma) == 10
@test size(dma) == (10,)
@test Base.IndexStyle(dma) == Base.IndexLinear()
