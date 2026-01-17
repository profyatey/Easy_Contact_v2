// ----------------- main.dart -----------------
import 'dart:io';
import 'package:excel/excel.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

// ignore: unused_import
void main() {
  runApp(
    MaterialApp(
      title: 'Easy Contactsv2',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.teal,
          primary: Colors.teal.shade600,
          secondary: Colors.amber.shade400,
          surface: Colors.white,
          onPrimary: Colors.white,
          onSecondary: Colors.black87,
        ),
        scaffoldBackgroundColor: Colors.grey.shade50,
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.teal.shade700,
          foregroundColor: Colors.white,
          elevation: 2,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.amber.shade400,
            foregroundColor: Colors.teal.shade900,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            textStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
            elevation: 2,
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
          filled: true,
          fillColor: Colors.white,
          labelStyle: TextStyle(color: Colors.teal.shade700),
        ),
        textTheme: TextTheme(
          bodyMedium: TextStyle(fontSize: 16, color: Colors.teal.shade900),
        ),
      ),
      home: const ContactInputScreen(),
    ),
  );
}

class Contact {
  String name;
  String location;
  String phone;

  Contact({required this.name, required this.location, required this.phone});
}

class ContactInputScreen extends StatefulWidget {
  const ContactInputScreen({super.key});

  @override
  State<ContactInputScreen> createState() => _ContactInputScreenState();
}

class _ContactInputScreenState extends State<ContactInputScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _locationController = TextEditingController();
  final _phoneController = TextEditingController();

  final List<Contact> contacts = [];
  String status = 'Add contacts and export to Excel';

  // ---------- HELPERS ----------
  String _timeStamp() {
    final now = DateTime.now();
    return '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_'
        '${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}${now.second.toString().padLeft(2, '0')}';
  }

  Excel _buildExcel(String sheetName) {
    final excel = Excel.createExcel();
    final defaultSheet = excel.getDefaultSheet()!;
    excel.rename(defaultSheet, sheetName);
    final sheet = excel[sheetName];

    sheet.appendRow([
      TextCellValue('Name'),
      TextCellValue('Location'),
      TextCellValue('Phone'),
    ]);

    for (final c in contacts) {
      sheet.appendRow([
        TextCellValue(c.name),
        TextCellValue(c.location),
        TextCellValue(c.phone),
      ]);
    }

    return excel;
  }

  // ---------- SAVE USING SAF ----------
  Future<void> _saveExcelWithSAF() async {
    if (contacts.isEmpty) {
      setState(() => status = 'No contacts to save!');
      return;
    }

    try {
      // Let user select a folder
      final folderPath = await FilePicker.platform.getDirectoryPath(
        dialogTitle: 'Select folder to save Excel',
      );

      if (folderPath == null) {
        setState(() => status = 'Save cancelled');
        return; // user cancelled
      }

      // Build Excel
      final excel = _buildExcel('Contacts');
      final bytes = excel.encode();
      if (bytes == null) throw Exception('Excel encoding failed');

      // Save file in selected folder
      final file = File('$folderPath/contacts_${_timeStamp()}.xlsx');
      await file.writeAsBytes(bytes, flush: true);

      setState(() => status = 'Excel file saved successfully at $folderPath');
    } catch (e) {
      setState(() => status = 'Save failed: $e');
    }
  }

  // ---------- EXPORT & SHARE ----------

  // ---------- CONTACT MANAGEMENT ----------
  void _addContact() {
    if (_formKey.currentState!.validate()) {
      setState(() {
        contacts.add(
          Contact(
            name: _nameController.text.trim(),
            location: _locationController.text.trim(),
            phone: _phoneController.text.trim(),
          ),
        );
        _nameController.clear();
        _locationController.clear();
        _phoneController.clear();
        status = 'Contact added (${contacts.length})';
      });
    }
  }

  void _deleteContact(int index) {
    setState(() {
      contacts.removeAt(index);
      status = 'Contact deleted. Total contacts: ${contacts.length}';
    });
  }

  Widget _buildContactList() {
    if (contacts.isEmpty) return const Text('No contacts added yet.');
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: contacts.length,
      itemBuilder: (context, index) {
        final c = contacts[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4),
          child: ListTile(
            title: Text(c.name),
            subtitle: Text('Location: ${c.location}\nPhone: ${c.phone}'),
            trailing: IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _deleteContact(index),
            ),
          ),
        );
      },
    );
  }

  // ---------- BUILD UI ----------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Easy Contacts'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            tooltip: 'Save Excel File',
            onPressed: _saveExcelWithSAF,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Form(
              key: _formKey,
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: 'Name'),
                    validator: (val) =>
                        val == null || val.trim().isEmpty ? 'Enter name' : null,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _locationController,
                    decoration: const InputDecoration(labelText: 'Location'),
                    validator: (val) => val == null || val.trim().isEmpty
                        ? 'Enter location'
                        : null,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _phoneController,
                    decoration: const InputDecoration(labelText: 'Phone'),
                    keyboardType: TextInputType.phone,
                    validator: (val) => val == null || val.trim().isEmpty
                        ? 'Enter phone'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _addContact,
                    child: const Text('Add Contact'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Contacts (${contacts.length}):',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            SizedBox(
              height: 300,
              child: SingleChildScrollView(child: _buildContactList()),
            ),

            const SizedBox(height: 20),
            Text(status),
          ],
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        height: 40,
        child: Text(
          'Developed by Web Yatey LLC',
          style: TextStyle(fontSize: 12, color: Colors.teal.shade700),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    _phoneController.dispose();
    super.dispose();
  }
}
