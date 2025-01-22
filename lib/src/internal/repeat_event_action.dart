import 'package:meta/meta.dart';
import 'package:simdart/src/event.dart';
import 'package:simdart/src/internal/time_action.dart';
import 'package:simdart/src/interval.dart';
import 'package:simdart/src/simdart.dart';

@internal
class RepeatEventAction extends TimeAction {
  RepeatEventAction(
      {required this.sim,
      required super.start,
      required this.eventName,
      required this.event,
      required this.interval,
      required this.resourceId,
      required this.rejectedEventPolicy});

  /// The name of the event.
  final String? eventName;

  /// Defines the behavior of the interval after a newly created event has been rejected.
  final RejectedEventPolicy rejectedEventPolicy;

  /// The event to be executed.
  final Event event;

  /// The resource id required by the event.
  final String? resourceId;

  final Interval interval;

  final SimDart sim;

  bool _discard = false;

  @override
  void execute() {
    if (_discard) {
      return;
    }
    //TODO Run directly without adding to the loop?
    SimDartHelper.process(
        sim: sim,
        event: event,
        start: null,
        delay: null,
        name: eventName,
        resourceId: resourceId,
        onReject: rejectedEventPolicy == RejectedEventPolicy.stopRepeating
            ? _removeFromLoop
            : null,
        interval: null,
        rejectedEventPolicy: null);
    int? start = interval.nextStart(sim);
    if (start != null) {
      //TODO avoid start = now?
      this.start = start;
      SimDartHelper.addAction(sim: sim, action: this);
    }
  }

  void _removeFromLoop() {
    _discard = true;
  }

  @override
  int secondaryCompareTo(TimeAction action) {
    // Gain priority over event actions
    return -1;
  }
}
