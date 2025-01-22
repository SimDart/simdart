import 'dart:async';

import 'package:simdart/src/simdart.dart';

/// The event to be executed.
///
/// A function that represents an event in the simulation. It receives an
/// [EventContext] that provides data about the event's execution state and context.
typedef Event = void Function(EventContext context);

/// Represents the context of an event in the simulation.
///
/// Encapsulates the information and state of an event being executed
/// within the simulation.
mixin EventContext {
  /// The simulation instance managing this event.
  SimDart get sim;

  /// Pauses the execution of the event for the specified [delay] in simulation time.
  ///
  /// The event is re-added to the simulation's event queue and will resume after
  /// the specified delay has passed.
  ///
  /// Throws an [ArgumentError] if the delay is negative.
  Future<void> wait(int delay);
}
