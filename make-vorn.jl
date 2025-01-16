#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
#       Make vorn                                                                                    #
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#

using JLD2

using DelaunayTriangulation

using CairoMakie

#----------------------------------------------------------------------------------------------------#

include("config.jl")

include("benchmark.jl")

include("logger.jl")

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#

dimention = ARGS[1]
method_name = ARGS[2]
map_name = ARGS[3]
function_name = ARGS[4]
cvtchange = ARGS[5]


closeup = if function_name == "rastrigin"
    0.25
elseif function_name == "rosenbrock"
    0.25
elseif function_name == "sphere"
    0.1
end

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#

fitness(x::Float64) = x >= 0 ?  1.0 / (1.0 + x) : abs(1.0 + x)

load_path = if dimention == "test"
    global LOW, UPP = -5.12, 5.12
    dir = "./result/testdata/"
    if !isdir(dir)
        error("Directory $dir does not exist.")
    end

    [path for path in readdir(dir) if occursin("test-", path) && occursin("CVT-", path)]
else
    dir = "./result/$(method_name)/$(function_name)/"
    if !isdir(dir)
        error("Directory $dir does not exist.")
    end
    [path for path in readdir(dir) if occursin("CVT-", path) && occursin("$(method_name)-$(map_name)-$(function_name)-$(dimention)", path)]
end

if isempty(load_path)
    error("No files found matching the criteria.")

    exit(1)
else
    println("Found $(length(load_path[end])) files matching the criteria.")
end

loadpath = joinpath(dir, load_path[end])
println(loadpath)

m = match(r"CVT-(\d{4}-\d{2}-\d{2}-\d{2}-\d{2})", load_path[end])
filedate = m !== nothing ? m.captures[1] : ""
println("Extracted date: ", filedate)

load_vorn = load(loadpath, "voronoi")

individualData = Vector{Tuple{Float64, Float64}}()
updateCountData = Vector{Int64}()
fitnessData = Vector{Float64}()
BestPoint = Vector{Tuple{Float64, Float64}}()

filepath = if dimention == "test"
    dir = "./result/testdata/"

    if !isdir(dir)
        error("Directory $dir does not exist.")
    end
    
    [path for path in readdir(dir) if occursin("test-", path) && occursin("result-", path)]
else
    dir = "./result/$(method_name)/$(function_name)/"
    
    if !isdir(dir)
        error("Directory $dir does not exist.")
    end

    [path for path in readdir(dir) if occursin("result-$(method_name)-$(map_name)-$(function_name)-$(dimention)-$(filedate)", path)]
end

if occursin(".dat", filepath[end])
    println("Reading: ", joinpath(dir, filepath[end]))
    
    open(joinpath(dir, filepath[end]), "r") do io  # Use joinpath to construct the full path
        reading_data = false # ボーダーライン検出用フラグ
        border_count = 0  # ボーダーラインのカウント
        
        for (k, line) in enumerate(eachline(io)) # ファイルを1行ずつ読み込む
            if occursin("=", line) # ボーダーラインを検出
                border_count += 1

                if border_count == 1 # 1つ目のボーダーラインに到達したらデータ読み取り開始
                    reading_data = true

                    continue
                elseif border_count == 2
                    reading_data = false

                    continue
                end
            end
            
            if reading_data
                parsed_value = tryparse(Int64, line)
                
                if parsed_value !== nothing
                    push!(updateCountData, parsed_value)  # Use push! to add elements to Data
                end
            elseif occursin("Best behavior:", line)
                m = Base.match(r"\[(-?\d+\.\d+),\s*(-?\d+\.\d+)\]", line)  # Use regex to extract two floats

                if m !== nothing
                    push!(BestPoint, (parse(Float64, m.captures[1]), parse(Float64, m.captures[2])))

                    break
                end
            end
        end
    end
end

if isempty(updateCountData)
    println("updateCountData is empty. Skipping color mapping and plotting.")
    exit(1)
