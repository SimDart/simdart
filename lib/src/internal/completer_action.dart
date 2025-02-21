import 'package:meta/meta.dart';
import 'package:simdart/src/internal/time_action.dart';

@internal
class CompleterAction extends TimeAction {
  CompleterAction({required super.start, required this.complete});

  final Function complete;

  @override
  void execute(void Function() onFinish) {
    complete.call();
    onFinish.call();
  }

  @override
  int secondaryCompareTo(TimeAction action) {
    return -1;
  }
}
