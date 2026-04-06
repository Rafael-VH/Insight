import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:insight/core/errors/failures.dart';
import 'package:insight/features/heroes/domain/entities/hero_detail.dart';
import 'package:insight/features/heroes/domain/entities/mlbbhero.dart';
import 'package:insight/features/heroes/domain/usecases/get_hero_detail.dart';
import 'package:insight/features/heroes/domain/usecases/get_heroes.dart';
import 'package:insight/features/heroes/presentation/bloc/hero_bloc.dart';
import 'package:insight/features/heroes/presentation/bloc/hero_event.dart';
import 'package:insight/features/heroes/presentation/bloc/hero_state.dart';

// ── Stubs simples (sin mockito para evitar dependencia de build_runner) ──────

class _FakeGetHeroes extends Fake implements GetHeroes {
  final Either<Failure, List<MlbbHero>> _response;
  _FakeGetHeroes(this._response);

  @override
  Future<Either<Failure, List<MlbbHero>>> call() async => _response;
}

class _FakeGetHeroDetail extends Fake implements GetHeroDetail {
  final Either<Failure, HeroDetail> _response;
  _FakeGetHeroDetail(this._response);

  @override
  Future<Either<Failure, HeroDetail>> call(int heroId) async => _response;
}

// ── Datos de prueba ───────────────────────────────────────────────

final _fakeHeroes = [
  const MlbbHero(heroId: 1, name: 'Layla', iconUrl: 'https://ex.com/1.png'),
  const MlbbHero(heroId: 2, name: 'Miya', iconUrl: 'https://ex.com/2.png'),
  const MlbbHero(heroId: 3, name: 'Alpha', iconUrl: 'https://ex.com/3.png'),
];

const _fakeDetail = HeroDetail(
  heroId: 1,
  name: 'Layla',
  iconUrl: 'https://ex.com/1.png',
  story: 'Una heroína valiente.',
  roles: ['Marksman'],
  specialties: ['Reap'],
  lane: 'Gold Lane',
);

