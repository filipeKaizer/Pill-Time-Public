import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_mdi_icons/flutter_mdi_icons.dart';
import 'package:pill_time/pages/AssistencePage.dart';
import 'package:pill_time/pages/PillPage.dart';
import 'package:pill_time/pages/addPillPage.dart';
import 'package:pill_time/pages/alarmPage.dart';
import 'package:pill_time/pages/progressPage.dart';
import 'package:pill_time/pages/settingsPage.dart';
import 'package:pill_time/pages/welcomePage.dart';
import 'package:pill_time/src/providers/memory.dart';
import 'package:pill_time/src/providers/settings.dart';
import 'package:provider/provider.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  tz.initializeTimeZones();
  tz.setLocalLocation(tz.getLocation('America/Sao_Paulo'));

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

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<Settings>(create: (_) => Settings()),
        ChangeNotifierProvider<Memory>(
          create: (_) => Memory(navigatorKey: navigatorKey),
        ),
      ],
      child: const PillTimeWidget(),
    ),
  );
}

class PillTimeWidget extends StatefulWidget {
  const PillTimeWidget({super.key});

  @override
  State<PillTimeWidget> createState() => _PillTimeWidgetState();
}

class _PillTimeWidgetState extends State<PillTimeWidget> {
  int currentIndex = 0;

  final List<Widget> pages = [Pillpage(), Progresspage(), Settingspage()];

  @override
  Widget build(BuildContext context) {
    final memory = Provider.of<Memory>(context);

    return MaterialApp(
      routes: {'/alarm': (_) => AlarmPage()},
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      home: memory.onWelcomePage
          ? Welcomepage()
          : memory.onAssitencePage
          ? Assistencepage()
          : Scaffold(
              backgroundColor: Settings.backgroundColor,

              appBar: AppBar(
                elevation: 2,
                centerTitle: true,
                backgroundColor: Settings.backgroundColor,
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
