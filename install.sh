#!/usr/bin/env bash

# =============================================================================
# Flutter Build Fix - Automatic Installation Script
# 
# Repository: https://github.com/flutterkage2k/flutter-build-fix
# Author: Heesung Jin (kage2k)
# Version: 3.3.0 - Fixed Version Check & Location Issues
# =============================================================================

set -e

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Configuration
REPO="flutterkage2k/flutter-build-fix"
INSTALL_DIR="$HOME/.flutter-tools"
SCRIPT_NAME="flutter_build_fix.sh"
SCRIPT_URL="https://raw.githubusercontent.com/$REPO/main/$SCRIPT_NAME"
VERSION_URL="https://api.github.com/repos/$REPO/releases/latest"

# Log functions
log_info()    { echo -e "${BLUE}[INFO] $1${NC}"; }
log_success() { echo -e "${GREEN}[SUCCESS] $1${NC}"; }
log_warning() { echo -e "${YELLOW}[WARNING] $1${NC}"; }
log_error()   { echo -e "${RED}[ERROR] $1${NC}"; }

# Enhanced shell detection
detect_shell() {
    if [ -n "$ZSH_VERSION" ]; then
        echo "zsh"
        return
    elif [ -n "$BASH_VERSION" ]; then
        echo "bash"
        return
    fi

    case "$SHELL" in
        */zsh) echo "zsh" ;;
        */bash) echo "bash" ;;
        */fish) echo "fish" ;;
        *) 
            ps -p "$PPID" -o comm= 2>/dev/null | sed 's/-//' | awk '{print tolower($1)}' || echo "bash"
            ;;
    esac
}

# Get shell configuration file
get_shell_rc() {
    local shell_type=$(detect_shell)
    case $shell_type in
        zsh)
            [ -f "$HOME/.zshrc" ] && echo "$HOME/.zshrc" || echo "$HOME/.zshrc"
            ;;
        bash)
            [ -f "$HOME/.bashrc" ] && echo "$HOME/.bashrc" || echo "$HOME/.bash_profile"
            ;;
        fish)
            echo "$HOME/.config/fish/config.fish"
            ;;
        *)
            echo "$HOME/.profile"
            ;;
    esac
}

# Cross-platform sed function
safe_sed() {
    local pattern="$1"
    local file="$2"
    
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        sed -i '' "$pattern" "$file" 2>/dev/null || true
    else
        # Linux
        sed -i "$pattern" "$file" 2>/dev/null || true
    fi
}

check_dependencies() {
    log_info "Checking dependencies..."
    
    if ! command -v curl >/dev/null 2>&1; then
        if command -v wget >/dev/null 2>&1; then
            log_warning "curl not found, using wget instead"
            USE_WGET=true
        else
            log_error "curl or wget is required"
            exit 1
        fi
    fi
}

# Normalize version strings (remove 'v' prefix if present)
normalize_version() {
    echo "$1" | sed 's/^v//'
}

get_latest_version() {
    log_info "Checking latest version..."
    
    local latest_version=""
    if [ "$USE_WGET" = true ]; then
        latest_version=$(wget -qO- "$VERSION_URL" 2>/dev/null | grep '"tag_name"' | sed -E 's/.*"([^"]+)".*/\1/' | head -1 2>/dev/null || echo "")
    else
        latest_version=$(curl -fsSL "$VERSION_URL" 2>/dev/null | grep '"tag_name"' | sed -E 's/.*"([^"]+)".*/\1/' | head -1 2>/dev/null || echo "")
    fi
    
    if [ -n "$latest_version" ]; then
        log_info "Latest version: $latest_version"
        echo "$latest_version"
    else
        log_warning "Could not fetch version info, using default"
        echo "v3.3.0"
    fi
}

download_script() {
    log_info "Downloading Flutter Build Fix script..."
    
    # Create installation directory
    mkdir -p "$INSTALL_DIR"
    
    # Download script
    if [ "$USE_WGET" = true ]; then
        if ! wget -q "$SCRIPT_URL" -O "$INSTALL_DIR/$SCRIPT_NAME"; then
            log_error "Download failed: $SCRIPT_URL"
            log_info "Please check if the file exists on GitHub"
            exit 1
        fi
    else
        if ! curl -fsSL "$SCRIPT_URL" -o "$INSTALL_DIR/$SCRIPT_NAME"; then
            log_error "Download failed: $SCRIPT_URL"
            log_info "Please check if the file exists on GitHub"
            exit 1
        fi
    fi
    
    # Make executable
    chmod +x "$INSTALL_DIR/$SCRIPT_NAME"
    log_success "Script downloaded: $INSTALL_DIR/$SCRIPT_NAME"
}