void main() {
  group('HeroBloc', () {
    // ── LoadHeroListEvent ─────────────────────────────────────────

    group('LoadHeroListEvent', () {
      blocTest<HeroBloc, HeroState>(
        'emite [HeroListLoading, HeroListLoaded] cuando la carga es exitosa',
        build: () => HeroBloc(
          getHeroes: _FakeGetHeroes(Right(_fakeHeroes)),
          getHeroDetail: _FakeGetHeroDetail(const Right(_fakeDetail)),
        ),
        act: (b) => b.add(const LoadHeroListEvent()),
        expect: () => [
          isA<HeroListLoading>(),
          isA<HeroListLoaded>()
              .having((s) => s.heroes.length, 'heroes.length', 3)
              .having((s) => s.filtered.length, 'filtered.length', 3),
        ],
      );

      blocTest<HeroBloc, HeroState>(
        'emite [HeroListLoading, HeroListError] cuando la carga falla',
        build: () => HeroBloc(
          getHeroes: _FakeGetHeroes(
            const Left(FileSystemFailure('Sin conexión')),
          ),
          getHeroDetail: _FakeGetHeroDetail(const Right(_fakeDetail)),
        ),
        act: (b) => b.add(const LoadHeroListEvent()),
        expect: () => [
          isA<HeroListLoading>(),
          isA<HeroListError>()
              .having((s) => s.message, 'message', 'Sin conexión'),
        ],
      );

      blocTest<HeroBloc, HeroState>(
        'emite HeroListError cuando la lista viene vacía',
        build: () => HeroBloc(
          getHeroes: _FakeGetHeroes(const Right([])),
          getHeroDetail: _FakeGetHeroDetail(const Right(_fakeDetail)),
        ),
        act: (b) => b.add(const LoadHeroListEvent()),
        expect: () => [
          isA<HeroListLoading>(),
          isA<HeroListError>(),
        ],
      );

      blocTest<HeroBloc, HeroState>(
        'NO recarga si ya está cargado y forceRefresh es false',
        build: () => HeroBloc(
          getHeroes: _FakeGetHeroes(Right(_fakeHeroes)),
          getHeroDetail: _FakeGetHeroDetail(const Right(_fakeDetail)),
        ),
        seed: () => HeroListLoaded(heroes: _fakeHeroes, filtered: _fakeHeroes),
        act: (b) => b.add(const LoadHeroListEvent(forceRefresh: false)),
        expect: () => [],
      );

      blocTest<HeroBloc, HeroState>(
        'recarga si forceRefresh es true aunque esté cargado',
        build: () => HeroBloc(
          getHeroes: _FakeGetHeroes(Right(_fakeHeroes)),
          getHeroDetail: _FakeGetHeroDetail(const Right(_fakeDetail)),
        ),
        seed: () => HeroListLoaded(heroes: _fakeHeroes, filtered: _fakeHeroes),
        act: (b) => b.add(const LoadHeroListEvent(forceRefresh: true)),
        expect: () => [
          isA<HeroListLoading>(),
          isA<HeroListLoaded>(),
        ],
      );
    });

    // ── SearchHeroListEvent ───────────────────────────────────────

    group('SearchHeroListEvent', () {
      blocTest<HeroBloc, HeroState>(
        'filtra héroes por nombre',
        build: () => HeroBloc(
          getHeroes: _FakeGetHeroes(Right(_fakeHeroes)),
          getHeroDetail: _FakeGetHeroDetail(const Right(_fakeDetail)),
        ),
        seed: () =>
            HeroListLoaded(heroes: _fakeHeroes, filtered: _fakeHeroes),
        act: (b) => b.add(const SearchHeroListEvent('lay')),
        expect: () => [
          isA<HeroListLoaded>().having(
            (s) => s.filtered.length,
            'filtered.length',
            1,
          ),
        ],
      );

      blocTest<HeroBloc, HeroState>(
        'muestra todos cuando la búsqueda está vacía',
        build: () => HeroBloc(
          getHeroes: _FakeGetHeroes(Right(_fakeHeroes)),
          getHeroDetail: _FakeGetHeroDetail(const Right(_fakeDetail)),
        ),
        seed: () => HeroListLoaded(
          heroes: _fakeHeroes,
          filtered: [_fakeHeroes[0]], // solo layla visible
        ),
        act: (b) => b.add(const SearchHeroListEvent('')),
        expect: () => [
          isA<HeroListLoaded>().having(
            (s) => s.filtered.length,
            'filtered.length',
            3,
          ),
        ],
      );

      blocTest<HeroBloc, HeroState>(
        'lista vacía cuando no hay coincidencias',
        build: () => HeroBloc(
          getHeroes: _FakeGetHeroes(Right(_fakeHeroes)),
          getHeroDetail: _FakeGetHeroDetail(const Right(_fakeDetail)),
        ),
        seed: () =>
            HeroListLoaded(heroes: _fakeHeroes, filtered: _fakeHeroes),
        act: (b) => b.add(const SearchHeroListEvent('zzznomatch')),
        expect: () => [
          isA<HeroListLoaded>().having(
            (s) => s.filtered.length,
            'filtered.length',
            0,
          ),
        ],
      );

      blocTest<HeroBloc, HeroState>(
        'no emite nada si aún no hay lista cargada',
        build: () => HeroBloc(
          getHeroes: _FakeGetHeroes(Right(_fakeHeroes)),
          getHeroDetail: _FakeGetHeroDetail(const Right(_fakeDetail)),
        ),
        act: (b) => b.add(const SearchHeroListEvent('lay')),
        expect: () => [],
      );

      blocTest<HeroBloc, HeroState>(
        'búsqueda es case-insensitive',
        build: () => HeroBloc(
          getHeroes: _FakeGetHeroes(Right(_fakeHeroes)),
          getHeroDetail: _FakeGetHeroDetail(const Right(_fakeDetail)),
        ),
        seed: () =>
            HeroListLoaded(heroes: _fakeHeroes, filtered: _fakeHeroes),
        act: (b) => b.add(const SearchHeroListEvent('LAYLA')),
        expect: () => [
          isA<HeroListLoaded>().having(
            (s) => s.filtered.length,
            'filtered.length',
            1,
          ),
        ],
      );
    });

    // ── LoadHeroDetailEvent ───────────────────────────────────────

    group('LoadHeroDetailEvent', () {
      blocTest<HeroBloc, HeroState>(
        'emite [HeroDetailLoading, HeroDetailLoaded] cuando el detalle carga',
        build: () => HeroBloc(
          getHeroes: _FakeGetHeroes(Right(_fakeHeroes)),
          getHeroDetail: _FakeGetHeroDetail(const Right(_fakeDetail)),
        ),
        act: (b) => b.add(const LoadHeroDetailEvent(1)),
        expect: () => [
          isA<HeroDetailLoading>(),
          isA<HeroDetailLoaded>()
              .having((s) => s.detail.name, 'name', 'Layla'),
        ],
      );

      blocTest<HeroBloc, HeroState>(
        'emite [HeroDetailLoading, HeroDetailError] cuando falla el detalle',
        build: () => HeroBloc(
          getHeroes: _FakeGetHeroes(Right(_fakeHeroes)),
          getHeroDetail: _FakeGetHeroDetail(
            const Left(FileSystemFailure('Héroe no encontrado')),
          ),
        ),
        act: (b) => b.add(const LoadHeroDetailEvent(999)),
        expect: () => [
          isA<HeroDetailLoading>(),
          isA<HeroDetailError>()
              .having((s) => s.message, 'message', 'Héroe no encontrado'),
        ],
      );
    });

    // ── HeroListLoaded.copyWith ───────────────────────────────────

    group('HeroListLoaded.copyWith', () {
      test('actualiza filtered manteniendo heroes', () {
        final state = HeroListLoaded(
          heroes: _fakeHeroes,
          filtered: _fakeHeroes,
        );
        final updated = state.copyWith(filtered: [_fakeHeroes[0]]);
        expect(updated.heroes.length, equals(3));
        expect(updated.filtered.length, equals(1));
      });

      test('actualiza searchQuery', () {
        final state = HeroListLoaded(
          heroes: _fakeHeroes,
          filtered: _fakeHeroes,
        );
        final updated = state.copyWith(searchQuery: 'alpha');
        expect(updated.searchQuery, equals('alpha'));
      });
    });
  });
}