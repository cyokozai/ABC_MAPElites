#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
#       Fitness function                                                                             #
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#

using Random         # 乱数生成

using Distributions  # 確率分布

#----------------------------------------------------------------------------------------------------#

include("benchmark.jl")  # ベンチマーク関数

include("config.jl")     # 設定ファイル

#----------------------------------------------------------------------------------------------------#
# Noise setting
# The flag of the fitness value. | 'true' is available when you want to add the noise to the fitness.
const fit_index = FIT_NOISE ? 1 : 2

# Constant of the noise. | Noise range is [-r_noise, r_noise]
const σ = r_noise / 4.0

# Normal distribution for the noise.
const N_noise = Normal(0.0, σ^(2.0))

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
# Fitness function
fitness(x::Float64) = x >= 0 ?  1.0 / (1.0 + x) : 1.0 + abs(x)

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
# Noise function with Gaussian function
noise(gene::Vector{Float64}) = FIT_NOISE ? [sum(x + rand(RNG, N_noise) for _ in 1:MEAN_GENE) / MEAN_GENE for x in gene] : gene

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
#                                                                                                    #
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#