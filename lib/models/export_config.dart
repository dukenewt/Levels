// Export configuration and purpose enums for backup/export logic

enum ExportPurpose { backup, deviceTransfer, troubleshooting, fullArchive }

class ExportConfig {
  final bool includeCompletedTasks;
  final int? completedTasksDaysLimit; // null = all, number = last X days
  final bool includeArchivedData;
  final bool includeTestData; // filter out obvious test tasks
  final ExportPurpose purpose;

  const ExportConfig({
    this.includeCompletedTasks = true,
    this.completedTasksDaysLimit = 30, // default: last 30 days
    this.includeArchivedData = false,
    this.includeTestData = false,
    this.purpose = ExportPurpose.backup,
  });

  // Predefined configurations for common use cases
  static const ExportConfig backup = ExportConfig(
    includeCompletedTasks: true,
    completedTasksDaysLimit: 30,
    includeArchivedData: false,
    purpose: ExportPurpose.backup,
  );

  static const ExportConfig deviceTransfer = ExportConfig(
    includeCompletedTasks: true,
    completedTasksDaysLimit: 7, // only recent completed tasks
    includeArchivedData: false,
    purpose: ExportPurpose.deviceTransfer,
  );

  static const ExportConfig fullArchive = ExportConfig(
    includeCompletedTasks: true,
    completedTasksDaysLimit: null, // all tasks
    includeArchivedData: true,
    purpose: ExportPurpose.fullArchive,
  );
} 