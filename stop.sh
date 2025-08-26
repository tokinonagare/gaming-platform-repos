#!/bin/bash

# =================================================================
# 🛑 Gaming Platform - 极简停止脚本
# =================================================================

echo "🛑 停止Gaming Platform服务..."

# 停止所有相关进程
pkill -f "vite.*3000" 2>/dev/null
pkill -f "vite.*3001" 2>/dev/null  
pkill -f "vite.*3002" 2>/dev/null
pkill -f "gaming-platform" 2>/dev/null

echo "✅ 所有服务已停止"