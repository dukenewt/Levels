import 'package:flutter/material.dart';
import '../core/theme/app_design_tokens.dart';
import 'micro_interactions.dart';
import 'enhanced_card.dart';

class MicroInteractionsShowcase extends StatefulWidget {
  const MicroInteractionsShowcase({Key? key}) : super(key: key);

  @override
  State<MicroInteractionsShowcase> createState() => _MicroInteractionsShowcaseState();
}

class _MicroInteractionsShowcaseState extends State<MicroInteractionsShowcase> {
  bool _isLoading = false;
  int _tapCount = 0;

  void _simulateLoading() {
    setState(() => _isLoading = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _isLoading = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Micro Interactions Showcase'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDesignTokens.space4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildSection('Interactive Scale', [
              _buildScaleExample(),
            ]),
            
            const SizedBox(height: AppDesignTokens.space6),
            
            _buildSection('Interactive Buttons', [
              _buildButtonExamples(),
            ]),
            
            const SizedBox(height: AppDesignTokens.space6),
            
            _buildSection('Interactive Cards', [
              _buildCardExamples(),
            ]),
            
            const SizedBox(height: AppDesignTokens.space6),
            
            _buildSection('Ripple Effects', [
              _buildRippleExamples(),
            ]),
            
            const SizedBox(height: AppDesignTokens.space6),
            
            _buildSection('Enhanced Components', [
              _buildEnhancedExamples(),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: AppDesignTokens.space3),
        ...children,
      ],
    );
  }

  Widget _buildScaleExample() {
    return Column(
      children: [
        Text(
          'Tap count: $_tapCount',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: AppDesignTokens.space3),
        Row(
          children: [
            Expanded(
              child: InteractiveScale(
                onTap: () => setState(() => _tapCount++),
                child: Container(
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Theme.of(context).colorScheme.primary,
                        Theme.of(context).colorScheme.secondary,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(AppDesignTokens.radiusMd),
                    boxShadow: AppDesignTokens.shadowMedium,
                  ),
                  child: const Center(
                    child: Text(
                      'Tap Me!\n(Default Scale)',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppDesignTokens.space3),
            Expanded(
              child: InteractiveScale(
                scaleDown: 0.9,
                duration: AppDesignTokens.microSlow,
                curve: AppDesignTokens.bounceCurve,
                onTap: () => setState(() => _tapCount++),
                child: Container(
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.orange,
                        Colors.red,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(AppDesignTokens.radiusMd),
                    boxShadow: AppDesignTokens.shadowMedium,
                  ),
                  child: const Center(
                    child: Text(
                      'Bouncy Scale!\n(Custom)',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildButtonExamples() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: InteractiveButton(
                onPressed: () => _simulateLoading(),
                backgroundColor: Theme.of(context).colorScheme.primary,
                child: const Text(
                  'Primary Button',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
            const SizedBox(width: AppDesignTokens.space3),
            Expanded(
              child: InteractiveButton(
                onPressed: null, // Disabled
                child: const Text('Disabled Button'),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppDesignTokens.space3),
        Row(
          children: [
            Expanded(
              child: InteractiveButton(
                onPressed: () {},
                backgroundColor: Colors.green,
                isLoading: _isLoading,
                child: const Text(
                  'Loading Button',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
            const SizedBox(width: AppDesignTokens.space3),
            Expanded(
              child: InteractiveButton(
                onPressed: () {},
                backgroundColor: Colors.red,
                borderRadius: BorderRadius.circular(AppDesignTokens.radiusXl),
                child: const Text(
                  'Rounded Button',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCardExamples() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: InteractiveCard(
                onTap: () => print('Card 1 tapped'),
                child: Column(
                  children: [
                    Icon(
                      Icons.star,
                      size: 32,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: AppDesignTokens.space2),
                    const Text('Interactive Card'),
                    const SizedBox(height: AppDesignTokens.space1),
                    Text(
                      'Tap me for feedback',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: AppDesignTokens.space3),
            Expanded(
              child: InteractiveCard(
                onTap: () => print('Card 2 tapped'),
                onLongPress: () => print('Card 2 long pressed'),
                enableHoverEffect: true,
                child: Column(
                  children: [
                    Icon(
                      Icons.touch_app,
                      size: 32,
                      color: Colors.orange,
                    ),
                    const SizedBox(height: AppDesignTokens.space2),
                    const Text('Hover & Press'),
                    const SizedBox(height: AppDesignTokens.space1),
                    Text(
                      'Hover + long press',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppDesignTokens.space3),
        InteractiveCard(
          enabled: false,
          child: Row(
            children: [
              Icon(
                Icons.block,
                color: Colors.grey,
              ),
              const SizedBox(width: AppDesignTokens.space3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Disabled Card'),
                    Text(
                      'This card is disabled and shows reduced opacity',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRippleExamples() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: AnimatedRipple(
                onTap: () => print('Ripple 1'),
                rippleColor: Colors.blue.withOpacity(0.3),
                child: Container(
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(AppDesignTokens.radiusMd),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: const Center(
                    child: Text('Blue Ripple'),
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppDesignTokens.space3),
            Expanded(
              child: AnimatedRipple(
                onTap: () => print('Ripple 2'),
                rippleColor: Colors.green.withOpacity(0.3),
                duration: const Duration(milliseconds: 800),
                child: Container(
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(AppDesignTokens.radiusMd),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: const Center(
                    child: Text('Slow Green Ripple'),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEnhancedExamples() {
    return Column(
      children: [
        const Text('Enhanced Card with Micro Interactions:'),
        const SizedBox(height: AppDesignTokens.space3),
        EnhancedCard(
          isInteractive: true,
          shadowLevel: CardShadowLevel.medium,
          onTap: () => print('Enhanced card tapped'),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).colorScheme.primary,
                      Theme.of(context).colorScheme.secondary,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(AppDesignTokens.radiusMd),
                ),
                child: const Icon(
                  Icons.animation,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: AppDesignTokens.space4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Enhanced Interactive Card',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: AppDesignTokens.space1),
                    Text(
                      'This combines our layered shadows with the new micro interactions system for the best of both worlds.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
} 