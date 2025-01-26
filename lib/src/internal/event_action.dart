import 'dart:async';
import 'dart:math';

import 'package:meta/meta.dart';
import 'package:simdart/src/event.dart';
import 'package:simdart/src/internal/resource.dart';
import 'package:simdart/src/internal/time_action.dart';
import 'package:simdart/src/interval.dart';
import 'package:simdart/src/simdart.dart';
import 'package:simdart/src/simulation_track.dart';

@internal
class EventAction extends TimeAction implements EventContext {
  EventAction(
      {required SimDart sim,
      required super.start,
      required String? eventName,
      required this.event,
      required this.resourceId,
      required this.onReject,
      required this.secondarySortByName})
      : _sim = sim,
        _eventName = eventName;

  /// The name of the event.
  final String? _eventName;
  String get eventName => _eventName ?? hashCode.toString();

  /// The event to be executed.
  final Event event;

  final Function? onReject;

  final SimDart _sim;

  @override
  Random get random => _sim.random;

  /// The resource id required by the event.
  final String? resourceId;

  bool _resourceAcquired = false;

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

  bool get _canRun => resourceId == null || _resourceAcquired;

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

    Resource? resource =
        SimDartHelper.getResource(sim: _sim, resourceId: resourceId);
    if (resource != null) {
      _resourceAcquired = resource.acquire(this);
    }

    if (_sim.includeTracks) {
      Status status = Status.executed;
      if (!_canRun) {
        status = Status.rejected;
      }
      SimDartHelper.addSimulationTrack(
          sim: _sim, eventName: eventName, status: status);
    }

    if (_canRun) {
      _runEvent().then((_) {
        if (_resourceAcquired) {
          if (resource != null) {
            resource.release(this);
            _resourceAcquired = false;
          }
          // Event released some resource, others events need retry.
          SimDartHelper.restoreWaitingEventsForResource(sim: _sim);
        }
      });
    } else {
      onReject?.call();
      SimDartHelper.queueOnWaitingForResource(sim: _sim, action: this);
    }
  }

  @override
  Future<void> wait(int delay) async {
    if (_resume != null) {
      return;
    }

    start = _sim.now + delay;
    // Adds it back to the loop to be resumed in the future.
    SimDartHelper.addAction(sim: _sim, action: this);

    final Completer<void> resume = Completer<void>();
    _resume = () {
      resume.complete();
      _resume = null;
    };
    await resume.future;
  }

  Future<void> _runEvent() async {
    return event(this);
  }

  @override
  int get now => _sim.now;

  @override
  void process(
      {required Event event,
      String? resourceId,
      String? name,
      int? start,
      int? delay}) {
    _sim.process(
        event: event,
        resourceId: resourceId,
        name: name,
        start: start,
        delay: delay);
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
    _sim.repeatProcess(
        event: event,
        interval: interval,
        start: start,
        delay: delay,
        rejectedEventPolicy: rejectedEventPolicy,
        resourceId: resourceId,
        name: name);
  }
}
