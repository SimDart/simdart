import 'dart:async';
import 'dart:collection';
import 'dart:math';

import 'package:meta/meta.dart';
import 'package:simdart/src/event.dart';
import 'package:simdart/src/execution_priority.dart';
import 'package:simdart/src/internal/event_action.dart';
import 'package:simdart/src/internal/event_scheduler_interface.dart';
import 'package:simdart/src/internal/now_interface.dart';
import 'package:simdart/src/internal/repeat_event_action.dart';
import 'package:simdart/src/internal/resource.dart';
import 'package:simdart/src/internal/time_action.dart';
import 'package:simdart/src/internal/time_loop.dart';
import 'package:simdart/src/internal/sim_configuration_interface.dart';
import 'package:simdart/src/interval.dart';
import 'package:simdart/src/resource_configurator.dart';
import 'package:simdart/src/sim_result.dart';
import 'package:simdart/src/simulation_track.dart';
import 'package:simdart/src/start_time_handling.dart';

/// Represents a discrete-event simulation engine.
class SimDart
    implements
        SimConfigurationInterface,
        EventSchedulerInterface,
        NowInterface {
  /// Creates a simulation instance.
  ///
  /// - [now]: The starting time of the simulation. Defaults to `0` if null.
  /// If provided, it must be less than or equal to [until].
  ///
  /// - [startTimeHandling]: Determines how to handle events scheduled with a start
  /// time in the past. The default behavior is [StartTimeHandling.throwErrorIfPast].
  ///
  /// - [includeTracks]: Determines whether simulation tracks should be included in the simulation result.
  ///
  /// - [seed]: The optional parameter used to initialize the random number generator
  /// for deterministic behavior in the simulation. If provided, it ensures that the
  /// random sequence is reproducible for the same seed value.
  ///
  /// - [secondarySortByName]: If true, events with the same start time are sorted
  /// by their event name. Defaults to false.
  ///
  /// - [executionPriority]: Defines the priority of task execution in the simulation.
  SimDart(
      {StartTimeHandling startTimeHandling = StartTimeHandling.throwErrorIfPast,
      int? now,
      this.secondarySortByName = false,
      this.includeTracks = false,
      ExecutionPriority executionPriority = ExecutionPriority.high,
      int? seed})
      : random = Random(seed) {
    _loop = TimeLoop(
        now: now,
        includeTracks: includeTracks,
        beforeRun: _beforeRun,
        executionPriority: executionPriority,
        startTimeHandling: startTimeHandling);
  }

  late final TimeLoop _loop;

  @override
  final bool includeTracks;

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
  ///
  /// - [until]: The time at which execution should stop. Execution will include events
  ///   scheduled at this time (inclusive). If null, execution will continue indefinitely.
  Future<SimResult> run({int? until}) async {
    return _loop.run(until: until);
  }

  @override
  void repeatProcess(
      {required Event event,
      int? start,
      int? delay,
      required Interval interval,
      RejectedEventPolicy rejectedEventPolicy =
          RejectedEventPolicy.keepRepeating,
      String? resourceId,
      String? name}) {
    _process(
        event: event,
        start: start,
        delay: delay,
        name: name,
        resourceId: resourceId,
        onReject: null,
        interval: interval,
        rejectedEventPolicy: rejectedEventPolicy);
  }

  @override
  void process(
      {required Event event,
      String? resourceId,
      String? name,
      int? start,
      int? delay}) {
    _process(
        event: event,
        start: start,
        delay: delay,
        name: name,
        resourceId: resourceId,
        onReject: null,
        interval: null,
        rejectedEventPolicy: null);
  }

  void _process(
      {required Event event,
      required int? start,
      required int? delay,
      required String? name,
      required String? resourceId,
      required Function? onReject,
      required Interval? interval,
      required RejectedEventPolicy? rejectedEventPolicy}) {
    if (start != null && delay != null) {
      throw ArgumentError(
          'Both start and delay cannot be provided at the same time.');
    }

    if (start != null) {
      if (start < now) {
        if (startTimeHandling == StartTimeHandling.throwErrorIfPast) {
          throw ArgumentError('Event start time cannot be in the past');
        } else if (startTimeHandling == StartTimeHandling.useNowIfPast) {
          // Uses the current time if the start time is in the past
          start = now;
        }
      }
    }

    if (delay != null) {
      if (delay < 0) {
        throw ArgumentError('Delay cannot be negative.');
      }
      start = now + delay;
    }

    start ??= now;

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
          start: start,
          eventName: name,
          event: event,
          resourceId: resourceId,
          onReject: onReject,
          secondarySortByName: secondarySortByName));
    }
  }

  @override
  ExecutionPriority get executionPriority => _loop.executionPriority;

  @override
  int get now => _loop.now;

  @override
  StartTimeHandling get startTimeHandling => _loop.startTimeHandling;
}

/// Defines the behavior of the interval after a newly created event has been rejected.
enum RejectedEventPolicy {
  /// Continues the repetition of the event at the specified intervals, even after the event was rejected.
  keepRepeating,

  /// Stops the repetition of the event entirely after it has been rejected.
  stopRepeating
}

/// A helper class to access private members of the [SimDart] class.
///
/// This class is marked as internal and should only be used within the library.
@internal
class SimDartHelper {
  static void process(
      {required SimDart sim,
      required Event event,
      required int? start,
      required int? delay,
      required String? name,
      required String? resourceId,
      required Function? onReject,
      required Interval? interval,
      required RejectedEventPolicy? rejectedEventPolicy}) {
    sim._process(
        event: event,
        start: start,
        delay: delay,
        name: name,
        resourceId: resourceId,
        onReject: onReject,
        interval: interval,
        rejectedEventPolicy: rejectedEventPolicy);
  }

  /// Adds an [TimeAction] to the loop.
  static void addAction({required SimDart sim, required TimeAction action}) {
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

  static void addSimulationTrack(
      {required SimDart sim,
      required String eventName,
      required Status status}) {
    Map<String, int> resourceUsage = {};
    for (Resource resource in sim._resources.values) {
      resourceUsage[resource.id] = resource.queue.length;
    }
    sim._loop.addTrack(SimulationTrack(
        status: status,
        name: eventName,
        time: sim.now,
        resourceUsage: resourceUsage));
  }
}
