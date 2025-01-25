#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
#       Import library                                                                               #
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#

using Printf  # フォーマット付き文字列を出力

using Dates   # 日付と時間

#----------------------------------------------------------------------------------------------------#

include("config.jl")    # 設定ファイル

include("savedata.jl")  # データ保存用のファイル

include("me.jl")        # MAP-Elitesアルゴリズムの実装ファイル

include("logger.jl")    # ログ出力用のファイル

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
#       Main                                                                                         #
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
# Main
function main()
    # Make result directory and log file
    MakeFiles()
    
    # Check dimension
    if D == 2
        logger("WARN", "Dimension is default value \"2\"")  # 次元がデフォルト値「2」であることを警告
    elseif D <= 0
        logger("ERROR", "Dimension is invalid")             # 次元が無効であることをエラーログに記録 -> 終了

        exit(1)
    else
        logger("INFO", "Dimension is $D")                   # 次元を情報ログに記録
    end
    
    # Convergence mode check
    if CONV_FLAG
        logger("INFO", "Convergence flag is true")   # 収束フラグが真であることを情報ログに記録
    else
        logger("INFO", "Convergence flag is false")  # 収束フラグが偽であることを情報ログに記録
    end
    
    # Check method
    println("Method   : ", METHOD)  # 使用するメソッドを出力

    if METHOD == "de"
        println("       F : ", F)   # 差分進化のF値を出力
        println("       CR: ", CR)  # 差分進化の交叉率を出力
    elseif METHOD == "abc"
        println("Trial count limit: ", TC_LIMIT)  # ABCアルゴリズムの試行回数制限を出力
    end

    println("Map      : ", MAP_METHOD)  # マップメソッドを出力

    if MAP_METHOD == "grid"
        println("Grid size    : ", GRID_SIZE)  # グリッドサイズを出力
    elseif MAP_METHOD == "cvt"
        println("Voronoi point: ", k_max)      # ボロノイ点の数を出力
    end
    
    # Print parameters
    println("Benchmark: ", OBJ_F)    # ベンチマーク関数を出力
    println("Dimension: ", D)        # 次元を出力
    println("Population size: ", N)  # 集団サイズを出力
    println("===================================================================================")

    #------ MAP ELITES ALGORITHM ------------------------------#

    begin_time = time()                   # 開始時間を記録

    popn, arch, iter_time = map_elites()  # MAP-Elitesアルゴリズムを実行
    
    finish_time = time()                  # 終了時間を記録

    #------ MAP ELITES ALGORITHM ------------------------------#

    elapsed_time = finish_time - begin_time  # 経過時間を計算
    
    println("===================================================================================")
    println("End of Iteration.\n")
    println("Time of iteration: ", iter_time, " [sec]")     # 反復の時間を出力
    println("Time:              ", elapsed_time, " [sec]")  # 総経過時間を出力
    println("===================================================================================")

    # Save result
    SaveResult(arch, iter_time, elapsed_time)
end

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
#       Run                                                                                          #
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#

try
    global exit_code = 0

    logger("INFO", "Start")  # 開始ログを記録
    println("Start")         # 開始メッセージを出力
    
    main()  # メイン関数を実行

    logger("INFO", "Success! :)")  # 成功ログを記録
    println("Success! :)")         # 成功メッセージを出力
catch e
    global exit_code = 1  # エラー発生時にexit_codeを1に設定

    logger("ERROR", "An error occurred! :(\n$e")  # エラーログを記録
    println("An error occurred! :(\n$e")          # エラーメッセージを出力
finally
    logger("INFO", "Finish")  # 終了ログを記録
    println("Finish")         # 終了メッセージを出力

    exit(exit_code)  # プログラムを終了
end

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
#                                                                                                    #
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#