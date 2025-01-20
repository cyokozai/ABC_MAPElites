#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
#       DE: Differential Evolution                                                                   #
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#

using Statistics

using Random

#----------------------------------------------------------------------------------------------------#

include("config.jl")

include("struct.jl")

include("fitness.jl")

include("crossover.jl")

include("logger.jl")

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
# Differential Evolution algorithm
function DE(population::Population, archive::Archive)
    I_p, I_a = population.individuals, archive.individuals
    r1, r2, r3 = zeros(Int, 3)
    b = Tuple{Float64, Float64}[]
    
    print("DE")

    for i in 1:N
        while r1 == r2 || r1 == r3 || r2 == r3 || I_a[r1].genes == I_p[i].genes || I_a[r2].genes == I_p[i].genes || I_a[r3].genes == I_p[i].genes
            r1, r2, r3 = rand(RNG, keys(I_a), 3)
        end
        
        v = clamp.(I_a[r1].genes .+ F .* (I_a[r2].genes .- I_a[r3].genes), LOW, UPP)
        u = crossover(I_p[i].genes, v)

        u_noised = noise(u)
        
        b = (objective_function(u_noised), objective_function(u))
        
        if fitness(b[fit_index]) > fitness(I_a[r1].benchmark[fit_index])
            archive.individuals[r1] = Individual(deepcopy(u), b, devide_gene(u))
        end

        if fitness(b[fit_index]) > fitness(I_a[r2].benchmark[fit_index])
            archive.individuals[r2] = Individual(deepcopy(u), b, devide_gene(u))
        end
        
        if fitness(b[fit_index]) > fitness(I_a[r3].benchmark[fit_index])
            archive.individuals[r3] = Individual(deepcopy(u), b, devide_gene(u))
        end

        if fitness(b[fit_index]) > fitness(I_p[i].benchmark[fit_index])
            population.individuals[i] = Individual(deepcopy(u), b, devide_gene(u))
        end
    end

    println(" done")
    
    return population, archive
end

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
#                                                                                                    #
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#