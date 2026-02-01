# Shark CLI - Command Line Interface

Công cụ dòng lệnh để quản lý hệ thống Shark OS.

## Quick Start

```bash
# Make executable
chmod +x shark

# Show version
./shark version

# Show status
./shark status

# Show help
./shark --help
```

## Installation

```bash
# Copy to system path
sudo install shark /usr/local/bin/shark

# Or link
sudo ln -s $(pwd)/shark /usr/local/bin/shark

# Test
shark --version
```

## Commands

```bash
shark status                    # System status
shark config show              # Show configuration
shark config init              # Initialize config
shark update info              # Update information
shark service podman start     # Manage services
shark container list           # List containers
shark kubernetes status        # K8s cluster status
```

See [shark --help](shark) for full documentation.
