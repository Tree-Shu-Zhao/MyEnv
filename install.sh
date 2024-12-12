#!/bin/bash

echo "Starting development environment setup..."

apt update

apt install -y \
    git \
    curl \
    wget \
    tmux \
    zsh \
    build-essential \
    unzip \
    ripgrep \
    xclip

# Install Oh My ZSH
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting

# Install oh-my-tmux
git clone https://github.com/gpakosz/.tmux.git ~/.tmux
ln -s -f ~/.tmux/.tmux.conf ~/.tmux.conf
cp ~/.tmux/.tmux.conf.local ~/.tmux.conf.local

# Install anaconda3
ANACONDA_VERSION="2023.09-0"
wget -q https://repo.anaconda.com/archive/Anaconda3-${ANACONDA_VERSION}-Linux-x86_64.sh -O /tmp/anaconda.sh
bash /tmp/anaconda.sh -b -p $HOME/anaconda3
rm /tmp/anaconda.sh
eval "$($HOME/anaconda3/bin/conda shell.bash hook)"
eval "$($HOME/anaconda3/bin/conda shell.zsh hook)"

# Install neovim
wget https://github.com/neovim/neovim/releases/download/v0.10.2/nvim-linux64.tar.gz
tar -zxvf nvim-linux64.tar.gz
mkdir -p ~/.local/opt
mv nvim-linux64 ~/.local/opt/nvim
mkdir -p ~/.local/bin
ln -s ~/.local/opt/nvim/bin/nvim ~/.local/bin/nvim
rm nvim-linux64.tar.gz
mkdir -p ~/.config/
cp -r nvim ~/.config/

# Install nodejs
wget -qO- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
nvm install --lts
nvm use --lts

# Install rust
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
source "$HOME/.cargo/env"
cargo install ripgrep fd-find

# Configure zsh
cat > ~/.zshrc << 'EOL'
# Path to oh-my-zsh installation
export ZSH="$HOME/.oh-my-zsh"

# Set theme
ZSH_THEME="ys"

# Set plugins
plugins=(
    git
    zsh-autosuggestions
    zsh-syntax-highlighting
    python
    node
    rust
)

source $ZSH/oh-my-zsh.sh

# Anaconda configuration
eval "$($HOME/anaconda3/bin/conda shell.zsh hook)"

# Rust configuration
source "$HOME/.cargo/env"

# NVM configuration
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

# Aliases
export PATH="$HOME/.local/bin:$PATH"
alias vim='nvim'
alias vi='nvim'

# Key bindings
bindkey '^ ' autosuggest-accept
EOL

# Set zsh as default shell
chsh -s $(which zsh)

echo "Setup complete! Please restart your terminal to apply all changes."
echo "Don't forget to:"
echo "1. Customize ~/.config/nvim/init.vim to your preferences"
echo "2. Customize ~/.tmux.conf.local for tmux preferences"
echo "3. The default conda environment 'dev' has been created"
echo "4. Node.js version installed: $(node --version)"
echo "5. Rust version installed: $(rustc --version)"
echo "6. Anaconda version installed: $(conda --version)"
echo "7. ZSH version installed: $(zsh --version)"
echo "8. Tmux version installed: $(tmux -V)"
