import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hiking_assistant/core/theme/app_colors.dart';
import 'package:hiking_assistant/core/theme/app_spacing.dart';
import 'package:hiking_assistant/core/theme/app_typography.dart';
import 'package:hiking_assistant/features/plant/domain/entities/plant_identification_result.dart';
import 'package:hiking_assistant/features/plant/presentation/providers/plant_provider.dart';

/// 植物识别页面
///
/// 支持从外部传入图片字节进行识别，或显示历史识别结果
class PlantIdentificationScreen extends ConsumerStatefulWidget {
  final Uint8List? initialImageBytes;
  final String? initialMediaType;

  const PlantIdentificationScreen({
    super.key,
    this.initialImageBytes,
    this.initialMediaType,
  });

  @override
  ConsumerState<PlantIdentificationScreen> createState() =>
      _PlantIdentificationScreenState();
}

class _PlantIdentificationScreenState
    extends ConsumerState<PlantIdentificationScreen> {
  @override
  void initState() {
    super.initState();
    // 如果有初始图片，自动进行识别
    if (widget.initialImageBytes != null && widget.initialMediaType != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(plantIdentificationProvider.notifier).identifyFromBytes(
              widget.initialImageBytes!,
              widget.initialMediaType!,
            );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(plantIdentificationProvider);

    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: AppBar(
        backgroundColor: AppColors.paper,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.ink),
          onPressed: () => context.pop(),
        ),
        title: Text(
          '植物识别',
          style: AppTypography.title.copyWith(
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        actions: [
          if (state.result != null || state.selectedImageBytes != null)
            IconButton(
              icon: const Icon(Icons.refresh, color: AppColors.ink),
              onPressed: () {
                ref.read(plantIdentificationProvider.notifier).clear();
              },
            ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 图片展示区域
              _ImagePreview(
                imageBytes: state.selectedImageBytes,
                isLoading: state.isLoading,
              ),
              const SizedBox(height: AppSpacing.lg),

              // 识别结果
              if (state.result != null) ...[
                _ResultCard(result: state.result!),
              ],

              // 错误信息
              if (state.errorMessage != null) ...[
                _ErrorCard(message: state.errorMessage!),
              ],

              // 空状态提示
              if (state.selectedImageBytes == null &&
                  state.result == null &&
                  state.errorMessage == null) ...[
                const _EmptyState(),
              ],

              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
      ),
    );
  }
}

/// 图片预览区域
class _ImagePreview extends StatelessWidget {
  final Uint8List? imageBytes;
  final bool isLoading;

  const _ImagePreview({
    this.imageBytes,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 280,
      decoration: BoxDecoration(
        color: AppColors.paperDark,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
          color: AppColors.inkMuted.withValues(alpha: 0.2),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (imageBytes != null)
              Image.memory(
                imageBytes!,
                fit: BoxFit.cover,
              )
            else
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.local_florist,
                    size: 64,
                    color: AppColors.inkMuted.withValues(alpha: 0.4),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    '暂无图片',
                    style: AppTypography.body.copyWith(
                      color: AppColors.inkMuted,
                    ),
                  ),
                ],
              ),
            if (isLoading)
              Container(
                color: Colors.black.withValues(alpha: 0.4),
                child: const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 3,
                      ),
                      SizedBox(height: AppSpacing.md),
                      Text(
                        'AI 识别中...',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// 识别结果卡片
class _ResultCard extends StatelessWidget {
  final PlantIdentificationResult result;

  const _ResultCard({required this.result});

  @override
  Widget build(BuildContext context) {
    final plantName = result.extractPlantName();
    final family = result.extractFamily();
    final features = result.extractFeatures();
    final toxicity = result.extractToxicityLevel();
    final edibility = result.extractEdibility();
    final allergyRisk = result.extractAllergyRisk();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 植物名称头部
        if (plantName != null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1B4D3E), Color(0xFF2E7D62)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              boxShadow: AppColors.softShadow(blur: 12, dy: 4),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.local_florist,
                      color: Colors.white,
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '识别结果',
                      style: AppTypography.label.copyWith(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (result.isDemo) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '演示模式',
                          style: AppTypography.dataSmall.copyWith(
                            color: Colors.white,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  plantName,
                  style: AppTypography.display.copyWith(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (family != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    family,
                    style: AppTypography.body.copyWith(
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                  ),
                ],
              ],
            ),
          ),

        const SizedBox(height: AppSpacing.lg),

        // 安全提示卡片（高优先级显示）
        if (toxicity != null)
          _SafetyCard(
            toxicity: toxicity,
            edibility: edibility,
            allergyRisk: allergyRisk,
            isToxic: result.isToxicPlant(),
            isHighlyToxic: result.isHighlyToxic(),
          ),

        const SizedBox(height: AppSpacing.lg),

        // 特征描述
        if (features != null)
          _InfoSection(
            title: '特征描述',
            icon: Icons.description_outlined,
            content: features,
          ),

        const SizedBox(height: AppSpacing.lg),

        // 完整识别结果
        if (result.description != null && result.description!.isNotEmpty)
          _InfoSection(
            title: '详细信息',
            icon: Icons.article_outlined,
            content: result.description!,
            isMarkdown: true,
          ),
      ],
    );
  }
}

/// 安全提示卡片
class _SafetyCard extends StatelessWidget {
  final String toxicity;
  final String? edibility;
  final String? allergyRisk;
  final bool isToxic;
  final bool isHighlyToxic;

  const _SafetyCard({
    required this.toxicity,
    this.edibility,
    this.allergyRisk,
    required this.isToxic,
    required this.isHighlyToxic,
  });

  @override
  Widget build(BuildContext context) {
    final backgroundColor = isHighlyToxic
        ? const Color(0xFFFEF2F2)
        : isToxic
            ? const Color(0xFFFFFBEB)
            : const Color(0xFFF0FDF4);
    final borderColor = isHighlyToxic
        ? const Color(0xFFEF4444)
        : isToxic
            ? const Color(0xFFF59E0B)
            : const Color(0xFF22C55E);
    final iconColor = borderColor;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: borderColor.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isToxic ? Icons.warning_amber : Icons.check_circle,
                color: iconColor,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                '安全评估',
                style: AppTypography.title.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: iconColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          _SafetyRow(label: '毒性等级', value: toxicity, highlight: isToxic),
          if (edibility != null)
            _SafetyRow(label: '可食用性', value: edibility ?? '', highlight: false),
          if (allergyRisk != null)
            _SafetyRow(label: '致敏风险', value: allergyRisk ?? '', highlight: false),
          if (isToxic) ...[
            const SizedBox(height: AppSpacing.sm),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: borderColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning, color: iconColor, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '此植物可能有毒，请勿触摸或食用。如遇不适，请立即就医。',
                      style: AppTypography.bodySmall.copyWith(
                        color: iconColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SafetyRow extends StatelessWidget {
  final String label;
  final String value;
  final bool highlight;

  const _SafetyRow({
    required this.label,
    required this.value,
    required this.highlight,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: AppTypography.body.copyWith(
              color: AppColors.inkLight,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: AppTypography.body.copyWith(
              color: highlight ? const Color(0xFFDC2626) : AppColors.ink,
              fontWeight: highlight ? FontWeight.w700 : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// 信息展示区域
class _InfoSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final String content;
  final bool isMarkdown;

  const _InfoSection({
    required this.title,
    required this.icon,
    required this.content,
    this.isMarkdown = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        boxShadow: AppColors.softShadow(blur: 8, dy: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: AppColors.forest),
              const SizedBox(width: 8),
              Text(
                title,
                style: AppTypography.title.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          _buildContent(),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (isMarkdown) {
      // 简单的 Markdown 文本解析
      final lines = content.split('\n');
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: lines.map((line) {
          final trimmed = line.trim();
          if (trimmed.startsWith('### ')) {
            return Padding(
              padding: const EdgeInsets.only(top: AppSpacing.md, bottom: AppSpacing.sm),
              child: Text(
                trimmed.substring(4),
                style: AppTypography.title.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: AppColors.forest,
                ),
              ),
            );
          } else if (trimmed.startsWith('**') && trimmed.contains('**:')) {
            // 粗体标签: 值
            final parts = trimmed.split('**: ');
            if (parts.length == 2) {
              final label = parts[0].replaceAll('**', '');
              final value = parts[1].replaceAll('**', '');
              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: RichText(
                  text: TextSpan(
                    style: AppTypography.body.copyWith(color: AppColors.ink),
                    children: [
                      TextSpan(
                        text: '$label: ',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      TextSpan(text: value),
                    ],
                  ),
                ),
              );
            }
          } else if (trimmed.startsWith('- ')) {
            return Padding(
              padding: const EdgeInsets.only(left: 8, bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('• ', style: TextStyle(fontSize: 14)),
                  Expanded(
                    child: Text(
                      trimmed.substring(2),
                      style: AppTypography.body.copyWith(color: AppColors.inkLight),
                    ),
                  ),
                ],
              ),
            );
          } else if (trimmed.isEmpty) {
            return const SizedBox(height: 4);
          }
          return Text(
            trimmed,
            style: AppTypography.body.copyWith(color: AppColors.inkLight),
          );
        }).toList(),
      );
    }

    return Text(
      content,
      style: AppTypography.body.copyWith(
        color: AppColors.inkLight,
        height: 1.5,
      ),
    );
  }
}

/// 错误卡片
class _ErrorCard extends StatelessWidget {
  final String message;

  const _ErrorCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
          color: const Color(0xFFEF4444).withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Color(0xFFEF4444)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: AppTypography.body.copyWith(
                color: const Color(0xFFDC2626),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 空状态
class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        boxShadow: AppColors.softShadow(blur: 8, dy: 2),
      ),
      child: Column(
        children: [
          Icon(
            Icons.eco,
            size: 64,
            color: AppColors.forest.withValues(alpha: 0.3),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            '拍照识别植物',
            style: AppTypography.title.copyWith(
              fontWeight: FontWeight.w700,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '在聊天中发送"这是什么植物"，或从相册选择照片，AI 将帮您识别山区植物并提供安全提示。',
            textAlign: TextAlign.center,
            style: AppTypography.body.copyWith(
              color: AppColors.inkMuted,
              height: 1.5,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          _TipRow(
            icon: Icons.warning_amber,
            text: '自动检测有毒植物并警告',
          ),
          const SizedBox(height: AppSpacing.sm),
          _TipRow(
            icon: Icons.info_outline,
            text: '提供食用性和致敏风险评估',
          ),
          const SizedBox(height: AppSpacing.sm),
          _TipRow(
            icon: Icons.nature,
            text: '专注中国北方山区常见植物',
          ),
        ],
      ),
    );
  }
}

class _TipRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _TipRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: AppColors.forest),
        const SizedBox(width: 8),
        Text(
          text,
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.inkLight,
          ),
        ),
      ],
    );
  }
}
