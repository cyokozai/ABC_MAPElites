###################### BUILDER ######################
FROM julia:1.10.5

SHELL ["/bin/bash", "-c"]

ARG lang="C"
ARG dir="src"

ENV DEBIAN_FRONTEND noninter active
ENV TERM xterm
ENV DISPLAY host.docker.internal:0.0
ENV LANG ${lang}
ENV LANGUAGE ${lang}
ENV LC_ALL ${lang}
ENV TZ Asia/Tokyo
ENV JULIA_NUM_THREADS 4

WORKDIR /root
COPY pkginstall.jl /root/pkginstall.jl

RUN apt -y update && apt -y upgrade &&\
    julia pkginstall.jl run &&\
    rm -rf pkginstall.jl

WORKDIR /root/${dir}
COPY ./${dir}/*.jl /root/${dir}