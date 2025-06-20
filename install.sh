#!/bin/bash

echo "Starting development environment setup..."

# Detect OS and privilege level
OS=""
ARCH=""
SUDO_CMD=""

# Check if we need sudo (not root and sudo is available)
if [[ $EUID -ne 0 ]] && command -v sudo >/dev/null 2>&1; then
    SUDO_CMD="sudo"
    echo "Running with sudo privileges"
elif [[ $EUID -eq 0 ]]; then
    echo "Running as root"
else
    echo "Warning: Running without root privileges and no sudo available"
fi

if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    OS="Linux"
    ARCH="x86_64"
    echo "Detected Linux OS"
    
    # Update package manager and install dependencies
    if command -v apt >/dev/null 2>&1; then
        $SUDO_CMD apt update -y
        $SUDO_CMD apt install -y git curl wget tmux zsh build-essential unzip ripgrep xclip
    elif command -v yum >/dev/null 2>&1; then
        $SUDO_CMD yum update -y
        $SUDO_CMD yum install -y git curl wget tmux zsh gcc gcc-c++ make unzip ripgrep xclip
    elif command -v pacman >/dev/null 2>&1; then
        $SUDO_CMD pacman -Sy --noconfirm git curl wget tmux zsh base-devel unzip ripgrep xclip
    elif command -v apk >/dev/null 2>&1; then
        # Alpine Linux (common in Docker containers)
        $SUDO_CMD apk update
        $SUDO_CMD apk add git curl wget tmux zsh build-base unzip ripgrep xclip
    else
        echo "Warning: No supported package manager found (apt/yum/pacman/apk)"
        echo "Please install manually: git curl wget tmux zsh build tools"
    fi
elif [[ "$OSTYPE" == "darwin"* ]]; then
    OS="MacOSX"
    ARCH="x86_64"
    if [[ $(uname -m) == "arm64" ]]; then
        ARCH="arm64"
    fi
    echo "Detected macOS"
    
    # Install Homebrew if not present
    if ! command -v brew >/dev/null 2>&1; then
        echo "Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" </dev/null
        if [[ $(uname -m) == "arm64" ]]; then
            eval "$(/opt/homebrew/bin/brew shellenv)"
        else
            eval "$(/usr/local/bin/brew shellenv)"
        fi
    fi
    
    # Install dependencies via Homebrew
    brew install git curl wget tmux zsh ripgrep
else
    echo "Unsupported operating system: $OSTYPE"
    exit 1
fi

# Verify zsh installation
if ! command -v zsh >/dev/null 2>&1; then
    echo "ERROR: zsh is not installed or not in PATH. Cannot proceed with Oh My ZSH setup."
    echo "Please install zsh manually and re-run this script."
    exit 1
fi

# Install Oh My ZSH
echo "Installing Oh My ZSH..."
export RUNZSH=no
export CHSH=no
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended </dev/null
git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions 2>/dev/null || echo "zsh-autosuggestions already installed"
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting 2>/dev/null || echo "zsh-syntax-highlighting already installed"

# Install oh-my-tmux
git clone https://github.com/gpakosz/.tmux.git ~/.tmux 2>/dev/null || echo "oh-my-tmux already installed"
ln -sf ~/.tmux/.tmux.conf ~/.tmux.conf
cp ~/.tmux/.tmux.conf.local ~/.tmux.conf.local 2>/dev/null || echo "tmux config already exists"

# Install miniconda3
# Get latest Miniconda version dynamically
echo "Fetching latest Miniconda version..."

