import 'dart:async';

import 'package:meta/meta.dart';
import 'package:simdart/src/simdart.dart';

/// Represents the state of a resource in relation to an event.
///
/// This class encapsulates the identifier of the resource and a flag
/// indicating whether the resource has been acquired by the event.
class ResourceState {
  /// The unique identifier of the resource.
  final String? id;

  /// Indicates whether the resource has been acquired by the event.
  bool _acquired = false;
  bool get acquired => _acquired;

  /// Creates a new [ResourceState] instance.
  ///
  /// [id] is the unique identifier of the resource.
  ResourceState({required this.id});
}

@internal
class ResourceStateHelper {
  static setAcquired(
      {required ResourceState resourceState, required bool acquired}) {
    resourceState._acquired = acquired;
  }
}

/// The event to be executed.
///
/// A function that represents an event in the simulation. It receives an
/// [EventContext] that provides data about the event's execution state and context.
typedef Event = void Function(EventContext context);

/// Represents the type of an event in the simulation.
///
/// This enum categorizes events based on their purpose and role within
/// the simulation lifecycle. It helps distinguish between internal
/// and regular events.
///
/// - [releaser]: Events responsible for releasing resources or
///   managing cleanup actions. These are typically generated internally
///   and are not directly tied to user-defined actions.
///
/// - [scheduler]: Internal events created by the simulation engine
///   to handle scheduled actions, such as delayed execution of a task or
///   resource management. These events are not explicitly defined by the
///   user but are crucial for maintaining the simulation timeline.
///
/// - [regular]: User-defined events that represent the primary actions
///   and processes in the simulation. These events are explicitly scheduled
///   and executed based on user logic.
enum EventType {
  /// Internal event scheduled by the engine for deferred or future actions.
  scheduler,

  /// User-defined event representing core simulation logic or processes.
  regular,
}

/// Represents the context of an event in the simulation.
///
/// This class encapsulates the information and state of an event being executed
/// within the simulation.
class EventContext {
  /// The name of the event.
  final String? _eventName;
  String get eventName => _eventName ?? hashCode.toString();

  /// The pptional resource that the event may require
  final ResourceState? resource;

  /// The scheduled start time of the event.
  int _start;

  /// Gets the scheduled start time of the event.
  int get start => _start;

  /// The event to be executed.
  final Event _event;

  /// Internal handler for resuming a waiting event.
  void Function()? _resume;

  /// The simulation instance managing this event.
  final SimDart sim;

  final EventType type;

  /// Creates an event context. This constructor is for internal use only.
  EventContext._(
      {required this.sim,
      required String? eventName,
      required int start,
      required this.type,
      required String? resourceId,
      required Event event})
      : _eventName = eventName,
        _start = start,
        _event = event,
        resource = resourceId != null ? ResourceState(id: resourceId) : null;

  /// Pauses the execution of the event for the specified [delay] in simulation time.
  ///
  /// The event is re-added to the simulation's event queue and will resume after
  /// the specified delay has passed.
  ///
  /// Throws an [ArgumentError] if the delay is negative.
  Future<void> wait(int delay) async {
    if (_resume != null) {
      return;
    }

    _start = sim.now + delay;
    SimDartHelper.addEvent(sim: sim, event: this);

    final Completer<void> resume = Completer<void>();
    _resume = () {
      resume.complete();
      _resume = null;
    };
    await resume.future;
  }
}

/// A helper class to access private members of the [EventContext] class.
///
/// This class is marked as internal and should only be used within the library.
@internal
class EventContextHelper {
  /// Creates a new [EventContext] instance using its private constructor.
  static EventContext build(
      {required SimDart sim,
      required String? name,
      required int start,
      required String? resourceId,
      required EventType type,
      required Event event}) {
    return EventContext._(
        sim: sim,
        eventName: name,
        start: start,
        event: event,
        type: type,
        resourceId: resourceId);
  }

  /// Retrieves the private `_resume` function of an [EventContext].
  static Function? getResume({required EventContext event}) {
    return event._resume;
  }

  /// Calls the private `_event` function of an [EventContext].
  static Future<void> executeEvent({required EventContext event}) async {
    return event._event(event);
  }

  static void setStart({required EventContext event, required int start}) {
    event._start = start;
  }
}
