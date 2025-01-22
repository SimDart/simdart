[![](https://img.shields.io/pub/v/simdart.svg)](https://pub.dev/packages/simdart)
[![](https://img.shields.io/badge/%F0%9F%91%8D%20and%20%E2%AD%90-are%20free-yellow)](#)

![](https://simdart.github.io/simdart-assets/simdart-text-128h.png)

---

**SimDart** is a discrete event simulation (DES) framework written in Dart.
It is designed to model and simulate systems where events occur at discrete points in time,
allowing for the analysis of complex processes and workflows.

Explore and learn more by clicking [here](https://simdart.github.io/simdart-demo/).

## Why Dart?

[Dart](https://dart.dev/) was chosen for this project due to its fast execution, single-threaded nature, and ease of use.
Dart's single-threaded model makes it particularly well-suited for discrete event simulation (DES),
as it simplifies the process of managing and processing events in sequence.
Dart's efficient handling of asynchronous tasks and event queues ensures
high performance in managing and executing events with minimal overhead.

Additionally, Dart's strong integration with [Flutter](https://flutter.dev/) makes it an ideal choice for developing
frontend applications to visualize and interact with simulations.

## Main Features

### Event Scheduling and Queue Management

- **Event Queue**  
  The core mechanism for scheduling events within the simulation. Events are placed in the queue and executed in order of their scheduled time. When resources are involved, events may wait in a queue until capacity becomes available.

- **Schedule Event at Specific Time**  
  Schedule an event to occur at a specific time. This allows events to be set to occur at precise simulation times.

- **Schedule Event After Delay**  
  Schedule an event to occur after a certain delay. This introduces a time gap between events, simulating waiting periods or delays.

- **Schedule Event Based on Interval**  
  Schedule recurring events to occur at regular intervals. This allows events to be triggered periodically, which is useful for simulations requiring regular or timed actions, such as periodic updates or repeated actions in the system.

- **Event Pausing (Wait)**  
  Temporarily pause the execution of an event for a specified duration. This is useful for simulating waiting times or delays between events in a process.

### Resources

- **Capacity-Limited Resources**
  A resource with a defined capacity, which limits how many events can access it simultaneously. When the resource is fully utilized, additional events must wait until capacity becomes available.

### Intervals

A collection of different interval types used to control event timing in simulations.

- **Fixed Interval**  
  A fixed interval where the duration between events is constant and does not change during the simulation.

- **Random Interval**  
  An interval where the duration is determined by a user-defined random function, offering variability in event timing.

- **Conditional Interval**  
  An interval where the duration depends on the state of the simulation at each step, allowing for dynamic adjustments based on conditions.

- **Probabilistic Interval**  
  An interval based on probabilistic distributions, introducing randomness with different statistical models.

  - **Uniform Distribution**  
    An interval where the duration is uniformly distributed between a minimum and maximum value, ensuring equal probability for all values within the range.

  - **Exponential Distribution**  
    An interval based on an exponential distribution, often used to model time between events in processes with constant rates.

  - **Normal (Gaussian) Distribution**  
    An interval modeled with a normal distribution, where durations are centered around a mean with a specified standard deviation, reflecting natural variance.

## Examples

### Processing events

```dart
import 'package:simdart/simdart.dart';

void main() async {
  final SimDart sim = SimDart(onTrack: (track) => print(track));

  sim.process(event: _a, name: 'A');
  sim.process(event: _b, start: 5, name: 'B');

  await sim.run();
}

void _a(EventContext context) async {
  await context.wait(10);
  context.sim.process(event: _c, delay: 1, name: 'C');
}

void _b(EventContext context) async {
  await context.wait(1);
}

void _c(EventContext context) async {
  await context.wait(10);
}
```

Output:
```
[0][A][executed]
[5][B][executed]
[6][B][resumed]
[10][A][resumed]
[11][C][executed]
[21][C][resumed]
```

### Resource capacity

```dart
import 'package:simdart/simdart.dart';

void main() async {
  final SimDart sim = SimDart(onTrack: (track) => print(track));

  sim.resources.limited(id: 'resource', capacity: 2);

  sim.process(event: _a, name: 'A1', resourceId: 'resource');
  sim.process(event: _a, name: 'A2', start: 1, resourceId: 'resource');
  sim.process(event: _a, name: 'A3', start: 2, resourceId: 'resource');
  sim.process(event: _b, name: 'B', start: 3);

  await sim.run();
}

void _a(EventContext context) async {
  await context.wait(10);
}

void _b(EventContext context) async {}
```

Output:
```
[0][A1][executed]
[1][A2][executed]
[2][A3][rejected]
[3][B][executed]
[10][A1][resumed]
[10][A3][executed]
[11][A2][resumed]
[20][A3][resumed]
```

### Repeating process

```dart
import 'package:simdart/simdart.dart';

void main() async {
  final SimDart sim = SimDart(onTrack: (track) => print(track));

  sim.repeatProcess(
          event: _a,
          start: 1,
          name: 'A',
          interval: Interval.fixed(fixedInterval: 2, untilTime: 6));

  await sim.run();
}

void _a(EventContext context) async {}
```

Output:
```
[1][A][executed]
[3][A][executed]
[5][A][executed]
```

## Upcoming Features

- **Resource Management**:
  - Upcoming support for simulating resource allocation, allowing for the management of limited resources across different events in the simulation.

- **Advanced Event Behaviors**:
  - Future enhancements will introduce more granular control over event behaviors, allowing for greater flexibility in simulating complex systems.

