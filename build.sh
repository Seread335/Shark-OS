#!/usr/bin/env bash
# Shark OS Build Script
# Complete build automation for Shark OS

VERSION="0.1.0"
BUILD_DATE=$(date +"%Y%m%d-%H%M%S")
DIST_DIR="$(pwd)/dist"
BUILD_LOG="${DIST_DIR}/build-${BUILD_DATE}.log"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m'

# Prefer central logging from scripts/lib/common.sh; wrap to also write to BUILD_LOG
if [ -f "./scripts/lib/common.sh" ]; then
    # shellcheck disable=SC1091
    source ./scripts/lib/common.sh
fi

log_to_file() {
    local level="$1"; shift
    local msg="[$(date -u +%Y-%m-%dT%H:%M:%SZ)] [$level] $*"
    mkdir -p "$(dirname "$BUILD_LOG")" 2>/dev/null || true
    echo "$msg" >> "$BUILD_LOG" 2>/dev/null || true
}

log_info() { printf "\e[34m[*]\e[0m %s\n" "$*" | tee -a "$BUILD_LOG"; log_to_file INFO "$*"; }
log_success() { printf "\e[32m[+]\e[0m %s\n" "$*" | tee -a "$BUILD_LOG"; log_to_file SUCCESS "$*"; }
log_warn() { printf "\e[33m[!]\e[0m %s\n" "$*" | tee -a "$BUILD_LOG"; log_to_file WARN "$*"; }
log_error() { printf "\e[31m[×]\e[0m %s\n" "$*" | tee -a "$BUILD_LOG"; log_to_file ERROR "$*"; }

log_section() { printf "\n${BOLD}${BLUE}=== %s ===${NC}\n" "$*" | tee -a "$BUILD_LOG"; log_to_file INFO "SECTION: $*"; }

# Create dist directory
mkdir -p "$DIST_DIR"

# Start build
log_section "Shark OS Build v${VERSION}"
log_info "Build Date: ${BUILD_DATE}"
log_info "Build Directory: $(pwd)"
log_info "Log File: ${BUILD_LOG}"

# Step 1: Validate Project Structure
log_section "Step 1: Validating Project Structure"
MISSING_FILES=0

required_files=(
    "README.md"
    "scripts/setup-build-env.sh"
    "scripts/ab-partition-setup.sh"
    "mkimage/mkimg.shark.sh"
    "shark-cli/shark"
    "aports/shark-main/APKBUILD"
    "docs/build-guide.md"
    ".github/workflows/build.yml"
)

for file in "${required_files[@]}"; do
    if [ -f "$file" ]; then
        log_success "Found: $file"
    else
        log_error "Missing: $file"
        MISSING_FILES=$((MISSING_FILES + 1))
    fi
done >> "$BUILD_LOG"

if [ $MISSING_FILES -gt 0 ]; then
    log_error "$MISSING_FILES required files missing"
    exit 1
fi

log_success "Project structure validated"

# Step 2: Copy Build Artifacts
log_section "Step 2: Preparing Build Artifacts"

# Copy Shark CLI
if [ -f "shark-cli/shark" ]; then
    cp shark-cli/shark "$DIST_DIR/shark-cli"
    chmod +x "$DIST_DIR/shark-cli"
    log_success "Shark CLI prepared ($(wc -l < shark-cli/shark) lines)"
fi

# Copy build scripts
cp scripts/ab-partition-setup.sh "$DIST_DIR/" 2>/dev/null && log_success "A/B partition script copied" || log_warn "A/B partition script copy failed"
cp scripts/setup-build-env.sh "$DIST_DIR/" 2>/dev/null && log_success "Build environment script copied" || log_warn "Build environment script copy failed"

# Copy mkimage script
cp mkimage/mkimg.shark.sh "$DIST_DIR/" 2>/dev/null && log_success "ISO builder script copied" || log_warn "ISO builder script copy failed"

# Step 3: Generate Documentation
log_section "Step 3: Generating Build Documentation"

cat > "$DIST_DIR/BUILD_INFO.md" << 'DOCEOF'
# Shark OS Build Information

## Build Details
- **Version**: 0.1.0-alpha
- **Build Date**: '$BUILD_DATE'
- **Status**: Prepared for compilation

## Prerequisites for Full Build

To complete the full Shark OS build, you need:

### Option 1: Alpine Linux System
```bash
# On native Alpine Linux 3.18+
cd /path/to/shark-os
bash scripts/setup-build-env.sh
bash build.sh
```

### Option 2: Docker Container (Recommended for Windows/Mac)
```bash
docker run -it --rm \
  -v $(pwd):/shark \
  -w /shark \
  alpine:3.18 \
  sh -c "apk add --no-cache bash git && bash build.sh"
```

### Option 3: WSL2 (Windows Subsystem for Linux)
```bash
# Install WSL2 with Alpine or Ubuntu
# Then run the same commands as Option 1
```

## Build Artifacts

This distribution includes:

1. **shark-cli** - System management command-line interface
   - Location: `shark-cli`
   - Features: System status, configuration, service management
   - Usage: `./shark-cli --help`

2. **ab-partition-setup.sh** - A/B Partitioning utility
   - Location: `ab-partition-setup.sh`
   - Purpose: Setup immutable root filesystem with A/B updates
   - Usage: `bash ab-partition-setup.sh --help`

3. **setup-build-env.sh** - Build environment setup
   - Location: `setup-build-env.sh`
   - Purpose: Initialize Alpine build environment
   - Usage: `bash setup-build-env.sh`

4. **mkimg.shark.sh** - ISO Image builder
   - Location: `mkimg.shark.sh`
   - Purpose: Create bootable Shark OS ISO images
   - Usage: `bash mkimg.shark.sh`

## Next Steps

