import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:insight/features/navigation/presentation/bloc/navigation_bloc.dart';
import 'package:insight/features/navigation/presentation/bloc/navigation_event.dart';
import 'package:insight/features/navigation/presentation/bloc/navigation_state.dart';

void main() {
  group('NavigationBloc', () {
    late NavigationBloc bloc;

    setUp(() {
      bloc = NavigationBloc(totalDestinations: 4);
    });

    tearDown(() {
      bloc.close();
    });

    // ── Estado inicial ────────────────────────────────────────────

    test('estado inicial es NavigationInitial con índice 0', () {
      expect(bloc.state, isA<NavigationInitial>());
      expect(bloc.state.currentIndex, equals(0));
    });

    // ── NavigationItemSelected ────────────────────────────────────

    group('NavigationItemSelected', () {
      blocTest<NavigationBloc, NavigationState>(
        'emite NavigationChanged al seleccionar un índice válido',
        build: () => NavigationBloc(totalDestinations: 4),
        act: (b) => b.add(const NavigationItemSelected(2)),
        expect: () => [
          isA<NavigationChanged>().having((s) => s.currentIndex, 'index', 2),
        ],
      );

      blocTest<NavigationBloc, NavigationState>(
        'no emite nada al seleccionar el índice actual',
        build: () => NavigationBloc(totalDestinations: 4),
        act: (b) => b.add(const NavigationItemSelected(0)),
        expect: () => [],
      );

      blocTest<NavigationBloc, NavigationState>(
        'emite NavigationError para índice fuera de rango',
        build: () => NavigationBloc(totalDestinations: 4),
        act: (b) => b.add(const NavigationItemSelected(10)),
        expect: () => [isA<NavigationError>()],
      );

      blocTest<NavigationBloc, NavigationState>(
        'emite NavigationError para índice negativo',
        build: () => NavigationBloc(totalDestinations: 4),
        act: (b) => b.add(const NavigationItemSelected(-1)),
        expect: () => [isA<NavigationError>()],
      );

      blocTest<NavigationBloc, NavigationState>(
        'NavigationChanged incluye previousIndex correcto',
        build: () => NavigationBloc(totalDestinations: 4),
        act: (b) => b.add(const NavigationItemSelected(3)),
        expect: () => [
          isA<NavigationChanged>()
              .having((s) => s.currentIndex, 'currentIndex', 3)
              .having((s) => s.previousIndex, 'previousIndex', 0),
        ],
      );
    });

    // ── NavigationReset ───────────────────────────────────────────

    group('NavigationReset', () {
      blocTest<NavigationBloc, NavigationState>(
        'vuelve a NavigationInitial con índice 0',
        build: () => NavigationBloc(totalDestinations: 4),
        act: (b) {
          b.add(const NavigationItemSelected(2));
          b.add(const NavigationReset());
        },
        expect: () => [
          isA<NavigationChanged>(),
          isA<NavigationInitial>()
              .having((s) => s.currentIndex, 'index', 0),
        ],
      );
    });

    // ── NavigateBack ──────────────────────────────────────────────

    group('NavigateBack', () {
      blocTest<NavigationBloc, NavigationState>(
        'vuelve al índice anterior tras navegar hacia adelante',
        build: () => NavigationBloc(totalDestinations: 4),
        act: (b) {
          b.add(const NavigationItemSelected(2));
          b.add(const NavigateBack());
        },
        expect: () => [
          isA<NavigationChanged>()
              .having((s) => s.currentIndex, 'currentIndex', 2),
          isA<NavigationChanged>()
              .having((s) => s.currentIndex, 'currentIndex', 0),
        ],
      );

      blocTest<NavigationBloc, NavigationState>(
        'emite NavigationInitial cuando no hay historial previo',
        build: () => NavigationBloc(totalDestinations: 4),
        act: (b) => b.add(const NavigateBack()),
        expect: () => [isA<NavigationInitial>()],
      );
    });

    // ── UpdateNavigationBadge ─────────────────────────────────────

    group('UpdateNavigationBadge', () {
      blocTest<NavigationBloc, NavigationState>(
        'emite NavigationBadgeUpdated con el badge correcto',
        build: () => NavigationBloc(totalDestinations: 4),
        act: (b) =>
            b.add(const UpdateNavigationBadge(index: 1, badge: '5')),
        expect: () => [
          isA<NavigationBadgeUpdated>()
              .having((s) => s.updatedItemIndex, 'itemIndex', 1)
              .having((s) => s.badge, 'badge', '5'),
        ],
      );

      blocTest<NavigationBloc, NavigationState>(
        'emite NavigationError para índice de badge fuera de rango',
        build: () => NavigationBloc(totalDestinations: 4),
        act: (b) =>
            b.add(const UpdateNavigationBadge(index: 99, badge: '1')),
        expect: () => [isA<NavigationError>()],
      );

      test('getBadge retorna el badge correcto después de actualizar', () {
        bloc.add(const UpdateNavigationBadge(index: 2, badge: '3'));
        // Pequeño delay para que el evento se procese
        Future.delayed(
          Duration.zero,
          () => expect(bloc.getBadge(2), equals('3')),
        );
      });
    });

    // ── currentIndex y canGoBack ──────────────────────────────────

    group('getters', () {
      test('currentIndex refleja el estado actual', () {
        expect(bloc.currentIndex, equals(0));
      });

      test('canGoBack es false en el estado inicial', () {
        expect(bloc.canGoBack, isFalse);
      });

      test('canGoBack es true tras navegar a otro índice', () async {
        bloc.add(const NavigationItemSelected(2));
        await Future.delayed(Duration.zero);
        expect(bloc.canGoBack, isTrue);
      });

      test('history tiene el índice 0 por defecto', () {
        expect(bloc.history, equals([0]));
      });
    });
  });
}