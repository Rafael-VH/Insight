import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:insight/core/errors/failures.dart';
import 'package:insight/features/stats/domain/entities/game_mode.dart';
import 'package:insight/features/stats/domain/entities/player_stats.dart';
import 'package:insight/features/stats/domain/entities/stats_collection.dart';
import 'package:insight/features/stats/domain/repositories/stats_repository.dart';
import 'package:insight/features/stats/domain/usecases/export_stats_to_json.dart';
import 'package:insight/features/stats/domain/usecases/get_all_stats_collections.dart';
import 'package:insight/features/stats/domain/usecases/get_latest_stats_collection.dart';
import 'package:insight/features/stats/domain/usecases/import_stats_from_json.dart';
import 'package:insight/features/stats/domain/usecases/save_collections_batch.dart';
import 'package:insight/features/stats/domain/usecases/save_stats_collection.dart';
import 'package:insight/features/stats/domain/usecases/update_stats_collection_name.dart';
import 'package:insight/features/stats/domain/usecases/usecase.dart';
import 'package:insight/features/stats/presentation/bloc/stats/stats_bloc.dart';
import 'package:insight/features/stats/presentation/bloc/stats/stats_event.dart';
import 'package:insight/features/stats/presentation/bloc/stats/stats_state.dart';

// ── Stubs ─────────────────────────────────────────────────────────

PlayerStats _buildStats(GameMode mode) => PlayerStats(
      mode: mode,
      totalGames: 500,
      winRate: 58.5,
      mvpCount: 100,
      legendary: 50,
      savage: 3,
      maniac: 20,
      tripleKill: 100,
      doubleKill: 800,
      mvpLoss: 60,
      maxKills: 20,
      maxAssists: 30,
      maxWinningStreak: 10,
      firstBlood: 150,
      maxDamageDealt: 8000,
      maxDamageTaken: 10000,
      maxGold: 950,
      kda: 3.8,
      teamFightParticipation: 70.0,
      goldPerMin: 650,
      heroDamagePerMin: 2800,
      deathsPerGame: 2.5,
      towerDamagePerGame: 900,
      oroMaxMin: 950,
      danoTomadoMaxMin: 10000,
      danoCausadoMaxMin: 8000,
    );

final _fakeCollection = StatsCollection(
  createdAt: DateTime(2025, 6, 1, 12, 0),
  totalStats: _buildStats(GameMode.total),
  name: 'Test Collection',
);

final _fakeCollections = [
  _fakeCollection,
  StatsCollection(
    createdAt: DateTime(2025, 5, 1, 10, 0),
    rankedStats: _buildStats(GameMode.ranked),
  ),
];

// ── Stubs de use cases ────────────────────────────────────────────

class _SaveOk extends Fake implements SaveStatsCollection {
  @override
  Future<Either<Failure, void>> call(StatsCollection c) async =>
      const Right(null);
}

class _SaveFail extends Fake implements SaveStatsCollection {
  @override
  Future<Either<Failure, void>> call(StatsCollection c) async =>
      const Left(FileSystemFailure('Error al guardar'));
}

class _GetAllOk extends Fake implements GetAllStatsCollections {
  @override
  Future<Either<Failure, List<StatsCollection>>> call(NoParams p) async =>
      Right(_fakeCollections);
}

class _GetAllFail extends Fake implements GetAllStatsCollections {
  @override
  Future<Either<Failure, List<StatsCollection>>> call(NoParams p) async =>
      const Left(FileSystemFailure('Error al cargar'));
}

class _GetLatestOk extends Fake implements GetLatestStatsCollection {
  @override
  Future<Either<Failure, StatsCollection?>> call(NoParams p) async =>
      Right(_fakeCollection);
}

class _UpdateNameOk extends Fake implements UpdateStatsCollectionName {
  @override
  Future<Either<Failure, void>> call(UpdateNameParams p) async =>
      const Right(null);
}

class _ExportOk extends Fake implements ExportStatsToJson {
  @override
  Future<Either<Failure, String>> call(List<StatsCollection> c) async =>
      const Right('/fake/export.json');
}

class _ExportFail extends Fake implements ExportStatsToJson {
  @override
  Future<Either<Failure, String>> call(List<StatsCollection> c) async =>
      const Left(FileSystemFailure('Error al exportar'));
}

class _ImportOk extends Fake implements ImportStatsFromJson {
  @override
  Future<Either<Failure, List<StatsCollection>>> call(String path) async =>
      Right(_fakeCollections);
}

class _ImportFail extends Fake implements ImportStatsFromJson {
  @override
  Future<Either<Failure, List<StatsCollection>>> call(String path) async =>
      const Left(ParseFailure('JSON inválido'));
}

class _BatchOk extends Fake implements SaveCollectionsBatch {
  @override
  Future<Either<Failure, int>> call(
    List<StatsCollection> c, {
    bool replaceExisting = false,
  }) async =>
      const Right(2);
}

