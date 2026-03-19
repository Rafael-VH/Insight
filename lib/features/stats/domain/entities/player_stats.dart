import 'package:insight/features/stats/domain/entities/game_mode.dart';

class PlayerStats {
  final GameMode mode;
  final int totalGames;
  final double winRate;
  final int mvpCount;

  // Achievement stats
  final int legendary;
  final int savage;
  final int maniac;
  final int tripleKill;
  final int doubleKill;
  final int mvpLoss;
  final int maxKills;
  final int maxAssists;
  final int maxWinningStreak;
  final int firstBlood;
  final int maxDamageDealt;
  final int maxDamageTaken;
  final int maxGold;

  // Performance stats
  final double kda;
  final double teamFightParticipation;
  final int goldPerMin;
  final int heroDamagePerMin;
  final double deathsPerGame;
  final int towerDamagePerGame;

  // Additional stats from images
  final int oroMaxMin;
  final int danoTomadoMaxMin;
  final int danoCausadoMaxMin;

  const PlayerStats({
    required this.mode,
    required this.totalGames,
    required this.winRate,
    required this.mvpCount,
    required this.legendary,
    required this.savage,
    required this.maniac,
    required this.tripleKill,
    required this.doubleKill,
    required this.mvpLoss,
    required this.maxKills,
    required this.maxAssists,
    required this.maxWinningStreak,
    required this.firstBlood,
    required this.maxDamageDealt,
    required this.maxDamageTaken,
    required this.maxGold,
    required this.kda,
    required this.teamFightParticipation,
    required this.goldPerMin,
    required this.heroDamagePerMin,
    required this.deathsPerGame,
    required this.towerDamagePerGame,
    required this.oroMaxMin,
    required this.danoTomadoMaxMin,
    required this.danoCausadoMaxMin,
  });

  PlayerStats copyWith({
    GameMode? mode,
    int? totalGames,
    double? winRate,
    int? mvpCount,
    int? legendary,
    int? savage,
    int? maniac,
    int? tripleKill,
    int? doubleKill,
    int? mvpLoss,
    int? maxKills,
    int? maxAssists,
    int? maxWinningStreak,
    int? firstBlood,
    int? maxDamageDealt,
    int? maxDamageTaken,
    int? maxGold,
    double? kda,
    double? teamFightParticipation,
    int? goldPerMin,
    int? heroDamagePerMin,
    double? deathsPerGame,
    int? towerDamagePerGame,
    int? oroMaxMin,
    int? danoTomadoMaxMin,
    int? danoCausadoMaxMin,
  }) {
    return PlayerStats(
      mode: mode ?? this.mode,
      totalGames: totalGames ?? this.totalGames,
      winRate: winRate ?? this.winRate,
      mvpCount: mvpCount ?? this.mvpCount,
      legendary: legendary ?? this.legendary,
      savage: savage ?? this.savage,
      maniac: maniac ?? this.maniac,
      tripleKill: tripleKill ?? this.tripleKill,
      doubleKill: doubleKill ?? this.doubleKill,
      mvpLoss: mvpLoss ?? this.mvpLoss,
      maxKills: maxKills ?? this.maxKills,
      maxAssists: maxAssists ?? this.maxAssists,
      maxWinningStreak: maxWinningStreak ?? this.maxWinningStreak,
      firstBlood: firstBlood ?? this.firstBlood,
      maxDamageDealt: maxDamageDealt ?? this.maxDamageDealt,
      maxDamageTaken: maxDamageTaken ?? this.maxDamageTaken,
      maxGold: maxGold ?? this.maxGold,
      kda: kda ?? this.kda,
      teamFightParticipation:
          teamFightParticipation ?? this.teamFightParticipation,
      goldPerMin: goldPerMin ?? this.goldPerMin,
      heroDamagePerMin: heroDamagePerMin ?? this.heroDamagePerMin,
      deathsPerGame: deathsPerGame ?? this.deathsPerGame,
      towerDamagePerGame: towerDamagePerGame ?? this.towerDamagePerGame,
      oroMaxMin: oroMaxMin ?? this.oroMaxMin,
      danoTomadoMaxMin: danoTomadoMaxMin ?? this.danoTomadoMaxMin,
      danoCausadoMaxMin: danoCausadoMaxMin ?? this.danoCausadoMaxMin,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'mode': mode.name,
      'totalGames': totalGames,
      'winRate': winRate,
      'mvpCount': mvpCount,
      'legendary': legendary,
      'savage': savage,
      'maniac': maniac,
      'tripleKill': tripleKill,
      'doubleKill': doubleKill,
      'mvpLoss': mvpLoss,
      'maxKills': maxKills,
      'maxAssists': maxAssists,
      'maxWinningStreak': maxWinningStreak,
      'firstBlood': firstBlood,
      'maxDamageDealt': maxDamageDealt,
      'maxDamageTaken': maxDamageTaken,
      'maxGold': maxGold,
      'kda': kda,
      'teamFightParticipation': teamFightParticipation,
      'goldPerMin': goldPerMin,
      'heroDamagePerMin': heroDamagePerMin,
      'deathsPerGame': deathsPerGame,
      'towerDamagePerGame': towerDamagePerGame,
      'oroMaxMin': oroMaxMin,
      'danoTomadoMaxMin': danoTomadoMaxMin,
      'danoCausadoMaxMin': danoCausadoMaxMin,
    };
  }

  static double _toDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }

  static int _toInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is double) return v.toInt();
    return int.tryParse(v.toString()) ?? 0;
  }

  factory PlayerStats.fromJson(Map<String, dynamic> json) {
    return PlayerStats(
      mode: GameMode.values.firstWhere(
        (e) => e.name == json['mode'],
        orElse: () => GameMode.total,
      ),
      totalGames: _toInt(json['totalGames']),
      winRate: _toDouble(json['winRate']),
      mvpCount: _toInt(json['mvpCount']),
      legendary: _toInt(json['legendary']),
      savage: _toInt(json['savage']),
      maniac: _toInt(json['maniac']),
      tripleKill: _toInt(json['tripleKill']),
      doubleKill: _toInt(json['doubleKill']),
      mvpLoss: _toInt(json['mvpLoss']),
      maxKills: _toInt(json['maxKills']),
      maxAssists: _toInt(json['maxAssists']),
      maxWinningStreak: _toInt(json['maxWinningStreak']),
      firstBlood: _toInt(json['firstBlood']),
      maxDamageDealt: _toInt(json['maxDamageDealt']),
      maxDamageTaken: _toInt(json['maxDamageTaken']),
      maxGold: _toInt(json['maxGold']),
      kda: _toDouble(json['kda']),
      teamFightParticipation: _toDouble(json['teamFightParticipation']),
      goldPerMin: _toInt(json['goldPerMin']),
      heroDamagePerMin: _toInt(json['heroDamagePerMin']),
      deathsPerGame: _toDouble(json['deathsPerGame']),
      towerDamagePerGame: _toInt(json['towerDamagePerGame']),
      oroMaxMin: _toInt(json['oroMaxMin']),
      danoTomadoMaxMin: _toInt(json['danoTomadoMaxMin']),
      danoCausadoMaxMin: _toInt(json['danoCausadoMaxMin']),
    );
  }
}
