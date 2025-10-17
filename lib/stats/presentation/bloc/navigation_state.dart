import 'package:equatable/equatable.dart';

abstract class NavigationState extends Equatable {
  const NavigationState();

  @override
  List<Object> get props => [];
}

class NavigationInitial extends NavigationState {
  final int currentIndex;

  const NavigationInitial({this.currentIndex = 0});

  @override
  List<Object> get props => [currentIndex];
}

class NavigationChanged extends NavigationState {
  final int currentIndex;

  const NavigationChanged(this.currentIndex);

  @override
  List<Object> get props => [currentIndex];
}
