# ベースイメージ: CUDA 12.4 Development + Ubuntu 22.04
FROM nvidia/cuda:12.4.0-devel-ubuntu22.04

# 環境変数の設定
# CUDA_HOMEを最初に定義し、他の変数で安全に参照できるようにする
ENV CUDA_HOME=/usr/local/cuda
ENV DEBIAN_FRONTEND=noninteractive \
    TZ=Asia/Tokyo \
    LANG=C.UTF-8 \
    LC_ALL=C.UTF-8 \
    # PATHにCUDAバイナリディレクトリを追加
    PATH=${CUDA_HOME}/bin:${PATH} \
    # LD_LIBRARY_PATHにCUDAライブラリディレクトリとスタブディレクトリを追加
    LD_LIBRARY_PATH=${CUDA_HOME}/lib64:${CUDA_HOME}/lib64/stubs:${LD_LIBRARY_PATH} \
    # llama-cpp-python のビルド時に CUDA を使用するように設定
    CMAKE_ARGS="-DGGML_CUDA=ON -DLLAMA_CUDA_FORCE_MMQ=ON -DCMAKE_CUDA_ARCHITECTURES=75" \
    FORCE_CUDA=1 \
    # Python パッケージのキャッシュを無効化
    PIP_NO_CACHE_DIR=1 \
    # Python パッケージのインストール時の警告を抑制
    PIP_DISABLE_PIP_VERSION_CHECK=1

# 必要なシステムパッケージのインストール（Cコンパイラ等）
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        software-properties-common \
        wget \
        libsndfile1 \
        tzdata \
        build-essential \
        git \
        ca-certificates \
        cmake \
        ninja-build \
        pkg-config \
        python3-dev \
        python3-pip \
        python3-setuptools \
        python3-wheel \
        python3-venv && \
    # Python3.11のリポジトリを追加
    add-apt-repository ppa:deadsnakes/ppa -y && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
        python3.11 \
        python3.11-distutils \
        python3.11-dev && \
    # タイムゾーンの設定
    ln -fs /usr/share/zoneinfo/Asia/Tokyo /etc/localtime && \
    dpkg-reconfigure -f noninteractive tzdata && \
    # Python3.11をデフォルトに設定
    update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.11 1 && \
    update-alternatives --set python3 /usr/bin/python3.11 && \
    ln -sf /usr/bin/python3.11 /usr/bin/python && \
    # pipのインストールとアップグレード
    wget -qO /tmp/get-pip.py https://bootstrap.pypa.io/get-pip.py && \
    python3.11 /tmp/get-pip.py && \
    rm /tmp/get-pip.py && \
    pip install --no-cache-dir --upgrade pip setuptools wheel && \
    # クリーンアップ
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# CUDAスタブライブラリへのシンボリックリンクを作成 (libcuda.so.1 が見つからない問題への対処)
RUN if [ -f "${CUDA_HOME}/lib64/stubs/libcuda.so" ] && [ ! -f "${CUDA_HOME}/lib64/stubs/libcuda.so.1" ]; then \
        ln -s ${CUDA_HOME}/lib64/stubs/libcuda.so ${CUDA_HOME}/lib64/stubs/libcuda.so.1; \
    fi

# 作業ディレクトリの設定
WORKDIR /app

# 依存関係ファイルを先にコピー（レイヤーキャッシュの最適化）
COPY requirements.txt /app/

# PyTorch および関連ライブラリを CUDA 12.1+ 互換でインストール
RUN pip install --no-cache-dir torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu121

# Pythonパッケージのインストール
# requirements.txt に llama-cpp-python が含まれていないことを確認してください
RUN pip install --no-cache-dir -v -r requirements.txt && \
    # llama-cpp-python を個別にインストール（CUDAサポート付き）
    echo "Attempting to install llama-cpp-python==0.3.9 with CUDA support..." && \
    pip install --no-cache-dir -v llama-cpp-python==0.3.9

# ソースコードを全てコピー
COPY . /app/

# ビルド後にキャッシュをクリーンアップしてイメージサイズを削減
RUN rm -rf /root/.cache/pip /root/.cache/pytest /root/.cache/mypy

