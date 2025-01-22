import 'dart:math';

import 'package:simdart/src/simdart.dart';

typedef NextIncrementGenerator = int Function(SimDart sim);

/// Abstract class representing an interval. The [getIncrement] method is implemented
/// by each subclass to define how the interval is calculated.
///
/// If both [untilTime] and [untilCount] are null, execution will repeat indefinitely.
abstract class Interval {
  Interval({required this.untilTime, required this.untilCount});

  /// The time at which execution should stop. If null, it will continue indefinitely.
  final int? untilTime;

  /// The maximum number of times execution can occur. If null, it will continue indefinitely.
  final int? untilCount;

  /// A counter to track how many times the event has been executed.
  int _executionCount = 0;

  /// Returns the increment value based on the current state of the simulation.
  /// This value must be added to the current simulation time.
  int getIncrement(SimDart sim);

  /// Returns the next start time for an event, calculated from the current time (now).
  int? nextStart(SimDart sim) {
    int start = sim.now + getIncrement(sim);
    if ((untilTime != null && start >= untilTime!) ||
        (untilCount != null && _executionCount >= untilCount!)) {
      return null;
    }
    if (untilCount != null) {
      _executionCount++;
    }
    return start;
  }

  /// Factory method for creating a FixedInterval.
  ///
  /// Creates an interval with a fixed duration.
  factory Interval.fixed(
          {required int fixedInterval, int? untilTime, int? untilCount}) =>
      FixedInterval._(
          fixedInterval: fixedInterval,
          untilTime: untilTime,
          untilCount: untilCount);

  /// Factory method for creating a RandomInterval.
  ///
  /// Creates an interval where the duration is randomly generated using the
  /// provided generator function.
  factory Interval.random(
          {required NextIncrementGenerator generator,
          int? untilTime,
          int? untilCount}) =>
      RandomInterval._(
          generator: generator, untilTime: untilTime, untilCount: untilCount);

  /// Factory method for creating a ConditionalInterval.
  ///
  /// Creates an interval where the duration is conditionally computed based
  /// on the simulation state.
  factory Interval.conditional(
          {required NextIncrementGenerator generator,
          int? untilTime,
          int? untilCount}) =>
      ConditionalInterval._(
          generator: generator, untilCount: untilCount, untilTime: untilTime);

  /// Factory method for creating a ProbabilisticInterval.
  ///
  /// Creates an interval with probabilistic distribution using the provided
  /// random number generator function.
  factory Interval.probabilistic(
          {required NextIncrementGenerator generator,
          int? untilTime,
          int? untilCount}) =>
      ProbabilisticInterval._(
          generator: generator, untilTime: untilTime, untilCount: untilCount);

  /// Factory method for creating a uniform probabilistic interval.
  ///
  /// Creates a probabilistic interval with a uniform distribution between
  /// [min] and [max].
  factory Interval.uniform(
          {required int min,
          required int max,
          int? untilTime,
          int? untilCount}) =>
      ProbabilisticInterval._uniform(
          min: min, max: max, untilCount: untilCount, untilTime: untilTime);

  /// Factory method for creating an exponential probabilistic interval.
  ///
  /// Creates a probabilistic interval with an exponential distribution based
  /// on the provided [mean].
  factory Interval.exponential(
          {required double mean, int? untilTime, int? untilCount}) =>
      ProbabilisticInterval._exponential(
          mean: mean, untilTime: untilTime, untilCount: untilCount);

  /// Factory method for creating a normal (Gaussian) probabilistic interval.
  ///
  /// Creates a probabilistic interval with a normal distribution based on
  /// the provided [mean] and [stdDev] (standard deviation).
  factory Interval.normal(
          {required double mean,
          required double stdDev,
          int? untilTime,
          int? untilCount}) =>
      ProbabilisticInterval._normal(
          mean: mean,
          stdDev: stdDev,
          untilTime: untilTime,
          untilCount: untilCount);
}

/// Represents a fixed interval where the duration is constant.
class FixedInterval extends Interval {
  final int fixedInterval;

  FixedInterval._(
      {required super.untilTime,
      required super.untilCount,
      required this.fixedInterval});

  @override
  int getIncrement(SimDart sim) => fixedInterval;
}

/// Represents a random interval where the duration is generated using a custom function.
class RandomInterval extends Interval {
  final NextIncrementGenerator _generator;

  RandomInterval._(
      {required super.untilTime,
      required super.untilCount,
      required NextIncrementGenerator generator})
      : _generator = generator;

  @override
  int getIncrement(SimDart sim) => _generator(sim);
}

/// Represents a conditional interval where the duration is computed based on the simulation state.
class ConditionalInterval extends Interval {
  final NextIncrementGenerator _generator;

  ConditionalInterval._(
      {required super.untilTime,
      required super.untilCount,
      required NextIncrementGenerator generator})
      : _generator = generator;

  @override
  int getIncrement(SimDart sim) => _generator(sim);
}

/// Represents a probabilistic interval where the duration is determined by a random number generator.
class ProbabilisticInterval extends Interval {
  final NextIncrementGenerator _generator;

  /// Constructor that takes a custom random generator function.
  ProbabilisticInterval._(
      {required super.untilTime,
      required super.untilCount,
      required NextIncrementGenerator generator})
      : _generator = generator;

  @override
  int getIncrement(SimDart sim) => _generator(sim);

  /// Factory constructor for creating a uniform probabilistic interval.
  ///
  /// The interval duration is uniformly distributed between [min] and [max].
  factory ProbabilisticInterval._uniform(
      {required int min,
      required int max,
      required int? untilTime,
      required int? untilCount}) {
    return ProbabilisticInterval._(
        generator: (sim) => min + sim.random.nextInt(max - min + 1),
        untilCount: untilCount,
        untilTime: untilTime);
  }

  /// Factory constructor for creating an exponential probabilistic interval.
  ///
  /// The interval duration follows an exponential distribution with the provided [mean].
  factory ProbabilisticInterval._exponential(
      {required double mean,
      required int? untilTime,
      required int? untilCount}) {
    return ProbabilisticInterval._(
        generator: (sim) {
          return (-mean * log(1 - sim.random.nextDouble())).round();
        },
        untilTime: untilTime,
        untilCount: untilCount);
  }

  /// Factory constructor for creating a normal (Gaussian) probabilistic interval.
  ///
  /// The interval duration follows a normal distribution with the provided
  /// [mean] and [stdDev].
  factory ProbabilisticInterval._normal(
      {required double mean,
      required double stdDev,
      required int? untilTime,
      required int? untilCount}) {
    return ProbabilisticInterval._(
        generator: (sim) {
          double u1 = sim.random.nextDouble();
          double u2 = sim.random.nextDouble();
          // Box-Muller transform to generate normally distributed random numbers.
          double z0 = sqrt(-2.0 * log(u1)) * cos(2.0 * pi * u2);
          return (mean + z0 * stdDev).round();
        },
        untilCount: untilCount,
        untilTime: untilTime);
  }
}
