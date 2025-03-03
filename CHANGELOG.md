## 0.4.0

* Added
  * `stop` method in `SimContext`.
  * Error handling.

## 0.3.0

* Access the list of created resources.
* Added
  * `runState` getter to determine whether the simulation has not started, is running, or has completed.
  * `stop` method to manually stop the simulation before it completes.
  * Listener to receive data throughout the simulation.

## 0.2.0

* Setting to determine how often `Future.delayed` is used instead of `Future.microtask` during event execution to allow GUI refresh.
* Adding numeric properties and counter.
* Allow creating new resources during simulation.
* Methods for acquiring and releasing resources within events.

## 0.1.0

* Initial release
  * Discrete event processing.
  * Event scheduling, execution, waiting, and repetition.
  * Intervals management.
  * Resources
    * Capacity limit