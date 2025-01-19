#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
#       Fitness function                                                                             #
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#

using Random

using Distributions

#----------------------------------------------------------------------------------------------------#

include("benchmark.jl")

include("config.jl")

#----------------------------------------------------------------------------------------------------#
# Noise setting
# The flag of the fitness value. | 'true' is available when you want to add the noise to the fitness.
const fit_index = FIT_NOISE ? 1 : 2

# Constant of the noise. | Noise range is [-r_noise, r_noise]
const σ = r_noise / 9.0

# Normal distribution for the noise.
const N_noise = Normal(0.0, σ^(2.0))

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
# Fitness function
fitness(x::Float64) = x >= 0 ?  1.0 / (1.0 + x) : 1.0 + abs(x)

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
# Noise function with Gaussian function
noise(gene::Vector{Float64}) = FIT_NOISE ? [x_i + rand(RNG, N_noise) for x_i in gene] : gene

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
#                                                                                                    #
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#