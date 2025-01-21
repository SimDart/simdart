import 'package:simdart/src/event.dart';
import 'package:simdart/src/simdart.dart';

/// Represents a generator of events that is triggered based on changes in the system state.
///
/// The [Observable] monitors changes in the system (such as changes to entity states or other values) and generates
/// events dynamically in response to those changes. It operates by observing the specified condition or trigger point
/// and schedules events accordingly.
class Observable {
  /// Creates an [Observable] instance with the provided parameters.
  ///
  /// The [condition] is a function that evaluates the state of the system and determines when an event should be generated.
  /// The [event] is the event to be generated when the condition is met.
  /// The [eventName] is an optional custom name for the event.
  ///
  /// The generator will observe changes in the system and generate events based on the provided condition.
  Observable({
    required this.condition,
    required this.event,
    this.eventName,
  });

  /// The condition function that determines when the event should be triggered.
  ///
  /// This function is continuously evaluated, and when it returns `true`, an event is generated.
  final bool Function(SimDart) condition;

  /// The event that is generated when the condition is met.
  final Event event;

  /// An optional name for the event.
  final String? eventName;
}
