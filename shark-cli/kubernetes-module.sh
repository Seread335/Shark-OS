#!/usr/bin/env bash
# Shark OS Kubernetes Integration Module
# Manages K3s and Kubernetes operations

K3S_CONFIG_DIR="/etc/kubernetes"
K3S_DATA_DIR="/var/lib/k3s"
K3S_LOG_FILE="/var/log/kubernetes/k3s.log"
KUBECONFIG="${KUBECONFIG:-/etc/kubernetes/kubeconfig.yaml}"

# ==============================================
# K3s Cluster Management
# ==============================================

k3s_check_status() {
    if ! command -v k3s &>/dev/null; then
        echo "Error: K3s not installed" >&2
        return 1
    fi
    
    if ! systemctl is-active --quiet k3s 2>/dev/null; then
        echo "K3s service is not running"
        return 1
    fi
    
    return 0
}

k3s_start() {
    echo "Starting K3s cluster..."
    
    if ! systemctl start k3s 2>&1; then
        echo "Failed to start K3s" >&2
        return 1
    fi
    
    # Wait for cluster to be ready
    local max_retries=30
    local retry=0
    
    while [ $retry -lt $max_retries ]; do
        if kubectl cluster-info &>/dev/null; then
            echo "K3s cluster is ready"
            return 0
        fi
        
        sleep 1
        retry=$((retry + 1))
    done
    
    echo "K3s cluster failed to start" >&2
    return 1
}

k3s_stop() {
    echo "Stopping K3s cluster..."
    
    if ! systemctl stop k3s 2>&1; then
        echo "Failed to stop K3s" >&2
        return 1
    fi
    
    echo "K3s cluster stopped"
    return 0
}

k3s_restart() {
    k3s_stop && k3s_start
}

k3s_status() {
    if k3s_check_status; then
        echo "K3s Status: Running"
    else
        echo "K3s Status: Stopped"
        return 1
    fi
    
    # Show nodes
    echo ""
    echo "Nodes:"
    kubectl get nodes 2>/dev/null || echo "  Unable to retrieve nodes"
    
    # Show cluster info
    echo ""
    echo "Cluster Info:"
    kubectl cluster-info 2>/dev/null | head -5 || echo "  Cluster information unavailable"
}

# ==============================================
# Kubernetes Node Management
# ==============================================

node_list() {
    if ! k3s_check_status; then
        return 1
    fi
    
    kubectl get nodes -o wide 2>/dev/null || {
        echo "Unable to list nodes" >&2
        return 1
    }
}

node_status() {
    local node="$1"
    
    if [ -z "$node" ]; then
        echo "Usage: shark kubernetes node <name>" >&2
        return 1
    fi
    
    if ! k3s_check_status; then
        return 1
    fi
    
    kubectl describe node "$node" 2>/dev/null || {
        echo "Node not found: $node" >&2
        return 1
    }
}

node_drain() {
    local node="$1"
    
    if [ -z "$node" ]; then
        echo "Usage: shark kubernetes drain <node>" >&2
        return 1
    fi
    
    if ! k3s_check_status; then
        return 1
    fi
    
    echo "Draining node: $node"
    kubectl drain "$node" --ignore-daemonsets --delete-emptydir-data 2>&1
}

# ==============================================
# Pod Management
# ==============================================

pod_list() {
    local namespace="${1:-all}"
    
    if ! k3s_check_status; then
        return 1
    fi
    
    if [ "$namespace" = "all" ]; then
        kubectl get pods -A -o wide 2>/dev/null
    else
        kubectl get pods -n "$namespace" -o wide 2>/dev/null
    fi
}

pod_logs() {
    local pod="$1"
    local namespace="${2:-default}"
    
    if [ -z "$pod" ]; then
        echo "Usage: shark kubernetes logs <pod> [namespace]" >&2
        return 1
    fi
    
    if ! k3s_check_status; then
        return 1
    fi
    
    kubectl logs -n "$namespace" "$pod" -f 2>&1
}

