class UserSnapshot {
  final UserProfile user;
  final TodayData today;
  final Baselines baselines;
  final List<Quest> quests;
  final Dojo dojo;
  final List<Chest> chests;

  UserSnapshot({
    required this.user,
    required this.today,
    required this.baselines,
    required this.quests,
    required this.dojo,
    required this.chests,
  });

  factory UserSnapshot.fromJson(Map<String, dynamic> json) => UserSnapshot(
        user: UserProfile.fromJson(json['user'] as Map<String, dynamic>),
        today: TodayData.fromJson(json['today'] as Map<String, dynamic>),
        baselines: Baselines.fromJson(json['baselines'] as Map<String, dynamic>),
        quests: (json['quests'] as List)
            .map((e) => Quest.fromJson(e as Map<String, dynamic>))
            .toList(),
        dojo: Dojo.fromJson(json['dojo'] as Map<String, dynamic>),
        chests: (json['chests'] as List)
            .map((e) => Chest.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class UserProfile {
  final String id;
  final String displayName;
  final int age;
  final String arena;
  final int trophies;
  final String avatar;

  UserProfile({
    required this.id,
    required this.displayName,
    required this.age,
    required this.arena,
    required this.trophies,
    required this.avatar,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
        id: json['id'] as String,
        displayName: json['displayName'] as String,
        age: json['age'] as int,
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

class Baselines {
  final String window;
  final Map<String, num> averages;

  Baselines({required this.window, required this.averages});

  factory Baselines.fromJson(Map<String, dynamic> json) {
    final averagesRaw = json['averages'] as Map<String, dynamic>;
    return Baselines(
      window: json['window'] as String,
      averages: averagesRaw.map((k, v) => MapEntry(k, v as num)),
    );
  }
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

class Dojo {
  final String id;
  final String name;
  final int memberCount;
  final String sensei;
  final BossFight weeklyBoss;
  final List<Buff> activeBuffs;

  Dojo({
    required this.id,
    required this.name,
    required this.memberCount,
    required this.sensei,
    required this.weeklyBoss,
    required this.activeBuffs,
  });

  factory Dojo.fromJson(Map<String, dynamic> json) => Dojo(
        id: json['id'] as String,
        name: json['name'] as String,
        memberCount: json['memberCount'] as int,
        sensei: json['sensei'] as String,
        weeklyBoss:
            BossFight.fromJson(json['weeklyBoss'] as Map<String, dynamic>),
        activeBuffs: (json['activeBuffs'] as List)
            .map((e) => Buff.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class BossFight {
  final String name;
  final String objective;
  final num progress;
  final num target;
  final String endsAt;

  BossFight({
    required this.name,
    required this.objective,
    required this.progress,
    required this.target,
    required this.endsAt,
  });

  double get fraction =>
      target == 0 ? 0 : (progress / target).clamp(0, 1).toDouble();

  factory BossFight.fromJson(Map<String, dynamic> json) => BossFight(
        name: json['name'] as String,
        objective: json['objective'] as String,
        progress: json['progress'] as num,
        target: json['target'] as num,
        endsAt: json['endsAt'] as String,
      );
}

class Buff {
  final String id;
  final String name;
  final String description;
  final String expiresAt;

  Buff({
    required this.id,
    required this.name,
    required this.description,
    required this.expiresAt,
  });

  factory Buff.fromJson(Map<String, dynamic> json) => Buff(
        id: json['id'] as String,
        name: json['name'] as String,
        description: json['description'] as String,
        expiresAt: json['expiresAt'] as String,
      );
}

enum ChestStatus { unlocking, pending, ready }

class Chest {
  final String id;
  final String rarity;
  final ChestStatus status;
  final String? unlocksAt;

  Chest({
    required this.id,
    required this.rarity,
    required this.status,
    this.unlocksAt,
  });

  factory Chest.fromJson(Map<String, dynamic> json) {
    final raw = json['status'] as String;
    final status = switch (raw) {
      'unlocking' => ChestStatus.unlocking,
      'ready' => ChestStatus.ready,
      _ => ChestStatus.pending,
    };
    return Chest(
      id: json['id'] as String,
      rarity: json['rarity'] as String,
      status: status,
      unlocksAt: json['unlocksAt'] as String?,
    );
  }
}
