#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
#       ABC: Artificial Bee Colony                                                                   #
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#

using Distributions  # 分布関数

using Random         # 乱数生成

#----------------------------------------------------------------------------------------------------#

include("config.jl")     # 設定ファイル

include("struct.jl")     # 構造体

include("fitness.jl")    # 適応度

include("crossover.jl")  # 交叉

include("logger.jl")     # ログ出力用のファイル

#----------------------------------------------------------------------------------------------------#
# Trial counter | Population
trial_P = zeros(Int, FOOD_SOURCE)  # 試行回数カウンタ（個体群）

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
# Uniform distribution | [-1, 1]
φ = () -> rand(RNG) * 2.0 - 1.0  # 一様分布 [-1, 1]

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
# Greedy selection
function greedySelection(x::Vector{Float64}, v::Vector{Float64}, trial::Vector{Int}, i::Int)
    x_b, v_b = (objective_function(noise(x)), objective_function(x)), (objective_function(noise(v)), objective_function(v))  # ベンチマークを計算
    
    if fitness(v_b[fit_index]) > fitness(x_b[fit_index])  # 新しい解が良い場合
        trial[i] = 0  # 試行回数をリセット
        
        return v      # 新しい解を返す
    else
        trial[i] += 1  # 試行回数をインクリメント
        
        return x       # 元の解を返す
    end
end

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
# Roulette selection | Population
function rouletteSelection(cum_probs::Vector{Float64}, I::Vector{Individual})
    r = rand(RNG)  # 乱数を生成
    
    for i in 1:length(I)
        if cum_probs[i] > r  # 累積確率が乱数よりも大きい場合
            return i  # 選択されたインデックスを返す
        end
    end

    return rand(RNG, 1:length(I))  # ランダムなインデックスを返す
end

#----------------------------------------------------------------------------------------------------#
# Roulette selection | Archive
function rouletteSelection(cum_probs::Dict{Int64, Float64}, I::Vector{Int64})
    r = rand(RNG)  # 乱数を生成

    for key in I
        if cum_probs[key] > r  # 累積確率が乱数よりも大きい場合
            return key  # 選択されたキーを返す
        end
    end
    
    return rand(RNG, I)  # ランダムなキーを返す
end

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
# Employed bee phase
function employed_bee(population::Population, archive::Archive)
    I_P = population.individuals    # 個体群を取得
    v_P = zeros(Float64, D)         # 変異ベクトルを初期化
    j   = rand(RNG, 1:FOOD_SOURCE)  # ランダムなインデックスを生成

    print(".")
    
    for i in 1:FOOD_SOURCE
        for d in 1:D
            while true
                j = rand(RNG, 1:FOOD_SOURCE)  # ランダムなインデックスを生成
                
                if i != j
                    break 
                end
            end
            
            v_P[d] = I_P[i].genes[d] + φ() * (I_P[i].genes[d] - I_P[j].genes[d])  # 変異ベクトルを計算
        end
        
        population.individuals[i].genes = deepcopy(greedySelection(I_P[i].genes, v_P, trial_P, i))  # 貪欲選択を行う
    end
    
    print(".")
    
    return population, archive  # 更新された個体群とアーカイブを返す
