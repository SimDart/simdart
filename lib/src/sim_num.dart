import 'dart:math';

import 'package:simdart/src/sim_property.dart';

/// A class to track numeric metrics in a discrete event simulation.
///
/// This class allows you to store and update numeric values (both integers and doubles),
/// while automatically tracking minimum, maximum, and average values.
class SimNum extends SimProperty {
  num? _value;
  num? _min;
  num? _max;
  num _total = 0;
  int _count = 0;
  num _sumOfSquares = 0;

  final Map<num, int> _frequencyMap = {};

  /// Creates a new [SimNum] instance.
  ///
  /// Optionally, provide a [name] to identify the metric.
  SimNum({super.name});

  /// The current value of the metric.
  ///
  /// Returns `null` if no value has been set.
  num? get value => _value;

  /// Sets the current value of the metric.
  ///
  /// If the value is not `null`, it updates the minimum, maximum, total, and count.
  set value(num? value) {
    _value = value;

    if (value != null) {
      _frequencyMap[value] = (_frequencyMap[value] ?? 0) + 1;

      // Update min and max
      _min = (_min == null || value < _min!) ? value : _min;
      _max = (_max == null || value > _max!) ? value : _max;

      // Update total, sum of squares, and count
      _total += value;
      _sumOfSquares += value * value;
      _count++;
    }
  }

  @override
  void reset() {
    _value = null;
    _min = null;
    _max = null;
    _total = 0;
    _count = 0;
    _sumOfSquares = 0;
    _frequencyMap.clear();
  }

  /// The minimum value recorded.
  ///
  /// Returns `null` if no value has been set.
  num? get min => _min;

  /// The maximum value recorded.
  ///
  /// Returns `null` if no value has been set.
  num? get max => _max;

  /// The average of all recorded values.
  ///
  /// Returns `null` if no value has been set.
  num? get average => _count > 0 ? _total / _count : null;

  /// Calculates the rate of the current value relative to a reference value.
  ///
  /// - [value]: The reference value.
  /// - Returns: The rate as a proportion (current value / reference value).
  ///   If the reference value is `0` or the current value is `null`, returns `0`.
  num rate(num value) {
    if (value == 0 || _value == null) {
      return 0;
    }
    return _value! / value;
  }

  /// Calculates the variance of the recorded values.
  ///
  /// Returns `null` if fewer than 2 values have been recorded.
  num? get variance {
    if (_count < 2) return null;
    return (_sumOfSquares - (_total * _total) / _count) / _count;
  }

  /// Calculates the standard deviation of the recorded values.
  ///
  /// Returns `null` if fewer than 2 values have been recorded.
  num? get standardDeviation {
    final varianceValue = variance;
    return varianceValue != null ? sqrt(varianceValue) : null;
  }

  /// Returns the mode of the recorded values.
  ///
  /// The mode is the value that appears most frequently.
  /// If there are multiple values with the same highest frequency, returns the first one.
  /// Returns `null` if no values have been recorded.
  num? get mode {
    if (_frequencyMap.isEmpty) return null;

    num? modeValue;
    int maxFrequency = 0;

    _frequencyMap.forEach((value, frequency) {
      if (frequency > maxFrequency) {
        modeValue = value;
        maxFrequency = frequency;
      }
    });

    return modeValue;
  }
}
