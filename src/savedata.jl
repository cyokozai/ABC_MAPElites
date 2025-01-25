#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
#       Save data to the result directory                                                            #
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#

using Printf  # フォーマット付き文字列を出力

using Dates   # 日付と時間

#----------------------------------------------------------------------------------------------------#

include("config.jl")    # 設定ファイル

include("struct.jl")    # 構造体

include("fitness.jl")   # 適応度

include("cvt.jl")       # CVT関連のファイル

include("logger.jl")    # ログ出力用のファイル

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
# Make result directory and log file
function MakeFiles()
    open("$(output)$METHOD/$OBJ_F/$F_RESULT", "w") do fr
        println(fr, "Date: ", DATE)
        println(fr, "Method: ", METHOD)
        if METHOD == "de"
            println(fr, "F: ", F)
            println(fr, "CR: ", CR)
        elseif METHOD == "abc"
            println(fr, "Trial count limit: ", TC_LIMIT)
        end
        println(fr, "Map: ", MAP_METHOD)
        if MAP_METHOD == "grid"
            println(fr, "Grid size: ", GRID_SIZE)
        elseif MAP_METHOD == "cvt"
            println(fr, "Voronoi point: ", k_max)
        end
        println(fr, "Noise: ", FIT_NOISE)
        println(fr, "Benchmark: ", OBJ_F)
        println(fr, "Dimension: ", D)
        println(fr, "Population size: ", N)
        println(fr, "===================================================================================")
    end

    if FIT_NOISE  # ノイズがある場合
        open("$(output)$METHOD/$OBJ_F/$F_FIT_N", "w") do ffn  # fitness.dat ファイルを開く
            println(ffn, "Date: ", DATE)
            println(ffn, "Method: ", METHOD)
            if METHOD == "de"
                println(ffn, "F: ", F)
                println(ffn, "CR: ", CR)
            elseif METHOD == "abc"
                println(ffn, "Trial count limit: ", TC_LIMIT)
            end
            println(ffn, "Map: ", MAP_METHOD)
            if MAP_METHOD == "grid"
                println(ffn, "Grid size: ", GRID_SIZE)
            elseif MAP_METHOD == "cvt"
                println(ffn, "Voronoi point: ", k_max)
            end
            println(ffn, "Noise: ", FIT_NOISE)
            println(ffn, "Benchmark: ", OBJ_F)
            println(ffn, "Dimension: ", D)
            println(ffn, "Population size: ", N)
            println(ffn, "===================================================================================")
        end
    end

    open("$(output)$METHOD/$OBJ_F/$F_FITNESS", "w") do ff  # futness.dat ファイルを開く
        println(ff, "Date: ", DATE)
        println(ff, "Method: ", METHOD)

        if METHOD == "de"  #DME
            println(ff, "F: ", F)
            println(ff, "CR: ", CR)
        elseif METHOD == "abc"  #ABCME
            println(ff, "Trial count limit: ", TC_LIMIT)
        end

        println(ff, "Map: ", MAP_METHOD)

        if MAP_METHOD == "grid"  # グリッドマップの場合
            println(ff, "Grid size: ", GRID_SIZE)
        elseif MAP_METHOD == "cvt"  # CVTマップの場合
            println(ff, "Voronoi point: ", k_max)
        end

        println(ff, "Noise: ", FIT_NOISE)
        println(ff, "Benchmark: ", OBJ_F)
        println(ff, "Dimension: ", D)
        println(ff, "Population size: ", N)
        println(ff, "===================================================================================")
    end

    open("$(output)$METHOD/$OBJ_F/$F_BEHAVIOR", "w") do fb
        println(fb, "Date: ", DATE)
        println(fb, "Method: ", METHOD)
        if METHOD == "DE"  #DME
            println(fb, "F: ", F)
            println(fb, "CR: ", CR)
        elseif METHOD == "ABC"  #ABCME
            println(fb, "Trial count limit: ", TC_LIMIT)
        end

        println(fb, "Map: ", MAP_METHOD)

        if MAP_METHOD == "grid"  # グリッドマップの場合
            println(fb, "Grid size: ", GRID_SIZE)
        elseif MAP_METHOD == "cvt"  # CVTマップの場合
            println(fb, "Voronoi point: ", k_max)
        end

        println(fb, "Noise: ", FIT_NOISE)
        println(fb, "Benchmark: ", OBJ_F)
        println(fb, "Dimension: ", D)
        println(fb, "Population size: ", N)
        println(fb, "===================================================================================")
    end
