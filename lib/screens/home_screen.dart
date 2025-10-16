// lib/screens/home_screen.dart
// Fixed: Banner ad không che khuất nội dung - Sử dụng Column layout

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../models/category.dart';
import '../models/quote.dart';
import '../providers/quote_provider.dart';
import '../utils/image_manager_enhanced.dart';
import '../utils/category_image_manager.dart';
import '../utils/responsive.dart';
import '../services/ads_service.dart';
import 'quote_list_screen.dart';
import 'quote_detail_screen.dart';
import 'favorites_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  int _selectedIndex = 0;
  
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  List<Quote> _searchResults = [];
  bool _isSearchLoading = false;

  late AnimationController _gradientAnimationController;
  
  late PageController _quotePagerController;
  int _currentQuotePage = 0;
  List<Quote> _randomQuotes = [];
  bool _isLoadingRandomQuotes = true;
  static const int _quotesPoolSize = 20;
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
    
    _quotePagerController = PageController(
      viewportFraction: 1.0,
    );
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<QuoteProvider>().loadCategories();
      context.read<QuoteProvider>().loadFavoriteQuotes();
      _loadRandomQuotesForPager();
      _loadHomeBannerAd();
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
    _quotePagerController.dispose();
    _homeBannerAd?.dispose();
    super.dispose();
  }

  Future<void> _loadRandomQuotesForPager() async {
    setState(() => _isLoadingRandomQuotes = true);
    
    final provider = context.read<QuoteProvider>();
    
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

  Future<void> _loadMoreQuotesIfNeeded(int currentPage) async {
    if (currentPage >= _randomQuotes.length - 5 && !_isLoadingMoreQuotes) {
      setState(() => _isLoadingMoreQuotes = true);
      
      final provider = context.read<QuoteProvider>();
      final newQuotes = <Quote>[];
      
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

  @override
  Widget build(BuildContext context) {
    final showBottomNav = Responsive.showBottomNav(context);

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
      body: Column(
        children: [
          // Nội dung chính - chiếm toàn bộ không gian còn lại
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: Responsive.maxContentWidth(context),
                ),
                child: _isSearching 
                    ? _buildSearchResults() 
                    : (_selectedIndex == 0 
                        ? _buildCategoriesView() 
                        : const FavoritesScreen()),
              ),
            ),
          ),
          
          // Banner ad ở dưới cùng (ngoài Expanded nên không che khuất)
          if (_isHomeBannerAdLoaded && _homeBannerAd != null)
            Container(
              color: Colors.white,
              child: SafeArea(
                top: false,
                child: SizedBox(
                  width: _homeBannerAd!.size.width.toDouble(),
                  height: _homeBannerAd!.size.height.toDouble(),
                  child: AdWidget(ad: _homeBannerAd!),
                ),
              ),
            ),
        ],
      ),
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
        return _buildScrollableCategoriesWithPager(provider.categories);
      },
    );
  }

  Widget _buildScrollableCategoriesWithPager(List<Category> categories) {
    final spacing = Responsive.gridSpacing(context);
    final columns = Responsive.gridColumns(context);
    final padding = Responsive.padding(context, 16);
    
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: _buildHorizontalQuotePager(),
        ),
        
        SliverPadding(
          padding: EdgeInsets.only(
            left: padding,
            right: padding,
            top: 8,
            bottom: padding,
          ),
          sliver: SliverGrid(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              crossAxisSpacing: spacing,
              mainAxisSpacing: spacing,
              childAspectRatio: 0.75,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
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
              childCount: categories.length,
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildHorizontalQuotePager() {
    final padding = Responsive.padding(context, 16);
    final spacing = Responsive.gridSpacing(context);
    final columns = Responsive.gridColumns(context);
    
    final screenWidth = MediaQuery.of(context).size.width;
    final maxWidth = Responsive.maxContentWidth(context);
    final contentWidth = screenWidth < maxWidth ? screenWidth : maxWidth;
    final availableWidth = contentWidth - (padding * 2);
    final cardWidth = (availableWidth - (spacing * (columns - 1))) / columns;
    final aspectRatio = 0.75;
    final pagerHeight = cardWidth / aspectRatio;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: spacing),
        
        Padding(
          padding: EdgeInsets.only(
            left: 8,
            right: 8,
            top: 8,
            bottom: 8,
          ),
          child: SizedBox(
            height: pagerHeight,
            child: _isLoadingRandomQuotes
                ? _buildPagerLoadingState()
                : _randomQuotes.isEmpty
                    ? _buildPagerEmptyState()
                    : _buildPagerContentClean(),
          ),
        ),
        
        SizedBox(height: spacing),
        
        if (!_isLoadingRandomQuotes && _randomQuotes.isNotEmpty)
          Center(
            child: _buildPageIndicators(),
          ),
        
        SizedBox(height: spacing),
      ],
    );
  }

  Widget _buildPagerLoadingState() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.grey[400]!.withValues(alpha: 0.4),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPagerEmptyState() {
    final colors = [const Color(0xFF667eea), const Color(0xFF764ba2)];
    
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

  Widget _buildPagerContentClean() {
    return PageView.builder(
      controller: _quotePagerController,
      onPageChanged: (index) {
        setState(() => _currentQuotePage = index);
        _loadMoreQuotesIfNeeded(index);
      },
      itemCount: null,
      itemBuilder: (context, index) {
        final quoteIndex = index % _randomQuotes.length;
        return _buildPagerCard(_randomQuotes[quoteIndex], index);
      },
    );
  }

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
              builder: (context) => QuoteDetailScreen(
                quotes: [quote],
                initialIndex: 0,
              ),
            ),
          );
        },
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: Responsive.padding(context, 8)),
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
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                top: -20,
                right: -20,
                child: Icon(
                  Icons.format_quote,
                  size: 120,
                  color: Colors.white.withValues(alpha: 0.1),
                ),
              ),
              
              Padding(
                padding: EdgeInsets.all(padding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
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

  Widget _buildPageIndicators() {
    final poolPosition = _currentQuotePage % _quotesPoolSize;
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        _quotesPoolSize.clamp(0, 10),
        (index) {
          final isActive = index == poolPosition;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: EdgeInsets.symmetric(horizontal: Responsive.padding(context, 4)),
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

    return CustomScrollView(
      slivers: [
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
    final imagePath = CategoryImageManager.getImagePath(category.name);
    final fallbackColors = CategoryImageManager.getFallbackGradient(category.name);

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
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Background: Image or Gradient
                  if (imagePath != null)
                    Image.asset(
                      imagePath,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        // Fallback to gradient if image fails
                        return Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: fallbackColors,
                            ),
                          ),
                        );
                      },
                    )
                  else
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: fallbackColors,
                        ),
                      ),
                    ),
                  
                  // Dark gradient overlay for text readability
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.7),
                        ],
                        stops: const [0.5, 1.0],
                      ),
                    ),
                  ),
                  
                  // Content
                  Padding(
                    padding: EdgeInsets.all(Responsive.padding(context, 16)),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Category name
                        Text(
                          category.name.toUpperCase(),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: Responsive.fontSize(context, 18),
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                            shadows: [
                              Shadow(
                                color: Colors.black.withValues(alpha: 0.5),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        
                        SizedBox(height: Responsive.padding(context, 8)),
                        
                        // Decorative line
                        Container(
                          width: 40,
                          height: 3,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ],
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