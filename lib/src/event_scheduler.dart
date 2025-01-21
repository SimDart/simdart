import 'package:meta/meta.dart';
import 'package:simdart/src/event.dart';
import 'package:simdart/src/interval.dart';
import 'package:simdart/src/simdart.dart';

/// Schedules events on a defined interval.
///
/// The [EventScheduler] schedules events to occur at specific times, based on a provided
/// [interval]. It is initialized with a [start] time and an [event], and optionally,
/// a custom [eventName] and [name]. Each time the generator is selected by the simulation,
/// it generates and executes the associated [event] and then schedules the next occurrence
/// of the event based on the defined interval. The [next] time is calculated before the event
/// is executed, ensuring that future events are properly scheduled even as the current event is running.
class EventScheduler {
  /// Creates a [EventScheduler] instance with the provided [start] time, [interval],
  /// [event], and optional [eventName].
  ///
  /// The [start] time defines when the first event will be scheduled.
  /// The [interval] defines how often subsequent events will occur.
  /// The [event] is the event to be scheduled, and [eventName] is an optional custom name for the event.
  /// The [name] is an optional name for the scheduler itself.
  /// The [untilTime] defines the time when the event should stop being scheduled.
  /// The [untilCount] defines the maximum number of times the event will execute.
  /// If both [untilTime] and [untilCount] are null, the event will run indefinitely.
  EventScheduler(
      {required int start,
      required this.interval,
      required this.event,
      this.untilCount,
      this.untilTime,
      this.name,
      this.eventName})
      : _next = start;

  /// The interval that determines when the next event will occur.
  ///
  /// This interval is used to calculate the time of the next event. It is important to note
  /// that the [next] time is determined before the event is executed, meaning the [next] time
  /// is calculated when the event is generated, not when it is executed. This ensures that the
  /// generator can properly schedule the subsequent events based on the interval.
  final Interval interval;

  /// The event to be scheduled.
  final Event event;

  /// An optional name for the event.
  final String? eventName;

  /// An optional name for the scheduler.
  final String? name;

  /// The time at which the event should stop being scheduled. If null, the event will continue indefinitely.
  final int? untilTime;

  /// The maximum number of times the event can be scheduled. If null, the event will continue indefinitely.
  final int? untilCount;

  /// A counter to track how many times the event has been executed.
  int _executionCount = 0;

  /// The time of the next event, in simulation units.
  int _next;

  int get next => _next;

  /// Executes the scheduled event and reschedules its own next occurrence.
  ///
  /// This method represents a loop where the generator keeps rescheduling itself for future execution
  /// while simultaneously triggering the event at the current time.
  Future<void> _run(EventContext context) async {
    _next = _next + interval.next(context.sim);
    if ((untilTime != null && _next >= untilTime!) ||
        (untilCount != null && _executionCount >= untilCount!)) {
      return;
    }
    SimDartHelper.processAtWithType(
        sim: context.sim,
        event: _run,
        start: next,
        name: name,
        resourceId: null,
        type: EventType.scheduler);
    context.sim.process(event, name: eventName);

    if (untilCount != null) {
      _executionCount++;
    }
  }
}

typedef ShouldExecuteEvent = bool Function(SimDart sim);
typedef ShouldIgnoreNextEvent = bool Function(SimDart sim);

/// Helper class to manage the scheduling of events via the [EventScheduler].
///
/// The [EventSchedulerHelper] class provides a utility method to add the [EventScheduler]
/// to the simulation's event queue at the appropriate time.
@internal
class EventSchedulerHelper {
  static Event eventFrom({required EventScheduler scheduler}) {
    return scheduler._run;
  }
}
