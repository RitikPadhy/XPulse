import 'package:flutter/material.dart';

import '../core/app_state.dart';
import '../ui/contracts/skin_scope.dart';

class SideQuestsScreen extends StatelessWidget {
  const SideQuestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = SkinScope.of(context).components;
    final state = AppStateScope.of(context);
    final active = state.activeQuests;
    final available = state.availableQuests;

    return Column(
      children: [
        c.pageHeader(title: 'Quests'),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.only(bottom: 24),
            children: [
              c.sectionHeader(
                label: 'Active  (${active.length} / ${AppState.maxActiveQuests})',
              ),
              if (active.isEmpty)
                _EmptyLine(text: 'Pick up to 4 below.')
              else
                ...active.map(
                  (q) => c.questPickerTile(
                    quest: q,
                    isActive: true,
                    canActivate: false,
                    onTap: () => state.deactivate(q.id),
                  ),
                ),
              c.sectionHeader(label: 'Available'),
              if (available.isEmpty)
                _EmptyLine(text: 'No more quests available today.')
              else
                ...available.map(
                  (q) => c.questPickerTile(
                    quest: q,
                    isActive: false,
                    canActivate: !state.isFull,
                    onTap: () => state.activate(q.id),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _EmptyLine extends StatelessWidget {
  final String text;
  const _EmptyLine({required this.text});

  @override
  Widget build(BuildContext context) {
    final p = SkinScope.of(context).palette;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: Text(
        text,
        style: TextStyle(
          color: p.textMuted,
          fontFamily: 'Courier',
          fontSize: 11,
          letterSpacing: 1,
        ),
      ),
    );
  }
}
