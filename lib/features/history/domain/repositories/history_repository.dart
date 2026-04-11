import 'package:dartz/dartz.dart';
import 'package:insight/core/errors/failures.dart';
import 'package:insight/features/history/domain/entities/stats_collection.dart';

/// Contrato del repositorio de historial.
///
/// Agrupa todas las operaciones de persistencia, búsqueda,
/// exportación e importación de [StatsCollection].
abstract class HistoryRepository {
  // ── CRUD ────────────────────────────────────────────────────────

  Future<Either<Failure, void>> saveStatsCollection(
    StatsCollection collection,
  );

  Future<Either<Failure, List<StatsCollection>>> getAllStatsCollections();

  Future<Either<Failure, StatsCollection?>> getLatestStatsCollection();

  Future<Either<Failure, StatsCollection?>> getStatsCollectionByDate(
    DateTime createdAt,
  );

  Future<Either<Failure, void>> updateStatsCollectionName(
    DateTime createdAt,
    String newName,
  );

  Future<Either<Failure, void>> deleteStatsCollection(DateTime createdAt);

  Future<Either<Failure, void>> clearAllStats();

  // ── Export / Import ─────────────────────────────────────────────

  /// Serializa [collections] a JSON, escribe el archivo en disco y
  /// retorna la ruta absoluta del archivo generado.
  Future<Either<Failure, String>> exportStatsToJson(
    List<StatsCollection> collections,
  );

  /// Lee el archivo JSON de [filePath] y retorna las colecciones parseadas.
  Future<Either<Failure, List<StatsCollection>>> importStatsFromJson(
    String filePath,
  );

  /// Guarda múltiples colecciones omitiendo duplicados exactos.
  /// Retorna el número de colecciones efectivamente guardadas.
  Future<Either<Failure, int>> saveCollectionsBatch(
    List<StatsCollection> collections, {
    bool replaceExisting = false,
  });
}
