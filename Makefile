.PHONY: all install-docker install-julia install-python install-jinja2
all: install-docker install-julia install-python install-jinja2
container: install-docker install-python install-jinja2
local-run: install-julia
install-docker:
    sudo apt-get update
    sudo apt-get install -y \
        apt-transport-https \
        ca-certificates \
        curl \
        software-properties-common
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
    sudo add-apt-repository \
    "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
        $(lsb_release -cs) \
        stable"
    sudo apt-get update
    sudo apt-get install -y docker-ce
    sudo gpasswd -a $USER docker
    newgrp docker
install-julia:
    curl -fsSL https://install.julialang.org | sh
    . ~/.bashrc
    julia pkginstall.jl
install-python:
    sudo apt -y install python3-pip
install-jinja2:
    pip install jinja2