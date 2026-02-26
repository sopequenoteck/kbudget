import 'package:freezed_annotation/freezed_annotation.dart';

part 'list_state.freezed.dart';

@freezed
class ListState<T> with _$ListState<T> {
  const factory ListState({
    @Default([]) List<T> items,
    @Default(false) bool isLoading,
    String? error,
    @Default(0) int currentPage,
    @Default(true) bool hasMore,
    @Default({}) Set<String> mutatingIds,
  }) = _ListState<T>;
}
