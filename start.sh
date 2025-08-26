#!/usr/bin/env bash

# =================================================================
# 🚀 Gaming Platform 统一启动脚本 (简化版，兼容性更强)
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

# 存储进程ID和名称
PIDS=()
SERVICE_NAMES=()

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

# 显示启动横幅
show_banner() {
    echo -e "${PURPLE}"
    echo "======================================================"
    echo "🚀 Gaming Platform - 微前端启动"
    echo "======================================================"
    echo -e "${NC}"
    
    # 自动发现服务
    local services=()
    for dir in ./gaming-platform-*/; do
        if [ -d "$dir" ] && [ -f "$dir/package.json" ]; then
            local dirname=$(basename "$dir")
            services+=("$dirname")
        fi
    done
    
    if [ ${#services[@]} -eq 0 ]; then
        error "未发现任何 gaming-platform-* 微服务目录"
        echo ""
        info "请确保在正确的目录中运行脚本，目录下应包含 gaming-platform-* 文件夹"
        exit 1
    fi
    
    echo "🔍 发现 ${#services[@]} 个微服务："
    for service in "${services[@]}"; do
        local port=$(get_default_port "$service")
        local service_name=$(get_service_name "$service")
        echo -e "  ${GREEN}•${NC} $service (${service_name}, 端口: $port)"
    done
    echo ""
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

# 检查依赖是否安装
check_dependencies() {
    log "检查微服务依赖..."
    
    local missing_deps=()
    
    for dir in ./gaming-platform-*/; do
        if [ -d "$dir" ] && [ -f "$dir/package.json" ]; then
            local dirname=$(basename "$dir")
            if [ ! -d "$dir/node_modules" ]; then
                missing_deps+=("$dirname")
            fi
        fi
    done
    
    if [ ${#missing_deps[@]} -gt 0 ]; then
        error "以下服务依赖未安装:"
        for dep in "${missing_deps[@]}"; do
            echo -e "  ${RED}•${NC} $dep"
        done
        echo ""
        info "请先运行: ${GREEN}./install.sh${NC}"
        exit 1
    fi
    
    success "所有依赖检查通过"
}

# 清理端口占用
cleanup_ports() {
    log "检查并清理端口占用..."
    
    local ports_cleaned=()
    
    for dir in ./gaming-platform-*/; do
        if [ -d "$dir" ] && [ -f "$dir/package.json" ]; then
            local dirname=$(basename "$dir")
            local port=$(get_default_port "$dirname")
            local service_name=$(get_service_name "$dirname")
            
            if lsof -i:$port > /dev/null 2>&1; then
                warning "清理端口 $port ($service_name)"
                lsof -ti:$port | xargs kill -9 2>/dev/null || true
                ports_cleaned+=("$port")
                sleep 1
            fi
        fi
    done
    
    if [ ${#ports_cleaned[@]} -gt 0 ]; then
        success "清理了端口: ${ports_cleaned[*]}"
    else
        info "所有端口都可用"
    fi
}

# 启动单个服务
start_service() {
    local service_dir=$1
    local port=$(get_default_port "$service_dir")
    local service_name=$(get_service_name "$service_dir")
    
    log "启动 $service_name (端口: $port)..."
    
    # 进入服务目录并启动
    cd "./$service_dir"
    
    # 后台启动 npm run dev
    npm run dev > "../logs/${service_dir}.log" 2>&1 &
    local pid=$!
    
    # 存储进程信息
    PIDS+=($pid)
    SERVICE_NAMES+=("$service_name")
    
    cd - > /dev/null
    
    # 等待服务启动
    local attempts=0
    local max_attempts=30
    
    while [ $attempts -lt $max_attempts ]; do
        if lsof -i:$port > /dev/null 2>&1; then
            success "$service_name 启动成功 (PID: $pid, 端口: $port)"
            return 0
        fi
        
        sleep 1
        attempts=$((attempts + 1))
    done
    
    error "$service_name 启动超时"
    return 1
}

# 获取启动顺序
get_start_order() {
    local ordered_services=()
    
    # 优先启动顺序：api -> root -> 其他
    for priority in "gaming-platform-api" "gaming-platform-root"; do
        if [ -d "./$priority" ]; then
            ordered_services+=("$priority")
        fi
    done
    
    # 添加其他服务
    for dir in ./gaming-platform-*/; do
        if [ -d "$dir" ] && [ -f "$dir/package.json" ]; then
            local dirname=$(basename "$dir")
            if [ "$dirname" != "gaming-platform-api" ] && [ "$dirname" != "gaming-platform-root" ]; then
                ordered_services+=("$dirname")
            fi
        fi
    done
    
    echo "${ordered_services[@]}"
}

# 显示服务状态
show_status() {
    echo ""
    echo -e "${CYAN}📊 服务状态:${NC}"
    echo "----------------------------------------"
    
    for dir in ./gaming-platform-*/; do
        if [ -d "$dir" ] && [ -f "$dir/package.json" ]; then
            local dirname=$(basename "$dir")
            local port=$(get_default_port "$dirname")
            local service_name=$(get_service_name "$dirname")
            
            if lsof -i:$port > /dev/null 2>&1; then
                echo -e "${GREEN}✓${NC} $service_name - http://localhost:$port"
            else
                echo -e "${RED}✗${NC} $service_name - 未运行"
            fi
        fi
    done
    
    echo "----------------------------------------"
}

# 显示访问信息
show_access_info() {
    echo ""
    echo -e "${GREEN}🎉 所有服务启动完成！${NC}"
    echo ""
    
    # 找到主应用端口
    local main_port="9000"
    if [ -d "./gaming-platform-root" ]; then
        main_port=$(get_default_port "gaming-platform-root")
    fi
    
    echo -e "${CYAN}🌐 访问地址:${NC}"
    echo -e "  主应用: ${GREEN}http://localhost:$main_port${NC}"
    echo ""
    echo -e "${CYAN}⚙️ 所有服务:${NC}"
    for dir in ./gaming-platform-*/; do
        if [ -d "$dir" ] && [ -f "$dir/package.json" ]; then
            local dirname=$(basename "$dir")
            local port=$(get_default_port "$dirname")
            local service_name=$(get_service_name "$dirname")
            echo -e "  • ${service_name}: http://localhost:$port"
        fi
    done
    echo ""
    echo -e "${CYAN}🛑 停止服务:${NC}"
    echo -e "  按 ${YELLOW}Ctrl+C${NC} 停止所有服务"
    echo ""
}

# 清理函数
cleanup() {
    echo ""
    log "正在停止所有服务..."
    
    # 停止所有后台进程
    for i in "${!PIDS[@]}"; do
        local pid=${PIDS[$i]}
        local service_name=${SERVICE_NAMES[$i]}
        
        if kill -0 $pid 2>/dev/null; then
            log "停止 $service_name (PID: $pid)"
            kill -TERM $pid 2>/dev/null || kill -KILL $pid 2>/dev/null
        fi
    done
    
    # 等待进程结束
    sleep 2
    
    # 强制清理端口
    for dir in ./gaming-platform-*/; do
        if [ -d "$dir" ] && [ -f "$dir/package.json" ]; then
            local dirname=$(basename "$dir")
            local port=$(get_default_port "$dirname")
            lsof -ti:$port | xargs kill -9 2>/dev/null || true
        fi
    done
    
    success "所有服务已停止"
    exit 0
}

# 创建日志目录
create_log_dir() {
    if [ ! -d "logs" ]; then
        mkdir -p logs
    fi
}

# 主启动流程
main_start() {
    show_banner
    
    # 检查依赖
    check_dependencies
    
    # 清理端口
    cleanup_ports
    
    # 创建日志目录
    create_log_dir
    
    echo ""
    log "开始启动微服务..."
    
    # 获取启动顺序并逐个启动
    local services=($(get_start_order))
    for service_dir in "${services[@]}"; do
        if ! start_service "$service_dir"; then
            error "服务启动失败，退出"
            cleanup
            exit 1
        fi
        echo ""
    done
    
    # 显示状态和访问信息
    show_status
    show_access_info
    
    # 设置信号处理
    trap cleanup SIGINT SIGTERM
    
    # 保持脚本运行并监控服务
    log "服务监控中... (按 Ctrl+C 退出)"
    
    while true; do
        sleep 5
        
        # 检查服务是否还在运行
        local failed_services=()
        for i in "${!PIDS[@]}"; do
            local pid=${PIDS[$i]}
            local service_name=${SERVICE_NAMES[$i]}
            
            if ! kill -0 $pid 2>/dev/null; then
                failed_services+=("$service_name")
            fi
        done
        
        if [ ${#failed_services[@]} -gt 0 ]; then
            error "以下服务意外停止: ${failed_services[*]}"
            cleanup
            exit 1
        fi
    done
}

# 显示帮助
show_help() {
    echo "Gaming Platform 启动脚本 (简化版)"
    echo ""
    echo "用法:"
    echo "  $0           # 启动所有微服务"
    echo "  $0 --help   # 显示帮助信息"
    echo ""
    echo "这个脚本会自动发现所有 gaming-platform-* 目录并启动相应服务："
    echo "  1. 检查依赖是否安装"
    echo "  2. 清理可能的端口占用"
    echo "  3. 按顺序启动所有微服务"
    echo "  4. 监控服务运行状态"
    echo ""
    echo "默认端口分配："
    echo "  • API服务: 9101"
    echo "  • 首页服务: 9001"
    echo "  • 主应用: 9000"
    echo "  • 游戏服务: 9002"
    echo "  • 活动服务: 9003"
    echo "  • 钱包服务: 9004"
    echo "  • 个人中心: 9005"
    echo ""
    echo "访问地址: http://localhost:9000"
    echo ""
}

# 主程序入口
case "${1:-}" in
    "--help"|"-h"|"help")
        show_help
        ;;
    "")
        main_start
        ;;
    *)
        echo "错误: 未知参数 '$1'"
        echo ""
        show_help
        exit 1
        ;;
esac