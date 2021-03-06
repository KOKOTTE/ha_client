part of '../main.dart';

class EntityPicture extends StatelessWidget {

  final EdgeInsetsGeometry padding;
  final BoxFit fit;
  
  const EntityPicture({Key key, this.padding: const EdgeInsets.all(0.0), this.fit: BoxFit.cover}) : super(key: key);

  int getDefaultIconByEntityId(String entityId, String deviceClass, String state) {
    String domain = entityId.split(".")[0];
    String iconNameByDomain = MaterialDesignIcons.defaultIconsByDomains["$domain.$state"] ?? MaterialDesignIcons.defaultIconsByDomains["$domain"];
    String iconNameByDeviceClass;
    if (deviceClass != null) {
      iconNameByDeviceClass = MaterialDesignIcons.defaultIconsByDeviceClass["$domain.$deviceClass.$state"] ?? MaterialDesignIcons.defaultIconsByDeviceClass["$domain.$deviceClass"];
    }
    String iconName = iconNameByDeviceClass ?? iconNameByDomain;
    if (iconName != null) {
      return MaterialDesignIcons.iconsDataMap[iconName] ?? 0;
    } else {
      return 0;
    }
  }

  Widget buildIcon(EntityWrapper data, BuildContext context) {
    if (data == null) {
      return null;
    }
    String iconName = data.icon;
    int iconCode = 0;
    if (iconName.length > 0) {
      iconCode = MaterialDesignIcons.getIconCodeByIconName(iconName);
    } else {
      iconCode = getDefaultIconByEntityId(data.entity.entityId,
          data.entity.deviceClass, data.entity.state); //
    }
    Widget iconPicture = Container(
      child: Center(
        child: Icon(
          IconData(iconCode, fontFamily: 'Material Design Icons'),
          size: Sizes.largeIconSize,
          color: HAClientTheme().getOffStateColor(context),
        )
      )
    );
    
    
    if (data.entityPicture != null) {
      return CachedNetworkImage(
        imageUrl: data.entityPicture,
        fit: this.fit,
        errorWidget: (context, _, __) => iconPicture,
        placeholder: (context, _) => iconPicture,
      );
    }
    
    return iconPicture;
  }

  @override
  Widget build(BuildContext context) {
    final EntityWrapper entityWrapper = EntityModel.of(context).entityWrapper;
    return Padding(
      padding: padding,
      child: buildIcon(
          entityWrapper,
          context
      ),
    );
  }
}