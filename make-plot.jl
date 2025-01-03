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

#----------------------------------------------------------------------------------------------------#

include("config.jl")

include("logger.jl")

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#

global MAXTIME = 100000

function MakeFigure()
    fig = CairoMakie.Figure()
    
    ax = if ARGS[1] == "test"
        [
        Axis(
            fig[1, 1],
            limits = ((0-2000, MAXTIME), (1.0e-6, 1.0e+6)),
            xlabelsize=18,
            xlabel=L"\mathrm{Generation\,} (\times 10^4)",
            ylabelsize=18,
            ylabel=L"\mathrm{Fitness\,}",
            title="Test data",
            xticks=(0:2*10^4:MAXTIME, string.([0, 2, 4, 6, 8, 10])),
            xminorticks = IntervalsBetween(2),
            yscale=log10,
            yticks=(10.0 .^ (-6.0:2.0:6.0), string.(["1.0e-06", "1.0e-04", "1.0e-02", "1.0e+00", "1.0e+02", "1.0e+04", "1.0e+06"])),
            yminorticks = IntervalsBetween(5),
            width = 720,
            height = 560
        )
        ]
    elseif ARGS[2] == "rosenbrock" && ARGS[1] == "10"
        [
        Axis(
            fig[1, 1],
            limits = ((0-2000, MAXTIME), (1.0e-4, 1.0e+8)),
            xlabelsize=18,
            xlabel=L"\text{Generation} \quad (\times 10^4)",
            ylabelsize=18,
            ylabel=L"\text{Fitness}",
            xticks=(0:2*10^4:MAXTIME, string.([0, 2, 4, 6, 8, 10])),
            xminorticks = IntervalsBetween(2),
            yscale=log10,
            yticks=(10.0 .^ (-4.0:2.0:8.0), string.(["1.0e-04", "1.0e-02", "1.0e+00", "1.0e+02", "1.0e+04", "1.0e+06", "1.0e+08"])),
            yminorticks = IntervalsBetween(5),
            width = 720,
            height = 560
        )
        ]
    elseif ARGS[2] == "rosenbrock" && ARGS[1] != "10"
        [
        Axis(
            fig[1, 1],
            limits = ((0-2000, MAXTIME), (1.0e-2, 1.0e+10)),
            xlabelsize=18,
            xlabel=L"\text{Generation} \quad (\times 10^4)",
            ylabelsize=18,
            ylabel=L"\text{Fitness}",
            xticks=(0:2*10^4:MAXTIME, string.([0, 2, 4, 6, 8, 10])),
            xminorticks = IntervalsBetween(2),
            yscale=log10,
            yticks=(10.0 .^ (-2.0:2.0:10.0), string.(["1.0e-02", "1.0e+00", "1.0e+02", "1.0e+04", "1.0e+06", "1.0e+08", "1.0e+10"])),
            yminorticks = IntervalsBetween(5),
            width = 720,
            height = 560
        )
        ]
    else
        [
        Axis(
            fig[1, 1],
            limits = ((0-2000, MAXTIME), (1.0e-6, 1.0e+6)),
            xlabelsize=18,
            xlabel=L"\text{Generation} \quad (\times 10^4)",
            ylabelsize=18,
            ylabel=L"\text{Fitness}",
            xticks=(0:2*10^4:MAXTIME, string.([0, 2, 4, 6, 8, 10])),
            xminorticks = IntervalsBetween(2),
            yscale=log10,
            yticks=(10.0 .^ (-6.0:2.0:6.0), string.(["1.0e-06", "1.0e-04", "1.0e-02", "1.0e+00", "1.0e+02", "1.0e+04", "1.0e+06"])),
            yminorticks = IntervalsBetween(5),
            width = 720,
            height = 560
        )
        ]
    end
    
    resize_to_layout!(fig)
    
    return fig, ax
end

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#

