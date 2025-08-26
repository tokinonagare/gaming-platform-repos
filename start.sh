#!/bin/bash

# =================================================================
# 🚀 Gaming Platform - 极简启动脚本
# =================================================================

echo "🚀 启动Gaming Platform (简化架构)"
echo "Container (容器应用): 端口 3000"
echo "Home (独立应用): 端口 3001"  
echo "API (服务): 端口 3002"
echo ""

# 启动API服务
echo "启动API服务..."
(cd gaming-platform-api && npm run dev) &
API_PID=$!

# 启动Home服务  
echo "启动Home服务..."
(cd gaming-platform-home && npm run dev) &
HOME_PID=$!

# 启动Container应用
echo "启动Container应用..."
(cd gaming-platform-container && npm run dev) &
CONTAINER_PID=$!

# 等待服务启动
sleep 3

echo ""
echo "✅ 服务启动完成!"
echo ""
echo "🌐 访问地址:"
echo "  Container应用 (主入口): http://localhost:3000"
echo "  Home应用 (独立): http://localhost:3001"
echo "  API服务: http://localhost:3002"
echo ""
echo "🛑 按 Ctrl+C 停止所有服务"

# 等待中断信号
trap "echo '停止所有服务...'; kill $API_PID $HOME_PID $CONTAINER_PID 2>/dev/null; exit" INT TERM

# 保持脚本运行
wait