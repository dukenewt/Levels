import 'package:flutter/material.dart';

class CalendarViewSelector extends StatelessWidget {
  final String currentView;
  final void Function(BuildContext, String) onViewChanged;

  const CalendarViewSelector({
    Key? key,
    required this.currentView,
    required this.onViewChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final Map<String, Color> viewColors = {
      'day': theme.colorScheme.primary,
      'week': theme.colorScheme.secondary,
      'month': theme.colorScheme.tertiary ?? theme.colorScheme.primaryContainer,
    };
    final Map<String, String> viewLabels = {
      'day': 'Day',
      'week': 'Week',
      'month': 'Month',
    };

    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 0),
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              theme.colorScheme.primary.withOpacity(0.7),
              theme.colorScheme.secondary.withOpacity(0.7),
              (theme.colorScheme.tertiary ?? theme.colorScheme.primaryContainer).withOpacity(0.7),
            ],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: ['day', 'week', 'month'].map((view) {
            final bool selected = currentView == view;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                decoration: BoxDecoration(
                  color: selected ? viewColors[view] : Colors.transparent,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: selected
                      ? [
                          BoxShadow(
                            color: viewColors[view]!.withOpacity(0.25),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : [],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(28),
                    onTap: () => onViewChanged(context, view),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                      child: Text(
                        viewLabels[view]!,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: selected
                              ? theme.colorScheme.onPrimary
                              : theme.textTheme.titleMedium?.color?.withOpacity(0.85),
                          fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}