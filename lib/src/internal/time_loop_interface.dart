import 'package:meta/meta.dart';
import 'package:simdart/src/execution_priority.dart';
import 'package:simdart/src/internal/now_interface.dart';
import 'package:simdart/src/start_time_handling.dart';

/// Represents the temporal loop in the algorithm, managing the execution of actions at specified times.
@internal
abstract interface class TimeLoopInterface implements NowInterface {
  /// Specifies how the simulation handles start times in the past.
  StartTimeHandling get startTimeHandling;

  /// Defines the priority of task execution in the simulation.
  ///
  /// - `highPriority`: Uses `Future.microtask` for immediate execution, prioritizing
  ///   processing without blocking the UI.
  /// - `lowPriority`: Uses `Future.delayed(Duration.zero)` to ensure non-blocking
  ///   execution, allowing the UI to remain responsive.
  ExecutionPriority get executionPriority;

  /// The time, in simulated time units, when the simulation started.
  /// This is the moment at which the first event is scheduled to be processed.
  ///
  /// For example, if the first process is scheduled to occur at time 10,
  /// then the simulation start time would be 10. This value helps track when
  /// the simulation officially begins its execution in terms of the simulation time.
  int? get startTime;

  /// The duration, in simulated time units, that the simulation took to execute.
  ///
  /// This value represents the total time elapsed during the processing of the simulation,
  /// from the start to the completion of all event handling, in terms of the simulated environment.
  /// It is used to track how much time has passed in the simulation model, not real-world time.
  ///
  /// The value will be `null` if the duration has not been calculated or set.
  int? get duration;
}
