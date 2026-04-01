# DeerFlow Docker Local Development

本目录提供基于 Docker 的本地开发环境。

## 快速开始

```bash
# 1. 初始化（拉取镜像）
make docker-init

# 2. 启动服务
make docker-start

# 3. 访问应用
open http://localhost:2026

# 4. 关闭服务
make docker-stop
```

## 数据目录

所有配置和数据存储在 `~/.deer-flow` 目录：

| 文件/目录 | 说明 |
|-----------|------|
| `config.yaml` | 配置文件 |
| `extensions_config.json` | 扩展配置 |
| `skills/` | 技能目录 |
| `memory.json` | 用户记忆 |
| `threads/` | 线程数据 |
| `.env` | 环境变量 |

## 服务组件

| 服务 | 端口 | 说明 |
|------|------|------|
| nginx | 2026 | 反向代理 |
| frontend | 3000 | Next.js 前端 |
| gateway | 8001 | Backend Gateway API |
| langgraph | 2024 | LangGraph Server |

## 命令

```bash
make docker-init          # 拉取镜像
make docker-start         # 启动服务
make docker-stop          # 停止服务
make docker-logs          # 查看日志
make docker-logs-frontend # 前端日志
make docker-logs-gateway  # Gateway 日志
```

## 沙箱模式

通过 `~/.deer-flow/config.yaml` 中的 `sandbox.use` 配置：

- `deerflow.sandbox.local:LocalSandboxProvider` — 本地沙箱（无需拉取镜像）
- `deerflow.community.aio_sandbox:AioSandboxProvider` — Docker 沙箱

## 持久化

- **记忆文件**：`~/.deer-flow/memory.json`
- **Checkpointer**：`~/.deer-flow/checkpoints.db`
- **线程数据**：`~/.deer-flow/threads/`
