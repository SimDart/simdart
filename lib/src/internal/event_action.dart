import 'dart:async';

import 'package:meta/meta.dart';
import 'package:simdart/src/event.dart';
import 'package:simdart/src/internal/resource.dart';
import 'package:simdart/src/internal/time_action.dart';
import 'package:simdart/src/sim_context.dart';
import 'package:simdart/src/simdart.dart';
import 'package:simdart/src/simulation_track.dart';

@internal
class EventAction extends TimeAction {
  EventAction(
      {required SimDart sim,
      required super.start,
      required String? eventName,
      required this.event,
      required this.secondarySortByName})
      : _sim = sim,
        _eventName = eventName;

  /// The name of the event.
  final String? _eventName;

  String get eventName => _eventName ?? hashCode.toString();

  /// The event to be executed.
  final Event event;

  final SimDart _sim;

  final bool secondarySortByName;

  /// Internal handler for resuming a waiting event.
  void Function()? _resume;

  @override
  int secondaryCompareTo(TimeAction action) {
    if (secondarySortByName && action is EventAction) {
      return eventName.compareTo(action.eventName);
    }
    return 0;
  }

  @override
  void execute() {
    final Function()? resume = _resume;

    if (resume != null) {
      if (_sim.includeTracks) {
        SimDartHelper.addSimulationTrack(
            sim: _sim, eventName: eventName, status: Status.resumed);
      }
      // Resume the event if it is waiting, otherwise execute its action.
      resume.call();
      return;
    }

    if (_sim.includeTracks) {
      SimDartHelper.addSimulationTrack(
          sim: _sim, eventName: eventName, status: Status.called);
    }

    _runEvent();
  }

  @override
  Future<void> wait(int delay) async {
    if (_resume != null) {
      throw StateError(
        "The event is already waiting. Did you forget to use 'await'?",
      );
    }

    start = _sim.now + delay;
    // Adds it back to the loop to be resumed in the future.
    SimDartHelper.addAction(sim: _sim, action: this);

    if (_sim.includeTracks) {
      SimDartHelper.addSimulationTrack(
          sim: _sim, eventName: eventName, status: Status.yielded);
    }
    final Completer<void> resume = Completer<void>();
    _resume = () {
      resume.complete();
      _resume = null;
    };
    await resume.future;
  }

  @override
  Future<void> acquireResource(String id) async {
    if (_resume != null) {
      throw StateError(
        "The event is already acquiring a resource. Did you forget to use 'await'?",
      );
    }
    Resource? resource = SimDartHelper.getResource(sim: _sim, resourceId: id);
    if (resource != null) {
      bool acquired = resource.acquire(this);
      if (!acquired) {
        if (_sim.includeTracks) {
          SimDartHelper.addSimulationTrack(
              sim: _sim, eventName: eventName, status: Status.yielded);
        }
        resource.waiting.add(this);
        final Completer<void> resume = Completer<void>();
        _resume = () {
          resume.complete();
          _resume = null;
        };
        await resume.future;
      }
    }
  }

  @override
  void releaseResource(String id) {
    Resource? resource = SimDartHelper.getResource(sim: _sim, resourceId: id);
    if (resource != null) {
      if (resource.release(_sim, this)) {
        if (resource.waiting.isNotEmpty) {
          SimDartHelper.addAction(
              sim: _sim, action: resource.waiting.removeAt(0));
        }
      }
    }
  }

  Future<void> _runEvent() async {
    return event(SimContextHelper.build(sim: _sim, event: this));
  }
}
