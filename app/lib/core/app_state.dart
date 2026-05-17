import 'package:flutter/widgets.dart';

import 'models/user_snapshot.dart';

/// Mutable, UI-agnostic app state.
///
/// Owns the set of active quest IDs (max 4) and exposes swap actions. Screens
/// read this via `AppStateScope.of(context)` and rebuild when it changes.
class AppState extends ChangeNotifier {
  AppState({required this.snapshot})
      : _activeQuestIds = {...snapshot.quests.initialActiveIds};

  final UserSnapshot snapshot;
  final Set<String> _activeQuestIds;

  static const int maxActiveQuests = 4;

  Set<String> get activeQuestIds => Set.unmodifiable(_activeQuestIds);

  List<Quest> get activeQuests => [
        for (final id in _activeQuestIds)
          if (snapshot.quests.byId(id) != null) snapshot.quests.byId(id)!,
      ];

  List<Quest> get availableQuests => [
        for (final q in snapshot.quests.pool)
          if (!_activeQuestIds.contains(q.id)) q,
      ];

  bool get isFull => _activeQuestIds.length >= maxActiveQuests;

  void deactivate(String id) {
    if (_activeQuestIds.remove(id)) notifyListeners();
  }

  void activate(String id) {
    if (_activeQuestIds.contains(id)) return;
    if (isFull) return;
    _activeQuestIds.add(id);
    notifyListeners();
  }
}

class AppStateScope extends InheritedNotifier<AppState> {
  const AppStateScope({
    super.key,
    required AppState super.notifier,
    required super.child,
  });

  static AppState of(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<AppStateScope>();
    assert(scope != null, 'No AppStateScope found in widget tree.');
    return scope!.notifier!;
  }
}
