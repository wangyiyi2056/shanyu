import 'package:hiking_assistant/features/chat/domain/tools/chat_tool.dart';

/// 工具注册表
class ToolRegistry {
  final Map<String, ChatTool> _tools = {};

  ToolRegistry(List<ChatTool> tools) {
    for (final tool in tools) {
      _tools[tool.name] = tool;
    }
  }

  List<ChatTool> get allTools => List.unmodifiable(_tools.values);

  ChatTool? getTool(String name) => _tools[name];

  bool hasTool(String name) => _tools.containsKey(name);

  /// 执行工具调用
  Future<ToolCallResult> execute(ToolCallRequest request) async {
    final tool = _tools[request.name];
    if (tool == null) {
      return ToolCallResult(
        toolName: request.name,
        arguments: request.arguments,
        result: '错误: 未找到工具 "${request.name}"',
        isSuccess: false,
        errorMessage: 'Tool not found',
      );
    }

    try {
      final result = await tool.execute(request.arguments);
      return ToolCallResult(
        toolName: request.name,
        arguments: request.arguments,
        result: result,
        isSuccess: true,
      );
    } on Exception catch (e) {
      return ToolCallResult(
        toolName: request.name,
        arguments: request.arguments,
        result: '执行出错: $e',
        isSuccess: false,
        errorMessage: e.toString(),
      );
    }
  }
}
