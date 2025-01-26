#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
#       DE: Differential Evolution                                                                   #
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#

using Statistics  # 統計関数

using Random      # 乱数生成

#----------------------------------------------------------------------------------------------------#

include("config.jl")     # 設定ファイル

include("struct.jl")     # 構造体

include("fitness.jl")    # 適応度

include("crossover.jl")  # 交叉

include("logger.jl")     # ログ出力用のファイル

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
# Differential Evolution algorithm
function DE(population::Population, archive::Archive)
    I_p, I_a = population.individuals, archive.individuals  # 個体群とアーカイブの個体を取得
    r1, r2, r3 = zeros(Int, 3)                              # ランダムなインデックスを初期化
    b = Tuple{Float64, Float64}[]                           # ベンチマーク結果を格納するタプルの配列を初期化
    
    print("DE")

    for i in 1:N
        while r1 == r2 || r1 == r3 || r2 == r3 || I_a[r1].genes == I_p[i].genes || I_a[r2].genes == I_p[i].genes || I_a[r3].genes == I_p[i].genes
            r1, r2, r3 = rand(RNG, keys(I_a), 3)  # ランダムな異なるインデックスを生成 -> ドナーベクトルを選択
        end
        
        v = clamp.(I_a[r1].genes .+ F .* (I_a[r2].genes .- I_a[r3].genes), LOW, UPP)  # 差分ベクトルを計算
        u = crossover(I_p[i].genes, v)  # 二項交叉を行い、トライアルベクトルを計算

        u_noised = noise(u)  # ノイズを加える
        b = (objective_function(u_noised), objective_function(u))  # ベンチマークを計算
        
        if b[fit_index] < I_a[r1].benchmark[fit_index]  # ターゲットベクトルとドナーベクトルr1の評価を比較
            archive.individuals[r1] = Individual(deepcopy(u), b, devide_gene(u))    # アーカイブr1を更新
        end

        if b[fit_index] < I_a[r2].benchmark[fit_index]  # ターゲットベクトルとドナーベクトルr2の評価を比較
            archive.individuals[r2] = Individual(deepcopy(u), b, devide_gene(u))    # アーカイブr2を更新
        end
        
        if b[fit_index] < I_a[r3].benchmark[fit_index]  # ターゲットベクトルとドナーベクトルr3の評価を比較
            archive.individuals[r3] = Individual(deepcopy(u), b, devide_gene(u))    # アーカイブr3を更新
        end

        if b[fit_index] < I_p[i].benchmark[fit_index]  # ターゲットベクトルとトライアルベクトルの評価を比較
            population.individuals[i] = Individual(deepcopy(u), b, devide_gene(u))  # 個体群を更新
        end
    end

    println(" done")
    
    return population, archive  # 更新された個体群とアーカイブを返す
end

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
#                                                                                                    #
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#