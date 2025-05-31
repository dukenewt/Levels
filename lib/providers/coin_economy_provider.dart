import 'package:flutter/foundation.dart';
import '../models/coin_economy.dart';
import '../models/skill.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../services/storage_service.dart';

class CoinEconomyProvider with ChangeNotifier {
  int _coins = 0;
  final List<CoinReward> _rewards = [];
  final Map<String, List<SkillPurchase>> _purchases = {};
  final Map<String, Set<String>> _dailyCompletedSkills = {};
  final StorageService _storage;

  CoinEconomyProvider({required StorageService storage}) : _storage = storage {
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      _coins = await _storage.getData('coins') ?? 0;
      
      final rewardsJson = await _storage.getData('coin_rewards');
      if (rewardsJson != null) {
        final List<dynamic> decodedRewards = rewardsJson is String 
            ? json.decode(rewardsJson) 
            : rewardsJson;
        _rewards.clear();
        _rewards.addAll(decodedRewards.map((r) => CoinReward.fromJson(r)));
      }

      final purchasesJson = await _storage.getData('skill_purchases');
      if (purchasesJson != null) {
        final Map<String, dynamic> decodedPurchases = purchasesJson is String 
            ? json.decode(purchasesJson) 
            : purchasesJson;
        _purchases.clear();
        decodedPurchases.forEach((skillId, purchases) {
          _purchases[skillId] = (purchases as List)
              .map((p) => SkillPurchase.fromJson(p))
              .toList();
        });
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error loading coin economy data: $e');
    }
  }

  Future<void> _saveData() async {
    try {
      await _storage.saveData('coins', _coins);
      
      final rewardsJson = _rewards.map((r) => r.toJson()).toList();
      await _storage.saveData('coin_rewards', rewardsJson);

      final purchasesJson = _purchases.map((key, value) => MapEntry(
        key,
        value.map((p) => p.toJson()).toList(),
      ));
      await _storage.saveData('skill_purchases', purchasesJson);
    } catch (e) {
      debugPrint('Error saving coin economy data: $e');
    }
  }

  int get coins => _coins;
  List<CoinReward> get rewards => List.unmodifiable(_rewards);
  Map<String, List<SkillPurchase>> get purchases => Map.unmodifiable(_purchases);

  // Add coins to the user's balance
  Future<void> addCoins(int amount) async {
    _coins += amount;
    await _saveData();
    notifyListeners();
  }

  // Check if user has enough coins
  bool hasEnoughCoins(int amount) {
    return _coins >= amount;
  }

  // Spend coins
  Future<bool> spendCoins(int amount) async {
    if (!hasEnoughCoins(amount)) return false;
    _coins -= amount;
    await _saveData();
    notifyListeners();
    return true;
  }

  // Handle level up reward
  Future<void> handleLevelUp(Skill skill, int newLevel) async {
    final reward = CoinReward.calculateLevelUpReward(newLevel);
    if (reward > 0) {
      await _addReward(
        CoinReward(
          id: 'level_up_${skill.id}_$newLevel',
          name: 'Level Up Reward',
          description: 'Reached level $newLevel in ${skill.name}',
          amount: reward,
          type: CoinRewardType.levelUp,
          timestamp: DateTime.now(),
          skillId: skill.id,
        ),
      );
    }

    // Check for milestone reward
    final milestoneReward = CoinReward.calculateMilestoneReward(newLevel);
    if (milestoneReward > 0) {
      await _addReward(
        CoinReward(
          id: 'milestone_${skill.id}_$newLevel',
          name: 'Milestone Achievement',
          description: 'Reached milestone level $newLevel in ${skill.name}',
          amount: milestoneReward,
          type: CoinRewardType.milestone,
          timestamp: DateTime.now(),
          skillId: skill.id,
        ),
      );
    }
  }

  // Handle balanced development reward
  void checkBalancedDevelopment(List<Skill> skills) {
    final skillLevels = skills.map((s) => s.level).toList();
    final reward = CoinReward.calculateBalancedDevelopmentReward(skillLevels);
    
    if (reward > 0) {
      _addReward(
        CoinReward(
          id: 'balanced_dev_${DateTime.now().millisecondsSinceEpoch}',
          name: 'Balanced Development',
          description: 'Maintained balanced skill levels',
          amount: reward,
          type: CoinRewardType.balancedDevelopment,
          timestamp: DateTime.now(),
        ),
      );
    }
  }

