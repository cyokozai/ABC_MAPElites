#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
#       CVT: Centroidal Voronoi Tessellations                                                        #
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#

using DelaunayTriangulation
using LinearAlgebra
using CairoMakie
using StableRNGs
using JLD2
using Dates

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#

path = "./result/testdata/"

LOW, UPP = -5.12, 5.12
D = 2
N = 50
k_max = 100
cvt_vorn_data_update = 1

seed   = Int(Dates.now().instant.periods.value)
rng    = StableRNG(seed)
points = [rand(rng, D) .* (UPP - LOW) .+ LOW for _ in 1:k_max - 4]

append!(points, [[UPP, UPP], [UPP, LOW], [LOW, UPP], [LOW, LOW]])

vorn = centroidal_smooth(voronoi(triangulate(points; rng), clip = false); maxiters = 1000, rng = rng)
Centroidal_point_list = DelaunayTriangulation.get_polygon_points(vorn)
Centroidal_polygon_list = DelaunayTriangulation.get_generators(vorn)

print(Centroidal_point_list)
println()
println(length(Centroidal_point_list))
print(Centroidal_polygon_list)
println()
println(length(Centroidal_polygon_list))

save("$(path)CVT-test-$(cvt_vorn_data_update)-voronoi.jld2", "voronoi", vorn)
save("$(path)CVT-test-$(cvt_vorn_data_update)-point.jld2", "point", Centroidal_point_list)
save("$(path)CVT-test-$(cvt_vorn_data_update)-polygon.jld2", "polygon", Centroidal_polygon_list)

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
load_vorn    = load("$(path)CVT-test-$(cvt_vorn_data_update)-voronoi.jld2", "voronoi")
load_point   = load("$(path)CVT-test-$(cvt_vorn_data_update)-point.jld2", "point")
load_polygon = load("$(path)CVT-test-$(cvt_vorn_data_update)-polygon.jld2", "polygon")

Data = zeros(Float64, N)

print(load_point)
println()
println(length(load_point))
println(maximum(load_point))
print(load_polygon)
println()
println(length(load_polygon))
println(maximum(load_polygon))

fig = Figure()
  
ax = Axis(
    fig[1, 1], 
    limits = ((-3, 3), (-3, 3)), 
    xlabel = L"b_1", 
    ylabel = L"b_2",
    width  = 400, 
    height = 400
)

resize_to_layout!(fig)

cellFitness = Dict{Int, Float64}(Int(key) => 0.0 for key in 1:k_max)
instances = Dict{Int, Vector{Float64}}()
colormap = cgrad(:viridis)
colors   = [colormap[1] for _ in 1:k_max]

for _ in 1:N
    instance  = rand(rng, D) .* (UPP - LOW) .+ LOW
    benchmark = sum((instance .- 0) .^ 2)
    fitness   = benchmark > 0 ? 1.0 / (1.0 + benchmark) : 1.0 + abs(benchmark)
    
    distances = [norm([instance[1] - centroid[1], instance[2] - centroid[2]], 2) for centroid in values(load_polygon)]
    closest_centroid_index = argmin(distances)

    cellFitness[closest_centroid_index] = fitness
    instances[closest_centroid_index] = instance
    colors[closest_centroid_index] = colormap[round(Int, fitness * (length(colormap) - 1) + 1)]
end

voronoiplot!(
    ax, 
    load_vorn,
    color = colors,
    strokewidth = 0.01,
    show_generators = false,
    clip = (LOW, UPP, LOW, UPP)
)

Colorbar(
    fig[1, 2],
    limits   = (0.0, 1.0),
    ticks    = 0:0.25:1.0,
    colormap = :viridis,
    highclip = :red,
    lowclip  = :white,
    label    = "Update frequency"
)

for (index, instance) in instances
    scatter!(ax, [instance[1]], [instance[2]], color = :black, markersize = 10)
end

resize_to_layout!(fig)

# PDFに保存するコード
mkpath("./result/testdata/pdf")
save("./result/testdata/pdf/output_graph.pdf", fig)

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#