import 'package:meta/meta.dart';
import 'package:simdart/src/event.dart';

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

abstract class Resource {
  final String id;
  final int capacity;
  final List<EventContext> queue = [];
  final bool Function(EventContext context)? acquisitionRule;

  final List<EventContext> waiting = [];

  Resource({required this.id, this.capacity = 1, this.acquisitionRule});

  bool acquire(EventContext event);

  void release(EventContext event);

  bool isAvailable();
}

class LimitedResource extends Resource {
  LimitedResource({required super.id, super.capacity, super.acquisitionRule});

  @override
  bool acquire(EventContext event) {
    if (acquisitionRule != null && !acquisitionRule!(event)) {
      // waiting.add(event);
      return false;
    }
    if (isAvailable()) {
      queue.add(event);
      ResourceStateHelper.setAcquired(
          resourceState: event.resource!, acquired: true);
      return true;
    } else {
      // waiting.add(event);
      return false;
    }
  }

  @override
  void release(EventContext event) {
    queue.remove(event);
    ResourceStateHelper.setAcquired(
        resourceState: event.resource!, acquired: false);
  }

  @override
  bool isAvailable() {
    return queue.length < capacity;
  }
}

@internal
class ResourcesConfiguratorHelper {
  static Iterable<ResourceConfiguration> iterable(
          {required ResourcesConfigurator configurator}) =>
      configurator._configurations;
}
