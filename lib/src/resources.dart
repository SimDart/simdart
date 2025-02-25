import 'package:meta/meta.dart';
import 'package:simdart/src/internal/completer_action.dart';
import 'package:simdart/src/internal/event_action.dart';
import 'package:simdart/src/internal/resource.dart';
import 'package:simdart/src/simdart.dart';
import 'package:simdart/src/simulation_track.dart';

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

  /// Checks if a resource is available.
  ///
  /// - [id]: The id of the resource to check.
  /// - Returns: `true` if the resource is available, `false` otherwise.
  bool isAvailable(String id) {
    Resource? resource = SimDartHelper.getResource(sim: _sim, resourceId: id);
    if (resource != null) {
      return resource.isAvailable();
    }
    return false;
  }
}

class ResourcesContext extends Resources {
  ResourcesContext._(super.sim, EventAction event)
      : _event = event,
        super._();

  final EventAction _event;

  /// Tries to acquire a resource immediately.
  ///
  /// - [id]: The id of the resource to acquire.
  /// - Returns: `true` if the resource was acquired, `false` otherwise.
  bool tryAcquire(String id) {
    Resource? resource = SimDartHelper.getResource(sim: _sim, resourceId: id);
    if (resource != null) {
      return resource.acquire(_event);
    }
    return false;
  }

  /// Acquires a resource, waiting if necessary until it becomes available.
  ///
  /// - [id]: The id of the resource to acquire.
  /// - Returns: A [Future] that completes when the resource is acquired.
  Future<void> acquire(String id) async {
    if (_event.eventCompleter != null) {
      SimDartHelper.error(
          sim: _sim,
          msg:
              "This event should be waiting for the resource to be released. Did you forget to use 'await'?");
      return;
    }
    Resource? resource = SimDartHelper.getResource(sim: _sim, resourceId: id);
    if (resource != null) {
      bool acquired = resource.acquire(_event);
      if (!acquired) {
        if (_sim.includeTracks) {
          SimDartHelper.addSimulationTrack(
              sim: _sim, eventName: _event.eventName, status: Status.yielded);
        }
        _event.buildCompleter();
        resource.waiting.add(_event);
        SimDartHelper.scheduleNextAction(sim: _sim);
        await _event.eventCompleter!.future;
        return await acquire(id);
      }
    }
  }

  /// Releases a previously acquired resource.
  ///
  /// - [id]: The id of the resource to release.
  void release(String id) {
    Resource? resource = SimDartHelper.getResource(sim: _sim, resourceId: id);
    if (resource != null) {
      if (resource.release(_sim, _event)) {
        if (resource.waiting.isNotEmpty) {
          EventAction other = resource.waiting.removeAt(0);
          // Schedule a complete to resume this event in the future.
          SimDartHelper.addAction(
              sim: _sim,
              action: CompleterAction(
                  start: _sim.now,
                  complete: other.eventCompleter!.complete,
                  order: other.order));
          SimDartHelper.scheduleNextAction(sim: _sim);
        }
      }
    }
  }
}

@internal
class ResourcesFactory {
  static Resources sim(SimDart sim) => Resources._(sim);

  static ResourcesContext context(SimDart sim, EventAction event) =>
      ResourcesContext._(sim, event);
}
