abstract class Resources {
  /// Creates a resource with limited capacity.
  ///
  /// This method adds a resource with the specified capacity.
  /// The resource will be configured as limited, meaning it will have a maximum
  /// capacity defined by the [capacity] parameter.
  ///
  /// - [id]: The unique identifier of the resource (required).
  /// - [capacity]: The maximum capacity of the resource. The default value is 1.
  void limited({required String id, int capacity = 1});

  /// Checks if a resource is available.
  ///
  /// - [id]: The id of the resource to check.
  /// - Returns: `true` if the resource is available, `false` otherwise.
  bool isAvailable(String id);
}
