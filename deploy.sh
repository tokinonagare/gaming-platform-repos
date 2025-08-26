#!/bin/bash

# =================================================================
# 🚀 Gaming Platform 生产环境部署脚本
# =================================================================

set -e  # 遇到错误立即退出

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 配置变量
DEPLOY_DIR="/var/www"
BACKUP_DIR="/var/backups/gaming-platform"
LOG_FILE="/var/log/gaming-platform-deploy.log"

# 仓库配置
REPOS=(
    "gaming-platform-root"
    "gaming-platform-api" 
    "gaming-platform-home"
    # "gaming-platform-games"    # 如果有的话
    # "gaming-platform-events"   # 如果有的话
    # "gaming-platform-wallet"   # 如果有的话
    # "gaming-platform-profile"  # 如果有的话
)

# 日志函数
log() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1" | tee -a "$LOG_FILE"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1" | tee -a "$LOG_FILE"
    exit 1
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1" | tee -a "$LOG_FILE"
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1" | tee -a "$LOG_FILE"
}

# 检查依赖
check_dependencies() {
    log "检查系统依赖..."
    
    # 检查 Node.js
    if ! command -v node &> /dev/null; then
        error "Node.js 未安装，请先安装 Node.js"
    fi
    
    # 检查 npm
    if ! command -v npm &> /dev/null; then
        error "npm 未安装，请先安装 npm"
    fi
    
    # 检查 nginx
    if ! command -v nginx &> /dev/null; then
        warning "Nginx 未安装，请确保已安装并配置 Nginx"
    fi
    
    success "系统依赖检查完成"
}

# 创建备份
create_backup() {
    log "创建备份..."
    
    mkdir -p "$BACKUP_DIR/$(date +'%Y%m%d_%H%M%S')"
    
    for repo in "${REPOS[@]}"; do
        if [ -d "$DEPLOY_DIR/$repo" ]; then
            cp -r "$DEPLOY_DIR/$repo" "$BACKUP_DIR/$(date +'%Y%m%d_%H%M%S')/"
            log "备份 $repo 完成"
        fi
    done
    
    success "备份创建完成"
}

# 构建单个微服务
build_service() {
    local service_name=$1
    local service_dir=$2
    
    log "构建 $service_name..."
    
    if [ ! -d "$service_dir" ]; then
        error "$service_name 目录不存在: $service_dir"
    fi
    
    cd "$service_dir"
    
    # 安装依赖
    log "安装 $service_name 依赖..."
    npm ci --production=false
    
    # 构建
    log "构建 $service_name..."
    npm run build
    
    if [ ! -d "dist" ]; then
        error "$service_name 构建失败，dist 目录不存在"
    fi
    
    success "$service_name 构建完成"
}

# 部署单个微服务
deploy_service() {
    local service_name=$1
    local service_dir=$2
    local deploy_path="$DEPLOY_DIR/$service_name"
    
    log "部署 $service_name..."
    
    # 创建部署目录
    mkdir -p "$deploy_path"
    
    # 复制构建产物
    if [ "$service_name" = "gaming-platform-root" ]; then
        # 主应用部署到根目录
        cp -r "$service_dir/dist/"* "$DEPLOY_DIR/gaming-platform/"
    else
        # 微服务部署到对应目录
        cp -r "$service_dir/dist/"* "$deploy_path/"
    fi
    
    # 设置权限
    chown -R www-data:www-data "$deploy_path" 2>/dev/null || log "无法设置权限，请手动设置"
    
    success "$service_name 部署完成"
}

# 主部署流程
main_deploy() {
    log "开始部署 Gaming Platform..."
    
    # 检查依赖
    check_dependencies
    
    # 创建备份
    create_backup
    
    # 创建基础目录
    mkdir -p "$DEPLOY_DIR/gaming-platform"
    
    # 构建和部署每个服务
    for repo in "${REPOS[@]}"; do
        if [ -d "./$repo" ]; then
            build_service "$repo" "./$repo"
            deploy_service "$repo" "./$repo"
        else
            warning "$repo 目录不存在，跳过"
        fi
    done
    
    # 部署 Nginx 配置
    deploy_nginx_config
    
    # 测试部署
    test_deployment
    
    success "🎉 Gaming Platform 部署完成!"
}

