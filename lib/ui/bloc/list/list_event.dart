part of 'list_bloc.dart';

@immutable
abstract class ListEvent extends Equatable {}

class ListLoadEvent extends ListEvent {
  @override
  List<Object?> get props => [];
}