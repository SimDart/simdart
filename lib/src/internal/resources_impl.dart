import 'package:meta/meta.dart';
import 'package:simdart/src/internal/resource.dart';
import 'package:simdart/src/resources.dart';
import 'package:simdart/src/simdart.dart';

@internal
class ResourcesImpl implements Resources {
  ResourcesImpl(SimDart sim) : _sim = sim;

  final SimDart _sim;

  @override
  void limited({required String id, int capacity = 1}) {
    SimDartHelper.addResource(
        sim: _sim,
        resourceId: id,
        create: () => LimitedResource(id: id, capacity: capacity));
  }

  @override
  bool isAvailable(String id) {
    Resource? resource = SimDartHelper.getResource(sim: _sim, resourceId: id);
    if (resource != null) {
      return resource.isAvailable();
    }
    return false;
  }
}
