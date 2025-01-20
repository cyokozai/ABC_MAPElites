#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
#       Config                                                                                       #
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#

using StableRNGs

using Dates

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
# Method and Objective function
# Method: me, abc, de
const METHOD     = length(ARGS) > 1 ? ARGS[2] : "abc"
if METHOD != "me" && METHOD != "abc" && METHOD != "de"
    println("Error: The method is not available.")

    exit(1)
end

# MAP Method: grid, cvt
const MAP_METHOD = length(ARGS) > 2 ? ARGS[3] : "cvt"
if MAP_METHOD != "grid" && MAP_METHOD != "cvt"
    println("Error: The MAP method is not available.")

    exit(1)
end

# Objective function: sphere, rosenbrock, rastrigin, griewank, ackley, schwefel, michalewicz
const OBJ_F      = length(ARGS) > 3 ? ARGS[4] : "sphere"
if OBJ_F != "sphere" && OBJ_F != "rosenbrock" && OBJ_F != "rastrigin" && OBJ_F != "griewank" && OBJ_F != "ackley" && OBJ_F != "schwefel" && OBJ_F != "michalewicz"
    println("Error: The objective function is not available.")

    exit(1)
end

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
# Random Number Generator
# Random seed
SEED = Int(Dates.now().instant.periods.value)

# Random number generator
RNG  = StableRNG(SEED)

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
# Parameters
# Number of dimensions
const D         = length(ARGS) > 0 && ARGS[1] == "test" ? 2 : parse(Int64, ARGS[1])

# Number of population size | Default: 64
const N         = 64

# Dumber of behavior dimensions | Default: 2
const BD        = 2

# Convergence flag | 'true' is available when you want to check the convergence.
const CONV_FLAG = false

# Epsiron | Default: 1e-6
const EPS       = 1e-6

# Number of max time | Default: 100000
const MAXTIME   = if ARGS[1] == "test"
    100
elseif CONV_FLAG == false
    100000
elseif OBJ_F == "sphere"
    # Sphere
    30000
elseif OBJ_F == "rosenbrock"
    # Rosenbrock
    60000
elseif OBJ_F == "rastrigin"
    # Rastrigin
    50000
elseif OBJ_F == "griewank"
    # Griewank
    30000
elseif OBJ_F == "ackley"
    # Ackley
    30000
elseif OBJ_F == "schwefel"
    # Schwefel
    30000
else
    println("Error: The objective function is not available.")

    exit(1)
end

#----------------------------------------------------------------------------------------------------#
# Noise parameter
# Fitness noise | 'true' is available when you want to add the noise to the fitness.
const FIT_NOISE = true

# Noise rate | Default: 0.01
const r_noise   = 0.01

#----------------------------------------------------------------------------------------------------#
# Map parameter
# MAP_METHOD == grid: Number of grid size. | Default: 158
const GRID_SIZE = 158

# MAP_METHOD == cvt: Number of max k. | Default: 25000
const k_max     = 25000

# Voronoi data update limit | Default: 3
const cvt_vorn_data_update_limit = length(ARGS) > 4 ? parse(Int64, ARGS[5]) : 3

# CVT Max iteration | Default: 100
const CVT_MAX_ITER               = 100

#----------------------------------------------------------------------------------------------------#
# MAP-Elites parameter
# Number of mutation rate | Default: 0.90
const MUTANT_R  = 0.90

#----------------------------------------------------------------------------------------------------#
# DE parameter
# The crossover probability / The differentiation (mutation) scaling factor | Default: 0.80 / 0.90
const CR, F = if METHOD == "abc"
    [0.50, 0.00]
elseif OBJ_F == "sphere"
    [0.20, 0.40]
elseif OBJ_F == "rosenbrock"
    [0.70, 0.80]
elseif OBJ_F == "rastrigin"
    [0.50, 0.60]
elseif OBJ_F == "griewank"
    [0.40, 0.50]
elseif OBJ_F == "ackley"
    [0.20, 0.50]
elseif OBJ_F == "schwefel"
    [0.20, 0.50]
else
    [0.80, 0.90]
end

#----------------------------------------------------------------------------------------------------#
# ABC parameter
# Food source: The number of limit trials that the employed bee can't find the better solution.
const FOOD_SOURCE = N

# Limit number: The number of limit trials that the scout bee can't find the better solution.
const TC_LIMIT    = D * floor(Int, k_max / (10 * FOOD_SOURCE))

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
# Result file
const output = "./result/"

if !isdir(output) || !isdir("$(output)$(METHOD)/$(OBJ_F)/") || !isdir("./log/")
    mkpath(output)
    mkpath("$(output)$(METHOD)/$(OBJ_F)/")
    mkpath("./log/")
end

# Date
const DATE    = Dates.format(now(), "yyyy-mm-dd-HH-MM")
const LOGDATE = Dates.format(now(), "yyyy-mm-dd")

# File name
const FILENAME   = length(ARGS) > 0 && ARGS[1] == "test" ? "$(DATE)-test" : "$(METHOD)-$(MAP_METHOD)-$(OBJ_F)-$(D)-$(DATE)"
const F_RESULT   = "result-$(FILENAME).dat"
const F_FITNESS  = "fitness-$(FILENAME).dat"
const F_FIT_N    = "fitness-noise-$(FILENAME).dat"
const F_BEHAVIOR = "behavior-$(FILENAME).dat"
const F_LOGFILE  = "log-$(METHOD)-$(OBJ_F)-$(LOGDATE).log"

# EXIT CODE: 0: Success, 1: Failure
exit_code = 0

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
#                                                                                                    #
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#