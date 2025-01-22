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

  @override
  void execute() {
    sim.process(event: event, resourceId: resourceId, name: eventName);
    //TODO next (repeat)
  }

  @override
  int secondaryCompareTo(RepeatEventAction action) {
    // Gain priority over event actions
    return -1;
  }
}
