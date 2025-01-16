using CSV
using DataFrames
using Statistics
using Printf

METHOD = ["default", "de", "abc"]

MAP = "cvt"

FUNCTION = ["rastrigin"] # "sphere", "rosenbrock", 

DIMENSION = ["10", "50", "100"]

function round_value(value::Float64)
    if abs(value) < 1e-4
        return @sprintf("%.4e", value)
    else
        return @sprintf("%.4f", value)
    end
end

function process_dat_files(input_dir::String, method::String, func::String, dim::String)
    # Initialize accumulators for storing fitness values for each rank
    noisy_fitness = Dict(i => [] for i in 1:10)
    true_fitness = Dict(i => [] for i in 1:10)

    # Read all .dat files in the input directory
    for file in filter(x -> endswith(x, ".dat"), [path for path in readdir(input_dir) if occursin("result-", path) && occursin("$(method)-$(MAP)-$(func)-$(dim)", path)]) 
        filepath = joinpath(input_dir, file)
        
        # Open and read the .dat file
        open(filepath, "r") do io
            current_rank = 0
            while !eof(io)
                line = readline(io)
                
                if occursin("Rank", line)
                    current_rank = parse(Int, match(r"Rank (\d+):", line).captures[1])
                elseif occursin("Noisy Fitness", line) && current_rank > 0
                    noisy_value = parse(Float64, split(line, ":")[2])
                    push!(noisy_fitness[current_rank], noisy_value)
                elseif occursin("True Fitness", line) && current_rank > 0
                    true_value = parse(Float64, split(line, ":")[2])
                    push!(true_fitness[current_rank], true_value)
                end
            end
        end
    end

    # Calculate averages for each rank
    results = DataFrame(Rank = 1:3, 
                        Avg_Noisy_Fitness = [round_value(mean(noisy_fitness[i])) for i in 1:3],
                        Avg_True_Fitness = [round_value(mean(true_fitness[i])) for i in 1:3])

    # Create output directory if it doesn't exist
    output_dir = joinpath(input_dir, "csv")
    if !isdir(output_dir)
        mkpath(output_dir)
    end

    # Write results to a CSV file
    output_file = "output-$(method)-$(func)-$(dim).csv"
    CSV.write(joinpath(output_dir, output_file), results)
end

function convert_method(method::String)
    if method == "default"
        return "ME"
    elseif method == "de"
        return "DME"
    elseif method == "abc"
        return "ABCME"
    else
        return method
    end
end

function aggregate_results(input_dir::String, func::String)
    data = DataFrame()
    for dim in DIMENSION
        temp_data = DataFrame()
        for (i, method) in enumerate(METHOD)
            method_name = convert_method(method)
            input_file = joinpath(input_dir, "csv", "output-$(method)-$(func)-$(dim).csv")
            df = CSV.read(input_file, DataFrame)
            df[!, :D] .= dim
            df[!, :Method] .= method_name
            if i == 1
                temp_data = hcat(temp_data, df[:, [:D, :Rank, :Avg_Noisy_Fitness, :Avg_True_Fitness]])
                rename!(temp_data, [:D => :D, :Rank => :Rank, :Avg_Noisy_Fitness => Symbol("$(method_name)_Noisy"), :Avg_True_Fitness => Symbol("$(method_name)_True")])
            else
                temp_data = hcat(temp_data, df[:, [:Avg_Noisy_Fitness, :Avg_True_Fitness]])
                rename!(temp_data, [:Avg_Noisy_Fitness => Symbol("$(method_name)_Noisy"), :Avg_True_Fitness => Symbol("$(method_name)_True")])
            end
        end
        data = vcat(data, temp_data)
    end
    return data
end

function make_table(input_dir::String, output_file::String, func::String)
    # 結果を集約
    df = aggregate_results(input_dir, func)

    # LaTeXテーブルのヘッダー部分を作成
    header = """
    \\begin{table}[h]
        \\centering
        \\caption{Rank of methods on $(func)} 
        \\begin{tabular}{rr|D{.}{.}{2.7}D{.}{.}{2.7}|D{.}{.}{2.7}D{.}{.}{2.7}|D{.}{.}{2.7}D{.}{.}{2.7}}
            \\hline
            \\multirow{2}{*}{\$D\$} & \\multirow{2}{*}{Rank} & \\multicolumn{2}{c|}{ME} & \\multicolumn{2}{c|}{DME} & \\multicolumn{2}{c}{ABCME} \\\\
             & & \\multicolumn{1}{c}{Noisy} & \\multicolumn{1}{c|}{True} & \\multicolumn{1}{c}{Noisy} & \\multicolumn{1}{c|}{True} & \\multicolumn{1}{c}{Noisy} & \\multicolumn{1}{c}{True} \\\\
            \\hline
            \\hline
    """

    # テーブルの行を作成
    rows = ""
    for dim in DIMENSION
        dim_rows = join(["& $(row.Rank) & $(row.ME_Noisy) & $(row.ME_True) & $(row.DME_Noisy) & $(row.DME_True) & $(row.ABCME_Noisy) & $(row.ABCME_True) \\\\" for row in eachrow(df) if row.D == dim], "\n")
        rows *= "\\multirow{3}{*}{$dim} " * dim_rows * "\n\\hline\n"
    end

    # LaTeXテーブルのフッター部分を作成
    footer = """
        \\end{tabular}
        \\label{tab:rank-methods-$(func)}
    \\end{table}
    """

    # 完全なLaTeXコードを組み立てる
    latex_code = header * rows * footer

    # Create output directory if it doesn't exist
    output_dir = joinpath(dirname(output_file))
    if !isdir(output_dir)
        mkpath(output_dir)
    end

    # テキストファイルに書き込む
    open(output_file, "w") do file
        write(file, latex_code)
    end

    println("LaTeX table has been written to $output_file.")
end

# Example usage:
for func in FUNCTION
    for method in METHOD
        for dim in DIMENSION
            process_dat_files("./result", method, func, dim)
        end
    end
    make_table("./result", "./result/latex/table-$(func).tex", func)
end
