part of '../../main.dart';

class CameraEntity extends Entity {

  static const SUPPORT_ON_OFF = 1;

  CameraEntity(Map rawData, String webHost) : super(rawData, webHost);

  bool get supportOnOff => ((supportedFeatures &
  CameraEntity.SUPPORT_ON_OFF) ==
      CameraEntity.SUPPORT_ON_OFF);

  @override
  Widget _buildAdditionalControlsForPage(BuildContext context) {
    return CameraStreamView();
  }
}