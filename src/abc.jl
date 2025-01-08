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
    r = rand(RNG)
    
    for i in 1:length(I)
        if cum_probs[i] > r
            return i
        end
    end

    return 1
end

function roulleteSelection(cum_probs::Vector{Float64}, I::Dict{Int64, Individual})
    r = rand(RNG)
    
    for (i, key) in enumerate(keys(I))
        if cum_probs[i] > r
            return key
        end
    end

    return keys(I)[1]
end

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
# Employed bee phase
function employed_bee(population::Population, archive::Archive)
    I_p, I_a = population.individuals, archive.individuals
    v_l, v_g = zeros(Float64, FOOD_SOURCE, D), zeros(Float64, FOOD_SOURCE, D)
    k, l = rand(RNG, keys(I_a)), rand(RNG, 1:D)
    
    print(".")

    for i in 1:FOOD_SOURCE
        for j in 1:D
            while I_p[i].genes[j] == I_a[k].genes[j] || j == l
                k = rand(RNG, keys(I_a))
                l = rand(RNG, 1:D)
            end
            
            v_l[i, j] = I_p[i].genes[j] + (rand(RNG) * 2.0 - 1.0) * (I_p[i].genes[j] - I_p[i].genes[l])
            v_g[i, j] = I_p[i].genes[j] + (rand(RNG) * 2.0 - 1.0) * (I_p[i].genes[j] - I_a[k].genes[j])
        end
        
        if objective_function(v_l[i, :]) > objective_function(v_g[i, :])
            population.individuals[i].genes = deepcopy(greedySelection(I_p[i].genes, v_l[i, :], i, k))
        else
            population.individuals[i].genes = deepcopy(greedySelection(I_p[i].genes, v_g[i, :], i, k))
        end
    end
    
    print(".")

    return population, archive
end

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
# Onlooker bee phase
function onlooker_bee(population::Population, archive::Archive)
    I_p, I_a = population.individuals, archive.individuals
    v_l, v_g = zeros(Float64, FOOD_SOURCE, D), zeros(Float64, FOOD_SOURCE, D)
    u_l, u_g = zeros(Float64, FOOD_SOURCE, D), zeros(Float64, FOOD_SOURCE, D)
    k, l = rand(RNG, keys(I_a)), rand(RNG, 1:D)

    Σ_fit_l = sum(fitness(I_p[i].benchmark[fit_index]) for i in 1:FOOD_SOURCE)
    cum_p_l = cumsum([fitness(I_p[i].benchmark[fit_index]) / Σ_fit_l for i in 1:FOOD_SOURCE])

    Σ_fit_g = sum(fitness(I_a[i].benchmark[fit_index]) for i in keys(I_a))
    cum_p_g = cumsum([fitness(I_a[i].benchmark[fit_index]) / Σ_fit_g for i in keys(I_a)])

    print(".")
    
    for i in 1:FOOD_SOURCE
        u_l[i, :] = deepcopy(I_p[roulleteSelection(cum_p_l, I_p)].genes)
        u_g[i, :] = deepcopy(I_a[roulleteSelection(cum_p_g, I_a)].genes)
        
        for j in 1:D
            while I_p[i].genes[j] == I_a[k].genes[j] || j == l
                k = rand(RNG, keys(I_a))
                l = rand(RNG, 1:D)
            end
            
            v_l[i, j] = u_l[i, j] + (rand(RNG) * 2.0 - 1.0) * (u_l[i, j] - I_p[i].genes[l])
            v_g[i, j] = u_g[i, j] + (rand(RNG) * 2.0 - 1.0) * (u_g[i, j] - I_a[k].genes[j])
        end

        if objective_function(v_l[i, :]) > objective_function(v_g[i, :])
            population.individuals[i].genes = deepcopy(greedySelection(I_p[i].genes, v_l[i, :], i, k))
        else
            population.individuals[i].genes = deepcopy(greedySelection(I_p[i].genes, v_g[i, :], i, k))
        end
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