import 'package:flutter/material.dart';
import 'package:flutter_notification/features/ticket/models/message_model.dart';
import 'package:flutter_notification/features/ticket/models/ticket_model.dart';
import 'package:flutter_notification/features/ticket/services/ticket_service.dart';
import 'package:flutter_notification/features/ticket/widgets/message_bubble.dart';


class TicketChatScreen extends StatefulWidget {
  final TicketModel ticket;
  final String userId;

  const TicketChatScreen({
    super.key,
    required this.ticket,
    required this.userId,
  });

  @override
  State<TicketChatScreen> createState() => _TicketChatScreenState();
}

class _TicketChatScreenState extends State<TicketChatScreen> {
  final TextEditingController _msgController = TextEditingController();

  void _sendMessage() async {
    final text = _msgController.text.trim();
    if (text.isEmpty) return;

    final message = MessageModel(
      id: '',
      senderId: widget.userId,
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
      appBar: AppBar(title: Text(widget.ticket.title)),
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
                    final isMe = message.senderId == widget.userId;
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
                      decoration: const InputDecoration(
                        hintText: "Type a message...",
                      ),
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
