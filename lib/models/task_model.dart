class Task {
  String id;
  String title;
  bool isCompleted;
  bool isHighPriority;
  String column;

  Task({
    required this.id,
    required this.title,
    this.isCompleted = false,
    this.isHighPriority = false,
    this.column = 'To Do',
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'isCompleted': isCompleted,
      'isHighPriority': isHighPriority,
      'column': column,
    };
  }

  factory Task.fromJson(Map<String, dynamic> json) {
    // Validate and sanitize input data
    if (json['id'] == null || json['id'].toString().isEmpty) {
      throw ArgumentError('Task ID cannot be null or empty');
    }
    
    if (json['title'] == null || json['title'].toString().trim().isEmpty) {
      throw ArgumentError('Task title cannot be null or empty');
    }
    
    // Sanitize title to prevent XSS and UI issues
    String sanitizedTitle = json['title'].toString().trim();
    // Remove any potential HTML/script tags
    sanitizedTitle = sanitizedTitle.replaceAll(RegExp(r'<[^>]*>'), '');
    // Limit title length to prevent UI overflow
    if (sanitizedTitle.length > 200) {
      sanitizedTitle = sanitizedTitle.substring(0, 197) + '...';
    }
    
    // Validate column name
    String column = json['column'] ?? 'To Do';
    const validColumns = ['To Do', 'In Progress', 'Done', 'Eisenhower'];
    if (!validColumns.contains(column)) {
      column = 'To Do'; // Default to safe value
    }
    
    return Task(
      id: json['id'].toString(),
      title: sanitizedTitle,
      isCompleted: json['isCompleted'] == true,
      isHighPriority: json['isHighPriority'] == true,
      column: column,
    );
  }

  @override
  String toString() {
    String prefix = '';
    if (isCompleted) prefix += '[Completed] ';
    if (isHighPriority) prefix += '[High Priority] ';
    return '$prefix$title';
  }

  Task copyWith({
    String? id,
    String? title,
    bool? isCompleted,
    bool? isHighPriority,
    String? column,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      isCompleted: isCompleted ?? this.isCompleted,
      isHighPriority: isHighPriority ?? this.isHighPriority,
      column: column ?? this.column,
    );
  }
}
