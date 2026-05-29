import 'package:flutter/widgets.dart';

import 'models/user_snapshot.dart';
import 'services/api_client.dart';

/// Mutable, UI-agnostic app state.
///
/// Owns the set of active quest IDs (max 4) and exposes swap actions. Screens
/// read this via `AppStateScope.of(context)` and rebuild when it changes.
/// Swaps are optimistic: the local set updates immediately and the server is
/// told; if the server rejects (e.g. the day is locked), we revert.
class AppState extends ChangeNotifier {
  AppState({required this.snapshot, ApiClient? api})
    : _api = api ?? ApiClient(),
      _activeQuestIds = {...snapshot.quests.initialActiveIds};

  final UserSnapshot snapshot;
  final ApiClient _api;
  final Set<String> _activeQuestIds;

  static const int maxActiveQuests = 4;

  /// Server-authoritative lock — after local noon the active set can't change.
  bool get locked => snapshot.quests.locked;

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
    if (locked) return;
    if (_activeQuestIds.remove(id)) {
      notifyListeners();
      _api.deactivateQuest(id).catchError((_) {
        _activeQuestIds.add(id); // server rejected — revert
        notifyListeners();
      });
    }
  }

  void activate(String id) {
    if (locked || _activeQuestIds.contains(id) || isFull) return;
    _activeQuestIds.add(id);
    notifyListeners();
    _api.activateQuest(id).catchError((_) {
      _activeQuestIds.remove(id); // server rejected — revert
      notifyListeners();
    });
  }
}

class AppStateScope extends InheritedNotifier<AppState> {
  const AppStateScope({
    super.key,
    required AppState super.notifier,
    required super.child,
  });

  static AppState of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppStateScope>();
    assert(scope != null, 'No AppStateScope found in widget tree.');
    return scope!.notifier!;
  }
}
