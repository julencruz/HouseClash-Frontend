enum TaskStatus {
  open,
  assigned,
  pendingReview,
  approved,
  autoApproved,
  disputed;

  static TaskStatus fromString(String value) => switch (value) {
    'OPEN'           => TaskStatus.open,
    'ASSIGNED'       => TaskStatus.assigned,
    'PENDING_REVIEW' => TaskStatus.pendingReview,
    'APPROVED'       => TaskStatus.approved,
    'AUTO_APPROVED'  => TaskStatus.autoApproved,
    'DISPUTED'       => TaskStatus.disputed,
    _                => TaskStatus.open,
  };

  String get label => switch (this) {
    TaskStatus.open          => 'Disponible',
    TaskStatus.assigned      => 'Asignada',
    TaskStatus.pendingReview => 'Pendiente revisión',
    TaskStatus.approved      => 'Aprobada',
    TaskStatus.autoApproved  => 'Auto-aprobada',
    TaskStatus.disputed      => 'Disputada',
  };
}

enum Effort {
  low,
  medium,
  high;

  static Effort fromString(String value) => switch (value) {
    'LOW'    => Effort.low,
    'MEDIUM' => Effort.medium,
    'HIGH'   => Effort.high,
    _        => Effort.low,
  };

  int get baseKudos => switch (this) {
    Effort.low    => 2,
    Effort.medium => 4,
    Effort.high   => 8,
  };
}

class CategorySummary {
  final int id;
  final String name;
  final bool isDefault;

  const CategorySummary({
    required this.id,
    required this.name,
    required this.isDefault,
  });

  factory CategorySummary.fromJson(Map<String, dynamic> json) => CategorySummary(
    id: json['id'] as int,
    name: json['name'] as String,
    isDefault: json['isDefault'] as bool,
  );
}

class TaskModel {
  final int        id;
  final String     title;
  final String?    description;
  final Effort     effort;
  final TaskStatus status;
  final int        kudosValue;
  final int?       assignedTo;
  final int        houseId;
  final CategorySummary category;
  final bool       isForced;
  final String?    recurrence;
  final DateTime?  deadline;
  final DateTime   createdAt;
  final DateTime?  completedAt;

  const TaskModel({
    required this.id,
    required this.title,
    this.description,
    required this.effort,
    required this.status,
    required this.kudosValue,
    this.assignedTo,
    required this.houseId,
    required this.category,
    required this.isForced,
    this.recurrence,
    this.deadline,
    required this.createdAt,
    this.completedAt,
  });

  factory TaskModel.fromJson(Map<String, dynamic> json) => TaskModel(
    id:          json['id'] as int,
    title:       json['title'] as String,
    description: json['description'] as String?,
    effort:      Effort.fromString(json['effort'] as String),
    status:      TaskStatus.fromString(json['status'] as String),
    kudosValue:  json['kudosValue'] as int,
    assignedTo:  json['assignedTo'] as int?,
    houseId:     json['houseId'] as int,
    category:    CategorySummary.fromJson(json['category'] as Map<String, dynamic>),
    isForced:    json['isForced'] as bool,
    recurrence:  json['recurrence'] as String?,
    deadline:    json['deadline'] != null ? DateTime.parse(json['deadline']) : null,
    createdAt:   DateTime.parse(json['createdAt']),
    completedAt: json['completedAt'] != null ? DateTime.parse(json['completedAt']) : null,
  );

  TaskModel copyWith({TaskStatus? status, int? assignedTo}) => TaskModel(
    id:          id,
    title:       title,
    description: description,
    effort:      effort,
    status:      status ?? this.status,
    kudosValue:  kudosValue,
    assignedTo:  assignedTo ?? this.assignedTo,
    houseId:     houseId,
    category:    category,
    isForced:    isForced,
    recurrence:  recurrence,
    deadline:    deadline,
    createdAt:   createdAt,
    completedAt: completedAt,
  );
}