#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
#       ME: Map Elites                                                                               #
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#

using StableRNGs  # 安定した乱数生成

using Random      # 乱数生成

#----------------------------------------------------------------------------------------------------#

include("struct.jl")     # 構造体

include("config.jl")     # 設定ファイル

include("benchmark.jl")  # ベンチマーク関数

include("fitness.jl")    # 適応度

include("crossover.jl")  # 交叉

include("cvt.jl")        # CVT関連のファイル

include("abc.jl")        # ABCアルゴリズム

include("de.jl")         # 差分進化アルゴリズム

include("logger.jl")     # ログ出力用のファイル

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
# Devide gene
function devide_gene(gene::Vector{Float64})
    gene_len    = length(gene)       # 遺伝子の長さを取得
    segment_len = div(gene_len, BD)  # セグメントの長さを計算
    behavior    = Float64[]          # 行動ベクトルを初期化

    for i in 1:BD
        start_idx = (i - 1) * segment_len + 1             # 開始インデックスを計算
        end_idx   = i == BD ? gene_len : i * segment_len  # 終了インデックスを計算
        
        push!(behavior, BD*sum(gene[start_idx:end_idx])/Float64(gene_len))  # 行動ベクトルに値を追加
    end
    
    return behavior  # 行動ベクトルを返す
end

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
# Initialize the best solution
function init_solution()
    gene = rand(RNG, D) .* (UPP - LOW) .+ LOW  # ランダムな遺伝子を生成
    gene_noised = noise(gene)                  # ノイズを加える

    return Individual(deepcopy(gene_noised), (objective_function(gene_noised), objective_function(gene)), devide_gene(gene_noised))  # 個体を生成して返す
end

#----------------------------------------------------------------------------------------------------#
# Best solution
best_solution = init_solution()  # 最良解を初期化

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
# Evaluator: Evaluation of the individual
function evaluator(individual::Individual)
    global best_solution

    # Objective function
    gene_noised = noise(individual.genes)  # ノイズを加える
    individual.benchmark = (objective_function(gene_noised), objective_function(individual.genes))  # ベンチマークを計算
    
    # Evaluate the behavior
    individual.behavior = deepcopy(devide_gene(gene_noised))  # 行動を評価

    # Update the best solution
    if individual.benchmark[fit_index] <= best_solution.benchmark[fit_index]  # 最良解より個体の評価が良い場合
        best_solution = Individual(deepcopy(individual.genes), deepcopy(individual.benchmark), deepcopy(individual.behavior))  # 最良解を更新
    end
    
    return individual  # 評価された個体を返す
end

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
# Mapping: Mapping the individual to the archive
Mapping = if MAP_METHOD == "grid"
    (population::Population, archive::Archive) -> begin
        # The length of the grid
        len = (UPP - LOW) / GRID_SIZE  # グリッドの長さを計算
        
        # Mapping the individual to the archive
        for (index, ind) in enumerate(population.individuals)
            idx = clamp.(ind.behavior, LOW, UPP)  # 行動をクランプ
            
            for i in 1:GRID_SIZE
                for j in 1:GRID_SIZE
                    if LOW + len * (i - 1) <= idx[1] && idx[1] < LOW + len * i && LOW + len * (j - 1) <= idx[2] && idx[2] < LOW + len * j  # グリッドに個体を保存
                        # Check the grid
                        if archive.grid[i, j] > 0  # グリッドに個体が存在する場合
                            if fitness(ind.benchmark[fit_index]) > fitness(archive.individuals[archive.grid[i, j]].benchmark[fit_index])  # 評価が良い場合
                                archive.grid[i, j] = index  # グリッドを更新
                                archive.individuals[index] = Individual(deepcopy(ind.genes), deepcopy(ind.benchmark), deepcopy(ind.behavior))  # 個体を更新
                                archive.grid_update_counts[i, j] += 1  # グリッドの更新回数を増やす
                            end
                        else  # グリッドに個体が存在しない場合
                            archive.grid[i, j] = index  # グリッドに個体を保存
                            archive.individuals[index] = Individual(deepcopy(ind.genes), deepcopy(ind.benchmark), deepcopy(ind.behavior))  # 個体を保存
                            archive.grid_update_counts[i, j] += 1  # グリッドの更新回数を増やす
                        end
                        
                        break
                    end
                end
            end
        end

        return archive  # 更新されたアーカイブを返す
    end
elseif MAP_METHOD == "cvt"
    (population::Population, archive::Archive) -> cvt_mapping(population, archive)  # CVTマッピング
else
    error("Invalid MAP method")  # 無効なMAPメソッドエラー -> 終了

    logger("ERROR", "Invalid MAP method")  # ログ出力
    
    exit(1)
