enum GameMode {
  total('Todas las Temporadas Todos los Juegos'),
  ranked('Todas las Temporadas Clasificatoria'),
  classic('Todas las Temporadas Clásica'),
  brawl('Todas las Temporadas Coliseo');

  const GameMode(this.displayName);
  final String displayName;
}
