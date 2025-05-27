import 'package:flutter/material.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.network(
                  'https://www.shakebugs.com/wp-content/uploads/2022/04/6-tips-onboarding-tehnical-employees.png',
                  height: 250,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 40),
                const Text(
                  'Welcome to LaptopHarbor',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF6A4F9A),
                  ),
                  textAlign: TextAlign.center, // <-- center align
                ),
                const SizedBox(height: 16),
                const Text(
                  'Discover and buy your perfect laptop with ease.',
                  style: TextStyle(fontSize: 18, color: Colors.black54),
                  textAlign: TextAlign.center, // <-- center align
                ),
                const SizedBox(height: 40),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pushReplacementNamed(context, '/login');
                  },
                  child: const Text(
                    'Get Started',
                    style:
                        TextStyle(color: Colors.white), // <-- white text color
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
