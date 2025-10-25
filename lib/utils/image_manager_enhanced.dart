// lib/utils/image_manager_enhanced.dart
// COMPLETE FIX: Improved gradients + weighted luminance

import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Enhanced version với 3-color gradients, animations, và decorative elements
class ImageManagerEnhanced {
  /// UPGRADE: 3-color gradients với màu được tối ưu cho khả năng đọc
  static final List<List<Color>> backgroundGradients = [
    // Gradient 0: Purple Dream (enhanced)
    [
      const Color(0xFF667eea),
      const Color(0xFF764ba2),
      const Color(0xFF5b42b8),
    ],
    
    // Gradient 1: Sunset Orange (enhanced)
    [
      const Color(0xFFf83600),
      const Color(0xFFfe8c00),
      const Color(0xFFf9d423),
    ],
    
    // Gradient 2: Ocean Blue (enhanced)
    [
      const Color(0xFF2E3192),
      const Color(0xFF1baaaa),
      const Color(0xFF1BFFFF),
    ],
    
    // Gradient 3: Green Beach (enhanced)
    [
      const Color(0xFF02AAB0),
      const Color(0xFF00cdac),
      const Color(0xFF00e7c3),
    ],
    
    // Gradient 4: Pink Flavour (enhanced)
    [
      const Color(0xFF800080),
      const Color(0xFFc060c0),
      const Color(0xFFffc0cb),
    ],
    
    // Gradient 5: Peachy (enhanced)
    [
      const Color(0xFFED4264),
      const Color(0xFFff8080),
      const Color(0xFFFFEDBC),
    ],
    
    // Gradient 6: Summer Vibes (enhanced)
    [
      const Color(0xFF22c1c3),
      const Color(0xFF88dd88),
      const Color(0xFFfdbb2d),
    ],
    
    // Gradient 7: Burning Orange (enhanced)
    [
      const Color(0xFFFF416C),
      const Color(0xFFff5555),
      const Color(0xFFFF4B2B),
    ],
    
    // Gradient 8: Royal Night (enhanced)
    [
      const Color(0xFF141E30),
      const Color(0xFF1a2a45),
      const Color(0xFF243B55),
    ],
    
    // Gradient 9: Mauve (enhanced)
    [
      const Color(0xFF42275a),
      const Color(0xFF5a3a64),
      const Color(0xFF734b6d),
    ],
    
    // Gradient 10: Citrus Peel (enhanced)
    [
      const Color(0xFFFDC830),
      const Color(0xFFf99c33),
      const Color(0xFFF37335),
    ],
    
    // ✅ FIXED: Gradient 11 - Fresh Turboscent (tối hơn để dễ đọc)
    [
      const Color(0xFFb8ba85), // Vàng ô liu đậm (từ F1F2B5)
      const Color(0xFF6a9070), // Xanh lá đậm (từ 8ab88e)
      const Color(0xFF135058), // Xanh đậm tối
    ],
    
    // Gradient 12: Green to Dark (enhanced) - GIỮ NGUYÊN
    [
      const Color(0xFF283c86),
      const Color(0xFF367268),
      const Color(0xFF45a247),
    ],
    
    // Gradient 13: Red Mist (enhanced)
    [
      const Color(0xFF000000),
      const Color(0xFF6b2626),
      const Color(0xFFe74c3c),
    ],
    
    // Gradient 14: Teal Love (enhanced)
    [
      const Color(0xFFAAFFA9),
      const Color(0xFF66ffbb),
      const Color(0xFF11FFBD),
    ],
    
    // Gradient 15: Sweet Morning (enhanced)
    [
      const Color(0xFFFF5F6D),
      const Color(0xFFff8888),
      const Color(0xFFFFC371),
    ],
    
    // Gradient 16: Netflix Dark (enhanced)
    [
      const Color(0xFF8E0E00),
      const Color(0xFF4a1010),
      const Color(0xFF1F1C18),
    ],
    
    // Gradient 17: Purple Paradise (enhanced)
    [
      const Color(0xFF1D2B64),
      const Color(0xFF8866aa),
      const Color(0xFFF8CDDA),
    ],
    
    // Gradient 18: Cosmic Fusion (enhanced)
    [
      const Color(0xFFff00cc),
      const Color(0xFF9933bb),
      const Color(0xFF333399),
    ],
    
    // Gradient 19: Moon Purple (enhanced)
    [
      const Color(0xFF4e54c8),
      const Color(0xFF6f74db),
      const Color(0xFF8f94fb),
    ],
  ];

  /// Lấy 3-color gradient cho quote
  static List<Color> getGradientForQuote(int quoteId) {
    final index = quoteId % backgroundGradients.length;
    return backgroundGradients[index];
  }

