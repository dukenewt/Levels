///reset function for UserProvider

Future<void> resetToLevelOne() async {
  if (_user != null) {
    final updatedUser = _user!.copyWith(
      level: 1,
      currentXp: 0,
    );
    await _firestoreService.setUser(updatedUser);
    _user = updatedUser;
    notifyListeners();
  }
}


//reset button for SettingsScreen
ListTile(
  leading: const Icon(Icons.replay, color: Colors.red),
  title: const Text('Reset to Level One'),
  subtitle: const Text('This will reset your level and XP.'),
  onTap: () {
    // Show a confirmation dialog before resetting
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Are you sure?'),
          content: const Text('This will reset your level and XP to zero.'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Reset'),
              onPressed: () {
                Provider.of<UserProvider>(context, listen: false).resetToLevelOne();
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  },
),