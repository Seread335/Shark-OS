#!/usr/bin/env bash
# Shark OS Container Integration Module
# Manages Podman and container runtime operations

PODMAN_SOCKET="/var/run/podman/podman.sock"
CONTAINERS_DATA_DIR="${CONTAINERS_DATA_DIR:-/var/lib/containers}"
SHARK_REGISTRY_CONFIG="/etc/shark/registries.conf"

# ==============================================
# Container Utilities
# ==============================================

container_check_runtime() {
    if ! command -v podman &>/dev/null; then
        echo "Error: Podman not installed" >&2
        return 1
    fi
    
    if [ ! -S "$PODMAN_SOCKET" ]; then
        echo "Error: Podman socket not available at $PODMAN_SOCKET" >&2
        return 1
    fi
    
    return 0
}

container_list() {
    if ! container_check_runtime; then
        return 1
    fi
    
    podman ps -a --format "table {{.ID}}\t{{.Names}}\t{{.Status}}\t{{.Image}}" 2>/dev/null || {
        echo "No containers available" >&2
        return 1
    }
}

container_stats() {
    if ! container_check_runtime; then
        return 1
    fi
    
    podman stats --no-stream --format "table {{.Container}}\t{{.CPUPercent}}\t{{.MemUsage}}" 2>/dev/null
}

container_pull() {
    local image="$1"
    
    if [ -z "$image" ]; then
        echo "Usage: shark container pull <image>" >&2
        return 1
    fi
    
    if ! container_check_runtime; then
        return 1
    fi
    
    podman pull "$image" 2>&1
}

container_run() {
    local image="$1"
    shift
    local args="$@"
    
    if [ -z "$image" ]; then
        echo "Usage: shark container run <image> [args...]" >&2
        return 1
    fi
    
    if ! container_check_runtime; then
        return 1
    fi
    
    podman run --rm $args "$image" 2>&1
}

container_inspect() {
    local container="$1"
    
    if [ -z "$container" ]; then
        echo "Usage: shark container inspect <id|name>" >&2
        return 1
    fi
    
    if ! container_check_runtime; then
        return 1
    fi
    
    podman inspect "$container" 2>&1 | grep -E '"(Id|Name|State|Config)"' | head -20
}

container_logs() {
    local container="$1"
    
    if [ -z "$container" ]; then
        echo "Usage: shark container logs <id|name>" >&2
        return 1
    fi
    
    if ! container_check_runtime; then
        return 1
    fi
    
    podman logs -f "$container" 2>&1
}

container_stop() {
    local container="$1"
    
    if [ -z "$container" ]; then
        echo "Usage: shark container stop <id|name>" >&2
        return 1
    fi
    
    if ! container_check_runtime; then
        return 1
    fi
    
    podman stop "$container" 2>&1
}

container_remove() {
    local container="$1"
    
    if [ -z "$container" ]; then
        echo "Usage: shark container remove <id|name>" >&2
        return 1
    fi
    
    if ! container_check_runtime; then
        return 1
    fi
    
    podman rm "$container" 2>&1
}

container_prune() {
    if ! container_check_runtime; then
        return 1
    fi
    
    podman container prune -f 2>&1
}

# ==============================================
# Image Management
# ==============================================

image_list() {
    if ! container_check_runtime; then
        return 1
    fi
    
    podman images --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}" 2>/dev/null
}

image_remove() {
    local image="$1"
    
    if [ -z "$image" ]; then
        echo "Usage: shark image remove <image>" >&2
        return 1
    fi
    
    if ! container_check_runtime; then
        return 1
    fi
    
    podman rmi "$image" 2>&1
}

image_build() {
    local dockerfile="$1"
    local tag="$2"
    
    if [ -z "$dockerfile" ] || [ -z "$tag" ]; then
        echo "Usage: shark image build <dockerfile> <tag>" >&2
        return 1
    fi
    
    if ! container_check_runtime; then
        return 1
    fi
    
    podman build -f "$dockerfile" -t "$tag" . 2>&1
}

# ==============================================
# Registry Management
# ==============================================

registry_list() {
    if [ -f "$SHARK_REGISTRY_CONFIG" ]; then
        grep -E '^\[' "$SHARK_REGISTRY_CONFIG" | tr -d '[]'
    else
        echo "No registries configured"
    fi
}

registry_add() {
    local registry="$1"
    
    if [ -z "$registry" ]; then
        echo "Usage: shark registry add <url>" >&2
        return 1
    fi
    
    if ! grep -q "$registry" "$SHARK_REGISTRY_CONFIG" 2>/dev/null; then
        mkdir -p "$(dirname "$SHARK_REGISTRY_CONFIG")"
        echo "[[registry]]" >> "$SHARK_REGISTRY_CONFIG"
        echo "location = \"$registry\"" >> "$SHARK_REGISTRY_CONFIG"
        echo "insecure = false" >> "$SHARK_REGISTRY_CONFIG"
        echo "Successfully added registry: $registry"
    else
        echo "Registry already configured: $registry"
    fi
}

# ==============================================
# Network Management
# ==============================================

network_list() {
    if ! container_check_runtime; then
        return 1
    fi
    
    podman network ls --format "table {{.Name}}\t{{.Driver}}" 2>/dev/null
}

network_create() {
    local name="$1"
    
    if [ -z "$name" ]; then
        echo "Usage: shark network create <name>" >&2
        return 1
    fi
    
    if ! container_check_runtime; then
        return 1
    fi
    
    podman network create "$name" 2>&1
}

network_inspect() {
    local network="$1"
    
    if [ -z "$network" ]; then
        echo "Usage: shark network inspect <name>" >&2
        return 1
    fi
    
    if ! container_check_runtime; then
        return 1
    fi
    
    podman network inspect "$network" 2>&1 | grep -E '"(Name|Driver|Containers)"' | head -10
}

# ==============================================
# Storage Management
# ==============================================

storage_info() {
    if ! container_check_runtime; then
        return 1
    fi
    
    podman system df 2>/dev/null || {
        echo "Unable to retrieve storage information"
        return 1
    }
}

storage_cleanup() {
    if ! container_check_runtime; then
        return 1
    fi
    
    podman system prune -af 2>&1
}

# ==============================================
# Export functions for use in main shark CLI
# ==============================================

export -f container_check_runtime
export -f container_list
export -f container_stats
export -f container_pull
export -f container_run
export -f container_inspect
export -f container_logs
export -f container_stop
export -f container_remove
export -f container_prune
export -f image_list
export -f image_remove
export -f image_build
export -f registry_list
export -f registry_add
export -f network_list
export -f network_create
export -f network_inspect
export -f storage_info
export -f storage_cleanup
