import 'dart:async';

import 'package:meta/meta.dart';
import 'package:simdart/src/event.dart';
import 'package:simdart/src/event_phase.dart';
import 'package:simdart/src/internal/completer_action.dart';
import 'package:simdart/src/internal/time_action.dart';
import 'package:simdart/src/interval.dart';
import 'package:simdart/src/resources.dart';
import 'package:simdart/src/sim_context.dart';
import 'package:simdart/src/sim_counter.dart';
import 'package:simdart/src/sim_num.dart';
import 'package:simdart/src/simdart.dart';

@internal
class EventAction extends TimeAction implements SimContext {
  EventAction(
      {required this.sim,
      required super.start,
      required String? eventName,
      required this.event})
      : _eventName = eventName;

  /// The name of the event.
  final String? _eventName;

  @override
  String get eventName => _eventName ?? hashCode.toString();

  /// The event to be executed.
  final Event event;

  final SimDart sim;

  @override
  late final ResourcesContext resources = ResourcesFactory.context(sim, this);

  @override
  int get now => sim.now;

  /// Internal handler for resuming a waiting event.
  EventCompleter? _eventCompleter;
  EventCompleter? get eventCompleter => _eventCompleter;

  void buildCompleter() {
    _eventCompleter = EventCompleter(event: this);
  }

  @override
  void execute() {
    if (_eventCompleter != null) {
      throw StateError('This event is yielding');
    }

    sim.observer?.onEvent(
        name: eventName,
        time: sim.now,
        phase: EventPhase.called,
        executionHash: hashCode);

    _runEvent().then((_) {
      if (_eventCompleter != null) {
        SimDartHelper.error(
            sim: sim,
            msg:
                "Next event is being scheduled, but the current one is still paused waiting for continuation. Did you forget to use 'await'?");
        return;
      }
      sim.observer?.onEvent(
          name: eventName,
          time: sim.now,
          phase: EventPhase.finished,
          executionHash: hashCode);

      SimDartHelper.scheduleNextAction(sim: sim);
    }).catchError((e) {
      // Sim already marked to finish. Let the last event finalize.
    });
  }

  Future<void> _runEvent() async {
    await event(this);
  }

  @override
  Future<void> wait(int delay) async {
    if (_eventCompleter != null) {
      SimDartHelper.error(
          sim: sim,
          msg: "The event is already waiting. Did you forget to use 'await'?");
      return;
    }

    sim.observer?.onEvent(
        name: eventName,
        time: sim.now,
        phase: EventPhase.yielded,
        executionHash: hashCode);

    _eventCompleter = EventCompleter(event: this);

    // Schedule a complete to resume this event in the future.
    SimDartHelper.addAction(
        sim: sim,
        action: CompleterAction(
            start: sim.now + delay,
            complete: _eventCompleter!.complete,
            order: order));
    SimDartHelper.scheduleNextAction(sim: sim);

    await _eventCompleter!.future;
  }

  @override
  void process({required Event event, String? name, int? start, int? delay}) {
    sim.process(event: event, name: name, start: start, delay: delay);
  }

  @override
  void repeatProcess(
      {required Event event,
      int? start,
      int? delay,
      required Interval interval,
      StopCondition? stopCondition,
      String Function(int start)? name}) {
    sim.repeatProcess(
        event: event,
        start: start,
        delay: delay,
        interval: interval,
        stopCondition: stopCondition,
        name: name);
  }

  @override
  SimCounter counter(String name) {
    return sim.counter(name);
  }

  @override
  SimNum num(String name) {
    return sim.num(name);
  }

  @override
  void dispose() {
    _eventCompleter?.complete();
  }
}

class EventCompleter {
  EventCompleter({required this.event});

  final Completer<void> _completer = Completer();

  final EventAction event;

  Future<void> get future => _completer.future;

  void complete() {
    event.sim.observer?.onEvent(
        name: event.eventName,
        time: event.sim.now,
        phase: EventPhase.resumed,
        executionHash: hashCode);
    _completer.complete();
    event._eventCompleter = null;
  }
}