else
    println("updateCountData: ", length(updateCountData))
end


filepath = if dimention == "test"
    dir = "./result/testdata/"

    if !isdir(dir)
        error("Directory $dir does not exist.")
    end
    
    [path for path in readdir(dir) if occursin("test-", path) && occursin("behavior-", path)]
else
    dir = "./result/$(method_name)/$(function_name)/"

    if !isdir(dir)
        error("Directory $dir does not exist.")
    end

    [path for path in readdir(dir) if occursin("behavior-$(method_name)-$(map_name)-$(function_name)-$(dimention)-$(filedate)", path)]
end

if occursin(".dat", filepath[end])
    println("Reading: ", joinpath(dir, filepath[end]))

    open(joinpath(dir, filepath[end]), "r") do io
        reading_data = false
        border_count = 0
        
        for (k, line) in enumerate(eachline(io))
            if occursin("=", line)
                border_count += 1

                if border_count == 2
                    reading_data = true

                    continue
                end
            end
            
            if reading_data
                m = Base.match(r"\[(-?\d+\.\d+),\s*(-?\d+\.\d+)\]", line)  # Use regex to extract two floats

                if m !== nothing
                    push!(individualData, (parse(Float64, m.captures[1]), parse(Float64, m.captures[2])))
                end
            end
        end
    end
end

if isempty(individualData)
    println("individualData is empty. Skipping color mapping and plotting.")
    exit(1)
else
    println("individualData: ", length(individualData))
end


filepath = if dimention == "test"
    dir = "./result/testdata/"

    if !isdir(dir)
        error("Directory $dir does not exist.")
    end
    
    [path for path in readdir(dir) if occursin("test-", path) && occursin("fitness-test-", path)]
else
    dir = "./result/$(method_name)/$(function_name)/"

    if !isdir(dir)
        error("Directory $dir does not exist.")
    end

    [path for path in readdir(dir) if occursin("fitness-noise-$(method_name)-$(map_name)-$(function_name)-$(dimention)-$(filedate)", path)]
end

if occursin(".dat", filepath[end])
    println("Reading: ", joinpath(dir, filepath[end]))

    open(joinpath(dir, filepath[end]), "r") do io
        reading_data = false
        border_count = 0
        
        for (k, line) in enumerate(eachline(io))
            if occursin("=", line)
                border_count += 1

                if border_count == 2
                    reading_data = true

                    continue
                end
            end
            
            if reading_data
                parsed_value = tryparse(Float64, line)
                
                if parsed_value !== nothing
                    push!(fitnessData, fitness(parsed_value))
                end
            end
        end
    end
end

if isempty(fitnessData)
    println("fitnessData is empty. Skipping color mapping and plotting.")
    exit(1)
else
    println("fitnessData: ", length(fitnessData))
end


