import Base: Float16, Float32, Float64, BigFloat

struct Double{T, E<:Emphasis} <: AbstractDouble{T}
    hi::T
    lo::T
end

@inline hi(x::Double{T,E}) where {T,E<:Emphasis} = x.hi
@inline lo(x::Double{T,E}) where {T,E<:Emphasis} = x.lo

@inline hi(x::T) where {T<:AbstractFloat} = x
@inline lo(x::T) where {T<:AbstractFloat} = zero(T)

# initializers

Double() = Double{Float64, Accuracy}(zero(Float64), zero(Float64))
Double(::Type{Accuracy}) = Double{Float64, Accuracy}(zero(Float64), zero(Float64))
Double(::Type{Performance}) = Double{Float64, Performance}(zero(Float64), zero(Float64))
Double(::Type{Accuracy}, hi::T) where {T<:AbstractFloat} = Double{T, Accuracy}(hi, zero(T))
Double(::Type{Performance}, hi::T) where {T<:AbstractFloat} = Double{T, Performance}(hi, zero(T))
Double(::Type{Accuracy}, hi::T, lo::T) where {T<:AbstractFloat} = Double{T, Accuracy}(hi, lo)
Double(::Type{Performance}, hi::T, lo::T) where {T<:AbstractFloat} = Double{T, Performance}(hi, lo)

Double(x::T) where {T<:AbstractFloat} =
    Double{Float64, Accuracy}(Float64(x), zero(Float64))
Double(x::T, y::T) where {T<:AbstractFloat} =
    Double{Float64, Accuracy}(add_(Float64(x), Float64(y))...,)
Double(x::T) where {T<:String} =
    Double{Float64, Accuracy}(Float64(x), zero(Float64))

for T in (:Float64, :Float32, :Float16)
  @eval begin
    $T(x::Double{$T, E}) where E<:Emphasis = x.hi
  end
end    
Float32(x::Double{Float64, E}) where E<:Emphasis = Float32(x.hi)
Float16(x::Double{Float64, E}) where E<:Emphasis = Float16(x.hi)
Float16(x::Double{Float32, E}) where E<:Emphasis = Float16(x.hi)

function BigFloat(x::Double{T, E}, p=precision(BigFloat)) where {T<:AbstractFloat, E<:Emphasis}
    BigFloat(x.hi, p) + BigFloat(x.lo, p)
end

function Double{T, E}(x::BigFloat) where {T<:AbstractFloat, E<:Emphasis}
    hi = T(x)
    lo = T(x-hi)
    return Double{T, E}(hi, lo)
end

FastDouble() = Double{Float64, Performance}(zero(Float64), zero(Float64))
FastDouble(x::T) where {T<:AbstractFloat} =
    Double{Float64, Performance}(x, zero(Float64))
FastDouble(x::T, y::T) where {T<:AbstractFloat} =
    Double{Float64, Performance}(add_(x, y)...,)

FastDouble(x::T) where {T<:Real} =
    FastDouble{Float64, Performance}(Float64(x), zero(Float64))
FastDouble(x::T, y::T) where {T<:Real} =
    FastDouble{Float64, Performance}(add_(convert(Float64,x), convert(Float64,y))...,)

# a fast type specific hash function helps
import Base: hash, hx, fptoui

const hash_doublefloat_lo = (UInt === UInt64) ? 0x9bad5ebab034fe78 : 0x72da40cb
const hash_0_dfloat_lo = hash(zero(UInt), hash_doublefloat_lo)
const hash_accuracy_lo = hash(hash(Accuracy), hash_doublefloat_lo)
const hash_performance_lo = hash(hash(Performance), hash_doublefloat_lo)

function hash(x::Double{T,Accuracy}, h::UInt) where {T}
    !isnan(hi(x)) ? 
       ( iszero(lo(x)) ? 
            hx(fptoui(UInt64, abs(hi(x))), hi(x), h ⊻ hash_accuracy_lo) :
            hx(fptoui(UInt64, abs(hi(x))), lo(x), h ⊻ hash_accuracy_lo)  
       ) : (hx_NaN ⊻ h)
end

function hash(x::Double{T,Performance}, h::UInt) where {T}
    !isnan(hi(x)) ? 
       ( iszero(lo(x)) ? 
            hx(fptoui(UInt64, abs(hi(x))), hi(x), h ⊻ hash_performance_lo) :
            hx(fptoui(UInt64, abs(hi(x))), lo(x), h ⊻ hash_performance_lo)  
       ) : (hx_NaN ⊻ h)
end


include("val_isa_cmp.jl")
include("string_show.jl")
