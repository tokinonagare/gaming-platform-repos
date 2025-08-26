# 🎮 Gaming Platform - 微前端架构

基于 Single-SPA 的微前端游戏平台，采用独立仓库管理的分布式开发模式。

## 🏗️ 架构概览

```
gaming-platform-repos/
├── gaming-platform-root/     # 🏠 主应用容器 (端口: 9000)
├── gaming-platform-home/     # 🏠 首页微服务 (端口: 9001)
├── gaming-platform-api/      # 📡 共享API服务 (端口: 9101)
├── install.sh                 # 📦 依赖安装脚本
├── start.sh                   # 🚀 服务启动脚本
├── stop.sh                    # 🛑 服务停止脚本
├── update.sh                  # 🔄 依赖更新脚本
├── deploy.sh                  # 🚢 生产部署脚本
└── nginx.conf                 # ⚙️ Nginx 配置文件
```

## 🚀 快速开始

### 1. 安装依赖

```bash
# 安装所有微服务依赖
./install.sh
```

### 2. 启动服务

```bash
# 启动所有微服务
./start.sh
```

### 3. 访问应用

打开浏览器访问: **http://localhost:9000**

### 4. 停止服务

```bash
# 优雅停止所有服务
./stop.sh
```

## ✨ 核心特性

- 🏗️ **独立仓库**: 每个微服务拥有独立的git仓库
- 🚀 **独立部署**: 可单独部署和更新某个服务
- 👥 **团队协作**: 不同团队可维护不同的微服务
- 🔧 **技术隔离**: 各服务可使用不同的技术栈版本
- ⚡ **热更新**: 开发时支持热更新和实时预览
- 🛡️ **错误隔离**: 单个微服务故障不影响整体应用
- 🔄 **自动发现**: 脚本自动发现所有 gaming-platform-* 服务
- 📦 **智能管理**: 支持依赖更新、服务监控等高级功能

## 📋 微服务说明

### 🏠 主应用 (gaming-platform-root)
- **职责**: 应用容器、路由管理、微服务编排
- **技术栈**: Single-SPA + React + Vite
- **端口**: 9000

### 📡 API服务 (gaming-platform-api)  
- **职责**: 提供统一的HTTP客户端和服务管理
- **技术栈**: JavaScript + Vite
- **端口**: 9101

### 🎮 首页服务 (gaming-platform-home)
- **职责**: 游戏推荐、分类展示、快捷操作
- **技术栈**: React + Vite
- **端口**: 9001

## 🛠️ 完整的管理命令

```bash
# 📦 依赖管理
./install.sh                    # 安装所有依赖
./update.sh                     # 交互式更新依赖
./update.sh --yes               # 自动确认更新
./update.sh --check             # 检查过期依赖

# 🚀 服务管理  
./start.sh                      # 启动所有服务
./stop.sh                       # 优雅停止服务
./stop.sh --force               # 强制停止所有进程
./stop.sh --clean-logs          # 停止服务并清理日志

# 🚢 部署管理
./deploy.sh deploy              # 部署到生产环境
./deploy.sh rollback [VERSION]  # 回滚到指定版本
./deploy.sh cleanup             # 清理旧备份

# 📖 帮助信息
./install.sh --help             # 查看安装脚本帮助
./start.sh --help               # 查看启动脚本帮助
./stop.sh --help                # 查看停止脚本帮助
./update.sh --help              # 查看更新脚本帮助
./deploy.sh help                # 查看部署脚本帮助
```

## 📦 生产环境部署

### 构建和部署

```bash
# 使用部署脚本 (推荐)
./deploy.sh deploy

# 或手动构建
cd gaming-platform-api && npm run build
cd gaming-platform-home && npm run build  
cd gaming-platform-root && npm run build
```

### 部署架构

生产环境下，所有微服务部署在同一域名的不同路径：

```
https://your-gaming-platform.com/
├── /                          # 主应用入口
├── /micro/api/services.js     # API服务模块
├── /micro/home/home.js        # Home服务模块
├── /micro/games/games.js      # Games服务模块 (扩展)
└── /api/*                     # 后端API代理
```

### Nginx 配置

项目提供了完整的 Nginx 配置文件 (`nginx.conf`)，支持：

- 静态文件缓存和压缩
- 微服务路由代理
- CORS 跨域支持
- 后端API代理
- 健康检查端点
- 自动负载均衡

## 🔧 开发指南

### 添加新的微服务

由于脚本具备自动发现功能，添加新服务非常简单：

1. **创建新服务目录**：
   ```bash
   mkdir gaming-platform-games
   cd gaming-platform-games
   npm init -y
   # 添加您的代码...
   ```

