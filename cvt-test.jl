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
using CairoMakie: RGB

path = "./result/testdata/"

D = 2
N = 10000
k_max = 25000

cvt_vorn_data_update = 1
LOW, UPP = -5.12, 5.12

seed   = Int(Dates.now().instant.periods.value)
rng    = StableRNG(seed)

points = [rand(rng, D) .* (UPP - LOW) .+ LOW for _ in 1:k_max - 4]
append!(points, [[UPP, UPP], [UPP, LOW], [LOW, UPP], [LOW, LOW]])

# vorn = centroidal_smooth(voronoi(triangulate(points; rng), clip = false); maxiters = 1000, rng = rng)
# save("$(path)CVT-cvttest-$(cvt_vorn_data_update).jld2", "voronoi", vorn)

# load_vorn = load("$(path)CVT-cvttest-$(cvt_vorn_data_update).jld2", "voronoi")
load_vorn = load("$(path)CVT-test-1-0.jld2", "voronoi")
load_centroids = DelaunayTriangulation.get_polygon_points(load_vorn)
load_vertices  = DelaunayTriangulation.get_generators(load_vorn)

cellFitness = Dict{Int, Float64}(key => 0.0 for key in 1:k_max)
instances = Dict{Int, Vector{Float64}}()

for _ in 1:N
    instance  = rand(rng, D) .* (UPP - LOW) .+ LOW
    benchmark = sum((instance .- 0) .^ 2)
    fitness   = benchmark > 0 ? 1.0 / (1.0 + benchmark) : 1.0 + abs(benchmark)
    
    distances = [norm(instance .- centroid, 2) for centroid in values(load_vertices)]
    closest_centroid_index = argmin(distances)
    
    cellFitness[closest_centroid_index] = fitness
    instances[closest_centroid_index] = instance
end

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
    color = :white,
    strokewidth = 0.01,
    show_generators = false,
    clip = (LOW, UPP, LOW, UPP)
)

colormap = cgrad(:viridis)

scatter!(
    ax, 
    [instance[1] for instance in values(instances)], 
    [instance[2] for instance in values(instances)], 
    color = [(colormap[round(Int, cellFitness[key] * 255) + 1], 0.5 * (cellFitness[key])^(1/2) + 0.4) for key in keys(instances)], 
    markersize = [(2 * (cellFitness[key])^(1/2) + 4) for key in keys(instances)]
)

Colorbar(
    fig[1, 2],
    limits   = (0.0, 1.0),
    ticks    = 0:0.25:1.0,
    colormap = :viridis,
    label    = "Evaluation value"
)

resize_to_layout!(fig)

mkpath("./result/testdata/pdf")
save("./result/testdata/pdf/output_graph.pdf", fig)
