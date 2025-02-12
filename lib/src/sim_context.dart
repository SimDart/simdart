import 'dart:async';
import 'dart:math';

import 'package:simdart/simdart.dart';
import 'package:simdart/src/internal/event_scheduler_interface.dart';

/// Represents the context of the simulation.
///
/// Encapsulates the information and state of the simulation.
abstract interface class SimContext implements EventSchedulerInterface {
  /// Pauses the execution of the event for the specified [delay] in simulation time.
  ///
  /// The event is re-added to the simulation's event queue and will resume after
  /// the specified delay has passed.
  ///
  /// Throws an [ArgumentError] if the delay is negative.
  Future<void> wait(int delay);

  /// The instance of the random number generator used across the simulation.
  /// It is initialized once and reused to improve performance, avoiding the need to
  /// instantiate a new `Random` object for each event.
  Random get random;

  /// Creates a new [SimCounter] instance with the given name.
  ///
  /// - [name]: The name of the counter. This is used to identify the counter in logs or reports.
  /// - Returns: A new instance of [SimCounter].
  SimCounter counter(String name);

  /// Creates a new [SimNum] instance with the given name.
  ///
  /// - [name]: The name of the numeric metric. This is used to identify the metric in logs or reports.
  /// - Returns: A new instance of [SimNum].
  SimNum num(String name);
}
