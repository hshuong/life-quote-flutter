// lib/models/category.dart

// Model đại diện cho một category (loại quote)
// VD: Action, Attitude, Life, Success...
class Category {
  final int? id;        // ID tự động tăng từ database (nullable vì khi tạo mới chưa có ID)
  final String name;    // Tên category: "Action", "Attitude"...
  final String icon;    // Icon hoặc emoji: "⚡", "😊"...

  Category({
    this.id,
    required this.name,
    required this.icon,
  });

  // Chuyển từ Map (data từ database) sang object Category
  // Database trả về data dạng Map<String, dynamic>
  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: map['id'] as int?,
      name: map['name'] as String,
      icon: map['icon'] as String,
    );
  }

  // Chuyển từ object Category sang Map để lưu vào database
  // INSERT hoặc UPDATE cần data dạng Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'icon': icon,
    };
  }

  /// Override toString để dễ debug
  @override
  String toString() {
    return 'Category{id: $id, name: $name, icon: $icon}';
  }
}