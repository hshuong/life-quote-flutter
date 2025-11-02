// lib/database/database_helper.dart

import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter/services.dart';
import '../models/category.dart';
import '../models/quote.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('life_quotes_english.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    try {
      // Lấy đường dẫn thư mục database trên thiết bị
      final dbPath = await getDatabasesPath();
      final path = join(dbPath, filePath);

      debugPrint('📁 Database path: $path');

      // Kiểm tra xem database đã tồn tại chưa
      final exists = await databaseExists(path);

      if (!exists) {
        // Database chưa tồn tại -> Copy từ assets
        debugPrint('📦 Database not found, copying from assets...');

        try {
          // Đảm bảo thư mục cha tồn tại
          await Directory(dirname(path)).create(recursive: true);
        } catch (_) {
          // Thư mục có thể đã tồn tại
        }

        // Đọc file database từ assets
        ByteData data = await rootBundle.load('assets/databases/$filePath');
        List<int> bytes = data.buffer.asUint8List(
          data.offsetInBytes,
          data.lengthInBytes,
        );

        // Ghi file vào đường dẫn database
        await File(path).writeAsBytes(bytes, flush: true);

        debugPrint('✅ Database copied successfully from assets');
      } else {
        debugPrint('✅ Database already exists, using existing database');
      }

      // Mở database
      final db = await openDatabase(
        path,
        version: 1,
        onOpen: (db) async {
          debugPrint('🔓 Database opened successfully');
          // Kiểm tra số lượng data
          await _checkDatabaseContent(db);
        },
      );

      return db;
    } catch (e) {
      debugPrint('❌ Error initializing database: $e');
      rethrow;
    }
  }

  /// Kiểm tra nội dung database sau khi mở
  Future<void> _checkDatabaseContent(Database db) async {
    try {
      // Đếm số categories
      final categoryCount = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM categories'),
      );
      debugPrint('📚 Found $categoryCount categories');

      // Đếm số quotes
      final quoteCount = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM quotes'),
      );
      debugPrint('📖 Found $quoteCount quotes');

      // Đếm số favorites
      final favoriteCount = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM quotes WHERE is_favorite = 1'),
      );
      debugPrint('❤️ Found $favoriteCount favorite quotes');
    } catch (e) {
      debugPrint('⚠️ Error checking database content: $e');
    }
  }

  // ===== CATEGORY OPERATIONS =====

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

  Future<List<Quote>> getQuotesByCategory(int categoryId) async {
    try {
      final db = await database;
      final result = await db.query(
        'quotes',
        where: 'category_id = ?',
        whereArgs: [categoryId],
        orderBy: 'id ASC',
      );
      //debugPrint('📖 Raw data: $result'); // In dữ liệu để debug
      debugPrint('📖 Loaded ${result.length} quotes for category $categoryId');
      return result.map((json) => Quote.fromMap(json)).toList();
    } catch (e) {
      debugPrint('❌ Error loading quotes: $e');
      rethrow;
    }
  }

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
      debugPrint('❌ Error loading favorites: $e');
      rethrow;
    }
  }

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

  Future<int> getQuoteCountByCategory(int categoryId) async {
    try {
      final db = await database;
      final result = await db.rawQuery(
        'SELECT COUNT(*) as count FROM quotes WHERE category_id = ?',
        [categoryId],
      );
      final count = Sqflite.firstIntValue(result) ?? 0;
      return count;
    } catch (e) {
      debugPrint('❌ Error counting quotes: $e');
      return 0;
    }
  }

  Future<int> deleteQuote(int id) async {
    try {
      final db = await database;
      final count = await db.delete('quotes', where: 'id = ?', whereArgs: [id]);
      debugPrint('🗑️ Deleted quote (ID: $id)');
      return count;
    } catch (e) {
      debugPrint('❌ Error deleting quote: $e');
      rethrow;
    }
  }

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

  Future<Quote?> getRandomQuote() async {
    try {
      final db = await database;
      final result = await db.rawQuery(
        'SELECT * FROM quotes ORDER BY RANDOM() LIMIT 1',
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

  /// Xóa database (hữu ích khi cần reset hoặc update database mới)
  Future<void> deleteDatabase() async {
    try {
      final dbPath = await getDatabasesPath();
      final path = join(dbPath, 'life_quotes.db');

      await databaseFactory.deleteDatabase(path);
      _database = null;

      debugPrint('🗑️ Database deleted successfully');
    } catch (e) {
      debugPrint('❌ Error deleting database: $e');
    }
  }

  /// Đóng database
  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
      debugPrint('🔒 Database closed');
    }
  }
}
