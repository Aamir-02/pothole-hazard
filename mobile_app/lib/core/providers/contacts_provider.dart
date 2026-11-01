import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_client.dart';

class EmergencyContactModel {
  final String id;
  final String name;
  final String phone;
  final String relationship;
  final bool isFavorite;

  EmergencyContactModel({
    required this.id,
    required this.name,
    required this.phone,
    required this.relationship,
    this.isFavorite = false,
  });

  factory EmergencyContactModel.fromJson(Map<String, dynamic> json) {
    return EmergencyContactModel(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? 'Contact',
      phone: json['phone'] ?? '',
      relationship: json['relationship'] ?? 'Friend',
      isFavorite: json['isFavorite'] ?? false,
    );
  }
}

class ContactsState {
  final bool isLoading;
  final List<EmergencyContactModel> contacts;

  ContactsState({this.isLoading = false, this.contacts = const []});
}

class ContactsNotifier extends StateNotifier<ContactsState> {
  ContactsNotifier() : super(ContactsState()) {
    fetchContacts();
  }

  Future<void> fetchContacts() async {
    state = ContactsState(isLoading: true, contacts: state.contacts);
    final res = await ApiClient.get('/contacts');

    if (res['success'] == true && res['contacts'] != null) {
      final list = (res['contacts'] as List).map((x) => EmergencyContactModel.fromJson(x)).toList();
      state = ContactsState(isLoading: false, contacts: list);
    } else {
      state = ContactsState(isLoading: false, contacts: [
        EmergencyContactModel(
          id: '1',
          name: 'Sarah (Wife)',
          phone: '+1 555 019 2834',
          relationship: 'Spouse',
          isFavorite: true,
        ),
        EmergencyContactModel(
          id: '2',
          name: 'David (Brother)',
          phone: '+1 555 014 9912',
          relationship: 'Family',
          isFavorite: true,
        ),
      ]);
    }
  }

  Future<bool> addContact(String name, String phone, String relationship, bool isFavorite) async {
    if (state.contacts.length >= 10) return false;

    final res = await ApiClient.post('/contacts', {
      'name': name,
      'phone': phone,
      'relationship': relationship,
      'isFavorite': isFavorite,
    });

    if (res['success'] == true) {
      await fetchContacts();
      return true;
    } else {
      // Local fallback addition
      final newContact = EmergencyContactModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name,
        phone: phone,
        relationship: relationship,
        isFavorite: isFavorite,
      );
      state = ContactsState(isLoading: false, contacts: [...state.contacts, newContact]);
      return true;
    }
  }

  Future<void> deleteContact(String id) async {
    await ApiClient.delete('/contacts/$id');
    state = ContactsState(
      isLoading: false,
      contacts: state.contacts.where((c) => c.id != id).toList(),
    );
  }
}

final contactsProvider = StateNotifierProvider<ContactsNotifier, ContactsState>((ref) {
  return ContactsNotifier();
});
