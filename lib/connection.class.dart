part of 'main.dart';

class Connection {

  static final Connection _instance = Connection._internal();

  factory Connection() {
    return _instance;
  }

  Connection._internal();

  String _domain;
  String _port;
  String displayHostname;
  String _webSocketAPIEndpoint;
  String httpWebHost;
  String _token;
  String _tempToken;
  String oauthUrl;
  String deviceName;
  bool useLovelace = true;
  bool settingsLoaded = false;
  bool get isAuthenticated => _token != null;
  StreamSubscription _socketSubscription;
  Duration connectTimeout = Duration(seconds: 15);

  bool isConnected = false;

  var onStateChangeCallback;

  IOWebSocketChannel _socket;

  int _currentMessageId = 0;
  Map<String, Completer> _messageResolver = {};

  Future init({bool loadSettings, bool forceReconnect: false}) async {
    Completer completer = Completer();
    if (loadSettings) {
      Logger.e("Loading settings...");
      SharedPreferences prefs = await SharedPreferences.getInstance();
      useLovelace = prefs.getBool('use-lovelace') ?? true;
      _domain = prefs.getString('hassio-domain');
      _port = prefs.getString('hassio-port');
      displayHostname = "$_domain:$_port";
      _webSocketAPIEndpoint = "${prefs.getString('hassio-protocol')}://$_domain:$_port/api/websocket";
      httpWebHost = "${prefs.getString('hassio-res-protocol')}://$_domain:$_port";
      //_token = prefs.getString('hassio-token');
      final storage = new FlutterSecureStorage();
      try {
        _token = await storage.read(key: "hacl_llt");
        Logger.e("Long-lived token read successful");
      } catch (e) {
        Logger.e("Cannt read secure storage. Need to relogin.");
        _token = null;
        await storage.delete(key: "hacl_llt");
      }
      DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
      AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
      deviceName = androidInfo.model;
      oauthUrl = "$httpWebHost/auth/authorize?client_id=${Uri.encodeComponent('http://ha-client.homemade.systems/')}&redirect_uri=${Uri.encodeComponent('http://ha-client.homemade.systems/service/auth_callback.html')}";
      settingsLoaded = true;
    }
    if ((_domain == null) || (_port == null) ||
        (_domain.isEmpty) || (_port.isEmpty)) {
      completer.completeError({"errorCode": 5, "errorMessage": "Check connection settings"});
    }

    if (_token == null) {
      AuthManager().getTempToken(
          oauthUrl: oauthUrl
      ).then((token) {
        Logger.d("Token from AuthManager recived");
        _tempToken = token;
        _doConnect(completer: completer, forceReconnect: forceReconnect);
      }).catchError((e) {
        completer.completeError(e);
      });
    } else {
      _doConnect(completer: completer, forceReconnect: forceReconnect);
    }

    return completer.future;
  }

  void _doConnect({Completer completer, bool forceReconnect}) {
    if (forceReconnect || !isConnected) {
      _connect().timeout(connectTimeout, onTimeout: () {
        _disconnect().then((_) {
          completer?.completeError(
              {"errorCode": 1, "errorMessage": "Connection timeout"});
        });
      }).then((_) => completer?.complete()).catchError((e) {
        completer?.completeError(e);
      });
    } else {
      completer?.complete();
    }
  }

  Completer connecting;

  Future _connect() async {
    if (connecting != null && !connecting.isCompleted) {
      Logger.w("Previous connection attempt pending...");
      return connecting.future;
    } else {
      connecting = Completer();
      await _disconnect();
      Logger.d("Socket connecting...");
      _socket = IOWebSocketChannel.connect(
          _webSocketAPIEndpoint, pingInterval: Duration(seconds: 15));
      _socketSubscription = _socket.stream.listen(
              (message) {
            isConnected = true;
            var data = json.decode(message);
            if (data["type"] == "auth_required") {
              Logger.d("[Received] <== ${data.toString()}");
              _authenticate().then((_) => connecting.complete()).catchError((
                  e) {
                if (!connecting.isCompleted) connecting.completeError(e);
              });
            } else if (data["type"] == "auth_ok") {
              Logger.d("[Received] <== ${data.toString()}");
              _messageResolver["auth"]?.complete();
              _messageResolver.remove("auth");
              if (!connecting.isCompleted) connecting.complete();
            } else if (data["type"] == "auth_invalid") {
              Logger.d("[Received] <== ${data.toString()}");
              _messageResolver["auth"]?.completeError(
                  {"errorCode": 62, "errorMessage": "${data["message"]}"});
              _messageResolver.remove("auth");
              logout().then((_) {
                if (!connecting.isCompleted) connecting.completeError(
                    {"errorCode": 62, "errorMessage": "${data["message"]}"});
              });
            } else {
              _handleMessage(data);
            }
          },
          cancelOnError: true,
          onDone: () => _handleSocketClose(connecting),
          onError: (e) => _handleSocketError(e, connecting)
      );
      return connecting.future;
    }
  }

