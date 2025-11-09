# Mac Setup Script

Automated setup script for new macOS machines.

## Usage

```bash
chmod +x mac-devops-setup.sh
./mac-devops-setup.sh
```

## What it installs

- Xcode CLI Tools
- Homebrew + packages (git, docker, terraform, aws cli, etc.)
- Python (via Homebrew) + pipx tools
- Node.js (via nvm) + npm packages
- Ruby (via rbenv) + gems (bundler, fastlane, cocoapods)
- Terraform + related tools
- Common applications (Docker, VSCode, iTerm2, Slack, etc.)
- Git configuration
- SSH key generation
- Shell configuration (zsh)
