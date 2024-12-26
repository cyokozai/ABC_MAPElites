#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
#       ME: Map Elites                                                                               #
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#

using StableRNGs

using Random

#----------------------------------------------------------------------------------------------------#

include("struct.jl")

include("config.jl")

include("benchmark.jl")

include("fitness.jl")

include("cvt.jl")

include("abc.jl")

include("de.jl")

include("logger.jl")

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
# Devide gene
function devide_gene(gene::Vector{Float64})
    g_len = length(gene)
    segment_length = div(g_len, BD)
    behavior = Float64[]
    
    for i in 1:BD
        start_idx = (i - 1) * segment_length + 1
        end_idx = i == BD ? g_len : i * segment_length
        
        push!(behavior, BD*sum(gene[start_idx:end_idx])/Float64(g_len))
    end
    
    return behavior
end

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
# Initialize the best solution
function init_solution()
    gene = rand(RNG, D) .* (UPP - LOW) .+ LOW
    gene_noised = noise(gene)

    return Individual(deepcopy(gene_noised), (objective_function(gene_noised), objective_function(gene)), devide_gene(gene_noised))
end

#----------------------------------------------------------------------------------------------------#
# Best solution
best_solution = init_solution()

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
# Evaluator: Evaluation of the individual
function evaluator(individual::Individual)
    # Objective function
    gene_noised = noise(individual.genes)
    individual.benchmark = (objective_function(gene_noised), objective_function(individual.genes))
    
    # Evaluate the behavior
    individual.behavior = deepcopy(devide_gene(gene_noised))

    # Update the best solution
    if fitness(individual.benchmark[fit_index]) >= fitness(best_solution.benchmark[fit_index])
        global best_solution = Individual(deepcopy(individual.genes), deepcopy(individual.benchmark), deepcopy(individual.behavior))
    end
    
    return individual
end

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
# Mapping: Mapping the individual to the archive
Mapping = if MAP_METHOD == "grid"
    (population::Population, archive::Archive) -> begin
        # The length of the grid
        len = (UPP - LOW) / GRID_SIZE
        
        # Mapping the individual to the archive
        for (index, ind) in enumerate(population.individuals)
            idx = clamp.(ind.behavior, LOW, UPP)
            
            for i in 1:GRID_SIZE
                for j in 1:GRID_SIZE
                    if LOW + len * (i - 1) <= idx[1] && idx[1] < LOW + len * i && LOW + len * (j - 1) <= idx[2] && idx[2] < LOW + len * j # Save the individual to the grid
                        # Check the grid
                        if archive.grid[i, j] > 0
                            if fitness(ind.benchmark[fit_index]) > fitness(archive.individuals[archive.grid[i, j]].benchmark[fit_index])
                                archive.grid[i, j] = index
                                archive.individuals[index] = Individual(deepcopy(ind.genes), deepcopy(ind.benchmark), deepcopy(ind.behavior))
                                archive.grid_update_counts[i, j] += 1
                            end
                        else
                            archive.grid[i, j] = index
                            archive.individuals[index] = Individual(deepcopy(ind.genes), deepcopy(ind.benchmark), deepcopy(ind.behavior))
                            archive.grid_update_counts[i, j] += 1
                        end
                        
                        break
                    end
                end
            end
        end

        return archive
    end
elseif MAP_METHOD == "cvt"
    (population::Population, archive::Archive) -> cvt_mapping(population, archive)
else
    error("Invalid MAP method")

    logger("ERROR", "Invalid MAP method")
    
    exit(1)
end

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
# Mutate: Mutation of the individual
mutate(individual::Individual) = rand(RNG) < MUTANT_R ? individual : init_solution()

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
# Select random elite
select_random_elite = if MAP_METHOD == "grid"
    (population::Population, archive::Archive) -> begin
        print(".")
        
        while true
            i, j = rand(RNG, 1:GRID_SIZE, 2)
            
            if archive.grid[i, j] > 0
                return archive.individuals[archive.grid[i, j]]
            end
        end
    end
elseif MAP_METHOD == "cvt"
    (population::Population, archive::Archive) -> begin
        print(".")

        random_centroid_index = rand(RNG, keys(archive.individuals))
        
        return archive.individuals[random_centroid_index]
    end
end

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
# Reproduction: Generate new individuals
Reproduction = if METHOD == "default"
    (population::Population, archive::Archive) -> (Population([evaluator(mutate(select_random_elite(population, archive))) for _ in 1:N]), archive)
elseif METHOD == "abc"
    (population::Population, archive::Archive) -> ABC(population, archive)
elseif METHOD == "de"
    (population::Population, archive::Archive) -> DE(population, archive)
else
    error("Invalid method")

    logger("ERROR", "Invalid method")

    exit(1)
end

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
# Map Elites algorithm
function map_elites()
    global best_solution

    # Print the solutions
    indPrint = if FIT_NOISE
        (ffn, ff) -> begin
            println("Now best: ", best_solution.genes[1:min(10, length(best_solution.genes))])
            println("Now noised best fitness: ", fitness(best_solution.benchmark[1]))
            println("Now corrected best fitness: ", fitness(best_solution.benchmark[2]))
            println("Now best behavior: ", best_solution.behavior)
            
            println(ffn, fitness(best_solution.benchmark[1]))
            println(ff, fitness(best_solution.benchmark[2]))
        end
    else
        (ffn, ff) -> begin
            println("Now best: ", best_solution.genes[1:min(10, length(best_solution.genes))])
            println("Now best fitness: ", fitness(best_solution.benchmark[2]))
            println("Now best behavior: ", best_solution.behavior)
            
            println(ff, fitness(best_solution.benchmark[2]))
        end
    end
    
    # Initialize
    logger("INFO", "Initialize")
    
    population::Population = Population([evaluator(init_solution()) for _ in 1:N])
    archive::Archive = if MAP_METHOD == "grid"
        Archive(zeros(Int64, GRID_SIZE, GRID_SIZE), zeros(Int64, GRID_SIZE, GRID_SIZE), Dict{Int64, Individual}())
    elseif MAP_METHOD == "cvt"
        init_CVT(population)
        Archive(zeros(Int64, 0, 0), zeros(Int64, k_max), Dict{Int64, Individual}())
    end
    
    # Open file
    ffn = open("$(output)$(METHOD)/$(OBJ_F)/$(F_FIT_N)", "a")
    ff  = open("$(output)$(METHOD)/$(OBJ_F)/$(F_FITNESS)", "a")

    #------ Main loop ------------------------------#

    logger("INFO", "Start Iteration")

    begin_time = time()

    for iter in 1:MAXTIME
        println("Generation: ", iter)
        
        # Evaluator
        population = Population([evaluator(ind) for ind in population.individuals])
        
        # Mapping
        archive = Mapping(population, archive)
        
        # Reproduction
        population, archive = Reproduction(population, archive)
        
        # Print the solutions
        indPrint(ffn, ff)
        
        # Confirm the convergence
        if CONV_FLAG
            if fitness(best_solution.benchmark[fit_index]) >= 1.0 || abs(sum(SOLUTION .- best_solution.genes)) < EPS
                logger("INFO", "Convergence")
                
                break
            elseif fitness(best_solution.benchmark[fit_index]) < 0.0
                logger("ERROR", "Invalid fitness value")
            end
        end
    end
    
    finish_time = time()
    
    logger("INFO", "Time out")

    #------ Main loop ------------------------------#

    # Close file
    close(ffn)
    close(ff)

    return population, archive, (finish_time - begin_time)
end

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
#                                                                                                    #
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#