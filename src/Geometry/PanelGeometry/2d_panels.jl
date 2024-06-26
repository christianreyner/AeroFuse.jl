
## 2D Panels
#==========================================================================================#

abstract type AbstractPanel2D <: AbstractPanel end

struct Panel2D{T <: Real} <: AbstractPanel2D
    p1 :: SVector{2,T}
    p2 :: SVector{2,T}
end

struct WakePanel2D{T <: Real} <: AbstractPanel2D
    p1 :: SVector{2,T}
    p2 :: SVector{2,T}
end

Base.length(:: Panel2D) = 1

Panel2D(x1, y1, x2, y2) = Panel2D(SVector(x1, y1), SVector(x2, y2))
Panel2D(p1 :: FieldVector{2,T}, p2 :: FieldVector{2,T}) where T <: Real = Panel2D{T}(p1, p2)
WakePanel2D(p1 :: FieldVector{2,T}, p2 :: FieldVector{2,T}) where T <: Real = WakePanel2D{T}(p1, p2)

a :: AbstractPanel2D + b :: AbstractPanel2D = Panel2D(p1(a) + p1(b), p2(a) + p2(b))
a :: AbstractPanel2D - b :: AbstractPanel2D = Panel2D(p1(a) - p1(b), p2(a) - p2(b))

collocation_point(panel :: AbstractPanel2D, a = 0.5) = a * (panel.p1 + panel.p2)
panel_vector(panel :: AbstractPanel2D) = panel.p2 - panel.p1
panel_length(panel :: AbstractPanel2D) = (norm ∘ panel_vector)(panel)

function transform_panel_points(panel_1 :: AbstractPanel2D, panel_2 :: AbstractPanel2D)
    x1, y1, x2, y2 = panel_2.p1, panel_2.p2
    xs, ys = panel_1.p1

    xp1, yp1 = affine_2D(x1, y1, xs, ys, panel_angle(panel_1))
    xp2, yp2 = affine_2D(x2, y2, xs, ys, panel_angle(panel_1))

    return xp1, yp1, xp2, yp2
end

transform_panel(panel :: AbstractPanel2D, x, y) = affine_2D(x, y, panel.p1..., panel_angle(panel))

transform_panel(panel :: AbstractPanel2D, point :: SVector{2,<: Real}) = transform_panel(panel, point.x, point.y)

function panel_angle(panel :: AbstractPanel2D)
    (x, y) = panel_vector(panel)
    return atan(y, x)
    # ifelse(θ < 0., θ + 2π, θ) # Branch cut
end

panel_normal(panel :: AbstractPanel2D) = let (x, y) = panel_vector(panel); normalize([-y; x]) end

tangent_vector(panel :: AbstractPanel2D) = panel.p2 - panel.p1 # rotation(1., 0., -panel_angle(panel))

normal_vector(panel :: AbstractPanel2D) = let t = tangent_vector(panel); [ t[2]; -t[1] ] end # inverse_rotation(0., 1., panel_angle(panel))

panel_location(panel :: AbstractPanel2D) = let angle = panel_angle(panel); ifelse((π/2 <= angle <= π) || (-π <= angle <= -π/2), "lower", "upper") end

panel_points(panels) = [ p1.(panels); [(p2 ∘ last)(panels)] ]

reverse_panel(panel :: AbstractPanel2D) = Panel2D(panel.p2, panel.p1)

trailing_edge_panel(panels) = Panel2D((p2 ∘ last)(panels), (p1 ∘ first)(panels))

bisector(f_pan, l_pan) = (normalize(panel_vector(l_pan)) + normalize(-panel_vector(f_pan))) / 2

function trailing_edge_info(panels)
    # Make trailing edge
    te_panel  = trailing_edge_panel(panels)
    s    = panel_vector(reverse_panel(te_panel))
    p    = normalize(s)

    t1 = -normalize(panel_vector(panels[1]))
    t2 = normalize(panel_vector(panels[end]))
    t  = normalize((t1 + t2) / 2)

    h_TE = -s[1] * t[2] + s[2] * t[1]
    tcp  = abs(t[1] * p[2] - t[2] * p[1])
    tdp  = dot(p, t)
    dtdx = t1[1] * t2[2] - t2[1] * t1[2]

    return te_panel, h_TE, tcp, tdp, dtdx
end

function wake_panel(panels, bound, α)
    _, firsty        = (p1 ∘ first)(panels)
    firstx, firsty   = (p1 ∘ first)(panels)
    lastx, lasty     = (p2 ∘ last)(panels)
    y_mid            = (firsty + lasty) / 2
    y_bound, x_bound = bound .* sincos(α)
    return WakePanel2D(SVector(lastx, y_mid), SVector(x_bound * lastx, y_bound * y_mid))
end

function wake_panels(panels, chord, length, num)
    _, firsty = (p1 ∘ first)(panels)
    _, lasty  = (p2 ∘ last)(panels)
    y_mid     = (firsty + lasty) / 2
    bounds    = sine_spacing(chord + length / 2, length, num)
    return @. WakePanel2D(SVector(bounds[1:end-1], y_mid), SVector(bounds[2:end], y_mid))
end

function panel_scalar(scalar_func, strength, panel :: AbstractPanel2D, x, y)
    # Transform point to local panel coordinates
    xp, yp = transform_panel(panel, SVector(x, y))
    return scalar_func(strength, xp, yp, 0., panel_length(panel))
end

function panel_scalar(scalar_func, strength, panel_j :: AbstractPanel2D, panel_i :: AbstractPanel2D, point = 0.5)
    x, y = collocation_point(panel_i, point)
    return panel_scalar(scalar_func, strength, panel_j, x, y)
end

function panel_velocity(velocity_func, strength, panel :: AbstractPanel2D, x, y)
    # Transform point to local panel coordinates
    xp, yp = transform_panel(panel, SVector(x, y))

    # Compute velocity in local panel coordinates
    u, w = velocity_func(strength, xp, yp, 0., panel_length(panel))

    # Transform velocity to original coordinates
    return inverse_rotation(u, w, panel_angle(panel))
end

function panel_velocity(velocity_func, strength, panel_j :: AbstractPanel2D, panel_i :: AbstractPanel2D, point = 0.5)
    x, y = collocation_point(panel_i, point)
    u, w = panel_velocity(velocity_func, strength, panel_j, x, y)

    return u, w
end

panel_velocity(f1, f2, str1, str2, panel :: AbstractPanel2D, x, y) = panel_velocity(f1, str1, panel, x, y) + panel_velocity(f2, str2, panel, x, y)

panel_velocity(f1, f2, str_j1, str_j2, panel_j :: AbstractPanel2D, panel_i :: AbstractPanel2D) = panel_velocity(f1, str_j1, panel_j, panel_i) .+ panel_velocity(f2, str_j2, panel_j, panel_i)

get_surface_values(panels, vals, surf = "upper", points = false) = partition(x -> (panel_location ∘ first)(x) == surf, (collect ∘ zip)(panels[2:end], vals), x -> ((first ∘ ifelse(points, p1, collocation_point) ∘ first)(x), last(x)))
