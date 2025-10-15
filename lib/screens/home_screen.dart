// lib/screens/home_screen.dart
// ENHANCED với Horizontal Quote Pager

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import '../models/category.dart';
import '../models/quote.dart';
import '../providers/quote_provider.dart';
import '../utils/image_manager_enhanced.dart';
import '../utils/responsive.dart';
import 'quote_list_screen.dart';
import 'quote_detail_screen.dart';
import 'favorites_screen.dart';

import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../services/ads_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  int _selectedIndex = 0;

  // Search state
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  List<Quote> _searchResults = [];
  bool _isSearchLoading = false;

  // Animation controller
  late AnimationController _gradientAnimationController;

  // 🎨 NEW: Horizontal Pager state
  late PageController _quotePagerController;
  int _currentQuotePage = 0;
  List<Quote> _randomQuotes = [];
  bool _isLoadingRandomQuotes = true;

  // 🎨 NEW: For infinite scroll
  static const int _quotesPoolSize =
      20; // Load 20 quotes for smooth infinite scroll
  bool _isLoadingMoreQuotes = false;

  BannerAd? _homeBannerAd;
  bool _isHomeBannerAdLoaded = false;

  @override
  void initState() {
    super.initState();

    _gradientAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    // 🎨 NEW: Initialize PageController for horizontal pager
    _quotePagerController = PageController(
      viewportFraction: 0.9, // Show a bit of next/previous card
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<QuoteProvider>().loadCategories();
      context.read<QuoteProvider>().loadFavoriteQuotes();
      _loadRandomQuotesForPager(); // 🎨 NEW: Load random quotes
      _loadHomeBannerAd(); // 🎯 ADDED
    });  
  }

  void _loadHomeBannerAd() {
    AdsService().loadBannerAd().then((ad) {
      if (mounted) {
        setState(() {
          _homeBannerAd = ad;
          _isHomeBannerAdLoaded = true;
        });
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _gradientAnimationController.dispose();
    _quotePagerController.dispose(); // 🎨 NEW
    _homeBannerAd?.dispose();
    super.dispose();
  }

  // 🎨 NEW: Load random quotes for horizontal pager (20 quotes for infinite scroll)
  Future<void> _loadRandomQuotesForPager() async {
    setState(() => _isLoadingRandomQuotes = true);

    final provider = context.read<QuoteProvider>();

    // Load 20 random quotes for smooth infinite scrolling
    final quotes = <Quote>[];
    for (int i = 0; i < _quotesPoolSize; i++) {
      final randomQuote = await provider.getRandomQuote();
      if (randomQuote != null) {
        quotes.add(randomQuote);
      }
    }

    if (mounted) {
      setState(() {
        _randomQuotes = quotes;
        _isLoadingRandomQuotes = false;
      });
    }
  }

  // 🎨 NEW: Load more quotes when approaching end (for infinite scroll)
  Future<void> _loadMoreQuotesIfNeeded(int currentPage) async {
    // If user is near the end (last 5 quotes), load more
    if (currentPage >= _randomQuotes.length - 5 && !_isLoadingMoreQuotes) {
      setState(() => _isLoadingMoreQuotes = true);

      final provider = context.read<QuoteProvider>();
      final newQuotes = <Quote>[];

      // Load 10 more quotes
      for (int i = 0; i < 10; i++) {
        final randomQuote = await provider.getRandomQuote();
        if (randomQuote != null) {
          newQuotes.add(randomQuote);
        }
      }

      if (mounted && newQuotes.isNotEmpty) {
        setState(() {
          _randomQuotes.addAll(newQuotes);
          _isLoadingMoreQuotes = false;
        });
      }
    }
  }

  Future<void> _performSearch(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearchLoading = false;
      });
      return;
    }

    setState(() => _isSearchLoading = true);

    final provider = context.read<QuoteProvider>();
    final results = await provider.searchQuotes(query);

    if (mounted) {
      setState(() {
        _searchResults = results;
        _isSearchLoading = false;
      });
    }
  }