for iter in ["FitnessValue"]
    colormap = if iter == "UpdateFrequency"
        cgrad(:heat)
    else
        cgrad(:viridis)
    end

    fig = Figure()

    ax = [Axis(
        fig[1, 1],
        limits = ((LOW, UPP), (LOW, UPP)),
        titlesize=18,
        xlabel = L"b_1",
        xlabelsize = 18,
        ylabel = L"b_2",
        ylabelsize = 18,
        width  = 500,
        height = 500
    ),
    Axis(
        fig[1, 3],
        limits = ((LOW * closeup, UPP * closeup), (LOW * closeup, UPP * closeup)),
        titlesize=18,
        xlabel = L"b_1",
        xlabelsize = 18,
        ylabel = L"b_2",
        ylabelsize = 18,
        width  = 500,
        height = 500
    )]

    voronoiplot!(
        ax[1],
        load_vorn,
        color = :white,
        strokewidth = 0.01,
        show_generators = false,
        clip = (LOW, UPP, LOW, UPP)
    )
    voronoiplot!(
        ax[2],
        load_vorn,
        color = :white,
        strokewidth = 0.06,
        show_generators = false,
        clip = (LOW * closeup, UPP * closeup, LOW * closeup, UPP * closeup)
    )

    resize_to_layout!(fig)

    scatter!(
        ax[1],
        titlesize=18,
        [d[1] for d in individualData],
        [d[2] for d in individualData],
        marker = :circle, 
        markersize =  7, 
        color = if iter == "UpdateFrequency"
            [(colormap[clamp(round(Int, ((fit - minimum(updateCountData)) / (maximum(updateCountData) - minimum(updateCountData))) * (length(colormap) - 1) + 1), 1, length(colormap))], 0.5 * ((fit - minimum(updateCountData)) / (maximum(updateCountData) - minimum(updateCountData)))^(1/2) + 0.4) for fit in updateCountData]
        else
            [(colormap[round(Int, fit * 255 + 1)], 0.5 * (fit^(1/2) + 0.4)) for fit in fitnessData]
        end
    )
    scatter!(
        ax[2], 
        titlesize=18,
        [d[1] for d in individualData],
        [d[2] for d in individualData],
        marker = :circle, 
        markersize = 14, 
        color = if iter == "UpdateFrequency"
            [(colormap[clamp(round(Int, ((fit - minimum(updateCountData)) / (maximum(updateCountData) - minimum(updateCountData))) * (length(colormap) - 1) + 1), 1, length(colormap))], 0.5 * ((fit - minimum(updateCountData)) / (maximum(updateCountData) - minimum(updateCountData)))^(1/2) + 0.4) for fit in updateCountData]
        else
            [(colormap[round(Int, fit * 255 + 1)], 0.5 * (fit^(1/2) + 0.4)) for fit in fitnessData]
        end
    )

    scatter!(ax[1], BestPoint, marker = :star5, markersize = 15, color = :orange)
    scatter!(ax[2], BestPoint, marker = :star5, markersize = 25, color = :orange)

    Colorbar(
        fig[1, 2],
        limits = if iter == "UpdateFrequency"
            (0, maximum(updateCountData))
        else
            (0.0, 1.0)
        end,
        titlesize=18,
        ticks = if iter == "UpdateFrequency"
            (0:maximum(updateCountData)/4:maximum(updateCountData), string.([0, "", "", "", maximum(updateCountData)]))
        else
            (0:0.25:1.0, string.(["0.00", "0.25", "0.50", "0.75", "1.00"]))
        end,
        colormap = colormap,
        label = if iter == "UpdateFrequency"
            "Update frequency"
        else
            "Fitness value"
        end
    )
    Colorbar(
        fig[1, 4],
        limits = if iter == "UpdateFrequency"
            (0, maximum(updateCountData))
        else
            (0.0, 1.0)
        end,
        titlesize=18,
        ticks = if iter == "UpdateFrequency"
            (0:maximum(updateCountData)/4:maximum(updateCountData), string.([0, "", "", "", maximum(updateCountData)]))
        else
            (0:0.25:1.0, string.(["0.00", "0.25", "0.50", "0.75", "1.00"]))
        end,
        colormap = colormap,
        label = if iter == "UpdateFrequency"
            "Update frequency"
        else
            "Fitness value"
        end
    )

    poly!(
        ax[1], 
        Rect(-UPP * closeup, -UPP * closeup, UPP * 2 * closeup, UPP * 2 * closeup),
        strokecolor = :blue,
        color = (:blue, 0.0),
        strokewidth = 1.0
    )

    resize_to_layout!(fig)

    if !isdir("result/pdf")
        mkdir("result/pdf")
    end

    if dimention == "test"
        println("Saved: result/testdata/pdf/cvt-testdata-$(iter).pdf")
        save("result/testdata/pdf/cvt-testdata-$(iter).pdf", fig)
    else
        println("Saved: result/pdf/$(function_name)-$(method_name)-$(dimention)-$(iter).pdf")
        save("result/pdf/$(function_name)-$(method_name)-$(dimention)-$(iter).pdf", fig)
    end
end