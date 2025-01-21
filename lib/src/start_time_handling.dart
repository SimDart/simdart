/// Defines how the simulation should handle start times that are in the past.
enum StartTimeHandling {
  /// Throws an exception if the start time is in the past.
  throwErrorIfPast,

  /// Uses the current simulation time (sim.now) if the start time is in the past.
  useNowIfPast
}
