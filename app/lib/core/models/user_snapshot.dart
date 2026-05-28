class UserSnapshot {
  final UserProfile user;
  final TodayData today;
  final QuestBook quests;
  final List<Friend> friends;

  UserSnapshot({
    required this.user,
    required this.today,
    required this.quests,
    required this.friends,
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

  /// Parses the backend `/v1/me/snapshot` response.
  factory UserSnapshot.fromJson(Map<String, dynamic> json) => UserSnapshot(
        user: UserProfile.fromMeJson(json['me'] as Map<String, dynamic>),
        today: TodayData.fromJson(json['today'] as Map<String, dynamic>),
        quests: QuestBook.fromJson(json['quests'] as Map<String, dynamic>),
        friends: (json['friends'] as List)
            .map((e) => Friend.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class UserProfile {
  final String id;
  final String displayName;
  final String joinedAt;
  final String? country;
  final String avatar;

  UserProfile({
    required this.id,
    required this.displayName,
    required this.joinedAt,
    required this.avatar,
    this.country,
  });

  /// Maps the backend `me` payload (id/name/role/created_at/details) to the
  /// shape the UI consumes.
  factory UserProfile.fromMeJson(Map<String, dynamic> json) {
    final details = json['details'] as Map<String, dynamic>?;
    final createdAt = json['created_at'] as String;
    return UserProfile(
      id: json['id'].toString(),
      displayName:
          (details?['display_name'] as String?) ?? (json['name'] as String),
      joinedAt: createdAt.split('T').first,
      country: details?['country'] as String?,
      avatar: (details?['avatar_key'] as String?) ?? 'default',
    );
  }
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

/// One row in the friends leaderboard.
class Friend {
  final int id;
  final String displayName;
  final String? avatarKey;
  final String? country;
  final int dailyXp;
  final int totalXp;
  final int rank;

  Friend({
    required this.id,
    required this.displayName,
    required this.dailyXp,
    required this.totalXp,
    required this.rank,
    this.avatarKey,
    this.country,
  });

  factory Friend.fromJson(Map<String, dynamic> j) => Friend(
        id: j['id'] as int,
        displayName: j['display_name'] as String,
        avatarKey: j['avatar_key'] as String?,
        country: j['country'] as String?,
        dailyXp: j['daily_xp'] as int,
        totalXp: j['total_xp'] as int,
        rank: j['rank'] as int,
      );
}

enum XpSource { quest, crit, activity }

class XpGain {
  final String label;
  final XpSource source;
  final int xp;
  const XpGain({required this.label, required this.source, required this.xp});
}

/// Detailed public profile of a single user — fetched on tap from the friends
/// leaderboard via GET /v1/users/{id}.
class FriendDetail {
  final int id;
  final String displayName;
  final String? avatarKey;
  final String? country;
  final String? bio;
  final String joinedAt;
  final int dailyXp;
  final int totalXp;
  final int? rank;
  final List<DailyXp> last7Days;

  FriendDetail({
    required this.id,
    required this.displayName,
    required this.joinedAt,
    required this.dailyXp,
    required this.totalXp,
    required this.last7Days,
    this.avatarKey,
    this.country,
    this.bio,
    this.rank,
  });

  factory FriendDetail.fromJson(Map<String, dynamic> j) => FriendDetail(
        id: j['id'] as int,
        displayName: j['display_name'] as String,
        avatarKey: j['avatar_key'] as String?,
        country: j['country'] as String?,
        bio: j['bio'] as String?,
        joinedAt: (j['joined_at'] as String).split('T').first,
        dailyXp: j['daily_xp'] as int,
        totalXp: j['total_xp'] as int,
        rank: j['rank'] as int?,
        last7Days: (j['last_7_days'] as List)
            .map((e) => DailyXp.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class DailyXp {
  final String day;
  final int xp;
  DailyXp({required this.day, required this.xp});

  factory DailyXp.fromJson(Map<String, dynamic> j) => DailyXp(
        day: j['day'] as String,
        xp: j['xp'] as int,
      );
}
