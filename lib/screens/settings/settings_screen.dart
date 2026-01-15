import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const _SectionHeader(title: 'Account'),
          _SettingsTile(
            icon: Icons.email,
            title: 'Email',
            subtitle: FirebaseAuth.instance.currentUser?.email ?? 'Not available',
            onTap: () {
              _showEmailDialog(context);
            },
          ),
          _SettingsTile(
            icon: Icons.lock,
            title: 'Change Password',
            subtitle: 'Update your password',
            onTap: () {
              _showPasswordDialog(context);
            },
          ),
          const Divider(height: 32),
          const _SectionHeader(title: 'Preferences'),
          _SettingsTile(
            icon: Icons.notifications,
            title: 'Notifications',
            subtitle: 'Manage notification settings',
            onTap: () {
              _showComingSoonDialog(context, 'Notifications');
            },
          ),
          _SettingsTile(
            icon: Icons.language,
            title: 'Language',
            subtitle: 'English',
            onTap: () {
              _showComingSoonDialog(context, 'Language Settings');
            },
          ),
          _SettingsTile(
            icon: Icons.dark_mode,
            title: 'Dark Mode',
            subtitle: 'Toggle dark theme',
            onTap: () {
              _showComingSoonDialog(context, 'Dark Mode');
            },
          ),
          const Divider(height: 32),
          const _SectionHeader(title: 'Support'),
          _SettingsTile(
            icon: Icons.help,
            title: 'Help & Support',
            subtitle: 'Get help with the app',
            onTap: () {
              _showComingSoonDialog(context, 'Help & Support');
            },
          ),
          _SettingsTile(
            icon: Icons.privacy_tip,
            title: 'Privacy Policy',
            subtitle: 'View our privacy policy',
            onTap: () {
              _showComingSoonDialog(context, 'Privacy Policy');
            },
          ),
          _SettingsTile(
            icon: Icons.description,
            title: 'Terms of Service',
            subtitle: 'View our terms of service',
            onTap: () {
              _showComingSoonDialog(context, 'Terms of Service');
            },
          ),
          const Divider(height: 32),
          const _SectionHeader(title: 'About'),
          _SettingsTile(
            icon: Icons.info,
            title: 'About',
            subtitle: 'SimpleShop v1.0.0',
            onTap: () {
              _showAboutDialog(context);
            },
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red[200]!),
            ),
            child: Column(
              children: [
                Icon(Icons.warning, color: Colors.red[700], size: 32),
                const SizedBox(height: 8),
                Text(
                  'Danger Zone',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.red[700],
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Once you delete your account, there is no going back. Please be certain.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {
                      _showDeleteAccountDialog(context);
                    },
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.red[700]!),
                      foregroundColor: Colors.red[700],
                    ),
                    child: const Text('Delete Account'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showEmailDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Email Address'),
        content: Text(
          FirebaseAuth.instance.currentUser?.email ?? 'No email found',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showPasswordDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Password'),
        content: const Text(
          'Password reset functionality would be implemented here. You will receive an email with instructions to reset your password.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Password reset email sent!'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            child: const Text('Send Reset Email'),
          ),
        ],
      ),
    );
  }

  void _showComingSoonDialog(BuildContext context, String feature) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(feature),
        content: const Text('This feature is coming soon!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('About SimpleShop'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('SimpleShop v1.0.0'),
            SizedBox(height: 8),
            Text('A simple and elegant shopping app built with Flutter.'),
            SizedBox(height: 8),
            Text('© 2024 SimpleShop. All rights reserved.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
          'Are you sure you want to delete your account? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Account deletion would be implemented here'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).primaryColor,
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).primaryColor),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
