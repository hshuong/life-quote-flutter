// lib/screens/home_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import '../models/category.dart';
import '../providers/quote_provider.dart';
import '../utils/image_manager.dart';
import '../utils/responsive.dart';
import 'quote_list_screen.dart';
import 'quote_detail_screen.dart';
import 'favorites_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<QuoteProvider>().loadCategories();
      context.read<QuoteProvider>().loadFavoriteQuotes();
    });
  }

  Future<void> _showRandomQuote() async {
    final provider = context.read<QuoteProvider>();
    final randomQuote = await provider.getRandomQuote();

    if (randomQuote == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No quotes available'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => QuoteDetailScreen(
            quotes: [randomQuote],
            initialIndex: 0,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Responsive: ẩn bottom nav trên tablet/desktop
    final showBottomNav = Responsive.showBottomNav(context);

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(
          _selectedIndex == 0 ? 'Life Quotes' : 'Favorites',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: Responsive.fontSize(context, 24),
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.deepPurple,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.shuffle),
            onPressed: _showRandomQuote,
            tooltip: 'Random Quote',
            iconSize: Responsive.fontSize(context, 24),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              final provider = context.read<QuoteProvider>();
              provider.clearCache();
              provider.loadCategories();
              provider.loadFavoriteQuotes();
            },
            tooltip: 'Refresh',
            iconSize: Responsive.fontSize(context, 24),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: Responsive.maxContentWidth(context),
          ),
          child: _selectedIndex == 0 
              ? _buildCategoriesView() 
              : const FavoritesScreen(),
        ),
      ),
      // Responsive: chỉ hiển thị bottom nav trên mobile
      bottomNavigationBar: showBottomNav
          ? BottomNavigationBar(
              currentIndex: _selectedIndex,
              onTap: (index) => setState(() => _selectedIndex = index),
              selectedItemColor: Colors.deepPurple,
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.category),
                  label: 'Categories',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.favorite),
                  label: 'Favorites',
                ),
              ],
            )
          : null,
      // Trên tablet: dùng navigation rail bên trái
      drawer: !showBottomNav ? _buildDrawer() : null,
    );
  }

  // Drawer cho tablet/desktop
  Widget _buildDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(color: Colors.deepPurple),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: const [
                Text(
                  'Life Quotes',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Inspire your day',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.category),
            title: const Text('Categories'),
            selected: _selectedIndex == 0,
            onTap: () {
              setState(() => _selectedIndex = 0);
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.favorite),
            title: const Text('Favorites'),
            selected: _selectedIndex == 1,
            onTap: () {
              setState(() => _selectedIndex = 1);
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCategoriesView() {
    return Consumer<QuoteProvider>(
      builder: (context, provider, child) {
        if (provider.error != null) {
          return _buildErrorState(provider);
        }
        if (provider.isLoadingCategories) {
          return _buildLoadingState();
        }
        if (provider.categories.isEmpty) {
          return _buildEmptyState();
        }
        return _buildCategoriesGrid(provider.categories);
      },
    );
  }

  Widget _buildErrorState(QuoteProvider provider) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(Responsive.padding(context, 32)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, 
              size: Responsive.fontSize(context, 64), 
              color: Colors.red,
            ),
            SizedBox(height: Responsive.padding(context, 16)),
            Text(
              'Oops! Something went wrong',
              style: TextStyle(
                fontSize: Responsive.fontSize(context, 18),
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: Responsive.padding(context, 8)),
            Text(
              provider.error!,
              style: TextStyle(
                color: Colors.grey,
                fontSize: Responsive.fontSize(context, 14),
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: Responsive.padding(context, 24)),
            ElevatedButton.icon(
              onPressed: () {
                provider.clearCache();
                provider.loadCategories();
              },
              icon: const Icon(Icons.refresh),
              label: Text(
                'Try Again',
                style: TextStyle(fontSize: Responsive.fontSize(context, 14)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    final spacing = Responsive.gridSpacing(context);
    final columns = Responsive.gridColumns(context);
    
    return Padding(
      padding: EdgeInsets.all(Responsive.padding(context, 16)),
      child: GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: columns,
          crossAxisSpacing: spacing,
          mainAxisSpacing: spacing,
          childAspectRatio: Responsive.categoryCardAspectRatio(context),
        ),
        itemCount: 8,
        itemBuilder: (context, index) {
          return Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.category_outlined,
            size: Responsive.fontSize(context, 80),
            color: Colors.grey[400],
          ),
          SizedBox(height: Responsive.padding(context, 16)),
          Text(
            'No categories available',
            style: TextStyle(
              fontSize: Responsive.fontSize(context, 18),
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoriesGrid(List<Category> categories) {
    final spacing = Responsive.gridSpacing(context);
    final columns = Responsive.gridColumns(context);
    final padding = Responsive.padding(context, 16);
    
    return Padding(
      padding: EdgeInsets.all(padding),
      child: GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: columns,
          crossAxisSpacing: spacing,
          mainAxisSpacing: spacing,
          childAspectRatio: Responsive.categoryCardAspectRatio(context),
        ),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          return TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: Duration(milliseconds: 300 + (index * 50)),
            curve: Curves.easeOut,
            builder: (context, value, child) {
              return Transform.translate(
                offset: Offset(0, 30 * (1 - value)),
                child: Opacity(opacity: value, child: child),
              );
            },
            child: _buildCategoryCard(category),
          );
        },
      ),
    );
  }

  Widget _buildCategoryCard(Category category) {
    final colors = ImageManager.getColorsForCategory(category.name);
    final iconSize = Responsive.fontSize(context, 48);
    final textSize = Responsive.fontSize(context, 18);

    return Hero(
      tag: 'category_${category.id}',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => QuoteListScreen(category: category),
              ),
            );
          },
          borderRadius: BorderRadius.circular(20),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: colors,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: colors[0].withValues(alpha: 0.4),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  category.icon,
                  style: TextStyle(fontSize: iconSize),
                ),
                SizedBox(height: Responsive.padding(context, 12)),
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: Responsive.padding(context, 8),
                  ),
                  child: Text(
                    category.name,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: textSize,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}