#!/bin/bash

set -e
set -u

log() { echo "▸ $1"; }
skip() { echo "⊘ $1"; }
err() { echo "✗ $1"; }

brew_install() {
    if brew list "$1" &>/dev/null; then
        skip "$1"
    else
        brew install "$1" 2>/dev/null || err "Failed: $1"
    fi
}

brew_cask() {
    if brew list --cask "$1" &>/dev/null; then
        skip "$1"
    else
        brew install --cask "$1" 2>/dev/null || err "Failed: $1"
    fi
}

npm_install() {
    if npm list -g "$1" &>/dev/null; then
        skip "$1"
    else
        npm install -g "$1" 2>/dev/null || err "Failed: $1"
    fi
}

pipx_install() {
    if pipx list 2>/dev/null | grep -q "$1"; then
        skip "$1"
    else
        pipx install "$1" 2>/dev/null || err "Failed: $1"
    fi
}

gem_install() {
    if gem list -i "^${1}$" &>/dev/null; then
        skip "$1"
    else
        gem install "$1" 2>/dev/null || err "Failed: $1"
    fi
}

[[ "$OSTYPE" != "darwin"* ]] && { err "macOS only"; exit 1; }

log "Starting setup..."

if ! xcode-select -p &>/dev/null; then
    log "Installing Xcode CLI Tools..."
    xcode-select --install
    err "Complete Xcode installation, then re-run"
    exit 0
fi

if ! command -v brew &>/dev/null; then
    log "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    [[ $(uname -m) == 'arm64' ]] && eval "$(/opt/homebrew/bin/brew shellenv)"
else
    skip "Homebrew"
    brew update &>/dev/null
fi

log "Homebrew Packages"
brew_install git
brew_install gh
brew_install zsh-completions
brew_install zsh-syntax-highlighting
brew_install zsh-autosuggestions
brew_install tmux
brew_install htop
brew_install tree
brew_install wget
brew_install curl
brew_install jq
brew_install yq
brew_install vim
brew_install git-lfs
brew_install tig
brew_install awscli
brew_install httpie
brew_install gnupg
brew_install openssl
brew_install nmap
brew_install telnet
brew_install netcat
brew_install wrk
brew_install docker-compose
brew_install docker-credential-helper
brew_install dive
brew_install grafana
brew_install prometheus

log "Python"
brew_install python@3.12
brew_install python@3.11
brew_install pipx
brew_install poetry
command -v pipx &>/dev/null && pipx ensurepath &>/dev/null

if command -v pipx &>/dev/null; then
    pipx_install virtualenv
    pipx_install pipenv
    pipx_install black
    pipx_install pylint
    pipx_install pytest
    pipx_install ipython
    pipx_install ansible
fi

log "Node.js"
if [ ! -d "$HOME/.nvm" ]; then
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash &>/dev/null
fi
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

if command -v nvm &>/dev/null; then
    nvm install --lts &>/dev/null
    nvm use --lts &>/dev/null
    nvm alias default node &>/dev/null
    npm_install yarn
    npm_install pnpm
    npm_install npm-check-updates
    npm_install http-server
    npm_install prettier
    npm_install eslint
    npm_install typescript
    npm_install @githubnext/github-copilot-cli
    npm_install @anthropic-ai/claude-cli
fi

log "Ruby & Fastlane"
brew_install rbenv
brew_install ruby-build

if command -v rbenv &>/dev/null; then
    eval "$(rbenv init - zsh 2>/dev/null || rbenv init - bash 2>/dev/null)" || true
    LATEST_RUBY=$(rbenv install -l 2>/dev/null | grep -v - | tail -1 | tr -d '[:space:]')
    if [ -n "$LATEST_RUBY" ] && ! rbenv versions 2>/dev/null | grep -q "$LATEST_RUBY"; then
        rbenv install "$LATEST_RUBY" &>/dev/null || err "Ruby install failed"
        rbenv global "$LATEST_RUBY" &>/dev/null || true
    fi
    if command -v gem &>/dev/null; then
        gem_install bundler
        gem_install fastlane
        gem_install cocoapods
    fi
fi

log "Terraform"
brew_install tfenv
if command -v tfenv &>/dev/null; then
    tfenv install latest &>/dev/null || err "Terraform install failed"
    tfenv use latest &>/dev/null || true
fi
brew_install terraform-docs
brew_install tflint
brew_install packer

log "Applications"
brew_cask docker
brew_cask visual-studio-code
brew_cask iterm2
brew_cask sublime-text
brew_cask slack
brew_cask zoom
brew_cask rectangle
brew_cask alfred
brew_cask the-unarchiver
brew_cask postman
brew_cask google-chrome
brew_cask firefox

log "Git Config"
if ! git config --global user.name &>/dev/null; then
    read -p "Git username: " username
    read -p "Git email: " email
    git config --global user.name "$username"
    git config --global user.email "$email"
    git config --global init.defaultBranch main
    git config --global pull.rebase false
    git config --global core.editor "vim"
    git config --global alias.co checkout
    git config --global alias.br branch
    git config --global alias.ci commit
    git config --global alias.st status
    git config --global alias.lg "log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit"
else
    skip "Git already configured"
fi

log "SSH Key"
if [ ! -f ~/.ssh/id_ed25519 ]; then
    email=$(git config --global user.email 2>/dev/null || echo "")
    [ -z "$email" ] && read -p "Email for SSH: " email
    ssh-keygen -t ed25519 -C "$email" -f ~/.ssh/id_ed25519 -N "" &>/dev/null
    eval "$(ssh-agent -s)" &>/dev/null && ssh-add ~/.ssh/id_ed25519 &>/dev/null
    log "SSH key: $(cat ~/.ssh/id_ed25519.pub)"
else
    skip "SSH key exists"
fi

log "Shell Config"
[ ! -f ~/.zshrc ] && touch ~/.zshrc
if ! grep -q "# DevOps Config" ~/.zshrc; then
    cat >> ~/.zshrc << 'EOF'

# DevOps Config
[[ $(uname -m) == 'arm64' ]] && eval "$(/opt/homebrew/bin/brew shellenv)"
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
command -v rbenv &>/dev/null && eval "$(rbenv init - zsh)"
export PATH="$HOME/.local/bin:$GOPATH/bin:$PATH"
export GOPATH="$HOME/go"

alias ll='ls -lah'; alias ..='cd ..'; alias ...='cd ../..';
alias tf='terraform'; alias d='docker'; alias dc='docker-compose'; alias g='git'
alias dps='docker ps'; alias dpsa='docker ps -a'; alias di='docker images'
mkcd() { mkdir -p "$1" && cd "$1"; }

HISTSIZE=10000; SAVEHIST=10000
setopt SHARE_HISTORY HIST_IGNORE_ALL_DUPS

[ -f /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ] && source /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
[ -f /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh ] && source /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh
EOF
fi

mkdir -p ~/Projects/{personal,work,opensource} ~/Scripts ~/Docker ~/Terraform &>/dev/null

brew cleanup &>/dev/null

log "✓ Setup complete!"
log "Next: source ~/.zshrc && open -a Docker"
