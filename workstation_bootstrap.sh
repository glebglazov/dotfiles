#!/usr/bin/env bash

# Install some basic packages
apt-get install -y software-properties-common ripgrep git mosh tmux docker
apt-get update

# Install tmux
apt-get install tmux

# Configure bash a bit
source_dot_my_profile_text=". $HOME/.my-profile"
(cat $HOME/.bashrc | grep "$source_dot_my_profile_text") || echo "$source_dot_my_profile_text" >> $HOME/.bashrc
cp .my-profile $HOME/.my-profile
. $HOME/.bashrc

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