# 部署 Nginx 配置
deploy_nginx_config() {
    log "部署 Nginx 配置..."
    
    if [ -f "./nginx.conf" ]; then
        # 备份现有配置
        if [ -f "/etc/nginx/sites-available/gaming-platform" ]; then
            cp "/etc/nginx/sites-available/gaming-platform" "/etc/nginx/sites-available/gaming-platform.backup.$(date +'%Y%m%d_%H%M%S')"
        fi
        
        # 复制新配置
        cp "./nginx.conf" "/etc/nginx/sites-available/gaming-platform"
        
        # 启用站点
        ln -sf "/etc/nginx/sites-available/gaming-platform" "/etc/nginx/sites-enabled/"
        
        # 测试 Nginx 配置
        if nginx -t; then
            systemctl reload nginx
            success "Nginx 配置部署完成"
        else
            error "Nginx 配置有误，请检查"
        fi
    else
        warning "nginx.conf 文件不存在，跳过 Nginx 配置"
    fi
}

# 测试部署
test_deployment() {
    log "测试部署..."
    
    # 检查主应用
    if [ -f "$DEPLOY_DIR/gaming-platform/index.html" ]; then
        success "主应用文件存在"
    else
        error "主应用文件不存在"
    fi
    
    # 检查微服务
    for repo in "${REPOS[@]}"; do
        if [[ "$repo" != "gaming-platform-root" ]]; then
            service_file="$DEPLOY_DIR/$repo/services.js"
            if [[ "$repo" = "gaming-platform-home" ]]; then
                service_file="$DEPLOY_DIR/$repo/home.js"
            fi
            
            if [ -f "$service_file" ]; then
                success "$repo 服务文件存在"
            else
                warning "$repo 服务文件不存在"
            fi
        fi
    done
}

# 回滚函数
rollback() {
    local backup_timestamp=$1
    
    if [ -z "$backup_timestamp" ]; then
        echo "可用的备份："
        ls -la "$BACKUP_DIR/"
        exit 1
    fi
    
    log "回滚到备份: $backup_timestamp"
    
    backup_path="$BACKUP_DIR/$backup_timestamp"
    
    if [ ! -d "$backup_path" ]; then
        error "备份不存在: $backup_path"
    fi
    
    for repo in "${REPOS[@]}"; do
        if [ -d "$backup_path/$repo" ]; then
            cp -r "$backup_path/$repo/"* "$DEPLOY_DIR/$repo/"
            log "回滚 $repo 完成"
        fi
    done
    
    systemctl reload nginx
    success "回滚完成"
}

# 清理旧备份
cleanup_old_backups() {
    log "清理超过 30 天的备份..."
    find "$BACKUP_DIR" -type d -mtime +30 -exec rm -rf {} +
    success "清理完成"
}

# 显示帮助
show_help() {
    echo "Gaming Platform 部署脚本"
    echo ""
    echo "用法:"
    echo "  $0 deploy                    # 完整部署"
    echo "  $0 rollback [TIMESTAMP]      # 回滚到指定备份"
    echo "  $0 cleanup                   # 清理旧备份"
    echo "  $0 help                      # 显示帮助"
    echo ""
    echo "示例:"
    echo "  $0 deploy"
    echo "  $0 rollback 20241201_143022"
    echo ""
}

# 主程序
case "${1:-}" in
    "deploy")
        main_deploy
        ;;
    "rollback")
        rollback "$2"
        ;;
    "cleanup")
        cleanup_old_backups
        ;;
    "help"|"--help"|"-h")
        show_help
        ;;
    *)
        echo "错误: 未知命令 '${1:-}'"
        echo ""
        show_help
        exit 1
        ;;
esac