class _FakeStatsRepo extends Fake implements StatsRepository {
  @override
  Future<Either<Failure, void>> deleteStatsCollection(DateTime d) async =>
      const Right(null);

  @override
  Future<Either<Failure, void>> clearAllStats() async => const Right(null);

  @override
  Future<Either<Failure, StatsCollection?>> getStatsCollectionByDate(
      DateTime d) async =>
      Right(_fakeCollection);

  // Métodos requeridos por la interfaz pero no usados en estos tests
  @override
  Future<Either<Failure, void>> saveStatsCollection(StatsCollection c) async =>
      const Right(null);

  @override
  Future<Either<Failure, List<StatsCollection>>>
      getAllStatsCollections() async => Right(_fakeCollections);

  @override
  Future<Either<Failure, StatsCollection?>>
      getLatestStatsCollection() async => Right(_fakeCollection);

  @override
  Future<Either<Failure, void>> updateStatsCollectionName(
          DateTime d, String n) async =>
      const Right(null);

  @override
  Future<Either<Failure, String>> exportStatsToJson(
          List<StatsCollection> c) async =>
      const Right('/fake/path.json');

  @override
  Future<Either<Failure, List<StatsCollection>>> importStatsFromJson(
          String p) async =>
      Right(_fakeCollections);

  @override
  Future<Either<Failure, int>> saveCollectionsBatch(
    List<StatsCollection> c, {
    bool replaceExisting = false,
  }) async =>
      const Right(2);
}

// ── Factory helper ────────────────────────────────────────────────

StatsBloc _buildBloc({
  SaveStatsCollection? save,
  GetAllStatsCollections? getAll,
  GetLatestStatsCollection? getLatest,
  UpdateStatsCollectionName? updateName,
  ExportStatsToJson? export,
  ImportStatsFromJson? import,
  SaveCollectionsBatch? batch,
}) {
  return StatsBloc(
    saveStatsCollection: save ?? _SaveOk(),
    getAllStatsCollections: getAll ?? _GetAllOk(),
    getLatestStatsCollection: getLatest ?? _GetLatestOk(),
    updateStatsCollectionName: updateName ?? _UpdateNameOk(),
    statsRepository: _FakeStatsRepo(),
    exportStatsToJson: export ?? _ExportOk(),
    importStatsFromJson: import ?? _ImportOk(),
    saveCollectionsBatch: batch ?? _BatchOk(),
  );
}

// ================================================================
// Tests
// ================================================================

