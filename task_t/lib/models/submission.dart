class TaskSubmission {
  final int id;
  final String description;
  final String? attachmentUrl;
  final DateTime submittedAt;
  final String submittedBy;

  TaskSubmission({
    required this.id,
    required this.description,
    this.attachmentUrl,
    required this.submittedAt,
    required this.submittedBy,
  });

  factory TaskSubmission.fromJson(Map<String, dynamic> json) {
    return TaskSubmission(
      id: json['id'],
      description: json['description'],
      attachmentUrl: json['attachment_url'],
      submittedAt: DateTime.parse(json['submitted_at']),
      submittedBy: json['submitted_by'],
    );
  }
}