import 'dart:async';
import 'dart:collection';
import 'dart:math';

import 'package:collection/collection.dart';
import 'package:meta/meta.dart';
import 'package:simdart/src/event.dart';
import 'package:simdart/src/event_scheduler.dart';
import 'package:simdart/src/execution_priority.dart';
import 'package:simdart/src/resource.dart';
import 'package:simdart/src/simulation_track.dart';
import 'package:simdart/src/start_time_handling.dart';

/// Represents a discrete-event simulation engine.
class SimDart {
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
      {this.startTimeHandling = StartTimeHandling.throwErrorIfPast,
      OnTrack? onTrack,
      this.secondarySortByName = false,
      this.executionPriority = ExecutionPriority.high,
      int? now,
      int? seed})
      : _onTrack = onTrack,
        _now = now ?? 0,
        random = Random(seed) {
    _priorityScheduler = executionPriority == ExecutionPriority.high
        ? _highPrioritySchedule
        : _lowPrioritySchedule;
    _events = PriorityQueue<EventContext>(
      (a, b) {
        final primaryComparison = a.start.compareTo(b.start);
        if (primaryComparison != 0) {
          return primaryComparison;
        }
        if (secondarySortByName) {
          return a.eventName.compareTo(b.eventName);
        }
        return 0;
      },
    );
  }

  /// Determines whether events with the same start time are sorted by their event name.
  ///
  /// The primary sorting criterion is always the simulated start time (`start`). If
  /// two events have the same start time, the order between them will be decided by
  /// their event name when [secondarySortByName] is set to true. If false, the order
  /// remains undefined for events with identical start times.
  final bool secondarySortByName;

  /// Specifies how the simulation handles start times in the past.
  final StartTimeHandling startTimeHandling;

  /// Defines the priority of task execution in the simulation.
  ///
  /// - `highPriority`: Uses `Future.microtask` for immediate execution, prioritizing
  ///   processing without blocking the UI.
  /// - `lowPriority`: Uses `Future.delayed(Duration.zero)` to ensure non-blocking
  ///   execution, allowing the UI to remain responsive.
  final ExecutionPriority executionPriority;

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

  /// Internal list of scheduled events.
  late final PriorityQueue<EventContext> _events;

  /// The current time in the simulation.
  int _now;

  /// Gets the current simulation time.
  int get now => _now;

  /// A callback function used to track the progress of the simulation.
  /// If provided, this function will be called with each [SimulationTrack] generated
  /// during the simulation. This is useful for debugging or logging purposes.
  final OnTrack? _onTrack;

  /// The time, in simulated time units, when the simulation started.
  /// This is the moment at which the first event is scheduled to be processed.
  ///
  /// For example, if the first process is scheduled to occur at time 10,
  /// then the simulation start time would be 10. This value helps track when
  /// the simulation officially begins its execution in terms of the simulation time.
  int? _startTime;
  int? get startTime => _startTime;

  /// The duration, in simulated time units, that the simulation took to execute.
  ///
  /// This value represents the total time elapsed during the processing of the simulation,
  /// from the start to the completion of all event handling, in terms of the simulated environment.
  /// It is used to track how much time has passed in the simulation model, not real-world time.
  ///
  /// The value will be `null` if the duration has not been calculated or set.
  int? _duration;
  int? get duration => _duration;

  /// A queue that holds events that are waiting for a resource to become available.
  ///
  /// These events were initially denied the resource and are placed in this queue
  /// to await the opportunity to be processed once the resource is released.
  final Queue<EventContext> _waitingForResource = Queue();

  late final Function _priorityScheduler;

  Completer<void>? _terminator;

  bool _nextEventScheduled = false;

  /// Runs the simulation, processing events in chronological order.
  Future<void> run() async {
    if (_terminator != null) {
      return;
    }
    if (_events.isEmpty) {
      _duration = 0;
      _startTime = 0;
      return;
    }
    _duration = null;
    _startTime = null;

    for (ResourceConfiguration rc
        in ResourcesConfiguratorHelper.iterable(configurator: resources)) {
      if (rc is LimitedResourceConfiguration) {
        _resources[rc.id] = LimitedResource(id: rc.id, capacity: rc.capacity);
      }
    }

    _terminator = Completer<void>();
    _scheduleNextEvent();
    await _terminator?.future;
    _duration = now - (startTime ?? 0);
    _terminator = null;
  }

  void _scheduleNextEvent() {
    assert(!_nextEventScheduled, 'Multiple schedules for the next event.');
    _nextEventScheduled = true;
    _priorityScheduler.call();
  }

  void _highPrioritySchedule() {
    Future.microtask(_consumeFirstEvent);
  }

  void _lowPrioritySchedule() {
    Future.delayed(Duration.zero, _consumeFirstEvent);
  }

  Future<void> _consumeFirstEvent() async {
    _nextEventScheduled = false;
    if (_events.isEmpty) {
      _terminator?.complete();
      return;
    }

    // Get the next event to process.
    EventContext event = _events.removeFirst();

    // Advance the simulation time to the event's start time.
    if (event.start > now) {
      _now = event.start;
    } else if (event.start < now) {
      EventContextHelper.setStart(event: event, start: now);
    }

    _startTime ??= now;

    Function? resume = EventContextHelper.getResume(event: event);
    if (resume != null) {
      if (_onTrack != null) {
        _onTrack(_buildSimulationTrack(event: event, status: Status.resumed));
      }
      // Resume the event if it is waiting, otherwise execute its action.
      resume.call();
      _scheduleNextEvent();
      return;
    }

    Resource? resource = _resources[event.resource?.id];
    bool canRun = true;
    if (resource != null) {
      canRun = resource.acquire(event);
    }

    if (_onTrack != null) {
      Status status = Status.executed;
      if (!canRun) {
        status = Status.rejected;
      } else if (event.type == EventType.scheduler) {
        status = Status.scheduled;
      }
      _onTrack(_buildSimulationTrack(event: event, status: status));
    }

    if (canRun) {
      EventContextHelper.executeEvent(event: event).then((_) {
        if (resource != null && event.resource!.acquired) {
          resource.release(event);
        }
        if (event.resource != null) {
          // Event was holding some resource, now maybe another event can be executed.
          while (_waitingForResource.isNotEmpty) {
            _events.add(_waitingForResource.removeFirst());
          }
        }
      });
    } else {
      _waitingForResource.add(event);
    }

    _scheduleNextEvent();
  }

  SimulationTrack _buildSimulationTrack(
      {required EventContext event, required Status status}) {
    Map<String, int> resourceUsage = {};
    for (Resource resource in _resources.values) {
      resourceUsage[resource.id] = resource.queue.length;
    }
    return SimulationTrack(
        status: status,
        name: event.eventName,
        time: now,
        resourceUsage: resourceUsage);
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
  void process(Event event,
      {String? resourceId, String? name, int? start, int? delay}) {
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

    _processAtWithType(
        event: event,
        start: start,
        name: name,
        resourceId: resourceId,
        type: EventType.regular);
  }

  /// Internal implementation of [processAt].
  void _processAtWithType(
      {required Event event,
      required int start,
      required String? name,
      required String? resourceId,
      required EventType type}) {
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
    _events.add(EventContextHelper.build(
        sim: this,
        name: name,
        start: start,
        event: event,
        resourceId: resourceId,
        type: type));
  }

  /// Adds a new [EventScheduler] to the simulation.
  ///
  /// The [EventScheduler] will generate events at specific intervals, as defined
  /// by its configuration (e.g., the [interval] and [event]). The generator's behavior
  /// will dictate how and when the events are triggered during the simulation.
  ///
  /// This method ensures that the event generation follows the defined schedule,
  /// and the events are processed at the appropriate times in the simulation's event queue.
  void addEventScheduler(EventScheduler scheduler) {
    _processAtWithType(
        event: EventSchedulerHelper.eventFrom(scheduler: scheduler),
        start: scheduler.next,
        name: scheduler.name,
        resourceId: null,
        type: EventType.scheduler);
  }
}

/// A function signature for tracking the progress of a simulation.
typedef OnTrack = void Function(SimulationTrack track);

/// A helper class to access private members of the [SimDart] class.
///
/// This class is marked as internal and should only be used within the library.
@internal
class SimDartHelper {
  /// Adds an [EventContext] to the private event list of the [SimDart] instance.
  static void addEvent({required SimDart sim, required EventContext event}) {
    sim._events.add(event);
  }

  /// Access point to the internal [SimDart._processAtWithType] method.
  static void processAtWithType(
      {required SimDart sim,
      required Event event,
      required int start,
      required String? name,
      required String? resourceId,
      required EventType type}) {
    sim._processAtWithType(
        event: event,
        start: start,
        name: name,
        resourceId: resourceId,
        type: type);
  }
}
