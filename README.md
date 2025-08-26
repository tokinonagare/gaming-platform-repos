# 🎮 Gaming Platform - 微前端游戏平台

基于Module Federation架构的现代化游戏平台，采用微前端设计实现高度模块化和可维护性。

## 🏗️ 系统架构

### 微服务架构图
```
┌─────────────────────────────────────────────────────────────┐
│                    Gaming Platform                          │
├─────────────────────────────────────────────────────────────┤
│  Container App (3000) - Module Federation Host             │
│  ┌─────────────────┐    ┌─────────────────┐                 │
│  │   Home App      │    │   Game App      │                 │
│  │   (3001)        │    │   (3002)        │                 │
│  │                 │    │                 │                 │
│  │ • 热门游戏      │    │ • 游戏搜索      │                 │
│  │ • 快捷操作      │    │ • 分类浏览      │                 │
│  │ • 游戏分类      │    │ • 游戏库管理     │                 │
│  └─────────────────┘    └─────────────────┘                 │
└─────────────────────────────────────────────────────────────┘
                           │
                           │ HTTP API
                           ▼
                ┌─────────────────┐
                │   API Service   │
                │     (3101)      │
                │                 │
                │ • 游戏数据API    │
                │ • CORS配置      │
                │ • 健康检查      │
                └─────────────────┘
```

## 🚀 快速启动

### 完整启动序列
按以下顺序启动所有服务：

```bash
# 1. 启动API服务 (后端数据)
cd gaming-platform-api
npm install && npm run dev
# 访问: http://localhost:3101

# 2. 启动Home应用 (首页微前端)
cd ../gaming-platform-home  
npm install && npm run build && npm run preview
# 访问: http://localhost:3001

# 3. 启动Game应用 (游戏库微前端)
cd ../gaming-platform-game
npm install && npm run build && npm run preview  
# 访问: http://localhost:3002

# 4. 启动Container应用 (主容器)
cd ../gaming-platform-container
npm install && npm run build && npm run preview
# 访问: http://localhost:3000 (主入口)
```

### 一键启动脚本
```bash
# 创建启动脚本
cat > start-all.sh << 'EOF'
#!/bin/bash
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
EOF

chmod +x start-all.sh
./start-all.sh
```

## 📦 项目结构

```
gaming-platform-repos/
├── README.md                    # 项目总览 (本文件)
├── gaming-platform-container/   # 微前端容器 (端口3000)
│   ├── src/App.jsx             # 主容器组件
│   ├── vite.config.js          # Module Federation Host配置
│   └── README.md               # Container详细文档
├── gaming-platform-home/       # 首页微应用 (端口3001) 
│   ├── src/App.jsx             # 首页组件
│   ├── src/services/gameApi.js # 游戏API服务
│   ├── vite.config.js          # Module Federation Remote配置
│   └── README.md               # Home详细文档
├── gaming-platform-game/       # 游戏库微应用 (端口3002)
│   ├── src/App.jsx             # 游戏库组件
│   ├── src/components/         # 游戏相关组件
│   ├── vite.config.js          # Module Federation Remote配置
│   └── README.md               # Game详细文档
└── gaming-platform-api/        # API后端服务 (端口3101)
    ├── src/server.js           # Express服务器
    ├── package.json            # API依赖配置
    └── README.md               # API详细文档
```

## 🌐 服务端口分配

| 服务 | 端口 | 描述 | 访问地址 |
|------|------|------|----------|
| **Container** | 3000 | 微前端容器主入口 | http://localhost:3000 |
| **Home** | 3001 | 首页微应用 | http://localhost:3001 |
| **Game** | 3002 | 游戏库微应用 | http://localhost:3002 |
| **API** | 3101 | 后端API服务 | http://localhost:3101 |

## 🎯 核心功能

### 🏠 首页 (Home App)
- **热门游戏展示**: 展示平台推荐的热门游戏
- **快捷操作**: 搜索、分类等快捷入口  
- **游戏分类导航**: 按类型浏览游戏
- **API集成**: 连接后端服务获取实时数据

### 🎮 游戏库 (Game App)  
- **智能搜索**: 按名称、类型搜索游戏
- **分类浏览**: 动作、冒险、解谜、策略等分类
- **最近游戏**: 快速访问最近玩过的游戏
- **游戏详情**: 完整的游戏信息展示

