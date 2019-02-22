part of '../../main.dart';

class MediaPlayerWidget extends StatelessWidget {
  
  @override
  Widget build(BuildContext context) {
    final EntityModel entityModel = EntityModel.of(context);
    final MediaPlayerEntity entity = entityModel.entityWrapper.entity;
    //TheLogger.debug("stop: ${entity.supportStop}, seek: ${entity.supportSeek}");
    return Column(
      children: <Widget>[
        Stack(
          alignment: AlignmentDirectional.topEnd,
          children: <Widget>[
            _buildImage(entity),
            Positioned(
              bottom: 0.0,
              left: 0.0,
              right: 0.0,
              child: Container(
                color: Colors.black45,
                child: _buildState(entity),
              ),
            ),
            Positioned(
                bottom: 0.0,
                left: 0.0,
                right: 0.0,
                child: MediaPlayerProgressWidget()
            )
          ],
        ),
        MediaPlayerPlaybackControls()
      ]
    );
  }

  Widget _buildState(MediaPlayerEntity entity) {
    TextStyle style = TextStyle(
        fontSize: 14.0,
        color: Colors.white,
        fontWeight: FontWeight.normal,
        height: 1.2
    );
    List<Widget> states = [];
    states.add(Text("${entity.displayName}", style: style));
    String state = entity.state;
    if (state == null || state == EntityState.off || state == EntityState.unavailable || state == EntityState.idle) {
      states.add(Text("${entity.state}", style: style.apply(fontSizeDelta: 4.0),));
    }
    if (entity.attributes['media_title'] != null) {
      states.add(Text(
        "${entity.attributes['media_title']}",
        style: style.apply(fontSizeDelta: 6.0, fontWeightDelta: 50),
        maxLines: 1,
        softWrap: true,
        overflow: TextOverflow.ellipsis,
      ));
    }
    if (entity.attributes['media_content_type'] == "music") {
      states.add(Text("${entity.attributes['media_artist'] ?? entity.attributes['app_name']}", style: style.apply(fontSizeDelta: 4.0),));
    } else if (entity.attributes['app_name'] != null) {
      states.add(Text("${entity.attributes['app_name']}", style: style.apply(fontSizeDelta: 4.0),));
    }
    return Padding(
      padding: EdgeInsets.fromLTRB(Sizes.leftWidgetPadding, Sizes.rowPadding, Sizes.rightWidgetPadding, Sizes.rowPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: states,
      ),
    );
  }

  Widget _buildImage(MediaPlayerEntity entity) {
    String state = entity.state;
    if (homeAssistantWebHost != null && entity.entityPicture != null && state != EntityState.off && state != EntityState.unavailable && state != EntityState.idle) {
      return Container(
        color: Colors.black,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Flexible(
              child: Image(
                image: CachedNetworkImageProvider("$homeAssistantWebHost${entity.entityPicture}"),
                height: 240.0,
                //width: 320.0,
                fit: BoxFit.contain,
              ),
            )
          ],
        ),
      );
    } else {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Icon(
            MaterialDesignIcons.getIconDataFromIconName("mdi:movie"),
            size: 150.0,
            color: EntityColor.stateColor("$state"),
          )
        ],
      );
      /*return Container(
        color: Colors.blue,
        height: 80.0,
      );*/
    }
  }
}

class MediaPlayerPlaybackControls extends StatelessWidget {

  final bool showMenu;
  final bool showStop;

  const MediaPlayerPlaybackControls({Key key, this.showMenu: true, this.showStop: false}) : super(key: key);


  void _setPower(MediaPlayerEntity entity) {
    if (entity.state != EntityState.unavailable && entity.state != EntityState.unknown) {
      if (entity.state == EntityState.off) {
        Logger.d("${entity.entityId} turn_on");
        eventBus.fire(new ServiceCallEvent(
            entity.domain, "turn_on", entity.entityId,
            null));
      } else {
        Logger.d("${entity.entityId} turn_off");
        eventBus.fire(new ServiceCallEvent(
            entity.domain, "turn_off", entity.entityId,
            null));
      }
    }
  }

  void _callAction(MediaPlayerEntity entity, String action) {
    Logger.d("${entity.entityId} $action");
    eventBus.fire(new ServiceCallEvent(
        entity.domain, "$action", entity.entityId,
        null));
  }

