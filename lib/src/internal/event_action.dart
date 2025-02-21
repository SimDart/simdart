import 'dart:async';

import 'package:meta/meta.dart';
import 'package:simdart/src/event.dart';
import 'package:simdart/src/internal/completer_action.dart';
import 'package:simdart/src/internal/resource.dart';
import 'package:simdart/src/internal/resources_context_impl.dart';
import 'package:simdart/src/internal/time_action.dart';
import 'package:simdart/src/interval.dart';
import 'package:simdart/src/resources_context.dart';
import 'package:simdart/src/sim_context.dart';
import 'package:simdart/src/sim_counter.dart';
import 'package:simdart/src/sim_num.dart';
import 'package:simdart/src/simdart.dart';
import 'package:simdart/src/simulation_track.dart';

@internal
class EventAction extends TimeAction implements SimContext {
  EventAction(
      {required this.sim,
      required super.start,
      required String? eventName,
      required this.event,
      required this.secondarySortByName})
      : _eventName = eventName;

  /// The name of the event.
  final String? _eventName;

  @override
  String get eventName => _eventName ?? hashCode.toString();

  /// The event to be executed.
  final Event event;

  final SimDart sim;

  final bool secondarySortByName;

  @override
  late final ResourcesContext resources = ResourcesContextImpl(sim, this);

  @override
  int get now => sim.now;

  /// Internal handler for resuming a waiting event.
  EventCompleter? _eventCompleter;

  @override
  int secondaryCompareTo(TimeAction action) {
    if (secondarySortByName && action is EventAction) {
      return eventName.compareTo(action.eventName);
    }
    return 0;
  }

  @override
  void execute(void Function() onFinish) {
    if (_eventCompleter != null) {
      throw StateError('This event is yielding');
    }

    if (sim.includeTracks) {
      SimDartHelper.addSimulationTrack(
          sim: sim, eventName: eventName, status: Status.called);
    }

    _runEvent().then((_) => onFinish.call());
  }

  @override
  Future<void> wait(int delay) async {
    if (_eventCompleter != null) {
      throw StateError(
        "The event is already waiting. Did you forget to use 'await'?",
      );
    }

    if (sim.includeTracks) {
      SimDartHelper.addSimulationTrack(
          sim: sim, eventName: eventName, status: Status.yielded);
    }
    _eventCompleter = EventCompleter(event: this);

    // Schedule a complete to resume this event in the future.
    SimDartHelper.addAction(
        sim: sim,
        action: CompleterAction(
            start: sim.now + delay, complete: _eventCompleter!.complete));

    await _eventCompleter!.future;
  }

  Future<void> acquireResource(String id) async {
    if (_eventCompleter != null) {
      throw StateError(
        "The event is already acquiring a resource. Did you forget to use 'await'?",
      );
    }
    Resource? resource = SimDartHelper.getResource(sim: sim, resourceId: id);
    if (resource != null) {
      bool acquired = resource.acquire(this);
      if (!acquired) {
        if (sim.includeTracks) {
          SimDartHelper.addSimulationTrack(
              sim: sim, eventName: eventName, status: Status.yielded);
        }
        _eventCompleter = EventCompleter(event: this);
        resource.waiting.add(_eventCompleter!.complete);
        await _eventCompleter!.future;
        return await acquireResource(id);
      }
    }
  }

  void releaseResource(String id) {
    Resource? resource = SimDartHelper.getResource(sim: sim, resourceId: id);
    if (resource != null) {
      if (resource.release(sim, this)) {
        if (resource.waiting.isNotEmpty) {
          resource.waiting.removeAt(0).call();
        }
      }
    }
  }

  Future<void> _runEvent() async {
    return event(this);
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
}

class EventCompleter {
  EventCompleter({required this.event});

  final Completer<void> _completer = Completer();

  final EventAction event;

  Future<void> get future => _completer.future;

  void complete() {
    if (event.sim.includeTracks) {
      SimDartHelper.addSimulationTrack(
          sim: event.sim, eventName: event.eventName, status: Status.resumed);
    }
    _completer.complete();
    event._eventCompleter = null;
  }
}
