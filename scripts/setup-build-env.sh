#!/usr/bin/env bash
# setup-build-env.sh - Setup Shark OS build environment
# Requires: Alpine Linux or compatible system with apk package manager

# Source common helpers if available
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "$SCRIPT_DIR/lib/common.sh" ]; then
    # shellcheck disable=SC1090
    source "$SCRIPT_DIR/lib/common.sh"
else
    set -e
    log_info() { echo "[*] $*"; }
    log_warn() { echo "[!] $*"; }
    log_error() { echo "[!] $*"; }
fi

# Check if running on Alpine or Alpine-compatible system
check_system() {
    log_info "Checking system compatibility..."
    
    if ! command -v apk &> /dev/null; then
        log_error "apk package manager not found"
        log_error "This build environment requires Alpine Linux or a compatible system"
        log_error "Please run this script in Alpine Linux or use Docker:"
        log_error "  docker run -it -v \$(pwd):/shark alpine:latest"
        exit 1
    fi
    
    if ! command -v abuild &> /dev/null; then
        log_warn "abuild not found, will attempt to install"
    fi
    
    log_info "System check passed"
}

# Install build dependencies
install_dependencies() {
    log_info "Installing build dependencies..."
    
    local deps_array=(
        build-base
        abuild
        apk-tools
        alpine-sdk
        alpine-conf
        linux-headers
        gcc
        g++
        musl-dev
        openssl-dev
        bash
        git
        vim
        curl
        wget
        tar
        xz
        bzip2
        gzip
        ca-certificates
        python3
        python3-dev
        perl
        perl-dev
        python3-pip
        git-lfs
        docker
        podman
    )
    log_info "Running: apk update && apk add <deps>"
    apk update
    apk add --no-cache "${deps_array[@]}"
    log_info "Dependencies installed"
}

# Setup abuild keys for signing packages
setup_abuild_keys() {
    log_info "Setting up abuild keys for package signing..."
    
    # Create .abuild directory if it doesn't exist
    mkdir -p ~/.abuild
    
    if [ ! -f ~/.abuild/abuild.conf ]; then
        log_info "Creating abuild configuration..."
        cat > ~/.abuild/abuild.conf << 'EOF'
# abuild.conf - Build configuration
PACKAGER="Shark OS Developers <dev@sharkoq.io>"
MAINTAINER="$PACKAGER"
JOBS=$(nproc)
MAKEFLAGS="-j${JOBS}"

# Use ccache if available
if which ccache >/dev/null 2>&1; then
    CC=ccache\ gcc
    CXX=ccache\ g++
fi
EOF
        log_info "abuild.conf created"
    fi
    
    # Generate signing keys if they don't exist
    # Use nullglob + array check to handle globbing safely in bash
    shopt -s nullglob
    rsa_files=(~/.abuild/*.rsa)
    shopt -u nullglob
    if [ ${#rsa_files[@]} -eq 0 ]; then
        log_warn "Generating new abuild RSA key pair (this may take a moment)..."
        abuild-keygen -a -i -n 2>&1 || log_warn "Key generation may have skipped if keys already exist"
    fi
    
    log_info "abuild keys setup complete"
}

# Create build directories
create_build_dirs() {
    log_info "Creating build directory structure..."
    
    local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    local project_root="$(dirname "$script_dir")"
    
    mkdir -p "$project_root/dist"
    mkdir -p "$project_root/.cache"
    mkdir -p "$project_root/tmp"
    mkdir -p /var/cache/distfiles
    
    log_info "Build directories created"
}

# Setup git hooks (optional)
setup_git_hooks() {
    log_info "Setting up git hooks..."
    
    local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    local project_root="$(dirname "$script_dir")"
    local hooks_dir="$project_root/.git/hooks"
    
    if [ -d "$project_root/.git" ]; then
        mkdir -p "$hooks_dir"
        
        # Create pre-commit hook for linting
        cat > "$hooks_dir/pre-commit" << 'EOF'
#!/usr/bin/env bash
# Pre-commit hook: run shellcheck and syntax checks

set -eEuo pipefail
# Use repo helper if available
HOOK_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$HOOK_DIR/.." && pwd)"

echo "[*] Running pre-commit checks..."

# Run ShellCheck via helper (will print instructions if shellcheck not available)
bash "$ROOT_DIR/scripts/ci/run-shellcheck.sh" || { echo "[!] ShellCheck failed. Fix issues before commit."; exit 1; }

# Syntax check
find . -name '*.sh' -type f -print0 | while IFS= read -r -d '' script; do
    if ! bash -n "$script" 2>/dev/null; then
        echo "[!] Syntax error in $script"
        exit 1
    fi
done

# Additional checks (e.g., no compiled artifacts)
if git ls-files --others --exclude-standard | grep -E '(^dist/|\.iso$|\.img$)' >/dev/null; then
    echo "[!] Untracked build artifacts present (dist/, *.iso). Please move or .gitignore them." >&2
    exit 1
fi

echo "[+] Pre-commit checks passed"
EOF
        chmod +x "$hooks_dir/pre-commit"
        log_info "Git hooks installed"
    else
        log_warn "Not a git repository, skipping git hooks setup"
    fi
}

# Configure Docker/Podman for building
setup_container_env() {
    log_info "Setting up container environment..."
    
    # Check if Docker/Podman is available
    if command -v docker &> /dev/null; then
        log_info "Docker found: $(docker --version)"
    elif command -v podman &> /dev/null; then
        log_info "Podman found: $(podman --version)"
    else
        log_warn "Docker/Podman not found - some build features may be limited"
    fi
}

# Create example build script
create_build_script() {
    log_info "Creating example build script..."
    
    local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    local project_root="$(dirname "$script_dir")"
    
    cat > "$project_root/build.sh" << 'EOF'
#!/bin/bash
# build.sh - Simple Shark OS build script

set -e

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DIST_DIR="$PROJECT_ROOT/dist"
APORTS_DIR="$PROJECT_ROOT/aports"

log_info() {
    echo "[*] $1"
}

log_info "Building Shark OS..."
log_info "Project Root: $PROJECT_ROOT"
log_info "Distribution Dir: $DIST_DIR"

# Build ISO image
if [ -f "$PROJECT_ROOT/mkimage/mkimg.shark.sh" ]; then
    log_info "Building ISO image..."
    bash "$PROJECT_ROOT/mkimage/mkimg.shark.sh"
else
    log_info "mkimg.shark.sh not found"
    exit 1
fi

log_info "Build complete!"
echo "Artifacts in: $DIST_DIR"
ls -lh "$DIST_DIR"
EOF
    chmod +x "$project_root/build.sh"
    
    log_info "Build script created at: $project_root/build.sh"
}

# Print summary
print_summary() {
    echo ""
    echo "========================================="
    echo "Build Environment Setup Complete!"
    echo "========================================="
    echo ""
    echo "Next steps:"
    echo "1. Edit aports/APKBUILD files as needed"
    echo "2. Run: bash build.sh"
    echo "3. Output will be in: dist/"
    echo ""
    echo "For more information:"
    echo "  - Alpine Linux: https://alpinelinux.org"
    echo "  - abuild: https://wiki.alpinelinux.org/wiki/Creating_an_alpine_package"
    echo "========================================="
}

# Main
main() {
    check_system
    install_dependencies
    setup_abuild_keys
    create_build_dirs
    setup_git_hooks
    setup_container_env
    create_build_script
    print_summary
}

main "$@"
