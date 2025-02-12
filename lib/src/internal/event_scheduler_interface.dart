import 'package:meta/meta.dart';
import 'package:simdart/src/event.dart';
import 'package:simdart/src/interval.dart';
import 'package:simdart/src/simdart.dart';

@internal
abstract interface class EventSchedulerInterface {
  /// Schedules a new event to occur repeatedly based on the specified interval configuration.
  ///
  /// [event] is the function that represents the action to be executed when the event occurs.
  /// [start] is the absolute time at which the event should occur. If null, the event will
  /// occur at the [now] simulation time.
  /// [delay] is the number of time units after the [now] when the event has been scheduled.
  /// It cannot be provided if [start] is specified.
  /// [interval] defines the timing configuration for the event, including its start time and
  /// the interval between repetitions. The specific details of the interval behavior depend
  /// on the implementation of the [Interval].
  /// [resourceId] is an optional parameter that specifies the ID of the resource required by the event.
  /// [name] is an optional identifier for the event.
  /// [rejectedEventPolicy] defines the behavior of the interval after a newly created event has been rejected.
  ///
  /// Throws an [ArgumentError] if the provided interval configuration is invalid, such as
  /// containing negative or inconsistent timing values.
  void repeatProcess(
      {required Event event,
      int? start,
      int? delay,
      required Interval interval,
      RejectedEventPolicy rejectedEventPolicy =
          RejectedEventPolicy.keepRepeating,
      String? resourceId,
      String? name});

  /// Schedules a new event to occur at a specific simulation time or after a delay.
  ///
  /// [event] is the function that represents the action to be executed when the event occurs.
  /// [start] is the absolute time at which the event should occur. If null, the event will
  /// occur at the [now] simulation time.
  /// [delay] is the number of time units after the [now] when the event has been scheduled.
  /// It cannot be provided if [start] is specified.
  /// [resourceId] is an optional parameter that specifies the ID of the resource required by the event.
  /// [name] is an optional identifier for the event.
  ///
  /// Throws an [ArgumentError] if both [start] and [delay] are provided or if [delay] is negative.
  void process(
      {required Event event,
      String? resourceId,
      String? name,
      int? start,
      int? delay});
}
