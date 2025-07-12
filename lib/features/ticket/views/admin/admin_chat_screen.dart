import 'package:flutter/material.dart';
import 'package:flutter_notification/features/ticket/models/message_model.dart';
import 'package:flutter_notification/features/ticket/models/ticket_model.dart';
import 'package:flutter_notification/features/ticket/services/ticket_service.dart';
import 'package:flutter_notification/features/ticket/widgets/message_bubble.dart';

class AdminChatScreen extends StatefulWidget {
  final TicketModel ticket;

  const AdminChatScreen({super.key, required this.ticket});

  @override
  State<AdminChatScreen> createState() => _AdminChatScreenState();
}

class _AdminChatScreenState extends State<AdminChatScreen> {
  final TextEditingController _msgController = TextEditingController();
  final String _adminId = "admin"; // static admin ID for example

  void _sendMessage() async {
    final text = _msgController.text.trim();
    if (text.isEmpty) return;

    final message = MessageModel(
      id: '',
      senderId: _adminId,
      message: text,
      sentAt: DateTime.now(),
    );

    await TicketService().sendMessage(widget.ticket.id, message);
    _msgController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final isClosed = widget.ticket.status == "closed";

    return Scaffold(
      appBar: AppBar(title: Text("Ticket: ${widget.ticket.title}")),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<MessageModel>>(
              stream: TicketService().getMessages(widget.ticket.id),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                final messages = snapshot.data!;
                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isMe = message.senderId == _adminId;
                    return MessageBubble(message: message, isMe: isMe);
                  },
                );
              },
            ),
          ),
          if (!isClosed)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _msgController,
                      decoration: const InputDecoration(hintText: "Reply..."),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send),
                    onPressed: _sendMessage,
                  ),
                ],
              ),
            ),
          if (isClosed)
            const Padding(
              padding: EdgeInsets.all(12.0),
              child: Text(
                "This ticket is closed.",
                style: TextStyle(color: Colors.red),
              ),
            ),
        ],
      ),
    );
  }
}
