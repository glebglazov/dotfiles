#!/usr/bin/env bash

append_text_to_file_if_not_exists() {
  file_path="$1"
  text="$2"

  grep -q "$text" $file_path || echo "$text" >> $file_path
}

idempotent_iptables_prepend() {
  iptables -D INPUT $1
  iptables -I INPUT 1 $1

  iptables -D DOCKER-USER $1
  iptables -I DOCKER-USER 1 $1
}

only_localhost_iptables_prepend() {
  idempotent_iptables_prepend "-p tcp --dport $1 -j DROP"
  idempotent_iptables_prepend "-p tcp -s localhost --dport $1 -j ACCEPT"
}

# Add NodeJS PPA
curl -sL https://deb.nodesource.com/setup_16.x | bash - && \
	curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - && \
	echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list

# Install some basic packages
apt-get update
apt-get install -y \
  software-properties-common \
  fzf \
  ripgrep \
  git \
  tig \
  mosh \
  tmux \
  docker.io \
  docker-compose \
  make \
  wget \
  curl \
  libmysqlclient-dev \
  mysql-client \
  pkg-config \
  nodejs \
  yarn \
  xsel
apt-get update

# Install ohmybash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/ohmybash/oh-my-bash/master/tools/install.sh)"

# Install NeoVim
nvim_binary_path=/usr/bin/nvim
curl https://github.com/neovim/neovim/releases/download/v0.5.1/nvim.appimage -L -o $nvim_binary_path
chmod a+x $nvim_binary_path
sh -c 'curl -fLo "${XDG_DATA_HOME:-$HOME/.local/share}"/nvim/site/autoload/plug.vim --create-dirs \
       https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'
nvim_config_dir=~/.config/nvim
mkdir -p $nvim_config_dir
ln -sf $(pwd)/init.vim $nvim_config_dir/init.vim

# Configure tmux
cd
git clone https://github.com/gpakosz/.tmux.git
ln -sf .tmux/.tmux.conf

# Configure bash a bit
source_dot_my_profile_text=". ~/.my-profile"
append_text_to_file_if_not_exists ~/.bashrc "$source_dot_my_profile_text"
. ~/.bashrc

# Setup iptables
iptables_rule="INPUT -p udp --dport 60000:61000 -j ACCEPT"
iptables -C $iptables_rule || sudo iptables -A $iptables_rule

only_localhost_iptables_prepend 3306
only_localhost_iptables_prepend 6379
only_localhost_iptables_prepend 11211

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

