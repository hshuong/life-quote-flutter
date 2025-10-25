// lib/providers/quote_provider.dart

//import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import '../models/category.dart' as app_models;
import '../models/quote.dart';
import '../database/database_helper.dart';

/// Provider quản lý state toàn bộ app
/// Sử dụng ChangeNotifier để notify UI khi có thay đổi
class QuoteProvider with ChangeNotifier {
  // Data storage
  List<app_models.Category> _categories = [];
  final Map<int, List<Quote>> _quotesByCategory = {};  // Cache quotes theo category
  List<Quote> _favoriteQuotes = [];
  
  // Loading states
  bool _isLoadingCategories = false;
  bool _isLoadingQuotes = false;
  
  // Error handling
  String? _error;

  // Getters - cho phép UI đọc data
  List<app_models.Category> get categories => _categories;
  List<Quote> get favoriteQuotes => _favoriteQuotes;
  bool get isLoadingCategories => _isLoadingCategories;
  bool get isLoadingQuotes => _isLoadingQuotes;
  String? get error => _error;

  /// Lấy quotes cho một category từ cache
  /// Nếu chưa có trong cache thì trả về list rỗng
  List<Quote> getQuotesForCategory(int categoryId) {
    return _quotesByCategory[categoryId] ?? [];
  }

/// Load tất cả categories từ database
  /// Chỉ load 1 lần, các lần sau dùng cache
  Future<void> loadCategories() async {
    // Nếu đã load rồi thì không load lại
    if (_categories.isNotEmpty) {
      debugPrint('📚 Categories already loaded, using cache');
      return;
    }

    // ✅ FIX: Kiểm tra nếu đang loading thì không load lại
    if (_isLoadingCategories) {
      debugPrint('📚 Categories already loading, skipping...');
      return;
    }

    _isLoadingCategories = true;
    _error = null;
    
    // ✅ FIX: Dùng SchedulerBinding để tránh notify trong build phase
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners(); // Báo UI update (hiển thị loading)
    });

    try {
      _categories = await DatabaseHelper.instance.getAllCategories();
      _isLoadingCategories = false;
      debugPrint('✅ Provider: Loaded ${_categories.length} categories');
      notifyListeners(); // Báo UI update (hiển thị data)
    } catch (e) {
      _error = 'Failed to load categories: $e';
      _isLoadingCategories = false;
      debugPrint('❌ Provider: $_error');
      notifyListeners(); // Báo UI update (hiển thị error)
    }
  }

  /// Load quotes cho một category
  /// Sử dụng cache: nếu đã load rồi thì không load lại
  Future<void> loadQuotesForCategory(int categoryId) async {
    // Check cache trước
    if (_quotesByCategory.containsKey(categoryId)) {
      debugPrint('📖 Quotes for category $categoryId already cached');
      return;
    }

    _isLoadingQuotes = true;
    _error = null;
    notifyListeners();

    try {
      final quotes = await DatabaseHelper.instance.getQuotesByCategory(categoryId);
      _quotesByCategory[categoryId] = quotes;
      _isLoadingQuotes = false;
      debugPrint('✅ Provider: Loaded ${quotes.length} quotes for category $categoryId');
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load quotes: $e';
      _isLoadingQuotes = false;
      debugPrint('❌ Provider: $_error');
      notifyListeners();
    }
  }

  /// Load tất cả favorite quotes
  Future<void> loadFavoriteQuotes() async {
    try {
      _favoriteQuotes = await DatabaseHelper.instance.getFavoriteQuotes();
      debugPrint('❤️ Provider: Loaded ${_favoriteQuotes.length} favorites');
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Provider: Failed to load favorites: $e');
    }
  }

  /// Toggle favorite status của một quote
  /// Cập nhật cả database và cache
  Future<void> toggleFavorite(Quote quote) async {
    try {
      final newStatus = !quote.isFavorite;
      
      // Update database
      await DatabaseHelper.instance.toggleFavorite(quote.id!, newStatus);
      debugPrint('💝 Provider: Toggled favorite for quote ${quote.id}');

      // Update cache trong _quotesByCategory
      if (_quotesByCategory.containsKey(quote.categoryId)) {
        final quotes = _quotesByCategory[quote.categoryId]!;
        final index = quotes.indexWhere((q) => q.id == quote.id);
        if (index != -1) {
          quotes[index] = quote.copyWith(isFavorite: newStatus);
        }
      }

      // Reload favorite list
      await loadFavoriteQuotes();
      
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Provider: Failed to toggle favorite: $e');
    }
  }

  /// Thêm quote mới vào database và cache
  Future<bool> addQuote(Quote quote) async {
    try {
      final id = await DatabaseHelper.instance.insertQuote(quote);
      debugPrint('✅ Provider: Added quote with ID $id');
      
      // Thêm vào cache nếu category đã được load
      if (_quotesByCategory.containsKey(quote.categoryId)) {
        final newQuote = quote.copyWith(id: id);
        _quotesByCategory[quote.categoryId]!.add(newQuote);
        notifyListeners();
      }
      
      return true;
    } catch (e) {
      debugPrint('❌ Provider: Failed to add quote: $e');
      return false;
    }
  }

  /// Xóa quote khỏi database và cache
  Future<bool> deleteQuote(Quote quote) async {
    try {
      await DatabaseHelper.instance.deleteQuote(quote.id!);
      debugPrint('🗑️ Provider: Deleted quote ${quote.id}');
      
      // Xóa khỏi cache
      if (_quotesByCategory.containsKey(quote.categoryId)) {
        _quotesByCategory[quote.categoryId]!
            .removeWhere((q) => q.id == quote.id);
      }
      
      // Xóa khỏi favorites nếu có
      if (quote.isFavorite) {
        _favoriteQuotes.removeWhere((q) => q.id == quote.id);
      }
      
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('❌ Provider: Failed to delete quote: $e');
      return false;
    }
  }

  /// Clear toàn bộ cache
  /// Hữu ích khi cần refresh data
  void clearCache() {
    _quotesByCategory.clear();
    _categories.clear();
    debugPrint('🧹 Provider: Cache cleared');
    notifyListeners();
  }

  /// Tìm kiếm quotes
  Future<List<Quote>> searchQuotes(String query) async {
    if (query.isEmpty) return [];
    
    try {
      return await DatabaseHelper.instance.searchQuotes(query);
    } catch (e) {
      debugPrint('❌ Provider: Search failed: $e');
      return [];
    }
  }

  /// Lấy quote ngẫu nhiên (cho daily quote feature)
  Future<Quote?> getRandomQuote() async {
    try {
      return await DatabaseHelper.instance.getRandomQuote();
    } catch (e) {
      debugPrint('❌ Provider: Failed to get random quote: $e');
      return null;
    }
  }
}