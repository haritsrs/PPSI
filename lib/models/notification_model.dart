class NotificationModel {
  final String id;
  final String title;
  final String message;
  final String type; // 'transaction', 'product', 'stock', 'system'
  final bool isRead;
  final DateTime createdAt;
  final Map<String, dynamic>? data; // Additional data like transactionId, productId, etc.

  NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    this.isRead = false,
    required this.createdAt,
    this.data,
  });

  factory NotificationModel.fromFirebase(Map<String, dynamic> data) {
    Map<String, dynamic>? additionalData;
    if (data['data'] != null && data['data'] is Map) {
      additionalData = Map<String, dynamic>.from(data['data'] as Map);
    }
    
    return NotificationModel(
      id: data['id'] as String? ?? data['key'] as String? ?? '',
      title: data['title'] as String? ?? '',
      message: data['message'] as String? ?? '',
      type: data['type'] as String? ?? 'system',
      isRead: data['isRead'] as bool? ?? false,
      createdAt: data['createdAt'] != null
          ? DateTime.tryParse(data['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      data: additionalData,
    );
  }

  Map<String, dynamic> toFirebase() {
    return {
      'title': title,
      'message': message,
      'type': type,
      'isRead': isRead,
      'createdAt': createdAt.toIso8601String(),
      if (data != null) 'data': data,
    };
  }

  NotificationModel copyWith({
    String? id,
    String? title,
    String? message,
    String? type,
    bool? isRead,
    DateTime? createdAt,
    Map<String, dynamic>? data,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      data: data ?? this.data,
    );
  }
}


