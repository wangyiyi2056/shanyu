/// 训练计划等级
enum TrainingLevel {
  beginner, // 新手
  intermediate, // 中级
  advanced, // 高级
}

/// 训练类型
enum TrainingType {
  cardio, // 有氧耐力
  strength, // 力量训练
  flexibility, // 柔韧性
  hiking, // 徒步模拟
  rest, // 休息/恢复
}

/// 训练日
class TrainingDay {
  final int weekNumber;
  final int dayNumber;
  final TrainingType type;
  final String title;
  final String description;
  final int durationMinutes;
  final int? targetElevation; // 目标爬升（米）
  final double? targetDistance; // 目标距离（公里）
  final bool isRestDay;

  const TrainingDay({
    required this.weekNumber,
    required this.dayNumber,
    required this.type,
    required this.title,
    required this.description,
    required this.durationMinutes,
    this.targetElevation,
    this.targetDistance,
    this.isRestDay = false,
  });
}

/// 训练计划
class TrainingPlan {
  final String id;
  final String name;
  final String description;
  final TrainingLevel level;
  final int durationWeeks;
  final List<TrainingDay> schedule;
  final String? goalRoute; // 目标路线
  final DateTime createdAt;

  const TrainingPlan({
    required this.id,
    required this.name,
    required this.description,
    required this.level,
    required this.durationWeeks,
    required this.schedule,
    this.goalRoute,
    required this.createdAt,
  });

  /// 获取指定周的训练
  List<TrainingDay> getWeekSchedule(int week) {
    return schedule.where((d) => d.weekNumber == week).toList();
  }

  /// 已完成天数（假设传入当前进度）
  int completedDays(int currentWeek, int currentDay) {
    var count = 0;
    for (final day in schedule) {
      if (day.weekNumber < currentWeek) {
        count++;
      } else if (day.weekNumber == currentWeek && day.dayNumber <= currentDay) {
        count++;
      }
    }
    return count;
  }

  String get levelLabel => switch (level) {
    TrainingLevel.beginner => '新手',
    TrainingLevel.intermediate => '中级',
    TrainingLevel.advanced => '高级',
  };
}
