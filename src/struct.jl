#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
#       Import struct                                                                                #
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
# Individual
mutable struct Individual

    genes::Vector{Float64}             # N dimension vector | N次元ベクトル

    benchmark::Tuple{Float64, Float64} # Benchmark value (1: with noise, 2: without noise) | ベンチマーク値 (1: ノイズあり, 2: ノイズなし)

    behavior::Vector{Float64}          # Behavior space | 行動空間

end

#----------------------------------------------------------------------------------------------------#
# Population
mutable struct Population

    individuals::Vector{Individual} # Group of individuals | 個体群

end

#----------------------------------------------------------------------------------------------------#
# Archive
mutable struct Archive

    grid::Matrix{Int64}                  # Grid map | グリッドマップ

    grid_update_counts::Vector{Int64}    # Grid update counts | グリッド更新回数

    individuals::Dict{Int64, Individual} # Individuals | 個体
    
end

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
#                                                                                                    #
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#