### 📡 API服务 (API Service)
- **RESTful API**: 标准的HTTP API接口
- **游戏数据管理**: 游戏信息的CRUD操作
- **智能CORS**: 开发和生产环境自适应
- **健康检查**: 服务状态监控

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

## 🔧 技术栈

### 前端技术
- **React 18**: 现代React框架
- **React Native Web**: 跨平台UI库
- **Vite**: 现代构建工具
- **Module Federation**: 微前端架构核心
- **@originjs/vite-plugin-federation**: Vite的Module Federation插件

### 后端技术  
- **Node.js + Express**: API服务框架
- **CORS**: 跨域资源共享配置
- **RESTful API**: 标准API设计

### 开发工具
- **npm**: 包管理器
- **ESLint**: 代码质量检查
- **Git**: 版本控制

## 🏗️ Module Federation架构

### 容器应用 (Host)
```javascript
// gaming-platform-container/vite.config.js
federation({
  name: 'containerApp',
  remotes: {
    homeApp: 'http://localhost:3001/assets/remoteEntry.js',
    gameApp: 'http://localhost:3002/assets/remoteEntry.js'
  },
  shared: {
    'react': { singleton: true },
    'react-dom': { singleton: true },
    'react-native-web': { singleton: true }
  }
})
```

### 微应用 (Remote)
```javascript
// gaming-platform-home/vite.config.js
federation({
  name: 'homeApp',
  filename: 'remoteEntry.js',
  exposes: {
    './App': './src/App.jsx'
  },
  shared: { /* 共享依赖配置 */ }
})
```

## 📱 开发指南

### 开发环境要求
- Node.js 16+
- npm 7+
- 现代浏览器 (Chrome 89+)

### 开发模式
```bash
# 开发单个微应用
cd gaming-platform-home
npm run dev

# Module Federation兼容模式
npm run build && npm run preview
```

### 构建配置
所有微应用都使用统一的构建配置：
```javascript
build: {
  target: 'chrome89',  // Module Federation兼容性
  minify: false,       // 保持模块联邦兼容性
  cssCodeSplit: false  // 避免样式加载问题
}
```

## 🚀 部署指南

### 生产环境配置
```bash
# 设置环境变量
export VITE_HOME_APP_URL=https://your-home-app-domain.com
export VITE_GAME_APP_URL=https://your-game-app-domain.com

# 构建所有应用
npm run build
```

### Docker部署
```dockerfile
# 示例Dockerfile
FROM node:18-alpine
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production
COPY . .
EXPOSE 3000
CMD ["npm", "run", "preview"]
```

## 🎯 特性亮点

- ✅ **Module Federation微前端**: 真正的模块化架构
- ✅ **响应式移动端设计**: React Native Web跨平台UI
- ✅ **智能API回退**: 优雅降级到模拟数据
- ✅ **现代化构建**: Vite快速构建和热更新
- ✅ **生产就绪**: 完整的CORS和部署配置
- ✅ **开发友好**: 独立开发和调试支持

## 🔍 故障排除

### 常见问题

**1. Module Federation加载失败**
```bash
# 确保使用build+preview模式
npm run build && npm run preview
```

**2. CORS错误**  
```bash
# 检查API服务CORS配置
curl http://localhost:3101/health
```

**3. 端口冲突**
```bash
# 检查端口占用
lsof -i :3000,:3001,:3002,:3101
```

## 📚 更多文档

- [Container应用详细文档](./gaming-platform-container/README.md)
- [Home应用详细文档](./gaming-platform-home/README.md)  
- [Game应用详细文档](./gaming-platform-game/README.md)
- [API服务详细文档](./gaming-platform-api/README.md)

## 🤝 贡献指南

1. Fork 本项目
2. 创建功能分支 (`git checkout -b feature/amazing-feature`)
3. 提交更改 (`git commit -m 'Add some amazing feature'`)
4. 推送到分支 (`git push origin feature/amazing-feature`)
5. 开启 Pull Request

## 📄 许可证

本项目采用 MIT 许可证 - 查看 [LICENSE](LICENSE) 文件了解详情。

---

🎮 **享受你的Gaming Platform开发之旅！**
