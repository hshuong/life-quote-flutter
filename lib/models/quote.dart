// lib/models/quote.dart

/// Model đại diện cho một quote
/// NOTE: Không có imageIndex nữa, dùng id để tính gradient!
class Quote {
  final int? id;          // ID tự động tăng từ database
  final String text;      // Nội dung câu quote
  //final String author;    // Tác giả
  final String? author; // Cho phép null
  final int categoryId;   // ID của category (Foreign Key)
  final bool isFavorite;  // Quote có được yêu thích không

  Quote({
    this.id,
    required this.text,
    //required this.author,
    this.author,
    required this.categoryId,
    this.isFavorite = false, // Mặc định không phải favorite
  });

  /// Chuyển từ Map (data từ database) sang object Quote
  factory Quote.fromMap(Map<String, dynamic> map) {
    return Quote(
      id: map['id'] as int?,
      text: map['text'] as String,
      //author: map['author'] as String,
      author: map['author'] as String?, // Xử lý null
      categoryId: map['category_id'] as int,
      // SQLite lưu boolean dạng INTEGER (0 = false, 1 = true)
      isFavorite: (map['is_favorite'] as int) == 1,
    );
  }

  // Chuyển từ object Quote sang Map để lưu vào database
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'text': text,
      'author': author,
      'category_id': categoryId,
      // Chuyển boolean thành INTEGER cho SQLite
      'is_favorite': isFavorite ? 1 : 0,
    };
  }

  /// Tạo bản copy của Quote với một số thuộc tính thay đổi
  /// Hữu ích khi cần toggle favorite mà không tạo object mới hoàn toàn
  Quote copyWith({
    int? id,
    String? text,
    String? author,
    int? categoryId,
    bool? isFavorite,
  }) {
    return Quote(
      id: id ?? this.id,
      text: text ?? this.text,
      author: author ?? this.author,
      categoryId: categoryId ?? this.categoryId,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }

  /// Override toString để dễ debug
  @override
  String toString() {
    return 'Quote{id: $id, text: "${text.substring(0, 20)}...", author: $author, isFavorite: $isFavorite}';
  }
}