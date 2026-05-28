class UserSnapshot {
  final UserProfile user;
  final TodayData today;
  final QuestBook quests;
  final List<Clan> leaderboard;

  UserSnapshot({
    required this.user,
    required this.today,
    required this.quests,
    required this.leaderboard,
  });

  /// Per-source breakdown of today's XP. Completed quests are listed
  /// individually, critical strikes roll up into one bonus line, and any
  /// remainder lands in a single "Daily Activity" line so the items always
  /// sum to `today.xpEarned`.
  List<XpGain> get xpBreakdown {
    const critXp = 50;
    final items = <XpGain>[];
    int accounted = 0;

    for (final q in quests.pool) {
      if (q.status == QuestStatus.complete) {
        items.add(XpGain(
          label: q.title,
          source: XpSource.quest,
          xp: q.xpReward,
        ));
        accounted += q.xpReward;
      }
    }

    final crits = today.criticalStrikes;
    if (crits > 0) {
      final bonus = crits * critXp;
      items.add(XpGain(
        label: '$crits× Critical Strike',
        source: XpSource.crit,
        xp: bonus,
      ));
      accounted += bonus;
    }

    final remainder = today.xpEarned - accounted;
    if (remainder > 0) {
      items.add(XpGain(
        label: 'Daily Activity',
        source: XpSource.activity,
        xp: remainder,
      ));
    }
    return items;
  }

  factory UserSnapshot.fromJson(Map<String, dynamic> json) => UserSnapshot(
        user: UserProfile.fromJson(json['user'] as Map<String, dynamic>),
        today: TodayData.fromJson(json['today'] as Map<String, dynamic>),
        quests: QuestBook.fromJson(json['quests'] as Map<String, dynamic>),
        leaderboard: (json['leaderboard'] as List)
            .map((e) => Clan.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class UserProfile {
  final String id;
  final String displayName;
  final int age;
  final String joinedAt;
  final String arena;
  final int trophies;
  final String avatar;

  UserProfile({
    required this.id,
    required this.displayName,
    required this.age,
    required this.joinedAt,
    required this.arena,
    required this.trophies,
    required this.avatar,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
        id: json['id'] as String,
        displayName: json['displayName'] as String,
        age: json['age'] as int,
        joinedAt: json['joinedAt'] as String,
        arena: json['arena'] as String,
        trophies: json['trophies'] as int,
        avatar: json['avatar'] as String,
      );
}

class TodayData {
  final String date;
  final Map<String, num> metrics;
  final int xpEarned;
  final int xpDailyGoal;
  final int criticalStrikes;

  TodayData({
    required this.date,
    required this.metrics,
    required this.xpEarned,
    required this.xpDailyGoal,
    required this.criticalStrikes,
  });

  double get xpProgress =>
      xpDailyGoal == 0 ? 0 : (xpEarned / xpDailyGoal).clamp(0, 1).toDouble();

  factory TodayData.fromJson(Map<String, dynamic> json) {
    final metricsRaw = json['metrics'] as Map<String, dynamic>;
    final xp = json['xp'] as Map<String, dynamic>;
    return TodayData(
      date: json['date'] as String,
      metrics: metricsRaw.map((k, v) => MapEntry(k, v as num)),
      xpEarned: xp['earned'] as int,
      xpDailyGoal: xp['dailyGoal'] as int,
      criticalStrikes: xp['criticalStrikes'] as int,
    );
  }
}

class QuestBook {
  final List<String> initialActiveIds;
  final List<Quest> pool;

  QuestBook({required this.initialActiveIds, required this.pool});

  Quest? byId(String id) {
    for (final q in pool) {
      if (q.id == id) return q;
    }
    return null;
  }

  factory QuestBook.fromJson(Map<String, dynamic> json) => QuestBook(
        initialActiveIds:
            (json['activeIds'] as List).map((e) => e as String).toList(),
        pool: (json['pool'] as List)
            .map((e) => Quest.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

enum QuestStatus { inProgress, complete }

class Quest {
  final String id;
  final String title;
  final String metric;
  final num target;
  final num current;
  final int xpReward;
  final QuestStatus status;

  Quest({
    required this.id,
    required this.title,
    required this.metric,
    required this.target,
    required this.current,
    required this.xpReward,
    required this.status,
  });

  double get progress =>
      target == 0 ? 0 : (current / target).clamp(0, 1).toDouble();

  factory Quest.fromJson(Map<String, dynamic> json) => Quest(
        id: json['id'] as String,
        title: json['title'] as String,
        metric: json['metric'] as String,
        target: json['target'] as num,
        current: json['current'] as num,
        xpReward: json['xpReward'] as int,
        status: json['status'] == 'complete'
            ? QuestStatus.complete
            : QuestStatus.inProgress,
      );
}

class Clan {
  final String id;
  final String name;
  final String tag;
  final List<ClanMember> members;

  Clan({
    required this.id,
    required this.name,
    required this.tag,
    required this.members,
  });

  int get totalTrophies =>
      members.fold(0, (acc, m) => acc + m.trophies);

  int get memberCount => members.length;

  List<ClanMember> get sortedByTrophies =>
      [...members]..sort((a, b) => b.trophies.compareTo(a.trophies));

  factory Clan.fromJson(Map<String, dynamic> json) => Clan(
        id: json['id'] as String,
        name: json['name'] as String,
        tag: json['tag'] as String,
        members: (json['members'] as List)
            .map((e) => ClanMember.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

enum XpSource { quest, crit, activity }

class XpGain {
  final String label;
  final XpSource source;
  final int xp;
  const XpGain({required this.label, required this.source, required this.xp});
}

class ClanMember {
  final String id;
  final String name;
  final int trophies;

  ClanMember({required this.id, required this.name, required this.trophies});

  factory ClanMember.fromJson(Map<String, dynamic> json) => ClanMember(
        id: json['id'] as String,
        name: json['name'] as String,
        trophies: json['trophies'] as int,
      );
}
