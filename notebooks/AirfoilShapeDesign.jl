### A Pluto.jl notebook ###
# v0.14.4

using Markdown
using InteractiveUtils

# ╔═╡ 9c8e3e2e-4093-11eb-3e43-85d1fead00e5
begin
	
	using AeroMDAO
	using NLsolve
	using Plots
	gr()
end;

# ╔═╡ aa0d9882-4093-11eb-1038-f3aa407bb8e9
md"# Airfoil Shape Design"

# ╔═╡ a4f74210-4093-11eb-10b3-c3ec247080d3
md"## Surface Optimization"

# ╔═╡ b618f06e-4093-11eb-17af-f918c12aa8da
function optimize_CST(αs, α, n_upper :: Integer, le = 0.2)
    airfoil = (Foil ∘ kulfan_CST)(αs[1:n_upper], αs[n_upper+1:end], (0., 0.), le, 80)
    uniform = Uniform2D(1.0, α)
    cl = solve_case(airfoil, uniform)[1]
end

# ╔═╡ bc6f40f0-4093-11eb-30a1-17ffd1f0d74b
begin
	dzs = (0., 0.)
	α_u0 = [0.1, 0.1, 0.1, 0.1, 0.1]
	α_l0 = [-0.2, -0.1, -0.1, -0.1]
	α_ul0 = [α_u0; α_l0]

	n_upper = length(α_u0)  # Number of upper surface variables
	le = 0.2                # Leading edge modification
	α = 0.                  # Angle of attack
end

# ╔═╡ c5f9ba60-4093-11eb-0ea9-d5a3bf495234
CST_cl = optimize_CST(α_ul0, α, n_upper, le)

# ╔═╡ d7d91370-4093-11eb-0be4-01686a5cec7d
begin
	CST_test = kulfan_CST(α_u0, α_l0, dzs, le, 80)
	plot(first.(CST_test), last.(CST_test), 
		 label = "Initial Surface", aspectratio = 1)
end

# ╔═╡ 087e19f0-40f1-11eb-01b0-b9a3691c39ef
md"""
```math
\begin{gather}
\text{minimize} & |{C_L - C_{L_0}}| & \text{Target lift coefficient } C_{L_0} \\
\text{subject to} & \mathbf x & \text{Shape variables}
\end{gather}
```
"""

# ╔═╡ e34b0360-4108-11eb-085b-d11a73ecf61d
md"""### Banana Design"""

# ╔═╡ 57bc7c80-4094-11eb-3e8b-1b496ce43efb
cl0 = 0.5

# ╔═╡ 8264f5d0-40f2-11eb-378e-01f8cac5cc7c
target_cl = x -> (optimize_CST(x, α, n_upper, le) - cl0)^2

# ╔═╡ ec6e16a2-4093-11eb-1904-23cad91aff99
resi_CST = nlsolve(target_cl, 
					α_ul0,						# Initial value
					autodiff = :forward,
					xtol = 1e-8,
					store_trace = true,
					extended_trace = true)

# ╔═╡ 23c84ca7-2d21-4685-a6ff-53861390012b
lol = resi_CST.trace.states[1]

# ╔═╡ 0afe7d80-4094-11eb-0830-1d3a7e58c1db
CST_opt = kulfan_CST(resi_CST.zero[1:n_upper],
					 resi_CST.zero[n_upper+1:end], 
					 dzs, le, 80)

# ╔═╡ 7c0f7f7c-b79d-4832-ace5-42cdfb24d222
optimize_CST(resi_CST.zero, α, n_upper, le)

# ╔═╡ 52141ff0-5574-11eb-029f-1d882484e835
begin
	fig = plot(aspectratio = 1)
	plot!(first.(CST_test), last.(CST_test), 
			label = "Initial Surface")
	plot!(first.(CST_opt), last.(CST_opt), 
			label = "Optimal Surface")
end

# ╔═╡ 8ed3fdc0-4093-11eb-1743-332b9934cbf8
## Plot


## Optimization



## Plot

# savefig(fig, "_research/tmp/CST_surface.pdf")
                
## Optimal test
# CST_cl = optimize_CST(resi_CST.minimizer, α, n_upper)
# println("CST Cl: $CST_cl")

# ## Camber-thickness optimization
# #============================================#

# # Camber optimization
# function optimize_camber_CST(αs, α, num_cam)
#     airfoil = (Foil ∘ camber_CST)(αs[1:num_cam], αs[num_cam+1:end], (0., 0.), 0., 80)
#     uniform = Uniform2D(1.0, α)
#     cl = solve_case(airfoil, uniform, 80)
# end

