// lib/screens/quote_list_screen.dart
// ✅ FULLY UPDATED with Material Design 3 Color Roles

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../models/category.dart';
import '../models/quote.dart';
import '../providers/quote_provider.dart';
import '../utils/image_manager_enhanced.dart';
import '../utils/responsive.dart';
import '../services/ads_service.dart';
import 'quote_detail_screen.dart';

class QuoteListScreen extends StatefulWidget {
  final Category category;

  const QuoteListScreen({
    super.key,
    required this.category,
  });

  @override
  State<QuoteListScreen> createState() => _QuoteListScreenState();
}

class _QuoteListScreenState extends State<QuoteListScreen> {
  BannerAd? _bannerAd;
  bool _isBannerAdLoaded = false;

  @override
  void initState() {
    super.initState();
    _initializeScreen();
  }

  void _initializeScreen() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final provider = context.read<QuoteProvider>();
        provider.loadQuotesForCategory(widget.category.id!);
        _loadBannerAd();
      }
    });
  }

  Future<void> _loadBannerAd() async {
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
        _bannerAd = ad;
        _isBannerAdLoaded = true;
      });
    }
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme; // ✅ Get color scheme
    
    return Scaffold(
      // ✅ Use surface color
      backgroundColor: colorScheme.surface,
      
      appBar: AppBar(
        title: Text(
          widget.category.name,
          style: Theme.of(context).appBarTheme.titleTextStyle?.copyWith(
            fontSize: Responsive.fontSize(context, 22),
          ),
        ),
        centerTitle: true,
        // AppBar already uses surface from theme
        elevation: 0,
      ),
      
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: Responsive.maxContentWidth(context),
                ),
                child: Consumer<QuoteProvider>(
                  builder: (context, provider, child) {
                    if (provider.isLoadingQuotes) {
                      return _buildLoadingState();
                    }

                    if (provider.error != null) {
                      return _buildErrorState(provider);
                    }

                    final quotes = provider.getQuotesForCategory(widget.category.id!);

                    if (quotes.isEmpty) {
                      return _buildEmptyState();
                    }

                    return _buildQuotesList(quotes);
                  },
                ),
              ),
            ),
          ),
          
          // Banner Ad
          if (_isBannerAdLoaded && _bannerAd != null)
            Container(
              margin: EdgeInsets.only(
                top: Responsive.padding(context, 4),
                bottom: Responsive.padding(context, 4),
              ),
              decoration: BoxDecoration(
                // ✅ Use surface color
                color: colorScheme.surface,
                boxShadow: [
                  BoxShadow(
                    // ✅ Use shadow from theme
                    color: colorScheme.shadow.withValues(alpha:0.1),
                    blurRadius: 4,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
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

  Widget _buildQuotesList(List<Quote> quotes) {
    return ListView.builder(
      padding: EdgeInsets.all(Responsive.padding(context, 16)),
      itemCount: quotes.length,
      itemBuilder: (context, index) {
        final quote = quotes[index];
        return _buildQuoteCard(quote, index, quotes);
      },
    );
  }

  Widget _buildQuoteCard(Quote quote, int index, List<Quote> quotes) {
    // Keep existing gradient logic for visual appeal
    final colors = ImageManagerEnhanced.getGradientForQuote(quote.id!);
    final padding = Responsive.padding(context, 20);
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
              builder: (context) => QuoteDetailScreen(
                quotes: quotes,
                initialIndex: index,
              ),
            ),
          );
          
          if (mounted) {
            final provider = context.read<QuoteProvider>();
            provider.loadQuotesForCategory(widget.category.id!);
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
                color: colors[0].withValues(alpha:0.3),
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

  Widget _buildLoadingState() {
    final colorScheme = Theme.of(context).colorScheme;
    final padding = Responsive.padding(context, 16);

    return ListView.builder(
      padding: EdgeInsets.all(padding),
      itemCount: 8,
      itemBuilder: (context, index) {
        return Container(
          margin: EdgeInsets.only(bottom: padding),
          child: Shimmer.fromColors(
            // ✅ Use surface variants for shimmer
            baseColor: colorScheme.surfaceContainerHighest,
            highlightColor: colorScheme.surfaceContainerLow,
            child: Container(
              height: Responsive.quoteCardMinHeight(context),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainer,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        );
      },
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
              // ✅ Use error color
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
                provider.loadQuotesForCategory(widget.category.id!);
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

  Widget _buildEmptyState() {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    
    return Center(
      child: Padding(
        padding: EdgeInsets.all(Responsive.padding(context, 32)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.format_quote,
              size: Responsive.fontSize(context, 80),
              // ✅ Use onSurfaceVariant for secondary icons
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            SizedBox(height: Responsive.padding(context, 16)),
            Text(
              'No quotes found',
              style: textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: Responsive.padding(context, 8)),
            Text(
              'Try another category',
              style: textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}