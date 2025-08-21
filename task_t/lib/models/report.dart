class ProgressReport {
  final int id;
  final String interneeName;
  final String generatedBy;
  final String periodStart;
  final String periodEnd;
  final int tasksCompleted;
  final int tasksPending;
  final String overallPerformance;
  final String? comments;
  final DateTime createdAt;

  ProgressReport({
    required this.id,
    required this.interneeName,
    required this.generatedBy,
    required this.periodStart,
    required this.periodEnd,
    required this.tasksCompleted,
    required this.tasksPending,
    required this.overallPerformance,
    this.comments,
    required this.createdAt,
  });

  factory ProgressReport.fromJson(Map<String, dynamic> json) {
    return ProgressReport(
      id: json['id'],
      interneeName: json['internee_name'],
      generatedBy: json['generated_by'],
      periodStart: json['period_start'],
      periodEnd: json['period_end'],
      tasksCompleted: json['tasks_completed'],
      tasksPending: json['tasks_pending'],
      overallPerformance: json['overall_performance'],
      comments: json['comments'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}