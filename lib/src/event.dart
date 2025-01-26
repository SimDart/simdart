import 'dart:async';
import 'dart:math';

import 'package:simdart/src/internal/event_scheduler_interface.dart';

/// The event to be executed.
///
/// A function that represents an event in the simulation. It receives an
/// [EventContext] that provides data about the event's execution state and context.
typedef Event = void Function(EventContext context);

/// Represents the context of an event in the simulation.
///
/// Encapsulates the information and state of an event being executed
/// within the simulation.
abstract interface class EventContext implements EventSchedulerInterface {
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
}
