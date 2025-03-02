import 'dart:collection';

import 'package:meta/meta.dart';
import 'package:simdart/src/event_phase.dart';
import 'package:simdart/src/internal/completer_action.dart';
import 'package:simdart/src/internal/completer_interrupt.dart';
import 'package:simdart/src/internal/event_action.dart';
import 'package:simdart/src/simdart.dart';

@internal
class ResourceStore {
  /// Holds the resources in the simulator.
  final Map<String, _ResourceImpl> _map = {};
  final List<_ResourceImpl> _list = [];
  late final UnmodifiableListView<_ResourceImpl> _unmodifiableList =
      UnmodifiableListView(_list);

  Map<String, int> usage() {
    Map<String, int> result = {};
    for (_ResourceImpl resource in _map.values) {
      result[resource.name] = resource._queue.length;
    }
    return result;
  }
}

abstract interface class Resource {
  String get name;
  int get capacity;
  bool isAvailable();
}

abstract interface class LimitedResource extends Resource {}

abstract class _ResourceImpl implements Resource {
  _ResourceImpl(
      {required this.name,
      required this.capacity,
      required this.acquisitionRule});

  @override
  final String name;

  @override
  final int capacity;

  final List<EventAction> _queue = [];
  final bool Function(EventAction event)? acquisitionRule;

  /// A queue that holds completer to resume events waiting for a resource to become available.
  final List<EventAction> _waiting = [];

  bool acquire(EventAction event);

  bool release(SimDart sim, EventAction event);
}

class _LimitedResourceImpl extends _ResourceImpl implements LimitedResource {
  _LimitedResourceImpl(
      {required super.name,
      required super.capacity,
      required super.acquisitionRule});

  @override
  bool acquire(EventAction event) {
    if (acquisitionRule != null && !acquisitionRule!(event)) {
      return false;
    }
    if (isAvailable()) {
      _queue.add(event);
      return true;
    }

    return false;
  }

  @override
  bool release(SimDart sim, EventAction event) {
    return _queue.remove(event);
  }

  @override
  bool isAvailable() {
    return _queue.length < capacity;
  }
}

class Resources {
  Resources._(SimDart sim)
      : _sim = sim,
        _store = SimDartHelper.resourceStore(sim: sim);

  final SimDart _sim;
  final ResourceStore _store;

  List<Resource> get all => _store._unmodifiableList;

  int get length => _store._map.length;

  /// Creates a resource with limited capacity.
  ///
  /// This method adds a resource with the specified capacity.
  /// The resource will be configured as limited, meaning it will have a maximum
  /// capacity defined by the [capacity] parameter.
  ///
  /// - [name]: The unique name of the resource (required).
  /// - [capacity]: The maximum capacity of the resource. The default value is 1.
  Resource limited({required String name, int capacity = 1}) {
    _ResourceImpl? resource = _store._map[name];
    if (resource == null) {
      resource = _LimitedResourceImpl(
          name: name, capacity: capacity, acquisitionRule: null);
      _store._map[name] = resource;
      _store._list.add(resource);
    }
    return resource;
  }

  /// Checks if a resource is available.
  ///
  /// - [name]: The name of the resource to check.
  /// - Returns: `true` if the resource is available, `false` otherwise.
  bool isAvailable(String name) {
    _ResourceImpl? resource = _store._map[name];
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
  /// - [name]: The name of the resource to acquire.
  /// - Returns: `true` if the resource was acquired, `false` otherwise.
  bool tryAcquire(String name) {
    _ResourceImpl? resource = _store._map[name];
    if (resource != null) {
      return resource.acquire(_event);
    }
    return false;
  }

  /// Acquires a resource, waiting if necessary until it becomes available.
  ///
  /// - [name]: The name of the resource to acquire.
  /// - Returns: A [Future] that completes when the resource is acquired.
  Future<void> acquire(String name) async {
    if (_event.eventCompleter != null) {
      SimDartHelper.removeCompleter(sim: _sim, completer: _event.eventCompleter!.completer);
      //TODO method or throw?
      SimDartHelper.error(
          sim: _sim,
          error:StateError("This event should be waiting. Did you forget to use 'await'?"));
      return;
    }
    _ResourceImpl? resource = _store._map[name];
    if (resource != null) {
      bool acquired = resource.acquire(_event);
      if (!acquired) {
        _sim.listener?.onEvent(
            name: _event.eventName,
            time: _sim.now,
            phase: EventPhase.yielded,
            executionHash: _event.hashCode);
        _event.buildCompleter();
        resource._waiting.add(_event);
        SimDartHelper.scheduleNextAction(sim: _sim);
          await _event.eventCompleter!.future;
        return await acquire(name);
      }
    }
  }

  /// Releases a previously acquired resource.
  ///
  /// - [name]: The name of the resource to release.
  void release(String name) {
    _ResourceImpl? resource = _store._map[name];
    if (resource != null) {
      if (resource.release(_sim, _event)) {
        if (resource._waiting.isNotEmpty) {
          EventAction waitingEvent = resource._waiting.removeAt(0);
          // Schedule a complete to resume this event in the future.
          SimDartHelper.addAction(
              sim: _sim,
              action: CompleterAction(
                  start: _sim.now,
                  complete: waitingEvent.eventCompleter!.complete,
                  order: waitingEvent.order));
          //TODO need?
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
