FROM nvidia/cuda:11.8.0-devel-ubuntu22.04

##############################################################################################################
# Global
##############################################################################################################

ENV LANG=C.UTF-8 LC_ALL=C.UTF-8
ARG DEBIAN_FRONTEND=noninteractive
ENV TZ=Asia/Tokyo

##############################################################################################################
# Global Path Setting
##############################################################################################################

ENV CUDA_HOME /usr/local/cuda
ENV LD_LIBRARY_PATH ${LD_LIBRARY_PATH}:${CUDA_HOME}/lib64
ENV LD_LIBRARY_PATH ${LD_LIBRARY_PATH}:/usr/local/lib

ENV OPENCL_LIBRARIES /usr/local/cuda/lib64
ENV OPENCL_INCLUDE_DIR /usr/local/cuda/include

##############################################################################################################
# SYSTEM
##############################################################################################################

RUN apt update && apt upgrade -y
RUN apt-get update && \
  apt-get install -y --no-install-recommends \
    software-properties-common \
    tzdata \
    build-essential \
    curl \
    bzip2 \
    ca-certificates \
    libglib2.0-0 \
    libxext6 \
    libsm6 \
    libxrender1 \
    git \
    vim \
    mercurial \
    subversion \
    cmake \
    libboost-dev \
    libboost-system-dev \
    libboost-filesystem-dev \
    gcc \
    g++ \
    graphviz \
    ffmpeg \
    libopencv-dev \
    tmux \
    zip \
    wget \
    tree \
    libopenblas-dev \
    npm \
    less \
    ssh \
    curl

##############################################################################################################
# python 3.10
##############################################################################################################

RUN add-apt-repository -y ppa:deadsnakes/ppa
RUN apt install -y python3.10-dev python3.10-venv
RUN update-alternatives --install /usr/bin/python python /usr/bin/python3.10 3
RUN apt install -y python3-pip
RUN python -m pip install -U pip

##############################################################################################################
# Miniconda
##############################################################################################################

ENV PATH="/root/miniconda3/bin:${PATH}"
ARG PATH="/root/miniconda3/bin:${PATH}"
RUN apt-get update

RUN apt-get install -y wget && rm -rf /var/lib/apt/lists/*

RUN wget \
    https://repo.anaconda.com/miniconda/Miniconda3-py310_23.5.2-0-Linux-x86_64.sh \
    && mkdir /root/.conda \
    && bash Miniconda3-py310_23.5.2-0-Linux-x86_64.sh -b \
    && rm -f Miniconda3-py310_23.5.2-0-Linux-x86_64.sh
RUN conda --version

# quick fix for `libstdc++.so.6: version `GLIBCXX_3.4.30' not found` error
RUN ln -sf /usr/lib/x86_64-linux-gnu/libstdc++.so.6 /root/miniconda3/lib/libstdc++.so.6


##############################################################################################################
# Requirements
##############################################################################################################
RUN conda install -y \
  cmake \
  ninja \
  mkl \
  mkl-include \
  matplotlib

##############################################################################################################
# yarn
##############################################################################################################
RUN curl -sL https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - && \
  echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list && \
  apt update && \
  apt install -y --no-install-recommends yarn


##############################################################################################################
# diff-so-fancy
##############################################################################################################
RUN npm install -g diff-so-fancy

##############################################################################################################
# clean caches
##############################################################################################################

RUN apt-get clean && \
  rm -rf /tmp/* /var/tmp/* /var/lib/apt/lists/* && \
  apt-get -y autoremove

##############################################################################################################
# python dependencies
##############################################################################################################

WORKDIR /pytorch-devenv/working
COPY ./artifact/requirements.txt .
RUN --mount=type=cache,target=/root/.cache/pip python -m pip install -r requirements.txt
RUN python -m pip freeze >| requirements.lock

##############################################################################################################
# Jupyter lab config
##############################################################################################################

COPY ./artifact/jupyter_lab_config.py .
RUN mkdir -p /usr/local/share/jupyter/lab/settings
