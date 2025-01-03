###################### BUILDER ######################
FROM ubuntu:latest AS builder

SHELL ["/bin/bash", "-c"]

ARG lang="C"
ARG version="1.10"
ARG patch="5"

ENV DEBIAN_FRONTEND = noninter active
ENV TERM xterm
ENV DISPLAY host.docker.internal:0.0
ENV LANG ${lang}
ENV LANGUAGE ${lang}
ENV LC_ALL ${lang}
ENV TZ Asia/Tokyo
ENV JULIA_NUM_THREADS 4

WORKDIR /root
COPY pkginstall.jl /root/

#~~~~~~~~~~~~~~~~~~~~~~ EDIT ~~~~~~~~~~~~~~~~~~~~~~~#

RUN apt -y update && apt -y upgrade &&\
    apt -y install tzdata \
    locales \
    curl \
    wget \
    tar \
    language-pack-ja-base language-pack-ja locales &&\
    wget https://julialang-s3.julialang.org/bin/linux/x64/${version}/julia-${version}.${patch}-linux-x86_64.tar.gz &&\
    tar zxvf julia-${version}.${patch}-linux-x86_64.tar.gz -C /usr --strip-components 1 &&\
    rm julia-${version}.${patch}-linux-x86_64.tar.gz &&\
    echo "alias newalias='julia'" >> ~/.bashrc &&\
    source ~/.bashrc &&\
    julia pkginstall.jl figure &&\
    rm -rf pkginstall.jl

#~~~~~~~~~~~~~~~~~~~~~~ EDIT ~~~~~~~~~~~~~~~~~~~~~~~#

WORKDIR /root/
COPY make-*.jl cvt-test.jl src/*.jl /root/