2. **脚本自动识别**：所有脚本会自动发现并管理新服务

3. **注册到主应用**：在 `gaming-platform-root/src/root-config.js` 中注册

4. **更新端口配置**：脚本会自动分配端口 (games: 9002)

### 本地开发

每个微服务都可以独立开发：

```bash
# 只启动某个微服务进行开发
cd gaming-platform-home
npm run dev
```

### 调试和日志

启动脚本会在 `logs/` 目录下生成各服务的日志文件：

```bash
# 查看日志
tail -f logs/gaming-platform-home.log
tail -f logs/gaming-platform-api.log
tail -f logs/gaming-platform-root.log
```

### 依赖更新工作流

```bash
# 1. 先停止所有服务
./stop.sh

# 2. 检查过期依赖
./update.sh --check

# 3. 更新依赖
./update.sh

# 4. 重新启动服务
./start.sh
```

## 🏷️ 版本管理

- 每个微服务独立进行版本管理
- 支持独立发布和回滚
- 主应用通过配置文件管理各服务版本
- CI/CD 支持增量构建和部署

## 🔄 通信机制

### 应用加载
- Root应用通过Single-SPA动态加载微服务
- 支持懒加载和按需加载
- 错误隔离和降级处理

### 数据共享
- API服务提供全局 `window.$api` 接口
- 统一的HTTP客户端和缓存管理
- 跨服务状态管理和事件通信

### 开发环境通信
```
Root (9000) → API (9101) → 提供全局服务
            → Home (9001) → 使用全局API服务
```

### 生产环境通信
```
同域名下不同路径 → 无跨域问题 → 统一的用户体验
```

## ⚙️ 配置管理

### 环境配置

主应用支持开发/生产环境自动切换：

**开发环境**：
```javascript
// 使用localhost端口
services: {
  api: 'http://localhost:9101/src/services.js',
  home: 'http://localhost:9001/src/home.js'
}
```

**生产环境**：
```javascript
// 使用相对路径
services: {
  api: '/micro/api/services.js',
  home: '/micro/home/home.js'
}
```

### 端口分配

脚本支持智能端口分配：

- **核心服务**：固定端口 (API: 9101, Home: 9001, Root: 9000)
- **扩展服务**：预定义端口 (Games: 9002, Events: 9003, Wallet: 9004, Profile: 9005)
- **新增服务**：动态分配 (从9010开始)

## 🚨 故障排除

### 常见问题

1. **端口冲突**：
   ```bash
   ./stop.sh --force  # 强制清理所有端口
   ```

2. **依赖问题**：
   ```bash
   ./update.sh --check  # 检查依赖状态
   ./update.sh         # 重新安装依赖
   ```

3. **服务无法启动**：
   ```bash
   # 查看日志
   tail -f logs/gaming-platform-[service-name].log
   ```

4. **跨域问题**：
   确保各服务的 `vite.config.js` 中启用了CORS

### 性能优化

- 使用 `./stop.sh --clean-logs` 定期清理日志
- 使用 `./update.sh --check` 定期检查依赖更新
- 监控各服务的内存和CPU使用情况

## 🤝 贡献指南

1. Fork 对应的微服务仓库
2. 创建功能分支：`git checkout -b feature/amazing-feature`
3. 提交代码：`git commit -m 'Add some amazing feature'`
4. 推送分支：`git push origin feature/amazing-feature`
5. 创建 Pull Request

## 📄 许可证

MIT License

## 📖 更多文档

- [部署文档](./deploy.sh) - 生产环境部署详细说明  
- [CI/CD配置](./.github/workflows/deploy.yml) - 自动化部署流程
- [Nginx配置](./nginx.conf) - 生产环境Web服务器配置

---

## 🎯 项目架构优势

### 开发体验
- ⚡ **快速启动**: 一键安装、启动、停止
- 🔄 **智能更新**: 自动检查和更新依赖
- 📊 **状态监控**: 实时显示服务运行状态
- 🛠️ **自动发现**: 无需手动配置新服务

### 生产就绪
- 🚢 **自动部署**: CI/CD 支持和一键部署
- 📈 **可扩展性**: 支持任意数量的微服务
- 🔒 **安全性**: CORS配置和安全头部
- 📊 **监控**: 健康检查和性能监控

### 团队协作
- 👥 **独立开发**: 团队间无代码冲突
- 🔀 **独立部署**: 不同服务独立发布
- 🏷️ **版本管理**: 每个服务独立版本控制
- 🧪 **独立测试**: 单独的测试和构建流程

这个架构为现代微前端应用提供了完整的开发、部署和维护解决方案！🚀