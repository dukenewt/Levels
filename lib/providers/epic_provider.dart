import 'package:flutter/material.dart';
import '../models/epic_project.dart';
import '../models/user.dart';
import '../services/secure_storage_service.dart';
import '../services/talent_management_service.dart';
import '../core/error_handling.dart';
import 'package:uuid/uuid.dart';
import 'dart:convert';

enum EpicOperationState {
  idle,
  loading,
  saving,
  deleting,
  completing,
}

class EpicProvider with ChangeNotifier {
  List<EpicProject> _epics = [];
  final SecureStorageService _storage;
  
  // State management
  EpicOperationState _operationState = EpicOperationState.idle;
  AppException? _lastError;
  bool _isInitialized = false;
  bool _isInitializing = false;
  
  // final _uuid = const Uuid(); // Unused but kept for future functionality

  EpicProvider({
    required SecureStorageService storage,
  }) : _storage = storage;

  // Getters
  List<EpicProject> get epics => List.unmodifiable(_epics);
  EpicOperationState get operationState => _operationState;
  AppException? get lastError => _lastError;
  bool get isInitialized => _isInitialized;
  bool get isLoading => _operationState != EpicOperationState.idle;

  // Get epics by status
  List<EpicProject> get activeEpics => 
      _epics.where((epic) => epic.status == EpicStatus.active).toList();
  
  List<EpicProject> get completedEpics => 
      _epics.where((epic) => epic.status == EpicStatus.completed).toList();
  
  List<EpicProject> get planningEpics => 
      _epics.where((epic) => epic.status == EpicStatus.planning).toList();

  // Get epics for a specific user
  List<EpicProject> getEpicsForUser(String userId) {
    return TalentManagementService.getEpicProjectsForUser(userId, _epics);
  }

  // Find epic containing a specific task
  EpicProject? findEpicForTask(String taskId) {
    return TalentManagementService.findEpicForTask(taskId, _epics);
  }

  /// Initialize the provider
  Future<void> initialize() async {
    if (_isInitialized || _isInitializing) return;
    
    _isInitializing = true;
    _setOperationState(EpicOperationState.loading);
    
    try {
      await _loadEpics();
      _isInitialized = true;
      _clearError();
    } catch (e) {
      _setError(StorageException('Failed to initialize epic provider: $e'));
    } finally {
      _isInitializing = false;
      _setOperationState(EpicOperationState.idle);
    }
  }

  /// Load epics from storage
  Future<void> _loadEpics() async {
    try {
      final result = await _storage.getData<String>('epic_projects', defaultValue: '[]');
      if (!result.isSuccess) {
        throw result.error!;
      }
      
      final epicsJson = result.data!;
      final List<dynamic> epicsList = epicsJson == '[]' ? [] : json.decode(epicsJson);
      
      _epics = epicsList
          .map((json) => EpicProject.fromJson(json as Map<String, dynamic>))
          .toList();
      
      notifyListeners();
    } catch (e) {
      throw StorageException('Failed to load epic projects: $e');
    }
  }

  /// Save epics to storage
  Future<void> _saveEpics() async {
    try {
      final epicsJson = _epics.map((epic) => epic.toJson()).toList();
      final jsonString = json.encode(epicsJson);
      final result = await _storage.saveData('epic_projects', jsonString);
      if (!result.isSuccess) {
        throw result.error!;
      }
    } catch (e) {
      throw StorageException('Failed to save epic projects: $e');
    }
  }

  /// Create a new epic project
  Future<EpicProject?> createEpic({
    required String title,
    required String description,
    required List<String> taskIds,
    required User user,
    DateTime? dueDate,
  }) async {
    _setOperationState(EpicOperationState.saving);
    
    try {
      // Validate epic creation
      final validationError = TalentManagementService.validateEpicCreation(
        user: user,
        title: title,
        taskIds: taskIds,
      );
      
      if (validationError != null) {
        _setError(ValidationException(validationError));
        return null;
      }

      // Create the epic project
      final epic = TalentManagementService.createEpicProject(
        title: title,
        description: description,
        userId: user.id,
        taskIds: taskIds,
        dueDate: dueDate,
      );

      // Add to local list
      _epics.add(epic);
      
      // Save to storage
      await _saveEpics();
      
      _clearError();
      notifyListeners();
      
      return epic;
    } catch (e) {
      _setError(StorageException('Failed to create epic project: $e'));
      return null;
    } finally {
      _setOperationState(EpicOperationState.idle);
    }
  }

