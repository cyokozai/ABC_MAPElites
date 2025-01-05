#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
#       CVT: Centroidal Voronoi Tessellations                                                        #
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
using DelaunayTriangulation
using LinearAlgebra
using CairoMakie
using ColorSchemes
using StableRNGs
using JLD2
using Dates
using Printf

path = "./result/testdata/"

D = 2
N = 10
k_max = 10

cvt_vorn_data_update = 1
LOW, UPP = -5.12, 5.12

seed   = Int(Dates.now().instant.periods.value)
rng    = StableRNG(seed)

points = [rand(rng, D) .* (UPP - LOW) .+ LOW for _ in 1:k_max - 4]
append!(points, [[UPP, UPP], [UPP, LOW], [LOW, UPP], [LOW, LOW]])

vorn = centroidal_smooth(voronoi(triangulate(points; rng), clip = false); maxiters = 1000, rng = rng)
save("$(path)CVT-cvttest-$(cvt_vorn_data_update).jld2", "voronoi", vorn)

load_vorn = load("$(path)CVT-cvttest-$(cvt_vorn_data_update).jld2", "voronoi")
load_centroids = DelaunayTriangulation.get_generators(load_vorn)
centroid_values = collect(values(load_centroids))

fig = Figure()

ax = Axis(
    fig[1, 1], 
    limits = (-5.12, 5.12, -5.12, 5.12),
    xlabel = L"b_1", 
    ylabel = L"b_2",
    width  = 400, 
    height = 400
)

resize_to_layout!(fig)

voronoiplot!(
    ax, 
    load_vorn,
    colormap = :viridis,
    strokewidth = 0.01,
    show_generators = false,
    clip = (LOW, UPP, LOW, UPP)
)

Colorbar(
    fig[1, 2],
    limits   = (0.0, 1.0),
    ticks    = 0:0.25:1.0,
    colormap = :viridis,
    label    = "Evaluation value"
)

# for (index, instance) in instances
#     scatter!(ax, [instance[1]], [instance[2]], color = :black, markersize = 10)
#     text!(ax, [instance[1]], [instance[2]], text = @sprintf("%.4f", cellFitness[index]), align = (:center, :bottom), color = :black)
# end

resize_to_layout!(fig)

mkpath("./result/testdata/pdf")
save("./result/testdata/pdf/output_graph.pdf", fig)
