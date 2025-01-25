#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
#       Benchmark                                                                                    #
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#

include("config.jl")  # 設定ファイル

include("logger.jl")  # ログ出力用のファイル

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
# Objective function
ObjFunction = if OBJ_F == "sphere"
    # Sphere
    x::Vector{Float64} -> sum(x .^ 2)
elseif OBJ_F == "rosenbrock"
    # Rosenbrock
    x::Vector{Float64} -> sum(100 .* (x[2:end] .- x[1:end-1].^2).^2 + (1 .- x[1:end-1]).^2)
elseif OBJ_F == "rastrigin"
    # Rastrigin
    x::Vector{Float64} -> sum(x .^ 2 - 10 * cos.(2 * pi * x) .+ 10)
elseif OBJ_F == "griewank"
    # Griewank
    x::Vector{Float64} -> sum(x .^ 2 / 4000) - prod(cos.(x ./ sqrt.(1:length(x)))) + 1
elseif OBJ_F == "ackley"
    # Ackley
    x::Vector{Float64} -> -20 * exp(-0.2 * sqrt(sum(x .^ 2) / length(x))) - exp(sum(cos.(2 * pi * x)) / length(x)) + 20 + exp(1)
elseif OBJ_F == "schwefel"
    # Schwefel
    x::Vector{Float64} -> 418.9829 * length(x) - sum(x .* sin.(sqrt.(abs.(x))))
else
    logger("ERROR", "Objective function is invalid")  # 目的関数が無効であることをエラーログに記録 -> 終了

    exit(1)
end

#----------------------------------------------------------------------------------------------------#
# Objective function | Average of the objective function
objective_function(x::Vector{Float64}) = sum(ObjFunction(x) for _ in 1:MEAN_GENE) / MEAN_GENE

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
# Number of solution and bounds
SOLUTION, LOW, UPP = if OBJ_F == "sphere"
    # Sphere
    [zeros(D), -5.12, 5.12]
elseif OBJ_F == "rosenbrock"
    # Rosenbrock
    [zeros(D), -5.00, 5.00]
elseif OBJ_F == "rastrigin"
    # Rastrigin
    [zeros(D), -5.12, 5.12]
elseif OBJ_F == "griewank"
    # Griewank
    [zeros(D), -512.0, 512.0]
elseif OBJ_F == "ackley"
    # Ackley
    [zeros(D), -32.0, 32.0]
elseif OBJ_F == "schwefel"
    # Schwefel
    [zeros(D), -500.0, 500.0]
else
    logger("ERROR", "Objective parameter is invalid")  # 目的関数パラメータが無効であることをエラーログに記録 -> 終了
    
    exit(1)
end

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
#                                                                                                    #
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#