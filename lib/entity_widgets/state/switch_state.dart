part of '../../main.dart';

class SwitchStateWidget extends StatefulWidget {
  @override
  _SwitchStateWidgetState createState() => _SwitchStateWidgetState();
}

class _SwitchStateWidgetState extends State<SwitchStateWidget> {

  String newState;
  bool updatedHere = false;

  @override
  void initState() {
    super.initState();
  }

  void _setNewState(newValue, Entity entity) {
    setState(() {
      newState = newValue ? EntityState.on : EntityState.off;
      updatedHere = true;
    });
    Timer(Duration(seconds: 2), (){
      setState(() {
        newState = entity.state;
        updatedHere = true;
        TheLogger.debug("Timer@!!");
      });
    });
    eventBus.fire(new ServiceCallEvent(
        entity.domain, (newValue as bool) ? "turn_on" : "turn_off", entity.entityId, null));
  }

  @override
  Widget build(BuildContext context) {
    final entityModel = EntityModel.of(context);
    final entity = entityModel.entityWrapper.entity;
    if (!updatedHere) {
      newState = entity.state;
    } else {
      updatedHere = false;
    }
    if (entity.state == EntityState.unavailable || entity.state == EntityState.unknown) {
      return SimpleEntityState();
    } else if ((entity.attributes["assumed_state"] == null) || (entity.attributes["assumed_state"] == false)) {
      return SizedBox(
        height: 32.0,
        child: Switch(
          value: newState == EntityState.on,
          onChanged: ((switchState) {
            _setNewState(switchState, entity);
          }),
        )
      );
    } else {
      return SizedBox(
        height: 32.0,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            IconButton(
              onPressed: () => _setNewState(false, entity),
              icon: Icon(MaterialDesignIcons.createIconDataFromIconName("mdi:flash-off")),
              color: newState == EntityState.on ? Colors.black : Colors.blue,
              iconSize: Sizes.iconSize,
            ),
            IconButton(
                onPressed: () => _setNewState(true, entity),
                icon: Icon(MaterialDesignIcons.createIconDataFromIconName("mdi:flash")),
                color: newState == EntityState.on ? Colors.blue : Colors.black,
                iconSize: Sizes.iconSize
            )
          ],
        ),
      );
    }
  }
}