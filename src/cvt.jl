#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
#       CVT: Centroidal Voronoi Tessellations                                                        #
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#

using DelaunayTriangulation  # Delaunay三角形分割

using LinearAlgebra          # 線形代数

using StableRNGs             # 乱数生成

using FileIO                 # ファイル入出力

using JLD2                   # JLD2ファイル

using Dates                  # 日付と時間

#----------------------------------------------------------------------------------------------------#

include("config.jl")  # 設定ファイル

include("struct.jl")  # 構造体

include("logger.jl")  # ログ出力用のファイル

#----------------------------------------------------------------------------------------------------#
# Voronoi diagram
vorn = nothing            # ボロノイ図の初期化

# Voronoi data update
cvt_vorn_data_update = 0  # ボロノイデータ更新カウンタの初期化

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
# Initialize the CVT
function init_CVT(population::Population)
    global vorn, cvt_vorn_data_update
    
    points   = [rand(RNG, BD) .* (UPP - LOW) .+ LOW for _ in 1:k_max - (N + 4)]  # ランダムな点を生成
    behavior = [population.individuals[i].behavior for i in 1:N]                 # 個体の行動を取得

    append!(points, behavior)                                          # 行動を点に追加
    append!(points, [[UPP, UPP], [UPP, LOW], [LOW, UPP], [LOW, LOW]])  # 境界点を追加
    
    vorn = centroidal_smooth(voronoi(triangulate(points; rng = RNG), clip = false); maxiters = CVT_MAX_ITER, rng = RNG)  # ボロノイ図を生成
    save("$(output)$(METHOD)/$(OBJ_F)/CVT-$(FILENAME)-$(cvt_vorn_data_update).jld2", "voronoi", vorn)                    # ボロノイ図を保存
    
    cvt_vorn_data_update += 1  # 更新カウンタをインクリメント
    
    logger("INFO", "CVT is initialized")  # 初期化完了のログを記録
    
    return DelaunayTriangulation.get_generators(vorn)::Dict{Int64, Tuple{Float64, Float64}}  # ボロノイ生成点を返す
end

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
# CVT mapping
function cvt_mapping(population::Population, archive::Archive)
    global vorn

    for ind in population.individuals
        distances = [norm([ind.behavior[1] - centroid[1], ind.behavior[2] - centroid[2]], 2) for centroid in values(DelaunayTriangulation.get_generators(vorn))]  # 各生成点との距離を計算
        
        closest_centroid_index = argmin(distances)  # 最も近い生成点のインデックスを取得
        
        if haskey(archive.individuals, closest_centroid_index)  # アーカイブに生成点が存在する場合
            if ind.benchmark[fit_index] < archive.individuals[closest_centroid_index].benchmark[fit_index]  # 個体の評価がアーカイブよりも良い場合
                archive.individuals[closest_centroid_index] = Individual(deepcopy(ind.genes), ind.benchmark, deepcopy(ind.behavior))  # アーカイブを更新

                archive.grid_update_counts[closest_centroid_index] += 1  # 更新カウンタをインクリメント
            end
        else  # アーカイブに生成点が存在しない場合
            archive.individuals[closest_centroid_index] = Individual(deepcopy(ind.genes), ind.benchmark, deepcopy(ind.behavior))  # 新しい個体をアーカイブに追加

            archive.grid_update_counts[closest_centroid_index] += 1  # 更新カウンタをインクリメント
        end
    end
    
    return archive  # 更新されたアーカイブを返す
end

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
#                                                                                                    #
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#