end

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
# Save result
function SaveResult(archive::Archive, iter_time::Float64, run_time::Float64)
    # Log file
    logger("INFO", "Time of iteration: $iter_time [sec]")
    logger("INFO", "Time: $run_time [sec]")

    # Open file
    if FIT_NOISE  # ノイズがある場合
        ffn = open("$(output)$METHOD/$OBJ_F/$F_FIT_N", "a")
        fr  = open("$(output)$METHOD/$OBJ_F/$F_RESULT", "a")
        ff  = open("$(output)$METHOD/$OBJ_F/$F_FITNESS", "a")
        fb  = open("$(output)$METHOD/$OBJ_F/$F_BEHAVIOR", "a")
    else  # ノイズがない場合
        fr = open("$(output)$METHOD/$OBJ_F/$F_RESULT", "a")
        ff = open("$(output)$METHOD/$OBJ_F/$F_FITNESS", "a")
        fb = open("$(output)$METHOD/$OBJ_F/$F_BEHAVIOR", "a")
    end

    # Write result
    if FIT_NOISE
        println(ffn, "===================================================================================")
        println(ff, "===================================================================================")
        println(fb, "===================================================================================")
    else
        println(ff, "===================================================================================")
        println(fb, "===================================================================================")
    end

    if MAP_METHOD == "grid"  # グリッドマップの場合
        for i in 1:GRID_SIZE
            for j in 1:GRID_SIZE
                if archive.grid[i, j] > 0  # グリッドに個体が存在する場合
                    if FIT_NOISE  # ノイズがある場合
                        println(ffn, archive.individuals[archive.grid[i, j]].benchmark[1])
                        println(ff, archive.individuals[archive.grid[i, j]].benchmark[2])
                        println(fb, archive.individuals[archive.grid[i, j]].behavior)
                        println(fr, archive.grid_update_counts[i, j])
                    else  # ノイズがない場合
                        println(ff, archive.individuals[archive.grid[i, j]].benchmark[2])
                        println(fb, archive.individuals[archive.grid[i, j]].behavior)
                        println(fr, archive.grid_update_counts[i, j])
                    end
                end
            end
        end
    elseif MAP_METHOD == "cvt"  # CVTマップの場合
        for (k, v) in archive.individuals
            if FIT_NOISE  # ノイズがある場合
                println(ffn, archive.individuals[k].benchmark[1])
                println(ff, archive.individuals[k].benchmark[2])
                println(fb, archive.individuals[k].behavior)
            else  # ノイズがない場合
                println(ff, archive.individuals[k].benchmark[2])
                println(fb, archive.individuals[k].behavior)
            end

            println(fr, archive.grid_update_counts[k])
        end
    else
        logger("ERROR", "Map method is invalid")  # マップメソッドが無効であることをエラーログに記録 -> 終了

        exit(1)
    end

    # Close file
    if FIT_NOISE  # ノイズがある場合
        close(ffn)
        close(fr)
        close(ff)
        close(fb)
    else
        close(fr)
        close(ff)
        close(fb)
    end
    
    logger("INFO", "End of Iteration")  # 反復終了のログを記録

    # Make result list
    arch_list = []
    
    if MAP_METHOD == "grid"  # グリッドマップの場合
        for i in 1:GRID_SIZE
            for j in 1:GRID_SIZE
                if archive.grid[i, j] > 0  # グリッドに個体が存在する場合
                    push!(arch_list, archive.individuals[archive.grid[i, j]])
                end
            end
        end
    elseif MAP_METHOD == "cvt"  # CVTマップの場合
        for k in keys(archive.individuals)
            if k > 0  # インデックスが0より大きい場合
                push!(arch_list, archive.individuals[k])
            end
        end
    else
        logger("ERROR", "Map method is invalid")  # マップメソッドが無効であることをエラーログに記録 -> 終了

        exit(1)
    end

    sort!(arch_list, by = x -> fitness(x.benchmark[fit_index]), rev = true)  # 適応度でソート

    open("$(output)$METHOD/$OBJ_F/$F_RESULT", "a") do fr  # 結果ファイルを開く
        println(fr, "===================================================================================")
        println(fr, "End of Iteration.\n")
        println(fr, "Time of iteration: ", iter_time, " [sec]")
        println(fr, "Time:              ", run_time, " [sec]")
        println(fr, "The number of solutions: ", length(arch_list))
        println(fr, "The number of regenerated CVT Map: ", cvt_vorn_data_update)
        println(fr, "===================================================================================")
        println(fr, "Top 10 suboptimal solutions:")

        for i in 1:10
            println(fr, "-----------------------------------------------------------------------------------")
            println(fr, "Rank ", i, ": ")
            println(fr, "├── Solution:      ", arch_list[i].genes)

            if FIT_NOISE  # ノイズがある場合
                println(fr, "├── Noisy Fitness: ", fitness(arch_list[i].benchmark[1]))
                println(fr, "├── True Fitness:  ", fitness(arch_list[i].benchmark[2]))
            else  # ノイズがない場合
                println(fr, "├── Fitness:       ", fitness(arch_list[i].benchmark[2]))
            end

            println(fr, "└── Behavior:      ", arch_list[i].behavior)
        end
    end

    println("===================================================================================")
    println("Best solution:      ", best_solution.genes)
    if FIT_NOISE  # ノイズがある場合
        println("Best noisy fitness: ", fitness(best_solution.benchmark[1]))
        println("Best true fitness:  ", fitness(best_solution.benchmark[2]))
    else  # ノイズがない場合
        println("Best fitness:       ", fitness(best_solution.benchmark[2]))
    end
    println("Best behavior:      ", best_solution.behavior)
    println("===================================================================================")
end

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
#                                                                                                    #
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#