# ## Test
# α_c0 = zeros(6)
# α_t0 = fill(0.4, 6)
# α_ct0 = [α_c0; α_t0]

# num_cam = length(α_c0)  # Number of camber variables
# α = 0.                  # Angle of attack
# cl0 = 1.2               # Target lift coefficient
# camber_cl = optimize_camber_CST(α_ct0, α, num_cam)
# println("Camber Cl: $camber_cl")

# ## Plot
# camber_test = camber_CST(α_ct0[1:num_cam], α_ct0[num_cam+1:end], (0., 0.), 0., 80)
# camthick_test = coordinates_to_camber_thickness(camber_test)
# plot(camber_test[:,1], camber_test[:,2], 
# 	label = "Initial Surface", aspectratio = 1)	
# # plot(camthick_test[:,1], camthick_test[:,2], 
# # 	label = "Initial Camber", aspectratio = 1)
# # plot!(camthick_test[:,1], camthick_test[:,3], 
# # 	label = "Initial Thickness", aspectratio = 1)

# ## Optimization
# l_bound = [ fill(-1e-12, length(α_c0)); [0.1, 0.12, 0.12, 0.05, 0.05, 0.05] ]
# u_bound = fill(Inf, length(α_ct0))

# resi_cam = optimize(x -> abs(optimize_camber_CST(x, α, num_cam) - cl0), 
# 					l_bound, u_bound,				# Bounds
# 					α_ct0,								# Initial value
# 					Fminbox(GradientDescent()),
# 					autodiff = :forward,
#                 	Optim.Options(
# 								#   extended_trace = true,
# 								  show_trace = true
# 								 )
# 					)

# ## Plot
# camber_opt = camber_CST(resi_cam.minimizer[1:num_cam], resi_cam.minimizer[num_cam+1:end], (0., 0.), 0., 80)

# surf_fig = plot(aspectratio = 1, dpi = 300)
# plot!(camber_test[:,1], camber_test[:,2], 
# 	label = "Initial Surface", aspectratio = 1)
# plot!(camber_opt[:,1], camber_opt[:,2], 
# 	label = "Optimal Surface for α = $α, Cl = $cl0")
# savefig(surf_fig, "_research/tmp/surface.pdf")

# ##
# camthick_opt = coordinates_to_camber_thickness(camber_opt)
# camthick_fig = plot(aspectratio = 1, dpi = 300)
# plot!(camthick_test[:,1], camthick_test[:,2], 
# 	label = "Initial Camber", aspectratio = 1)
# plot!(camthick_test[:,1], camthick_test[:,3], 
# 	label = "Initial Thickness", aspectratio = 1)
# plot!(camthick_opt[:,1], camthick_opt[:,2], 
# 	label = "Optimal Camber for α = $α, Cl = $cl0", aspectratio = 1)
# plot!(camthick_opt[:,1], camthick_opt[:,3], 
# 	label = "Optimal Thickness for α = $α, Cl = $cl0", aspectratio = 1)
# savefig(camthick_fig, "_research/tmp/camthick.pdf")
                
# ## Optimal test
# camber_cl = optimize_camber_CST(resi_cam.minimizer, α, num_cam)
# println("Camber Cl: $camber_cl")

# ╔═╡ Cell order:
# ╟─aa0d9882-4093-11eb-1038-f3aa407bb8e9
# ╠═9c8e3e2e-4093-11eb-3e43-85d1fead00e5
# ╟─a4f74210-4093-11eb-10b3-c3ec247080d3
# ╠═b618f06e-4093-11eb-17af-f918c12aa8da
# ╠═bc6f40f0-4093-11eb-30a1-17ffd1f0d74b
# ╠═c5f9ba60-4093-11eb-0ea9-d5a3bf495234
# ╠═d7d91370-4093-11eb-0be4-01686a5cec7d
# ╟─087e19f0-40f1-11eb-01b0-b9a3691c39ef
# ╠═8264f5d0-40f2-11eb-378e-01f8cac5cc7c
# ╠═ec6e16a2-4093-11eb-1904-23cad91aff99
# ╠═23c84ca7-2d21-4685-a6ff-53861390012b
# ╟─e34b0360-4108-11eb-085b-d11a73ecf61d
# ╠═0afe7d80-4094-11eb-0830-1d3a7e58c1db
# ╠═7c0f7f7c-b79d-4832-ace5-42cdfb24d222
# ╠═57bc7c80-4094-11eb-3e8b-1b496ce43efb
# ╠═52141ff0-5574-11eb-029f-1d882484e835
# ╟─8ed3fdc0-4093-11eb-1743-332b9934cbf8