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
D    = 2
kmax = 100
cvt_vorn_data_update = 1

seed   = Int(Dates.now().instant.periods.value)
rng    = StableRNG(seed)
points = [rand(rng, D) .* (UPP - LOW) .+ LOW for _ in 1:kmax]

append!(points, [[UPP, UPP], [UPP, LOW], [LOW, UPP], [LOW, LOW]])

vorn = centroidal_smooth(voronoi(triangulate(points; rng), clip = false); maxiters = 1000, rng = rng)
Centroidal_point_list = DelaunayTriangulation.get_polygon_points(vorn)
Centroidal_polygon_list = DelaunayTriangulation.get_generators(vorn)

save("$(path)CVT-test-$(cvt_vorn_data_update).jld2", "voronoi", vorn)
save("$(path)CVT-test-$(cvt_vorn_data_update).jld2", "point", Centroidal_point_list)
save("$(path)CVT-test-$(cvt_vorn_data_update).jld2", "polygon", Centroidal_polygon_list)

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#

# ファイルに保存されているキーを確認するコードを追加
file_keys = JLD2.jldopen("$(path)CVT-test-$(cvt_vorn_data_update).jld2") do file
    keys(file)
end
println("Keys in the file: ", file_keys)

# 正しいキーを使用するように修正
load_vorn    = load("$(path)CVT-test-$(cvt_vorn_data_update).jld2", "voronoi")
load_point   = load("$(path)CVT-test-$(cvt_vorn_data_update).jld2", "point")
load_polygon = load("$(path)CVT-test-$(cvt_vorn_data_update).jld2", "polygon")

fig = Figure()

ax = Axis(
    fig[1, 1], 
    limits = ((-3, 3), (-3, 3)), 
    xlabel = L"b_1", 
    ylabel = L"b_2",
    width = 400, 
    height = 400
)

voronoiplot!(
    ax, 
    load_vorn, 
    color = :white, 
    strokewidth = 1.0, 
    show_generators = true
)

resize_to_layout!(fig)

for _ in 1:50
    instance = rand(rng, D) .* (UPP - LOW) .+ LOW
    fitness  = sum((instance .- 0) .^ 2)
    
    distances = [norm([instance[1] - centroid[1], instance[2] - centroid[2]], 2) for centroid in Centroidal_point_list]
    closest_centroid_index = argmin(distances)
    closest_centroid = load_point[closest_centroid_index]
    
    println("The point $(instance) is closest to the centroid at $(closest_centroid), which corresponds to polygon index $(closest_centroid_index).")
    
    scatter!(ax, [instance[1]], [instance[2]], markersize = 20, color = :black)
end

Colorbar(
    fig[1, 2],
    limits = (0, maximum(Data)),
    ticks=(0:maximum(Data)/4:maximum(Data), string.([0, "", "", "", maximum(Data)])),
    colormap = :heat,
    highclip = :red,
    lowclip = :white,
    label = "Update frequency"
)

resize_to_layout!(fig)

# PDFに保存するコード
save("./result/testdata/pdf/output_graph.pdf", fig)

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#