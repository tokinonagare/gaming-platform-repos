# 🎮 Gaming Platform

现代化游戏平台，基于微前端架构构建，提供灵活的游戏内容管理和展示功能。

## 🏗️ 架构概览

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│  Container App  │────│   Home App      │────│   API Service   │
│   (Port 3000)   │    │  (Port 3001)    │    │  (Port 3002)    │
│                 │    │                 │    │                 │
│ • 应用容器      │    │ • 游戏展示      │    │ • REST API      │
│ • 底部导航      │    │ • 热门推荐      │    │ • 游戏数据      │
│ • iframe集成    │    │ • 游戏分类      │    │ • 智能CORS     │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

## 🚀 快速开始

### 启动服务

```bash
# 启动所有服务
./start.sh

# 停止所有服务  
./stop.sh
```

### 访问地址

- **🏠 主应用**: http://localhost:3000
- **🎮 游戏应用**: http://localhost:3001  
- **📡 API服务**: http://localhost:3002

## 📱 服务详情

### Container App (容器应用)
- **端口**: 3000
- **功能**: 应用壳子，提供底部导航和iframe集成
- **技术栈**: React + React Native Web + Vite

### Home App (游戏应用)  
- **端口**: 3001
- **功能**: 游戏内容展示，热门推荐，游戏分类
- **技术栈**: React + React Native Web + Vite

### API Service (后端服务)
- **端口**: 3002  
- **功能**: 游戏数据API，支持热门游戏、搜索、分类等
- **技术栈**: Node.js + Express + 智能CORS

## 🌐 API端点

| 方法 | 端点 | 描述 |
|------|------|------|
| GET | /api/games/featured | 获取热门游戏列表 |
| GET | /api/games/categories | 获取游戏分类 |
| GET | /api/games/search | 搜索游戏 |
| GET | /api/games/:id | 获取游戏详情 |
| POST | /api/games/:id/rating | 提交游戏评分 |
| POST | /api/games/:id/favorite | 添加游戏收藏 |
| GET | /health | 健康检查 |

## 🎯 特性

- ✅ **微前端架构**: 模块化、可扩展
- ✅ **响应式设计**: 支持桌面和移动端
- ✅ **智能CORS**: 自动适配开发和生产环境
- ✅ **API回退机制**: 优雅降级到模拟数据
- ✅ **现代化技术栈**: React 18 + Vite + Express

## 📄 许可证

MIT License
