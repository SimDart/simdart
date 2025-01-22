import 'dart:async';

import 'package:collection/collection.dart';
import 'package:meta/meta.dart';
import 'package:simdart/src/execution_priority.dart';
import 'package:simdart/src/internal/time_action.dart';
import 'package:simdart/src/internal/time_loop_mixin.dart';
import 'package:simdart/src/start_time_handling.dart';

/// Represents the temporal loop in the algorithm, managing the execution of actions at specified times.
@internal
class TimeLoop with TimeLoopMixin {
  TimeLoop(
      {required int? now,
      required this.beforeRun,
      required this.executionPriority,
      required this.startTimeHandling}) {
    _now = now ?? 0;
    _priorityScheduler = executionPriority == ExecutionPriority.high
        ? _highPrioritySchedule
        : _lowPrioritySchedule;
  }

  @override
  final StartTimeHandling startTimeHandling;

  @override
  final ExecutionPriority executionPriority;

  final Function beforeRun;

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

  @override
  int? get startTime => _startTime;
  int? _startTime;

  @override
  int? get duration => _duration;
  int? _duration;

  late final Function _priorityScheduler;

  bool _nextEventScheduled = false;

  late int? _until;

  @override
  int get now => _now;
  late int _now;

  Completer<void>? _terminator;

  /// Runs the simulation, processing actions in chronological order.
  Future<void> run({int? until}) async {
    if (until != null && _now > until) {
      throw ArgumentError('`now` must be less than or equal to `until`.');
    }
    _until = until;

    if (_terminator != null) {
      return;
    }
    if (_actions.isEmpty) {
      _duration = 0;
      _startTime = 0;
      return;
    }
    _duration = null;
    _startTime = null;

    beforeRun();

    _terminator = Completer<void>();
    _scheduleNextEvent();
    await _terminator?.future;
    _duration = _now - (startTime ?? 0);
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

  void addAction(TimeAction action) {
    _actions.add(action);
  }

  Future<void> _consumeFirstEvent() async {
    _nextEventScheduled = false;
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

    _scheduleNextEvent();
  }
}
