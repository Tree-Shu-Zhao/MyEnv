#!/bin/bash

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# Visual formatting functions
print_header() {
    echo -e "\n${CYAN}╔════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${WHITE}  $1${CYAN}$(printf "%*s" $((60 - ${#1})) "")║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════════════════════════╝${NC}\n"
}

print_section() {
    echo -e "\n${BLUE}┌─ $1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ ERROR: $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

print_progress() {
    echo -e "${PURPLE}🔄 $1${NC}"
}

print_header "Development Environment Setup"

print_section "System Requirements Check"

# Check available disk space
AVAILABLE_SPACE=$(df /tmp 2>/dev/null | awk 'NR==2 {print $4}' || echo "0")
if [[ "$AVAILABLE_SPACE" -lt 1048576 ]]; then  # Less than 1GB
    print_warning "Low disk space detected. Installation may fail."
    print_warning "Available space in /tmp: $(( AVAILABLE_SPACE / 1024 ))MB"
    print_warning "Recommended: At least 1GB free space"
else
    print_success "Sufficient disk space available"
fi

# Test write permissions to /tmp
if ! touch /tmp/install_test 2>/dev/null; then
    print_error "Cannot write to /tmp directory. Check permissions."
    exit 1
else
    rm -f /tmp/install_test
    print_success "Write permissions verified"
fi

print_section "OS Detection & Privilege Check"

OS=""
ARCH=""
SUDO_CMD=""

# Check if we need sudo (not root and sudo is available)
if [[ $EUID -ne 0 ]] && command -v sudo >/dev/null 2>&1; then
    SUDO_CMD="sudo"
    print_info "Running with sudo privileges"
elif [[ $EUID -eq 0 ]]; then
    print_info "Running as root"
else
    print_warning "Running without root privileges and no sudo available"
fi

if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    OS="Linux"
    ARCH="x86_64"
    print_success "Detected Linux OS"
    
    # Update package manager and install dependencies
    print_progress "Installing system dependencies..."
    if command -v apt >/dev/null 2>&1; then
        print_info "Using apt package manager"
        $SUDO_CMD apt update -y >/dev/null 2>&1
        $SUDO_CMD apt install -y git curl wget tmux zsh build-essential unzip ripgrep xclip >/dev/null 2>&1
        print_success "System dependencies installed via apt"
    elif command -v yum >/dev/null 2>&1; then
        print_info "Using yum package manager"
        $SUDO_CMD yum update -y >/dev/null 2>&1
        $SUDO_CMD yum install -y git curl wget tmux zsh gcc gcc-c++ make unzip ripgrep xclip >/dev/null 2>&1
        print_success "System dependencies installed via yum"
    elif command -v pacman >/dev/null 2>&1; then
        print_info "Using pacman package manager"
        $SUDO_CMD pacman -Sy --noconfirm git curl wget tmux zsh base-devel unzip ripgrep xclip >/dev/null 2>&1
        print_success "System dependencies installed via pacman"
    elif command -v apk >/dev/null 2>&1; then
        print_info "Using apk package manager (Alpine Linux)"
        $SUDO_CMD apk update >/dev/null 2>&1
        $SUDO_CMD apk add git curl wget tmux zsh build-base unzip ripgrep xclip >/dev/null 2>&1
        print_success "System dependencies installed via apk"
    else
        print_warning "No supported package manager found (apt/yum/pacman/apk)"
        print_warning "Please install manually: git curl wget tmux zsh build tools"
    fi
elif [[ "$OSTYPE" == "darwin"* ]]; then
    OS="MacOSX"
    ARCH="x86_64"
    if [[ $(uname -m) == "arm64" ]]; then
        ARCH="arm64"
    fi
    print_success "Detected macOS ($ARCH)"
    
    # Install Homebrew if not present
    if ! command -v brew >/dev/null 2>&1; then
        print_progress "Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" </dev/null
        if [[ $(uname -m) == "arm64" ]]; then
            eval "$(/opt/homebrew/bin/brew shellenv)"
        else
            eval "$(/usr/local/bin/brew shellenv)"
        fi
        print_success "Homebrew installed successfully"
    else
        print_info "Homebrew already installed"
    fi
    
    # Install dependencies via Homebrew
    print_progress "Installing system dependencies via Homebrew..."
    brew install git curl wget tmux zsh ripgrep >/dev/null 2>&1
    print_success "System dependencies installed via Homebrew"
else
    print_error "Unsupported operating system: $OSTYPE"
    exit 1
fi

print_section "Shell Configuration"

# Verify zsh installation
if ! command -v zsh >/dev/null 2>&1; then
    print_error "zsh is not installed or not in PATH. Cannot proceed with Oh My ZSH setup."
    print_error "Please install zsh manually and re-run this script."
    exit 1
else
    print_success "zsh installation verified"
fi

# Install Oh My ZSH
print_progress "Installing Oh My ZSH..."

# Remove existing .zshrc to avoid conflicts
if [[ -f "$HOME/.zshrc" ]]; then
    print_info "Backing up existing .zshrc file"
    mv "$HOME/.zshrc" "$HOME/.zshrc.backup.$(date +%Y%m%d_%H%M%S)"
fi

export RUNZSH=no
export CHSH=yes
# Provide "y" input to answer any interactive prompts (especially shell change)
rm -rf $HOME/.oh-my-zsh
if printf "y\n" | sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended >/dev/null 2>&1; then
    print_success "Oh My ZSH installed successfully"
else
    print_warning "Oh My ZSH installation may have failed"
fi

print_progress "Installing ZSH plugins..."
if git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions >/dev/null 2>&1; then
    print_success "zsh-autosuggestions installed"
else
    print_info "zsh-autosuggestions already installed or failed to install"
fi

if git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting >/dev/null 2>&1; then
    print_success "zsh-syntax-highlighting installed"
else
    print_info "zsh-syntax-highlighting already installed or failed to install"
fi

print_section "Terminal Configuration"

# Install oh-my-tmux
print_progress "Installing oh-my-tmux..."
if git clone https://github.com/gpakosz/.tmux.git ~/.tmux >/dev/null 2>&1; then
    print_success "oh-my-tmux cloned successfully"
else
    print_info "oh-my-tmux already installed or failed to clone"
fi

ln -sf ~/.tmux/.tmux.conf ~/.tmux.conf
if cp ~/.tmux/.tmux.conf.local ~/.tmux.conf.local 2>/dev/null; then
    print_success "tmux configuration applied"
else
    print_info "tmux configuration already exists"
fi

print_section "Python Environment Setup"

# Install miniconda3
# Get latest Miniconda version dynamically
print_progress "Fetching latest Miniconda version..."

MINICONDA_VERSION=$(curl -s https://repo.anaconda.com/miniconda/ 2>/dev/null | grep -o 'Miniconda3-py[0-9]*_[0-9]*\.[0-9]*\.[0-9]*-[0-9]*-Linux-x86_64\.sh' | head -1 | sed 's/Miniconda3-\(.*\)-Linux-x86_64\.sh/\1/')

# Fallback to known good version if both methods fail
if [[ -z "$MINICONDA_VERSION" || "$MINICONDA_VERSION" == "null" ]]; then
    print_warning "Failed to fetch latest version, using fallback version"
    MINICONDA_VERSION="py312_24.11.1-0"
else
    print_success "Latest Miniconda version: $MINICONDA_VERSION"
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
print_progress "Downloading Miniconda installer: $MINICONDA_INSTALLER"
if wget -q https://repo.anaconda.com/miniconda/${MINICONDA_INSTALLER} -O /tmp/miniconda.sh; then
    print_success "Download successful, installing Miniconda..."
    if bash /tmp/miniconda.sh -b -p $HOME/miniconda3 >/dev/null 2>&1; then
        print_success "Miniconda installed successfully"
    else
        print_error "Miniconda installation failed"
        exit 1
    fi
    rm -f /tmp/miniconda.sh
else
    print_warning "Download failed, trying fallback version..."
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
    
    print_progress "Downloading fallback installer: $FALLBACK_INSTALLER"
    if wget -q https://repo.anaconda.com/miniconda/${FALLBACK_INSTALLER} -O /tmp/miniconda.sh; then
        if bash /tmp/miniconda.sh -b -p $HOME/miniconda3 >/dev/null 2>&1; then
            print_success "Miniconda (fallback) installed successfully"
        else
            print_error "Miniconda installation failed"
            exit 1
        fi
        rm -f /tmp/miniconda.sh
    else
        print_error "Failed to download Miniconda installer. Please check your internet connection."
        exit 1
    fi
fi
eval "$($HOME/miniconda3/bin/conda shell.bash hook)"
eval "$($HOME/miniconda3/bin/conda shell.zsh hook)"

print_section "Development Tools Installation"

# Install rust first (needed for uv)
print_progress "Installing Rust..."
if curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y >/dev/null 2>&1; then
    print_success "Rust installation completed"
    . "$HOME/.cargo/env"
else
    print_warning "Rust installation failed, some tools may not work"
fi

# Install uv (fast Python package installer)
print_progress "Installing uv..."
if curl -LsSf https://astral.sh/uv/install.sh | sh >/dev/null 2>&1; then
    print_success "uv installation completed"
else
    print_warning "uv installation failed, continuing without uv"
fi

# Install neovim
print_progress "Installing Neovim..."
if [[ "$OS" == "Linux" ]]; then
    if wget -q https://github.com/neovim/neovim/releases/download/v0.10.2/nvim-linux64.tar.gz -O /tmp/nvim.tar.gz; then
        tar -zxf /tmp/nvim.tar.gz -C /tmp/ >/dev/null 2>&1
        mkdir -p ~/.local/opt
        mv /tmp/nvim-linux64 ~/.local/opt/nvim
        mkdir -p ~/.local/bin
        ln -sf ~/.local/opt/nvim/bin/nvim ~/.local/bin/nvim
        rm -f /tmp/nvim.tar.gz
        print_success "Neovim installed successfully"
    else
        print_error "Failed to download Neovim"
        exit 1
    fi
elif [[ "$OS" == "MacOSX" ]]; then
    if wget -q https://github.com/neovim/neovim/releases/download/v0.10.2/nvim-macos-${ARCH}.tar.gz -O /tmp/nvim.tar.gz; then
        tar -zxf /tmp/nvim.tar.gz -C /tmp/ >/dev/null 2>&1
        mkdir -p ~/.local/opt
        mv /tmp/nvim-macos-${ARCH} ~/.local/opt/nvim
        mkdir -p ~/.local/bin
        ln -sf ~/.local/opt/nvim/bin/nvim ~/.local/bin/nvim
        rm -f /tmp/nvim.tar.gz
        print_success "Neovim installed successfully"
    else
        print_error "Failed to download Neovim"
        exit 1
    fi
fi

# Copy nvim configuration
print_progress "Configuring Neovim..."
mkdir -p ~/.config/
if cp -r nvim ~/.config/; then
    print_success "Neovim configuration applied"
else
    print_warning "Failed to copy Neovim configuration"
fi

# Install nodejs
print_progress "Installing Node.js via nvm..."
if wget -qO- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash >/dev/null 2>&1; then
    print_success "nvm installation completed"
    export NVM_DIR="/usr/local/nvm"

    [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
    [ -s "$NVM_DIR/bash_completion" ] && . "$NVM_DIR/bash_completion"
    
    # Install Node.js LTS if nvm is available
    if command -v nvm >/dev/null 2>&1; then
        print_progress "Installing Node.js LTS..."
        if nvm install --lts >/dev/null 2>&1; then
            print_success "Node.js LTS installed"
        else
            print_warning "Node.js installation failed"
        fi
        
        if nvm use --lts >/dev/null 2>&1; then
            print_success "Node.js LTS set as default"
        else
            print_warning "Could not set Node.js LTS as default"
        fi
    else
        print_warning "nvm command not available, Node.js not installed"
    fi
else
    print_warning "nvm installation failed, Node.js not installed"
fi

# Install additional Rust tools if cargo is available
if command -v cargo >/dev/null 2>&1; then
    print_progress "Installing additional Rust tools..."
    if cargo install ripgrep fd-find >/dev/null 2>&1; then
        print_success "Additional Rust tools installed (ripgrep, fd-find)"
    else
        print_warning "Failed to install additional Rust tools"
    fi
else
    print_info "Cargo not available, skipping additional Rust tools"
fi

print_section "Shell Configuration"

# Configure zsh
print_progress "Configuring zsh..."
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

# Load Oh My ZSH if available
if [[ -f "$ZSH/oh-my-zsh.sh" ]]; then
    source "$ZSH/oh-my-zsh.sh"
fi

# Miniconda configuration
if [[ -f "$HOME/miniconda3/bin/conda" ]]; then
    eval "$($HOME/miniconda3/bin/conda shell.zsh hook)"
fi

# Rust configuration
if [[ -f "$HOME/.cargo/env" ]]; then
    source "$HOME/.cargo/env"
else
    export PATH="$HOME/.cargo/bin:$PATH"
fi

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

print_success "zsh configuration file created"

# Check if shell change was successful (Oh My ZSH should have handled this)
if [[ "$SHELL" != "$(which zsh)" ]]; then
    # Try manual shell change as fallback
    if command -v chsh >/dev/null 2>&1; then
        if chsh -s $(which zsh) 2>/dev/null; then
            print_success "Default shell changed to zsh successfully"
        else
            print_warning "Could not change default shell (common in Docker containers)"
            print_info "You can manually start zsh by running: zsh"
        fi
    else
        print_warning "chsh command not available (common in Docker containers)"
        print_info "You can manually start zsh by running: zsh"
    fi
else
    print_success "Default shell is already zsh"
fi

print_header "Installation Complete!"
echo ""
print_section "Installed Software Versions"

# Check versions using zsh (which has all the configurations loaded)
if zsh -c "command -v node" >/dev/null 2>&1; then
    NODE_VERSION=$(zsh -c "node --version" 2>/dev/null)
    print_success "Node.js: $NODE_VERSION"
else
    print_error "Node.js: Not installed"
fi

if zsh -c "command -v rustc" >/dev/null 2>&1; then
    RUST_VERSION=$(zsh -c "rustc --version" 2>/dev/null)
    print_success "Rust: $RUST_VERSION"
else
    print_error "Rust: Not installed"
fi

if zsh -c "command -v conda" >/dev/null 2>&1; then
    CONDA_VERSION=$(zsh -c "conda --version" 2>/dev/null)
    print_success "Miniconda: $CONDA_VERSION"
else
    print_error "Miniconda: Not installed"
fi

# Check for uv in common installation locations
if [[ -x "$HOME/.local/bin/uv" ]]; then
    UV_VERSION=$("$HOME/.local/bin/uv" --version 2>/dev/null)
    print_success "uv: $UV_VERSION"
elif command -v uv >/dev/null 2>&1; then
    UV_VERSION=$(uv --version 2>/dev/null)
    print_success "uv: $UV_VERSION"
else
    print_warning "uv: Not installed"
fi

if command -v zsh >/dev/null 2>&1; then
    print_success "ZSH: $(zsh --version)"
else
    print_error "ZSH: Not installed"
fi

if command -v tmux >/dev/null 2>&1; then
    print_success "Tmux: $(tmux -V)"
else
    print_error "Tmux: Not installed"
fi

# Check for nvim in its installation location
if [[ -x "$HOME/.local/bin/nvim" ]]; then
    NVIM_VERSION=$("$HOME/.local/bin/nvim" --version 2>/dev/null | head -1)
    print_success "Neovim: $NVIM_VERSION"
elif command -v nvim >/dev/null 2>&1; then
    NVIM_VERSION=$(nvim --version 2>/dev/null | head -1)
    print_success "Neovim: $NVIM_VERSION"
else
    print_error "Neovim: Not installed"
fi

echo ""

# Docker-specific instructions
if [[ -f /.dockerenv ]] || [[ -n "${container}" ]]; then
    print_header "🐳 Docker Environment Detected"
    print_info "To start using zsh, run: zsh"
    print_success "Your development environment is ready to use!"
else
    print_header "📋 Next Steps"
    print_info "Please restart your terminal or run 'zsh' to apply all changes."
    print_success "Your development environment is ready to use!"
fi