  /// ENHANCED: BoxDecoration với 3 colors và stops tùy chỉnh
  static BoxDecoration getBackgroundDecoration(int quoteId) {
    final colors = getGradientForQuote(quoteId);
    
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: colors,
        stops: const [0.0, 0.5, 1.0],
      ),
    );
  }

  /// ENHANCED: Animated gradient decoration với rotation
  static BoxDecoration getAnimatedDecoration(int quoteId, double animationValue) {
    final colors = getGradientForQuote(quoteId);
    
    final angle = animationValue * math.pi / 4;
    
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment(
          math.cos(angle),
          math.sin(angle),
        ),
        end: Alignment(
          -math.cos(angle),
          -math.sin(angle),
        ),
        colors: colors,
        stops: const [0.0, 0.5, 1.0],
      ),
    );
  }

  /// ✅ IMPROVED: Tính màu text với weighted luminance
  /// Ưu tiên màu đầu (50%) và giữa (30%) vì chiếm diện tích lớn hơn
  static Color getTextColor(int quoteId) {
    final colors = getGradientForQuote(quoteId);
    
    // Tính độ sáng của từng màu
    final brightness1 = colors[0].computeLuminance();
    final brightness2 = colors[1].computeLuminance();
    final brightness3 = colors.length > 2 ? colors[2].computeLuminance() : brightness2;
    
    // Weighted average: 50% màu đầu + 30% màu giữa + 20% màu cuối
    final weightedBrightness = 
        (brightness1 * 0.5) + 
        (brightness2 * 0.3) + 
        (brightness3 * 0.2);
    
    // Threshold 0.45 để chữ đen xuất hiện sớm hơn trên nền sáng
    return weightedBrightness > 0.45 ? Colors.black87 : Colors.white;
  }

  /// ENHANCED: Category colors với 3 màu
  static List<Color> getColorsForCategory(String categoryName) {
    final colorMap = {
      'Yourself': [
        const Color(0xFF667eea),
        const Color(0xFF6f6fc8),
        const Color(0xFF764ba2),
      ],
      'Attitude': [
        const Color(0xFFf83600),
        const Color(0xFFfe8c00),
        const Color(0xFFf9d423),
      ],
      'Action': [
        const Color(0xFF2E3192),
        const Color(0xFF1baaaa),
        const Color(0xFF1BFFFF),
      ],
      'Hardwork': [
        const Color(0xFFED4264),
        const Color(0xFFff8080),
        const Color(0xFFFFEDBC),
      ],
      'Failure': [
        const Color(0xFFFF416C),
        const Color(0xFFff5555),
        const Color(0xFFFF4B2B),
      ],
      'Success': [
        const Color(0xFFFDC830),
        const Color(0xFFf99c33),
        const Color(0xFFF37335),
      ],
      'Motivation': [
        const Color(0xFF02AAB0),
        const Color(0xFF00cdac),
        const Color(0xFF00e7c3),
      ],
      'Life': [
        const Color(0xFF4e54c8),
        const Color(0xFF6f74db),
        const Color(0xFF8f94fb),
      ],
    };

    return colorMap[categoryName] ?? [
      const Color(0xFF667eea),
      const Color(0xFF6f6fc8),
      const Color(0xFF764ba2),
    ];
  }

  /// NEW: Tạo decorative geometric shapes cho background
  static Widget buildDecorativeShapes({
    required int quoteId,
    required Size screenSize,
  }) {
    final colors = getGradientForQuote(quoteId);
    final shapeColor = colors[0].withValues(alpha: 0.1);

    return Stack(
      children: [
        // Circle top right
        Positioned(
          top: -50,
          right: -50,
          child: Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: shapeColor,
            ),
          ),
        ),
        
        // Circle bottom left
        Positioned(
          bottom: -80,
          left: -80,
          child: Container(
            width: 250,
            height: 250,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: shapeColor,
            ),
          ),
        ),
        
        // Square middle right
        Positioned(
          top: screenSize.height * 0.4,
          right: -30,
          child: Transform.rotate(
            angle: math.pi / 4,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: colors[1].withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// NEW: Shimmer effect overlay
  static Widget buildShimmerOverlay({
    required Animation<double> animation,
    required List<Color> colors,
  }) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withValues(alpha: 0.0),
                Colors.white.withValues(alpha: 0.1 * animation.value),
                Colors.white.withValues(alpha: 0.0),
              ],
              stops: [
                0.0,
                animation.value,
                1.0,
              ],
            ),
          ),
        );
      },
    );
  }

  /// NEW: Pulse animation decoration
  static BoxDecoration getPulseDecoration({
    required int quoteId,
    required double scale,
  }) {
    final colors = getGradientForQuote(quoteId);
    
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: colors,
        stops: const [0.0, 0.5, 1.0],
      ),
      boxShadow: [
        BoxShadow(
          color: colors[0].withValues(alpha: 0.4 * scale),
          blurRadius: 20 * scale,
          spreadRadius: 5 * scale,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  /// NEW: Radial gradient variant (cho categories)
  static BoxDecoration getRadialDecoration(String categoryName) {
    final colors = getColorsForCategory(categoryName);
    
    return BoxDecoration(
      gradient: RadialGradient(
        center: Alignment.topLeft,
        radius: 1.5,
        colors: colors,
        stops: const [0.0, 0.5, 1.0],
      ),
      borderRadius: BorderRadius.circular(20),
    );
  }

  /// NEW: Mesh-like gradient (iOS 18 style) - Simulated
  static BoxDecoration getMeshGradient(int quoteId) {
    final colors = getGradientForQuote(quoteId);
    
    return BoxDecoration(
      gradient: RadialGradient(
        center: Alignment.center,
        radius: 2.0,
        colors: [
          colors[0],
          colors[1],
          colors[2],
          colors[0].withValues(alpha: 0.8),
        ],
        stops: const [0.0, 0.3, 0.7, 1.0],
      ),
    );
  }
}