import 'dart:async';
import 'dart:math';

import 'package:collection/collection.dart';
import 'package:meta/meta.dart';
import 'package:simdart/src/event.dart';
import 'package:simdart/src/internal/completer_interrupt.dart';
import 'package:simdart/src/internal/debug_listener.dart';
import 'package:simdart/src/internal/event_action.dart';
import 'package:simdart/src/internal/repeat_event_action.dart';
import 'package:simdart/src/internal/simdart_interface.dart';
import 'package:simdart/src/internal/stop_action.dart';
import 'package:simdart/src/internal/time_action.dart';
import 'package:simdart/src/interval.dart';
import 'package:simdart/src/resources.dart';
import 'package:simdart/src/sim_counter.dart';
import 'package:simdart/src/sim_num.dart';
import 'package:simdart/src/sim_listener.dart';
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
      this.listener,
      this.executionPriority = 0,
      int? seed})
      : random = Random(seed),
        _now = now;

  RunState _runState = RunState.notStarted;
  RunState get runState => _runState;

   DebugListener? _debugListener;

  final SimListener? listener;

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

  final List<Completer<void>> _completerList = [];

  final Completer<void> _terminator = Completer();

  Object? _error;

  /// Runs the simulation, processing events in chronological order.
  ///
  /// - [until]: The time at which execution should stop. Execution will include events
  ///   scheduled at this time (inclusive). If null, execution will continue indefinitely.
  Future<SimResult> run({int? until}) async {

    if (runState != RunState.notStarted) {
      throw StateError('Simulation has already started.');
    }

    _runState = RunState.running;
    listener?.onStart();
    if (until != null && _now > until) {
      throw ArgumentError('`now` must be less than or equal to `until`.');
    }
    _until = until;

    _duration = 0;

    if (_actions.isEmpty) {
      _startTime = 0;
      _runState = RunState.finished;
    } else {
      _startTime = null;
      _scheduleNextAction();
      await _terminator.future;

      print('terminou');
      print('foi com erro? -> ${_error.runtimeType}: $_error');
      if (_error != null) {
        print('ue? erro?');
        _runState = RunState.error;
        throw _error!;
      } else {
        _runState = RunState.finished;
      }
      _duration = _now - (_startTime ?? 0);
    }
    return _buildResult();
  }

  void stop() {
    print("stop");
    _addAction(StopAction(start: now, sim:this));
    _scheduleNextAction();
  }

  void _disposeCompleteList() {
    while (_completerList.isNotEmpty) {
      Completer<void> completer = _completerList.removeAt(0);
      _debugListener?.onRemoveCompleter();
      if (!completer.isCompleted) {
        print('vai CompleterInterrupt');
        // prevents subsequent methods from being executed after complete inside the async method.
          completer.completeError(CompleterInterrupt());
      }
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
    if (!_nextActionScheduled) {
      print('_scheduleNextAction');
      _debugListener?.onScheduleNextAction();
      _nextActionScheduled = true;
      if (executionPriority == 0 || _executionCount < executionPriority) {
        _executionCount++;
        Future.microtask(_nextAction);
      } else {
        _executionCount = 0;
        Future.delayed(Duration.zero, _nextAction);
      }
    }
  }

  void _addAction(TimeAction action) {
    if (_runState==RunState.running || _runState==RunState.notStarted) {
      _actions.add(action);
    }
  }

  Future<void> _nextAction() async {
    print('_nextAction');
    _debugListener?.onNextAction();
    _nextActionScheduled = false;
    if (_actions.isEmpty || runState!=RunState.running) {
      _disposeCompleteList();
      if(!_terminator.isCompleted) {
        _terminator.complete();
      }
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

    _debugListener?.onExecuteAction();
    action.execute();
  }
}

enum RunState { notStarted, running, finished, stopped, error }

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

  static void scheduleNextAction({required SimDart sim}) {
    sim._scheduleNextAction();
  }

  static ResourceStore resourceStore({required SimDart sim}) =>
      sim._resourceStore;

  static void addCompleter(
      {required SimDart sim, required Completer<void> completer}) {
    sim._completerList.add(completer);
    sim._debugListener?.onAddCompleter();
  }

  static void removeCompleter(
      {required SimDart sim, required Completer<void> completer}) {
    sim._completerList.remove(completer);
    sim._debugListener?.onRemoveCompleter();
  }

  static void error({required SimDart sim, required StateError error}) {
    print('error');
    if(sim._error==null) {
      sim._error = error;
      sim._runState = RunState.error;
    }
  }
  
  static void setDebugListener({required SimDart sim, required DebugListener? listener}) {
    sim._debugListener=listener;
  }

  static void stop({required SimDart sim}) {
    print('stopando');
    sim._debugListener?.onStop();
    sim._runState = RunState.stopped;
  }
}
