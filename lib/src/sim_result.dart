import 'dart:collection';

import 'package:simdart/src/sim_counter.dart';
import 'package:simdart/src/sim_num.dart';

/// Represents the simulation result.
class SimResult {
  SimResult(
      {required this.duration,
      required this.startTime,
      required Map<String, SimNum> numProperties,
      required Map<String, SimCounter> counterProperties})
      : numProperties = UnmodifiableMapView(numProperties),
        counterProperties = UnmodifiableMapView(counterProperties);

  /// The duration, in simulated time units, that the simulation took to execute.
  ///
  /// This value represents the total time elapsed during the processing of the simulation,
  /// from the start to the completion of all event handling, in terms of the simulated environment.
  /// It is used to track how much time has passed in the simulation model, not real-world time.
  final int duration;

  /// The time, in simulated time units, when the simulation started.
  /// This is the moment at which the first event is scheduled to be processed.
  ///
  /// For example, if the first process is scheduled to occur at time 10,
  /// then the simulation start time would be 10. This value helps track when
  /// the simulation officially begins its execution in terms of the simulation time.
  final int startTime;

  final Map<String, SimNum> numProperties;
  final Map<String, SimCounter> counterProperties;
}
