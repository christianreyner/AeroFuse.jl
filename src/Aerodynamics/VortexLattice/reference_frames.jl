## Reflections and projections
#==========================================================================================#

# Reflect the ``y``-coordinate of a given 3-dimensional vector about the ``x``-``z`` plane.
reflect_xz(vector) = SVector(vector[1], -vector[2], vector[3])


# Project a given 3-dimensional vector or into the ``y``-``z`` plane.
project_yz(vector) = SVector(0, vector[2], vector[3])

# Reflect the ``x``- and ``z``- coordinates of a given 3-dimensional vector about the ``y``-``z`` and ``x``-``y`` planes respectively for the representation in body axes.
flip_xz(vector) = SVector(-vector[1], vector[2], -vector[3])

## Axis transformations
#==========================================================================================#

geometry_to_body_axes(coords) = -coords

"""
    geometry_to_stability_axes(coords, α)

Convert coordinates from geometry to stability axes with angle ``α``.
"""
geometry_to_stability_axes(coords, α :: T) where T <: Real = RotY{T}(α) * coords

"""
    geometry_to_stability_axes(coords, α)

Convert coordinates from stability to geometry axes with angle ``α``.
"""
stability_to_geometry_axes(coords, α :: T) where T <: Real = geometry_to_stability_axes(coords, -α)

"""
    geometry_to_wind_axes(coords, α, β)
    geometry_to_wind_axes(vor :: AbstractVortex, α, β)

Convert coordinates from geometry axes to wind axes for given angles of attack ``α`` and sideslip ``\\beta.``
"""
geometry_to_wind_axes(coords, α, β) = let T = promote_type(eltype(α), eltype(β)); RotZY{T}(β, α) * coords end

function geometry_to_wind_axes(vortex :: AbstractVortex, α, β) 
    T = promote_type(eltype(α), eltype(β))
    return transform(vortex, LinearMap(RotZY{T}(β, α)))
end

geometry_to_wind_axes(coords, fs :: Freestream) = geometry_to_wind_axes(coords, fs.alpha, fs.beta)
geometry_to_wind_axes(vor :: AbstractVortex, fs :: Freestream) = geometry_to_wind_axes(vor, fs.alpha, fs.beta)

"""
    wind_to_geometry_axes(coords, α, β)
    wind_to_geometry_axes(vor :: AbstractVortex, α, β) 

Convert coordinates from wind axes to geometry axes for given angles of attack ``α`` and sideslip \\beta.``
"""
## Check order
function wind_to_geometry_axes(coords, α, β) 
    T = promote_type(eltype(α), eltype(β))
    return RotYZ{T}(-α, -β) * coords
end

function wind_to_geometry_axes(vor :: AbstractVortex, α, β) 
    T = promote_type(eltype(α), eltype(β))
    return transform(vor, LinearMap(RotYZ{T}(-α, -β)))
end


# function rotate_zy(θ₁, θ₂)
#     sinθ₁, cosθ₁ = sincos(θ₁)
#     sinθ₂, cosθ₂ = sincos(θ₂)
#     z            = zero(sinθ₁)

#     @SMatrix [ cosθ₁* cosθ₂  -sinθ₁  cosθ₁ * sinθ₂
#                sinθ₁* cosθ₂   cosθ₁  sinθ₁ * sinθ₂
#                  -sinθ₂         z        cosθ₂     ]
# end