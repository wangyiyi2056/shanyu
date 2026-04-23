/// 工具参数定义
class ToolParameter {
  final String name;
  final String type;
  final String description;
  final bool required;
  final dynamic defaultValue;

  const ToolParameter({
    required this.name,
    required this.type,
    required this.description,
    this.required = true,
    this.defaultValue,
  });

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'description': description,
      if (defaultValue != null) 'default': defaultValue,
    };
  }
}

/// 聊天工具接口
///
/// 每个工具对应一个可由 AI 调用的应用功能
abstract class ChatTool {
  /// 工具名称（英文，用于 API）
  String get name;

  /// 工具显示名称（中文）
  String get displayName;

  /// 工具描述
  String get description;

  /// 工具参数定义
  List<ToolParameter> get parameters;

  /// 执行工具
  ///
  /// [arguments] 为 AI 提供的参数
  /// 返回工具执行结果的文本描述
  Future<String> execute(Map<String, dynamic> arguments);

  /// 转换为 Anthropic tools 格式
  Map<String, dynamic> toAnthropicSchema() {
    final properties = <String, dynamic>{};
    final requiredParams = <String>[];

    for (final param in parameters) {
      properties[param.name] = param.toJson();
      if (param.required) {
        requiredParams.add(param.name);
      }
    }

    return {
      'name': name,
      'description': description,
      'input_schema': {
        'type': 'object',
        'properties': properties,
        'required': requiredParams,
      },
    };
  }
}

/// 工具调用结果
class ToolCallResult {
  final String toolName;
  final Map<String, dynamic> arguments;
  final String result;
  final bool isSuccess;
  final String? errorMessage;

  const ToolCallResult({
    required this.toolName,
    required this.arguments,
    required this.result,
    this.isSuccess = true,
    this.errorMessage,
  });
}

/// 工具调用请求（来自 AI）
class ToolCallRequest {
  final String id;
  final String name;
  final Map<String, dynamic> arguments;

  const ToolCallRequest({
    required this.id,
    required this.name,
    required this.arguments,
  });
}
