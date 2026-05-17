import 'package:flutter_test/flutter_test.dart';

import 'package:xpulse/core/models/user_snapshot.dart';

void main() {
  test('Quest progress clamps between 0 and 1', () {
    final q = Quest(
      id: 'q',
      title: 't',
      metric: 'steps',
      target: 1000,
      current: 1500,
      xpReward: 50,
      status: QuestStatus.complete,
    );
    expect(q.progress, 1.0);
  });
}
