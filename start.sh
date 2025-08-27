#!/bin/bash

# =================================================================
# 🚀 Gaming Platform - Module Federation架构启动脚本
# =================================================================

# 帮助信息
show_help() {
    echo "Gaming Platform 启动脚本"
    echo ""
    echo "用法:"
    echo "  ./start.sh              # 交互式启动，包含进度显示和信号处理"
    echo "  ./start.sh --simple     # 简单并行启动"
    echo "  ./start.sh --help       # 显示帮助信息"
    echo ""
    echo "端口分配:"
    echo "  Container (容器): 端口 3000 - http://localhost:3000"
    echo "  Home (首页): 端口 3001 - http://localhost:3001"  
    echo "  Game (游戏库): 端口 3002 - http://localhost:3002"
    echo "  API (后端): 端口 3101 - http://localhost:3101"
}

# 简单启动模式
simple_start() {
    echo "🚀 启动Gaming Platform所有服务..."
    
    # 并行启动所有服务
    echo "📡 启动API服务..."
    (cd gaming-platform-api && npm run dev) &
    
    echo "🏠 启动Home应用..."
    (cd gaming-platform-home && npm run build && npm run preview) &
    
    echo "🎮 启动Game应用..."  
    (cd gaming-platform-game && npm run build && npm run preview) &
    
    echo "🌐 启动Container应用..."
    (cd gaming-platform-container && npm run build && npm run preview) &
    
    wait
}

# 交互式启动模式
interactive_start() {
    echo "🚀 启动Gaming Platform所有服务..."
    echo "Container (微前端容器): 端口 3000"
    echo "Home (首页微应用): 端口 3001"  
    echo "Game (游戏库微应用): 端口 3002"
    echo "API (后端服务): 端口 3101"
    echo ""

    # 启动API服务 (后端数据)
    echo "📡 启动API服务..."
    (cd gaming-platform-api && npm run dev) &
    API_PID=$!
    sleep 2

    # 启动Home应用 (首页微前端) - Module Federation需要build+preview
    echo "🏠 启动Home应用..."
    (cd gaming-platform-home && npm run build && npm run preview) &
    HOME_PID=$!
    sleep 3

    # 启动Game应用 (游戏库微前端) - Module Federation需要build+preview  
    echo "🎮 启动Game应用..."
    (cd gaming-platform-game && npm run build && npm run preview) &
    GAME_PID=$!
    sleep 3

    # 启动Container应用 (主容器) - Module Federation需要build+preview
    echo "🌐 启动Container应用..."
    (cd gaming-platform-container && npm run build && npm run preview) &
    CONTAINER_PID=$!

    # 等待服务启动
    sleep 5

    echo ""
    echo "✅ Gaming Platform启动完成!"
    echo ""
    echo "🌐 访问地址:"
    echo "  📱 主应用入口: http://localhost:3000"
    echo "  🏠 Home应用: http://localhost:3001"
    echo "  🎮 Game应用: http://localhost:3002"
    echo "  📡 API服务: http://localhost:3101"
    echo ""
    echo "🏗️ Module Federation微前端架构"
    echo "🛑 按 Ctrl+C 停止所有服务"

    # 等待中断信号
    trap "echo '🛑 停止所有服务...'; kill $API_PID $HOME_PID $GAME_PID $CONTAINER_PID 2>/dev/null; exit" INT TERM

    # 保持脚本运行
    wait
}

# 主逻辑
case "${1:-}" in
    --help|-h)
        show_help
        ;;
    --simple|-s)
        simple_start
        ;;
    "")
        interactive_start
        ;;
    *)
        echo "❌ 未知参数: $1"
        echo "使用 --help 查看帮助信息"
        exit 1
        ;;
esac