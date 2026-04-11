import 'package:dartz/dartz.dart';
import 'package:insight/core/errors/failures.dart';
import 'package:insight/features/upload/domain/entities/stats_collection.dart';

abstract class StatsRepository {
  Future<Either<Failure, void>> saveStatsCollection(StatsCollection collection);
  Future<Either<Failure, List<StatsCollection>>> getAllStatsCollections();
  Future<Either<Failure, StatsCollection?>> getLatestStatsCollection();
  Future<Either<Failure, void>> deleteStatsCollection(DateTime createdAt);
  Future<Either<Failure, void>> clearAllStats();

  Future<Either<Failure, void>> updateStatsCollectionName(DateTime createdAt, String newName);

  Future<Either<Failure, StatsCollection?>> getStatsCollectionByDate(DateTime createdAt);

  // ── Exportar / Importar ──────────────────────────────
  /// Serializa [collections] a JSON, lo escribe en disco y
  /// retorna la ruta absoluta del archivo generado.
  Future<Either<Failure, String>> exportStatsToJson(List<StatsCollection> collections);

  /// Lee el archivo JSON de [filePath] y retorna las colecciones parseadas.
  Future<Either<Failure, List<StatsCollection>>> importStatsFromJson(String filePath);

  /// Guarda múltiples colecciones en batch, omitiendo duplicados exactos.
  /// Retorna el número de colecciones efectivamente guardadas.
  Future<Either<Failure, int>> saveCollectionsBatch(
    List<StatsCollection> collections, {
    bool replaceExisting = false,
  });
}
