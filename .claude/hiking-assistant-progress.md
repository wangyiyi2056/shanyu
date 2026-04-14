---
name: hiking-assistant-progress
description: 爬山助手 AI Agent 项目进展记录
type: project
originSessionId: 29879823-2e07-4b34-b632-2ffec156a94c
---
# 爬山助手项目进展

## 项目概述
- **目标**: 构建一个 AI 驱动的爬山助手移动应用
- **技术栈**: Flutter + Riverpod + flutter_map + 本地 AI API
- **核心功能**: 智能路线推荐（先聚焦单一核心功能）

## 已实现功能

### 1. 基础架构 (已完成)
- Flutter 项目结构（feature-based 目录）
- Riverpod 状态管理
- GoRouter 路由配置
- Material 3 主题系统

### 2. AI 对话系统 (已完成)
- **Claude API Service**: 本地 API 集成 (`http://127.0.0.1:8000/v1/chat/completions`)
  - 模型: gemma-4-e4b-it-8bit
  - API Key: 123456
  - Demo 模式 fallback
- **意图识别**: LocalIntentRules (关键词/正则匹配)
  - 位置实体提取（香山、百望山等）
  - 快速响应处理

### 3. 位置服务 (已完成)
- GPS 定位 (Geolocator)
- 地理编码/逆地理编码 (Geocoding)
- 位置搜索功能
- 默认位置: 北京市 (39.9042, 116.4074)

### 4. 地图功能 (已完成)
- flutter_map + OpenStreetMap (无需 API Key)
- 用户位置标记
- 路线显示
- 地点点击交互

### 5. 智能路线推荐 (已完成 ✅)
- **路线数据模型**: HikingRoute + Waypoint
- **本地数据源**: 8 条真实北京爬山路线
  - 香山公园-亲子线 (easy)
  - 香山公园-主路线 (moderate)
  - 百望山 (moderate)
  - 凤凰岭-北线 (hard)
  - 妙峰山-古道 (hard)
  - 雾灵山-穿越线 (expert)
  - 长城-慕田峪 (moderate)
  - 白虎涧 (easy)
- **推荐用例**: 基于用户偏好（难度、时长、距离）
- **AI 集成**: 将推荐路线作为上下文提供给 AI

## 任务计划（优先级排序）

| ID | 任务 | 状态 | 依赖 | 优先级 |
|----|------|------|------|--------|
| #2 | 路线详情页面实现 | pending | - | **P0** (下一个) |
| #3 | 路线评价系统 | pending | #2 | P1 |
| #5 | 天气 API 集成 | pending | - | P1 |
| #1 | 轨迹记录功能 | pending | #2, #3, #5 | P2 |
| #4 | 微信小程序适配 | pending | #1, #2, #3, #5 | P3 |

### 任务详情

**#2 路线详情页面实现** (P0)
- 创建路线详情页面
- 展示路线图片、描述、waypoints
- 显示用户评价和评分
- 添加导航按钮

**#3 路线评价系统** (P1)
- 用户评分功能（1-5星）
- 评论提交
- 收藏功能
- 评价数据存储

**#5 天气 API 集成** (P1)
- 选择天气 API 服务
- 实时天气查询
- 出行建议生成
- 安全提醒（恶劣天气）

**#1 轨迹记录功能** (P2)
- 实时 GPS 跟踪
- 轨迹数据存储（SQLite）
- 轨迹可视化
- 分享功能

**#4 微信小程序适配** (P3)
- 评估 Flutter → 小程序方案
- 功能适配（去除不支持的特性）
- 微信 API 集成

## 计划实现功能（旧版）

### Phase 2: 路线详情增强
- [ ] 路线详情页面 → **#2**
- [ ] 路线评价系统 → **#3**
- [ ] 路线图片展示 → **#2**
- [ ] 路线导航功能 → **#2**

### Phase 3: 天气集成
- [ ] 天气 API 集成 → **#5**
- [ ] 出行建议（基于天气） → **#5**
- [ ] 安全提醒 → **#5**

### Phase 4: 轨迹记录
- [ ] 实时 GPS 跟踪 → **#1**
- [ ] 轨迹数据存储 → **#1**
- [ ] 轨迹分享功能 → **#1**

### Phase 5: 小程序适配
- [ ] 微信小程序版本 → **#4**
- [ ] 功能适配 → **#4**

## 关键文件
- `lib/features/chat/data/services/claude_api_service.dart` - AI 服务
- `lib/features/chat/presentation/providers/chat_provider.dart` - 聊天状态管理
- `lib/features/hiking/data/models/route_model.dart` - 路线数据模型
- `lib/features/hiking/data/datasources/route_local_datasource.dart` - 路线数据
- `lib/features/hiking/domain/usecases/route_recommendation_usecase.dart` - 推荐逻辑
- `lib/shared/services/location_service.dart` - 位置服务

## 用户偏好记录
- 目标用户: 休闲徒步者
- 技术偏好: Flutter (未来接入小程序)
- AI 重点: 对话交互
- 暂无后端服务对接