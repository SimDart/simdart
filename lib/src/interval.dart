import 'dart:math';

import 'package:simdart/src/simdart.dart';

/// Abstract class representing an interval. The [next] method is implemented
/// by each subclass to define how the interval is calculated.
abstract class Interval {
  const Interval();

  /// Returns the next interval value based on the current state of the simulation.
  int next(SimDart sim);

  /// Factory method for creating a FixedInterval.
  ///
  /// Creates an interval with a fixed duration.
  factory Interval.fixed(int fixedInterval) => FixedInterval(fixedInterval);

  /// Factory method for creating a RandomInterval.
  ///
  /// Creates an interval where the duration is randomly generated using the
  /// provided generator function.
  factory Interval.random(int Function(SimDart sim) generator) =>
      RandomInterval(generator);

  /// Factory method for creating a ConditionalInterval.
  ///
  /// Creates an interval where the duration is conditionally computed based
  /// on the simulation state.
  factory Interval.conditional(int Function(SimDart sim) computeInterval) =>
      ConditionalInterval(computeInterval);

  /// Factory method for creating a ProbabilisticInterval.
  ///
  /// Creates an interval with probabilistic distribution using the provided
  /// random number generator function.
  factory Interval.probabilistic(int Function(SimDart sim) randomGenerator) =>
      ProbabilisticInterval(randomGenerator);

  /// Factory method for creating a uniform probabilistic interval.
  ///
  /// Creates a probabilistic interval with a uniform distribution between
  /// [min] and [max].
  factory Interval.uniform(int min, int max) =>
      ProbabilisticInterval.uniform(min, max);

  /// Factory method for creating an exponential probabilistic interval.
  ///
  /// Creates a probabilistic interval with an exponential distribution based
  /// on the provided [mean].
  factory Interval.exponential(double mean) =>
      ProbabilisticInterval.exponential(mean);

  /// Factory method for creating a normal (Gaussian) probabilistic interval.
  ///
  /// Creates a probabilistic interval with a normal distribution based on
  /// the provided [mean] and [stdDev] (standard deviation).
  factory Interval.normal(double mean, double stdDev) =>
      ProbabilisticInterval.normal(mean, stdDev);
}

/// Represents a fixed interval where the duration is constant.
class FixedInterval extends Interval {
  final int fixedInterval;

  const FixedInterval(this.fixedInterval);

  @override
  int next(SimDart sim) => fixedInterval;
}

/// Represents a random interval where the duration is generated using a custom function.
class RandomInterval extends Interval {
  final int Function(SimDart sim) generator;

  const RandomInterval(this.generator);

  @override
  int next(SimDart sim) => generator(sim);
}

/// Represents a conditional interval where the duration is computed based on the simulation state.
class ConditionalInterval extends Interval {
  final int Function(SimDart sim) computeInterval;

  const ConditionalInterval(this.computeInterval);

  @override
  int next(SimDart sim) => computeInterval(sim);
}

/// Represents a probabilistic interval where the duration is determined by a random number generator.
class ProbabilisticInterval extends Interval {
  final int Function(SimDart sim) _randomGenerator;

  /// Constructor that takes a custom random generator function.
  const ProbabilisticInterval(this._randomGenerator);

  @override
  int next(SimDart sim) => _randomGenerator(sim);

  /// Factory constructor for creating a uniform probabilistic interval.
  ///
  /// The interval duration is uniformly distributed between [min] and [max].
  factory ProbabilisticInterval.uniform(int min, int max) {
    return ProbabilisticInterval(
        (sim) => min + sim.random.nextInt(max - min + 1));
  }

  /// Factory constructor for creating an exponential probabilistic interval.
  ///
  /// The interval duration follows an exponential distribution with the provided [mean].
  factory ProbabilisticInterval.exponential(double mean) {
    return ProbabilisticInterval((sim) {
      return (-mean * log(1 - sim.random.nextDouble())).round();
    });
  }

  /// Factory constructor for creating a normal (Gaussian) probabilistic interval.
  ///
  /// The interval duration follows a normal distribution with the provided
  /// [mean] and [stdDev].
  factory ProbabilisticInterval.normal(double mean, double stdDev) {
    return ProbabilisticInterval((sim) {
      double u1 = sim.random.nextDouble();
      double u2 = sim.random.nextDouble();
      // Box-Muller transform to generate normally distributed random numbers.
      double z0 = sqrt(-2.0 * log(u1)) * cos(2.0 * pi * u2);
      return (mean + z0 * stdDev).round();
    });
  }
}
