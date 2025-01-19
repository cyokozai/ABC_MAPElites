#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
#       Import library                                                                               #
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#

using Printf

using Dates

#----------------------------------------------------------------------------------------------------#

include("config.jl")

include("savedata.jl")

include("me.jl")

include("logger.jl")

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
#       Main                                                                                         #
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
# Main
function main()
    # Make result directory and log file
    MakeFiles()
    
    # Check dimension
    if D == 2
        logger("WARN", "Dimension is default value \"2\"")
    elseif D <= 0
        logger("ERROR", "Dimension is invalid")
        
        exit(1)
    else
        logger("INFO", "Dimension is $D")
    end
    
    # Convergence mode check
    if CONV_FLAG
        logger("INFO", "Convergence flag is true")
    else
        logger("INFO", "Convergence flag is false")
    end
    
    # Check method
    println("Method   : ", METHOD)
    if METHOD == "de"
        println("F : ", F)
        println("CR: ", CR)
    elseif METHOD == "abc"
        println("Trial count limit: ", TC_LIMIT)
    end
    println("Map      : ", MAP_METHOD)
    if MAP_METHOD == "grid"
        println("Grid size    : ", GRID_SIZE)
    elseif MAP_METHOD == "cvt"
        println("Voronoi point: ", k_max)
    end
    
    # Print parameters
    println("Benchmark: ", OBJ_F)
    println("Dimension: ", D)
    println("Population size: ", N)
    println("===================================================================================")

    #------ MAP ELITES ALGORITHM ------------------------------#

    begin_time = time()

    popn, arch, iter_time = map_elites()
    
    finish_time = time()

    #------ MAP ELITES ALGORITHM ------------------------------#

    elapsed_time = finish_time - begin_time
    
    println("===================================================================================")
    println("End of Iteration.\n")
    println("Time of iteration: ", iter_time, " [sec]")
    println("Time:              ", elapsed_time, " [sec]")
    println("===================================================================================")

    # Save result
    SaveResult(arch, iter_time, elapsed_time)
end

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
#       Run                                                                                          #
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#

try
    global exit_code = 0

    logger("INFO", "Start")
    println("Start")
    
    main()

    logger("INFO", "Success! :)")
    println("Success! :)")
catch e
    global exit_code = 1

    logger("ERROR", "An error occurred! :(\n$e")
    println("An error occurred! :(\n$e")
finally
    logger("INFO", "Finish")
    println("Finish")

    exit(exit_code)
end

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
#                                                                                                    #
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#