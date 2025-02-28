import 'dart:async';
import 'dart:math';

import 'package:collection/collection.dart';
import 'package:meta/meta.dart';
import 'package:simdart/src/event.dart';
import 'package:simdart/src/internal/event_action.dart';
import 'package:simdart/src/internal/repeat_event_action.dart';
import 'package:simdart/src/internal/simdart_interface.dart';
import 'package:simdart/src/internal/time_action.dart';
import 'package:simdart/src/interval.dart';
import 'package:simdart/src/resources.dart';
import 'package:simdart/src/sim_counter.dart';
import 'package:simdart/src/sim_num.dart';
import 'package:simdart/src/sim_observer.dart';
import 'package:simdart/src/sim_result.dart';
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
      this.observer,
      this.executionPriority = 0,
      int? seed})
      : random = Random(seed),
        _now = now;

  RunState _runState = RunState.notStarted;
  RunState get runState => _runState;

  final SimObserver? observer;

  final Map<String, SimNum> _numProperties = {};
  final Map<String, SimCounter> _counterProperties = {};

  final ResourceStore _resourceStore = ResourceStore();
  late final Resources resources = ResourcesFactory.sim(this);

  /// The instance of the random number generator used across the simulation.
  /// It is initialized once and reused to improve performance, avoiding the need to
  /// instantiate a new `Random` object for each event.
  late final Random random;

  /// Queue that holds the [TimeAction] instances to be executed at their respective times.
  final PriorityQueue<TimeAction> _actions = PriorityQueue<TimeAction>(
    (a, b) {
      final int c = a.start.compareTo(b.start);
      if (c != 0) {
        return c;
      }
      return a.order.compareTo(b.order);
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

  int? _startTime;

  int _duration = 0;

  bool _nextActionScheduled = false;

  late int? _until;

  @override
  int get now => _now;
  late int _now;

  final Completer<void> _terminator = Completer();

  bool _error = false;

  /// Runs the simulation, processing events in chronological order.
  ///
  /// - [until]: The time at which execution should stop. Execution will include events
  ///   scheduled at this time (inclusive). If null, execution will continue indefinitely.
  Future<SimResult> run({int? until}) async {
    if (runState != RunState.notStarted) {
      throw StateError('Simulation has already started.');
    }

    _runState = RunState.running;
    observer?.onStart();
    if (until != null && _now > until) {
      throw ArgumentError('`now` must be less than or equal to `until`.');
    }
    _until = until;

    _duration = 0;

    if (_actions.isEmpty) {
      _startTime = 0;
    } else {
      _startTime = null;
      _scheduleNextAction();
      await _terminator.future;
      _duration = _now - (_startTime ?? 0);
    }
    _runState = RunState.finished;
    return _buildResult();
  }

  void stop() {
    if (!_terminator.isCompleted) {
      _terminator.complete();
    }
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
    _addAction(
        EventAction(sim: this, start: start, eventName: name, event: event));
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
        numProperties: _numProperties,
        counterProperties: _counterProperties);
  }

  void _scheduleNextAction() {
    if (_error) {
      return;
    }
    if (!_nextActionScheduled) {
      _nextActionScheduled = true;
      if (executionPriority == 0 || _executionCount < executionPriority) {
        _executionCount++;
        Future.microtask(_consumeNextAction);
      } else {
        _executionCount = 0;
        Future.delayed(Duration.zero, _consumeNextAction);
      }
    }
  }

  void _addAction(TimeAction action) {
    if (_error) {
      return;
    }
    _actions.add(action);
  }

  Future<void> _consumeNextAction() async {
    if (_error || _terminator.isCompleted) {
      return;
    }

    _nextActionScheduled = false;
    if (_actions.isEmpty) {
      _terminator.complete();
      return;
    }

    TimeAction action = _actions.removeFirst();

    // Advance the simulation time to the action's start time.
    if (action.start > now) {
      _now = action.start;
      if (_until != null && now > _until!) {
        _startTime ??= now;
        _terminator.complete();
        return;
      }
    } else if (action.start < now) {
      action.start = now;
    }

    _startTime ??= now;

    action.execute();
  }
}

enum RunState { notStarted, running, finished }

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

  static ResourceStore resourceStore({required SimDart sim}) =>
      sim._resourceStore;

  static void scheduleNextAction({required SimDart sim}) {
    sim._scheduleNextAction();
  }

  static void error({required SimDart sim, required String msg}) {
    sim._error = true;
    while (sim._actions.isNotEmpty) {
      TimeAction action = sim._actions.removeFirst();
      action.dispose();
    }
    sim._terminator.completeError(StateError(msg));
  }
}
