import 'package:flutter/material.dart';
import 'package:flutter_notification/features/ticket/models/ticket_model.dart';
import 'package:flutter_notification/features/ticket/services/ticket_service.dart';


class TicketFormScreen extends StatefulWidget {
  final String userId;
  const TicketFormScreen({super.key, required this.userId});

  @override
  State<TicketFormScreen> createState() => _TicketFormScreenState();
}

class _TicketFormScreenState extends State<TicketFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();

  bool _loading = false;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    final ticket = TicketModel(
      id: '',
      userId: widget.userId,
      title: _titleController.text.trim(),
      description: _descController.text.trim(),
      status: 'open',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await TicketService().createTicket(ticket);

    setState(() => _loading = false);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Raise Ticket")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Title'),
                validator: (value) => value!.isEmpty ? 'Enter title' : null,
              ),
              TextFormField(
                controller: _descController,
                decoration: const InputDecoration(labelText: 'Description'),
                validator: (value) => value!.isEmpty ? 'Enter description' : null,
                maxLines: 3,
              ),
              const SizedBox(height: 20),
              _loading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                onPressed: _submit,
                child: const Text("Submit Ticket"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
