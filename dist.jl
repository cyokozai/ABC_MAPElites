using Random
using Distributions
using CairoMakie


D = 1000
gene = ones(Float64, 1:D)
Data = zeros(Int64, 1, 1)

const r_noise = 0.01
const σ = r_noise / 9.0
const N_noise = Normal(0.0, σ^(2.0))

indList = [x_d + rand(N_noise) for x_d in gene]
Data = [count(x -> x < i && x > i-0.01, indList) for i in 0.9:0.001:1.1]


fig = CairoMakie.Figure(size = (800, 600), fontsize=24, px_per_unit=2)
ax = fig[1, 1] = Axis(fig, title = "Gene Distribution", xlabel = "Value", ylabel = "Frequency", xticks = 0.9:0.01:1.1, yticks = 0:100:D)
limits!(ax, 0.9, 1.1, 0, maximum(Data) + 10)
hist!(ax, indList, bins = 50, color = :green, label = "Noisy Gene")
barplot!(ax, 0.9:0.001:1.1, Data, color = :red, strokecolor = :black, strokewidth = 0.001)

save("src/result/testdata/pdf/geneDist.pdf", fig)