#!/bin/bash

# =================================================================
# 🛑 Gaming Platform - Module Federation架构停止脚本
# =================================================================

echo "🛑 停止Gaming Platform所有服务..."

# 停止所有Gaming Platform相关进程
echo "📡 停止API服务 (端口3101)..."
pkill -f "vite.*3101" 2>/dev/null
pkill -f "gaming-platform-api" 2>/dev/null

echo "🏠 停止Home应用 (端口3001)..."
pkill -f "vite.*3001" 2>/dev/null  
pkill -f "gaming-platform-home" 2>/dev/null

echo "🎮 停止Game应用 (端口3002)..."
pkill -f "vite.*3002" 2>/dev/null
pkill -f "gaming-platform-game" 2>/dev/null

echo "🌐 停止Container应用 (端口3000)..."
pkill -f "vite.*3000" 2>/dev/null
pkill -f "gaming-platform-container" 2>/dev/null

# 通用清理
pkill -f "gaming-platform" 2>/dev/null

sleep 1
echo ""
echo "✅ Gaming Platform所有服务已停止"
echo "🏗️ Module Federation架构已关闭"