// ...existing code...
@override
Widget build(BuildContext context) {
  final showBottomNav = Responsive.showBottomNav(context);

  // Banner Ad Widget
  Widget bannerAdWidget = _isHomeBannerAdLoaded && _homeBannerAd != null
      ? SizedBox(
          width: _homeBannerAd!.size.width.toDouble(),
          height: _homeBannerAd!.size.height.toDouble(),
          child: AdWidget(ad: _homeBannerAd!),
        )
      : const SizedBox.shrink();

  return Scaffold(
    backgroundColor: Colors.grey[100],
    appBar: AppBar(
      title: _isSearching ? _buildSearchField() : _buildTitle(),
      centerTitle: true,
      backgroundColor: Colors.deepPurple,
      elevation: 0,
      actions: [
        IconButton(
          icon: Icon(_isSearching ? Icons.close : Icons.search),
          onPressed: () {
            setState(() {
              _isSearching = !_isSearching;
              if (!_isSearching) {
                _searchController.clear();
                _searchResults = [];
              }
            });
          },
          iconSize: Responsive.fontSize(context, 24),
          tooltip: _isSearching ? 'Close Search' : 'Search',
        ),
      ],
    ),
    body: Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: Responsive.maxContentWidth(context),
        ),
        child: Column(
          children: [
            Expanded(
              child: _isSearching
                  ? _buildSearchResults()
                  : (_selectedIndex == 0
                        ? _buildCategoriesView()
                        : const FavoritesScreen()),
            ),
            // Banner Ad placed at the bottom, above navigation bar
            bannerAdWidget,
          ],
        ),
      ),
    ),
    // Remove bottomSheet
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
    drawer: !showBottomNav ? _buildDrawer() : null,
  );
}
// ...existing code...

  Widget _buildTitle() {
    return Text(
      _selectedIndex == 0 ? 'Life Quotes' : 'Favorites',
      style: TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: Responsive.fontSize(context, 24),
      ),
    );
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      autofocus: true,
      style: TextStyle(
        color: Colors.white,
        fontSize: Responsive.fontSize(context, 16),
      ),
      decoration: InputDecoration(
        hintText: 'Search quotes...',
        hintStyle: TextStyle(
          color: Colors.white70,
          fontSize: Responsive.fontSize(context, 16),
        ),
        border: InputBorder.none,
      ),
      onChanged: (value) {
        Future.delayed(const Duration(milliseconds: 500), () {
          if (_searchController.text == value) {
            _performSearch(value);
          }
        });
      },
    );
  }

  Widget _buildSearchResults() {
    if (_isSearchLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.deepPurple),
      );
    }

    if (_searchController.text.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search,
              size: Responsive.fontSize(context, 80),
              color: Colors.grey[400],
            ),
            SizedBox(height: Responsive.padding(context, 16)),
            Text(
              'Search for quotes',
              style: TextStyle(
                fontSize: Responsive.fontSize(context, 18),
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: Responsive.padding(context, 8)),
            Text(
              'Enter keywords to find quotes',
              style: TextStyle(
                fontSize: Responsive.fontSize(context, 14),
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    if (_searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: Responsive.fontSize(context, 80),
              color: Colors.grey[400],
            ),
            SizedBox(height: Responsive.padding(context, 16)),
            Text(
              'No results found',
              style: TextStyle(
                fontSize: Responsive.fontSize(context, 18),
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            SizedBox(height: Responsive.padding(context, 8)),
            Text(
              'Try different keywords',
              style: TextStyle(
                fontSize: Responsive.fontSize(context, 14),
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(Responsive.padding(context, 16)),
          color: Colors.deepPurple.withValues(alpha: 0.1),
          child: Row(
            children: [
              Icon(
                Icons.search,
                size: Responsive.fontSize(context, 20),
                color: Colors.deepPurple,
              ),
              SizedBox(width: Responsive.padding(context, 8)),
              Text(
                'Found ${_searchResults.length} quote${_searchResults.length > 1 ? 's' : ''}',
                style: TextStyle(
                  fontSize: Responsive.fontSize(context, 14),
                  fontWeight: FontWeight.w600,
                  color: Colors.deepPurple,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.all(Responsive.padding(context, 16)),
            itemCount: _searchResults.length,
            itemBuilder: (context, index) {
              return _buildQuoteCard(
                _searchResults[index],
                index,
                _searchResults,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildQuoteCard(Quote quote, int index, List<Quote> quotes) {
    final colors = ImageManagerEnhanced.getGradientForQuote(quote.id!);
    final padding = Responsive.padding(context, 16);
    final fontSize = Responsive.fontSize(context, 16);
    final authorSize = Responsive.fontSize(context, 14);

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 300 + (index * 50)),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 50 * (1 - value)),
          child: Opacity(opacity: value, child: child),
        );
      },
      child: GestureDetector(
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  QuoteDetailScreen(quotes: quotes, initialIndex: index),
            ),
          );
        },
        child: Container(
          margin: EdgeInsets.only(bottom: padding),
          constraints: BoxConstraints(
            minHeight: Responsive.quoteCardMinHeight(context),
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: colors,
              stops: const [0.0, 0.5, 1.0],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: colors[0].withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.all(padding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  quote.text,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: fontSize,
                    fontWeight: FontWeight.w500,
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: Responsive.padding(context, 8)),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        '- ${quote.author}',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: authorSize,
                          fontStyle: FontStyle.italic,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (quote.isFavorite)
                      Icon(
                        Icons.favorite,
                        color: Colors.white,
                        size: Responsive.fontSize(context, 20),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

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

  // 🎨 ENHANCED: Categories view with Horizontal Quote Pager scrollable inside
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

        // 🎨 NEW: Single scrollable view with Pager + Grid
        return _buildScrollableCategoriesWithPager(provider.categories);
      },
    );
  }

  // 🎨 NEW: Scrollable content with Pager inside
  Widget _buildScrollableCategoriesWithPager(List<Category> categories) {
    final spacing = Responsive.gridSpacing(context);
    final columns = Responsive.gridColumns(context);
    final padding = Responsive.padding(context, 16);

    return CustomScrollView(
      slivers: [
        // 🎨 Horizontal Quote Pager as first sliver
        SliverToBoxAdapter(child: _buildHorizontalQuotePager()),

        // 🎨 Categories Grid
        SliverPadding(
          padding: EdgeInsets.all(padding),
          sliver: SliverGrid(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              crossAxisSpacing: spacing,
              mainAxisSpacing: spacing,
              childAspectRatio: Responsive.categoryCardAspectRatio(context),
            ),
            delegate: SliverChildBuilderDelegate((context, index) {
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
            }, childCount: categories.length),
          ),
        ),
      ],
    );
  }

  // 🎨 NEW: Horizontal Quote Pager Widget with consistent sizing
  Widget _buildHorizontalQuotePager() {
    final padding = Responsive.padding(context, 16);
    final spacing = Responsive.gridSpacing(context);
    final columns = Responsive.gridColumns(context);

    // 🎨 Calculate pager height based on category card aspect ratio
    final screenWidth = MediaQuery.of(context).size.width;
    final maxWidth = Responsive.maxContentWidth(context);
    final contentWidth = screenWidth < maxWidth ? screenWidth : maxWidth;
    final availableWidth = contentWidth - (padding * 2);
    final cardWidth = (availableWidth - (spacing * (columns - 1))) / columns;
    final aspectRatio = Responsive.categoryCardAspectRatio(context);
    final pagerHeight = cardWidth / aspectRatio; // Same height as category card

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 🎨 "Quote of the Day" label OUTSIDE pager
        Padding(
          padding: EdgeInsets.only(left: padding, right: padding, top: padding),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: Responsive.padding(context, 12),
              vertical: Responsive.padding(context, 6),
            ),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF667eea), Color(0xFF764ba2)],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF667eea).withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.auto_awesome,
                  size: Responsive.fontSize(context, 14),
                  color: Colors.white,
                ),
                SizedBox(width: Responsive.padding(context, 4)),
                Text(
                  'Quote of the Day',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: Responsive.fontSize(context, 12),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),

        // 🎨 Space between label and pager (same as grid spacing)
        SizedBox(height: spacing),

        // 🎨 Horizontal Pager with matching margins
        Padding(
          padding: EdgeInsets.symmetric(horizontal: padding),
          child: SizedBox(
            height: pagerHeight,
            child: _isLoadingRandomQuotes
                ? _buildPagerLoadingState()
                : _randomQuotes.isEmpty
                ? _buildPagerEmptyState()
                : _buildPagerContentClean(),
          ),
        ),

        // 🎨 Space between pager and indicators (same as grid spacing)
        SizedBox(height: spacing),

        // 🎨 Page indicators (centered)
        if (!_isLoadingRandomQuotes && _randomQuotes.isNotEmpty)
          Center(child: _buildPageIndicators()),

        // 🎨 Space after indicators before grid
        SizedBox(height: spacing),
      ],
    );
  }

  // 🎨 NEW: Pager loading state (updated with matching shadow effect)
  Widget _buildPagerLoadingState() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: Responsive.padding(context, 16)),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        // 🎨 Shadow effect matching category cards
        boxShadow: [
          BoxShadow(
            color: Colors.grey[400]!.withValues(alpha: 0.4),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),
    );
  }

  // 🎨 NEW: Pager empty state (updated with matching shadow effect)
  Widget _buildPagerEmptyState() {
    final colors = [const Color(0xFF667eea), const Color(0xFF764ba2)];

    return Container(
      margin: EdgeInsets.symmetric(horizontal: Responsive.padding(context, 16)),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
          stops: const [0.0, 0.5, 1.0],
        ),
        borderRadius: BorderRadius.circular(20),
        // 🎨 Shadow effect matching category cards
        boxShadow: [
          BoxShadow(
            color: colors[0].withValues(alpha: 0.4),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Text(
          'No quotes available',
          style: TextStyle(
            color: Colors.white,
            fontSize: Responsive.fontSize(context, 16),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  // 🎨 NEW: Clean pager content without internal label
  Widget _buildPagerContentClean() {
    return PageView.builder(
      controller: _quotePagerController,
      onPageChanged: (index) {
        setState(() => _currentQuotePage = index);
        _loadMoreQuotesIfNeeded(index);
      },
      itemCount: null, // Infinite scroll
      itemBuilder: (context, index) {
        final quoteIndex = index % _randomQuotes.length;
        return _buildPagerCard(_randomQuotes[quoteIndex], index);
      },
    );
  }

 

  // 🎨 NEW: Individual pager card with consistent shadow & gradient effects
  Widget _buildPagerCard(Quote quote, int index) {
    final colors = ImageManagerEnhanced.getGradientForQuote(quote.id!);
    final padding = Responsive.padding(context, 20);

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Transform.scale(
          scale: 0.95 + (0.05 * value),
          child: Opacity(opacity: value, child: child),
        );
      },
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  QuoteDetailScreen(quotes: [quote], initialIndex: 0),
            ),
          );
        },
        child: Container(
          margin: EdgeInsets.symmetric(
            horizontal: Responsive.padding(context, 8),
          ),
          decoration: BoxDecoration(
            // 🎨 3-color gradient like category cards
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: colors,
              stops: const [0.0, 0.5, 1.0],
            ),
            borderRadius: BorderRadius.circular(20),
            // 🎨 Enhanced shadow matching category cards
            boxShadow: [
              BoxShadow(
                color: colors[0].withValues(alpha: 0.4),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Decorative quote icon background (like category cards)
              Positioned(
                top: -20,
                right: -20,
                child: Icon(
                  Icons.format_quote,
                  size: 120,
                  color: Colors.white.withValues(alpha: 0.1),
                ),
              ),

              // Main content
              Padding(
                padding: EdgeInsets.all(padding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Quote text
                    Flexible(
                      child: Text(
                        quote.text,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: Responsive.fontSize(context, 15),
                          fontWeight: FontWeight.w600,
                          height: 1.4,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),

                    SizedBox(height: Responsive.padding(context, 12)),

                    // Author
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '- ${quote.author}',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontSize: Responsive.fontSize(context, 13),
                              fontStyle: FontStyle.italic,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (quote.isFavorite)
                          Icon(
                            Icons.favorite,
                            color: Colors.white,
                            size: Responsive.fontSize(context, 18),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 🎨 NEW: Page indicators (shows position in current pool)
  Widget _buildPageIndicators() {
    // Show only indicators for the current "pool" of visible quotes
    final poolPosition = _currentQuotePage % _quotesPoolSize;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        _quotesPoolSize.clamp(0, 10), // Show max 10 dots
        (index) {
          final isActive = index == poolPosition;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: EdgeInsets.symmetric(
              horizontal: Responsive.padding(context, 4),
            ),
            width: isActive ? 24.0 : 8.0,
            height: 8.0,
            decoration: BoxDecoration(
              color: isActive ? Colors.deepPurple : Colors.grey[400],
              borderRadius: BorderRadius.circular(4),
            ),
          );
        },
      ),
    );
  }

  Widget _buildErrorState(QuoteProvider provider) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(Responsive.padding(context, 32)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
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
    final padding = Responsive.padding(context, 16);

    // 🎨 UPDATED: Loading state with Pager + Grid scrollable
    return CustomScrollView(
      slivers: [
        // Pager loading
        SliverToBoxAdapter(
          child: Container(
            height: Responsive.isMobile(context) ? 200.0 : 240.0,
            margin: EdgeInsets.only(
              top: padding,
              bottom: padding,
              left: padding,
              right: padding,
            ),
            child: Shimmer.fromColors(
              baseColor: Colors.grey[300]!,
              highlightColor: Colors.grey[100]!,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ),
        ),

        // Grid loading
        SliverPadding(
          padding: EdgeInsets.all(padding),
          sliver: SliverGrid(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              crossAxisSpacing: spacing,
              mainAxisSpacing: spacing,
              childAspectRatio: Responsive.categoryCardAspectRatio(context),
            ),
            delegate: SliverChildBuilderDelegate((context, index) {
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
            }, childCount: 8),
          ),
        ),
      ],
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

 
  Widget _buildCategoryCard(Category category) {
    final colors = ImageManagerEnhanced.getColorsForCategory(category.name);

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
          child: AnimatedBuilder(
            animation: _gradientAnimationController,
            builder: (context, child) {
              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: colors,
                    stops: const [0.0, 0.5, 1.0],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: colors[0].withValues(alpha: 0.4),
                      blurRadius: 8 + (_gradientAnimationController.value * 4),
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: child,
              );
            },
            child: Padding(
              padding: EdgeInsets.symmetric(
                vertical: Responsive.padding(context, 16),
                horizontal: Responsive.padding(context, 8),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.8, end: 1.0),
                    duration: const Duration(milliseconds: 600),
                    curve: Curves.elasticOut,
                    builder: (context, scale, child) {
                      return Transform.scale(scale: scale, child: child);
                    },
                    child: Text(
                      category.icon,
                      style: TextStyle(
                        fontSize: Responsive.categoryCardIconSize(context),
                      ),
                    ),
                  ),

                  SizedBox(height: Responsive.padding(context, 8)),

                  Flexible(
                    child: Center(
                      child: Text(
                        category.name,
                        style: Responsive.categoryCardTitleStyle(context),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
