import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../models/theme_model.dart';
import '../widgets/glass_card.dart';

class ThemeSelectionScreen extends StatelessWidget {
  const ThemeSelectionScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final availableThemes = themeProvider.availableThemes;
    final premiumThemes = themeProvider.premiumThemes;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Themes'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (availableThemes.isNotEmpty) ...[
            Text(
              'Available Themes',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...availableThemes.map((theme) => _buildThemeCard(
              context,
              theme,
              themeProvider,
              isSelected: theme.type == themeProvider.currentTheme,
            )),
          ],
          if (premiumThemes.isNotEmpty) ...[
            const SizedBox(height: 32),
            Text(
              'Premium Themes',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...premiumThemes.map((theme) => _buildThemeCard(
              context,
              theme,
              themeProvider,
              isSelected: theme.type == themeProvider.currentTheme,
              isLocked: !themeProvider.isThemeUnlocked(theme.type),
            )),
          ],
        ],
      ),
    );
  }

  Widget _buildThemeCard(
    BuildContext context,
    AppTheme theme,
    ThemeProvider themeProvider, {
    required bool isSelected,
    bool isLocked = false,
  }) {
    return GlassCard(
      margin: const EdgeInsets.only(bottom: 16),
      onTap: isLocked
          ? () => _showPremiumDialog(context, theme)
          : () => themeProvider.setTheme(theme.type),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      theme.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      theme.description,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Icon(
                  Icons.check_circle,
                  color: Theme.of(context).colorScheme.primary,
                )
              else if (isLocked)
                Icon(
                  Icons.lock,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            height: 100,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: theme.gradientColors,
              ),
            ),
            child: Center(
              child: Text(
                'Preview',
                style: TextStyle(
                  color: theme.textColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          if (isLocked) ...[
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Premium Theme',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                ElevatedButton(
                  onPressed: () => _showPremiumDialog(context, theme),
                  child: const Text('Unlock'),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  void _showPremiumDialog(BuildContext context, AppTheme theme) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Unlock ${theme.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This premium theme includes:',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            _buildFeatureItem(context, 'Glassmorphism effects'),
            _buildFeatureItem(context, 'Custom gradients'),
            _buildFeatureItem(context, 'Priority indicators'),
            _buildFeatureItem(context, 'Exclusive animations'),
            const SizedBox(height: 16),
            Text(
              'Unlock this theme for 500 coins',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // TODO: Implement premium theme purchase
              Navigator.pop(context);
            },
            child: const Text('Purchase'),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(BuildContext context, String feature) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            Icons.check_circle,
            size: 16,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Text(feature),
        ],
      ),
    );
  }
} 