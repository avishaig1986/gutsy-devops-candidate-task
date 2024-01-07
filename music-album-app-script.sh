#!/bin/bash
set -x

echo "Checking if docker is installed"
if [[ $(which docker) && $(docker --version) ]]; then
    echo "docker already installed"
  else
    echo "docker not installed, installing docker"
    # taken from public github repo https://github.com/docker/docker-install
    curl -sfJSL https://get.docker.com > get-docker.sh
    chmod +x get-docker.sh
    sh get-docker.sh

    if [[ $(getent group docker) ]]; then
        echo "docker group exists."
    else
        echo "docker group does not exist"
        sudo groupadd docker
        sudo usermod -aG docker $USER
    fi

    rm get-docker.sh
fi

echo "Checking if minikube is installed"
if [[ $(which minikube) && $(minikube version) ]]; then
    echo "minikube already installed"
  else
    echo "minikube not installed, installing minikube"
    curl -sLO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
    sudo install minikube-linux-amd64 /usr/local/bin/minikube
    rm minikube-linux-amd64
fi

echo "Checking if helm is installed"
if [[ $(which helm) && $(helm version) ]]; then
    echo "helm already installed"
  else
    echo "helm not installed, installing helm"
    curl -sLO https://get.helm.sh/helm-v3.13.3-linux-amd64.tar.gz
    tar -zxvf helm-v3.13.3-linux-amd64.tar.gz
    sudo mv linux-amd64/helm /usr/local/bin/helm
    rm helm-v3.13.3-linux-amd64.tar.gz
    rm -Rf linux-amd64

fi

echo "Checking if kubectl is installed"
if [[ $(which kubectl) && $(kubectl version --client) ]]; then
    echo "kubectl already installed"
  else
    echo "kubectl not installed, installing kubectl"
    curl -sLO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
    chmod +x kubectl
    mkdir -p ~/.local/bin
    mv kubectl ~/.local/bin/kubectl
fi

minikube start
minikube addons enable ingress
minikube addons enable storage-provisioner-rancher
docker build ./redis --tag redis-db:1.0.0
docker build ./server --tag go-server:1.0.0
minikube image load redis-db:1.0.0
minikube image load go-server:1.0.0
kubectl apply -k k8s-fluent-bit
helm repo add fluent https://fluent.github.io/helm-charts
helm upgrade --install --wait --namespace logging --values k8s-fluent-bit/values.yml fluent-bit fluent/fluent-bit
kubectl apply -k k8s-music-albums-app
sleep 30
curl --insecure https://$(minikube ip):443/api/v1/music-albums?key=101 -H 'Content-Type: application/json'