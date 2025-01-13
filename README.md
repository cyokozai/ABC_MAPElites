# ABC MAP-Elites

## How to use this program

### Install

- Docker

    ```shell
    make container
    ```

- Local

    ```shell
    make local-run
    ```

- All

    ```shell
    make all
    ```

- Confirm apps

    ```shell
    $ docker -v
    Docker version 27.3.1, build ce12230
    $ julia -v
    julia version 1.10.5
    $ python3 -V
    Python 3.10.12
    $ pip -V
    pip 22.0.2 from /usr/lib/python3/dist-packages/pip (python 3.10)
    ```

### Deploy the programs on Docker

- Set the source code into `./src`
- Test `./docker-runner.py`

    ```shell
    python3 docker-runner.py test
    ```

- Run `./docker-runner.py`

    ```shell
    python3 docker-runner.py
    ```

### 

### MAP-elites Configuration

- Open `./src/config.jl`

以下は提供されたコードに基づいてMarkdown形式で作成したパラメータの表です。

---

### General Parameters

| パラメータ      | 説明                                                                                 | デフォルト値                         |
|----------------|------------------------------------------------------------------------------------|-----------------------------------|
| `SEED`        | ランダムシード。現在日時に基づいて初期化される。                                              | `Int(Dates.now().instant.periods.value)` |
| `RNG`         | ランダム数ジェネレーター。`SEED`を使用して初期化される。                                        | `StableRNG(SEED)`               |
| `D`           | 次元数。テスト時は`2`、それ以外は引数で指定する。                                               | `2` または `parse(Int64, ARGS[1])` |
| `N`           | 個体群のサイズ。                                                                          | `64`                              |
| `BD`          | 行動次元数。変更不可。                                                                     | `2`                               |
| `MAXTIME`     | 最大時間。テスト時は`100`、それ以外は引数で指定する。                                            | `100` または `100000`            |
| `MUTANT_R`    | 突然変異率。                                                                             | `0.10`                            |
| `CONV_FLAG`   | 収束フラグ。収束を確認したい場合は`true`に設定する。                                             | `true`                            |
| `FIT_NOISE`   | フィットネスノイズフラグ。ノイズを追加したい場合は`true`に設定する。                                   | `true`                            |
| `NOIZE_R`     | ノイズ率。`0.0 < NOIZE_R < 1.0`。デフォルト値は`0.10`。                                         | `0.10`                            |

---

### MAP Parameters

| パラメータ          | 説明                                                             | デフォルト値 |
|--------------------|----------------------------------------------------------------|---------|
| `GRID_SIZE`       | グリッドマップのサイズ。`MAP_METHOD == grid`の場合に使用される。            | `158`   |
| `k_max`           | 最大クラスタ数。`MAP_METHOD == cvt`の場合に使用される。                     | `25000` |

---

### Voronoi Parameters

| パラメータ                      | 説明                                              | デフォルト値 |
|--------------------------------|-------------------------------------------------|---------|
| `cvt_vorn_data_update_limit`  | Voronoiデータ更新の制限回数。                             | `3`     |

---

### DE Parameters

| パラメータ       | 説明                                                              | デフォルト値 |
|-----------------|-----------------------------------------------------------------|---------|
| `CR`           | 交叉確率。目的関数によって値が変化する。                                   | `目的関数による` |
| `F`            | 差分（突然変異）スケーリング係数。目的関数によって値が変化する。                      | `目的関数による` |

#### 目的関数ごとの`CR`と`F`

| 目的関数           | `CR`   | `F`   |
|--------------------|--------|-------|
| `sphere`          | `0.10` | `0.30` |
| `rosenbrock`      | `0.75` | `0.70` |
| `rastrigin`       | `0.01` | `0.50` |
| `griewank`        | `0.20` | `0.50` |
| `ackley`          | `0.20` | `0.50` |
| `schwefel`        | `0.20` | `0.50` |
| `michalewicz`     | `0.20` | `0.50` |
| その他             | `0.8`  | `0.9`  |

---

### ABC Parameters

| パラメータ      | 説明                                                          | デフォルト値                  |
|----------------|-------------------------------------------------------------|--------------------------|
| `TC_LIMIT`    | ScoutBeeがより良い解を見つけられなかった際の試行回数の制限。`floor(Int, k_max / N)`で計算される。 | `floor(Int, k_max / N)` | 

## Graphs and plots

### Make the convergence graphs and vorn plot in PDF

- Check the file name of the result data in `./src/result`
- Compose up `./docker-compose.yaml`

    ```shell
    docker compose  -f "docker-compose.yaml" up -d --build julia-figure
    ```

- ~~Run `./make=plot.py` & `./make-vorn.py`~~
  - Unavailable

    ```shell
    julia make-plot.jl <Dimention> <Method> <Grid or CVT> <Objective function> <Fitness or CVT>
    ```

### Plots Configuration

- Open `./src/make-plot.jl`


### Sample graphs

- `fitness-testdata.pdf`

![sample-fitness](./result/testdata/fitness-testdata.pdf)

- `behavior-testdata.pdf`

![sample-behavior](./result/testdata/behavior-testdata.pdf)
