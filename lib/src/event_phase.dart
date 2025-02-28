/// Enum representing the possible event phases.
///
/// This enumeration is used to track and distinguish different event status
/// during the lifecycle of the simulation.
enum EventPhase {
  /// The event was called for the first time.
  called,

  /// The event was resumed after being paused.
  resumed,

  yielded,

  finished;

  /// Returns the string representation of the status.
  @override
  String toString() {
    return name;
  }
}
