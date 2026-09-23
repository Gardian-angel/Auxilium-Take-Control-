import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SettingsScreen extends StatelessWidget {
  final String tab;
  const SettingsScreen({super.key, this.tab = 'account'});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      initialIndex: ['account', 'connections', 'billing', 'security'].indexOf(tab).clamp(0, 3),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Settings'),
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: 'Account'),
              Tab(text: 'Connections'),
              Tab(text: 'Billing'),
              Tab(text: 'Security'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _AccountTab(),
            _ConnectionsTab(),
            _BillingTab(),
            _SecurityTab(),
          ],
        ),
      ),
    );
  }
}

class _AccountTab extends StatelessWidget {
  const _AccountTab();

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const SizedBox(height: 16),
        Center(
          child: CircleAvatar(
            radius: 40,
            backgroundImage: user?.photoURL != null ? NetworkImage(user!.photoURL!) : null,
            child: user?.photoURL == null ? const Icon(Icons.person, size: 40) : null,
          ),
        ),
        const SizedBox(height: 12),
        Center(child: Text(user?.displayName ?? 'User',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
        Center(child: Text(user?.email ?? '',
            style: const TextStyle(color: Colors.grey))),
        const SizedBox(height: 32),
        ListTile(leading: const Icon(Icons.edit), title: const Text('Edit profile'), onTap: () {}),
        ListTile(
          leading: const Icon(Icons.language),
          title: const Text('Language'),
          trailing: const Text('English'),
          onTap: () {},
        ),
        ListTile(
          leading: const Icon(Icons.schedule),
          title: const Text('Timezone'),
          trailing: const Text('UTC'),
          onTap: () {},
        ),
        ListTile(
          leading: const Icon(Icons.accessibility_new),
          title: const Text('Accessibility'),
          onTap: () {},
        ),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.logout),
          title: const Text('Sign out'),
          onTap: () async {
            await FirebaseAuth.instance.signOut();
            if (context.mounted) context.go('/login');
          },
        ),
        ListTile(
          leading: const Icon(Icons.delete_forever, color: Colors.red),
          title: const Text('Delete account', style: TextStyle(color: Colors.red)),
          onTap: () => _confirmDelete(context),
        ),
      ],
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete account'),
        content: const Text('This will permanently delete your account and all data. This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await FirebaseAuth.instance.currentUser?.delete();
      context.go('/login');
    }
  }
}

class _ConnectionsTab extends StatelessWidget {
  const _ConnectionsTab();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: ListTile(
            leading: const Icon(Icons.g_mobiledata, size: 32, color: Colors.blue),
            title: const Text('Google Workspace'),
            subtitle: const Text('Calendar, Drive integration'),
            trailing: OutlinedButton(onPressed: () {}, child: const Text('Connect')),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: ListTile(
            leading: const Icon(Icons.window, size: 28, color: Color(0xFF0078D4)),
            title: const Text('Microsoft Graph'),
            subtitle: const Text('Outlook, Teams integration'),
            trailing: OutlinedButton(onPressed: () {}, child: const Text('Connect')),
          ),
        ),
      ],
    );
  }
}

class _BillingTab extends StatelessWidget {
  const _BillingTab();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Current plan',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 8),
                const Text('Free',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
                const SizedBox(height: 4),
                const Text('Basic mood tracking'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {},
                  child: const Text('Upgrade to Premium — \$4.99/mo'),
                ),
                const SizedBox(height: 8),
                Center(
                  child: TextButton(
                    onPressed: () {},
                    child: const Text('Restore purchases'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SecurityTab extends StatelessWidget {
  const _SecurityTab();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ListTile(
          leading: const Icon(Icons.lock_outline),
          title: const Text('Change password'),
          onTap: () {
            final email = FirebaseAuth.instance.currentUser?.email;
            if (email != null) {
              FirebaseAuth.instance.sendPasswordResetEmail(email: email);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Reset email sent')),
              );
            }
          },
        ),
        SwitchListTile(
          secondary: const Icon(Icons.security),
          title: const Text('Two-factor authentication'),
          subtitle: const Text('Coming soon'),
          value: false,
          onChanged: null,
        ),
        SwitchListTile(
          secondary: const Icon(Icons.fingerprint),
          title: const Text('Biometric login'),
          value: false,
          onChanged: (_) {},
        ),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.privacy_tip_outlined),
          title: const Text('Privacy policy'),
          onTap: () {},
        ),
        ListTile(
          leading: const Icon(Icons.description_outlined),
          title: const Text('Terms of service'),
          onTap: () {},
        ),
      ],
    );
  }
}
