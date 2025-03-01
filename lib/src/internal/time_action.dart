import 'package:meta/meta.dart';

/// Represents any action to be executed at a specific time in the temporal loop of the algorithm.
@internal
abstract class TimeAction {
  static int _globalOrder = 0;

  TimeAction({required this.start, int? order})
      : order = order ?? _globalOrder++;

  /// The scheduled start time.
  int start;

  final int order;

  void execute();

  void dispose();
}
