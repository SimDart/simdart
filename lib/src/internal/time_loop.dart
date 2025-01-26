import 'dart:async';
import 'dart:math' as math;

import 'package:collection/collection.dart';
import 'package:meta/meta.dart';
import 'package:simdart/src/internal/now_interface.dart';
import 'package:simdart/src/internal/sim_result_interface.dart';
import 'package:simdart/src/internal/time_action.dart';
import 'package:simdart/src/internal/sim_configuration_interface.dart';
import 'package:simdart/src/sim_result.dart';
import 'package:simdart/src/simulation_track.dart';
import 'package:simdart/src/start_time_handling.dart';

/// Represents the temporal loop in the algorithm, managing the execution of actions at specified times.
@internal
class TimeLoop
    implements SimConfigurationInterface, NowInterface, SimResultInterface {
  TimeLoop(
      {required int? now,
      required this.beforeRun,
      required this.includeTracks,
      required int executionPriorityCounter,
      required this.startTimeHandling})
      : executionPriorityCounter = math.max(executionPriorityCounter, 0),
        _now = now ?? 0;

  @override
  final StartTimeHandling startTimeHandling;

  @override
  final int executionPriorityCounter;

  int _executionCount = 0;

  final Function beforeRun;

  @override
  final bool includeTracks;

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

  bool _nextEventScheduled = false;

  late int? _until;

  @override
  int get now => _now;
  late int _now;

  List<SimulationTrack>? _tracks;

  Completer<void>? _terminator;

  /// Runs the simulation, processing actions in chronological order.
  Future<SimResult> run({int? until}) async {
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
    _duration = null;
    _startTime = null;

    beforeRun();

    _terminator = Completer<void>();
    _scheduleNextEvent();
    await _terminator?.future;
    _duration = _now - (startTime ?? 0);
    _terminator = null;
    return _buildResult();
  }

  SimResult _buildResult() {
    return SimResult(startTime: startTime, duration: duration, tracks: _tracks);
  }

  void _scheduleNextEvent() {
    assert(!_nextEventScheduled, 'Multiple schedules for the next event.');
    _nextEventScheduled = true;
    if (executionPriorityCounter == 0 ||
        _executionCount < executionPriorityCounter) {
      _executionCount++;
      Future.microtask(_consumeFirstEvent);
    } else {
      _executionCount = 0;
      Future.delayed(Duration.zero, _consumeFirstEvent);
    }
  }

  void addAction(TimeAction action) {
    _actions.add(action);
  }

  void addTrack(SimulationTrack track) {
    _tracks ??= [];
    _tracks!.add(track);
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