  // Handle cross-skill combo reward
  void trackDailySkillCompletion(String skillId) {
    final today = DateTime.now().toIso8601String().split('T')[0];
    _dailyCompletedSkills.putIfAbsent(today, () => {});
    _dailyCompletedSkills[today]!.add(skillId);

    final uniqueSkills = _dailyCompletedSkills[today]!.length;
    final reward = CoinReward.calculateCrossSkillComboReward(uniqueSkills);

    if (reward > 0) {
      _addReward(
        CoinReward(
          id: 'cross_skill_$today',
          name: 'Cross-Skill Combo',
          description: 'Completed tasks in $uniqueSkills different skills today',
          amount: reward,
          type: CoinRewardType.crossSkillCombo,
          timestamp: DateTime.now(),
        ),
      );
    }
  }

  // Add a reward and update coin balance
  Future<void> _addReward(CoinReward reward) async {
    _rewards.add(reward);
    await addCoins(reward.amount);
  }

  // Initialize purchases for a skill
  void initializeSkillPurchases(String skillId) {
    if (!_purchases.containsKey(skillId)) {
      _purchases[skillId] = SkillPurchases.templates.entries.map((entry) {
        final template = entry.value;
        return SkillPurchase(
          id: '${entry.key}_$skillId',
          name: template['name'],
          description: template['description'],
          cost: template['cost'],
          durationMinutes: template['effects']?['duration'] != null 
              ? template['effects']['duration'] * 60 // Convert hours to minutes
              : 0,
          xpMultiplier: template['effects']?['xpMultiplier'] ?? 1.0,
        );
      }).toList();
    }
  }

  // Get available purchases for a skill
  List<SkillPurchase> getAvailablePurchases(String skillId) {
    return _purchases[skillId] ?? [];
  }

  // Purchase an item
  Future<bool> purchaseItem(String skillId, String purchaseId) async {
    final purchase = _purchases[skillId]?.firstWhere(
      (p) => p.id == purchaseId,
      orElse: () => throw Exception('Purchase not found'),
    );

    if (purchase == null || !hasEnoughCoins(purchase.cost)) {
      return false;
    }

    if (await spendCoins(purchase.cost)) {
      final updatedPurchase = purchase.copyWith(
        expiresAt: purchase.durationMinutes > 0
            ? DateTime.now().add(Duration(minutes: purchase.durationMinutes))
            : null,
      );

      _purchases[skillId] = _purchases[skillId]!.map((p) {
        return p.id == purchaseId ? updatedPurchase : p;
      }).toList();

      await _saveData();
      notifyListeners();
      return true;
    }

    return false;
  }

  // Check if a purchase is active
  bool isPurchaseActive(String skillId, String purchaseId) {
    final purchase = _purchases[skillId]?.firstWhere(
      (p) => p.id == purchaseId,
      orElse: () => throw Exception('Purchase not found'),
    );

    if (purchase == null) return false;

    if (purchase.expiresAt != null && DateTime.now().isAfter(purchase.expiresAt!)) {
      // Deactivate expired purchase
      _purchases[skillId] = _purchases[skillId]!.map((p) {
        return p.id == purchaseId ? p.copyWith(expiresAt: null) : p;
      }).toList();
      notifyListeners();
      return false;
    }

    return purchase.expiresAt != null;
  }

  // Get active purchases for a skill
  List<SkillPurchase> getActivePurchases(String skillId) {
    return _purchases[skillId]?.where((p) => isPurchaseActive(skillId, p.id)).toList() ?? [];
  }

  // Get XP multiplier from active boosters
  double getXPMultiplier(String skillId) {
    final activeBoosters = getActivePurchases(skillId)
        .where((p) => p.xpMultiplier > 1.0)
        .toList();

    if (activeBoosters.isEmpty) return 1.0;

    return activeBoosters.fold(1.0, (multiplier, booster) {
      return multiplier * booster.xpMultiplier;
    });
  }
} 