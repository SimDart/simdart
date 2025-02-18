import 'dart:async';
import 'dart:math';

import 'package:collection/collection.dart';
import 'package:meta/meta.dart';
import 'package:simdart/src/event.dart';
import 'package:simdart/src/internal/event_action.dart';
import 'package:simdart/src/internal/repeat_event_action.dart';
import 'package:simdart/src/internal/resource.dart';
import 'package:simdart/src/internal/resources_impl.dart';
import 'package:simdart/src/internal/simdart_interface.dart';
import 'package:simdart/src/internal/time_action.dart';
import 'package:simdart/src/interval.dart';
import 'package:simdart/src/resources.dart';
import 'package:simdart/src/sim_counter.dart';
import 'package:simdart/src/sim_num.dart';
import 'package:simdart/src/sim_result.dart';
import 'package:simdart/src/simulation_track.dart';
import 'package:simdart/src/start_time_handling.dart';

/// Represents a discrete-event simulation engine.
class SimDart implements SimDartInterface {
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
      {this.startTimeHandling = StartTimeHandling.throwErrorIfPast,
      int now = 0,
      this.secondarySortByName = false,
      this.includeTracks = false,
      this.executionPriority = 0,
      int? seed})
      : random = Random(seed),
        _now = now;

  bool _hasRun = false;

  /// Determines whether events with the same start time are sorted by their event name.
  ///
  /// The primary sorting criterion is always the simulated start time (`start`). If
  /// two events have the same start time, the order between them will be decided by
  /// their event name when [secondarySortByName] is set to true. If false, the order
  /// remains undefined for events with identical start times.
  final bool secondarySortByName;

  final Map<String, SimNum> _numProperties = {};
  final Map<String, SimCounter> _counterProperties = {};

  /// Holds the resources in the simulator.
  final Map<String, Resource> _resources = {};

  late final Resources resources = ResourcesImpl(this);

  /// The instance of the random number generator used across the simulation.
  /// It is initialized once and reused to improve performance, avoiding the need to
  /// instantiate a new `Random` object for each event.
  late final Random random;

  /// Queue that holds the [TimeAction] instances to be executed at their respective times.
  final PriorityQueue<TimeAction> _actions = PriorityQueue<TimeAction>(
    (a, b) {
      final primaryComparison = a.start.compareTo(b.start);
      if (primaryComparison != 0) {
        return primaryComparison;
      }
      return a.secondaryCompareTo(b);
    },
  );

  /// Specifies how the simulation handles start times in the past.
  final StartTimeHandling startTimeHandling;

  /// Determines how often `Future.delayed` is used instead of `Future.microtask` during events execution.
  ///
  /// - `0`: Always uses `microtask`.
  /// - `1`: Alternates between `microtask` and `Future.delayed`.
  /// - `N > 1`: Executes `N` events with `microtask` before using `Future.delayed`.
  final int executionPriority;

  int _executionCount = 0;

  /// Determines whether simulation tracks should be included in the simulation result.
  ///
  /// When set to `true`, the simulation will collect and return a list of [SimulationTrack]
  /// objects as part of its result. If set to `false`, the tracks will not be collected,
  /// and the list will be `null`.
  ///
  /// Default: `false`
  final bool includeTracks;

  int? _startTime;

  int _duration = 0;

  bool _nextActionScheduled = false;

  late int? _until;

  @override
  int get now => _now;
  late int _now;

  List<SimulationTrack>? _tracks;

  Completer<void>? _terminator;

  /// Runs the simulation, processing events in chronological order.
  ///
  /// - [until]: The time at which execution should stop. Execution will include events
  ///   scheduled at this time (inclusive). If null, execution will continue indefinitely.
  Future<SimResult> run({int? until}) async {
    if (_hasRun) {
      throw StateError('The simulation has already been run.');
    }

    _hasRun = true;
    if (until != null && _now > until) {
      throw ArgumentError('`now` must be less than or equal to `until`.');
    }
    _until = until;

    if (_terminator != null) {
      return _buildResult();
    }
    if (_actions.isEmpty) {
      _duration = 0;
      _startTime = 0;
      return _buildResult();
    }
    _duration = 0;
    _startTime = null;

    _terminator = Completer<void>();
    _scheduleNextAction();
    await _terminator?.future;
    _duration = _now - (_startTime ?? 0);
    _terminator = null;
    return _buildResult();
  }

  @override
  SimCounter counter(String name) {
    return _counterProperties.putIfAbsent(name, () => SimCounter(name: name));
  }

  @override
  SimNum num(String name) {
    return _numProperties.putIfAbsent(name, () => SimNum(name: name));
  }

  @override
  void repeatProcess(
      {required Event event,
      int? start,
      int? delay,
      required Interval interval,
      StopCondition? stopCondition,
      String Function(int start)? name}) {
    start = _calculateEventStart(start: start, delay: delay);
    _addAction(RepeatEventAction(
        sim: this,
        start: start,
        eventName: name,
        event: event,
        interval: interval,
        stopCondition: stopCondition));
  }

  @override
  void process({required Event event, String? name, int? start, int? delay}) {
    start = _calculateEventStart(start: start, delay: delay);
    _addAction(EventAction(
        sim: this,
        start: start,
        eventName: name,
        event: event,
        secondarySortByName: secondarySortByName));
  }

  int _calculateEventStart({required int? start, required int? delay}) {
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

    return start;
  }

  SimResult _buildResult() {
    return SimResult(
        startTime: _startTime ?? 0,
        duration: _duration,
        tracks: _tracks,
        numProperties: _numProperties,
        counterProperties: _counterProperties);
  }

  void _scheduleNextAction() {
    assert(!_nextActionScheduled, 'Multiple schedules for the next action.');
    _nextActionScheduled = true;
    if (executionPriority == 0 || _executionCount < executionPriority) {
      _executionCount++;
      Future.microtask(_consumeNextAction);
    } else {
      _executionCount = 0;
      Future.delayed(Duration.zero, _consumeNextAction);
    }
  }

  void _addAction(TimeAction action) {
    _actions.add(action);
  }

  void _addTrack({required String eventName, required Status status}) {
    Map<String, int> resourceUsage = {};
    for (Resource resource in _resources.values) {
      resourceUsage[resource.id] = resource.queue.length;
    }
    _tracks ??= [];
    _tracks!.add(SimulationTrack(
        status: status,
        name: eventName,
        time: now,
        resourceUsage: resourceUsage));
  }

  Future<void> _consumeNextAction() async {
    _nextActionScheduled = false;
    if (_actions.isEmpty) {
      _terminator?.complete();
      return;
    }

    TimeAction action = _actions.removeFirst();

    // Advance the simulation time to the action's start time.
    if (action.start > now) {
      _now = action.start;
      if (_until != null && now > _until!) {
        _startTime ??= now;
        _terminator?.complete();
        return;
      }
    } else if (action.start < now) {
      action.start = now;
    }

    _startTime ??= now;

    action.execute();

    _scheduleNextAction();
  }
}

typedef StopCondition = bool Function(SimDart sim);

/// A helper class to access private members of the [SimDart] class.
///
/// This class is marked as internal and should only be used within the library.
@internal
class SimDartHelper {
  /// Adds an [TimeAction] to the loop.
  static void addAction({required SimDart sim, required TimeAction action}) {
    sim._addAction(action);
  }

  static Resource? getResource(
      {required SimDart sim, required String? resourceId}) {
    return sim._resources[resourceId];
  }

  static void addResource(
      {required SimDart sim,
      required String resourceId,
      required Resource Function() create}) {
    sim._resources.putIfAbsent(resourceId, create);
  }

  static void addSimulationTrack(
      {required SimDart sim,
      required String eventName,
      required Status status}) {
    sim._addTrack(eventName: eventName, status: status);
  }
}
