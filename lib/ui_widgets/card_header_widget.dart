part of '../main.dart';

class CardHeaderWidget extends StatelessWidget {

  final String name;

  const CardHeaderWidget({Key key, this.name}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var result;
    if ((name != null) && (name.trim().length > 0)) {
      result = new ListTile(
        title: Text("$name",
            textAlign: TextAlign.left,
            overflow: TextOverflow.ellipsis,
            style: new TextStyle(fontWeight: FontWeight.bold, fontSize: Sizes.largeFontSize)),
      );
    } else {
      result = new Container(width: 0.0, height: 0.0);
    }
    return result;
  }

}