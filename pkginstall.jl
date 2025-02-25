using Pkg

Pkg.add("JLD2")
Pkg.add("FileIO")

Pkg.add("Distributions")
Pkg.add("StableRNGs")
Pkg.add("DelaunayTriangulation")
Pkg.add("LinearAlgebra")

if !isempty(ARGS) && ARGS[1] == "figure"
    Pkg.add("CairoMakie")
    Pkg.add("LaTeXStrings")
    Pkg.add("PyCall")
    Pkg.add("PyPlot")
    Pkg.add("UnicodePlots")
    Pkg.add("Plots")
    Pkg.add("StatsPlots")
    Pkg.add("ColorSchemes")
    Pkg.add("CSV")
    Pkg.add("DataFrames")
end

Pkg.precompile()