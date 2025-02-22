import 'package:simdart/src/internal/resources_impl.dart';

abstract class ResourcesContext extends ResourcesImpl {
  ResourcesContext(super.sim);

  /// Releases a previously acquired resource.
  ///
  /// - [id]: The id of the resource to release.
  void release(String id);

  /// Tries to acquire a resource immediately.
  ///
  /// - [id]: The id of the resource to acquire.
  /// - Returns: `true` if the resource was acquired, `false` otherwise.
  bool tryAcquire(String id);

  /// Acquires a resource, waiting if necessary until it becomes available.
  ///
  /// - [id]: The id of the resource to acquire.
  /// - Returns: A [Future] that completes when the resource is acquired.
  Future<void> acquire(String id);
}
