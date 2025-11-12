// lib/screens/home_screen.dart
// ✅ FULLY UPDATED with Notification Navigation Handling

import 'dart:convert';
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
import '../services/notification_service.dart';
import 'quote_list_screen.dart';
import 'quote_detail_screen.dart';
import 'favorites_screen.dart';
import 'theme_settings_screen.dart';
import '../widgets/theme_toggle_button.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin, RouteAware {
  int _selectedIndex = 0;
  
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  List<Quote> _searchResults = [];
  bool _isSearchLoading = false;
  
  int _searchOffset = 0;
  final int _searchLimit = 50;
  int _totalSearchResults = 0;
  bool _isLoadingMore = false;
  bool _hasMoreResults = true;

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
    
    _initializeScreen();
    
    // ✅ Check for notification payload after a short delay
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        debugPrint('🏠 Ready to check notification payload');
        _checkNotificationPayload();
      }
    });
  }

  void _initializeScreen() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final provider = context.read<QuoteProvider>();
        
        if (provider.categories.isEmpty) {
          provider.loadCategories();
        }
        
        if (provider.favoriteQuotes.isEmpty) {
          provider.loadFavoriteQuotes();
        }
        
        if (_randomQuotes.isEmpty) {
          _loadRandomQuotesForPager();
        }
        
        if (!_isHomeBannerAdLoaded) {
          _loadHomeBannerAd();
        }
      }
    });
  }

  /// ✅ Check and handle notification payload
  Future<void> _checkNotificationPayload() async {
    final payload = NotificationService().getAndClearLastPayload();
    
    if (payload != null && payload.isNotEmpty) {
      debugPrint('📱 Processing notification payload: $payload');
      
      try {
        // Parse JSON payload
        final data = jsonDecode(payload);
        debugPrint('📦 Parsed data: $data');
        final quoteId = data['quoteId'] as int?;
        final text = data['text'] as String?;
        final author = data['author'] as String?;

        debugPrint('🔢 Quote ID: $quoteId');
        debugPrint('📝 Text: ${text?.substring(0, 50)}...');
        debugPrint('✍️ Author: $author');
        
        if (quoteId != null && text != null) {
          // Load the quote from database/cache to get accurate data
          final provider = context.read<QuoteProvider>();
          final actualQuote = await provider.getQuoteById(quoteId);

          debugPrint('🔍 Found in DB: ${actualQuote != null}');
          
          if (mounted && actualQuote != null) {
            // Navigate to quote detail screen
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => QuoteDetailScreen(
                  quotes: [actualQuote],
                  initialIndex: 0,
                ),
              ),
            );
            
            debugPrint('✅ Navigated to quote detail from notification');
          } else if (mounted) {
            debugPrint('⚠️ Using fallback quote from notification data');
            // Fallback: create quote from notification data if not found in DB
            final fallbackQuote = Quote(
              id: quoteId,
              text: text,
              author: author,
              categoryId: 0, // Unknown category
              isFavorite: false,
            );
            
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => QuoteDetailScreen(
                  quotes: [fallbackQuote],
                  initialIndex: 0,
                ),
              ),
            );
            
            debugPrint('⚠️ Used fallback quote from notification');
          }
        } else {
          debugPrint('❌ Missing required data: quoteId=$quoteId, text=$text');
        }

      } catch (e) {
        debugPrint('❌ Error processing notification payload: $e');
        debugPrint('Stack trace: ${StackTrace.current}');
      }
    } else {
      debugPrint('ℹ️ No payload to process');
    }

    debugPrint('🏠 ======================================');
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _refreshDataIfNeeded();
  }

  void _refreshDataIfNeeded() {
    if (mounted) {
      final provider = context.read<QuoteProvider>();
      
      if (provider.categories.isEmpty && !provider.isLoadingCategories) {
        provider.loadCategories();
      }
      
      if (_randomQuotes.isEmpty && !_isLoadingRandomQuotes) {
        _loadRandomQuotesForPager();
      }
    }
  }

  Future<void> _loadHomeBannerAd() async {
    if (!mounted) return;
    
    final padding = Responsive.padding(context, 16);
    final screenWidth = MediaQuery.of(context).size.width;
    final maxWidth = Responsive.maxContentWidth(context);
    final contentWidth = screenWidth < maxWidth ? screenWidth : maxWidth;
    final bannerWidth = (contentWidth - (padding * 2)).truncate();
    
    final size = await AdsService().getAdaptiveBannerSize(bannerWidth);
    
    if (size == null) {
      return;
    }
    
    final ad = await AdsService().loadAdaptiveBannerAd(size);
    
    if (mounted && ad != null) {
      setState(() {
        _homeBannerAd = ad;
        _isHomeBannerAdLoaded = true;
      });
    }
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
    if (!mounted) return;
    
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
        _searchOffset = 0;
        _totalSearchResults = 0;
        _hasMoreResults = true;
      });
      return;
    }

    setState(() {
      _isSearchLoading = true;
      _searchOffset = 0;
      _searchResults = [];
    });

    final provider = context.read<QuoteProvider>();
    
    final totalCount = await provider.getSearchResultsCount(query);
    final results = await provider.searchQuotes(query, offset: 0, limit: _searchLimit);

    if (mounted) {
      setState(() {
        _searchResults = results;
        _totalSearchResults = totalCount;
        _searchOffset = results.length;
        _hasMoreResults = results.length < totalCount;
        _isSearchLoading = false;
      });
    }
  }

  Future<void> _loadMoreSearchResults() async {
    if (_isLoadingMore || !_hasMoreResults) return;

    setState(() => _isLoadingMore = true);

    final provider = context.read<QuoteProvider>();
    final query = _searchController.text;
    
    final moreResults = await provider.searchQuotes(
      query, 
      offset: _searchOffset, 
      limit: _searchLimit,
    );

    if (mounted) {
      setState(() {
        _searchResults.addAll(moreResults);
        _searchOffset += moreResults.length;
        _hasMoreResults = _searchResults.length < _totalSearchResults;
        _isLoadingMore = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final showBottomNav = Responsive.showBottomNav(context);

    return Scaffold(
      backgroundColor: colorScheme.surface,
      
      appBar: AppBar(
        title: _isSearching ? _buildSearchField() : _buildTitle(),
        centerTitle: true,
        elevation: 0,
        actions: [
          if (!_isSearching)
            IconButton(
              icon: const Icon(Icons.notifications_active),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const QuoteOfDaySettingsScreen(),
                  ),
                );
              },
              iconSize: Responsive.fontSize(context, 24),
              tooltip: 'Quote of the Day',
            ),
          
          if (!_isSearching) const ThemeToggleButton(),

          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchController.clear();
                  _searchResults = [];
                  _searchOffset = 0;
                  _totalSearchResults = 0;
                  _hasMoreResults = true;
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
        ],
      ),
      
      bottomNavigationBar: showBottomNav
          ? BottomNavigationBar(
              currentIndex: _selectedIndex,
              onTap: (index) => setState(() => _selectedIndex = index),
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
      _selectedIndex == 0 ? 'Life Quote' : 'Favorites',
    );
  }

  Widget _buildSearchField() {
    final colorScheme = Theme.of(context).colorScheme;
    
    return TextField(
      controller: _searchController,
      autofocus: true,
      style: TextStyle(
        color: colorScheme.onSurface,
        fontSize: Responsive.fontSize(context, 16),
      ),
      decoration: InputDecoration(
        hintText: 'Search quotes...',
        hintStyle: TextStyle(
          color: colorScheme.onSurfaceVariant.withValues(alpha:0.7),
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
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    
    if (_isSearchLoading) {
      return Center(
        child: CircularProgressIndicator(
          color: colorScheme.primary,
        ),
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
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            SizedBox(height: Responsive.padding(context, 16)),
            Text(
              'Search for quotes',
              style: textTheme.headlineSmall,
            ),
            SizedBox(height: Responsive.padding(context, 8)),
            Text(
              'Enter keywords to find quotes',
              style: textTheme.bodyMedium,
            ),
          ],
        ),
      );
    }

    if (_searchResults.isEmpty && !_isSearchLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: Responsive.fontSize(context, 80),
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            SizedBox(height: Responsive.padding(context, 16)),
            Text(
              'No results found',
              style: textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: Responsive.padding(context, 8)),
            Text(
              'Try different keywords',
              style: textTheme.bodyMedium,
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(Responsive.padding(context, 16)),
          color: colorScheme.surfaceContainerHighest,
          child: Row(
            children: [
              Icon(
                Icons.search,
                size: Responsive.fontSize(context, 20),
                color: colorScheme.primary,
              ),
              SizedBox(width: Responsive.padding(context, 8)),
              Text(
                'Found $_totalSearchResults quote${_totalSearchResults > 1 ? 's' : ''} • Showing ${_searchResults.length}',
                style: textTheme.labelLarge?.copyWith(
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
        
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.all(Responsive.padding(context, 16)),
            itemCount: _searchResults.length + (_hasMoreResults ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == _searchResults.length) {
                return _buildLoadMoreButton();
              }
              
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

  Widget _buildLoadMoreButton() {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Container(
      margin: EdgeInsets.only(
        top: Responsive.padding(context, 8),
        bottom: Responsive.padding(context, 16),
      ),
      child: _isLoadingMore
          ? Center(
              child: Padding(
                padding: EdgeInsets.all(Responsive.padding(context, 16)),
                child: CircularProgressIndicator(
                  color: colorScheme.primary,
                ),
              ),
            )
          : ElevatedButton.icon(
              onPressed: _loadMoreSearchResults,
              icon: const Icon(Icons.expand_more),
              label: Text(
                'Load More (${_totalSearchResults - _searchResults.length} remaining)',
                style: TextStyle(
                  fontSize: Responsive.fontSize(context, 14),
                ),
              ),
              style: ElevatedButton.styleFrom(
                minimumSize: Size(
                  double.infinity,
                  Responsive.padding(context, 48),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
    );
  }

  Widget _buildQuoteCard(Quote quote, int index, List<Quote> quotes) {
    final colors = ImageManagerEnhanced.getGradientForQuote(quote.id!);
    final padding = Responsive.padding(context, 16);
    final fontSize = Responsive.fontSize(context, 16);
    final authorSize = Responsive.fontSize(context, 14);
    final textColor = ImageManagerEnhanced.getTextColor(quote.id!);

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
          if (mounted) {
            _refreshDataIfNeeded();
          }
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
                    color: textColor,
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
                    if (quote.author != null && quote.author!.isNotEmpty)
                      Expanded(
                        child: Text(
                          '- ${quote.author}',
                          style: TextStyle(
                            color: textColor.withValues(alpha:0.9),
                            fontSize: authorSize,
                            fontStyle: FontStyle.italic,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      )
                    else
                      const Spacer(),
                    if (quote.isFavorite)
                      Icon(
                        Icons.favorite,
                        color: textColor,
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
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: colorScheme.primary,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  'Life Quotes',
                  style: textTheme.headlineMedium?.copyWith(
                    color: colorScheme.onPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Inspire your day',
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onPrimary.withValues(alpha: 0.8),
                  ),
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
          
          const Divider(),
          
          ListTile(
            leading: const Icon(Icons.notifications_active),
            title: const Text('Quote of the Day'),
            subtitle: const Text('Daily notification'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const QuoteOfDaySettingsScreen(),
                ),
              );
            },
          ),
          
          ListTile(
            leading: const Icon(Icons.palette),
            title: const Text('Theme Settings'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ThemeSettingsScreen(),
                ),
              );
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
    //final spacing = Responsive.gridSpacing(context);
    final columns = Responsive.gridColumns(context);
    final padding = Responsive.padding(context, 24);

    final crossAxisSpacing = Responsive.padding(context, 24);  // Ngang
    final mainAxisSpacing = Responsive.padding(context, 12);   // Dọc
    final topSpacing = Responsive.padding(context, 20);        // QuotePager → Grid
    
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: _buildHorizontalQuotePager(),
        ),
        
        SliverPadding(
          padding: EdgeInsets.only(
            left: padding,
            right: padding,
            top: topSpacing,
            bottom: padding,
          ),
          sliver: SliverGrid(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              crossAxisSpacing: crossAxisSpacing,
              mainAxisSpacing: mainAxisSpacing,
              childAspectRatio: Responsive.categoryCardAspectRatio(context),
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
    final spacing = Responsive.gridSpacing(context);
    final columns = Responsive.gridColumns(context);
    final padding = Responsive.padding(context, 24);
    
    final screenWidth = MediaQuery.of(context).size.width;
    final maxWidth = Responsive.maxContentWidth(context);
    final contentWidth = screenWidth < maxWidth ? screenWidth : maxWidth;
    final availableWidth = contentWidth - (padding * 2);
    final cardWidth = (availableWidth - (spacing * (columns - 1))) / columns;
    final aspectRatio = Responsive.categoryCardAspectRatio(context);
    final pagerHeight = cardWidth / aspectRatio;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: spacing),
        
        Padding(
          padding: EdgeInsets.symmetric(horizontal: padding),
          child: SizedBox(
            height: pagerHeight,
            child: _isLoadingRandomQuotes
                ? _buildPagerLoadingState()
                : _randomQuotes.isEmpty
                    ? _buildPagerEmptyState()
                    : _buildPagerContentWithImages(),
          ),
        ),
        
        SizedBox(height: spacing),
        
        if (!_isLoadingRandomQuotes && _randomQuotes.isNotEmpty)
          Center(
            child: _buildPageIndicators(),
          ),
        
        //SizedBox(height: spacing),
      ],
    );
  }

  Widget _buildPagerLoadingState() {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Shimmer.fromColors(
      baseColor: colorScheme.surfaceContainerHighest,
      highlightColor: colorScheme.surfaceContainerLow,
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow.withValues(alpha:0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPagerEmptyState() {
    final textTheme = Theme.of(context).textTheme;
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
          style: textTheme.titleMedium?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildPagerContentWithImages() {
    return PageView.builder(
      controller: _quotePagerController,
      onPageChanged: (index) {
        setState(() => _currentQuotePage = index);
        _loadMoreQuotesIfNeeded(index);
      },
      itemCount: _randomQuotes.length * 3,
      itemBuilder: (context, index) {
        final quoteIndex = index % _randomQuotes.length;
        return _buildPagerCardWithImage(_randomQuotes[quoteIndex], index);
      },
    );
  }

  Widget _buildPagerCardWithImage(Quote quote, int index) {
    final padding = Responsive.padding(context, 28);
    final colorScheme = Theme.of(context).colorScheme;
    const textColor = Colors.white;
    
    final imageList = [
		'assets/images/categories/i1043959780.jpg',
		'assets/images/categories/i1050750000.jpg',
		'assets/images/categories/i1053405882.jpg',
		'assets/images/categories/i1082411378.jpg',
		'assets/images/categories/i1130883848.jpg',
		'assets/images/categories/i1132264290.jpg',
		'assets/images/categories/i1137079196.jpg',
		'assets/images/categories/i1161389146.jpg',
		'assets/images/categories/i1167484409.jpg',
		'assets/images/categories/i117146059.jpg',
		'assets/images/categories/i1182434606.jpg',
		'assets/images/categories/i1192260535.jpg',
		'assets/images/categories/i1268487061.jpg',
		'assets/images/categories/i1270042705.jpg',
		'assets/images/categories/i1277015766.jpg',
		'assets/images/categories/i1292399669.jpg',
		'assets/images/categories/i1301592032.jpg',
		'assets/images/categories/i1308867983.jpg',
		'assets/images/categories/i1369254957.jpg',
		'assets/images/categories/i1388623445.jpg',
		'assets/images/categories/i1418527039.jpg',
		'assets/images/categories/i1418783006.jpg',
		'assets/images/categories/i1419410282.jpg',
		'assets/images/categories/i1440351590.jpg',
		'assets/images/categories/i1440503559.jpg',
		'assets/images/categories/i1443409611.jpg',
		'assets/images/categories/i1458782106.jpg',
		'assets/images/categories/i146060521.jpg',
		'assets/images/categories/i1473454504.jpg',
		'assets/images/categories/i1477148178.jpg',
		'assets/images/categories/i1478418006.jpg',
		'assets/images/categories/i1493704782.jpg',
		'assets/images/categories/i1696167872.jpg',
		'assets/images/categories/i1739024655.jpg',
		'assets/images/categories/i1791589607.jpg',
		'assets/images/categories/i186534154.jpg',
		'assets/images/categories/i2133340831.jpg',
		'assets/images/categories/i471909179.jpg',
		'assets/images/categories/i483724081.jpg',
		'assets/images/categories/i498063665.jpg',
		'assets/images/categories/i498309616.jpg',
		'assets/images/categories/i511852760.jpg',
		'assets/images/categories/i521975241.jpg',
		'assets/images/categories/i526705622.jpg',
		'assets/images/categories/i530185374.jpg',
		'assets/images/categories/i534037450.jpg',
		'assets/images/categories/i536291400.jpg',
		'assets/images/categories/i537621432.jpg',
		'assets/images/categories/i538653565.jpg',
		'assets/images/categories/i543212762.jpg',
		'assets/images/categories/i620951116.jpg',
		'assets/images/categories/i621938662.jpg',
		'assets/images/categories/i692869260.jpg',
		'assets/images/categories/i694050758.jpg',
		'assets/images/categories/i809971888.jpg',
		'assets/images/categories/i860528958.jpg',
		'assets/images/categories/i879845502.jpg',
		'assets/images/categories/i884343584.jpg',
		'assets/images/categories/i898869110.jpg',
		'assets/images/categories/i899836048.jpg',
		'assets/images/categories/i921341724.jpg',
		'assets/images/categories/i935746242.jpg',
		'assets/images/categories/i937057490.jpg',
		'assets/images/categories/i959149062.jpg',
		'assets/images/categories/i968886386.jpg',
    ];
    
    final imageIndex = (quote.id ?? 0) % imageList.length;
    final imagePath = imageList[imageIndex];
    final fallbackColors = ImageManagerEnhanced.getGradientForQuote(quote.id!);
    
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
        onTap: () async {
          final actualIndex = index % _randomQuotes.length;
          
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => QuoteDetailScreen(
                quotes: _randomQuotes,
                initialIndex: actualIndex,
              ),
            ),
          );
          
          if (mounted) {
            _refreshDataIfNeeded();
          }
        },
        child: Material(
          elevation: 6,
          borderRadius: BorderRadius.circular(16),
          shadowColor: colorScheme.shadow.withValues(alpha: 0.3),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  imagePath,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: fallbackColors,
                          stops: const [0.0, 0.5, 1.0],
                        ),
                      ),
                    );
                  },
                ),
                
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.2),
                        Colors.black.withValues(alpha: 0.5),
                      ],
                      stops: const [0.0, 1.0],
                    ),
                  ),
                ),
                
                Positioned(
                  top: -20,
                  right: -20,
                  child: Icon(
                    Icons.format_quote,
                    size: 120,
                    color: Colors.white.withValues(alpha: 0.15),
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
                            color: textColor,
                            fontSize: Responsive.fontSize(context, 15),
                            fontWeight: FontWeight.w700,
                            height: 1.4,
                            shadows: [
                              Shadow(
                                color: Colors.black.withValues(alpha: 0.5),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      
                      SizedBox(height: Responsive.padding(context, 12)),
                      
                      Row(
                        children: [
                          if (quote.author != null && quote.author!.isNotEmpty)
                          Expanded(
                            child: Text(
                              '- ${quote.author}',
                              style: TextStyle(
                                color: textColor,
                                fontSize: Responsive.fontSize(context, 13),
                                fontStyle: FontStyle.italic,
                                fontWeight: FontWeight.w600,
                                shadows: [
                                  Shadow(
                                    color: Colors.black.withValues(alpha: 0.5),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          )
                          else
                            const Spacer(),
                          if (quote.isFavorite)
                            Container(
                              padding: EdgeInsets.all(Responsive.padding(context, 6)),
                              decoration: BoxDecoration(
                                color: colorScheme.error.withValues(alpha: 0.9),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.favorite,
                                color: colorScheme.onError,
                                size: Responsive.fontSize(context, 16),
                              ),
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
      ),
    );
  }

  Widget _buildPageIndicators() {
    final colorScheme = Theme.of(context).colorScheme;
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
              color: isActive 
                  ? colorScheme.primary
                  : colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(4),
            ),
          );
        },
      ),
    );
  }

  Widget _buildErrorState(QuoteProvider provider) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    
    return Center(
      child: Padding(
        padding: EdgeInsets.all(Responsive.padding(context, 32)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: Responsive.fontSize(context, 64),
              color: colorScheme.error,
            ),
            SizedBox(height: Responsive.padding(context, 16)),
            Text(
              'Oops! Something went wrong',
              style: textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: Responsive.padding(context, 8)),
            Text(
              provider.error!,
              style: textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: Responsive.padding(context, 24)),
            ElevatedButton.icon(
              onPressed: () {
                provider.clearCache();
                provider.loadCategories();
                _loadRandomQuotesForPager();
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
    final colorScheme = Theme.of(context).colorScheme;
    final spacing = Responsive.gridSpacing(context);
    final columns = Responsive.gridColumns(context);
    final padding = Responsive.padding(context, 16);

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Container(
            height: Responsive.isMobile(context) ? 200.0 : 240.0,
            margin: EdgeInsets.symmetric(
              horizontal: padding,
              vertical: spacing,
            ),
            child: Shimmer.fromColors(
              baseColor: colorScheme.surfaceContainerHighest,
              highlightColor: colorScheme.surfaceContainerLow,
              child: Container(
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainer,
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ),
        ),

        SliverPadding(
          padding: EdgeInsets.only(
            left: padding,
            right: padding,
            top: spacing,
            bottom: padding,
          ),
          sliver: SliverGrid(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              crossAxisSpacing: spacing,
              mainAxisSpacing: spacing,
              childAspectRatio: Responsive.categoryCardAspectRatio(context),
            ),
            delegate: SliverChildBuilderDelegate((context, index) {
              return Shimmer.fromColors(
                baseColor: colorScheme.surfaceContainerHighest,
                highlightColor: colorScheme.surfaceContainerLow,
                child: Container(
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainer,
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
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.category_outlined,
            size: Responsive.fontSize(context, 80),
            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
          ),
          SizedBox(height: Responsive.padding(context, 16)),
          Text(
            'No categories available',
            style: textTheme.headlineSmall,
          ),
          SizedBox(height: Responsive.padding(context, 16)),
          ElevatedButton.icon(
            onPressed: () {
              context.read<QuoteProvider>().loadCategories();
              _loadRandomQuotesForPager();
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Reload'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildCategoryCard(Category category) {
    final colorScheme = Theme.of(context).colorScheme;
    final imagePath = CategoryImageManager.getImagePath(category.name);
    final fallbackColors = CategoryImageManager.getFallbackGradient(category.name);

    return Hero(
      tag: 'category_${category.id}',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => QuoteListScreen(category: category),
              ),
            );
            if (mounted) {
              _refreshDataIfNeeded();
            }
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: colorScheme.shadow.withValues(alpha: 0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (imagePath != null)
                    Image.asset(
                      imagePath,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
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
                  
                  Padding(
                    padding: EdgeInsets.all(Responsive.padding(context, 24)),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          category.name,
                          style: Responsive.categoryCardTitleStyle(context),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
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