  Future _disconnect() {
    Completer completer = Completer();
    if (!isConnected) {
      completer.complete();
    } else {
      isConnected = false;
      List<Future> fl = [];
      Logger.d("Socket disconnecting...");
      if (_socketSubscription != null) {
        fl.add(_socketSubscription.cancel());
      }
      if (_socket != null && _socket.sink != null &&
          _socket.closeCode == null) {
        fl.add(_socket.sink.close().timeout(Duration(seconds: 3)));
      }
      Future.wait(fl).whenComplete(() => completer.complete());
    }
    return completer.future;
  }

  _handleMessage(data) {
    if (data["type"] == "result") {
      if (data["id"] != null && data["success"]) {
        Logger.d("[Received] <== Request id ${data['id']} was successful");
        _messageResolver["${data["id"]}"]?.complete(data["result"]);
      } else if (data["id"] != null) {
        Logger.e("[Received] <== Error received on request id ${data['id']}: ${data['error']}");
        _messageResolver["${data["id"]}"]?.completeError({"errorMessage": "${data['error']["message"]}"});
      }
      _messageResolver.remove("${data["id"]}");
    } else if (data["type"] == "event") {
      if ((data["event"] != null) && (data["event"]["event_type"] == "state_changed")) {
        Logger.d("[Received] <== ${data['type']}.${data["event"]["event_type"]}: ${data["event"]["data"]["entity_id"]}");
        onStateChangeCallback(data["event"]["data"]);
      } else if (data["event"] != null) {
        Logger.w("Unhandled event type: ${data["event"]["event_type"]}");
      } else {
        Logger.e("Event is null: $data");
      }
    } else {
      Logger.d("[Received unhandled] <== ${data.toString()}");
    }
  }

  void _handleSocketClose(Completer connectionCompleter) {
    Logger.d("Socket disconnected.");
    if (!connectionCompleter.isCompleted) {
      isConnected = false;
      connectionCompleter.completeError({"errorCode": 82, "errorMessage": "Disconnected"});
    } else {
      _disconnect().then((_) {
        Timer(Duration(seconds: 5), () {
          Logger.d("Trying to reconnect...");
          _connect().catchError((e) {
            isConnected = false;
            eventBus.fire(ShowErrorEvent("Unable to connect to Home Assistant", 81));
          });
        });
      });
    }
  }

  void _handleSocketError(e, Completer connectionCompleter) {
    Logger.e("Socket stream Error: $e");
    if (!connectionCompleter.isCompleted) {
      isConnected = false;
      connectionCompleter.completeError({"errorCode": 81, "errorMessage": "Unable to connect to Home Assistant"});
    } else {
      _disconnect().then((_) {
        Timer(Duration(seconds: 5), () {
          Logger.d("Trying to reconnect...");
          _connect().catchError((e) {
            isConnected = false;
            eventBus.fire(ShowErrorEvent("Unable to connect to Home Assistant", 81));
          });
        });
      });
    }
  }

  Future _authenticate() {
    Completer completer = Completer();
    if (_token != null) {
      Logger.d( "Long-lived token exist");
      Logger.d( "[Sending] ==> auth request");
      sendSocketMessage(
          type: "auth",
          additionalData: {"access_token": "$_token"},
          auth: true
      ).then((_) {
        completer.complete();
      }).catchError((e) => completer.completeError(e));
    } else if (_tempToken != null) {
      Logger.d("We have temp token. Loging in...");
      sendSocketMessage(
          type: "auth",
          additionalData: {"access_token": "$_tempToken"},
          auth: true
      ).then((_) {
        Logger.d("Requesting long-lived token...");
        _getLongLivedToken().then((_) {
          completer.complete();
        }).catchError((e) {
          Logger.e("Can't get long-lived token: $e");
          throw e;
        });
      }).catchError((e) => completer.completeError(e));
    } else {
      completer.completeError({"errorCode": 63, "errorMessage": "General login error"});
    }
    return completer.future;
  }

