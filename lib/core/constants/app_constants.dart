class AppConstants {
  AppConstants._();

  // App Info
  static const String appName = '爬山助手';
  static const String appVersion = '1.0.0';

  // Backend API 配置 - 通过 --dart-define 注入
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://127.0.0.1:8000',
  );

  // Anthropic Claude API 配置
  // 支持两种模式:
  // 1. 本地模型 (OpenAI 兼容格式) - 用于开发测试
  // 2. Anthropic Claude API - 用于生产环境
  static const String claudeApiUrl = String.fromEnvironment(
    'CLAUDE_API_URL',
    defaultValue: 'https://api.anthropic.com/v1/messages',
  );

  static const String claudeApiKey = String.fromEnvironment(
    'CLAUDE_API_KEY',
    defaultValue: '',
  );

  // Claude 模型选择
  // 推荐: claude-opus-4-7 (最强推理), claude-sonnet-4-6 (平衡), claude-haiku-4-5 (快速)
  static const String claudeModel = String.fromEnvironment(
    'CLAUDE_MODEL',
    defaultValue: 'claude-sonnet-4-6',
  );

  // 旧版 OpenAI 兼容 API (本地模型)
  static const String chatApiUrl = String.fromEnvironment(
    'CHAT_API_URL',
    defaultValue: 'http://127.0.0.1:8000/v1/chat/completions',
  );

  static const String apiKey = String.fromEnvironment(
    'API_KEY',
    defaultValue: '',
  );

  // AI 配置
  static const int maxMessageLength = 2000;
  static const int maxConversationHistory = 50;
  static const Duration aiResponseTimeout = Duration(seconds: 60);
  static const String defaultModel = 'claude-sonnet-4-6';

  // Prompt Caching 配置
  // 最小缓存 tokens: Opus/Haiku 4096, Sonnet 1024
  static const int minCacheTokens = 1024;
  static const bool enablePromptCaching = true;

  // Extended Thinking 配置
  // 仅支持 Opus 4.6+, Sonnet 4.6
  static const bool enableExtendedThinking = false;

  // 地图配置
  static const double defaultMapZoom = 13.0;
  static const double defaultLatitude = 39.9042; // 北京
  static const double defaultLongitude = 116.4074;

  // 轨迹记录
  static const int locationUpdateInterval = 5; // 秒
  static const int minDistanceFilter = 10; // 米

  // 缓存
  static const String routesCacheKey = 'cached_routes';
  static const String userPrefsCacheKey = 'user_preferences';
  static const Duration cacheExpiry = Duration(hours: 24);

  // 安全检查：确保生产环境使用 HTTPS
  static bool get isProductionSecure =>
      apiBaseUrl.startsWith('https://') ||
      apiBaseUrl.contains('localhost') ||
      apiBaseUrl.contains('127.0.0.1');

  // Claude API 模式检测
  static bool get isClaudeApiMode =>
      claudeApiUrl.contains('anthropic.com');

  // 可用模型列表
  static const List<String> availableModels = [
    'claude-opus-4-7',   // 最强推理，自适应 thinking
    'claude-opus-4-6',   // 高级推理
    'claude-sonnet-4-6', // 平衡性能与成本
    'claude-haiku-4-5',  // 快速响应
  ];

  // 模型定价 (每百万 tokens)
  // 用于成本估算显示
  static const Map<String, Map<String, double>> modelPricing = {
    'claude-opus-4-7': {'input': 5.00, 'output': 25.00},
    'claude-opus-4-6': {'input': 5.00, 'output': 25.00},
    'claude-sonnet-4-6': {'input': 3.00, 'output': 15.00},
    'claude-haiku-4-5': {'input': 1.00, 'output': 5.00},
  };
}