import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:hiking_assistant/core/constants/app_constants.dart';
import 'package:hiking_assistant/features/plant/domain/entities/plant_identification_result.dart';

/// 植物识别服务
///
/// 使用 Claude Vision API 进行植物识别：
/// - 支持图片分析（base64 或 URL）
/// - 提供植物名称、特征、毒性警告
/// - 给出户外安全建议
class PlantIdentificationService {
  PlantIdentificationService._();

  static PlantIdentificationService get instance => PlantIdentificationService._();

  static const String _apiUrl = AppConstants.claudeApiUrl;
  static const String _apiKey = AppConstants.claudeApiKey;
  static const String _model = AppConstants.claudeModel;
  static const String _apiVersion = '2023-06-01';

  /// 识别植物（从图片字节）
  ///
  /// 支持 JPEG, PNG, GIF, WebP 格式
  Future<PlantIdentificationResult> identifyFromImageBytes(
    Uint8List imageBytes,
    String mediaType, // 'image/jpeg', 'image/png', etc.
  ) async {
    try {
      final base64Image = base64Encode(imageBytes);

      return await _identifyWithClaudeVision(
        imageSource: {
          'type': 'base64',
          'media_type': mediaType,
          'data': base64Image,
        },
      );
    } on Exception catch (e) {
      return PlantIdentificationResult.error(
        message: '图片处理失败: ${e.toString()}',
      );
    }
  }

  /// 识别植物（从图片 URL）
  Future<PlantIdentificationResult> identifyFromUrl(String imageUrl) async {
    try {
      return await _identifyWithClaudeVision(
        imageSource: {
          'type': 'url',
          'url': imageUrl,
        },
      );
    } on Exception catch (e) {
      return PlantIdentificationResult.error(
        message: '图片加载失败: ${e.toString()}',
      );
    }
  }

  /// 使用 Claude Vision API 识别
  Future<PlantIdentificationResult> _identifyWithClaudeVision({
    required Map<String, dynamic> imageSource,
  }) async {
    if (_apiKey.isEmpty) {
      return _getDemoResult();
    }

    final systemPrompt = '''你是一个专业的野外植物识别专家，专注于中国北方山区的植物。

## 识别要求
1. **准确识别**：根据图片特征，识别植物的科学名称和常见名称
2. **安全评估**：特别关注是否有毒性、是否可食用、是否有致敏风险
3. **特征描述**：简要描述识别依据（叶片、花朵、果实等特征）
4. **分布信息**：说明该植物在中国北方的分布情况

## 回复格式
使用以下结构化格式回复：

### 🌿 植物识别结果

**名称**：[中文名] / [学名]
**科属**：[科名] - [属名]
**特征**：[简要特征描述]

### ⚠️ 安全提示

**毒性等级**：[无毒/低毒/有毒/剧毒]
**可食用性**：[不可食用/需处理后食用/可食用]
**致敏风险**：[无/低/高]

### 📝 户外建议

- [针对该植物的具体建议]
- [遇到该植物时的注意事项]

## 重要原则
1. 如果无法确定植物身份，明确说明"无法确定"，不要猜测
2. 任何有毒植物必须用醒目的警告标识
3. 野生蘑菇类必须强调"不建议采摘食用"
4. 提供准确信息，但鼓励用户进一步查阅专业资料确认''';

    final requestBody = {
      'model': _model,
      'max_tokens': 2048,
      'system': [
        {
          'type': 'text',
          'text': systemPrompt,
          'cache_control': {'type': 'ephemeral'},
        },
      ],
      'messages': [
        {
          'role': 'user',
          'content': [
            {
              'type': 'image',
              'source': imageSource,
            },
            {
              'type': 'text',
              'text': '请识别这张图片中的植物，并提供详细的安全信息。',
            },
          ],
        },
      ],
    };

    final response = await http
        .post(
      Uri.parse(_apiUrl),
      headers: {
        'Content-Type': 'application/json',
        'x-api-key': _apiKey,
        'anthropic-version': _apiVersion,
      },
      body: jsonEncode(requestBody),
    )
        .timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final content = data['content'] as List?;
      final textBlock = content?.firstWhere(
        (b) => b['type'] == 'text',
        orElse: () => {'text': ''},
      );
      final text = textBlock['text'] as String? ?? '';

      return PlantIdentificationResult.success(
        description: text,
        confidence: 0.85,
        imageBytes: imageSource['type'] == 'base64' ? base64Decode(imageSource['data'] as String) : null,
        mediaType: imageSource['media_type'] as String?,
      );
    } else {
      return _getDemoResult();
    }
  }

  /// 演示结果（API 不可用时）
  PlantIdentificationResult _getDemoResult() {
    return PlantIdentificationResult.success(
      description: '''### 🌿 植物识别结果

**名称**：野菊花 / Chrysanthemum indicum
**科属**：菊科 - 菊属
**特征**：小型黄色花朵，叶片羽状分裂，有特殊香气

### ⚠️ 安全提示

**毒性等级**：无毒
**可食用性**：可药用，但不建议直接食用
**致敏风险**：低（部分人群可能对花粉过敏）

### 📝 户外建议

- 野菊花可采摘用于泡茶，但需确认无农药污染
- 避免采摘路边的野菊花，可能有汽车尾气污染
- 如不确定植物身份，请勿采摘食用

💡 **提示**：目前使用演示数据。配置 Claude API Key 后可获得准确的植物识别结果。''',
      confidence: 0.50,
      isDemo: true,
    );
  }
}