  @override
  Widget build(BuildContext context) {
    final MediaPlayerEntity entity = EntityModel.of(context).entityWrapper.entity;
    List<Widget> result = [];
    if (entity.supportTurnOn || entity.supportTurnOff) {
      result.add(
          IconButton(
            icon: Icon(Icons.power_settings_new),
            onPressed: () => _setPower(entity),
            iconSize: Sizes.iconSize,
          )
      );
    } else {
      result.add(
          Container(
            width: Sizes.iconSize,
          )
      );
    }
    List <Widget> centeredControlsChildren = [];
    if (entity.supportPreviousTrack && entity.state != EntityState.off && entity.state != EntityState.unavailable) {
      centeredControlsChildren.add(
          IconButton(
            icon: Icon(Icons.skip_previous),
            onPressed: () => _callAction(entity, "media_previous_track"),
            iconSize: Sizes.iconSize,
          )
      );
    }
    if (entity.supportPlay || entity.supportPause) {
      if (entity.state == EntityState.playing) {
        centeredControlsChildren.add(
            IconButton(
              icon: Icon(Icons.pause_circle_filled),
              color: Colors.blue,
              onPressed: () => _callAction(entity, "media_pause"),
              iconSize: Sizes.iconSize*1.8,
            )
        );
      } else if (entity.state == EntityState.paused || entity.state == EntityState.idle) {
        centeredControlsChildren.add(
            IconButton(
              icon: Icon(Icons.play_circle_filled),
              color: Colors.blue,
              onPressed: () => _callAction(entity, "media_play"),
              iconSize: Sizes.iconSize*1.8,
            )
        );
      } else {
        centeredControlsChildren.add(
            Container(
              width: Sizes.iconSize*1.8,
              height: Sizes.iconSize*2.0,
            )
        );
      }
    }
    if (entity.supportNextTrack && entity.state != EntityState.off && entity.state != EntityState.unavailable) {
      centeredControlsChildren.add(
          IconButton(
            icon: Icon(Icons.skip_next),
            onPressed: () => _callAction(entity, "media_next_track"),
            iconSize: Sizes.iconSize,
          )
      );
    }
    if (centeredControlsChildren.isNotEmpty) {
      result.add(
          Expanded(
              child: Row(
                mainAxisAlignment: showMenu ? MainAxisAlignment.center : MainAxisAlignment.end,
                children: centeredControlsChildren,
              )
          )
      );
    } else {
      result.add(
          Expanded(
            child: Container(
              height: 10.0,
            ),
          )
      );
    }
    if (showMenu) {
      result.add(
          IconButton(
              icon: Icon(MaterialDesignIcons.getIconDataFromIconName(
                  "mdi:dots-vertical")),
              onPressed: () => eventBus.fire(new ShowEntityPageEvent(entity))
          )
      );
    } else if (entity.supportStop && entity.state != EntityState.off && entity.state != EntityState.unavailable) {
      result.add(
          IconButton(
              icon: Icon(Icons.stop),
              onPressed: () => _callAction(entity, "media_stop")
          )
      );
    }
    return Row(
      children: result,
      mainAxisAlignment: MainAxisAlignment.center,
    );
  }

}

class MediaPlayerControls extends StatefulWidget {
  @override
  _MediaPlayerControlsState createState() => _MediaPlayerControlsState();
}

class _MediaPlayerControlsState extends State<MediaPlayerControls> {

  double _newVolumeLevel;
  bool _changedHere = false;
  String _newSoundMode;
  String _newSource;

  void _setVolume(double value, String entityId) {
    setState(() {
      _changedHere = true;
      _newVolumeLevel = value;
      eventBus.fire(ServiceCallEvent("media_player", "volume_set", entityId, {"volume_level": value}));
    });
  }

  void _setVolumeMute(bool isMuted, String entityId) {
    eventBus.fire(ServiceCallEvent("media_player", "volume_mute", entityId, {"is_volume_muted": isMuted}));
  }

  void _setVolumeUp(String entityId) {
    eventBus.fire(ServiceCallEvent("media_player", "volume_up", entityId, null));
  }

  void _setVolumeDown(String entityId) {
    eventBus.fire(ServiceCallEvent("media_player", "volume_down", entityId, null));
  }

  void _setSoundMode(String value, String entityId) {
    setState(() {
      _newSoundMode = value;
      _changedHere = true;
      eventBus.fire(ServiceCallEvent("media_player", "select_sound_mode", entityId, {"sound_mode": "$value"}));
    });
  }

  void _setSource(String source, String entityId) {
    setState(() {
      _newSource = source;
      _changedHere = true;
      eventBus.fire(ServiceCallEvent("media_player", "select_source", entityId, {"source": "$source"}));
    });
  }

