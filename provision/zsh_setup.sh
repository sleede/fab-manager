#!/usr/bin/env bash

echo "***************************************************"
echo 'Updating system packages... '
echo "***************************************************"
sudo apt update && sudo apt upgrade -y


echo "***************************************************"
echo 'Checking Zsh installation... '
echo "***************************************************"
if ! dpkg -s zsh; then
  # Install and set Zsh as shell
  sudo apt install -y zsh

  # Install Oh-My-Zsh!
  git clone git://github.com/robbyrussell/oh-my-zsh.git ~/.oh-my-zsh
  cp ~/.oh-my-zsh/templates/zshrc.zsh-template ~/.zshrc

  # Change the Oh-My-Zsh! default configuration.
  sed -i 's/ZSH_THEME="robbyrussell"/ZSH_THEME="blinks"/g' ~/.zshrc
  sed -i 's/# CASE_SENSITIVE="true"/CASE_SENSITIVE="true"/g' ~/.zshrc
  sed -i 's/# COMPLETION_WAITING_DOTS="true"/COMPLETION_WAITING_DOTS="true"/g' ~/.zshrc
  sed -i 's/# DISABLE_UNTRACKED_FILES_DIRTY="true"/DISABLE_UNTRACKED_FILES_DIRTY="true"/g' ~/.zshrc
  sed -i 's/# HIST_STAMPS="mm/dd/yyyy"/HIST_STAMPS="yyyy-mm-dd"/g' ~/.zshrc
  sed -i 's/plugins=(git)/plugins=(git dirhistory common-aliases command-not-found ruby)/g' ~/.zshrc

  # Include .profile settings
  echo ' '  >> ~/.zshrc
  echo '# Include .profile settings'  >> ~/.zshrc
  echo 'source ~/.profile'  >> ~/.zshrc
  echo ' '  >> ~/.zshrc

  # Change shell to Zsh for the vagrant user
  sudo chsh -s /bin/zsh vagrant
fi
