import 'dart:async';
import 'dart:collection';
import 'dart:math';

import 'package:meta/meta.dart';
import 'package:simdart/src/event.dart';
import 'package:simdart/src/execution_priority.dart';
import 'package:simdart/src/internal/event_action.dart';
import 'package:simdart/src/internal/repeat_event_action.dart';
import 'package:simdart/src/internal/time_loop.dart';
import 'package:simdart/src/internal/time_loop_mixin.dart';
import 'package:simdart/src/interval.dart';
import 'package:simdart/src/internal/resource.dart';
import 'package:simdart/src/resource_configurator.dart';
import 'package:simdart/src/simulation_track.dart';
import 'package:simdart/src/start_time_handling.dart';

/// Represents a discrete-event simulation engine.
class SimDart with TimeLoopMixin {
  /// Creates a simulation instance.
  ///
  /// [startTimeHandling] determines how to handle events scheduled with a start
  /// time in the past. The default behavior is [StartTimeHandling.throwErrorIfPast].
  /// [onTrack] is an optional callback function that can be used to track the progress
  /// of the simulation.
  /// [seed] is an optional parameter used to initialize the random number generator
  /// for deterministic behavior in the simulation. If provided, it ensures that the
  /// random sequence is reproducible for the same seed value.
  /// [secondarySortByName] - If true, events with the same start time are sorted
  /// by their event name. Defaults to false.
  /// [executionPriority] defines the priority of task execution in the simulation.
  SimDart(
      {StartTimeHandling startTimeHandling = StartTimeHandling.throwErrorIfPast,
      OnTrack? onTrack,
      this.secondarySortByName = false,
      ExecutionPriority executionPriority = ExecutionPriority.high,
      int? now,
      int? seed})
      : _onTrack = onTrack,
        random = Random(seed) {
    _loop = TimeLoop(
        now: now,
        beforeRun: _beforeRun,
        executionPriority: executionPriority,
        startTimeHandling: startTimeHandling);
  }

  late final TimeLoop _loop;

  /// Determines whether events with the same start time are sorted by their event name.
  ///
  /// The primary sorting criterion is always the simulated start time (`start`). If
  /// two events have the same start time, the order between them will be decided by
  /// their event name when [secondarySortByName] is set to true. If false, the order
  /// remains undefined for events with identical start times.
  final bool secondarySortByName;

  final Map<dynamic, Resource> _resources = {};

  /// Holds the configurations for the resources in the simulator.
  ///
  /// Once the simulation begins, no new resource configurations can be added to
  /// this list.
  final ResourcesConfigurator resources = ResourcesConfigurator();

  /// The instance of the random number generator used across the simulation.
  /// It is initialized once and reused to improve performance, avoiding the need to
  /// instantiate a new `Random` object for each event.
  late final Random random;

  /// A callback function used to track the progress of the simulation.
  /// If provided, this function will be called with each [SimulationTrack] generated
  /// during the simulation. This is useful for debugging or logging purposes.
  final OnTrack? _onTrack;

  /// A queue that holds event actions that are waiting for a resource to become available.
  ///
  /// These events were initially denied the resource and are placed in this queue
  /// to await the opportunity to be processed once the resource is released.
  final Queue<EventAction> _waitingForResource = Queue();

  void _beforeRun() {
    for (ResourceConfiguration rc
        in ResourcesConfiguratorHelper.iterable(configurator: resources)) {
      if (rc is LimitedResourceConfiguration) {
        _resources[rc.id] = LimitedResource(id: rc.id, capacity: rc.capacity);
      }
    }
  }

  /// Runs the simulation, processing events in chronological order.
  Future<void> run() async {
    return _loop.run();
  }

  /// Schedules a new event to occur repeatedly based on the specified interval configuration.
  ///
  /// [event] is the function that represents the action to be executed when the event occurs.
  /// [interval] defines the timing configuration for the event, including its start time and
  /// the interval between repetitions. The specific details of the interval behavior depend
  /// on the implementation of the [Interval].
  /// [resourceId] is an optional parameter that specifies the ID of the resource required by the event.
  /// [name] is an optional identifier for the event.
  /// [rejectedEventPolicy] defines the behavior of the interval after a newly created event has been rejected.
  ///
  /// Throws an [ArgumentError] if the provided interval configuration is invalid, such as
  /// containing negative or inconsistent timing values.
  void repeatProcess(
      {required Event event,
      required Interval interval,
      RejectedEventPolicy rejectedEventPolicy =
          RejectedEventPolicy.keepRepeating,
      String? resourceId,
      String? name}) {
    int? start = interval.nextStart(this);
    if (start != null) {
      _process(
          event: event,
          start: start,
          name: name,
          resourceId: resourceId,
          interval: interval);
    }
  }

