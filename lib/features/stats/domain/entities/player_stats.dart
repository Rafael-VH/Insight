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

  factory PlayerStats.fromJson(Map<String, dynamic> json) {
    return PlayerStats(
      mode: GameMode.values.firstWhere((e) => e.name == json['mode']),
      totalGames: json['totalGames'],
      winRate: json['winRate'],
      mvpCount: json['mvpCount'],
      legendary: json['legendary'],
      savage: json['savage'],
      maniac: json['maniac'],
      tripleKill: json['tripleKill'],
      doubleKill: json['doubleKill'],
      mvpLoss: json['mvpLoss'],
      maxKills: json['maxKills'],
      maxAssists: json['maxAssists'],
      maxWinningStreak: json['maxWinningStreak'],
      firstBlood: json['firstBlood'],
      maxDamageDealt: json['maxDamageDealt'],
      maxDamageTaken: json['maxDamageTaken'],
      maxGold: json['maxGold'],
      kda: json['kda'],
      teamFightParticipation: json['teamFightParticipation'],
      goldPerMin: json['goldPerMin'],
      heroDamagePerMin: json['heroDamagePerMin'],
      deathsPerGame: json['deathsPerGame'],
      towerDamagePerGame: json['towerDamagePerGame'],
      oroMaxMin: json['oroMaxMin'],
      danoTomadoMaxMin: json['danoTomadoMaxMin'],
      danoCausadoMaxMin: json['danoCausadoMaxMin'],
    );
  }
}
