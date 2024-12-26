#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
#       ABC: Artificial Bee Colony                                                                   #
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#

using Statistics

using Random

#----------------------------------------------------------------------------------------------------#

include("config.jl")

include("struct.jl")

include("fitness.jl")

include("logger.jl")

#----------------------------------------------------------------------------------------------------#
# ABC Trial
trial = zeros(Int, FOOD_SOURCE)

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
# Greedy selection
function greedySelection(f::Vector{Float64}, v::Vector{Float64}, i::Int64, k::Int64)
    global trial

    v_b, f_b = (objective_function(noise(v)), objective_function(v)), (objective_function(noise(f)), objective_function(f))
    
    if fitness(v_b[fit_index]) > fitness(f_b[fit_index])
        trial[i] = 0
        
        return v
    else
        trial[i] += 1
        
        return f
    end
end

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
# Roulette selection
function roulleteSelection(cum_probs::Vector{Float64}, I::Vector{Individual})
    r = rand()
    
    for (i, cum_p) in enumerate(cum_probs)
        if r <= cum_p
            return i
        end
    end

    return FOOD_SOURCE
end

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
# Employed bee phase
function employed_bee(population::Population, archive::Archive)
    I_p, I_a = population.individuals, archive.individuals
    v = zeros(Float64, FOOD_SOURCE, D)
    k = 0
    
    print(".")

    for i in 1:FOOD_SOURCE
        for j in 1:D
            while true
                k = rand(RNG, keys(I_a))
                
            if I_p[i].genes[j] != I_a[k].genes[j] break end
            end
            
            v[i, j] = I_p[i].genes[j] + (rand(RNG) * 2.0 - 1.0) * (I_p[i].genes[j] - I_a[k].genes[j])
        end
        
        population.individuals[i].genes = deepcopy(greedySelection(I_p[i].genes, v[i, :], i, k))
    end
    
    print(".")

    return population, archive
end

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
# Onlooker bee phase
function onlooker_bee(population::Population, archive::Archive)
    I_p, I_a = population.individuals, archive.individuals
    v, u = zeros(Float64, FOOD_SOURCE, D), zeros(Float64, FOOD_SOURCE, D)
    k = 0

    Σ_fit = sum(fitness(I_p[i].benchmark[fit_index]) for i in 1:FOOD_SOURCE)
    cum_p = cumsum([fitness(I_p[i].benchmark[fit_index]) / Σ_fit for i in 1:FOOD_SOURCE])
    
    print(".")
    
    for i in 1:FOOD_SOURCE
        u[i, :] = deepcopy(I_p[roulleteSelection(cum_p, I_p)].genes)
        
        for j in 1:D
            while true
                k = rand(RNG, keys(I_a))
                
                if I_p[i].genes[j] != I_a[k].genes[j] break end
            end
            
            v[i, j] = u[i, j] + (rand(RNG) * 2.0 - 1.0) * (u[i, j] - I_a[k].genes[j])
        end
        
        population.individuals[i].genes = deepcopy(greedySelection(I_p[i].genes, v[i, :], i, k))
    end
    
    print(".")

    return population, archive
end

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
# Scout bee phase
function scout_bee(population::Population, archive::Archive)
    global trial, cvt_vorn_data_update

    print(".")

    if maximum(trial) > TC_LIMIT
        for i in 1:FOOD_SOURCE
            if trial[i] > TC_LIMIT
                gene = rand(Float64, D) .* (UPP - LOW) .+ LOW
                gene_noised = noise(gene)

                population.individuals[i] = Individual(deepcopy(gene_noised), (objective_function(gene_noised), objective_function(gene)), devide_gene(gene_noised))
                trial[i] = 0
                
                logger("INFO", "Scout bee found a new food source")
                
                if cvt_vorn_data_update < cvt_vorn_data_update_limit
                    init_CVT(population)
                    
                    new_archive = Archive(zeros(Int64, 0, 0), zeros(Int64, k_max), Dict{Int64, Individual}())
                    archive = deepcopy(cvt_mapping(population, new_archive))
                    
                    logger("INFO", "Recreate Voronoi diagram")
                end
            end
        end
    end

    print(".")
    
    return population, archive
end

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
# ABC algorithm
function ABC(population::Population, archive::Archive)
    # Employee bee phase
    print("Employed bee phase")
    population, archive = employed_bee(population, archive)
    println(". Done")

    # Onlooker bee phase
    print("Onlooker bee phase")
    population, archive = onlooker_bee(population, archive)
    println(". Done")

    # Scout bee phase
    print("Scout bee phase")
    population, archive = scout_bee(population, archive)
    println(". Done")
    
    return population, archive
end

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
#                                                                                                    #
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#