pod_exec() {
    local pod="$1"
    local namespace="${2:-default}"
    shift 2
    local -a cmd=("$@")
    
    if [ -z "$pod" ] || [ ${#cmd[@]} -eq 0 ]; then
        echo "Usage: shark kubernetes exec <pod> [namespace] <command...>" >&2
        return 1
    fi
    
    if ! k3s_check_status; then
        return 1
    fi
    
    kubectl exec -n "$namespace" -it "$pod" -- "${cmd[@]}" 2>&1
}

pod_delete() {
    local pod="$1"
    local namespace="${2:-default}"
    
    if [ -z "$pod" ]; then
        echo "Usage: shark kubernetes delete <pod> [namespace]" >&2
        return 1
    fi
    
    if ! k3s_check_status; then
        return 1
    fi
    
    kubectl delete pod -n "$namespace" "$pod" 2>&1
}

# ==============================================
# Deployment Management
# ==============================================

deployment_list() {
    local namespace="${1:-all}"
    
    if ! k3s_check_status; then
        return 1
    fi
    
    if [ "$namespace" = "all" ]; then
        kubectl get deployments -A 2>/dev/null
    else
        kubectl get deployments -n "$namespace" 2>/dev/null
    fi
}

deployment_scale() {
    local deployment="$1"
    local replicas="$2"
    local namespace="${3:-default}"
    
    if [ -z "$deployment" ] || [ -z "$replicas" ]; then
        echo "Usage: shark kubernetes scale <deployment> <replicas> [namespace]" >&2
        return 1
    fi
    
    if ! k3s_check_status; then
        return 1
    fi
    
    kubectl scale deployment -n "$namespace" "$deployment" --replicas="$replicas" 2>&1
}

# ==============================================
# Service Management
# ==============================================

service_list() {
    local namespace="${1:-all}"
    
    if ! k3s_check_status; then
        return 1
    fi
    
    if [ "$namespace" = "all" ]; then
        kubectl get svc -A 2>/dev/null
    else
        kubectl get svc -n "$namespace" 2>/dev/null
    fi
}

service_info() {
    local service="$1"
    local namespace="${2:-default}"
    
    if [ -z "$service" ]; then
        echo "Usage: shark kubernetes svc <name> [namespace]" >&2
        return 1
    fi
    
    if ! k3s_check_status; then
        return 1
    fi
    
    kubectl get svc -n "$namespace" "$service" -o wide 2>/dev/null
}

# ==============================================
# Namespace Management
# ==============================================

namespace_list() {
    if ! k3s_check_status; then
        return 1
    fi
    
    kubectl get namespaces 2>/dev/null
}

namespace_create() {
    local namespace="$1"
    
    if [ -z "$namespace" ]; then
        echo "Usage: shark kubernetes namespace <name>" >&2
        return 1
    fi
    
    if ! k3s_check_status; then
        return 1
    fi
    
    kubectl create namespace "$namespace" 2>&1
}

# ==============================================
# Cluster Information
# ==============================================

cluster_info() {
    if ! k3s_check_status; then
        echo "K3s cluster is not running" >&2
        return 1
    fi
    
    echo "=== Cluster Information ==="
    kubectl cluster-info 2>/dev/null
    
    echo ""
    echo "=== Nodes ==="
    kubectl get nodes -o wide 2>/dev/null | head -10
    
    echo ""
    echo "=== System Pods ==="
    kubectl get pods -n kube-system 2>/dev/null | head -15
    
    echo ""
    echo "=== Available Resources ==="
    kubectl top nodes 2>/dev/null || echo "Metrics not available"
}

# ==============================================
# Config & Context Management
# ==============================================

config_get_context() {
    kubectl config current-context 2>/dev/null
}

config_use_context() {
    local context="$1"
    
    if [ -z "$context" ]; then
        echo "Usage: shark kubernetes use-context <name>" >&2
        return 1
    fi
    
    kubectl config use-context "$context" 2>&1
}

config_list_contexts() {
    kubectl config get-contexts 2>/dev/null
}

# ==============================================
# Export functions for use in main shark CLI
# ==============================================

export -f k3s_check_status
export -f k3s_start
export -f k3s_stop
export -f k3s_restart
export -f k3s_status
export -f node_list
export -f node_status
export -f node_drain
export -f pod_list
export -f pod_logs
export -f pod_exec
export -f pod_delete
export -f deployment_list
export -f deployment_scale
export -f service_list
export -f service_info
export -f namespace_list
export -f namespace_create
export -f cluster_info
export -f config_get_context
export -f config_use_context
export -f config_list_contexts
