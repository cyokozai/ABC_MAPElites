#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
#       Make plot                                                                                    #
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#

using Printf

using LaTeXStrings

using Dates

using FileIO

using JLD2

using DelaunayTriangulation

using CairoMakie

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#

global MAXTIME = 100000

dimension = ARGS[1]
function_name = ARGS[2]

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#

function MakeFigure()
    fig = CairoMakie.Figure(size=(800, 600), fontsize=24, px_per_unit=2)
    
    ax = if ARGS[1] == "test"
        [
        Axis(
            fig[1, 1],
            limits=((0-2000, MAXTIME), (1.0e-6, 1.0e+6)),
            xlabel=L"\mathrm{Generation} (\times 10^4)",
            ylabel=L"\mathrm{Function value}",
            title="Test data",
            xticks=(0:2*10^4:MAXTIME, string.([0, 2, 4, 6, 8, 10])),
            xminorticks=IntervalsBetween(2),
            yscale=log10,
            yticks=(10.0 .^ (-6.0:2.0:6.0), string.(["1.0e-06", "1.0e-04", "1.0e-02", "1.0e+00", "1.0e+02", "1.0e+04", "1.0e+06"])),
            yminorticks=IntervalsBetween(5),
            width=720,
            height=560
        )
        ]
    else
        [
        Axis(
            fig[1, 1],
            limits=((0-2000, MAXTIME), (1.0e-4, 1.0e+6)),
            xlabel=L"\text{Generation} \quad (\times 10^4)",
            ylabelsize=24,
            ylabel=L"\text{Function value}",
            xticks=(0:2*10^4:MAXTIME, string.([0, 2, 4, 6, 8, 10])),
            xminorticks=IntervalsBetween(2),
            yscale=log10,
            yticks=(10.0 .^ (-4.0:2.0:6.0), string.(["1.0e-04", "1.0e-02", "1.0e+00", "1.0e+02", "1.0e+04", "1.0e+06"])),
            yminorticks=IntervalsBetween(5),
            width=720,
            height=560
        )
        ]
    end
    
    resize_to_layout!(fig)
    
    return fig, ax
end

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#

function ReadData(dir::String)
    println("Read data: $dir")
    mlist = ["me", "de", "abc", "me", "de", "abc"] # "me", "de", "abc", "me", "de", "abc"
    Data = Dict{String, Array{Float64, 2}}()

    if ARGS[1] == "test"
        filepath = [path for path in readdir(dir) if occursin("-$(ARGS[1])-", path) && occursin("fitness", path)]
        data = Array{Float64, 2}(undef, length(filepath), MAXTIME)

        if length(filepath) == 0
            println("No such file: $filepath")
            
            return nothing
        else
            for (i, f) in enumerate(filepath)
                parsed_value = 0.0

                if occursin(".dat", f)
                    j, reading_data = 1, false
                    
                    open("$dir$f", "r") do io # ファイルを開く
                        for line in eachline(io) # ファイルを1行ずつ読み込む
                            if occursin("=", line) # ボーダーラインを検出
                                if !reading_data # データ読み取り開始
                                    reading_data = true
                                    
                                    continue
                                else # 2つ目のボーダーラインに到達したら終了
                                    break
                                end
                            end
                            
                            if reading_data
                                parsed_value = tryparse(Float64, line)
                                
                                if parsed_value !== nothing
                                    data[i, j] = parsed_value
                                    
                                    j += 1
                                end
                            end
                        end
                    end
                end
            end
        end

        Data["test"] = data
    else
        for (m, method) in enumerate(mlist)
            filepath = if m <= length(mlist) / 2
                [path for path in readdir("$(dir)/$(method)/$(function_name)/") if occursin("-$(dimension)-", path) && occursin("$(function_name)", path) && occursin("fitness-", path)]
            else
                [path for path in readdir("$(dir)/$(method)/$(function_name)/") if occursin("-$(dimension)-", path) && occursin("$(function_name)", path) && occursin("fitness-noise-", path)]
            end
            data = Array{Float64, 2}(undef, length(filepath), MAXTIME)

            if length(filepath) == 0
                println("No such file: $filepath")
                
                return nothing
            else
                for (i, f) in enumerate(filepath)
                    if occursin(".dat", f)
                        j, reading_data = 1, false
                        
                        open("$(dir)/$(method)/$(function_name)/$f", "r") do io # ファイルを開く
                            for line in eachline(io) # ファイルを1行ずつ読み込む
                                if occursin("=", line) # ボーダーラインを検出
                                    if !reading_data # データ読み取り開始
                                        reading_data = true
                                        
                                        continue
                                    else # 2つ目のボーダーラインに到達したら終了
                                        break
                                    end
                                end
                                
                                if reading_data
                                    parsed_value = tryparse(Float64, line)
                                    
                                    if parsed_value !== nothing
                                        data[i, j] = parsed_value
                                        
                                        j += 1
                                    end
                                end
                            end
                        end
                    end
                end
            end

            if m <= length(mlist) / 2
                Data["$(method)"] = data
            else
                Data["$(method)-noised"] = data
            end
        end
    end
    
    return Data
