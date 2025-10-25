// lib/utils/image_manager.dart

import 'package:flutter/material.dart';

/// Class quản lý background gradients cho quotes
/// Thay vì lưu 1000+ ảnh, ta dùng 20 gradients và xoay vòng bằng quoteId % 20
class ImageManager {
  /// Danh sách 20 gradient backgrounds
  /// Mỗi gradient gồm 2 màu: [màu bắt đầu, màu kết thúc]
  static final List<List<Color>> backgroundGradients = [
    // Gradient 0: Purple Dream
    [const Color(0xFF667eea), const Color(0xFF764ba2)],
    
    // Gradient 1: Sunset Orange
    [const Color(0xFFf83600), const Color(0xFFf9d423)],
    
    // Gradient 2: Ocean Blue
    [const Color(0xFF2E3192), const Color(0xFF1BFFFF)],
    
    // Gradient 3: Green Beach
    [const Color(0xFF02AAB0), const Color(0xFF00CDAC)],
    
    // Gradient 4: Pink Flavour
    [const Color(0xFF800080), const Color(0xFFffc0cb)],
    
    // Gradient 5: Peachy
    [const Color(0xFFED4264), const Color(0xFFFFEDBC)],
    
    // Gradient 6: Summer Vibes
    [const Color(0xFF22c1c3), const Color(0xFFfdbb2d)],
    
    // Gradient 7: Burning Orange
    [const Color(0xFFFF416C), const Color(0xFFFF4B2B)],
    
    // Gradient 8: Royal Night
    [const Color(0xFF141E30), const Color(0xFF243B55)],
    
    // Gradient 9: Mauve
    [const Color(0xFF42275a), const Color(0xFF734b6d)],
    
    // Gradient 10: Citrus Peel
    [const Color(0xFFFDC830), const Color(0xFFF37335)],
    
    // Gradient 11: Fresh Turboscent
    [const Color(0xFFF1F2B5), const Color(0xFF135058)],
    
    // Gradient 12: Green to Dark
    [const Color(0xFF283c86), const Color(0xFF45a247)],
    
    // Gradient 13: Red Mist
    [const Color(0xFF000000), const Color(0xFFe74c3c)],
    
    // Gradient 14: Teal Love
    [const Color(0xFFAAFFA9), const Color(0xFF11FFBD)],
    
    // Gradient 15: Sweet Morning
    [const Color(0xFFFF5F6D), const Color(0xFFFFC371)],
    
    // Gradient 16: Netflix Dark
    [const Color(0xFF8E0E00), const Color(0xFF1F1C18)],
    
    // Gradient 17: Purple Paradise
    [const Color(0xFF1D2B64), const Color(0xFFF8CDDA)],
    
    // Gradient 18: Cosmic Fusion
    [const Color(0xFFff00cc), const Color(0xFF333399)],
    
    // Gradient 19: Moon Purple
    [const Color(0xFF4e54c8), const Color(0xFF8f94fb)],
  ];

  /// Lấy gradient colors dựa trên quoteId
  /// 
  /// Sử dụng modulo (%) để xoay vòng qua 20 gradients:
  /// - Quote ID 1  → 1 % 20 = 1  → Gradient 1
  /// - Quote ID 47 → 47 % 20 = 7 → Gradient 7
  /// - Quote ID 100 → 100 % 20 = 0 → Gradient 0
  static List<Color> getGradientForQuote(int quoteId) {
    final index = quoteId % backgroundGradients.length;
    return backgroundGradients[index];
  }

  /// Tạo BoxDecoration với gradient cho background của quote
  /// 
  /// Trả về decoration có thể dùng trực tiếp cho Container
  static BoxDecoration getBackgroundDecoration(int quoteId) {
    final colors = getGradientForQuote(quoteId);
    
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,      // Gradient từ góc trên trái
        end: Alignment.bottomRight,    // Đến góc dưới phải
        colors: colors,
        stops: const [0.0, 1.0],       // Điểm chuyển màu mượt mà
      ),
    );
  }

  /// Tính màu text phù hợp dựa trên độ sáng của gradient
  /// 
  /// Nếu background sáng → dùng text đen
  /// Nếu background tối → dùng text trắng
  /// Đảm bảo text luôn dễ đọc trên mọi background
  static Color getTextColor(int quoteId) {
    final colors = getGradientForQuote(quoteId);
    
    // Tính độ sáng (luminance) của cả 2 màu trong gradient
    final brightness1 = colors[0].computeLuminance();
    final brightness2 = colors[1].computeLuminance();
    
    // Tính độ sáng trung bình
    final averageBrightness = (brightness1 + brightness2) / 2;
    
    // Nếu brightness > 0.5 (sáng) → text đen
    // Ngược lại (tối) → text trắng
    return averageBrightness > 0.5 ? Colors.black87 : Colors.white;
  }

  /// Lấy màu cho category card (dùng cho HomeScreen)
  /// Map tên category với màu gradient phù hợp
  static List<Color> getColorsForCategory(String categoryName) {
    final colorMap = {
      'Yourself': [const Color(0xFF667eea), const Color(0xFF764ba2)],
      'Attitude': [const Color(0xFFf83600), const Color(0xFFf9d423)],
      'Action': [const Color(0xFF2E3192), const Color(0xFF1BFFFF)],
      'Hardwork': [const Color(0xFFED4264), const Color(0xFFFFEDBC)],
      'Failure': [const Color(0xFFFF416C), const Color(0xFFFF4B2B)],
      'Success': [const Color(0xFFFDC830), const Color(0xFFF37335)],
      'Motivation': [const Color(0xFF02AAB0), const Color(0xFF00CDAC)],
      'Life': [const Color(0xFF4e54c8), const Color(0xFF8f94fb)],
    };

    // Trả về màu từ map, hoặc màu mặc định nếu không tìm thấy
    return colorMap[categoryName] ?? 
           [const Color(0xFF667eea), const Color(0xFF764ba2)];
  }
}