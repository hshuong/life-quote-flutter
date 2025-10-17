// lib/screens/quote_list_screen.dart
// Optimized: Padding cân bằng, banner ad không che khuất

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../models/category.dart';
import '../models/quote.dart';
import '../providers/quote_provider.dart';
import '../utils/image_manager.dart';
import '../utils/responsive.dart';
import '../services/ads_service.dart';
import 'quote_detail_screen.dart';

class QuoteListScreen extends StatefulWidget {
  final Category category;

  const QuoteListScreen({super.key, required this.category});

  @override
  State<QuoteListScreen> createState() => _QuoteListScreenState();
}

class _QuoteListScreenState extends State<QuoteListScreen> {
  // Search/Filter state
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  List<Quote> _filteredQuotes = [];

  // Ads
  BannerAd? _bannerAd;
  bool _isBannerAdLoaded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<QuoteProvider>().loadQuotesForCategory(widget.category.id!);
      _loadBannerAd();
    });
  }

  void _loadBannerAd() {
    AdsService().loadBannerAd().then((ad) {
      if (mounted) {
        setState(() {
          _bannerAd = ad;
          _isBannerAdLoaded = true;
        });
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _bannerAd?.dispose();
    super.dispose();
  }

  // Filter quotes trong category hiện tại
  void _filterQuotes(String query, List<Quote> allQuotes) {
    if (query.isEmpty) {
      setState(() {
        _filteredQuotes = [];
      });
      return;
    }

    final results = allQuotes.where((quote) {
      final searchLower = query.toLowerCase();
      final textMatch = quote.text.toLowerCase().contains(searchLower);
      final authorMatch = quote.author?.toLowerCase().contains(searchLower) ?? false;
      return textMatch || authorMatch;
    }).toList();

    setState(() {
      _filteredQuotes = results;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: _isSearching ? _buildSearchField() : _buildTitle(),
        centerTitle: true,
        backgroundColor: Colors.deepPurple,
        elevation: 0,
        iconTheme: const IconThemeData(
          color: Colors.white,
        ),
        actions: [
          // Filter/Search button
          Consumer<QuoteProvider>(
            builder: (context, provider, child) {
              final quotes = provider.getQuotesForCategory(widget.category.id!);
              // Chỉ hiện nút search nếu có quotes
              if (quotes.isEmpty && !provider.isLoadingQuotes) {
                return const SizedBox.shrink();
              }
              
              return IconButton(
                icon: Icon(_isSearching ? Icons.close : Icons.filter_list),
                onPressed: () {
                  setState(() {
                    _isSearching = !_isSearching;
                    if (!_isSearching) {
                      _searchController.clear();
                      _filteredQuotes = [];
                    }
                  });
                },
                iconSize: Responsive.fontSize(context, 24),
                tooltip: _isSearching ? 'Close Filter' : 'Filter',
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Nội dung chính
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: Responsive.maxContentWidth(context),
                ),
                child: _buildQuotesList(),
              ),
            ),
          ),
          
          // Banner ad ở dưới cùng (ngoài Expanded)
          if (_isBannerAdLoaded && _bannerAd != null)
            Container(
              color: Colors.white,
              child: SafeArea(
                top: false,
                child: SizedBox(
                  width: _bannerAd!.size.width.toDouble(),
                  height: _bannerAd!.size.height.toDouble(),
                  child: AdWidget(ad: _bannerAd!),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // Build title với category info
  Widget _buildTitle() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          widget.category.icon,
          style: TextStyle(fontSize: Responsive.fontSize(context, 24)),
        ),
        SizedBox(width: Responsive.padding(context, 8)),
        Flexible(
          child: Text(
            widget.category.name,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: Responsive.fontSize(context, 20),
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  // Build search/filter text field
  Widget _buildSearchField() {
    return Consumer<QuoteProvider>(
      builder: (context, provider, child) {
        final allQuotes = provider.getQuotesForCategory(widget.category.id!);
        
        return TextField(
          controller: _searchController,
          autofocus: true,
          style: TextStyle(
            color: Colors.white,
            fontSize: Responsive.fontSize(context, 16),
          ),
          decoration: InputDecoration(
            hintText: 'Filter in ${widget.category.name}...',
            hintStyle: TextStyle(
              color: Colors.white70,
              fontSize: Responsive.fontSize(context, 16),
            ),
            border: InputBorder.none,
          ),
          onChanged: (value) {
            _filterQuotes(value, allQuotes);
          },
        );
      },
    );
  }

  // Build main quotes list
  Widget _buildQuotesList() {
    return Consumer<QuoteProvider>(
      builder: (context, provider, child) {
        // Loading state
        if (provider.isLoadingQuotes) {
          return _buildShimmerLoading();
        }

        final allQuotes = provider.getQuotesForCategory(widget.category.id!);

        // Empty state - không có quotes trong category
        if (allQuotes.isEmpty) {
          return Center(
            child: Padding(
              padding: EdgeInsets.all(Responsive.padding(context, 32)),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.format_quote,
                    size: Responsive.fontSize(context, 80),
                    color: Colors.grey[400],
                  ),
                  SizedBox(height: Responsive.padding(context, 24)),
                  Text(
                    'No quotes available',
                    style: TextStyle(
                      fontSize: Responsive.fontSize(context, 20),
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[700],
                    ),
                  ),
                  SizedBox(height: Responsive.padding(context, 8)),
                  Text(
                    'in ${widget.category.name} category',
                    style: TextStyle(
                      fontSize: Responsive.fontSize(context, 14),
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        // Quyết định hiển thị filtered hay all quotes
        final quotesToShow = _isSearching && _searchController.text.isNotEmpty
            ? _filteredQuotes
            : allQuotes;

        // Nếu đang search nhưng không có kết quả
        if (_isSearching && _searchController.text.isNotEmpty && _filteredQuotes.isEmpty) {
          return _buildNoFilterResults();
        }

        // Success state - display quotes
        return Column(
          children: [
            // Filter info header (nếu đang filter)
            if (_isSearching && _searchController.text.isNotEmpty)
              Container(
                padding: EdgeInsets.all(Responsive.padding(context, 12)),
                color: Colors.deepPurple.withValues(alpha: 0.1),
                child: Row(
                  children: [
                    Icon(
                      Icons.filter_list,
                      size: Responsive.fontSize(context, 18),
                      color: Colors.deepPurple,
                    ),
                    SizedBox(width: Responsive.padding(context, 8)),
                    Expanded(
                      child: Text(
                        'Showing ${quotesToShow.length} of ${allQuotes.length} quote${quotesToShow.length != 1 ? 's' : ''}',
                        style: TextStyle(
                          fontSize: Responsive.fontSize(context, 13),
                          fontWeight: FontWeight.w600,
                          color: Colors.deepPurple,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _searchController.clear();
                          _filteredQuotes = [];
                        });
                      },
                      child: Text(
                        'Clear',
                        style: TextStyle(
                          fontSize: Responsive.fontSize(context, 13),
                          color: Colors.deepPurple,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            // Quotes list
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  provider.clearCache();
                  await provider.loadQuotesForCategory(widget.category.id!);
                },
                child: ListView.builder(
                  padding: EdgeInsets.all(Responsive.padding(context, 16)),
                  itemCount: quotesToShow.length,
                  itemBuilder: (context, index) {
                    return _buildQuoteCard(
                      quotesToShow[index],
                      index,
                      quotesToShow,
                    );
                  },
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // No filter results
  Widget _buildNoFilterResults() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(Responsive.padding(context, 32)),
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
              'No matching quotes',
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
            SizedBox(height: Responsive.padding(context, 16)),
            TextButton.icon(
              onPressed: () {
                setState(() {
                  _searchController.clear();
                  _filteredQuotes = [];
                });
              },
              icon: const Icon(Icons.clear),
              label: const Text('Clear Filter'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.deepPurple,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Shimmer loading effect
  Widget _buildShimmerLoading() {
    final minHeight = Responsive.quoteCardMinHeight(context);
    final padding = Responsive.padding(context, 16);

    return ListView.builder(
      padding: EdgeInsets.all(padding),
      itemCount: 8,
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Container(
            margin: EdgeInsets.only(bottom: padding),
            height: minHeight,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        );
      },
    );
  }

  // Build individual quote card
  Widget _buildQuoteCard(Quote quote, int index, List<Quote> quotes) {
    final colors = ImageManager.getGradientForQuote(quote.id!);
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
              builder: (context) => QuoteDetailScreen(
                quotes: quotes,
                initialIndex: index,
              ),
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
                // Quote text
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
                // Author and favorite icon
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
}