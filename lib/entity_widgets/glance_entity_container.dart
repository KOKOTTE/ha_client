part of '../main.dart';

class GlanceEntityContainer extends StatelessWidget {

  final bool showName;
  final bool showState;
  final bool nameInTheBottom;
  final double iconSize;
  final double nameFontSize;
  final bool wordsWrapInName;

  GlanceEntityContainer({
    Key key,
    @required this.showName,
    @required this.showState,
    this.nameInTheBottom: false,
    this.iconSize: Sizes.iconSize,
    this.nameFontSize: Sizes.smallFontSize,
    this.wordsWrapInName: false
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final EntityWrapper entityWrapper = EntityModel.of(context).entityWrapper;
    List<Widget> result = [];
    if (!nameInTheBottom) {
      if (showName) {
        result.add(_buildName());
      }
    } else {
      if (showState) {
        result.add(_buildState());
      }
    }
    result.add(
      EntityIcon(
        padding: EdgeInsets.all(0.0),
        iconSize: iconSize,
      )
    );
    if (!nameInTheBottom) {
      if (showState) {
        result.add(_buildState());
      }
    } else {
      result.add(_buildName());
    }

    return Center(
      child: InkResponse(
        child: ConstrainedBox(
          constraints: BoxConstraints(minWidth: Sizes.iconSize * 2),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            //mainAxisAlignment: MainAxisAlignment.start,
            //crossAxisAlignment: CrossAxisAlignment.center,
            children: result,
          ),
        ),
        onTap: () => entityWrapper.handleTap(),
        onLongPress: () => entityWrapper.handleHold(),
      ),
    );
  }

  Widget _buildName() {
    return EntityName(
      padding: EdgeInsets.only(bottom: Sizes.rowPadding),
      textOverflow: TextOverflow.ellipsis,
      wordsWrap: wordsWrapInName,
      textAlign: TextAlign.center,
      fontSize: nameFontSize,
    );
  }

  Widget _buildState() {
    return SimpleEntityState(
      textAlign: TextAlign.center,
      expanded: false,
      maxLines: 1,
      padding: EdgeInsets.only(top: Sizes.rowPadding),
    );
  }
}