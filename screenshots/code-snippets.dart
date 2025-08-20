// We could place this in a new file, e.g., 'lib/services/task_analyzer_service.dart'

class TaskDifficultySuggester {
  static const Map<String, String> keywordMap = {
    // Easy Keywords (often quick, simple actions)
    'call': 'easy',
    'email': 'easy',
    'text': 'easy',
    'buy': 'easy',
    'schedule': 'easy',
    'plan': 'easy',
    'tidy': 'easy',
    'water plants': 'easy',

    // Medium Keywords (require more sustained effort or focus)
    'read': 'medium',
    'write': 'medium',
    'review': 'medium',
    'laundry': 'medium',
    'dishes': 'medium',
    'cook': 'medium',
    'clean': 'medium',

    // Hard Keywords (often require significant physical or mental energy)
    'gym': 'hard',
    'workout': 'hard',
    'exercise': 'hard',
    'study': 'hard',
    'research': 'hard',
    'project': 'hard',
    'prepare presentation': 'hard',
    
    // Epic Keywords (major, multi-hour commitments)
    'deep clean': 'epic',
    'build': 'epic',
    'finish project': 'epic'
  };

  static String suggestDifficulty(String taskTitle) {
    final title = taskTitle.toLowerCase();

    // Prioritize longer, more specific phrases first
    for (var entry in keywordMap.entries) {
      if (title.contains(entry.key)) {
        return entry.value; // Return the difficulty for the first match
      }
    }

    // Default to medium if no keywords are found
    return 'medium';
  }
}

// In _EnhancedTaskCreationDialogState

void _onTitleChanged(String title) {
  final suggestedDifficulty = TaskDifficultySuggester.suggestDifficulty(title);
  setState(() {
    _difficulty = suggestedDifficulty;
  });
  _updateEstimatedXp();
}

// Then in your title's TextFormField:
TextFormField(
  controller: _titleController,
  onChanged: _onTitleChanged, // Call the new method here
  //... rest of the widget
)