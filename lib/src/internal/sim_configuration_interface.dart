import 'package:meta/meta.dart';
import 'package:simdart/src/start_time_handling.dart';

@internal
abstract interface class SimConfigurationInterface {
  /// Specifies how the simulation handles start times in the past.
  StartTimeHandling get startTimeHandling;

  /// Determines whether simulation tracks should be included in the simulation result.
  ///
  /// When set to `true`, the simulation will collect and return a list of [SimulationTrack]
  /// objects as part of its result. If set to `false`, the tracks will not be collected,
  /// and the list will be `null`.
  ///
  /// Default: `false`
  bool get includeTracks;

  /// Determines how often `Future.delayed` is used instead of `Future.microtask` during events execution.
  ///
  /// - `0`: Always uses `microtask`.
  /// - `1`: Alternates between `microtask` and `Future.delayed`.
  /// - `N > 1`: Executes `N` events with `microtask` before using `Future.delayed`.
  int get executionPriority;
}
