import 'package:meta/meta.dart';
import 'package:simdart/src/internal/event_action.dart';
import 'package:simdart/src/internal/resource.dart';
import 'package:simdart/src/resources_context.dart';
import 'package:simdart/src/simdart.dart';

@internal
class ResourcesContextImpl extends ResourcesContext {
  ResourcesContextImpl(super.sim, EventAction event)
      : _sim = sim,
        _event = event;

  final SimDart _sim;
  final EventAction _event;

  @override
  void release(String id) {
    _event.releaseResource(id);
  }

  @override
  bool tryAcquire(String id) {
    Resource? resource = SimDartHelper.getResource(sim: _sim, resourceId: id);
    if (resource != null) {
      return resource.acquire(_event);
    }
    return false;
  }

  @override
  Future<void> acquire(String id) async {
    return await _event.acquireResource(id);
  }
}
