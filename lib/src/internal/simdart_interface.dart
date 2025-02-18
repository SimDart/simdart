import 'package:meta/meta.dart';
import 'package:simdart/src/event.dart';
import 'package:simdart/src/interval.dart';
import 'package:simdart/src/sim_counter.dart';
import 'package:simdart/src/sim_num.dart';
import 'package:simdart/src/simdart.dart';

@internal
abstract class SimDartInterface {
  /// Gets the current simulation time.
  int get now;

  /// Schedules a new event to occur repeatedly based on the specified interval configuration.
  ///
  /// - [event]: The event to repeat.
  /// - [start]: The time at which the first event should be executed. If null, the event will
  ///    occur at the [now] simulation time.
  /// - [delay]: The delay before starting the repetition.
  /// - [interval]: The interval between event executions.
  /// - [stopCondition]: A function that determines whether to stop the repetition.
  ///   If provided, it will be called before each subsequent event execution.
  ///   If it returns `true`, the repetition stops.
  ///   The first event is always executed, regardless of the stop condition.
  /// - [name] is an optional identifier for the event.
  ///
  /// Throws an [ArgumentError] if the provided interval configuration is invalid, such as
  /// containing negative or inconsistent timing values.
  void repeatProcess(
      {required Event event,
      int? start,
      int? delay,
      required Interval interval,
      StopCondition? stopCondition,
      String Function(int start)? name});

  /// Schedules a new event to occur at a specific simulation time or after a delay.
  ///
  /// [event] is the function that represents the action to be executed when the event occurs.
  /// [start] is the absolute time at which the event should occur. If null, the event will
  /// occur at the [now] simulation time.
  /// [delay] is the number of time units after the [now] when the event has been scheduled.
  /// It cannot be provided if [start] is specified.
  /// [name] is an optional identifier for the event.
  ///
  /// Throws an [ArgumentError] if both [start] and [delay] are provided or if [delay] is negative.
  void process({required Event event, String? name, int? start, int? delay});

  /// Creates a new [SimCounter] instance with the given name.
  ///
  /// - [name]: The name of the counter. This is used to identify the counter in logs or reports.
  /// - Returns: A new instance of [SimCounter].
  SimCounter counter(String name);

  /// Creates a new [SimNum] instance with the given name.
  ///
  /// - [name]: The name of the numeric metric. This is used to identify the metric in logs or reports.
  /// - Returns: A new instance of [SimNum].
  SimNum num(String name);
}
