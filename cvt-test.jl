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

load_vorn     = load("$(path)CVT-cvttest-$(cvt_vorn_data_update).jld2", "voronoi")
load_controid = DelaunayTriangulation.get_generators(load_vorn)
load_polygon  = DelaunayTriangulation.get_polygons(load_vorn)

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

cellFitness = Dict{Int, Float64}(Int(key) => 0.0 for key in keys(load_polygon))
instances = Dict{Int, Vector{Float64}}()
colormap = ColorSchemes.viridis

function map_fitness_to_color(fitness::Dict{Int, Float64}, colormap)
    min_val, max_val = 0.0, 1.0
    range_val = 1.0 / (length(colormap.colors) - 1)
    
    return Dict(key => colormap.colors[round(Int, (value - min_val) / (max_val - min_val) / range_val) + 1] for (key, value) in fitness)
end

for _ in 1:N
    instance  = rand(rng, D) .* (UPP - LOW) .+ LOW
    benchmark = sum((instance .- 0) .^ 2)
    fitness   = benchmark > 0 ? 1.0 / (1.0 + benchmark) : 1.0 + abs(benchmark)
    
    distances = [norm([instance[1] - centroid[1], instance[2] - centroid[2]], 2) for centroid in values(load_polygon)]
    closest_centroid_index = argmin(distances)
    
    cellFitness[closest_centroid_index] = fitness
    instances[closest_centroid_index]   = instance
end

colors = map_fitness_to_color(cellFitness, colormap)
polygon_colors = [colors[i] for i in 1:k_max]

voronoiplot!(
    ax, 
    load_vorn,
    color = polygon_colors,
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

for (index, instance) in instances
    scatter!(ax, [instance[1]], [instance[2]], color = :black, markersize = 10)
    text!(ax, [instance[1]], [instance[2]], text = @sprintf("%.4f", cellFitness[index]), align = (:center, :bottom), color = :black)
end

resize_to_layout!(fig)

mkpath("./result/testdata/pdf")
save("./result/testdata/pdf/output_graph.pdf", fig)
