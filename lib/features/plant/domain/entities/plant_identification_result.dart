import 'dart:typed_data';

/// 植物识别结果
class PlantIdentificationResult {
  final bool isSuccess;
  final String? description;
  final double? confidence;
  final String? errorMessage;
  final bool isDemo;
  final Uint8List? imageBytes;
  final String? mediaType;

  const PlantIdentificationResult({
    required this.isSuccess,
    this.description,
    this.confidence,
    this.errorMessage,
    this.isDemo = false,
    this.imageBytes,
    this.mediaType,
  });

  factory PlantIdentificationResult.success({
    required String description,
    required double confidence,
    bool isDemo = false,
    Uint8List? imageBytes,
    String? mediaType,
  }) {
    return PlantIdentificationResult(
      isSuccess: true,
      description: description,
      confidence: confidence,
      isDemo: isDemo,
      imageBytes: imageBytes,
      mediaType: mediaType,
    );
  }

  factory PlantIdentificationResult.error({
    required String message,
    Uint8List? imageBytes,
    String? mediaType,
  }) {
    return PlantIdentificationResult(
      isSuccess: false,
      errorMessage: message,
      imageBytes: imageBytes,
      mediaType: mediaType,
    );
  }

  /// 提取植物名称（从描述文本）
  String? extractPlantName() {
    if (description == null) return null;

    final nameMatch =
        RegExp(r'\*\*名称\*\*[：:]\s*(.+)').firstMatch(description!);
    if (nameMatch != null) {
      return nameMatch.group(1)?.trim();
    }
    return null;
  }

  /// 提取科属信息
  String? extractFamily() {
    if (description == null) return null;

    final familyMatch =
        RegExp(r'\*\*科属\*\*[：:]\s*(.+)').firstMatch(description!);
    if (familyMatch != null) {
      return familyMatch.group(1)?.trim();
    }
    return null;
  }

  /// 提取特征描述
  String? extractFeatures() {
    if (description == null) return null;

    final featureMatch =
        RegExp(r'\*\*特征\*\*[：:]\s*(.+)').firstMatch(description!);
    if (featureMatch != null) {
      return featureMatch.group(1)?.trim();
    }
    return null;
  }

  /// 提取毒性等级
  String? extractToxicityLevel() {
    if (description == null) return null;

    final toxicityMatch =
        RegExp(r'\*\*毒性等级\*\*[：:]\s*(.+)').firstMatch(description!);
    if (toxicityMatch != null) {
      return toxicityMatch.group(1)?.trim();
    }
    return null;
  }

  /// 提取可食用性
  String? extractEdibility() {
    if (description == null) return null;

    final edibilityMatch =
        RegExp(r'\*\*可食用性\*\*[：:]\s*(.+)').firstMatch(description!);
    if (edibilityMatch != null) {
      return edibilityMatch.group(1)?.trim();
    }
    return null;
  }

  /// 提取致敏风险
  String? extractAllergyRisk() {
    if (description == null) return null;

    final allergyMatch =
        RegExp(r'\*\*致敏风险\*\*[：:]\s*(.+)').firstMatch(description!);
    if (allergyMatch != null) {
      return allergyMatch.group(1)?.trim();
    }
    return null;
  }

  /// 是否为有毒植物
  bool isToxicPlant() {
    final toxicity = extractToxicityLevel();
    if (toxicity == null) return false;
    return toxicity.contains('有毒') || toxicity.contains('剧毒');
  }

  /// 是否为剧毒植物
  bool isHighlyToxic() {
    final toxicity = extractToxicityLevel();
    if (toxicity == null) return false;
    return toxicity.contains('剧毒');
  }
}