setup_aliases() {
    log_info "Setting up aliases..."
    
    local shell_type=$(detect_shell)
    local shell_rc=$(get_shell_rc)
    
    log_info "Detected shell: $shell_type"
    log_info "Configuration file: $shell_rc"
    
    # Create backup
    if [ -f "$shell_rc" ]; then
        cp "$shell_rc" "${shell_rc}.backup.$(date +%Y%m%d_%H%M%S)"
        log_info "Backup created: ${shell_rc}.backup.$(date +%Y%m%d_%H%M%S)"
    fi
    
    # Remove existing flutter-fix aliases
    if [ -f "$shell_rc" ]; then
        safe_sed '/# Flutter Build Fix aliases/d' "$shell_rc"
        safe_sed '/alias flutter-fix=/d' "$shell_rc"
        safe_sed '/alias ffand=/d' "$shell_rc"
        safe_sed '/alias ffios=/d' "$shell_rc"
        safe_sed '/alias ff-full=/d' "$shell_rc"
        safe_sed '/alias ff-dry=/d' "$shell_rc"
        safe_sed '/alias ff-auto=/d' "$shell_rc"
    fi
    
    # Apply shell-specific alias syntax
    case $shell_type in
        fish)
            # Create config directory for fish
            mkdir -p "$(dirname "$shell_rc")"
            cat >> "$shell_rc" << EOF

# Flutter Build Fix aliases
alias flutter-fix="$INSTALL_DIR/$SCRIPT_NAME --full"
alias ffand="$INSTALL_DIR/$SCRIPT_NAME --android"
alias ffios="$INSTALL_DIR/$SCRIPT_NAME --ios"
alias ff-full="$INSTALL_DIR/$SCRIPT_NAME --full --auto"
alias ff-dry="$INSTALL_DIR/$SCRIPT_NAME --full --dry-run"
alias ff-auto="$INSTALL_DIR/$SCRIPT_NAME --full --auto"
EOF
            ;;
        *)
            # POSIX compatible shells (bash, zsh, etc.)
            cat >> "$shell_rc" << EOF

# Flutter Build Fix aliases
alias flutter-fix="$INSTALL_DIR/$SCRIPT_NAME --full"
alias ffand="$INSTALL_DIR/$SCRIPT_NAME --android"
alias ffios="$INSTALL_DIR/$SCRIPT_NAME --ios"
alias ff-full="$INSTALL_DIR/$SCRIPT_NAME --full --auto"
alias ff-dry="$INSTALL_DIR/$SCRIPT_NAME --full --dry-run"
alias ff-auto="$INSTALL_DIR/$SCRIPT_NAME --full --auto"
EOF
            ;;
    esac
    
    log_success "Aliases configured in: $shell_rc"
}

verify_installation() {
    log_info "Verifying installation..."
    
    if [ -f "$INSTALL_DIR/$SCRIPT_NAME" ] && [ -x "$INSTALL_DIR/$SCRIPT_NAME" ]; then
        log_success "Script installation verified"
        
        # Simple version display without running the script
        log_info "Installed version: v3.3.0"
        return 0
    else
        log_error "Installation verification failed"
        return 1
    fi
}

check_flutter() {
    log_info "Checking Flutter environment..."
    
    if command -v flutter >/dev/null 2>&1; then
        local flutter_version=$(flutter --version 2>/dev/null | head -n1 | grep -o 'Flutter [0-9.]*' | cut -d' ' -f2 2>/dev/null || echo "unknown")
        log_info "Flutter version: $flutter_version"
        
        # Check if we're in a Flutter project (but don't require it)
        if [ -f "pubspec.yaml" ]; then
            local project_name=$(grep "^name:" pubspec.yaml | cut -d' ' -f2 | tr -d '"' | head -1 2>/dev/null || echo "unknown")
            log_info "Flutter project detected: $project_name"
        else
            log_info "Not in Flutter project directory (this is normal for installation)"
        fi
    else
        log_warning "Flutter not installed"
        log_info "Install Flutter: https://docs.flutter.dev/get-started/install"
    fi
}

