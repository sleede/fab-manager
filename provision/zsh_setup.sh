#!/usr/bin/env bash

###
# Update system packages
update_system() {
  echo 'Updating system'
  sudo apt-get update && sudo apt-get upgrade -y
  sudo apt-get install -y git curl
}

###
# Install ZSH shell
install_zsh() {
  echo 'Installing ZSH'
  # Install and set zsh as shell
  sudo apt-get install -y zsh

  # Change shell to Zsh for the vagrant user
  sudo chsh -s /bin/zsh vagrant
}

###
# Install Oh My ZSH! plugin framework
install_ohmyzsh() {
  echo "Installing Oh-My-ZSH!"
  git clone git://github.com/robbyrussell/oh-my-zsh.git ~/.oh-my-zsh
  cp ~/.oh-my-zsh/templates/zshrc.zsh-template ~/.zshrc

  # Change the Oh-My-Zsh! default configuration.
  sed -i 's@ZSH_THEME="robbyrussell"@ZSH_THEME="blinks"@g' ~/.zshrc
  sed -i 's@# CASE_SENSITIVE="true"@CASE_SENSITIVE="true"@g' ~/.zshrc
  sed -i 's@# COMPLETION_WAITING_DOTS="true"@COMPLETION_WAITING_DOTS="true"@g' ~/.zshrc
  sed -i 's@# DISABLE_UNTRACKED_FILES_DIRTY="true"@DISABLE_UNTRACKED_FILES_DIRTY="true"@g' ~/.zshrc
  sed -i 's@# HIST_STAMPS="mm/dd/yyyy"@HIST_STAMPS="yyyy-mm-dd"@g' ~/.zshrc
  sed -i 's@plugins=(git)@plugins=(git dirhistory common-aliases command-not-found ruby)@g' ~/.zshrc

  # Include .profile settings
  echo -e "\n# Include .profile settings"  >> ~/.zshrc
  echo -e "source ~/.profile\n"  >> ~/.zshrc
}

setup() {
  update_system
  install_zsh
  install_ohmyzsh
}

setup "$@"
