part of '../main.dart';

class CardHeaderWidget extends StatelessWidget {

  final String name;
  final Widget trailing;
  final Widget subtitle;

  const CardHeaderWidget({Key key, this.name, this.trailing, this.subtitle}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var result;
    if ((name != null) && (name.trim().length > 0)) {
      result = new ListTile(
        trailing: trailing,
        subtitle: subtitle,
        title: Text("$name",
            textAlign: TextAlign.left,
            overflow: TextOverflow.ellipsis,
            style: new TextStyle(fontSize: Sizes.mediumFontSize)),
      );
    } else {
      result = new Container(width: 0.0, height: 0.0);
    }
    return result;
  }

}