#!/usr/bin/env bash

# =================================================================
# 🛠️ Gaming Platform 统一安装脚本
# =================================================================

set -e  # 遇到错误立即退出

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

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

# 显示横幅
show_banner() {
    echo -e "${CYAN}"
    echo "======================================================"
    echo "🎮 Gaming Platform - 微前端架构"
    echo "======================================================"
    echo -e "${NC}"
    
    # 自动发现服务
    discover_services
    
    echo "📦 发现 ${#SERVICES[@]} 个微服务："
    for i in "${!SERVICES[@]}"; do
        echo -e "  ${GREEN}•${NC} ${SERVICES[$i]} (${SERVICE_NAMES[$i]})"
    done
    echo ""
    echo "正在安装所有微服务的依赖..."
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

# 安装单个服务的依赖
install_service() {
    local service_dir=$1
    local service_name=$2
    
    if [ ! -d "./$service_dir" ]; then
        warning "$service_name 目录不存在，跳过安装"
        return 0
    fi
    
    log "安装 $service_name 依赖..."
    
    cd "./$service_dir"
    
    # 清理可能存在的问题
    if [ -f "package-lock.json" ]; then
        rm -f package-lock.json
    fi
    
    if [ -d "node_modules" ]; then
        rm -rf node_modules
    fi
    
    # 安装依赖
    npm install
    
    if [ $? -eq 0 ]; then
        success "$service_name 依赖安装完成"
    else
        error "$service_name 依赖安装失败"
    fi
    
    cd - > /dev/null
    echo ""
}

# 验证安装
verify_installation() {
    log "验证安装结果..."
    
    local failed_services=()
    
    for i in "${!SERVICES[@]}"; do
        local service=${SERVICES[$i]}
        local service_name=${SERVICE_NAMES[$i]}
        
        if [ -d "./$service/node_modules" ]; then
            success "$service_name - 依赖已安装"
        else
            warning "$service_name - 依赖安装可能有问题"
            failed_services+=("$service_name")
        fi
    done
    
    if [ ${#failed_services[@]} -eq 0 ]; then
        echo ""
        success "🎉 所有微服务依赖安装完成！"
        info "现在可以运行 ${CYAN}./start.sh${NC} 启动所有服务"
    else
        echo ""
        error "以下服务安装失败: ${failed_services[*]}"
    fi
}

# 显示使用说明
show_usage() {
    echo -e "${CYAN}📋 后续步骤:${NC}"
    echo "1. 启动所有服务: ${GREEN}./start.sh${NC}"
    echo "2. 访问应用: ${GREEN}http://localhost:9000${NC}"
    echo "3. 停止服务: ${GREEN}Ctrl+C${NC}"
    echo ""
    echo -e "${CYAN}📖 服务端口:${NC}"
    echo "- 主应用 (Root): http://localhost:9000"
    echo "- 首页服务 (Home): http://localhost:9001"  
    echo "- API服务 (API): http://localhost:9101"
    echo ""
    echo -e "${CYAN}🛠️ 其他命令:${NC}"
    echo "- 部署到生产: ${GREEN}./deploy.sh deploy${NC}"
    echo "- 查看迁移指导: ${GREEN}cat MIGRATION_GUIDE.md${NC}"
}

# 主安装流程
main_install() {
    show_banner
    
    # 检查是否发现了任何服务
    if [ ${#SERVICES[@]} -eq 0 ]; then
        error "未发现任何 gaming-platform-* 微服务目录"
        echo ""
        info "请确保在正确的目录中运行脚本，目录下应包含 gaming-platform-* 文件夹"
        exit 1
    fi
    
    # 检查系统依赖
    check_dependencies
    
    # 安装各个微服务的依赖
    for i in "${!SERVICES[@]}"; do
        install_service "${SERVICES[$i]}" "${SERVICE_NAMES[$i]}"
    done
    
    # 验证安装结果
    verify_installation
    
    echo ""
    show_usage
}

# 显示帮助信息
show_help() {
    echo "Gaming Platform 安装脚本"
    echo ""
    echo "用法:"
    echo "  $0                # 安装所有微服务依赖"
    echo "  $0 --help        # 显示帮助信息"
    echo ""
    echo "这个脚本会："
    echo "  1. 检查系统依赖 (Node.js, npm)"
    echo "  2. 安装 API 服务依赖"
    echo "  3. 安装 Home 服务依赖"
    echo "  4. 安装 Root 应用依赖"
    echo "  5. 验证安装结果"
    echo ""
}

# 主程序入口
case "${1:-}" in
    "--help"|"-h"|"help")
        show_help
        ;;
    "")
        main_install
        ;;
    *)
        echo "错误: 未知参数 '$1'"
        echo ""
        show_help
        exit 1
        ;;
esac