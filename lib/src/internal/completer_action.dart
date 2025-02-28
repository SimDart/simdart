import 'package:meta/meta.dart';
import 'package:simdart/src/internal/time_action.dart';

@internal
class CompleterAction extends TimeAction {
  CompleterAction(
      {required super.start, required this.complete, required super.order});

  final Function complete;

  @override
  void execute() {
    complete.call();
  }

  @override
  void dispose() {}
}