void main() {
  group('StatsBloc', () {
    // ── Estado inicial ──────────────────────────────────────────

    test('estado inicial es StatsInitial', () {
      expect(_buildBloc().state, isA<StatsInitial>());
    });

    // ── SaveStatsCollectionEvent ────────────────────────────────

    group('SaveStatsCollectionEvent', () {
      blocTest<StatsBloc, StatsState>(
        'emite [StatsSaving, StatsSaved, StatsCollectionsLoaded] al guardar',
        build: _buildBloc,
        act: (b) => b.add(SaveStatsCollectionEvent(_fakeCollection)),
        expect: () => [
          isA<StatsSaving>(),
          isA<StatsSaved>(),
          isA<StatsCollectionsLoaded>(),
        ],
      );

      blocTest<StatsBloc, StatsState>(
        'emite StatsError cuando la colección no tiene stats',
        build: _buildBloc,
        act: (b) => b.add(
          SaveStatsCollectionEvent(
            StatsCollection(createdAt: DateTime.now()),
          ),
        ),
        expect: () => [isA<StatsError>()],
      );

      blocTest<StatsBloc, StatsState>(
        'emite StatsError cuando el repositorio falla',
        build: () => _buildBloc(save: _SaveFail()),
        act: (b) => b.add(SaveStatsCollectionEvent(_fakeCollection)),
        expect: () => [
          isA<StatsSaving>(),
          isA<StatsError>(),
        ],
      );
    });

    // ── LoadAllStatsCollectionsEvent ────────────────────────────

    group('LoadAllStatsCollectionsEvent', () {
      blocTest<StatsBloc, StatsState>(
        'emite [StatsLoading, StatsCollectionsLoaded] al cargar colecciones',
        build: _buildBloc,
        act: (b) => b.add(LoadAllStatsCollectionsEvent()),
        expect: () => [
          isA<StatsLoading>(),
          isA<StatsCollectionsLoaded>()
              .having((s) => s.collections.length, 'length', 2),
        ],
      );

      blocTest<StatsBloc, StatsState>(
        'emite StatsError cuando la carga falla',
        build: () => _buildBloc(getAll: _GetAllFail()),
        act: (b) => b.add(LoadAllStatsCollectionsEvent()),
        expect: () => [
          isA<StatsLoading>(),
          isA<StatsError>(),
        ],
      );

      blocTest<StatsBloc, StatsState>(
        'no emite StatsLoading si ya hay StatsCollectionsLoaded',
        build: _buildBloc,
        seed: () => StatsCollectionsLoaded(_fakeCollections),
        act: (b) => b.add(LoadAllStatsCollectionsEvent()),
        expect: () => [isA<StatsCollectionsLoaded>()],
      );
    });

    // ── DeleteStatsCollectionEvent ──────────────────────────────

    group('DeleteStatsCollectionEvent', () {
      blocTest<StatsBloc, StatsState>(
        'emite [StatsLoading, StatsDeleted, StatsCollectionsLoaded]',
        build: _buildBloc,
        act: (b) =>
            b.add(DeleteStatsCollectionEvent(_fakeCollection.createdAt)),
        expect: () => [
          isA<StatsLoading>(),
          isA<StatsDeleted>(),
          isA<StatsCollectionsLoaded>(),
        ],
      );
    });

    // ── UpdateStatsCollectionNameEvent ──────────────────────────

    group('UpdateStatsCollectionNameEvent', () {
      blocTest<StatsBloc, StatsState>(
        'emite [StatsNameUpdated, StatsCollectionsLoaded]',
        build: _buildBloc,
        act: (b) => b.add(
          UpdateStatsCollectionNameEvent(
            createdAt: _fakeCollection.createdAt,
            newName: 'Nuevo Nombre',
          ),
        ),
        expect: () => [
          isA<StatsNameUpdated>()
              .having((s) => s.newName, 'newName', 'Nuevo Nombre'),
          isA<StatsCollectionsLoaded>(),
        ],
      );
    });

    // ── ExportStatsToJsonEvent ──────────────────────────────────

    group('ExportStatsToJsonEvent', () {
      blocTest<StatsBloc, StatsState>(
        'emite [StatsExporting, StatsExported] cuando la exportación es exitosa',
        build: _buildBloc,
        act: (b) => b.add(const ExportStatsToJsonEvent()),
        expect: () => [
          isA<StatsExporting>(),
          isA<StatsExported>()
              .having((s) => s.filePath, 'filePath', '/fake/export.json'),
        ],
      );

      blocTest<StatsBloc, StatsState>(
        'emite StatsError cuando la exportación falla',
        build: () => _buildBloc(export: _ExportFail()),
        act: (b) => b.add(
          ExportStatsToJsonEvent(collections: _fakeCollections),
        ),
        expect: () => [
          isA<StatsExporting>(),
          isA<StatsError>(),
        ],
      );
    });

    // ── ImportStatsFromJsonEvent ────────────────────────────────

    group('ImportStatsFromJsonEvent', () {
      blocTest<StatsBloc, StatsState>(
        'emite [StatsImporting, StatsImported] cuando la importación es exitosa',
        build: _buildBloc,
        act: (b) =>
            b.add(const ImportStatsFromJsonEvent(filePath: '/fake/file.json')),
        expect: () => [
          isA<StatsImporting>(),
          isA<StatsImported>()
              .having((s) => s.importedCount, 'importedCount', 2),
        ],
      );

      blocTest<StatsBloc, StatsState>(
        'emite StatsError cuando el parseo del archivo falla',
        build: () => _buildBloc(import: _ImportFail()),
        act: (b) =>
            b.add(const ImportStatsFromJsonEvent(filePath: '/fake/bad.json')),
        expect: () => [
          isA<StatsImporting>(),
          isA<StatsError>(),
        ],
      );

      blocTest<StatsBloc, StatsState>(
        'StatsImported incluye merged=true para importación fusionada',
        build: _buildBloc,
        act: (b) => b.add(const ImportStatsFromJsonEvent(
          filePath: '/fake/file.json',
          mergeWithExisting: true,
        )),
        expect: () => [
          isA<StatsImporting>(),
          isA<StatsImported>().having((s) => s.merged, 'merged', true),
        ],
      );

      blocTest<StatsBloc, StatsState>(
        'StatsImported incluye merged=false para importación con reemplazo',
        build: _buildBloc,
        act: (b) => b.add(const ImportStatsFromJsonEvent(
          filePath: '/fake/file.json',
          mergeWithExisting: false,
        )),
        expect: () => [
          isA<StatsImporting>(),
          isA<StatsImported>().having((s) => s.merged, 'merged', false),
        ],
      );
    });

    // ── ClearAllStatsEvent ──────────────────────────────────────

    group('ClearAllStatsEvent', () {
      blocTest<StatsBloc, StatsState>(
        'emite [StatsLoading, StatsCleared, StatsCollectionsLoaded]',
        build: _buildBloc,
        act: (b) => b.add(ClearAllStatsEvent()),
        expect: () => [
          isA<StatsLoading>(),
          isA<StatsCleared>(),
          isA<StatsCollectionsLoaded>(),
        ],
      );
    });
  });
}