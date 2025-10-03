// lib/screens/quote_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:provider/provider.dart';
import '../models/quote.dart';
import '../providers/quote_provider.dart';
import '../utils/image_manager.dart';
import '../utils/responsive.dart';

class QuoteDetailScreen extends StatefulWidget {
  final List<Quote> quotes;
  final int initialIndex;

  const QuoteDetailScreen({
    super.key,
    required this.quotes,
    required this.initialIndex,
  });

  @override
  State<QuoteDetailScreen> createState() => _QuoteDetailScreenState();
}

class _QuoteDetailScreenState extends State<QuoteDetailScreen>
    with SingleTickerProviderStateMixin {
  late PageController _pageController;
  late int currentIndex;
  late List<Quote> quotes;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    currentIndex = widget.initialIndex;
    quotes = List.from(widget.quotes);
    
    _pageController = PageController(initialPage: currentIndex);
    
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeIn),
    );
    
    _fadeController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _toggleFavorite() async {
    final quote = quotes[currentIndex];
    final provider = context.read<QuoteProvider>();
    
    await provider.toggleFavorite(quote);
    
    setState(() {
      quotes[currentIndex] = quote.copyWith(isFavorite: !quote.isFavorite);
    });

    HapticFeedback.lightImpact();

    if (mounted) {
      final newStatus = quotes[currentIndex].isFavorite;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                newStatus ? Icons.favorite : Icons.favorite_border,
                color: Colors.white,
              ),
              const SizedBox(width: 8),
              Text(newStatus ? 'Added to favorites' : 'Removed from favorites'),
            ],
          ),
          duration: const Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
          backgroundColor: newStatus ? Colors.red : Colors.grey[800],
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  Future<void> _copyQuote() async {
    final quote = quotes[currentIndex];
    final textToCopy = '${quote.text}\n\n- ${quote.author}';
    
    await Clipboard.setData(ClipboardData(text: textToCopy));
    HapticFeedback.mediumImpact();
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: const [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Text('Quote copied to clipboard!'),
            ],
          ),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.green,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

    // Share quote
  Future<void> _shareQuote() async {
    final quote = quotes[currentIndex];
    final textToShare =
        '${quote.text}\n\n- ${quote.author}\n\n📱 Shared from Life Quotes App';
    HapticFeedback.selectionClick();

    try {
      await SharePlus.instance.share(ShareParams(text: textToShare));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to share quote'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: EdgeInsets.all(Responsive.padding(context, 8)),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.3),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.arrow_back,
              color: Colors.white,
              size: Responsive.fontSize(context, 24),
            ),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Center(
            child: Container(
              margin: EdgeInsets.only(right: Responsive.padding(context, 16)),
              padding: EdgeInsets.symmetric(
                horizontal: Responsive.padding(context, 12),
                vertical: Responsive.padding(context, 6),
              ),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${currentIndex + 1}/${quotes.length}',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: Responsive.fontSize(context, 14),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
      body: PageView.builder(
        controller: _pageController,
        itemCount: quotes.length,
        onPageChanged: (index) {
          setState(() {
            currentIndex = index;
          });
          _fadeController.reset();
          _fadeController.forward();
          HapticFeedback.selectionClick();
        },
        itemBuilder: (context, index) {
          final quote = quotes[index];
          return _buildQuotePage(quote);
        },
      ),
    );
  }

  Widget _buildQuotePage(Quote quote) {
    final decoration = ImageManager.getBackgroundDecoration(quote.id!);
    final textColor = ImageManager.getTextColor(quote.id!);

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        decoration: decoration,
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: Responsive.maxContentWidth(context),
              ),
              child: Column(
                children: [
                  Expanded(
                    child: Center(
                      child: SingleChildScrollView(
                        padding: EdgeInsets.symmetric(
                          horizontal: Responsive.padding(context, 32),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Decorative quote icon
                            TweenAnimationBuilder<double>(
                              tween: Tween(begin: 0.0, end: 1.0),
                              duration: const Duration(milliseconds: 500),
                              curve: Curves.elasticOut,
                              builder: (context, value, child) {
                                return Transform.scale(scale: value, child: child);
                              },
                              child: Icon(
                                Icons.format_quote_rounded,
                                size: Responsive.fontSize(context, 56),
                                color: textColor.withValues(alpha: 0.5),
                              ),
                            ),
                            SizedBox(height: Responsive.padding(context, 24)),
                            
                            // Quote text - Responsive font size
                            TweenAnimationBuilder<double>(
                              tween: Tween(begin: 0.0, end: 1.0),
                              duration: const Duration(milliseconds: 600),
                              curve: Curves.easeOut,
                              builder: (context, value, child) {
                                return Transform.translate(
                                  offset: Offset(0, 20 * (1 - value)),
                                  child: Opacity(opacity: value, child: child),
                                );
                              },
                              child: Text(
                                quote.text,
                                style: TextStyle(
                                  color: textColor,
                                  fontSize: Responsive.quoteDetailTextSize(context),
                                  fontWeight: FontWeight.w600,
                                  height: 1.5,
                                  letterSpacing: 0.3,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            
                            SizedBox(height: Responsive.padding(context, 32)),
                            
                            // Author
                            TweenAnimationBuilder<double>(
                              tween: Tween(begin: 0.0, end: 1.0),
                              duration: const Duration(milliseconds: 700),
                              curve: Curves.easeOut,
                              builder: (context, value, child) {
                                return Opacity(opacity: value, child: child);
                              },
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: Responsive.padding(context, 20),
                                  vertical: Responsive.padding(context, 10),
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  '- ${quote.author}',
                                  style: TextStyle(
                                    color: textColor,
                                    fontSize: Responsive.fontSize(context, 18),
                                    fontStyle: FontStyle.italic,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  
                  _buildActionButtons(quote, textColor),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons(Quote quote, Color iconColor) {
    return Container(
      padding: EdgeInsets.all(Responsive.padding(context, 24)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildActionButton(
            icon: Icons.share_rounded,
            label: 'Share',
            color: iconColor,
            onPressed: _shareQuote,
          ),
          
          _buildActionButton(
            icon: quote.isFavorite ? Icons.favorite : Icons.favorite_border,
            label: quote.isFavorite ? 'Saved' : 'Save',
            color: quote.isFavorite ? Colors.red : iconColor,
            onPressed: _toggleFavorite,
            scale: quote.isFavorite ? 1.1 : 1.0,
          ),
          
          _buildActionButton(
            icon: Icons.content_copy_rounded,
            label: 'Copy',
            color: iconColor,
            onPressed: _copyQuote,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
    double scale = 1.0,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Transform.scale(scale: value * scale, child: child);
      },
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: Responsive.padding(context, 20),
              vertical: Responsive.padding(context, 12),
            ),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.3),
                width: 1.5,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  color: color,
                  size: Responsive.fontSize(context, 28),
                ),
                SizedBox(height: Responsive.padding(context, 4)),
                Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontSize: Responsive.fontSize(context, 12),
                    fontWeight: FontWeight.w600,
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