function ReadData(dir::String)
    println("Read data: $dir")
    mlist = ["default", "de", "abc", "default", "de", "abc"]
    Data = Dict{String, Array{Float64, 2}}()

    if ARGS[1] == "test"
        filepath = [path for path in readdir(dir) if occursin("-$(ARGS[1])-", path) && occursin("fitness", path)]
        data = Array{Float64, 2}(undef, length(filepath), MAXTIME)

        if length(filepath) == 0
            println("No such file: $(ARGS)")
            
            return nothing
        else
            for (i, f) in enumerate(filepath)
                o_val, old, parsed_value = 0.0, 0.0, 0.0

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

                                if parsed_value == 0.0
                                    data[i, j] = old
                                else
                                    o_val = 1.0/parsed_value - 1.0

                                    if o_val < 0.0
                                        data[i, j] = abs(parsed_value - 1.0)
                                    else
                                        data[i, j] = o_val
                                    end
                                end

                                old = parsed_value
                                j += 1
                            end
                        end
                    end
                end
            end
        end

        Data["test"] = data
    else
        for (m, method) in enumerate(mlist)
            filepath = if m <= 3
                [path for path in readdir("$(dir)$(method)/$(ARGS[2])/") if occursin("-$(ARGS[1]).", path) && occursin("-$(ARGS[2])-", path) && occursin("fitness-2", path)]
            else
                [path for path in readdir("$(dir)$(method)/$(ARGS[2])/") if occursin("-$(ARGS[1]).", path) && occursin("-$(ARGS[2])-", path) && occursin("fitness-noise-2", path)]
            end
            data = Array{Float64, 2}(undef, length(filepath), MAXTIME)

            if length(filepath) == 0
                println("No such file: $ARGS")
                
                return nothing
            else
                for (i, f) in enumerate(filepath)
                    if occursin(".dat", f)
                        j, reading_data = 1, false
                        
                        open("$(dir)$(method)/$(ARGS[2])/$f", "r") do io # ファイルを開く
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
                                        if parsed_value == 0.0
                                            data[i, j] = 1.0e+2
                                        else
                                            o_val = 1.0/parsed_value - 1.0

                                            if o_val < 0.0
                                                data[i, j] = abs(parsed_value - 1.0)
                                            else
                                                data[i, j] = o_val
                                            end
                                        end

                                        j += 1
                                    end
                                end
                            end
                        end
                    end
                end
            end

            if m <= 3
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
        
        n, ls, cr = if key == "test" || key == "default"
            1, :solid, :red
        elseif key == "de"
            1, :solid, :blue
        elseif key == "abc"
            1, :solid, :green
        elseif key == "default-noised"
            2, :dash, :red
        elseif key == "de-noised"
            2, :dash, :blue
        elseif key == "abc-noised"
            2, :dash, :green
        end
        
        linedata[key] = lines!(axis[1], 1:length(average_data), average_data, linestyle=ls,  linewidth=1.2, color=cr)
        push!(keys, key)
    end

    axislegend(
        axis[1],
        [linedata["default"], linedata["default-noised"], linedata["de"], linedata["de-noised"], linedata["abc"], linedata["abc-noised"]],
        ["Default", "Default (Noised)", "DE", "DE (Noised)", "ABC", "ABC (Noised)"],
        position=:cb, fontsize=16, orientation = :horizontal
    )
    
    resize_to_layout!(fig)
end

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#

function SavePDF(fig)
    if ARGS[1] == "test"
        println("Saved: result/testdata/pdf/testdata.pdf")
        save("result/testdata/pdf/fitness-testdata.pdf", fig)
    else
        println("Saved: result/graph/$(ARGS[2])-$(ARGS[1]).pdf")
        save("result/graph/$(ARGS[2])-$(ARGS[1]).pdf", fig)
    end
end

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#

function main()
    println("Start the plotting process")
    data = if ARGS[1] == "test"
        mkpath("./result/testdata/pdf/")
        ReadData("./result/testdata/")
    else
        mkpath("./result/pdf/")
        ReadData("./result/")
    end
    
    println("Read data")
    if data == ""
        println("No data to plot. Exiting.")
        
        return
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