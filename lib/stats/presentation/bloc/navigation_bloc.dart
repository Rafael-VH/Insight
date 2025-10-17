import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:insight/stats/presentation/bloc/navigation_event.dart';
import 'package:insight/stats/presentation/bloc/navigation_state.dart';

class NavigationBloc extends Bloc<NavigationEvent, NavigationState> {
  NavigationBloc() : super(const NavigationInitial()) {
    on<NavigationItemSelected>(_onNavigationItemSelected);
    on<NavigationReset>(_onNavigationReset);
  }

  void _onNavigationItemSelected(
    NavigationItemSelected event,
    Emitter<NavigationState> emit,
  ) {
    emit(NavigationChanged(event.index));
  }

  void _onNavigationReset(
    NavigationReset event,
    Emitter<NavigationState> emit,
  ) {
    emit(const NavigationInitial());
  }

  int get currentIndex {
    if (state is NavigationChanged) {
      return (state as NavigationChanged).currentIndex;
    }
    if (state is NavigationInitial) {
      return (state as NavigationInitial).currentIndex;
    }
    return 0;
  }
}
