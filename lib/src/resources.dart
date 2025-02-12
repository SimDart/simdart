import 'package:meta/meta.dart';
import 'package:simdart/src/internal/resource.dart';
import 'package:simdart/src/simdart.dart';

/// This class is responsible for creating the resources
/// available in the simulator.
class Resources {
  Resources._(SimDart sim) : _sim = sim;

  final SimDart _sim;

  /// Creates a resource with limited capacity.
  ///
  /// This method adds a resource with the specified capacity.
  /// The resource will be configured as limited, meaning it will have a maximum
  /// capacity defined by the [capacity] parameter.
  ///
  /// - [id]: The unique identifier of the resource (required).
  /// - [capacity]: The maximum capacity of the resource. The default value is 1.
  void limited({required String id, int capacity = 1}) {
    SimDartHelper.addResource(
        sim: _sim,
        resourceId: id,
        create: () => LimitedResource(id: id, capacity: capacity));
  }
}

@internal
class ResourcesHelper {
  static Resources build(SimDart sim) => Resources._(sim);
}
