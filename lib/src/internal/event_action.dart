import 'dart:async';

import 'package:meta/meta.dart';
import 'package:simdart/src/event.dart';
import 'package:simdart/src/internal/time_action.dart';
import 'package:simdart/src/internal/resource.dart';
import 'package:simdart/src/simdart.dart';
import 'package:simdart/src/simulation_track.dart';

@internal
class EventAction extends TimeAction with EventContext {
  EventAction(
      {required this.sim,
      required super.start,
      required String? eventName,
      required this.event,
      required this.resourceId,
      required this.onTrack,
      required this.secondarySortByName})
      : _eventName = eventName;

  /// The name of the event.
  final String? _eventName;
  String get eventName => _eventName ?? hashCode.toString();

  /// A callback function used to track the progress of the simulation.
  /// If provided, this function will be called with each [SimulationTrack] generated
  /// during the simulation. This is useful for debugging or logging purposes.
  final OnTrack? onTrack;

  /// The event to be executed.
  final Event event;

  @override
  final SimDart sim;

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
      if (onTrack != null) {
        onTrack!(SimDartHelper.buildSimulationTrack(
            sim: sim, eventName: eventName, status: Status.resumed));
      }
      // Resume the event if it is waiting, otherwise execute its action.
      resume.call();
      return;
    }

    Resource? resource =
        SimDartHelper.getResource(sim: sim, resourceId: resourceId);
    if (resource != null) {
      _resourceAcquired = resource.acquire(this);
    }

    if (onTrack != null) {
      Status status = Status.executed;
      if (!_canRun) {
        status = Status.rejected;
      }
      onTrack!(SimDartHelper.buildSimulationTrack(
          sim: sim, eventName: eventName, status: status));
    }

    if (_canRun) {
      _runEvent().then((_) {
        if (_resourceAcquired) {
          if (resource != null) {
            resource.release(this);
            _resourceAcquired = false;
          }
          // Event released some resource, others events need retry.
          SimDartHelper.restoreWaitingEventsForResource(sim: sim);
        }
      });
    } else {
      SimDartHelper.queueOnWaitingForResource(sim: sim, action: this);
    }
  }

  @override
  Future<void> wait(int delay) async {
    if (_resume != null) {
      return;
    }

    start = sim.now + delay;
    // Adds it back to the loop to be resumed in the future.
    SimDartHelper.addAction(sim: sim, action: this);

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
}
