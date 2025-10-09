import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'api_service.dart'; // Make sure this has AuthService

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final AuthService _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      body: Center(
        child: user == null
            ? ElevatedButton(
          onPressed: () async {
            await _authService.signInWithGoogle();
            final user = FirebaseAuth.instance.currentUser;

            if (user != null) {
              print("✅ Signed In User Details:");
              print("UID: ${user.uid}");
              print("Name: ${user.displayName}");
              print("Email: ${user.email}");
              print("Photo URL: ${user.photoURL}");
            }

            setState(() {});
          },
          child: const Text("Sign in with Google"),
        )
            : Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (user.photoURL != null)
              CircleAvatar(
                backgroundImage: NetworkImage(user.photoURL!),
                radius: 40,
              ),
            const SizedBox(height: 10),
            Text("Name: ${user.displayName ?? 'N/A'}"),
            Text("Email: ${user.email ?? 'N/A'}"),
            Text("UID: ${user.uid}"),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                await _authService.signOut();
                setState(() {});
              },
              child: const Text("Sign Out"),
            ),
          ],
        ),
      ),
    );
  }
}
