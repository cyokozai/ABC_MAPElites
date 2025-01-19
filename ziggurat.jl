using Random

# 定数の定義
const R = 3.442619855899  # Zigguratテーブルの範囲定数
const ZIGGURAT_TABLE_SIZE = 256

# Zigguratテーブルを準備
const zig_x = Vector{Float64}(undef, ZIGGURAT_TABLE_SIZE + 1)
const zig_y = Vector{Float64}(undef, ZIGGURAT_TABLE_SIZE)

function initialize_ziggurat_table()
    # 初期化
    f = x -> exp(-0.5 * x * x)
    zig_x[ZIGGURAT_TABLE_SIZE + 1] = R
    zig_y[ZIGGURAT_TABLE_SIZE] = f(R)

    for i in ZIGGURAT_TABLE_SIZE:-1:2
        zig_x[i] = sqrt(-2 * log(f(zig_x[i + 1])))
        zig_y[i - 1] = f(zig_x[i])
    end
    zig_x[1] = 0.0
end

initialize_ziggurat_table()

# N_noise関数
function N_noise(mu, sigma2)
    σ = sqrt(sigma2)
    while true
        # 一様乱数生成
        u = rand(UInt32) % UInt32(ZIGGURAT_TABLE_SIZE) + 1
        x = rand() * (zig_x[u + 1] - zig_x[u]) + zig_x[u]

        if rand() * zig_y[u] <= exp(-0.5 * x^2)
            return mu + σ * x * (rand(Bool) ? 1 : -1)  # 符号付け
        end
    end
end

# 動作確認
mu = 0.0
sigma2 = 1.0
println("Generated random number: ", rand(N_noise(mu, sigma2)))