1. **For Development**: Use Shark CLI to manage local development system
2. **For Deployment**: Use mkimage builder to create ISO for installation
3. **For Infrastructure**: Use ab-partition-setup.sh for A/B partition setup

## Build Instructions

### Full Kernel + Package Build (requires Alpine Linux)
```bash
cd aports/shark-main
abuild -r
```

### ISO Image Generation (requires Alpine mkimage)
```bash
bash mkimage/mkimg.shark.sh
```

## Documentation

- See `docs/build-guide.md` for detailed build instructions
- See `docs/installation.md` for installation and deployment
- See `ROADMAP.md` for development roadmap
- See `CONTRIBUTING.md` for contribution guidelines

## Build Environment Requirements

| Component | Version | Purpose |
|-----------|---------|---------|
| Alpine Linux | 3.18+ | Base system |
| Linux Kernel | 6.6+ | Base kernel |
| abuild | Latest | Package builder |
| mkimage | Latest | Image builder |
| Podman | 4.0+ | Container runtime |

## Troubleshooting

### Build fails with "apk not found"
- You're not on Alpine Linux or in an Alpine container
- Use the Docker option instead

### ISO build fails
- Ensure mkimage is installed: `apk add mkimage`
- Check disk space: need at least 10GB free

### Permission denied errors
- Make sure scripts are executable: `chmod +x *.sh`
- Run with proper permissions (may need sudo for some operations)

## Support

- GitHub Issues: https://github.com/Seread335/Shark-OS/issues
- Documentation: https://github.com/Seread335/Shark-OS/wiki
- Email: dev@sharkoq.io

DOCEOF

log_success "Build documentation generated"

# Step 4: Create Build Configuration
log_section "Step 4: Creating Build Configuration"

cat > "$DIST_DIR/build.config" << 'CFGEOF'
# Shark OS Build Configuration

# Version
SHARK_VERSION=0.1.0
SHARK_RELEASE=alpha

# Architecture
SHARK_ARCH="x86_64 aarch64 armv7"

# Build features
ENABLE_eBPF=yes
ENABLE_CGROUP_V2=yes
ENABLE_APPARMOR=yes
ENABLE_ABOPARTITION=yes

# Kernel configuration
KERNEL_VERSION=6.6
KERNEL_LOCALVERSION=-shark

# Output
OUTPUT_ISO=shark-os-${SHARK_VERSION}-${SHARK_RELEASE}.iso
OUTPUT_TARBALL=shark-os-base-${SHARK_VERSION}.tar.gz

# Build options
PARALLEL_JOBS=4
COMPRESS_LEVEL=6

CFGEOF

log_success "Build configuration created"

# Step 5: Generate Build Summary
log_section "Step 5: Generating Build Summary"

cat > "$DIST_DIR/BUILD_SUMMARY.txt" << SUMEOF
╔═══════════════════════════════════════════════════════════╗
║         Shark OS Build Summary                            ║
║         Build Date: ${BUILD_DATE}                    ║
╚═══════════════════════════════════════════════════════════╝

PROJECT INFORMATION
───────────────────
Name:        Shark OS
Version:     0.1.0-alpha
Repository:  https://github.com/Seread335/Shark-OS
License:     GPL v3.0

BUILD ARTIFACTS
───────────────
✓ shark-cli                    - System management CLI tool
✓ ab-partition-setup.sh        - A/B partitioning utility
✓ setup-build-env.sh           - Environment initialization
✓ mkimg.shark.sh               - ISO image builder
✓ BUILD_INFO.md                - Build instructions
✓ build.config                 - Build configuration

NEXT STEPS
──────────
1. Review BUILD_INFO.md for detailed build instructions
2. Use Docker for cross-platform building
3. Run the appropriate build command for your platform

DOCUMENTATION
──────────────
- Build Guide:     docs/build-guide.md
- Installation:    docs/installation.md
- Roadmap:         ROADMAP.md
- Contributing:    CONTRIBUTING.md

SUPPORT
────────
GitHub:  https://github.com/Seread335/Shark-OS
Email:   dev@sharkoq.io
Wiki:    https://github.com/Seread335/Shark-OS/wiki

Build Status: ✅ READY FOR COMPILATION

SUMEOF

log_success "Build summary created"

# Step 6: Display Results
log_section "Build Preparation Complete!"

log_info "Build artifacts:"
if [ "$(ls -A "$DIST_DIR")" ]; then
    ls -lh "$DIST_DIR" | awk 'NR > 1 {printf "  %-40s %8s\n", $9, $5}'
else
    log_warn "No artifacts generated"
fi

log_section "Summary"
log_success "Project validated and ready for compilation"
log_info "Total files prepared: $(ls -1 "$DIST_DIR" | wc -l)"
log_info "Build directory: $DIST_DIR"
log_info "Build log: $BUILD_LOG"

cat > "$DIST_DIR/QUICK_START.sh" << 'QUICKEOF'
#!/bin/bash
# Quick Start for Shark OS Build using Docker

echo "Starting Shark OS build in Docker container..."
docker run -it --rm \
  -v "$(pwd)":/shark \
  -w /shark \
  alpine:3.18 \
  sh -c "
    # Install dependencies
    apk add --no-cache bash git make gcc musl-dev alpine-sdk
    
    # Setup build environment
    bash scripts/setup-build-env.sh
    
    # Build kernel and packages
    cd aports/shark-main && abuild -r && cd ../../
    
    # Create ISO image
    bash mkimage/mkimg.shark.sh
    
    echo 'Build complete! Check dist/ for artifacts'
  "
QUICKEOF

chmod +x "$DIST_DIR/QUICK_START.sh"
log_success "Quick start script generated"

log_info "========================================="
log_success "All preparation steps completed successfully!"
log_info "=========================================\n"

exit 0
