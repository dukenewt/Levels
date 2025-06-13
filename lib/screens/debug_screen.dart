import 'package:flutter/material.dart';
import '../core/theme/app_design_tokens.dart';
import '../widgets/enhanced_card.dart';
import '../widgets/micro_interactions_showcase.dart';

class DebugScreen extends StatelessWidget {
  const DebugScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(title: const Text('Debug Tools & Design System')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Debug Tools Section
            Text(
              'Debug Tools',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Set coins to 1000')),
                );
              },
              child: const Text('Set 1000 Coins'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const MicroInteractionsShowcase(),
                  ),
                );
              },
              child: const Text('View Micro Interactions'),
            ),
            
            const SizedBox(height: 32),
            const Divider(),
            const SizedBox(height: 32),
            
            // Shadow System Showcase
            Text(
              'Enhanced Shadow System',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Experience the new layered shadows with enhanced depth and vibrancy',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 24),

            // Shadow Levels
            _buildSection(
              'Shadow Levels',
              'Different elevation levels for visual hierarchy',
              context,
              [
                _buildShadowCard('Low Shadow', CardShadowLevel.low, context),
                _buildShadowCard('Medium Shadow', CardShadowLevel.medium, context),
                _buildShadowCard('High Shadow', CardShadowLevel.high, context),
                _buildShadowCard('Extra High Shadow', CardShadowLevel.xHigh, context),
              ],
            ),

            const SizedBox(height: 24),

            // Interactive Elements
            _buildSection(
              'Interactive Elements',
              'Tap to see dynamic shadow changes',
              context,
              [
                EnhancedCard(
                  isInteractive: true,
                  shadowLevel: CardShadowLevel.medium,
                  onTap: () => _showSnackbar(context, 'Interactive card tapped!'),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Interactive Card',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Tap to see dynamic shadows and press animation',
                        style: TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Colored Accent Shadows
            _buildSection(
              'Colored Accent Shadows',
              'Priority-based colored shadows for visual importance',
              context,
              [
                EnhancedCard(
                  isHighPriority: true,
                  accentColor: theme.colorScheme.primary,
                  shadowLevel: CardShadowLevel.medium,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.priority_high,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'High Priority Task',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Notice the blue accent shadow that adds visual importance',
                        style: TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                EnhancedCard(
                  isHighPriority: true,
                  accentColor: Colors.green,
                  shadowLevel: CardShadowLevel.medium,
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.check_circle,
                            color: Colors.green,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Completed Task',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Green accent shadow indicates completion',
                        style: TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                EnhancedCard(
                  isHighPriority: true,
                  accentColor: Colors.purple,
                  shadowLevel: CardShadowLevel.medium,
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.star,
                            color: Colors.purple,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Epic Difficulty Task',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Purple accent shadow for epic difficulty tasks',
                        style: TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Enhanced Buttons
            _buildSection(
              'Enhanced Buttons',
              'Buttons with responsive press animations and shadows',
              context,
              [
                Row(
                  children: [
                    Expanded(
                      child: EnhancedButton(
                        onPressed: () => _showSnackbar(context, 'Primary button pressed!'),
                        child: const Text('Primary Button'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: EnhancedButton(
                        isPrimary: false,
                        onPressed: () => _showSnackbar(context, 'Secondary button pressed!'),
                        child: const Text('Secondary Button'),
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Comparison
            _buildSection(
              'Before vs After Comparison',
              'See the difference between flat and layered shadows',
              context,
              [
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: theme.cardColor,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Before: Flat Shadow',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Single, weak shadow\nLacks depth',
                              style: TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: EnhancedCard(
                        shadowLevel: CardShadowLevel.medium,
                        child: const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'After: Layered Shadow',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Multiple shadow layers\nCreates realistic depth',
                              style: TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSection(String title, String description, BuildContext context, List<Widget> children) {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          description,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
        const SizedBox(height: 16),
        ...children,
      ],
    );
  }

  Widget _buildShadowCard(String title, CardShadowLevel level, BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: EnhancedCard(
        shadowLevel: level,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'This card uses ${level.name} shadow level',
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  void _showSnackbar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
      ),
    );
  }
} 