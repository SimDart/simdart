import 'package:meta/meta.dart';

/// Represents any action to be executed at a specific time in the temporal loop of the algorithm.
@internal
abstract class TimeAction {
  TimeAction({required this.start});

  /// The scheduled start time.
  int start;

  void execute();

  Future<void> wait(int delay);

  Future<void> acquireResource(String id);

  void releaseResource(String id);

  int secondaryCompareTo(TimeAction action) {
    return 0;
  }
}
