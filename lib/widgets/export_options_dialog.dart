import 'package:flutter/material.dart';
import '../models/export_config.dart';

class ExportOptionsDialog extends StatefulWidget {
  const ExportOptionsDialog({Key? key}) : super(key: key);

  @override
  _ExportOptionsDialogState createState() => _ExportOptionsDialogState();
}

class _ExportOptionsDialogState extends State<ExportOptionsDialog> {
  ExportPurpose selectedPurpose = ExportPurpose.backup;
  int completedTasksDays = 30;
  bool includeTestData = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Export Options'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('What do you want to export?'),
            const SizedBox(height: 16),
            DropdownButtonFormField<ExportPurpose>(
              value: selectedPurpose,
              decoration: const InputDecoration(labelText: 'Export Purpose'),
              items: [
                DropdownMenuItem(
                  value: ExportPurpose.backup,
                  child: Text('Backup (recommended)'),
                ),
                DropdownMenuItem(
                  value: ExportPurpose.deviceTransfer,
                  child: Text('Device Transfer'),
                ),
                DropdownMenuItem(
                  value: ExportPurpose.fullArchive,
                  child: Text('Complete Archive'),
                ),
              ],
              onChanged: (value) => setState(() => selectedPurpose = value!),
            ),
            const SizedBox(height: 16),
            if (selectedPurpose != ExportPurpose.fullArchive)
              Column(
                children: [
                  const Text('Include completed tasks from last:'),
                  Slider(
                    value: completedTasksDays.toDouble(),
                    min: 7,
                    max: 365,
                    divisions: 51,
                    label: '$completedTasksDays days',
                    onChanged: (value) => setState(() => completedTasksDays = value.round()),
                  ),
                ],
              ),
            CheckboxListTile(
              title: const Text('Include test/debug tasks'),
              value: includeTestData,
              onChanged: (value) => setState(() => includeTestData = value ?? false),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            final config = ExportConfig(
              purpose: selectedPurpose,
              completedTasksDaysLimit: selectedPurpose == ExportPurpose.fullArchive ? null : completedTasksDays,
              includeTestData: includeTestData,
            );
            Navigator.pop(context, config);
          },
          child: const Text('Export'),
        ),
      ],
    );
  }
} 