#!/usr/bin/env bash

sudo apt-get install -y software-properties-common ripgrep git
sudo apt-add-repository ppa:ansible/ansible
sudo apt-get update
sudo apt-get install -y ansible

git config --global user.name "Gleb Glazov"
git config --global user.email "glazov.gleb@gmail.com"
