#!/usr/bin/env bash
# Shark OS Lightweight Test Suite
# Fast validation without system lag

PASSED=0
FAILED=0

# Colors
G='\033[0;32m'
R='\033[0;31m'
Y='\033[1;33m'
B='\033[0;34m'
NC='\033[0m'

# Quick test functions
check_file() {
    if [ -f "$1" ]; then
        printf '%b
' '\1'
        ((PASSED++))
    else
        printf '%b
' '\1'
        ((FAILED++))
    fi
}

check_dir() {
    if [ -d "$1" ]; then
        printf '%b
' '\1'
        ((PASSED++))
    else
        printf '%b
' '\1'
        ((FAILED++))
    fi
}

check_syntax() {
    if bash -n "$1" 2>/dev/null; then
        printf '%b
' '\1'
        ((PASSED++))
    else
        printf '%b
' '\1'
        ((FAILED++))
    fi
}

# Main tests
printf '%b
' '\1'

# Project structure
echo "Project Structure:"
check_dir "aports" "aports directory"
check_dir "mkimage" "mkimage directory"
check_dir "shark-cli" "shark-cli directory"
check_dir "scripts" "scripts directory"
check_dir "docs" "docs directory"

# Key files
printf '%b
' '\1'
check_file "README.md" "README.md"
check_file "ROADMAP.md" "ROADMAP.md"
check_file "CONTRIBUTING.md" "CONTRIBUTING.md"
check_file "LICENSE" "LICENSE"

# Build artifacts
printf '%b
' '\1'
check_dir "dist" "dist directory"
check_file "dist/shark-cli" "shark-cli binary"
check_file "dist/BUILD_INFO.md" "BUILD_INFO.md"
check_file "dist/build.config" "build.config"

# Scripts
printf '%b
' '\1'
check_file "scripts/setup-build-env.sh" "setup-build-env.sh"
check_file "scripts/ab-partition-setup.sh" "ab-partition-setup.sh"
check_syntax "scripts/setup-build-env.sh" "setup-build-env.sh syntax"

# Kernel configs
printf '%b
' '\1'
check_file "aports/shark-main/APKBUILD" "APKBUILD"
check_file "aports/shark-main/config-shark-x86_64" "x86_64 kernel config"
check_file "aports/shark-main/config-shark-aarch64" "ARM64 kernel config"

# CLI tool
printf '%b
' '\1'
check_file "shark-cli/shark" "shark CLI"
check_syntax "shark-cli/shark" "shark CLI syntax"

# Documentation
printf '%b
' '\1'
check_file "docs/build-guide.md" "build-guide.md"
check_file "docs/installation.md" "installation.md"
check_file "docs/config.example.yml" "config.example.yml"

# Summary
TOTAL=$((PASSED + FAILED))
printf '%b
' '\1'
printf '%b
' '\1'
printf '%b
' '\1'
printf '%b
' '\1'

if [ $FAILED -eq 0 ]; then
    printf '%b
' '\1'
    exit 0
else
    printf '%b
' '\1'
    exit 1
fi
