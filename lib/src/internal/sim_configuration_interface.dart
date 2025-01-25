import 'package:meta/meta.dart';
import 'package:simdart/src/execution_priority.dart';
import 'package:simdart/src/start_time_handling.dart';

@internal
abstract interface class SimConfigurationInterface {
  /// Specifies how the simulation handles start times in the past.
  StartTimeHandling get startTimeHandling;

  /// Defines the priority of task execution in the simulation.
  ///
  /// - `highPriority`: Uses `Future.microtask` for immediate execution, prioritizing
  ///   processing without blocking the UI.
  /// - `lowPriority`: Uses `Future.delayed(Duration.zero)` to ensure non-blocking
  ///   execution, allowing the UI to remain responsive.
  ExecutionPriority get executionPriority;

  /// Determines whether simulation tracks should be included in the simulation result.
  ///
  /// When set to `true`, the simulation will collect and return a list of [SimulationTrack]
  /// objects as part of its result. If set to `false`, the tracks will not be collected,
  /// and the list will be `null`.
  ///
  /// Default: `false`
  bool get includeTracks;
}
