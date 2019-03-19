part of '../main.dart';

class TimerEntity extends Entity {
  TimerEntity(Map rawData, String webHost) : super(rawData, webHost);

  Duration duration;

  @override
  void update(Map rawData, String webHost) {
    super.update(rawData, webHost);
    String durationSource = "${attributes["duration"]}";
    if (durationSource != null && durationSource.isNotEmpty) {
      try {
        List<String> durationList = durationSource.split(":");
        if (durationList.length == 1) {
          duration = Duration(seconds: int.tryParse(durationList[0] ?? 0));
        } else if (durationList.length == 2) {
          duration = Duration(
              hours: int.tryParse(durationList[0]) ?? 0,
              minutes: int.tryParse(durationList[1]) ?? 0
          );
        } else if (durationList.length == 3) {
          duration = Duration(
              hours: int.tryParse(durationList[0]) ?? 0,
              minutes: int.tryParse(durationList[1]) ?? 0,
              seconds: int.tryParse(durationList[2]) ?? 0
          );
        } else {
          Logger.e("Strange $entityId duration format: $durationSource");
          duration = Duration(seconds: 0);
        }
      } catch (e) {
        Logger.e("Error parsing duration for $entityId: ${e.toString()}");
        duration = Duration(seconds: 0);
      }
    } else {
      duration = Duration(seconds: 0);
    }
  }

  @override
  Widget _buildStatePart(BuildContext context) {
    return TimerState();
  }
}