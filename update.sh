#!/usr/bin/env bash

# =================================================================
# 🔄 Gaming Platform 依赖更新脚本
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
    exit 1
}

warning() {
    echo -e "${YELLOW}⚠️${NC} $1"
}

info() {
    echo -e "${CYAN}ℹ️${NC} $1"
}

# 显示更新横幅
show_banner() {
    echo -e "${PURPLE}"
    echo "======================================================"
    echo "🔄 Gaming Platform - 依赖更新"
    echo "======================================================"
    echo -e "${NC}"
}

# 自动发现微服务
discover_services() {
    local services=()
    local service_names=()
    
    # 查找所有 gaming-platform-* 目录
    for dir in ./gaming-platform-*/; do
        if [ -d "$dir" ] && [ -f "$dir/package.json" ]; then
            local dirname=$(basename "$dir")
            services+=("$dirname")
            
            # 从目录名推断服务名称
            case "$dirname" in
                "gaming-platform-root")
                    service_names+=("主应用")
                    ;;
                "gaming-platform-api")
                    service_names+=("API服务")
                    ;;
                "gaming-platform-home")
                    service_names+=("首页服务")
                    ;;
                "gaming-platform-games")
                    service_names+=("游戏服务")
                    ;;
                "gaming-platform-events")
                    service_names+=("活动服务")
                    ;;
                "gaming-platform-wallet")
                    service_names+=("钱包服务")
                    ;;
                "gaming-platform-profile")
                    service_names+=("个人中心")
                    ;;
                *)
                    # 从 gaming-platform- 后面提取服务名
                    local service_suffix=${dirname#gaming-platform-}
                    service_names+=("${service_suffix}服务")
                    ;;
            esac
        fi
    done
    
    # 输出发现的服务
    SERVICES=("${services[@]}")
    SERVICE_NAMES=("${service_names[@]}")
    
    # 排序：确保关键服务优先
    local ordered_services=()
    local ordered_names=()
    
    # 优先级排序：api -> root -> 其他服务
    for priority_service in "gaming-platform-api" "gaming-platform-root"; do
        for i in "${!SERVICES[@]}"; do
            if [ "${SERVICES[$i]}" = "$priority_service" ]; then
                ordered_services+=("${SERVICES[$i]}")
                ordered_names+=("${SERVICE_NAMES[$i]}")
                break
            fi
        done
    done
    
    # 添加其他服务
    for i in "${!SERVICES[@]}"; do
        local service="${SERVICES[$i]}"
        if [ "$service" != "gaming-platform-api" ] && [ "$service" != "gaming-platform-root" ]; then
            ordered_services+=("$service")
            ordered_names+=("${SERVICE_NAMES[$i]}")
        fi
    done
    
    SERVICES=("${ordered_services[@]}")
    SERVICE_NAMES=("${ordered_names[@]}")
}

