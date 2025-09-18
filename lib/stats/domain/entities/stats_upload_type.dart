enum StatsUploadType {
  total('Estadísticas Totales', 1),
  byModes('Por Modos de Juego', 3);

  const StatsUploadType(this.displayName, this.imageCount);
  final String displayName;
  final int imageCount;

  String get appBarTitle {
    switch (this) {
      case StatsUploadType.total:
        return 'Cargar Estadísticas Totales';
      case StatsUploadType.byModes:
        return 'Cargar por Modos de Juego';
    }
  }
}
