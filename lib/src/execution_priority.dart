/// Enum that defines the priority of task execution in the system.
///
/// - `highPriority`: Execution is given high priority, and it will be
///   processed using `Future.microtask` between events, allowing for
///   immediate execution without blocking the UI.
///
/// - `lowPriority`: Execution is given lower priority, using `Future.delayed(Duration.zero)`,
///   which allows for non-blocking execution and ensures that the UI is not blocked, allowing
///   for smoother interactions with the user interface.
enum ExecutionPriority {
  /// High priority execution, will use `Future.microtask` between events.
  /// This ensures that the task runs immediately without blocking other operations or the UI.
  high,

  /// Low priority execution, will use `Future.delayed(Duration.zero)`.
  /// This ensures that the task is executed with minimal blocking, allowing the UI to remain responsive.
  low
}
