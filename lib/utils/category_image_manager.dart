// lib/utils/category_image_manager.dart

import 'package:flutter/material.dart';

class CategoryImageManager {
  // Map category name to image asset path
  static const Map<String, String> categoryImages = {
    'Life': 'assets/images/categories/i117146059.jpg',
    'Yourself': 'assets/images/categories/i483724081.jpg',
    'Attitude': 'assets/images/categories/i498063665.jpg',
    'Goal': 'assets/images/categories/i498309616.jpg',
    'Action': 'assets/images/categories/i526705622.jpg',
    'Confidence': 'assets/images/categories/i530185374.jpg',
    'Hard work': 'assets/images/categories/i536291400.jpg',
    'Failure': 'assets/images/categories/i537621432.jpg',
    'Stay Strong Through Failures': 'assets/images/categories/i694050758.jpg',
    'Positive': 'assets/images/categories/i809971888.jpg',
    'Time': 'assets/images/categories/i860528958.jpg',
    'Power': 'assets/images/categories/i879845502.jpg',
    'Accuracy': 'assets/images/categories/i884343584.jpg',
    'Change': 'assets/images/categories/i898869110.jpg',
    'Hard Times': 'assets/images/categories/i899836048.jpg',
    'Being Real': 'assets/images/categories/i921341724.jpg',
    'Keep Trying': 'assets/images/categories/i937057490.jpg',
    'Encouraging': 'assets/images/categories/i968886386.jpg',
    'Inspiration': 'assets/images/categories/i1053405882.jpg',
    'Experience': 'assets/images/categories/i1082411378.jpg',
    'Business': 'assets/images/categories/i1130883848.jpg',
    'SomeTimes': 'assets/images/categories/i1192260535.jpg',
    'Mistake': 'assets/images/categories/i1268487061.jpg',
    'Forgiveness': 'assets/images/categories/i1270042705.jpg',
    'Happiness': 'assets/images/categories/i1277015766.jpg',
    'People': 'assets/images/categories/i1292399669.jpg',
    'Fake People': 'assets/images/categories/i1308867983.jpg',
    'Giveup': 'assets/images/categories/i1369254957.jpg',
    'Funny and Smile': 'assets/images/categories/i1458782106.jpg',
    'Present Future Past': 'assets/images/categories/i2133340831.jpg',
    'Appreciation': 'assets/images/categories/i1473454504.jpg',
    'Love': 'assets/images/categories/i1477148178.jpg',
    'Short Quotes': 'assets/images/categories/i1493704782.jpg',
    'Wisdom': 'assets/images/categories/i1696167872.jpg',
    'Fitness and Workout': 'assets/images/categories/i1739024655.jpg',
    'Proverbs': 'assets/images/categories/i1791589607.jpg',
  };

  // Fallback gradient colors if image not found
  static const Map<String, List<Color>> fallbackGradients = {
    'Life': [Color(0xFF4e54c8), Color(0xFF8f94fb)],
    'Yourself': [Color(0xFF667eea), Color(0xFF764ba2)],
    'Attitude': [Color(0xFFf83600), Color(0xFFf9d423)],
    'Goal': [Color(0xFF56ab2f), Color(0xFFa8e063)],
    'Action': [Color(0xFF2E3192), Color(0xFF1BFFFF)],
    'Confidence': [Color(0xFF2193b0), Color(0xFF6dd5ed)],
    'Hard work': [Color(0xFFED4264), Color(0xFFFFEDBC)],
    'Failure': [Color(0xFFFF416C), Color(0xFFFF4B2B)],
    'Stay Strong Through Failures': [Color(0xFF283048), Color(0xFF859398)],
    'Positive': [Color(0xFF02AAB0), Color(0xFF00CDAC)],
    'Time': [Color(0xFFee9ca7), Color(0xFFffdde1)],
    'Power': [Color(0xFF232526), Color(0xFF414345)],
    'Accuracy': [Color(0xFF00c6ff), Color(0xFF0072ff)],
    'Change': [Color(0xFF8E2DE2), Color(0xFF4A00E0)],
    'Hard Times': [Color(0xFF8360c3), Color(0xFF2ebf91)],
    'Being Real': [Color(0xFF2196f3), Color(0xFFf44336)],
    'Keep Trying': [Color(0xFF56CCF2), Color(0xFF2F80ED)],
    'Encouraging': [Color(0xFFF7971E), Color(0xFFFFD200)],
    'Inspiration': [Color(0xFF00b09b), Color(0xFF96c93d)],
    'Experience': [Color(0xFF1c92d2), Color(0xFFf2fcfe)],
    'Business': [Color(0xFF373B44), Color(0xFF4286f4)],
    'SomeTimes': [Color(0xFFff9966), Color(0xFFff5e62)],
    'Mistake': [Color(0xFF6a11cb), Color(0xFF2575fc)],
    'Forgiveness': [Color(0xFFf7971e), Color(0xFFffd200)],
    'Happiness': [Color(0xFF56ab2f), Color(0xFFa8e063)],
    'People': [Color(0xFF283048), Color(0xFF859398)],
    'Fake People': [Color(0xFF606c88), Color(0xFF3f4c6b)],
    'Giveup': [Color(0xFFbdc3c7), Color(0xFF2c3e50)],
    'Funny and Smile': [Color(0xFFf7797d), Color(0xFFFBD786)],
    'Present Future Past': [Color(0xFFa1c4fd), Color(0xFFc2e9fb)],
    'Appreciation': [Color(0xFF8360c3), Color(0xFF2ebf91)],
    'Love': [Color(0xFFFF6B9D), Color(0xFFC06C84)],
    'Short Quotes': [Color(0xFF02AAB0), Color(0xFF00CDAC)],
    'Wisdom': [Color(0xFF1f4037), Color(0xFF99f2c8)],
    'Fitness and Workout': [Color(0xFFf12711), Color(0xFFf5af19)],
    'Proverbs': [Color(0xFF232526), Color(0xFF414345)],
  };

  // Get image path for category
  static String? getImagePath(String categoryName) {
    return categoryImages[categoryName];
  }

  // Get fallback gradient colors
  static List<Color> getFallbackGradient(String categoryName) {
    return fallbackGradients[categoryName] ??
        [const Color(0xFF667eea), const Color(0xFF764ba2)];
  }

  // Check if image exists for category
  static bool hasImage(String categoryName) {
    return categoryImages.containsKey(categoryName);
  }
}
