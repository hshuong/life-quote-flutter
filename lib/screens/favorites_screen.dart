// lib/screens/favorites_screen.dart
// UPDATED: Using Theme instead of hard-coded colors

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/quote_provider.dart';
import '../utils/image_manager_enhanced.dart';
import '../utils/responsive.dart';
import 'quote_detail_screen.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context); // ✅ Get theme
    
    return Consumer<QuoteProvider>(
      builder: (context, provider, child) {
        final favorites = provider.favoriteQuotes;

        // EMPTY STATE
        if (favorites.isEmpty) {
          return Center(
            child: Padding(
              padding: EdgeInsets.all(Responsive.padding(context, 32)),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.favorite_border,
                    size: Responsive.fontSize(context, 100),
                    color: theme.textTheme.bodyMedium?.color?.withValues(alpha:0.3), // ✅ Use theme
                  ),
                  SizedBox(height: Responsive.padding(context, 24)),
                  Text(
                    'No Favorite Quotes Yet',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: Responsive.padding(context, 12)),
                  Text(
                    'Start adding quotes to your favorites\nby tapping the heart icon ❤️',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        // SUCCESS STATE - List favorites
        return ListView.builder(
          padding: EdgeInsets.all(Responsive.padding(context, 16)),
          itemCount: favorites.length,
          itemBuilder: (context, index) {
            final quote = favorites[index];
            final colors = ImageManagerEnhanced.getGradientForQuote(quote.id!);
            final padding = Responsive.padding(context, 20);
            final fontSize = Responsive.fontSize(context, 16);
            final authorSize = Responsive.fontSize(context, 14);
            final iconSize = Responsive.fontSize(context, 24);
            final textColor = ImageManagerEnhanced.getTextColor(quote.id!);

            return TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: Duration(milliseconds: 300 + (index * 30)),
              curve: Curves.easeOut,
              builder: (context, value, child) {
                return Transform.translate(
                  offset: Offset(0, 30 * (1 - value)),
                  child: Opacity(opacity: value, child: child),
                );
              },
              child: GestureDetector(
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => QuoteDetailScreen(
                        quotes: favorites,
                        initialIndex: index,
                      ),
                    ),
                  );
                  provider.loadFavoriteQuotes();
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
                            if (quote.author != null &&
                                quote.author!.isNotEmpty)
                              Expanded(
                                child: Text(
                                  '- ${quote.author}',
                                  style: TextStyle(
                                    color: textColor..withValues(alpha: 0.9),
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
                                size: iconSize,
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}