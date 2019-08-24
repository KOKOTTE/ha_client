part of '../../main.dart';

class AutomationEntity extends Entity {
  AutomationEntity(Map rawData, String webHost) : super(rawData, webHost);


  @override
  Widget _buildStatePart(BuildContext context) {
    return SwitchStateWidget();
  }

  @override
  Widget _buildAdditionalControlsForPage(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.max,
      children: <Widget>[
        FlatServiceButton(
          serviceDomain: domain,
          entityId: entityId,
          text: "TRIGGER",
          serviceName: "trigger",
        )
      ],
    );
  }
}