  /// Start an epic project
  Future<bool> startEpic(String epicId) async {
    _setOperationState(EpicOperationState.saving);
    
    try {
      final epicIndex = _epics.indexWhere((epic) => epic.id == epicId);
      if (epicIndex == -1) {
        _setError(ValidationException('Epic project not found'));
        return false;
      }

      final epic = _epics[epicIndex];
      final startedEpic = TalentManagementService.startEpic(epic);
      
      _epics[epicIndex] = startedEpic;
      await _saveEpics();
      
      _clearError();
      notifyListeners();
      
      return true;
    } catch (e) {
      _setError(StorageException('Failed to start epic project: $e'));
      return false;
    } finally {
      _setOperationState(EpicOperationState.idle);
    }
  }

  /// Update epic progress when a task is completed
  Future<EpicProject?> updateEpicProgress(String taskId) async {
    try {
      final epic = findEpicForTask(taskId);
      if (epic == null) return null;

      final updatedEpic = TalentManagementService.updateEpicProgress(epic, taskId);
      if (updatedEpic == null) return null;

      // Update in local list
      final epicIndex = _epics.indexWhere((e) => e.id == epic.id);
      if (epicIndex != -1) {
        _epics[epicIndex] = updatedEpic;
        await _saveEpics();
        notifyListeners();
      }

      return updatedEpic;
    } catch (e) {
      _setError(StorageException('Failed to update epic progress: $e'));
      return null;
    }
  }

  /// Update an existing epic project
  Future<bool> updateEpic(EpicProject updatedEpic) async {
    _setOperationState(EpicOperationState.saving);
    
    try {
      final epicIndex = _epics.indexWhere((epic) => epic.id == updatedEpic.id);
      if (epicIndex == -1) {
        _setError(ValidationException('Epic project not found'));
        return false;
      }

      _epics[epicIndex] = updatedEpic;
      await _saveEpics();
      
      _clearError();
      notifyListeners();
      
      return true;
    } catch (e) {
      _setError(StorageException('Failed to update epic project: $e'));
      return false;
    } finally {
      _setOperationState(EpicOperationState.idle);
    }
  }

  /// Delete an epic project
  Future<bool> deleteEpic(String epicId) async {
    _setOperationState(EpicOperationState.deleting);
    
    try {
      final epicIndex = _epics.indexWhere((epic) => epic.id == epicId);
      if (epicIndex == -1) {
        _setError(ValidationException('Epic project not found'));
        return false;
      }

      _epics.removeAt(epicIndex);
      await _saveEpics();
      
      _clearError();
      notifyListeners();
      
      return true;
    } catch (e) {
      _setError(StorageException('Failed to delete epic project: $e'));
      return false;
    } finally {
      _setOperationState(EpicOperationState.idle);
    }
  }

  /// Complete an epic project manually
  Future<bool> completeEpic(String epicId) async {
    _setOperationState(EpicOperationState.completing);
    
    try {
      final epicIndex = _epics.indexWhere((epic) => epic.id == epicId);
      if (epicIndex == -1) {
        _setError(ValidationException('Epic project not found'));
        return false;
      }

      final epic = _epics[epicIndex];
      final completedEpic = epic.copyWith(
        status: EpicStatus.completed,
        completedAt: DateTime.now(),
        completedTasks: epic.requiredTasks,
      );
      
      _epics[epicIndex] = completedEpic;
      await _saveEpics();
      
      _clearError();
      notifyListeners();
      
      return true;
    } catch (e) {
      _setError(StorageException('Failed to complete epic project: $e'));
      return false;
    } finally {
      _setOperationState(EpicOperationState.idle);
    }
  }

  /// Get epic by ID
  EpicProject? getEpicById(String epicId) {
    try {
      return _epics.firstWhere((epic) => epic.id == epicId);
    } catch (e) {
      return null;
    }
  }

  /// Clear all data (for testing/debugging)
  Future<void> clearAllData() async {
    _setOperationState(EpicOperationState.deleting);
    
    try {
      _epics.clear();
      final result = await _storage.saveData('epic_projects', '[]');
      if (!result.isSuccess) {
        throw result.error!;
      }
      _clearError();
      notifyListeners();
    } catch (e) {
      _setError(StorageException('Failed to clear epic data: $e'));
    } finally {
      _setOperationState(EpicOperationState.idle);
    }
  }

  // Helper methods for state management
  void _setOperationState(EpicOperationState state) {
    _operationState = state;
    notifyListeners();
  }

  void _setError(AppException error) {
    _lastError = error;
    notifyListeners();
  }

  void _clearError() {
    _lastError = null;
  }

  @override
  void dispose() {
    super.dispose();
  }
}