# Try method 1: Anaconda API
MINICONDA_VERSION=$(curl -s https://api.anaconda.org/release/continuumio/miniconda3/latest 2>/dev/null | grep -o '"version":"[^"]*' | cut -d'"' -f4)

# Try method 2: Parse download page if API fails
if [[ -z "$MINICONDA_VERSION" || "$MINICONDA_VERSION" == "null" ]]; then
    echo "API method failed, trying download page..."
    MINICONDA_VERSION=$(curl -s https://repo.anaconda.com/miniconda/ 2>/dev/null | grep -o 'Miniconda3-py[0-9]*_[0-9]*\.[0-9]*\.[0-9]*-[0-9]*-Linux-x86_64\.sh' | head -1 | sed 's/Miniconda3-\(.*\)-Linux-x86_64\.sh/\1/')
fi

# Fallback to known good version if both methods fail
if [[ -z "$MINICONDA_VERSION" || "$MINICONDA_VERSION" == "null" ]]; then
    echo "Failed to fetch latest version, using fallback version"
    MINICONDA_VERSION="py312_24.11.1-0"
else
    echo "Latest Miniconda version: $MINICONDA_VERSION"
fi

if [[ "$OS" == "Linux" ]]; then
    MINICONDA_INSTALLER="Miniconda3-${MINICONDA_VERSION}-Linux-x86_64.sh"
elif [[ "$OS" == "MacOSX" ]]; then
    if [[ "$ARCH" == "arm64" ]]; then
        MINICONDA_INSTALLER="Miniconda3-${MINICONDA_VERSION}-MacOSX-arm64.sh"
    else
        MINICONDA_INSTALLER="Miniconda3-${MINICONDA_VERSION}-MacOSX-x86_64.sh"
    fi
fi

# Download Miniconda installer
echo "Downloading Miniconda installer: $MINICONDA_INSTALLER"
if wget -q https://repo.anaconda.com/miniconda/${MINICONDA_INSTALLER} -O /tmp/miniconda.sh; then
    echo "Download successful, installing Miniconda..."
    bash /tmp/miniconda.sh -b -p $HOME/miniconda3
    rm /tmp/miniconda.sh
else
    echo "Download failed, trying fallback version..."
    MINICONDA_FALLBACK_VERSION="py312_24.11.1-0"
    if [[ "$OS" == "Linux" ]]; then
        FALLBACK_INSTALLER="Miniconda3-${MINICONDA_FALLBACK_VERSION}-Linux-x86_64.sh"
    elif [[ "$OS" == "MacOSX" ]]; then
        if [[ "$ARCH" == "arm64" ]]; then
            FALLBACK_INSTALLER="Miniconda3-${MINICONDA_FALLBACK_VERSION}-MacOSX-arm64.sh"
        else
            FALLBACK_INSTALLER="Miniconda3-${MINICONDA_FALLBACK_VERSION}-MacOSX-x86_64.sh"
        fi
    fi
    
    echo "Downloading fallback installer: $FALLBACK_INSTALLER"
    if wget -q https://repo.anaconda.com/miniconda/${FALLBACK_INSTALLER} -O /tmp/miniconda.sh; then
        bash /tmp/miniconda.sh -b -p $HOME/miniconda3
        rm /tmp/miniconda.sh
    else
        echo "ERROR: Failed to download Miniconda installer. Please check your internet connection."
        exit 1
    fi
fi
eval "$($HOME/miniconda3/bin/conda shell.bash hook)"
eval "$($HOME/miniconda3/bin/conda shell.zsh hook)"

# Install uv (fast Python package installer)
curl -LsSf https://astral.sh/uv/install.sh | sh </dev/null
source $HOME/.cargo/env

# Install neovim
if [[ "$OS" == "Linux" ]]; then
    wget -q https://github.com/neovim/neovim/releases/download/v0.10.2/nvim-linux64.tar.gz -O /tmp/nvim.tar.gz
    tar -zxf /tmp/nvim.tar.gz -C /tmp/
    mkdir -p ~/.local/opt
    mv /tmp/nvim-linux64 ~/.local/opt/nvim
    mkdir -p ~/.local/bin
    ln -sf ~/.local/opt/nvim/bin/nvim ~/.local/bin/nvim
    rm /tmp/nvim.tar.gz
elif [[ "$OS" == "MacOSX" ]]; then
    wget -q https://github.com/neovim/neovim/releases/download/v0.10.2/nvim-macos-${ARCH}.tar.gz -O /tmp/nvim.tar.gz
    tar -zxf /tmp/nvim.tar.gz -C /tmp/
    mkdir -p ~/.local/opt
    mv /tmp/nvim-macos-${ARCH} ~/.local/opt/nvim
    mkdir -p ~/.local/bin
    ln -sf ~/.local/opt/nvim/bin/nvim ~/.local/bin/nvim
    rm /tmp/nvim.tar.gz
fi

# Copy nvim configuration
mkdir -p ~/.config/
cp -r nvim ~/.config/

# Install nodejs
wget -qO- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash </dev/null
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
nvm install --lts </dev/null
nvm use --lts

# Install rust
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y </dev/null
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

# Miniconda configuration
eval "$($HOME/miniconda3/bin/conda shell.zsh hook)"

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

# Set zsh as default shell (only if not already zsh)
if [[ "$SHELL" != "$(which zsh)" ]]; then
    echo "Attempting to change default shell to zsh..."
    if command -v chsh >/dev/null 2>&1; then
        if chsh -s $(which zsh) 2>/dev/null; then
            echo "Default shell changed to zsh successfully"
        else
            echo "Warning: Could not change default shell (common in Docker containers)"
            echo "You can manually start zsh by running: zsh"
        fi
    else
        echo "Warning: chsh command not available (common in Docker containers)"
        echo "You can manually start zsh by running: zsh"
    fi
else
    echo "Default shell is already zsh"
fi

echo "Setup complete!"
echo ""
echo "Installed versions:"
echo "1. Node.js: $(node --version)"
echo "2. Rust: $(rustc --version)"
echo "3. Miniconda: $(conda --version)"
echo "4. uv: $(uv --version)"
echo "5. ZSH: $(zsh --version)"
echo "6. Tmux: $(tmux -V)"
echo "7. Neovim: $(nvim --version | head -1)"
echo ""

# Docker-specific instructions
if [[ -f /.dockerenv ]] || [[ -n "${container}" ]]; then
    echo "🐳 Docker container detected!"
    echo "To start using zsh, run: zsh"
    echo "Your development environment is ready to use."
else
    echo "Please restart your terminal or run 'zsh' to apply all changes."
fi
