#!/bin/bash

# =================================================================
# 🚀 Gaming Platform - 一键启动脚本 (与README文档匹配)
# =================================================================

echo "🚀 启动Gaming Platform所有服务..."

# 启动API服务
echo "📡 启动API服务..."
cd gaming-platform-api && npm run dev &

# 启动微应用
echo "🏠 启动Home应用..."
cd ../gaming-platform-home && npm run build && npm run preview &

echo "🎮 启动Game应用..."  
cd ../gaming-platform-game && npm run build && npm run preview &

echo "🌐 启动Container应用..."
cd ../gaming-platform-container && npm run build && npm run preview &

wait