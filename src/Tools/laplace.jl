module Laplace

using StaticArrays

"""
Solutions to Laplace's equation.
"""
abstract type AbstractLaplace end

# Performs velocity and potential calculations on a grid
function grid_data(objects :: AbstractVector{<: AbstractLaplace}, xs)
    vels = foldl((v1, v2) -> [ u .+ v for (u, v) ∈ zip(v1, v2) ], velocity(object, xs) for object ∈ objects)
    pots = foldl((v1, v2) -> v1 + v2, potential(object, xs) for object ∈ objects)
    
    vels, pots
end

# Performs velocity and potential computations for an object on a grid
grid_data(object :: AbstractLaplace, xs) = velocity(object, xs), potential(object, xs)
velocity(object :: AbstractLaplace, xs) = map(x -> velocity(object, x...), xs) 
potential(object :: AbstractLaplace, xs) = map(x -> potential(object, x...), xs)

struct Source2D{T <: Real} <: AbstractLaplace
    str :: T
    x0 :: T
    y0 :: T 
end

velocity(src :: Source2D, x, y) = SVector(src.str / (2π) * (x - src.x0) / ((x - src.x0)^2 + (y - src.y0)^2), str / (2π) * (y - src.y0) / ((x - src.x0)^2 + (y - src.y0)^2))
potential(src :: Source2D, x, y) = src.str / (4π) * log((x - src.x0)^2 + (y - src.y0)^2)
stream(src :: Source2D, x, y) = src.str / (2π) * atan(y - src.y0, x - src.x0)

struct Uniform2D{T <: Real} <: AbstractLaplace
    mag :: T
    ang :: T
    Uniform2D{T}(mag, ang) where T <: Real = new(mag, deg2rad(ang))
end

Uniform2D(mag :: T, ang :: T) where T <: Real = Uniform2D{T}(mag, ang)
Uniform2D(mag :: Real, ang :: Real) = Uniform2D(promote(mag, ang)...)

velocity(uni :: Uniform2D) = let (sa, ca) = sincos(uni.ang); uni.mag * SVector(ca, sa) end
potential(uni :: Uniform2D, x, y) = uni.mag * (x * cos(uni.ang) + y * sin(uni.ang))

struct Doublet2D{T <: Real} <: AbstractLaplace
    str :: T
    x0 :: T
    y0 :: T 
end 

velocity(dub :: Doublet2D, x, y) = SVector(dub.str / (2π) * ((x - dub.x0)^2 - (y - dub.y0)^2) / ((x - dub.x0)^2 + (y - dub.y0)^2)^2, - dub.str / (2π) * 2 * (x - dub.x0) * (y - dub.y0) / ((x - dub.x0)^2 + (y - dub.y0)^2)^2)
potential(dub :: Doublet2D, x, y) = -dub.str / (2π) * (y - dub.y0) / ((x - dub.x0)^2 + (y - dub.y0)^2)
stream(dub :: Doublet2D, x, y) = -dub.str / (2π) * (y - dub.y0) / ((x - dub.x0)^2 + (y - dub.y0)^2)

struct Vortex2D{T <: Real} <: AbstractLaplace
    str :: T
    x0 :: T
    y0 :: T 
end

velocity(vor :: Vortex2D, x, y) = SVector(-vor.str / (2π) * (y - vor.y0) / ((x - vor.x0)^2 + (y - vor.y0)^2), str / (2π) * (x - vor.x0) / ((x - vor.x0)^2 + (y - vor.y0)^2))
potential(vor :: Vortex2D, x, y) = vor.str / (2π) * atan(y - vor.y0, x - vor.x0)
stream(vor :: Vortex2D, x, y) = -vor.str / (4π) * log((x - vor.x0)^2 + (y - vor.y0)^2)


#------Integrated solutions in local panel coordinates for lumped distributions------#

source_potential(str :: Real, x :: Real, z :: Real, x1 :: Real, x2 :: Real) = str / (4π) * ((x - x1) * log((x - x1)^2 + z^2) - (x - x2) * log((x - x2)^2 + z^2) + 2z * (atan(z, x - x2) - atan(z, x - x1)))

source_velocity(str :: Real, x :: Real, z :: Real, x1 :: Real, x2 :: Real) = SVector(str / (4π) * log(((x - x1)^2 + z^2) / ((x - x2)^2 + z^2)), doublet_potential(str, x, z, x1, x2))

doublet_potential(str :: Real, x :: Real, z :: Real, x1 :: Real, x2 :: Real) = str / (2π) * (atan(z, x - x1) - atan(z, x - x2))

doublet_velocity(str :: Real, x :: Real, z :: Real, x1 :: Real, x2 :: Real) = SVector(str / (2π) * - (z / ((x - x1)^2 + z^2) - z / ((x - x2)^2 + z^2) ), str / (2π) * ( (x - x1) / ((x - x1)^2 + z^2) - (x - x2) / ((x - x2)^2 + z^2)))

# speed = norm ∘ velocity

## Freestream
#----------------------------------------------#

"""
A Freestream type expressing a freestream flow in spherical polar coordinates with angles α, β and magnitude mag.
"""
struct Freestream <: AbstractLaplace
    mag :: Real
    α :: Real 
    β :: Real
    Ω :: SVector{3, Real}
    Freestream(mag, α_deg, β_deg, Ω = SVector(0, 0, 0)) = new(mag, deg2rad(α_deg), deg2rad(β_deg), Ω)
end

"""
Converts freestream flow coordinates to Cartesian coordinates.
"""
freestream_to_cartesian(r, θ, φ) = r .* SVector(cos(θ) * cos(φ), -sin(φ), sin(θ) * cos(φ))

"""
Computes the velocity of Freestream.
"""
velocity(uni :: Freestream) = freestream_to_cartesian(uni.mag, uni.α, uni.β)

"""
Computes the velocity of Freestream in the aircraft reference frame.
"""
aircraft_velocity(uni :: Freestream) = -velocity(uni)

end