end

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
# Onlooker bee phase
function onlooker_bee(population::Population, archive::Archive)
    I_P, I_A = population.individuals, archive.individuals              # 個体群とアーカイブの個体を取得
    v_P, v_A = zeros(Float64, D), zeros(Float64, D)                     # 変異ベクトルを初期化
    u_P, u_A = zeros(Float64, D), zeros(Float64, D)                     # 交叉ベクトルを初期化
    j, k     = rand(RNG, 1:FOOD_SOURCE), rand(RNG, collect(keys(I_A)))  # ランダムなインデックスを生成
    
    # 適応度の合計を計算
    Σ_fit_p = sum(fitness(I_P[i].benchmark[fit_index]) for i in 1:FOOD_SOURCE)
    Σ_fit_a = sum(fitness(I_A[i].benchmark[fit_index]) for i in keys(I_A))

    # 累積確率を計算
    cum_p_p = [fitness(I_P[i].benchmark[fit_index]) / Σ_fit_p for i in 1:FOOD_SOURCE]
    cum_p_a = Dict{Int64, Float64}(i => fitness(I_A[i].benchmark[fit_index]) / Σ_fit_a for i in keys(I_A))

    print(".")
    
    for i in 1:FOOD_SOURCE
        # ルーレット選択を行う
        u_P = I_P[rouletteSelection(cum_p_p, I_P)].genes
        u_A = I_A[rouletteSelection(cum_p_a, collect(keys(I_A)))].genes

        for d in 1:D
            while true
                j, k = rand(RNG, 1:FOOD_SOURCE), rand(RNG, collect(keys(I_A)))  # ランダムなインデックスを生成
                
                if I_P[i].genes[d] != I_A[k].genes[d] && i != j
                    break 
                end
            end
            
            # 変異ベクトルを計算
            v_P[d] = u_P[d] + φ() * (u_A[d] - I_P[j].genes[d])
            v_A[d] = u_A[d] + φ() * (u_P[d] - I_A[k].genes[d])
        end
        
        # 変異ベクトルv_Pとv_Aの評価を比較
        population.individuals[i].genes = if objective_function(v_P) < objective_function(v_A)
            greedySelection(I_P[i].genes, v_P, trial_P, i)  # 個体I_P[i]と変異ベクトルv_Pとで貪欲選択を行う
        else
            greedySelection(I_P[i].genes, v_A, trial_P, i)  # 個体I_P[i]と変異ベクトルv_Aとで貪欲選択を行う
        end
    end
    
    print(".")

    return population, archive  # 更新された個体群とアーカイブを返す
end

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
# Scout bee phase
function scout_bee(population::Population, archive::Archive)
    global trial_P, cvt_vorn_data_update
    
    print(".")
    
    if maximum(trial_P) > TC_LIMIT  # 試行回数が上限を超えた場合
        for i in 1:FOOD_SOURCE
            if trial_P[i] > TC_LIMIT  # 試行回数が上限を超えた場合
                gene        = rand(Float64, D) .* (UPP - LOW) .+ LOW  # 新しい遺伝子を生成
                gene_noised = noise(gene)  # ノイズを加える
                
                population.individuals[i] = Individual(deepcopy(gene_noised), (objective_function(gene_noised), objective_function(gene)), devide_gene(gene_noised))  # 新しい個体を生成
                trial_P[i] = 0  # 試行回数をリセット
                
                logger("INFO", "Scout bee found a new food source")  # 新しい食料源を発見したことをログに記録
            end
        end

        if cvt_vorn_data_update <= cvt_vorn_data_update_limit  # ボロノイデータ更新回数が上限値以下の場合
            init_CVT(population)  # CVTを初期化
            
            new_archive = Archive(zeros(Int64, 0, 0), zeros(Int64, k_max), Dict{Int64, Individual}())  # 新しいアーカイブを生成
            archive     = deepcopy(cvt_mapping(population, new_archive))                               # アーカイブを更新
            
            logger("INFO", "Recreate Voronoi diagram")  # ボロノイ図を再作成したことをログに記録
        end
    end
    
    print(".")
    
    return population, archive  # 更新された個体群とアーカイブを返す
end

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
# ABC algorithm
function ABC(population::Population, archive::Archive)
    # Employee bee phase | 収穫蜂フェーズ
    print("Employed bee phase ")
    population, archive = employed_bee(population, archive)
    println(". Done")
    
    # Onlooker bee phase | 追従蜂フェーズ
    print("Onlooker bee phase ")
    population, archive = onlooker_bee(population, archive)
    println(". Done")

    # Scout bee phase | 偵察蜂フェーズ
    print("Scout bee phase    ")
    population, archive = scout_bee(population, archive)
    println(". Done")
    
    return population, archive  # 更新された個体群とアーカイブを返す
end

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
#                                                                                                    #
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#