#!/usr/bin/env bash

# Install some basic packages

apt-get install -y software-properties-common ripgrep git mosh tmux
apt-get update

# Setup iptables

iptables_rule="INPUT -p udp --dport 60000:61000 -j ACCEPT"
iptables -C $iptables_rule || sudo iptables -A $iptables_rule

iptables_config_dir="/etc/iptables"
mkdir -p $iptables_config_dir

iptables_config_path="$iptables_config_dir/rules.v4"
[ -f $iptables_config_path ] || iptables-save > $iptables_config_path

# Git setup

git config --global user.name "Gleb Glazov"
git config --global user.email "glazov.gleb@gmail.com"

