#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
#       ABC: Artificial Bee Colony                                                                   #
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#

using Distributions

using Random

#----------------------------------------------------------------------------------------------------#

include("config.jl")

include("struct.jl")

include("fitness.jl")

include("crossover.jl")

include("logger.jl")

#----------------------------------------------------------------------------------------------------#
# Trial counter | Population
trial_P = zeros(Int, FOOD_SOURCE)

# Trial counter | Archive
trial_A = zeros(Int, k_max)

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
# Uniform distribution
φ = () -> rand(RNG) * 2.0 - 1.0

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
# Greedy selection
function greedySelection(x::Vector{Float64}, v::Vector{Float64}, trial::Vector{Int}, i::Int)
    x_b, v_b = (objective_function(noise(x)), objective_function(x)), (objective_function(noise(v)), objective_function(v))
    
    if fitness(v_b[fit_index]) > fitness(x_b[fit_index])
        trial[i] = 0
        
        return v
    else
        trial[i] += 1
        
        return x
    end
end

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
# Roulette selection | Population
function roulleteSelection(cum_probs::Vector{Float64}, I::Vector{Individual})
    r = rand(RNG)
    
    for i in 1:length(I)
        if cum_probs[i] > r
            return i
        end
    end

    return rand(RNG, 1:length(I))
end

#----------------------------------------------------------------------------------------------------#
# Roulette selection | Archive
function roulleteSelection(cum_probs::Vector{Float64}, I::Dict{Int64, Individual})
    r = rand(RNG)
    
    for (i, key) in enumerate(keys(I))
        if cum_probs[i] > r
            return key
        end
    end
    
    return keys(I)[rand(RNG, keys(I))]
end

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
# Employed bee phase
function employed_bee(population::Population, archive::Archive)
    I_P = population.individuals
    v_P = zeros(Float64, D)
    j   = rand(RNG, 1:FOOD_SOURCE)
    
    print(".")
    
    for i in 1:FOOD_SOURCE
        for d in 1:D
            while true
                j = rand(RNG, 1:FOOD_SOURCE)
                
                if i != j
                    break 
                end
            end
            
            v_P[d] = I_P[i].genes[d] + φ() * (I_P[i].genes[d] - I_P[j].genes[d])
        end
        
        population.individuals[i].genes = deepcopy(greedySelection(population.individuals[i].genes, v_P, trial_P, i))
    end
    
    print(".")

    return population, archive
end

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
# Onlooker bee phase
function onlooker_bee(population::Population, archive::Archive)
    I_P, I_A = population.individuals, archive.individuals
    v_P, v_A = zeros(Float64, D), zeros(Float64, D)
    u_P, u_A = zeros(Float64, D), zeros(Float64, D)
    j, k     = rand(RNG, 1:FOOD_SOURCE), rand(RNG, keys(I_A))
    
    Σ_fit_p, Σ_fit_a = sum(fitness(I_P[i].benchmark[fit_index]) for i in 1:FOOD_SOURCE), sum(fitness(I_A[i].benchmark[fit_index]) for i in keys(I_A))
    cum_p_p, cum_p_a = cumsum([fitness(I_P[i].benchmark[fit_index]) / Σ_fit_p for i in 1:FOOD_SOURCE]), cumsum([fitness(I_A[i].benchmark[fit_index]) / Σ_fit_a for i in keys(I_A)])

    print(".")
    
    for i in 1:FOOD_SOURCE
        u_P = I_P[roulleteSelection(cum_p_p, I_P)].genes
        u_A = I_A[roulleteSelection(cum_p_a, I_A)].genes

        for d in 1:D
            while true
                j, k = rand(RNG, 1:FOOD_SOURCE), rand(RNG, keys(I_A))
                
                if I_P[i].genes[d] != I_A[k].genes[d] && i != j
                    break 
                end
            end
            
            v_P[d] = u_P[d] + φ() * (u_P[d] - I_P[j].genes[d])
            v_A[d] = u_A[d] + φ() * (u_A[d] - I_A[k].genes[d])
        end
        
        u_CR = crossover(v_P, v_A)
        if objective_function(u_CR) < objective_function(I_P[i].genes)
            archive.individuals[rand(RNG, keys(I_A))].genes = deepcopy(u_CR)
        end

        population.individuals[i].genes = deepcopy(greedySelection(population.individuals[i].genes, v_P, trial_P, i))
        population.individuals[i].genes = deepcopy(greedySelection(population.individuals[i].genes, v_A, trial_A, k))
    end
    
    print(".")

    return population, archive
end

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
# Scout bee phase
function scout_bee(population::Population, archive::Archive)
    global trial_P, cvt_vorn_data_update
    
    print(".")
    
    if maximum(trial_P) > TC_LIMIT
        for i in 1:FOOD_SOURCE
            if trial_P[i] > TC_LIMIT
                gene        = rand(Float64, D) .* (UPP - LOW) .+ LOW
                gene_noised = noise(gene)
                
                population.individuals[i] = Individual(deepcopy(gene_noised), (objective_function(gene_noised), objective_function(gene)), devide_gene(gene_noised))
                trial_P[i] = 0
                
                logger("INFO", "Scout bee found a new food source")
            end
        end
    elseif maximum(trial_A) > TC_LIMIT ÷ D
        for key in keys(archive.individuals)
            if trial_A[key] > TC_LIMIT ÷ D
                gene        = rand(Float64, D) .* (UPP - LOW) .+ LOW
                gene_noised = noise(gene)
                
                archive.individuals[key] = Individual(deepcopy(gene_noised), (objective_function(gene_noised), objective_function(gene)), devide_gene(gene_noised))
                trial_A[key] = 0
                
                logger("INFO", "Scout bee found a new food source")
            end
        end

        if cvt_vorn_data_update < cvt_vorn_data_update_limit
            init_CVT(population)
            
            new_archive = Archive(zeros(Int64, 0, 0), zeros(Int64, k_max), Dict{Int64, Individual}())
            archive     = deepcopy(cvt_mapping(population, new_archive))
            
            logger("INFO", "Recreate Voronoi diagram")
        end
    end
    
    print(".")
    
    return population, archive
end

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
# ABC algorithm
function ABC(population::Population, archive::Archive)
    # Employee bee phase
    print("Employed bee phase ")
    population, archive = employed_bee(population, archive)
    println(". Done")
    
    # Onlooker bee phase
    print("Onlooker bee phase ")
    population, archive = onlooker_bee(population, archive)
    println(". Done")

    # Scout bee phase
    print("Scout    bee phase ")
    population, archive = scout_bee(population, archive)
    println(". Done")
    println(maximum(trial_P))
    println(maximum(trial_A))
    
    return population, archive
end

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
#                                                                                                    #
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#