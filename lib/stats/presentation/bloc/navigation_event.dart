import 'package:equatable/equatable.dart';

abstract class NavigationEvent extends Equatable {
  const NavigationEvent();

  @override
  List<Object> get props => [];
}

class NavigationItemSelected extends NavigationEvent {
  final int index;

  const NavigationItemSelected(this.index);

  @override
  List<Object> get props => [index];
}

class NavigationReset extends NavigationEvent {}
