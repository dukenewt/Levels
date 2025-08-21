# Bug Fix & Improvement Backlog

This document tracks specific bugs, UI/UX improvements, and small tweaks discovered during testing and development. Items here are more granular than the high-level roadmap features.

## 🐛 Critical Bugs
*Issues that break core functionality or cause crashes*

- [ ] 🔥 CRITICAL: Talent select screen did not appear on reaching level 5 - talent progression system broken 
- [ ] critical: completing a task through swipe and circle select, show different animations. - task completion animations not unified
- [ ] 🔥 CRITICAL: Perk/Talent animations conflict causing cancellations or skipped sequences — unify under a screen-level orchestrator and serialize per-entity animations
- [ ] ⚠️ HIGH: Race condition between XP level-up and talent dialog trigger — dialog request must occur post-frame after state commit and navigation is mounted

## 🔧 UI/UX Improvements  
*Small tweaks, polish items, and user experience enhancements*

- [ ] ⚠️ HIGH: Add perk unlock notification screen/dialog when perks are achieved - users need visual feedback
- [ ] high: Add interactive click into tasks to update - users need more ways to interact with tasks
- [ ] high: Need accent or contrast for tasks - support accessibility and visual of tasks
- [ ] 📝 LOW: Task dashboard view selector is clunky when users complete/delete all tasks - improve empty state handling 

## 🎮 Gameplay Balance
*Perk/XP/progression adjustments and game mechanics tuning*

- [ ] ⚠️ HIGH: Remove "Smart Task Suggestions" as a perk (Level 3) - no AI model included, shouldn't imitate AI features 

## 📱 Platform-Specific Issues
*iOS/Android specific bugs or inconsistencies*

- [ ] 

## 🚀 Performance & Technical
*Performance optimizations and technical debt*

- [ ] Introduce `AnimationOrchestrator` with controller registry keyed by entity id; central disposal and `TickerMode` handling
- [ ] Add Reduced Motion preference and guard all animations accordingly
- [ ] Consolidate effect evaluation into pure `PerkEffectEngine`; avoid logic in widgets

## ✅ Recently Fixed
*Completed items moved here for reference - clear periodically*

- [x] Example completed item

---

## Guidelines:
- Use descriptive titles that explain the issue clearly
- Add severity indicators for critical bugs: `🔥 CRITICAL`, `⚠️ HIGH`, `📝 LOW`
- Reference file paths when relevant: `file_path:line_number`
- Cross off items immediately when fixed
- Move completed items to "Recently Fixed" section