# 显示发现的服务
show_discovered_services() {
    discover_services
    
    if [ ${#SERVICES[@]} -eq 0 ]; then
        error "未发现任何 gaming-platform-* 微服务目录"
    fi
    
    echo "🔍 发现 ${#SERVICES[@]} 个微服务："
    for i in "${!SERVICES[@]}"; do
        echo -e "  ${GREEN}•${NC} ${SERVICES[$i]} (${SERVICE_NAMES[$i]})"
    done
    echo ""
}

# 检查系统依赖
check_dependencies() {
    log "检查系统依赖..."
    
    # 检查 Node.js
    if ! command -v node &> /dev/null; then
        error "Node.js 未安装！请先安装 Node.js (推荐版本: 18+)"
    fi
    
    NODE_VERSION=$(node --version | cut -d'v' -f2 | cut -d'.' -f1)
    if [ "$NODE_VERSION" -lt 16 ]; then
        warning "Node.js 版本过低 ($NODE_VERSION)，推荐使用 16+ 版本"
    fi
    
    # 检查 npm
    if ! command -v npm &> /dev/null; then
        error "npm 未安装！请先安装 npm"
    fi
    
    info "Node.js: $(node --version)"
    info "npm: $(npm --version)"
    echo ""
}

# 备份package-lock.json
backup_lockfile() {
    local service_dir=$1
    local service_name=$2
    
    if [ -f "$service_dir/package-lock.json" ]; then
        log "备份 $service_name 的 package-lock.json"
        cp "$service_dir/package-lock.json" "$service_dir/package-lock.json.backup.$(date +'%Y%m%d_%H%M%S')"
    fi
}

# 清理旧依赖
clean_old_dependencies() {
    local service_dir=$1
    local service_name=$2
    
    log "清理 $service_name 的旧依赖..."
    
    cd "./$service_dir"
    
    # 备份package-lock.json
    if [ -f "package-lock.json" ]; then
        cp "package-lock.json" "package-lock.json.backup.$(date +'%Y%m%d_%H%M%S')"
        info "已备份 package-lock.json"
    fi
    
    # 删除node_modules和package-lock.json
    if [ -d "node_modules" ]; then
        log "删除旧的 node_modules..."
        rm -rf node_modules
    fi
    
    if [ -f "package-lock.json" ]; then
        log "删除旧的 package-lock.json..."
        rm -f package-lock.json
    fi
    
    # 清理npm缓存
    log "清理npm缓存..."
    npm cache clean --force > /dev/null 2>&1 || true
    
    cd - > /dev/null
    success "$service_name 旧依赖清理完成"
}

# 更新单个服务的依赖
update_service() {
    local service_dir=$1
    local service_name=$2
    
    if [ ! -d "./$service_dir" ]; then
        warning "$service_name 目录不存在，跳过更新"
        return 0
    fi
    
    log "更新 $service_name 依赖..."
    
    cd "./$service_dir"
    
    # 检查package.json是否存在
    if [ ! -f "package.json" ]; then
        warning "$service_name 缺少 package.json，跳过更新"
        cd - > /dev/null
        return 0
    fi
    
    # 更新依赖
    log "安装最新依赖..."
    if npm install; then
        success "$service_name 依赖更新完成"
    else
        error "$service_name 依赖更新失败"
    fi
    
    # 检查是否有安全漏洞
    log "检查安全漏洞..."
    if npm audit --audit-level=moderate > /dev/null 2>&1; then
        info "$service_name 没有发现安全问题"
    else
        warning "$service_name 发现安全问题，尝试自动修复..."
        npm audit fix --force > /dev/null 2>&1 || warning "自动修复失败，请手动检查"
    fi
    
    cd - > /dev/null
    echo ""
}

# 检查依赖更新
check_outdated() {
    local service_dir=$1
    local service_name=$2
    
    log "检查 $service_name 的过期依赖..."
    
    cd "./$service_dir"
    
    if npm outdated > /dev/null 2>&1; then
        info "$service_name 所有依赖都是最新版本"
    else
        warning "$service_name 存在过期依赖:"
        npm outdated || true
    fi
    
    cd - > /dev/null
    echo ""
}

# 验证更新结果
verify_update() {
    log "验证更新结果..."
    
    local failed_services=()
    
    for i in "${!SERVICES[@]}"; do
        local service=${SERVICES[$i]}
        local service_name=${SERVICE_NAMES[$i]}
        
        if [ -d "./$service/node_modules" ]; then
            success "$service_name - 依赖已更新"
        else
            warning "$service_name - 依赖更新可能有问题"
            failed_services+=("$service_name")
        fi
    done
    
    if [ ${#failed_services[@]} -eq 0 ]; then
        echo ""
        success "🎉 所有微服务依赖更新完成！"
    else
        echo ""
        error "以下服务更新失败: ${failed_services[*]}"
    fi
}

# 显示更新摘要
show_update_summary() {
    echo ""
    echo -e "${CYAN}📋 更新摘要:${NC}"
    echo "----------------------------------------"
    
    for i in "${!SERVICES[@]}"; do
        local service=${SERVICES[$i]}
        local service_name=${SERVICE_NAMES[$i]}
        
        if [ -d "./$service" ] && [ -f "./$service/package.json" ]; then
            cd "./$service"
            local package_count=$(npm list --depth=0 2>/dev/null | grep -c "├─\|└─" || echo "未知")
            echo -e "${GREEN}✓${NC} $service_name - $package_count 个依赖包"
            cd - > /dev/null
        fi
    done
    
    echo "----------------------------------------"
}

# 主更新流程
main_update() {
    show_banner
    show_discovered_services
    
    # 检查系统依赖
    check_dependencies
    
    # 询问确认
    if [[ "${1:-}" != "--yes" ]] && [[ "${1:-}" != "-y" ]]; then
        echo -e "${YELLOW}⚠️ 警告: 此操作将删除所有 node_modules 和 package-lock.json 文件${NC}"
        echo -e "${YELLOW}   并重新安装最新版本的依赖包。${NC}"
        echo ""
        read -p "确定要继续吗? (y/N): " -n 1 -r
        echo
        
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            info "操作已取消"
            exit 0
        fi
        echo ""
    fi
    
    # 更新各个微服务的依赖
    for i in "${!SERVICES[@]}"; do
        clean_old_dependencies "${SERVICES[$i]}" "${SERVICE_NAMES[$i]}"
        update_service "${SERVICES[$i]}" "${SERVICE_NAMES[$i]}"
    done
    
    # 验证更新结果
    verify_update
    
    # 显示更新摘要
    show_update_summary
    
    # 显示后续步骤
    echo ""
    echo -e "${CYAN}🚀 后续步骤:${NC}"
    echo "1. 启动所有服务: ${GREEN}./start.sh${NC}"
    echo "2. 检查应用功能: ${GREEN}http://localhost:9000${NC}"
    echo "3. 如有问题，可查看日志文件进行排查"
}

# 只检查过期依赖
check_only() {
    show_banner
    show_discovered_services
    
    log "检查所有服务的过期依赖..."
    echo ""
    
    for i in "${!SERVICES[@]}"; do
        check_outdated "${SERVICES[$i]}" "${SERVICE_NAMES[$i]}"
    done
    
    info "检查完成，使用 ${GREEN}./update.sh${NC} 进行更新"
}

# 显示帮助
show_help() {
    echo "Gaming Platform 依赖更新脚本"
    echo ""
    echo "用法:"
    echo "  $0                    # 交互式更新所有微服务依赖"
    echo "  $0 --yes             # 自动确认并更新所有依赖"
    echo "  $0 --check           # 只检查过期依赖，不执行更新"
    echo "  $0 --help            # 显示帮助信息"
    echo ""
    echo "这个脚本会："
    echo "  1. 自动发现所有 gaming-platform-* 微服务"
    echo "  2. 备份现有的 package-lock.json 文件"
    echo "  3. 清理旧的 node_modules 和 package-lock.json"
    echo "  4. 清理 npm 缓存"
    echo "  5. 重新安装最新版本的依赖"
    echo "  6. 检查并修复安全漏洞"
    echo "  7. 验证更新结果"
    echo ""
    echo "注意事项："
    echo "  • 更新前会自动备份 package-lock.json"
    echo "  • 建议在更新前停止所有服务"
    echo "  • 更新完成后需要重新启动服务"
    echo ""
}

# 主程序入口
case "${1:-}" in
    "--help"|"-h"|"help")
        show_help
        ;;
    "--check"|"-c")
        check_only
        ;;
    "--yes"|"-y")
        main_update "--yes"
        ;;
    "")
        main_update
        ;;
    *)
        echo "错误: 未知参数 '$1'"
        echo ""
        show_help
        exit 1
        ;;
esac