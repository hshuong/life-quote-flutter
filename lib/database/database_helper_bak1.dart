// lib/database/database_helper.dart

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
// Thay đổi từ:
//import 'package:flutter/foundation.dart';
// Thành:
import 'package:flutter/foundation.dart' show debugPrint;
import '../models/category.dart';
import '../models/quote.dart';

/// Class quản lý SQLite database
/// Sử dụng Singleton pattern - chỉ có 1 instance duy nhất
class DatabaseHelper {
  // Singleton instance
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  // Private constructor
  DatabaseHelper._init();

  /// Getter để lấy database
  /// Nếu chưa có thì tạo mới, có rồi thì trả về instance hiện tại
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('life_quotes.db');
    return _database!;
  }

  /// Khởi tạo database
  Future<Database> _initDB(String filePath) async {
    try {
      // Lấy đường dẫn thư mục database của thiết bị
      final dbPath = await getDatabasesPath();
      final path = join(dbPath, filePath);

      debugPrint('📁 Database path: $path');

      // Mở database, nếu chưa có thì tạo mới
      return await openDatabase(
        path,
        version: 1,                    // Version của database schema
        onCreate: _createDB,            // Callback khi tạo database lần đầu
        onUpgrade: _upgradeDB,          // Callback khi nâng cấp version
      );
    } catch (e) {
      debugPrint('❌ Error initializing database: $e');
      rethrow;
    }
  }

  /// Tạo tables khi database được tạo lần đầu
  Future<void> _createDB(Database db, int version) async {
    debugPrint('🔨 Creating database tables...');

    // Tạo bảng categories
    await db.execute('''
      CREATE TABLE categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        icon TEXT NOT NULL
      )
    ''');
    debugPrint('✅ Table "categories" created');

    // Tạo bảng quotes
    // NOTE: Không có column image_index nữa!
    await db.execute('''
      CREATE TABLE quotes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        text TEXT NOT NULL,
        author TEXT NOT NULL,
        category_id INTEGER NOT NULL,
        is_favorite INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (category_id) REFERENCES categories (id) ON DELETE CASCADE
      )
    ''');
    debugPrint('✅ Table "quotes" created');

    // Tạo index để tăng tốc độ truy vấn
    await db.execute('CREATE INDEX idx_category_id ON quotes(category_id)');
    await db.execute('CREATE INDEX idx_is_favorite ON quotes(is_favorite)');
    debugPrint('✅ Indexes created');

    // Thêm dữ liệu mẫu
    await _insertSampleData(db);
  }

  /// Xử lý upgrade database khi tăng version
  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    debugPrint('🔄 Upgrading database from v$oldVersion to v$newVersion');
    // Thêm logic migration ở đây nếu cần trong tương lai
  }

  /// Thêm dữ liệu mẫu vào database
  Future<void> _insertSampleData(Database db) async {
    debugPrint('📝 Inserting sample data...');

    // Thêm categories
    final categories = [
      {'name': 'Yourself', 'icon': '🧘'},
      {'name': 'Attitude', 'icon': '😊'},
      {'name': 'Action', 'icon': '⚡'},
      {'name': 'Hardwork', 'icon': '💪'},
      {'name': 'Failure', 'icon': '🎯'},
      {'name': 'Success', 'icon': '🏆'},
      {'name': 'Motivation', 'icon': '🔥'},
      {'name': 'Life', 'icon': '🌟'},
    ];

    for (var category in categories) {
      await db.insert('categories', category);
    }
    debugPrint('✅ Inserted ${categories.length} categories');

    // Thêm sample quotes
    // NOTE: Không có image_index trong data!
    final sampleQuotes = [
      {
        'text': 'The only way to do great work is to love what you do.',
        'author': 'Steve Jobs',
        'category_id': 3, // Action
        'is_favorite': 0,
      },
      {
        'text': 'Success is not final, failure is not fatal: it is the courage to continue that counts.',
        'author': 'Winston Churchill',
        'category_id': 5, // Failure
        'is_favorite': 0,
      },
      {
        'text': 'Believe you can and you\'re halfway there.',
        'author': 'Theodore Roosevelt',
        'category_id': 7, // Motivation
        'is_favorite': 0,
      },
      {
        'text': 'Your attitude, not your aptitude, will determine your altitude.',
        'author': 'Zig Ziglar',
        'category_id': 2, // Attitude
        'is_favorite': 0,
      },
      {
        'text': 'Hard work beats talent when talent doesn\'t work hard.',
        'author': 'Tim Notke',
        'category_id': 4, // Hardwork
        'is_favorite': 0,
      },
      {
        'text': 'The future belongs to those who believe in the beauty of their dreams.',
        'author': 'Eleanor Roosevelt',
        'category_id': 8, // Life
        'is_favorite': 0,
      },
      {
        'text': 'It does not matter how slowly you go as long as you do not stop.',
        'author': 'Confucius',
        'category_id': 3, // Action
        'is_favorite': 0,
      },
      {
        'text': 'Everything you\'ve ever wanted is on the other side of fear.',
        'author': 'George Addair',
        'category_id': 1, // Yourself
        'is_favorite': 0,
      },
    ];

    for (var quote in sampleQuotes) {
      await db.insert('quotes', quote);
    }
    debugPrint('✅ Inserted ${sampleQuotes.length} quotes');
  }

  // ===== CATEGORY OPERATIONS =====

  /// Lấy tất cả categories, sắp xếp theo tên
  Future<List<Category>> getAllCategories() async {
    try {
      final db = await database;
      final result = await db.query('categories', orderBy: 'name ASC');
      debugPrint('📚 Loaded ${result.length} categories');
      return result.map((json) => Category.fromMap(json)).toList();
    } catch (e) {
      debugPrint('❌ Error loading categories: $e');
      rethrow;
    }
  }

  /// Thêm category mới
  Future<int> insertCategory(Category category) async {
    try {
      final db = await database;
      final id = await db.insert('categories', category.toMap());
      debugPrint('✅ Inserted category: ${category.name} (ID: $id)');
      return id;
    } catch (e) {
      debugPrint('❌ Error inserting category: $e');
      rethrow;
    }
  }

  // ===== QUOTE OPERATIONS =====

  /// Lấy tất cả quotes theo category
  Future<List<Quote>> getQuotesByCategory(int categoryId) async {
    try {
      final db = await database;
      final result = await db.query(
        'quotes',
        where: 'category_id = ?',
        whereArgs: [categoryId],
        orderBy: 'id ASC',
      );
      debugPrint('📖 Loaded ${result.length} quotes for category $categoryId');
      return result.map((json) => Quote.fromMap(json)).toList();
    } catch (e) {
      debugPrint('❌ Error loading quotes: $e');
      rethrow;
    }
  }
  
  /// Lấy tất cả quotes yêu thích
  Future<List<Quote>> getFavoriteQuotes() async {	
	try {
      final db = await database;
      final result = await db.query(
        'quotes',
        where: 'is_favorite = ?',
        whereArgs: [1],
        orderBy: 'id DESC',
      );
      debugPrint('❤️ Loaded ${result.length} favorite quotes');
      return result.map((json) => Quote.fromMap(json)).toList();
    } catch (e) {
      debugPrint('❌ Error loading favorite quotes: $e');
      rethrow;
    }
	
  }

  /// Thêm quote mới
  Future<int> insertQuote(Quote quote) async {
    try {
      final db = await database;
      final id = await db.insert('quotes', quote.toMap());
      debugPrint('✅ Inserted quote (ID: $id)');
      return id;
    } catch (e) {
      debugPrint('❌ Error inserting quote: $e');
      rethrow;
    }
  }

  /// Cập nhật quote
  Future<int> updateQuote(Quote quote) async {
    try {
      final db = await database;
      final count = await db.update(
        'quotes',
        quote.toMap(),
        where: 'id = ?',
        whereArgs: [quote.id],
      );
      debugPrint('✅ Updated quote (ID: ${quote.id})');
      return count;
    } catch (e) {
      debugPrint('❌ Error updating quote: $e');
      rethrow;
    }
  }

  /// Toggle trạng thái yêu thích của quote
  Future<void> toggleFavorite(int quoteId, bool isFavorite) async {
    try {
      final db = await database;
      await db.update(
        'quotes',
        {'is_favorite': isFavorite ? 1 : 0},
        where: 'id = ?',
        whereArgs: [quoteId],
      );
      debugPrint('💝 Toggled favorite for quote $quoteId: $isFavorite');
    } catch (e) {
      debugPrint('❌ Error toggling favorite: $e');
      rethrow;
    }
  }

  /// Đếm số lượng quotes trong một category
  Future<int> getQuoteCountByCategory(int categoryId) async {
    try {
      final db = await database;
      final result = await db.rawQuery(
        'SELECT COUNT(*) as count FROM quotes WHERE category_id = ?',
        [categoryId],
      );
      final count = Sqflite.firstIntValue(result) ?? 0;
      debugPrint('🔢 Category $categoryId has $count quotes');
      return count;
    } catch (e) {
      debugPrint('❌ Error counting quotes: $e');
      return 0;
    }
  }

  /// Xóa quote
  Future<int> deleteQuote(int id) async {
    try {
      final db = await database;
      final count = await db.delete(
        'quotes',
        where: 'id = ?',
        whereArgs: [id],
      );
      debugPrint('🗑️ Deleted quote (ID: $id)');
      return count;
    } catch (e) {
      debugPrint('❌ Error deleting quote: $e');
      rethrow;
    }
  }

  /// Tìm kiếm quotes theo text hoặc author
  Future<List<Quote>> searchQuotes(String query) async {
    try {
      if (query.isEmpty) return [];
      
      final db = await database;
      final result = await db.query(
        'quotes',
        where: 'text LIKE ? OR author LIKE ?',
        whereArgs: ['%$query%', '%$query%'],
        orderBy: 'id DESC',
        limit: 50,
      );
      debugPrint('🔍 Found ${result.length} quotes matching "$query"');
      return result.map((json) => Quote.fromMap(json)).toList();
    } catch (e) {
      debugPrint('❌ Error searching quotes: $e');
      return [];
    }
  }

  /// Lấy một quote ngẫu nhiên
  Future<Quote?> getRandomQuote() async {
    try {
      final db = await database;
      final result = await db.rawQuery(
        'SELECT * FROM quotes ORDER BY RANDOM() LIMIT 1'
      );
      
      if (result.isNotEmpty) {
        debugPrint('🎲 Got random quote');
        return Quote.fromMap(result.first);
      }
      return null;
    } catch (e) {
      debugPrint('❌ Error getting random quote: $e');
      return null;
    }
  }

  /// Đóng database
  Future<void> close() async {
    final db = await database;
    await db.close();
    debugPrint('🔒 Database closed');
  }
}