  /// Schedules a new event to occur at a specific simulation time or after a delay.
  ///
  /// [event] is the function that represents the action to be executed when the event occurs.
  /// [start] is the absolute time at which the event should occur. If null, the event will
  /// occur at the [now] simulation time.
  /// [delay] is the number of time units after the [now] when the event has been scheduled.
  /// It cannot be provided if [start] is specified.
  /// [resourceId] is an optional parameter that specifies the ID of the resource required by the event.
  /// [name] is an optional identifier for the event.
  ///
  /// Throws an [ArgumentError] if both [start] and [delay] are provided or if [delay] is negative.
  void process(
      {required Event event,
      String? resourceId,
      String? name,
      int? start,
      int? delay}) {
    if (start != null && delay != null) {
      throw ArgumentError(
          'Both start and delay cannot be provided at the same time.');
    }

    if (delay != null) {
      if (delay < 0) {
        throw ArgumentError('Delay cannot be negative.');
      }
      start = now + delay;
    }

    start ??= now;

    _process(
        event: event,
        start: start,
        name: name,
        resourceId: resourceId,
        interval: null);
  }

  void _process(
      {required Event event,
      required int start,
      required String? name,
      required String? resourceId,
      required Interval? interval,
      final RejectedEventPolicy? rejectedEventPolicy}) {
    if (start < now) {
      if (startTimeHandling == StartTimeHandling.throwErrorIfPast) {
        throw ArgumentError('Event start time cannot be in the past');
      } else if (startTimeHandling == StartTimeHandling.useNowIfPast) {
        // Uses the current time if the start time is in the past
        start = now;
      }
    }
    if (start < 0) {
      throw ArgumentError('Event start time cannot be negative.');
    }
    if (interval != null && rejectedEventPolicy != null) {
      _loop.addAction(RepeatEventAction(
          sim: this,
          rejectedEventPolicy: rejectedEventPolicy,
          start: start,
          eventName: name,
          event: event,
          resourceId: resourceId,
          interval: interval));
    } else {
      _loop.addAction(EventAction(
          sim: this,
          onTrack: _onTrack,
          start: start,
          eventName: name,
          event: event,
          resourceId: resourceId,
          secondarySortByName: secondarySortByName));
    }
  }

  @override
  int? get duration => _loop.duration;

  @override
  ExecutionPriority get executionPriority => _loop.executionPriority;

  @override
  int get now => _loop.now;

  @override
  int? get startTime => _loop.startTime;

  @override
  StartTimeHandling get startTimeHandling => _loop.startTimeHandling;
}

/// A function signature for tracking the progress of a simulation.
typedef OnTrack = void Function(SimulationTrack track);

/// Defines the behavior of the interval after a newly created event has been rejected.
enum RejectedEventPolicy {
  /// Continues the repetition of the event at the specified intervals, even after the event was rejected.
  keepRepeating,

  /// Restart the repetition once the event has been resumed.
  restartOnResume,

  /// Stops the repetition of the event entirely after it has been rejected.
  stopRepeating
}

/// A helper class to access private members of the [SimDart] class.
///
/// This class is marked as internal and should only be used within the library.
@internal
class SimDartHelper {
  /// Adds an [EventAction] to the loop.
  static void addEvent({required SimDart sim, required EventAction action}) {
    sim._loop.addAction(action);
  }

  static void restoreWaitingEventsForResource({required SimDart sim}) {
    while (sim._waitingForResource.isNotEmpty) {
      sim._loop.addAction(sim._waitingForResource.removeFirst());
    }
  }

  static void queueOnWaitingForResource(
      {required SimDart sim, required EventAction action}) {
    sim._waitingForResource.add(action);
  }

  static Resource? getResource(
      {required SimDart sim, required String? resourceId}) {
    return sim._resources[resourceId];
  }

  static SimulationTrack buildSimulationTrack(
      {required SimDart sim,
      required String eventName,
      required Status status}) {
    Map<String, int> resourceUsage = {};
    for (Resource resource in sim._resources.values) {
      resourceUsage[resource.id] = resource.queue.length;
    }
    return SimulationTrack(
        status: status,
        name: eventName,
        time: sim.now,
        resourceUsage: resourceUsage);
  }
}
