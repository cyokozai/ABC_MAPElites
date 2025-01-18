#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
#       Config                                                                                       #
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#

using StableRNGs

using Dates

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
# Method
# Objective function: sphere, rosenbrock, rastrigin, griewank, ackley, schwefel, michalewicz
OBJ_F      = length(ARGS) > 3 ? ARGS[4] : "sphere"

# MAP Method: grid, cvt
MAP_METHOD = length(ARGS) > 2 ? ARGS[3] : "cvt"

# Method: default, abc, de
METHOD     = length(ARGS) > 1 ? ARGS[2] : "abc"

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
# Parameter
# Random seed
SEED      = Int(Dates.now().instant.periods.value)

# Random number generator
RNG       = StableRNG(SEED)

# Number of dimensions
D         = length(ARGS) > 0 && ARGS[1] == "test" ? 2 : parse(Int64, ARGS[1])

# Number of population size
N         = 64

# Dumber of behavior dimensions | No need to change because it isn't available.
BD        = 2

# Convergence flag | 'true' is available when you want to check the convergence.
CONV_FLAG = false

# Epsiron | Default: 1e-6
EPS       = 1e-6

# Fitness noise | 'true' is available when you want to add the noise to the fitness.
FIT_NOISE = true

# Noise rate | Default: 0.01
r_noise   = 0.01

# Number of max time | Default: 100000
MAXTIME   = if CONV_FLAG == false
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
    100000
end

if length(ARGS) > 0 && ARGS[1] == "test"
    MAXTIME = 100
end

#----------------------------------------------------------------------------------------------------#
# Map parameter
# MAP_METHOD == grid: Number of grid size.
GRID_SIZE = 158

# MAP_METHOD == cvt: Number of max k.
k_max     = 25000

# Number of mutation rate
MUTANT_R  = 0.90

#----------------------------------------------------------------------------------------------------#
# Voronoi parameter
# Voronoi data update limit | Default: 3
cvt_vorn_data_update_limit = length(ARGS) > 4 ? parse(Int64, ARGS[5]) : 3

# CVT Max iteration | Default: 100
CVT_MAX_ITER               = 100

#----------------------------------------------------------------------------------------------------#
# DE parameter
# The crossover probability | default: 0.9
# The differentiation (mutation) scaling factor (default: 0.9).
CR, F = if OBJ_F == "sphere"
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
FOOD_SOURCE = N

# Limit number: The number of limit trials that the scout bee can't find the better solution.
TC_LIMIT    = D * floor(Int, k_max / (10 * FOOD_SOURCE))

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
# Result file
output = "./result/"

if !isdir(output) || !isdir("$(output)$(METHOD)/$(OBJ_F)/") || !isdir("./log/")
    mkpath(output)
    mkpath("$(output)$(METHOD)/$(OBJ_F)/")
    mkpath("./log/")
end

# Date
DATE    = Dates.format(now(), "yyyy-mm-dd-HH-MM")
LOGDATE = Dates.format(now(), "yyyy-mm-dd")

# File name
FILENAME   = length(ARGS) > 0 && ARGS[1] == "test" ? "$(DATE)-test" : "$(METHOD)-$(MAP_METHOD)-$(OBJ_F)-$(D)-$(DATE)"
F_RESULT   = "result-$(FILENAME).dat"
F_FITNESS  = "fitness-$(FILENAME).dat"
F_FIT_N    = "fitness-noise-$(FILENAME).dat"
F_BEHAVIOR = "behavior-$(FILENAME).dat"
F_LOGFILE  = "log-$(METHOD)-$(OBJ_F)-$(LOGDATE).log"

# EXIT CODE: 0: Success, 1: Failure
exit_code = 0

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
#                                                                                                    #
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#