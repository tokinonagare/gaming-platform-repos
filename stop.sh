#!/usr/bin/env bash

# =================================================================
# 🛑 Gaming Platform 统一停止脚本
# =================================================================

set -e  # 遇到错误立即退出

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# 日志函数
log() {
    echo -e "${BLUE}[$(date +'%H:%M:%S')]${NC} $1"
}

success() {
    echo -e "${GREEN}✅${NC} $1"
}

error() {
    echo -e "${RED}❌${NC} $1"
}

warning() {
    echo -e "${YELLOW}⚠️${NC} $1"
}

info() {
    echo -e "${CYAN}ℹ️${NC} $1"
}

# 显示停止横幅
show_banner() {
    echo -e "${RED}"
    echo "======================================================"
    echo "🛑 Gaming Platform - 停止所有服务"
    echo "======================================================"
    echo -e "${NC}"
}

# 获取默认端口
get_default_port() {
    local service=$1
    case "$service" in
        "gaming-platform-api") echo "9101" ;;
        "gaming-platform-home") echo "9001" ;;
        "gaming-platform-root") echo "9000" ;;
        "gaming-platform-games") echo "9002" ;;
        "gaming-platform-events") echo "9003" ;;
        "gaming-platform-wallet") echo "9004" ;;
        "gaming-platform-profile") echo "9005" ;;
        *) echo "9010" ;;  # 默认端口
    esac
}

# 获取服务名称
get_service_name() {
    local service=$1
    case "$service" in
        "gaming-platform-api") echo "API服务" ;;
        "gaming-platform-home") echo "首页服务" ;;
        "gaming-platform-root") echo "主应用" ;;
        "gaming-platform-games") echo "游戏服务" ;;
        "gaming-platform-events") echo "活动服务" ;;
        "gaming-platform-wallet") echo "钱包服务" ;;
        "gaming-platform-profile") echo "个人中心" ;;
        *) 
            local suffix=${service#gaming-platform-}
            echo "${suffix}服务"
            ;;
    esac
}

# 发现所有服务
discover_services() {
    local services=()
    for dir in ./gaming-platform-*/; do
        if [ -d "$dir" ] && [ -f "$dir/package.json" ]; then
            local dirname=$(basename "$dir")
            services+=("$dirname")
        fi
    done
    echo "${services[@]}"
}

