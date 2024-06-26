## Fuselage example
using AeroFuse
using Plots

# Fuselage parameters
l_fuselage = 18. # Length (m)
h_fuselage = 1.5 # Height (m)
w_fuselage = 1.8 # Width (m)

## Hyperelliptic fuselage
fuse = HyperEllipseFuselage(
    radius = w_fuselage / 2,
    length = l_fuselage,
    c_nose = 2,
    c_rear = 2,
)

ts = 0:0.1:1                # Distribution of sections
S_f = wetted_area(fuse, ts) # Surface area, m²
V_f = volume(fuse, ts)      # Volume, m³

## Plot
plot(fuse, 
    aspect_ratio = 1, 
    zlim = (-0.5, 0.5) .* fuse.length,
    label = "Fuselage"
)

## Chordwise locations and corresponding radii
lens = [0.0, 0.005, 0.01, 0.03, 0.1, 0.2, 0.4, 0.6, 0.7, 0.8, 0.98, 1.0]
rads = [0.05, 0.15, 0.25, 0.4, 0.8, 1., 1., 1., 1., 0.85, 0.3, 0.01] * w_fuselage / 2

fuse = Fuselage(l_fuselage, lens, rads, [0., 0., 0.])

## Plotting
plot(fuse, aspect_ratio = 1, zlim = (-10,10))