# 山语 - AI 爬山助手

一个基于 Flutter 的 AI 驱动爬山助手移动应用，专注于智能路线推荐功能。

## 核心功能

### 智能路线推荐 ✅
- 8 条真实北京爬山路线数据（香山、百望山、凤凰岭等）
- 根据用户偏好（难度、时长、距离）智能推荐
- AI 对话式交互，自然语言查询

### AI 对话系统 ✅
- 本地 API 集成（支持 OpenAI 格式）
- 意图识别 + 快速响应
- Demo 模式 fallback
- 天气上下文集成

### 位置服务 ✅
- GPS 定位
- 地理编码/逆地理编码
- 基于位置的路线排序

### 地图展示 ✅
- OpenStreetMap（无需 API Key）
- 路线可视化
- 用户位置标记
- 实时轨迹记录与展示

### 路线详情与评价 ✅
- 路线图片、描述、waypoints 展示
- 用户评分与评论
- 收藏功能
- 实时天气卡片

### 天气集成 ✅
- Open-Meteo 免费天气 API
- 实时天气与 3 日预报
- 出行建议与安全提醒

### 轨迹记录 ✅
- 实时 GPS 跟踪
- SQLite 本地存储
- 暂停/恢复/停止记录
- 轨迹历史列表与详情
- 轨迹地图回放

## 技术栈

| 技术 | 用途 |
|------|------|
| Flutter 3.x | 跨平台移动开发 |
| Riverpod | 状态管理 |
| flutter_map | 地图展示 |
| Geolocator | GPS 定位 |
| Geocoding | 地理编码 |
| sqflite | 轨迹本地存储 |
| shared_preferences | 评价与收藏本地存储 |
| GoRouter | 路由管理 |
| Open-Meteo | 免费天气 API |

## 项目结构

```
lib/
├── core/           # 核心（主题、路由）
├── features/
│   ├── chat/       # AI 对话
│   │   ├── data/services/claude_api_service.dart
│   │   ├── domain/services/intent_service.dart
│   │   └── presentation/providers/chat_provider.dart
│   ├── hiking/     # 爬山路线
│   │   ├── data/models/route_model.dart
│   │   ├── data/datasources/route_local_datasource.dart
│   │   ├── domain/usecases/route_recommendation_usecase.dart
│   │   └── presentation/screens/map_screen.dart
│   ├── tracking/   # 轨迹记录
│   │   ├── data/models/track_model.dart
│   │   ├── data/datasources/track_local_datasource.dart
│   │   ├── presentation/providers/tracking_provider.dart
│   │   └── presentation/screens/
│   └── weather/    # 天气服务
│       ├── data/services/weather_api_service.dart
│       └── data/models/weather_model.dart
└── shared/         # 共享服务
    └── services/location_service.dart
```

## 运行方式

```bash
# 安装依赖
flutter pub get

# 运行（Chrome）
flutter run -d chrome

# 运行（macOS）
flutter run -d macos
```

## API 配置

本地 AI API:
- 地址: `http://127.0.0.1:8000/v1/chat/completions`
- API Key: `123456`
- 模型: `gemma-4-e4b-it-8bit`

## 路线示例

| 路线 | 难度 | 距离 | 时长 |
|------|------|------|------|
| 香山公园-亲子线 | 简单 | 2.3km | 90分钟 |
| 百望山 | 中等 | 3.5km | 120分钟 |
| 凤凰岭-北线 | 较难 | 5.5km | 240分钟 |
| 雾灵山-穿越线 | 专家 | 8.5km | 420分钟 |

## 任务计划

| 优先级 | 任务 | 状态 | 说明 |
|--------|------|------|------|
| **P0** | 路线详情页面 | ✅ | 展示路线完整信息、图片、导航按钮 |
| P1 | 路线评价系统 | ✅ | 用户评分、评论、收藏功能 |
| P1 | 天气 API 集成 | ✅ | 实时天气、出行建议、安全提醒 |
| P2 | 轨迹记录 | ✅ | GPS 跟踪、轨迹存储、历史回放 |
| P3 | 微信小程序 | ⏸️ | 平台适配、功能裁剪（已暂停） |

## 未来规划

- Phase 2: 路线详情页面 + 评价系统 ✅
- Phase 3: 天气 API 集成 + 出行建议 ✅
- Phase 4: 轨迹记录功能 ✅
- Phase 5: 微信小程序适配 ⏸️