# 检查服务运行状态
check_running_services() {
    log "检查运行中的服务..."
    
    local services=($(discover_services))
    local running_services=()
    
    for service in "${services[@]}"; do
        local port=$(get_default_port "$service")
        local service_name=$(get_service_name "$service")
        
        if lsof -i:$port > /dev/null 2>&1; then
            running_services+=("$service:$port:$service_name")
            info "$service_name 正在运行 (端口: $port)"
        fi
    done
    
    if [ ${#running_services[@]} -eq 0 ]; then
        success "没有发现运行中的服务"
        return 1
    fi
    
    echo "${running_services[@]}"
    return 0
}

# 停止单个服务
stop_service_by_port() {
    local port=$1
    local service_name=$2
    
    log "停止 $service_name (端口: $port)..."
    
    # 获取进程ID
    local pids=$(lsof -ti:$port 2>/dev/null || true)
    
    if [ -z "$pids" ]; then
        warning "$service_name 未运行"
        return 0
    fi
    
    # 优雅停止
    for pid in $pids; do
        if kill -0 $pid 2>/dev/null; then
            log "优雅停止进程 $pid ($service_name)"
            kill -TERM $pid 2>/dev/null || true
        fi
    done
    
    # 等待进程结束
    sleep 3
    
    # 检查是否成功停止
    if ! lsof -i:$port > /dev/null 2>&1; then
        success "$service_name 停止成功"
        return 0
    fi
    
    # 强制停止
    warning "$service_name 需要强制停止"
    for pid in $(lsof -ti:$port 2>/dev/null || true); do
        if kill -0 $pid 2>/dev/null; then
            log "强制停止进程 $pid ($service_name)"
            kill -KILL $pid 2>/dev/null || true
        fi
    done
    
    sleep 1
    
    if ! lsof -i:$port > /dev/null 2>&1; then
        success "$service_name 强制停止成功"
    else
        error "$service_name 停止失败"
        return 1
    fi
}

# 清理进程和端口
cleanup_processes() {
    log "清理相关进程..."
    
    # 查找可能的npm进程
    local npm_pids=$(ps aux | grep -E "npm.*run.*dev" | grep -v grep | awk '{print $2}' || true)
    if [ -n "$npm_pids" ]; then
        for pid in $npm_pids; do
            if kill -0 $pid 2>/dev/null; then
                log "停止npm进程 $pid"
                kill -TERM $pid 2>/dev/null || kill -KILL $pid 2>/dev/null || true
            fi
        done
    fi
    
    # 查找可能的vite进程
    local vite_pids=$(ps aux | grep -E "vite" | grep -v grep | awk '{print $2}' || true)
    if [ -n "$vite_pids" ]; then
        for pid in $vite_pids; do
            if kill -0 $pid 2>/dev/null; then
                log "停止vite进程 $pid"
                kill -TERM $pid 2>/dev/null || kill -KILL $pid 2>/dev/null || true
            fi
        done
    fi
    
    sleep 2
}

# 清理日志文件
cleanup_logs() {
    if [ -d "logs" ]; then
        log "清理日志文件..."
        rm -rf logs/*.log 2>/dev/null || true
        success "日志文件已清理"
    fi
}

# 显示最终状态
show_final_status() {
    echo ""
    echo -e "${CYAN}📊 停止后状态:${NC}"
    echo "----------------------------------------"
    
    local services=($(discover_services))
    local still_running=()
    
    for service in "${services[@]}"; do
        local port=$(get_default_port "$service")
        local service_name=$(get_service_name "$service")
        
        if lsof -i:$port > /dev/null 2>&1; then
            echo -e "${RED}✗${NC} $service_name - 仍在运行 (端口: $port)"
            still_running+=("$service_name")
        else
            echo -e "${GREEN}✓${NC} $service_name - 已停止"
        fi
    done
    
    echo "----------------------------------------"
    
    if [ ${#still_running[@]} -eq 0 ]; then
        echo ""
        success "🎉 所有服务已成功停止！"
    else
        echo ""
        error "以下服务停止失败: ${still_running[*]}"
        info "您可能需要手动停止这些服务"
    fi
}

# 主停止流程
main_stop() {
    show_banner
    
    # 检查运行中的服务
    local running_services
    if ! running_services=($(check_running_services)); then
        echo ""
        success "🎉 没有需要停止的服务"
        exit 0
    fi
    
    echo ""
    log "开始停止所有服务..."
    
    # 停止每个运行中的服务
    local failed_services=()
    for service_info in $running_services; do
        IFS=':' read -r service port service_name <<< "$service_info"
        if ! stop_service_by_port "$port" "$service_name"; then
            failed_services+=("$service_name")
        fi
        echo ""
    done
    
    # 清理进程
    cleanup_processes
    
    # 清理日志 (可选)
    if [[ "${1:-}" == "--clean-logs" ]]; then
        cleanup_logs
    fi
    
    # 显示最终状态
    show_final_status
}

# 强制停止所有
force_stop_all() {
    show_banner
    warning "强制停止模式 - 将停止所有相关进程"
    echo ""
    
    # 停止所有可能的端口
    local ports=(9000 9001 9002 9003 9004 9005 9101 9010 9011 9012)
    
    for port in "${ports[@]}"; do
        if lsof -i:$port > /dev/null 2>&1; then
            warning "强制停止端口 $port 上的进程"
            lsof -ti:$port | xargs kill -9 2>/dev/null || true
        fi
    done
    
    cleanup_processes
    cleanup_logs
    
    success "🎉 强制停止完成"
}

# 显示帮助
show_help() {
    echo "Gaming Platform 停止脚本"
    echo ""
    echo "用法:"
    echo "  $0                    # 优雅停止所有运行中的服务"
    echo "  $0 --force           # 强制停止所有相关进程和端口"
    echo "  $0 --clean-logs      # 停止服务并清理日志文件"
    echo "  $0 --help           # 显示帮助信息"
    echo ""
    echo "这个脚本会自动发现并停止所有 gaming-platform-* 服务："
    echo "  1. 自动发现运行中的服务"
    echo "  2. 优雅停止服务进程 (SIGTERM)"
    echo "  3. 如需要则强制停止 (SIGKILL)"
    echo "  4. 清理相关的npm和vite进程"
    echo ""
    echo "支持的服务端口:"
    echo "  • API服务: 9101"
    echo "  • 首页服务: 9001"
    echo "  • 主应用: 9000"
    echo "  • 游戏服务: 9002"
    echo "  • 活动服务: 9003"
    echo "  • 钱包服务: 9004"
    echo "  • 个人中心: 9005"
    echo ""
}

# 主程序入口
case "${1:-}" in
    "--help"|"-h"|"help")
        show_help
        ;;
    "--force"|"-f")
        force_stop_all
        ;;
    "--clean-logs"|"-c")
        main_stop "--clean-logs"
        ;;
    "")
        main_stop
        ;;
    *)
        echo "错误: 未知参数 '$1'"
        echo ""
        show_help
        exit 1
        ;;
esac