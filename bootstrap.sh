#!/usr/bin/env bash

append_text_to_file_if_not_exists() {
  file_path=$1
  text=$2
  
  (cat $file_path | grep "$text") || echo "$text" >> $file_path
}

# Install ohmybash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/ohmybash/oh-my-bash/master/tools/install.sh)"

# Install some basic packages
apt-get install -y software-properties-common ripgrep git mosh tmux docker.io
apt-get update

# Install tmux
apt-get install tmux

# Configure bash a bit
source_dot_my_profile_text=". $HOME/.my-profile"
cp .my-profile $HOME/.my-profile
append_text_to_file_if_not_exists $HOME/.bashrc $source_dot_my_profile_text
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

# Installing ruby-install, chruby, Ruby...
wget -O ruby-install-0.8.3.tar.gz https://github.com/postmodern/ruby-install/archive/v0.8.3.tar.gz
tar -xzvf ruby-install-0.8.3.tar.gz
cd ruby-install-0.8.3
make install
cd ..
rm -rf ruby-install-0.8.3 ruby-install-0.8.3.tar.gz

wget -O chruby-0.3.9.tar.gz https://github.com/postmodern/chruby/archive/v0.3.9.tar.gz
tar -xzvf chruby-0.3.9.tar.gz
cd chruby-0.3.9
make install
cd ..
rm -rf chruby-0.3.9 chruby-0.3.9.tar.gz

append_text_to_file_if_not_exists $HOME/.my-profile "source /usr/local/share/chruby/chruby.sh"
append_text_to_file_if_not_exists $HOME/.my-profile "source /usr/local/share/chruby/auto.sh"
. $HOME/.my-profile