end

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#

function PlotData(Data, fig, axis)
    linedata = Dict{String, Any}()
    keys = String[]
    
    for (key, data) in Data
        sum_data = zeros(size(data, 2))
        
        for j in 1:size(data, 1)
            sum_data .+= data[j, :] # Sum data
        end
        
        average_data = sum_data ./ Float64(size(data, 1)) # Calculate average data
        
        average_data = [abs(x) for x in average_data]
        
        n, ls, cr = if key == "test" || key == "me"
            1, :dash, :red
        elseif key == "de"
            1, :dash, :blue
        elseif key == "abc"
            1, :dash, :green
        elseif key == "me-noised"
            2, :solid, :red
        elseif key == "de-noised"
            2, :solid, :blue
        elseif key == "abc-noised"
            2, :solid, :green
        end
        
        linedata[key] = lines!(axis[1], 1:length(average_data), average_data, linestyle=ls,  linewidth=1.2, color=cr)
        push!(keys, key)
    end

    Legend(
        fig[1, 2],
        [linedata["me"], linedata["me-noised"], linedata["de"], linedata["de-noised"], linedata["abc"], linedata["abc-noised"]],
        ["ME", "ME (Noised)", "DME", "DME (Noised)", "ABCME", "ABCME (Noised)"],
        fontsize=48, markersize=30
    )
    
    resize_to_layout!(fig)
end

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#

function SavePDF(fig)
    if ARGS[1] == "test"
        println("Saved: result/testdata/pdf/fitness-testdata.pdf")
        save("result/testdata/pdf/fitness-testdata.pdf", fig)
    else
        if !isdir("result/graph")
            mkpath("result/graph")
        end

        println("Saved: result/graph/$(function_name)-$(dimension).pdf")
        save("result/graph/$(function_name)-$(dimension).pdf", fig)
    end
end

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#

function main()
    println("Start the plotting process")
    data = if ARGS[1] == "test"
        if isdir("result/testdata")
            mkpath("result/testdata/pdf")
        end

        ReadData("result/testdata")
    else
        if isdir("result/pdf")
            mkpath("result/pdf")
        end

        ReadData("result")
    end
    
    println("Read data")
    
    if data === nothing
        println("No data to plot. Exiting.")
        return 1
    end

    println("Make figure")
    figure, axis = MakeFigure()

    println("Plot data")
    PlotData(data, figure, axis)
    
    println("Save PDF")
    SavePDF(figure)
end

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#

# try
#     main()
# catch e
#     logger("ERROR", e)

#     global exit_code = 1
# finally
#     logger("INFO", "Finish the plotting process")

#     exit(exit_code)
# end
main()

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
#                                                                                                    #
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#