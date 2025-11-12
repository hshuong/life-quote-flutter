// lib/utils/responsive.dart

import 'package:flutter/material.dart';

/// Helper class để xử lý responsive design
/// Hỗ trợ tất cả loại màn hình: phone, fold, flip, tablet
class Responsive {
  /// Breakpoints cho các loại màn hình
  static const double mobileSmall =
      320; // Phone nhỏ (iPhone SE, Samsung Galaxy Flip khi gập)
  static const double mobile = 375; // Phone thông thường
  static const double mobileLarge = 428; // Phone lớn (iPhone Pro Max)
  static const double foldUnfolded = 512; // Fold phone khi mở (Galaxy Z Fold)
  static const double tablet = 768; // Tablet
  static const double desktop = 1024; // Desktop/Tablet lớn

  /// Lấy chiều rộng màn hình
  static double width(BuildContext context) {
    return MediaQuery.of(context).size.width;
  }

  /// Lấy chiều cao màn hình
  static double height(BuildContext context) {
    return MediaQuery.of(context).size.height;
  }

  /// Kiểm tra loại màn hình
  static bool isMobileSmall(BuildContext context) {
    return width(context) < mobile;
  }

  static bool isMobile(BuildContext context) {
    return width(context) >= mobile && width(context) < tablet;
  }

  static bool isFoldUnfolded(BuildContext context) {
    return width(context) >= foldUnfolded && width(context) < tablet;
  }

  static bool isTablet(BuildContext context) {
    return width(context) >= tablet && width(context) < desktop;
  }

  static bool isDesktop(BuildContext context) {
    return width(context) >= desktop;
  }

  /// Lấy số cột cho grid dựa trên màn hình
  static int gridColumns(BuildContext context) {
    final w = width(context);
    if (w < mobile) return 2; // Phone nhỏ: 2 cột
    if (w < foldUnfolded) return 2; // Phone: 2 cột
    if (w < tablet) return 3; // Fold mở: 3 cột
    if (w < desktop) return 4; // Tablet: 4 cột
    return 5; // Desktop: 5 cột
  }

  /// Font size responsive
  static double fontSize(BuildContext context, double baseSize) {
    final w = width(context);
    if (w < mobileSmall) return baseSize * 0.85; // Giảm 15% cho màn hình rất nhỏ
    if (w < mobile) return baseSize * 0.9; // Giảm 10%
    if (w < tablet) return baseSize; // Size gốc
    if (w < desktop) return baseSize * 1.1; // Tăng 10% cho tablet
    return baseSize * 1.2; // Tăng 20% cho desktop
  }

  /// Padding responsive
  static double padding(BuildContext context, double basePadding) {
    final w = width(context);
    if (w < mobileSmall) return basePadding * 0.75;
    if (w < mobile) return basePadding * 0.875;
    if (w < tablet) return basePadding;
    if (w < desktop) return basePadding * 1.25;
    return basePadding * 1.5;
  }

  /// Grid spacing responsive
  static double gridSpacing(BuildContext context) {
    final w = width(context);
    if (w < mobileSmall) return 12;
    if (w < mobile) return 14;
    if (w < tablet) return 16;
    if (w < desktop) return 20;
    return 24;
  }

  /// Card aspect ratio cho category cards
  /// Đổi thành chiều cao > chiều rộng (portrait card)
  // static double categoryCardAspectRatio(BuildContext context) {
  //   final w = width(context);
  //   if (w < mobileSmall) return 0.95; // Tỷ lệ rộng:cao = 0.7 (card cao hơn)
  //   if (w < mobile) return 0.96; // Card hơi cao. Màn ngoài fold 5
  //   if (w < tablet) return 1; // Phone/Fold Màn trong fold 5
  //   return 1; // Tablet/Desktop
  // }

  static double categoryCardAspectRatio(BuildContext context) {
    final w = width(context);
    if (w < mobileSmall) return 0.85;  // Card dọc rõ
    if (w < mobile) return 0.88;       // Portrait đẹp
    if (w < tablet) return 0.90;       // Cân đối
    return 0.8;                        // Tablet/Desktop
  }

  /// Card title style với line height tốt hơn

  // Style cho title bình thường
  static TextStyle categoryCardTitleStyle(BuildContext context) {
    return TextStyle(
      color: Colors.white,
      fontSize: categoryCardTitleSize(context),
      fontWeight: FontWeight.bold,
      height: 1.6,
    );
  }

  // Style cho title highlight (nếu cần)
  static TextStyle categoryCardTitleStyleHighlight(BuildContext context) {
    return categoryCardTitleStyle(context).copyWith(
      color: Colors.yellow,
      shadows: [Shadow(blurRadius: 10, color: Colors.black)],
    );
  }

  // Style cho subtitle (nếu cần)
  static TextStyle categoryCardSubtitleStyle(BuildContext context) {
    return TextStyle(
      color: Colors.white70,
      fontSize: categoryCardTitleSize(context) * 0.8,
      height: 1.3,
    );
  }

  /// Card title font size (giảm để fit 2 dòng)
  static double categoryCardTitleSize(BuildContext context) {
    final w = width(context);
    if (w < mobileSmall) return 14;
    if (w < mobile) return 15;
    if (w < tablet) return 16;
    return 17;
  }

  /// Card icon size
  static double categoryCardIconSize(BuildContext context) {
    final w = width(context);
    if (w < mobileSmall) return 40;
    if (w < mobile) return 42;
    if (w < tablet) return 44;
    return 48;
  }

  /// Quote card height
  static double quoteCardMinHeight(BuildContext context) {
    final w = width(context);
    if (w < mobileSmall) return 90;
    if (w < mobile) return 100;
    if (w < tablet) return 110;
    return 120;
  }

  /// Detail screen text size
  static double quoteDetailTextSize(BuildContext context) {
    final w = width(context);
    if (w < mobileSmall) return 20;
    if (w < mobile) return 22;
    if (w < foldUnfolded) return 24;
    if (w < tablet) return 26;
    if (w < desktop) return 28;
    return 32;
  }

  /// Bottom navigation visibility (ẩn trên tablet/desktop lớn)
  static bool showBottomNav(BuildContext context) {
    return width(context) < tablet;
  }

  /// Max width cho content (tránh quá rộng trên màn hình lớn)
  static double maxContentWidth(BuildContext context) {
    final w = width(context);
    if (w < tablet) return w; // Phone: full width
    if (w < desktop) return w * 0.9; // Tablet: 90%
    return 1200; // Desktop: max 1200px
  }

  /// Orientation check
  static bool isLandscape(BuildContext context) {
    return MediaQuery.of(context).orientation == Orientation.landscape;
  }

  static bool isPortrait(BuildContext context) {
    return MediaQuery.of(context).orientation == Orientation.portrait;
  }

  /// Safe area padding
  static EdgeInsets safeAreaPadding(BuildContext context) {
    return MediaQuery.of(context).padding;
  }

  /// Device type description (for debugging)
  static String deviceType(BuildContext context) {
    final w = width(context);
    if (w < mobileSmall) return 'Mobile Small (${w.toInt()}px)';
    if (w < mobile) return 'Mobile (${w.toInt()}px)';
    if (w < foldUnfolded) return 'Mobile Large (${w.toInt()}px)';
    if (w < tablet) return 'Fold Unfolded (${w.toInt()}px)';
    if (w < desktop) return 'Tablet (${w.toInt()}px)';
    return 'Desktop (${w.toInt()}px)';
  }
}
