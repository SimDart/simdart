import 'package:simdart/src/event_phase.dart';

/// A base class for listening simulation.
abstract class SimListener {
  /// Called when there is a change in resource usage.
  ///
  /// [name] - The name of the resource whose usage is being reported.
  /// [usage] - The percentage of resource usage, typically between 0 and 100.
  // void onResourceUsage({required String name, required double usage});

  /// Called when an event occurs in the simulation.
  ///
  /// [name] - The name of the event being processed. This can be null if the event does not have a name.
  /// [time] - The simulation time when the event occurred, usually in ticks or arbitrary units depending on the simulation.
  /// [phase] - The phase during which the event occurred. This helps categorize the event's context in the simulation lifecycle.
  /// [executionHash] - The hash of the event execution.
  void onEvent(
      {required String name,
      required int time,
      required EventPhase phase,
      required int executionHash});

  void onStart() {}

  void onError(String error);
}

mixin SimListenerMixin implements SimListener {
  @override
  void onStart() {}
  @override
  void onError(String error) {}
  //@override
  //void onResourceUsage({required String name, required double usage}) {}
  @override
  void onEvent(
      {required String name,
      required int time,
      required EventPhase phase,
      required int executionHash}) {}
}

class ConsoleEventListener with SimListenerMixin {
  ConsoleEventListener();

  @override
  void onEvent(
      {required String name,
      required int time,
      required EventPhase phase,
      required int executionHash}) {
    print('[time:$time][event:$name][phase:${phase.name}]');
  }

  @override
  void onError(String error) {
    print('Error: $error');
  }
}
