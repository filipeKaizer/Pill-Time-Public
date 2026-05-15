import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_mdi_icons/flutter_mdi_icons.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:pill_time/pages/mainPages/AssistencePage.dart';
import 'package:pill_time/pages/pillPage/PillPage.dart';
import 'package:pill_time/pages/pillPage/addPillPage.dart';
import 'package:pill_time/pages/alarmPages/alarmPage.dart';
import 'package:pill_time/pages/gamePages/progressPage.dart';
import 'package:pill_time/pages/mainPages/settingsPage.dart';
import 'package:pill_time/pages/mainPages/welcomePage.dart';
import 'package:pill_time/pages/utils/pdfView.dart';
import 'package:pill_time/src/providers/memory.dart';
import 'package:pill_time/src/providers/settings.dart';
import 'package:provider/provider.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  tz.initializeTimeZones();
  tz.setLocalLocation(tz.getLocation('America/Sao_Paulo'));

  await Hive.initFlutter();

  await Hive.openBox('cache'); // cria/abre o armazenamento
  await Hive.openBox('settings');

  FlutterForegroundTask.init(
    androidNotificationOptions: AndroidNotificationOptions(
      channelId: 'alarm_service',
      channelName: 'Alarm Service',
      channelDescription: 'Serviço de alarme',
      channelImportance: NotificationChannelImportance.MAX,
      priority: NotificationPriority.MAX,
    ),
    iosNotificationOptions: IOSNotificationOptions(),
    foregroundTaskOptions: ForegroundTaskOptions(
      autoRunOnBoot: false,
      eventAction: ForegroundTaskEventAction.repeat(2000),
    ),
  );

  Settings settings = Settings();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<Settings>(create: (_) => settings),
        ChangeNotifierProvider<Memory>(
          create: (_) => Memory(navigatorKey: navigatorKey, settings: settings),
        ),
      ],
      child: PillTimeWidget(settings: settings),
    ),
  );
}

class PillTimeWidget extends StatefulWidget {
  Settings settings;
  PillTimeWidget({required this.settings});

  @override
  State<PillTimeWidget> createState() => _PillTimeWidgetState();
}

class _PillTimeWidgetState extends State<PillTimeWidget> {
  int currentIndex = 0;

  List<Widget> get pages => [
    Pillpage(),
    Progresspage(),
    Settingspage(settings: widget.settings),
  ];

  @override
  Widget build(BuildContext context) {
    final memory = Provider.of<Memory>(context);

    return MaterialApp(
      routes: {'/alarm': (_) => AlarmPage()},
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      home: memory.onWelcomePage && memory.settings.firstUse
          ? Welcomepage()
          : memory.onAssitencePage && memory.settings.firstUse
          ? Assistencepage()
          : Scaffold(
              backgroundColor: Settings.backgroundColor,

              appBar: AppBar(
                elevation: 2,
                centerTitle: true,
                backgroundColor: Settings.backgroundColor,
                actions: [
                  Padding(
                    padding: const EdgeInsets.only(right: 5),
                    child: InkWell(
                      onTap: () {
                        navigatorKey.currentState?.push(
                          MaterialPageRoute(builder: (_) => PdfView()),
                        );
                      },
                      child: Icon(Mdi.printer, color: Colors.white, size: 25),
                    ),
                  ),
                ],
                title: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Pill",
                      style: TextStyle(
                        color: Settings.secondColor,
                        fontSize: 20,
                      ),
                    ),
                    Text(
                      "Time",
                      style: TextStyle(
                        color: Settings.thirtColor,
                        fontSize: 20,
                      ),
                    ),
                  ],
                ),
              ),

              body: pages[currentIndex],

              floatingActionButton: currentIndex == 0
                  ? FloatingActionButton(
                      onPressed: () {
                        navigatorKey.currentState?.push(
                          MaterialPageRoute(builder: (_) => Addpillpage()),
                        );
                      },
                      backgroundColor: Settings.secondColor,
                      child: const Icon(Mdi.plus, color: Colors.white70),
                    )
                  : null,

              bottomNavigationBar: BottomNavigationBar(
                onTap: (value) {
                  setState(() {
                    currentIndex = value;
                  });
                },
                currentIndex: currentIndex,
                backgroundColor: Settings.bottonBarColor,
                selectedItemColor: Settings.secondColor,
                unselectedItemColor: Colors.white70,
                items: const [
                  BottomNavigationBarItem(
                    icon: Icon(Mdi.pill),
                    label: "Remédios",
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Mdi.controller),
                    label: "Progresso",
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Mdi.accountSettingsOutline),
                    label: "Config.",
                  ),
                ],
              ),
            ),
    );
  }
}
