// lib/screens/quote_list_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import '../models/category.dart';
import '../models/quote.dart';
import '../providers/quote_provider.dart';
import '../utils/image_manager.dart';
import '../utils/responsive.dart';
import 'quote_detail_screen.dart';

class QuoteListScreen extends StatefulWidget {
  final Category category;

  const QuoteListScreen({super.key, required this.category});

  @override
  State<QuoteListScreen> createState() => _QuoteListScreenState();
}

class _QuoteListScreenState extends State<QuoteListScreen> {
  // Search state
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  List<Quote> _searchResults = [];
  bool _isSearchLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<QuoteProvider>().loadQuotesForCategory(widget.category.id!);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Thực hiện tìm kiếm
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
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: _isSearching ? _buildSearchField() : _buildTitle(),
        centerTitle: true,
        backgroundColor: Colors.deepPurple,
        elevation: 0,
        actions: [
          // Search button
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
          child: _isSearching ? _buildSearchResults() : _buildQuotesList(),
        ),
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

  // Build search text field
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
        // Debounce search - chờ 500ms sau khi user ngừng gõ
        Future.delayed(const Duration(milliseconds: 500), () {
          if (_searchController.text == value) {
            _performSearch(value);
          }
        });
      },
    );
  }

  // Build search results view
  Widget _buildSearchResults() {
    // Loading state
    if (_isSearchLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.deepPurple),
      );
    }

    // Empty query - show search prompt
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

    // No results found
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

    // Display search results
    return Column(
      children: [
        // Result count header
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
        // Results list
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

  // Build main quotes list (from category)
  Widget _buildQuotesList() {
    return Consumer<QuoteProvider>(
      builder: (context, provider, child) {
        // Loading state
        if (provider.isLoadingQuotes) {
          return _buildShimmerLoading();
        }

        final quotes = provider.getQuotesForCategory(widget.category.id!);

        // Empty state
        if (quotes.isEmpty) {
          return Center(
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
          );
        }

        // Success state - display quotes
        return RefreshIndicator(
          onRefresh: () async {
            provider.clearCache();
            await provider.loadQuotesForCategory(widget.category.id!);
          },
          child: ListView.builder(
            padding: EdgeInsets.all(Responsive.padding(context, 16)),
            itemCount: quotes.length,
            itemBuilder: (context, index) {
              return _buildQuoteCard(quotes[index], index, quotes);
            },
          ),
        );
      },
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