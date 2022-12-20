import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:flutter/material.dart';

import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}

enum Routes { signIn, counter }

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final providers = [EmailAuthProvider()];

    return MaterialApp(
      initialRoute: fb_auth.FirebaseAuth.instance.currentUser == null ? Routes.signIn.name : Routes.counter.name,
      routes: {
        Routes.signIn.name: (context) {
          return SignInScreen(
            providers: providers,
            actions: [
              AuthStateChangeAction<SignedIn>((context, state) {
                Navigator.pushReplacementNamed(context, Routes.counter.name);
              }),
            ],
          );
        },
        Routes.counter.name: (context) {
          return CounterScreen(
            title: "Counter for ${fb_auth.FirebaseAuth.instance.currentUser?.email ?? ''}",
          );
        },
      },
    );
  }
}

class CounterScreen extends StatefulWidget {
  const CounterScreen({super.key, required this.title});

  final String title;

  @override
  State<CounterScreen> createState() => _CounterScreenState();
}

class _CounterScreenState extends State<CounterScreen> {
  int _counter = 0;
  final userId = fb_auth.FirebaseAuth.instance.currentUser?.uid;
  late final DocumentReference<Map<String, dynamic>> docRef;

  void _incrementCounter() {
    final userData = {
      "counter": _counter++,
    };
    final db = FirebaseFirestore.instance;
    db.collection("users").doc(userId).set(userData).onError((e, _) => debugPrint("Error writing document: $e"));
  }

  @override
  void initState() {
    super.initState();
    docRef = FirebaseFirestore.instance.collection("users").doc(userId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(
            onPressed: () {
              fb_auth.FirebaseAuth.instance.signOut();
              Navigator.pushReplacementNamed(context, Routes.signIn.name);
            },
            icon: const Icon(Icons.exit_to_app),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'You have pushed the button this many times:',
            ),
            StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                stream: docRef.snapshots(),
                builder: (context, snapshot) {
                  final userData = snapshot.data?.data();
                  if (!snapshot.hasData || userData == null) {
                    return const CircularProgressIndicator();
                  }
                  final loadedCount = userData["counter"];
                  print("loaded count:$loadedCount");
                  _counter = loadedCount;
                  return Text(
                    '$_counter',
                    style: Theme.of(context).textTheme.headline4,
                  );
                }
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}
