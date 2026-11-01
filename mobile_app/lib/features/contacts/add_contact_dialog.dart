import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/providers/contacts_provider.dart';

class AddContactDialog extends ConsumerStatefulWidget {
  const AddContactDialog({super.key});

  @override
  ConsumerState<AddContactDialog> createState() => _AddContactDialogState();
}

class _AddContactDialogState extends ConsumerState<AddContactDialog> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  String _relationship = 'Family';
  final bool _isFavorite = true;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _saveContact() async {
    if (_nameController.text.isEmpty || _phoneController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter contact name and phone number')),
      );
      return;
    }

    final success = await ref.read(contactsProvider.notifier).addContact(
      _nameController.text.trim(),
      _phoneController.text.trim(),
      _relationship,
      _isFavorite,
    );

    if (mounted) {
      if (!success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Maximum limit of 10 emergency contacts reached!')),
        );
      } else {
        context.pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.darkCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: const Text('Add Emergency Contact', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: 'Contact Name (e.g. Sarah)',
                prefixIcon: Icon(Icons.person, color: AppColors.primaryRed),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: 'Phone Number (e.g. +91 9876543210)',
                prefixIcon: Icon(Icons.phone, color: AppColors.primaryRed),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Text('Relationship: ', style: TextStyle(color: Colors.white70)),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButton<String>(
                    value: _relationship,
                    isExpanded: true,
                    dropdownColor: AppColors.darkSurface,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    items: ['Family', 'Spouse', 'Friend', 'Doctor', 'Guardian'].map((r) {
                      return DropdownMenuItem(value: r, child: Text(r));
                    }).toList(),
                    onChanged: (v) => setState(() => _relationship = v!),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => context.pop(),
          child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryRed),
          onPressed: _saveContact,
          child: const Text('Save Contact', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
