import 'dart:collection';

/// Represents the tracking information of an event processing in the simulation.
///
/// The track provides details about the status of the event's execution,
/// including whether it was executed, resumed, waited for, or completed.
/// It also includes the event's name and the time at which the event was processed,
/// making it useful for debugging, testing, or logging the simulation's progress.
class SimulationTrack {
  /// The event status.
  final Status status;

  /// The name of the event that was processed.
  final String name;

  /// The current time in the simulation when the event occurred.
  final int time;

  /// A map that tracks the usage of resources within the simulation.
  ///
  /// Each key represents the unique ID of a resource, and its corresponding value
  /// indicates the quantity or number of events currently allocated to that resource.
  /// This attribute is used to monitor resource consumption and manage allocations
  /// effectively during the simulation.
  late final UnmodifiableMapView<String, int> resourceUsage;

  /// Constructor for creating a [SimulationTrack] instance.
  ///
  /// [status] is the event status (e.g., [Status.executed]).
  /// [name] is the name of the event being processed, can be null.
  /// [time] is the simulation time when the event occurred.
  SimulationTrack(
      {required this.status,
      required this.name,
      required this.time,
      required Map<String, int> resourceUsage})
      : resourceUsage = UnmodifiableMapView(resourceUsage);

  @override
  String toString() {
    return '[$time][$name][$status]';
  }
}

/// Enum representing the possible event status.
///
/// This enumeration is used to track and distinguish different event status
/// during the lifecycle of the simulation.
enum Status {
  /// The event was executed for the first time.
  executed,

  /// The event was resumed after being paused.
  resumed,

  /// The event was scheduled internally, typically by [EventScheduler].
  scheduled,

  /// The resource was rejected for the event.
  rejected;

  /// Returns the string representation of the status.
  @override
  String toString() {
    return name;
  }
}
