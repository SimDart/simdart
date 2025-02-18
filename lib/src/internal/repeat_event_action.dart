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
      required this.stopCondition});

  /// The name of the event.
  final String Function(int start)? eventName;

  final StopCondition? stopCondition;

  /// The event to be executed.
  final Event event;

  final Interval interval;

  final SimDart sim;

  @override
  void execute() {
    //TODO Run directly without adding to the loop?
    sim.process(
        event: event, name: eventName != null ? eventName!(sim.now) : null);
    bool repeat = true;
    if (stopCondition != null) {
      repeat = stopCondition!(sim);
    }
    if (repeat) {
      int? start = interval.nextStart(sim);
      if (start != null) {
        //TODO avoid start = now?
        this.start = start;
        SimDartHelper.addAction(sim: sim, action: this);
      }
    }
  }

  @override
  int secondaryCompareTo(TimeAction action) {
    // Gain priority over event actions
    return -1;
  }

  @override
  Future<void> wait(int delay) {
    throw StateError('Feature not available');
  }

  @override
  Future<void> acquireResource(String id) {
    throw StateError('Feature not available');
  }

  @override
  void releaseResource(String id) {
    throw StateError('Feature not available');
  }
}
