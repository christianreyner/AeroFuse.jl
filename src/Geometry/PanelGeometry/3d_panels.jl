## 3D Panels
#==========================================================================================#
abstract type AbstractPanel3D <: AbstractPanel end

"""
    Panel3D(p1, p2, p3, p4)

Four Cartesian coordinates `p1, p2, p3, p4` representing corners of a panel in 3 dimensions. The following commutative diagram (math joke) depicts the order:

```
z → y
↓
x
        p1 —→— p4
        |       |
        ↓       ↓
        |       |
        p2 —→— p3
```
"""
struct Panel3D{T <: Real} <: AbstractPanel3D
    p1 :: SVector{3,T}
    p2 :: SVector{3,T}
    p3 :: SVector{3,T}
    p4 :: SVector{3,T}
end

Panel3D(p1, p2, p3, p4) = let T = promote_type(eltype(p1), eltype(p2), eltype(p3), eltype(p4)); Panel3D{T}(p1, p2, p3, p4) end

Panel3D((p1, p2, p3, p4)) = Panel3D(p1, p2, p3, p4)

## Some algebraic operations on Panel3D
+(p :: AbstractPanel3D, v) = Panel3D(p.p1 + v, p.p2 + v, p.p3 + v, p.p4 + v)
-(p :: AbstractPanel3D, v) = Panel3D(p.p1 - v, p.p2 - v, p.p3 - v, p.p4 - v)
×(p :: AbstractPanel3D, v) = Panel3D(p.p1 × v, p.p2 × v, p.p3 × v, p.p4 × v)
(trans::AffineMap)(p::Panel3D) = Panel3D(trans(p.p1), trans(p.p2), trans(p.p3), trans(p.p4))

Base.length(:: Panel3D) = 1

average_chord(panel :: Panel3D) = (p2(panel) - p1(panel) + p3(panel) - p4(panel)) / 2
average_width(panel :: Panel3D) = (p4(panel) - p1(panel) + p3(panel) - p2(panel)) / 2

"""
    panel_coordinates(panel :: Panel3D)

Compute the coordinates of a `Panel3D`.
"""
panel_coordinates(panel :: Panel3D) = SVector( p1(panel), p2(panel), p3(panel), p4(panel) )

"""
    make_panels(xyzs)

Convert an array of coordinates corresponding to a wing, ordered from root to tip and leading-edge to trailing-edge, into panels.
"""
make_panels(xyzs :: AbstractArray{<: SVector{3,<: Real}}) = @views Panel3D.(xyzs[1:end-1,1:end-1], xyzs[2:end,1:end-1], xyzs[2:end,2:end], xyzs[1:end-1,2:end])

"""
    transform(panel :: Panel3D, rotation, translation)

Perform an affine transformation on the coordinates of a `Panel3D` given a rotation matrix and translation vector.
"""
function transform(panel :: Panel3D, rotation, translation) 
    T = Translation(translation) ∘ LinearMap(rotation)
    Panel3D(T(panel.p1), T(panel.p2), T(panel.p3), T(panel.p4))
end

"""
    midpoint(panel :: Panel3D)

Compute the midpoint of a `Panel3D`.
"""
midpoint(panel :: Panel3D) = (p1(panel) + p2(panel) + p3(panel) + p4(panel)) / 4

"""
    panel_normal(panel :: Panel3D)

Compute the normal vector of a `Panel3D`.
"""
panel_normal(panel :: Panel3D) = let p31 = p3(panel) - p1(panel), p42 = p4(panel) - p2(panel); p31 × p42 end

"""
    transform_normal(panel :: Panel3D, h_l, g_l)

Transform the normal vector ``n̂₀`` of a `Panel3D` about the hinge axis ``ĥₗ`` by the control gain ``gₗ``.

The transformation is the following: ``n̂ₗ = gₗ ĥₗ × n̂₀`` (FVA, Drela, 6.36).
"""
transform_normal(panel :: Panel3D, h_l, g_l) = g_l * cross(h_l, panel_normal(panel))

"""
    panel_area(panel :: Panel3D)

Compute the (possibly non-planar, hence nonsensical) area of a `Panel3D`.
"""
panel_area(panel :: Panel3D) = 1/2 * norm(panel_normal(panel)) # (norm ∘ cross)(average_chord(panel), average_width(panel))

"""
    wetted_area(panels :: Array{Panel3D})

Compute the total wetted area by summing the areas of an array of `Panel3D`.
"""
wetted_area(panels) = sum(panel -> panel_area(panel), panels)

"""
    reflect_xz(panel :: Panel3D)

Reflect a Panel3D with respect to the ``x``-``z`` plane of its reference coordinate system.
"""
reflect_xz(panel :: Panel3D) = Panel3D((reflect_xz ∘ p1)(panel), (reflect_xz ∘ p2)(panel), (reflect_xz ∘ p3)(panel), (reflect_xz ∘ p4)(panel))

# Compute local axis coordinates
function local_coordinate_system(stream, normie) 
    s_hat = normalize(stream)
    n_hat = normalize(normie)
    c_hat = s_hat × n_hat

    reduce(hcat, @SMatrix [ c_hat; s_hat; n_hat ])
end

# Compute local axis coordinates
local_coordinate_system(panel :: Panel3D) = local_coordinate_system((panel.p4 - panel.p1 + panel.p3 - panel.p2) / 2, panel_normal(panel))

collocation_point(panel :: AbstractPanel3D) = midpoint(panel)

"""
    transform_panel(panel :: AbstractPanel3D, point :: Point3D) -> panel :: AbstractPanel3D, point :: Point3D

Transform point and panel from GCS into panel LCS.
"""
function transform_panel(panel :: AbstractPanel3D, point :: Point3D)
    # Translate p1 to xy plane
    tr1 = Translation(0., 0., -panel.p1.z)
    local_panel = tr1(panel)
    local_point = tr1(point)

    # Find normal of panel
    n = panel_normal(panel)

    # Find rotation axis
    d = n × SVector(0.,0.,1.)

    # No rotation if already aligned
    if norm(d) <= 1e-7
        return local_panel, local_point
    end

    # Find rotation angle
    θ = acos(n.z / norm(n))
    tr2 = recenter(LinearMap(AngleAxis(θ, d.x, d.y, d.z)), local_panel.p1)

    local_panel = tr2(local_panel)
    local_point = tr2(local_point)

    # tr = tr1 ∘ tr2
    # invtr = inv(tr)

    return local_panel, local_point
end


"""
	get_transformation(panel :: AbstractPanel3D) -> tr :: AffineMap

Calculate required transformation from GCS to panel LCS.
"""
function get_transformation(panel :: AbstractPanel3D)
    # Translate p1 to xy plane
	p1 = panel.p1
    tr1 = Translation(0., 0., -p1.z)

    # Find normal of panel
    n = panel_normal(panel)

    # Find rotation axis
    d = n × SVector(0.,0.,1.)

    # No rotation if already aligned
    if norm(d) <= 1e-7
        return local_panel, local_point
    end

    # Find rotation angle
    θ = acos(n.z / norm(n))
    tr2 = recenter(LinearMap(AngleAxis(θ, d.x, d.y, d.z)), tr1(p1))

    return tr1 ∘ tr2
end