import 'package:flutter/material.dart';

class CalendarScreen extends StatelessWidget {
  const CalendarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Calendar & Scheduling')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Connected Calendars', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 16),
                  ListTile(
                    leading: const Icon(Icons.calendar_today, color: Colors.blue),
                    title: const Text('Google Calendar'),
                    trailing: OutlinedButton(onPressed: () {}, child: const Text('Connect')),
                    contentPadding: EdgeInsets.zero,
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.calendar_view_month, color: Color(0xFF0078D4)),
                    title: const Text('Microsoft Outlook'),
                    trailing: OutlinedButton(onPressed: () {}, child: const Text('Connect')),
                    contentPadding: EdgeInsets.zero,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Upcoming Events', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 16),
                  Center(
                    child: Text('Connect a calendar to see events',
                      style: TextStyle(color: Colors.grey.shade400)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
