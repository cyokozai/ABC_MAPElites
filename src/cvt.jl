#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
#       CVT: Centroidal Voronoi Tessellations                                                        #
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#

using DelaunayTriangulation

using LinearAlgebra

using StableRNGs

using FileIO

using JLD2

using Dates

#----------------------------------------------------------------------------------------------------#

include("config.jl")

include("struct.jl")

include("logger.jl")

#----------------------------------------------------------------------------------------------------#
# Voronoi diagram
vorn = nothing

# Voronoi data update
cvt_vorn_data_update = 0

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
# Initialize the CVT
function init_CVT(population::Population)
    global vorn, cvt_vorn_data_update
    
    points   = [rand(RNG, BD) .* (UPP - LOW) .+ LOW for _ in 1:k_max - (N + 4)]
    behavior = [population.individuals[i].behavior for i in 1:N]
    append!(points, behavior)
    append!(points, [[UPP, UPP], [UPP, LOW], [LOW, UPP], [LOW, LOW]])
    
    vorn = centroidal_smooth(voronoi(triangulate(points; rng = RNG), clip = false); maxiters = CVT_MAX_ITER, rng = RNG)
    save("$(output)$(METHOD)/$(OBJ_F)/CVT-$(FILENAME)-$(cvt_vorn_data_update).jld2", "voronoi", vorn)
    
    cvt_vorn_data_update += 1
    
    logger("INFO", "CVT is initialized")
    
    return DelaunayTriangulation.get_generators(vorn)::Dict{Int64, Tuple{Float64, Float64}}
end

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
# CVT mapping
function cvt_mapping(population::Population, archive::Archive)
    global vorn

    for ind in population.individuals
        distances = [norm([ind.behavior[1] - centroid[1], ind.behavior[2] - centroid[2]], 2) for centroid in values(DelaunayTriangulation.get_generators(vorn))]
        closest_centroid_index = argmin(distances)
        
        if haskey(archive.individuals, closest_centroid_index)
            if ind.benchmark[fit_index] < archive.individuals[closest_centroid_index].benchmark[fit_index]
                archive.individuals[closest_centroid_index] = Individual(deepcopy(ind.genes), ind.benchmark, deepcopy(ind.behavior))

                archive.grid_update_counts[closest_centroid_index] += 1
            end
        else
            archive.individuals[closest_centroid_index] = Individual(deepcopy(ind.genes), ind.benchmark, deepcopy(ind.behavior))

            archive.grid_update_counts[closest_centroid_index] += 1
        end
    end
    
    return archive
end

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
#                                                                                                    #
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#