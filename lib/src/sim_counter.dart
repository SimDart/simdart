import 'package:simdart/src/sim_property.dart';

/// A class to track event counts in a discrete event simulation.
///
/// This class extends [SimProperty] and provides methods to increment and reset a counter.
/// It is useful for counting occurrences of specific events, such as arrivals, departures, or errors.
class SimCounter extends SimProperty {
  int _value = 0;

  /// Creates a new [SimCounter] instance.
  ///
  /// Optionally, provide a [name] to identify the counter.
  SimCounter({super.name});

  /// The current value of the counter.
  int get value => _value;

  /// Increments the counter by 1.
  void inc() {
    _value++;
  }

  /// Increments the counter by a specified value.
  ///
  /// - [value]: The value to increment the counter by.
  void incBy(int value) {
    if (value > 0) {
      _value += value;
    }
  }

  /// Resets the counter to 0.
  @override
  void reset() {
    _value = 0;
  }
}
