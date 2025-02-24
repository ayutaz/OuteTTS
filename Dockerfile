# ベースイメージ: CUDA 12.4 Runtime + Ubuntu 22.04
FROM nvidia/cuda:12.4.0-runtime-ubuntu22.04

# 環境変数の設定
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Asia/Tokyo

# 必要なシステムパッケージのインストール（Cコンパイラ等）
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        software-properties-common \
        wget \
        libsndfile1 \
        tzdata \
        build-essential && \
    ln -fs /usr/share/zoneinfo/Asia/Tokyo /etc/localtime && \
    dpkg-reconfigure -f noninteractive tzdata && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Python3.11、pip、およびPython開発パッケージのインストール
RUN add-apt-repository ppa:deadsnakes/ppa -y && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
        python3.11 \
        python3.11-distutils \
        python3.11-dev && \
    wget -qO /tmp/get-pip.py https://bootstrap.pypa.io/get-pip.py && \
    python3.11 /tmp/get-pip.py && \
    rm /tmp/get-pip.py

# python3 コマンドを Python3.11 にリンク
RUN update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.11 1

# python コマンドも Python3.11 を指すようにシンボリックリンクを作成
RUN ln -sf /usr/bin/python3.11 /usr/bin/python

# 作業ディレクトリの設定
WORKDIR /app

# ローカルのrequirements.txtをコンテナにコピー
COPY requirements.txt /app/

# Pythonパッケージのインストール
RUN pip install --no-cache-dir -r requirements.txt

# ソースコードを全てコピー
COPY . /app/
