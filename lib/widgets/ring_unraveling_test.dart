import 'package:flutter/material.dart';
import '../services/enhanced_celebration_controller.dart';

/// Test widget to preview the enhanced ring unraveling celebration
/// This helps you see the new dot sizes, XP bar colors, and unraveling effect
class RingUnravelingTest extends StatefulWidget {
  const RingUnravelingTest({Key? key}) : super(key: key);

  @override
  State<RingUnravelingTest> createState() => _RingUnravelingTestState();
}

class _RingUnravelingTestState extends State<RingUnravelingTest> {
  Color _selectedColor = Colors.blue;
  double _progressValue = 1.0;
  int _levelValue = 15;
  
  final List<Color> _colorOptions = [
    Colors.blue,
    Colors.green,
    Colors.purple,
    Colors.orange,
    Colors.red,
    Colors.teal,
    Colors.indigo,
  ];
  
  final List<String> _testPerks = [
    'Enhanced Focus',
    'Streak Master', 
    'Time Warrior',
    'Productivity Boost',
    'Achievement Hunter',
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ring Unraveling Test'),
        backgroundColor: _selectedColor,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Color Selection
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'XP Bar Color',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      children: _colorOptions.map((color) {
                        final isSelected = _selectedColor == color;
                        return GestureDetector(
                          onTap: () => setState(() => _selectedColor = color),
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              border: isSelected
                                  ? Border.all(color: Colors.white, width: 3)
                                  : null,
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: color.withOpacity(0.5),
                                        blurRadius: 8,
                                        spreadRadius: 2,
                                      ),
                                    ]
                                  : null,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Progress Control
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'XP Progress: ${(_progressValue * 100).toStringAsFixed(0)}%',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Slider(
                      value: _progressValue,
                      onChanged: (value) => setState(() => _progressValue = value),
                      activeColor: _selectedColor,
                      min: 0.1,
                      max: 1.0,
                      divisions: 9,
                    ),
                    // Visual preview of the XP bar
                    Container(
                      height: 12,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(6),
                        color: _selectedColor.withOpacity(0.2),
                      ),
                      child: FractionallySizedBox(
                        widthFactor: _progressValue,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(6),
                            gradient: LinearGradient(
                              colors: [
                                _selectedColor.withOpacity(0.6),
                                _selectedColor,
                                _selectedColor.withOpacity(0.8),
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: _selectedColor.withOpacity(0.4),
                                blurRadius: 4,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Level Control
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Level: $_levelValue',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Slider(
                      value: _levelValue.toDouble(),
                      onChanged: (value) => setState(() => _levelValue = value.round()),
                      activeColor: _selectedColor,
                      min: 5,
                      max: 50,
                      divisions: 45,
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Test Button
            ElevatedButton(
              onPressed: _showTestCelebration,
              style: ElevatedButton.styleFrom(
                backgroundColor: _selectedColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.celebration, size: 24),
                  const SizedBox(width: 8),
                  const Text(
                    'Test Enhanced Unraveling Animation',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Info Card
            Card(
              color: _selectedColor.withOpacity(0.1),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: _selectedColor),
                        const SizedBox(width: 8),
                        Text(
                          'Enhanced Features',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: _selectedColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildFeatureItem('Variable dot sizes (6-10px base)', Icons.fiber_manual_record),
                    _buildFeatureItem('XP bar gradient colors', Icons.gradient),
                    _buildFeatureItem('Physics-based unraveling', Icons.scatter_plot),
                    _buildFeatureItem('Staggered animation timing', Icons.timeline),
                    _buildFeatureItem('Glowing particle effects', Icons.auto_awesome),
                    _buildFeatureItem('Motion trails for fast dots', Icons.show_chart),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildFeatureItem(String text, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: _selectedColor.withOpacity(0.7)),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              color: _selectedColor.withOpacity(0.8),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
  
  void _showTestCelebration() {
    // Show a preview of the enhanced unraveling animation
    EnhancedCelebrationController.instance.showPreviewCelebration(
      context: context,
      xpBarColor: _selectedColor,
      level: _levelValue,
      progress: _progressValue,
      testPerks: _testPerks.take(3).toList(),
    );
  }
} 