end

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
# Mutate: Mutation of the individual
mutate(individual::Individual) = rand(RNG) < MUTANT_R ? individual : init_solution()  # 突然変異

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
# Select random elite
select_random_elite = if MAP_METHOD == "grid"
    (population::Population, archive::Archive) -> begin
        while true
            i, j, k = rand(RNG, 1:GRID_SIZE, 3)  # ランダムなインデックスを生成
            
            if archive.grid[i, j] > 0 && archive.grid[i, k] > 0 && j != k
                return archive.individuals[archive.grid[i, j]], archive.individuals[archive.grid[i, k]]  # ランダムなエリートを選択
            end
        end
    end
elseif MAP_METHOD == "cvt"
    (population::Population, archive::Archive) -> begin
        random_centroid_index1, random_centroid_index2 = zeros(Int64, 2)  # ランダムなインデックスを初期化

        while random_centroid_index1 == random_centroid_index2
            random_centroid_index1, random_centroid_index2 = rand(RNG, keys(archive.individuals), 2)  # ランダムなインデックスを生成
        end
        
        return archive.individuals[random_centroid_index1], archive.individuals[random_centroid_index2]  # ランダムなエリートを選択
    end
end

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
# Reproduction: Generate new individuals
Reproduction = if METHOD == "me"  # MAP-Elites
    (population::Population, archive::Archive) -> (Population([evaluator(mutate(crossover(select_random_elite(population, archive)))) for _ in 1:N]), archive)
elseif METHOD == "abc"  # ABC MAP-Elites
    (population::Population, archive::Archive) -> ABC(population, archive)
elseif METHOD == "de"  # Differential MAP-Elites
    (population::Population, archive::Archive) -> DE(population, archive)
else
    error("Invalid method")  # 無効なメソッドエラー -> 終了
    
    logger("ERROR", "Invalid method")  # ログ出力

    exit(1)
end

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
# Map Elites algorithm
function map_elites()
    global best_solution

    # Print the solutions
    indPrint = if FIT_NOISE  # ノイズを考慮する場合
        (ffn, ff) -> begin
            println("Now best individual: ", best_solution.genes[1:min(10, length(best_solution.genes))])
            println("Now best behavior:   ", best_solution.behavior)
            println("Now noised    best fitness: ", fitness(best_solution.benchmark[1]))
            println("Now corrected best fitness: ", fitness(best_solution.benchmark[2]))
            
            println(ffn, best_solution.benchmark[1])
            println(ff, best_solution.benchmark[2])
        end
    else  # ノイズを考慮しない場合
        (ffn, ff) -> begin
            println("Now best individual: ", best_solution.genes[1:min(10, length(best_solution.genes))])
            println("Now best behavior:   ", best_solution.behavior)
            println("Now best fitness:    ", fitness(best_solution.benchmark[2]))
            
            println(ff, fitness(best_solution.benchmark[2]))
        end
    end
    
    #------ Initialize ------------------------------#
    
    logger("INFO", "Initialize")

    # Initialize the population
    population::Population = Population([evaluator(init_solution()) for _ in 1:N])  # 個体群を初期化

    # Initialize the archive
    archive::Archive = if MAP_METHOD == "grid"  # グリッドマッピングの場合
        Archive(zeros(Int64, GRID_SIZE, GRID_SIZE), zeros(Int64, GRID_SIZE, GRID_SIZE), Dict{Int64, Individual}())  # アーカイブを初期化
    elseif MAP_METHOD == "cvt"  # CVTマッピングの場合
        init_CVT(population)  # CVTを初期化
        Archive(zeros(Int64, 0, 0), zeros(Int64, k_max), Dict{Int64, Individual}())  # アーカイブを初期化
    else
        error("Invalid MAP method")  # 無効なMAPメソッドエラー -> 終了

        logger("ERROR", "Invalid MAP method")  # ログ出力

        exit(1)
    end
    
    # Open file
    ffn = open("$(output)$(METHOD)/$(OBJ_F)/$(F_FIT_N)", "a")
    ff  = open("$(output)$(METHOD)/$(OBJ_F)/$(F_FITNESS)", "a")

    #------ Main loop ------------------------------#

    logger("INFO", "Start Iteration")

    begin_time = time()  # 初期化後の開始時間を取得

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
        if CONV_FLAG  # 収束判定を行うか否か
            if fitness(best_solution.benchmark[fit_index]) >= 1.0 || abs(sum(SOLUTION .- best_solution.genes)) < EPS  # 収束判定
                logger("INFO", "Convergence")
                
                break
            elseif fitness(best_solution.benchmark[fit_index]) < 0.0  # 適応度が負の場合
                logger("ERROR", "Invalid fitness value")  # エラーを出力 -> 終了

                exit(1)
            end
        end
    end
    
    finish_time = time()  # 終了時間を取得
    
    logger("INFO", "Time out")

    #------ Save data ------------------------------#

    # Close file
    close(ffn)
    close(ff)

    return population, archive, (finish_time - begin_time)  # 更新された個体群とアーカイブ、経過時間を返す
end

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
#                                                                                                    #
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#