  @override
  Widget build(BuildContext context) {
    final MediaPlayerEntity entity = EntityModel.of(context).entityWrapper.entity;
    List<Widget> children = [
      MediaPlayerPlaybackControls(
        showMenu: false,
      )
    ];
    if (entity.state != EntityState.off && entity.state != EntityState.unknown && entity.state != EntityState.unavailable) {
      Widget muteWidget;
      Widget volumeStepWidget;
      if (entity.supportVolumeMute) {
        bool isMuted = entity.attributes["is_volume_muted"] ?? false;
        muteWidget =
            IconButton(
                icon: Icon(isMuted ? Icons.volume_off : Icons.volume_up),
                onPressed: () => _setVolumeMute(!isMuted, entity.entityId)
            );
      } else {
        muteWidget = Container(width: 0.0, height: 0.0,);
      }
      if (entity.supportVolumeStep) {
        volumeStepWidget = Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            IconButton(
                icon: Icon(MaterialDesignIcons.getIconDataFromIconName("mdi:plus")),
                onPressed: () => _setVolumeUp(entity.entityId)
            ),
            IconButton(
                icon: Icon(MaterialDesignIcons.getIconDataFromIconName("mdi:minus")),
                onPressed: () => _setVolumeDown(entity.entityId)
            )
          ],
        );
      } else {
        volumeStepWidget = Container(width: 0.0, height: 0.0,);
      }
      if (entity.supportVolumeSet) {
        if (!_changedHere) {
          _newVolumeLevel = entity._getDoubleAttributeValue("volume_level");
        } else {
          _changedHere = false;
        }
        children.add(
            UniversalSlider(
              leading: muteWidget,
              closing: volumeStepWidget,
              title: "Volume",
              onChanged: (value) {
                setState(() {
                  _changedHere = true;
                  _newVolumeLevel = value;
                });
              },
              value: _newVolumeLevel,
              onChangeEnd: (value) => _setVolume(value, entity.entityId),
              max: 1.0,
              min: 0.0,
            )
        );
      } else {
        children.add(Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            muteWidget,
            volumeStepWidget
          ],
        ));
      }

      if (entity.supportSelectSoundMode && entity.soundModeList != null) {
        if (!_changedHere) {
          _newSoundMode = entity.attributes["sound_mode"];
        } else {
          _changedHere = false;
        }
        children.add(
          ModeSelectorWidget(
              options: entity.soundModeList,
              caption: "Sound mode",
              value: _newSoundMode,
              onChange: (value) => _setSoundMode(value, entity.entityId)
          )
        );
      }

      if (entity.supportSelectSource && entity.sourceList != null) {
        if (!_changedHere) {
          _newSource = entity.attributes["source"];
        } else {
          _changedHere = false;
        }
        children.add(
            ModeSelectorWidget(
                options: entity.sourceList,
                caption: "Source",
                value: _newSource,
                onChange: (value) => _setSource(value, entity.entityId)
            )
        );
      }

    }
    return Column(
      children: children,
    );
  }

}

class MediaPlayerProgressWidget extends StatefulWidget {
  @override
  _MediaPlayerProgressWidgetState createState() => _MediaPlayerProgressWidgetState();
}

class _MediaPlayerProgressWidgetState extends State<MediaPlayerProgressWidget> {

  Timer _timer;

  @override
  Widget build(BuildContext context) {
    final EntityModel entityModel = EntityModel.of(context);
    final MediaPlayerEntity entity = entityModel.entityWrapper.entity;
    double progress;
    try {
      DateTime lastUpdated = DateTime.parse(
          entity.attributes["media_position_updated_at"]).toLocal();
      Duration duration = Duration(seconds: entity._getIntAttributeValue("media_duration") ?? 1);
      Duration position = Duration(seconds: entity._getIntAttributeValue("media_position") ?? 0);
      int currentPosition = position.inSeconds;
      if (entity.state == EntityState.playing) {
        _timer?.cancel();
        _timer = Timer(Duration(seconds: 1), () {
          setState(() {
          });
        });
        int differenceInSeconds = DateTime
            .now()
            .difference(lastUpdated)
            .inSeconds;
        currentPosition = currentPosition + differenceInSeconds;
      } else {
        _timer?.cancel();
      }
      progress = currentPosition / duration.inSeconds;
      return LinearProgressIndicator(
        value: progress,
        backgroundColor: Colors.black45,
        valueColor: AlwaysStoppedAnimation<Color>(EntityColor.stateColor(EntityState.on)),
      );
    } catch (e) {
      _timer?.cancel();
      progress = 0.0;
    }
    return LinearProgressIndicator(
      value: progress,
      backgroundColor: Colors.black45,
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

}