check_system() {
    log_info "System compatibility check..."
    
    case "$OSTYPE" in
        darwin*)
            log_success "macOS detected - full support available"
            ;;
        linux*)
            log_info "Linux detected - Android support available"
            log_warning "iOS support requires macOS"
            ;;
        *)
            log_warning "Unsupported system: $OSTYPE"
            log_info "This script is optimized for macOS and Linux"
            ;;
    esac
    
    # Check Java
    if command -v java >/dev/null 2>&1; then
        local java_version=$(java -version 2>&1 | head -n1 | grep -o '[0-9]*' | head -1)
        if [ "$java_version" -ge 17 ] 2>/dev/null; then
            log_success "Java $java_version detected"
        else
            log_warning "Java 17+ recommended (current: $java_version)"
        fi
    else
        log_warning "Java not found - required for Android development"
    fi
}

check_existing_installation() {
    if [ -f "$INSTALL_DIR/$SCRIPT_NAME" ]; then
        log_info "Existing installation detected"
        
        # Get current installed version from file
        local current_version=$(grep "SCRIPT_VERSION=" "$INSTALL_DIR/$SCRIPT_NAME" | cut -d'"' -f2 2>/dev/null || echo "unknown")
        local latest_version=$(get_latest_version)
        
        # Normalize versions for comparison
        local current_norm=$(normalize_version "$current_version")
        local latest_norm=$(normalize_version "$latest_version")
        
        log_info "Current installed: v$current_norm"
        log_info "Latest available: $latest_version"
        
        if [ "$current_norm" != "$latest_norm" ]; then
            log_warning "Update available: v$current_norm -> $latest_version"
        else
            log_success "Already up to date"
        fi
    else
        log_info "New installation"
    fi
}

show_completion_message() {
    local shell_type=$(detect_shell)
    local shell_rc=$(get_shell_rc)
    
    echo ""
    log_success "Flutter Build Fix installation completed!"
    echo ""
    log_info "Installation location: $INSTALL_DIR/$SCRIPT_NAME"
    log_info "Detected shell: $shell_type"
    log_info "Configuration file: $shell_rc"
    log_info "Version: v3.3.0"
    echo ""
    echo -e "${BLUE}Usage Commands:${NC}"
    echo "  flutter-fix    # Full cleanup (Android + iOS)"
    echo "  ffand          # Android only"
    echo "  ffios          # iOS only (macOS)"
    echo "  ff-full        # Full cleanup (auto mode)"
    echo "  ff-dry         # Preview changes (dry-run)"
    echo "  ff-auto        # Auto mode with defaults"
    echo ""
    echo -e "${YELLOW}Important:${NC}"
    echo "  Open a new terminal or run:"
    echo -e "  ${GREEN}source $shell_rc${NC}"
    echo ""
    echo -e "${CYAN}Next Steps:${NC}"
    echo "  1. Open a new terminal (or source your shell config)"
    echo "  2. Navigate to your Flutter project directory"
    echo "  3. Run: flutter-fix"
    echo ""
    echo -e "${BLUE}Advanced Usage:${NC}"
    echo "  $INSTALL_DIR/$SCRIPT_NAME --help    # Show all options"
    echo "  $INSTALL_DIR/$SCRIPT_NAME --version # Show version"
    echo ""
    echo -e "${GREEN}Update:${NC}"
    echo "  curl -fsSL https://raw.githubusercontent.com/$REPO/main/install.sh | bash"
    echo ""
    echo -e "${BLUE}Features:${NC}"
    echo "  • Flutter 3.35.3 optimization"
    echo "  • Kotlin DSL + Groovy DSL support"
    echo "  • 16KB page size support (Google Play 2025)"
    echo "  • AGP 8.7.3 + Gradle 8.12 + Kotlin 2.1.0"
    echo "  • Safe operations with backups"
    echo ""
    echo -e "${CYAN}Documentation:${NC}"
    echo "  https://github.com/$REPO"
}

main() {
    echo -e "${BLUE}"
    echo "=================================================================="
    echo "    Flutter Build Fix - Automatic Installation"
    echo "    Universal DSL Support | Kotlin DSL + Groovy DSL"
    echo "    Repository: https://github.com/$REPO"
    echo "    Author: Heesung Jin (kage2k)"
    echo "=================================================================="
    echo -e "${NC}"
    
    check_dependencies
    check_system
    check_existing_installation
    check_flutter
    download_script
    setup_aliases
    
    if verify_installation; then
        show_completion_message
    else
        log_error "Installation failed"
        exit 1
    fi
}

# Execute script
main "$@"