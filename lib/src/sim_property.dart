/// A base class for simulation properties.
///
/// This class provides a common interface for properties used in discrete event simulations,
/// such as counters, numeric metrics, or other tracked values.
abstract class SimProperty {
  /// The name of this property (optional).
  ///
  /// Useful for identifying the property in logs or reports.
  final String name;

  /// Creates a new [SimProperty] instance.
  ///
  /// Optionally, provide a [name] to identify the property.
  SimProperty({this.name = ''});

  /// Resets the property to its initial state.
  void reset();
}