  Future logout() {
    Completer completer = Completer();
    _disconnect().whenComplete(() {
      _token = null;
      _tempToken = null;
      final storage = new FlutterSecureStorage();
      storage.delete(key: "hacl_llt").whenComplete((){
        completer.complete();
      });
    });
    return completer.future;
  }

  Future _getLongLivedToken() {
    Completer completer = Completer();
    sendSocketMessage(type: "auth/long_lived_access_token", additionalData: {"client_name": "HA Client app ${DateTime.now().millisecondsSinceEpoch}", "lifespan": 365}).then((data) {
      Logger.d("Got long-lived token.");
      _token = data;
      _tempToken = null;
      final storage = new FlutterSecureStorage();
      storage.write(key: "hacl_llt", value: "$_token").then((_) {
        completer.complete();
      }).catchError((e) {
        throw e;
      });
    }).catchError((e) {
      logout();
      completer.completeError({"errorCode": 63, "errorMessage": "Authentication error: $e"});
    });
    return completer.future;
  }

  Future sendSocketMessage({String type, Map additionalData, bool auth: false}) {
    Completer _completer = Completer();
    Map dataObject = {"type": "$type"};
    String callbackName;
    if (!auth) {
      _incrementMessageId();
      dataObject["id"] = _currentMessageId;
      callbackName = "$_currentMessageId";
    } else {
      callbackName = "auth";
    }
    if (additionalData != null) {
      dataObject.addAll(additionalData);
    }
    _messageResolver[callbackName] = _completer;
    String rawMessage = json.encode(dataObject);
    if (!isConnected) {
      _connect().timeout(connectTimeout, onTimeout: (){
        _completer.completeError({"errorCode": 8, "errorMessage": "No connection to Home Assistant"});
      }).then((_) {
        Logger.d("[Sending] ==> $rawMessage");
        _socket.sink.add(rawMessage);
      }).catchError((e) {
        _completer.completeError(e);
      });
    } else {
      Logger.d("[Sending] ==> $rawMessage");
      _socket.sink.add(rawMessage);
    }
    return _completer.future;
  }

  void _incrementMessageId() {
    _currentMessageId += 1;
  }

  Future callService({String domain, String service, String entityId, Map additionalServiceData}) {
    Map serviceData = {};
    if (entityId != null) {
      serviceData["entity_id"] = entityId;
    }
    if (additionalServiceData != null && additionalServiceData.isNotEmpty) {
      serviceData.addAll(additionalServiceData);
    }
    if (serviceData.isNotEmpty)
      return sendSocketMessage(type: "call_service", additionalData: {"domain": domain, "service": service, "service_data": serviceData});
    else
      return sendSocketMessage(type: "call_service", additionalData: {"domain": domain, "service": service});
  }

  Future<List> getHistory(String entityId) async {
    DateTime now = DateTime.now();
    //String endTime = formatDate(now, [yyyy, '-', mm, '-', dd, 'T', HH, ':', nn, ':', ss, z]);
    String startTime = formatDate(now.subtract(Duration(hours: 24)), [yyyy, '-', mm, '-', dd, 'T', HH, ':', nn, ':', ss, z]);
    String url = "$httpWebHost/api/history/period/$startTime?&filter_entity_id=$entityId";
    Logger.d("[Sending] ==> $url");
    http.Response historyResponse;
    historyResponse = await http.get(url, headers: {
      "authorization": "Bearer $_token",
      "Content-Type": "application/json"
    });
    var history = json.decode(historyResponse.body);
    if (history is List) {
      Logger.d( "[Received] <== ${history.first.length} history recors");
      return history;
    } else {
      return [];
    }
  }

  Future sendHTTPPost({String endPoint, String data, String contentType: "application/json", bool includeAuthHeader: true}) async {
    Completer completer = Completer();
    String url = "$httpWebHost$endPoint";
    Logger.d("[Sending] ==> $url");
    Map<String, String> headers = {};
    if (contentType != null) {
      headers["Content-Type"] = contentType;
    }
    if (includeAuthHeader) {
      headers["authorization"] = "Bearer $_token";
    }
    http.post(
        url,
        headers: headers,
        body: data
    ).then((response) {
      Logger.d("[Received] <== ${response.statusCode}, ${response.body}");
      if (response.statusCode == 200) {
        completer.complete(response.body);
      } else {
        completer.completeError({"code": response.statusCode, "message": "${response.body}"});
      }
    }).catchError((e) {
      completer.completeError(e);
    });
    return completer.future;
  }

}