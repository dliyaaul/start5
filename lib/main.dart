import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  runApp(const PomoFocusApp());
}

class PomoFocusApp extends StatelessWidget {
  const PomoFocusApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  /// TIMER
  int totalSeconds = 25 * 60;
  Timer? timer;
  bool isRunning = false;

  /// TAB
  int selectedTab = 0;
  final List<String> tabs = ["Pomodoro", "Short Break", "Long Break"];

  /// FIREBASE
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  /// INPUT TASK
  final TextEditingController taskController = TextEditingController();

  /// NOTIFIKASI
  final FlutterLocalNotificationsPlugin notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
    );

    notificationsPlugin.initialize(settings);
  }

  /// START TIMER
  void startTimer() {
    if (isRunning) return;

    setState(() {
      isRunning = true;
    });

    timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (totalSeconds == 0) {
        t.cancel();
        setState(() {
          isRunning = false;
        });
        onTimerComplete();
      } else {
        setState(() {
          totalSeconds--;
        });
      }
    });
  }

  /// RESET TIMER
  void resetTimer(int seconds) {
    timer?.cancel();
    setState(() {
      totalSeconds = seconds;
      isRunning = false;
    });
  }

  /// FORMAT TIME
  String formatTime(int seconds) {
    int minutes = seconds ~/ 60;
    int secs = seconds % 60;
    return "${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}";
  }

  /// NOTIFIKASI
  Future<void> showNotification() async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'pomodoro_channel',
          'Pomodoro',
          importance: Importance.max,
          priority: Priority.high,
        );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
    );

    await notificationsPlugin.show(
      0,
      'Waktu Habis!',
      'Saatnya istirahat 🎉',
      details,
    );
  }

  void onTimerComplete() {
    showNotification();
  }

  /// FIREBASE ADD TASK
  Future<void> addTask(String title) async {
    if (title.trim().isEmpty) return;

    await firestore.collection('tasks').add({
      'title': title,
      'createdAt': Timestamp.now(),
    });

    taskController.clear();
  }

  /// GANTI MODE TIMER
  void changeTab(int index) {
    setState(() {
      selectedTab = index;
    });

    if (index == 0) {
      resetTimer(25 * 60);
    } else if (index == 1) {
      resetTimer(5 * 60);
    } else {
      resetTimer(15 * 60);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFBA4949),
      appBar: AppBar(
        backgroundColor: const Color(0xFFBA4949),
        elevation: 0,
        title: const Text("Pomofocus"),
      ),
      body: Column(
        children: [
          const SizedBox(height: 20),

          /// TIMER CARD
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: [
                /// TAB
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(tabs.length, (index) {
                    return GestureDetector(
                      onTap: () => changeTab(index),
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 5),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: selectedTab == index
                              ? Colors.black26
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Text(
                          tabs[index],
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    );
                  }),
                ),

                const SizedBox(height: 20),

                /// TIMER TEXT
                Text(
                  formatTime(totalSeconds),
                  style: const TextStyle(
                    fontSize: 80,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),

                const SizedBox(height: 20),

                /// BUTTON
                ElevatedButton(
                  onPressed: startTimer,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 50,
                      vertical: 15,
                    ),
                  ),
                  child: Text(
                    isRunning ? "RUNNING..." : "START",
                    style: const TextStyle(
                      color: Color(0xFFBA4949),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          const Text("#1", style: TextStyle(color: Colors.white70)),
          const Text("Time to focus!", style: TextStyle(color: Colors.white)),

          const SizedBox(height: 20),

          /// TASK HEADER
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Tasks",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Icon(Icons.more_vert, color: Colors.white),
              ],
            ),
          ),

          const Divider(color: Colors.white38),

          /// INPUT TASK
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: taskController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      hintText: "Tambah task...",
                      hintStyle: TextStyle(color: Colors.white70),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.white38),
                      ),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => addTask(taskController.text),
                  icon: const Icon(Icons.add, color: Colors.white),
                ),
              ],
            ),
          ),

          /// LIST TASK (REALTIME)
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: firestore
                  .collection('tasks')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  );
                }

                final docs = snapshot.data!.docs;

                return ListView(
                  children: docs.map((doc) {
                    return ListTile(
                      title: Text(
                        doc['title'],
                        style: const TextStyle(color: Colors.white),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
