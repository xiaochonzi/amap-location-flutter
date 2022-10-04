import 'dart:async';
import 'dart:io';
import 'dart:ui';


import 'package:amap_location_flutter_plugin/amap_location_flutter_plugin.dart';
import 'package:amap_location_flutter_plugin/amap_location_option.dart';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  initializeService();
  runApp(const MyApp());
}

AMapLocationOption getLocationOption() {
  AMapLocationOption locationOption = new AMapLocationOption();

  ///是否单次定位
  locationOption.onceLocation = false;

  ///是否需要返回逆地理信息
  locationOption.needAddress = true;

  ///逆地理信息的语言类型
  locationOption.geoLanguage = GeoLanguage.DEFAULT;

  locationOption.desiredLocationAccuracyAuthorizationMode =
      AMapLocationAccuracyAuthorizationMode.ReduceAccuracy;

  locationOption.fullAccuracyPurposeKey = "AMapLocationScene";

  ///设置Android端连续定位的定位间隔
  locationOption.locationInterval = 2000;

  ///设置Android端的定位模式<br>
  ///可选值：<br>
  ///<li>[AMapLocationMode.Battery_Saving]</li>
  ///<li>[AMapLocationMode.Device_Sensors]</li>
  ///<li>[AMapLocationMode.Hight_Accuracy]</li>
  locationOption.locationMode = AMapLocationMode.Hight_Accuracy;

  ///设置iOS端的定位最小更新距离<br>
  locationOption.distanceFilter = -1;

  ///设置iOS端期望的定位精度
  /// 可选值：<br>
  /// <li>[DesiredAccuracy.Best] 最高精度</li>
  /// <li>[DesiredAccuracy.BestForNavigation] 适用于导航场景的高精度 </li>
  /// <li>[DesiredAccuracy.NearestTenMeters] 10米 </li>
  /// <li>[DesiredAccuracy.Kilometer] 1000米</li>
  /// <li>[DesiredAccuracy.ThreeKilometers] 3000米</li>
  locationOption.desiredAccuracy = DesiredAccuracy.Best;

  ///设置iOS端是否允许系统暂停定位
  locationOption.pausesLocationUpdatesAutomatically = false;

  ///将定位参数设置给定位插件
  return locationOption;
}


Future<void> initializeService() async {
  final service = FlutterBackgroundService();
  /// OPTIONAL, using custom notification channel id
  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'my_foreground', // id
    'MY FOREGROUND SERVICE', // title
    description:
    'This channel is used for important notifications.', // description
    importance: Importance.low, // importance must be at low or higher level
  );

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  if (Platform.isIOS) {
    await flutterLocalNotificationsPlugin.initialize(
      const InitializationSettings(
        iOS: IOSInitializationSettings(),
      ),
    );
  }
  await flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.createNotificationChannel(channel);
  await service.configure(
    androidConfiguration: AndroidConfiguration(
      // this will be executed when app is in foreground or background in separated isolate
      onStart: onStart,
      // auto start service
      autoStart: false,
      isForegroundMode: true,
      notificationChannelId: 'my_foreground',
      initialNotificationTitle: 'AWESOME SERVICE',
      initialNotificationContent: 'Initializing',
      foregroundServiceNotificationId: 888,
    ),
    iosConfiguration: IosConfiguration(
      // auto start service
      autoStart: false,
      // this will be executed when app is in foreground in separated isolate
      onForeground: onStart,
      onBackground: onIosBackground,
    ),
  );
  service.startService();
}

@pragma('vm:entry-point')
Future<bool> onIosBackground(ServiceInstance service) async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();
  return true;
}


@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();
  AmapLocationFlutterPlugin _locationPlugin = new AmapLocationFlutterPlugin();
  AmapLocationFlutterPlugin.setApiKey(
      "ea4c317a75c12f0360e46126f38b1ac3", "dfb64c0463cb53927914364b5c09aba0");
  ///注册定位结果监听
  StreamSubscription<Map<String, Object>> _locationListener = _locationPlugin
      .onLocationChanged()
      .listen((Map<String, Object> result) {
    print(result);
    service.invoke("update", result);
  });

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  if (service is AndroidServiceInstance) {
    service.on('setAsForeground').listen((event) {
      service.setAsForegroundService();
    });
    service.on('setAsBackground').listen((event) {
      service.setAsBackgroundService();
    });
  }
  service.on('stopService').listen((event) {
    service.stopSelf();
  });

  Timer.periodic(Duration(seconds: 5), (timer) {
    print("高德");
    AMapLocationOption option = getLocationOption();
    _locationPlugin.setLocationOption(option);
    _locationPlugin.startLocation();
  });
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {

  @override
  void initState() {
    super.initState();
    /// 动态申请定位权限
    requestPermission();
    AmapLocationFlutterPlugin.updatePrivacyAgree(true);
    AmapLocationFlutterPlugin.updatePrivacyShow(true, true);
  }


  String text = "Stop Service";
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          StreamBuilder<Map<String, dynamic>?>(
            stream: FlutterBackgroundService().on('update'),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }
              Map data = snapshot.data!;
              List<Widget> resultWidgets = [];
              if (data.isNotEmpty) {
                data.forEach((key, value) {
                  resultWidgets.add(_resultWidget(key, value));
                });
              }
              return Column(
                children: [
                  SizedBox(
                    height: MediaQuery.of(context).size.height - 500,
                    child: ListView(
                      children: resultWidgets,
                    ),
                  ),
                ],
              );
            },
          ),
          ElevatedButton(
            child: const Text("Foreground Mode"),
            onPressed: () {
              FlutterBackgroundService().invoke("setAsForeground");
            },
          ),
          ElevatedButton(
            child: const Text("Background Mode"),
            onPressed: () {
              FlutterBackgroundService().invoke("setAsBackground");
            },
          ),
          ElevatedButton(
            child: Text(text),
            onPressed: () async {
              final service = FlutterBackgroundService();
              var isRunning = await service.isRunning();
              if (isRunning) {
                service.invoke("stopService");
              } else {
                service.startService();
              }
              if (!isRunning) {
                text = 'Stop Service';
              } else {
                text = 'Start Service';
              }
              setState(() {});
            },
          ),
        ],
      ),
    );
  }

  Widget _resultWidget(key, value) {
    return Center(
      child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text('$key:' ' $value'),
          ]),
    );
  }


  // 动态申请定位权限
  void requestPermission() async {
    // 申请权限
    bool hasLocationPermission = await requestLocationPermission();
    if (hasLocationPermission) {
      // 权限申请通过
    } else {}
  }

  /// 申请定位权限
  /// 授予定位权限返回true， 否则返回false
  Future<bool> requestLocationPermission() async {
    //获取当前的权限
    var status = await Permission.locationAlways.status;
    if (status == PermissionStatus.granted) {
      //已经授权
      return true;
    } else {
      //未授权则发起一次申请
      status = await Permission.locationAlways.request();
      if (status == PermissionStatus.granted) {
        return true;
      } else {
        return false;
      }
    }
  }
}
