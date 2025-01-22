import 'package:meta/meta.dart';

/// This class is responsible for configuring the resources
/// available in the simulator. It allows adding resource configurations, but once
/// the simulator starts running, no new configurations can be added.
///
/// ## Note
/// After the simulation starts running, no new configurations can be
/// added. Configurations need to be defined before the simulation starts.
class ResourcesConfigurator {
  final List<ResourceConfiguration> _configurations = [];

  /// Configures a resource with limited capacity.
  ///
  /// This method adds a resource configuration with the specified capacity.
  /// The resource will be configured as limited, meaning it will have a maximum
  /// capacity defined by the [capacity] parameter.
  ///
  /// - [id]: The unique identifier of the resource (required).
  /// - [capacity]: The maximum capacity of the resource. The default value is 1.
  void limited({required String id, int capacity = 1}) {
    _configurations
        .add(LimitedResourceConfiguration(id: id, capacity: capacity));
  }
}

abstract class ResourceConfiguration {
  ResourceConfiguration({required this.id, required this.capacity});

  final String id;
  final int capacity;
}

class LimitedResourceConfiguration extends ResourceConfiguration {
  LimitedResourceConfiguration({required super.id, required super.capacity});
}

@internal
class ResourcesConfiguratorHelper {
  static Iterable<ResourceConfiguration> iterable(
          {required ResourcesConfigurator configurator}) =>
      configurator._configurations;
}
