// Updated Task model with assignedToId field
class Task {
  final int id;
  final String title;
  final String? description;
  final String status;
  final DateTime? deadline;
  final String? createdBy;
  final String? assignedTo;
  final int? assignedToId; // Add this field
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Task({
    required this.id,
    required this.title,
    this.description,
    required this.status,
    this.deadline,
    this.createdBy,
    this.assignedTo,
    this.assignedToId, // Add this
    this.createdAt,
    this.updatedAt,
  });

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      status: json['status'],
      deadline: json['deadline'] != null 
          ? DateTime.parse(json['deadline']) 
          : null,
      createdBy: json['created_by'],
      assignedTo: json['assigned_to'],
      assignedToId: json['assigned_to_id'], // Add this mapping
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : null,
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'status': status,
      'deadline': deadline?.toIso8601String(),
      'created_by': createdBy,
      'assigned_to': assignedTo,
      'assigned_to_id': assignedToId, // Add this
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}