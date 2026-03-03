import 'package:flutter/material.dart';
import '../../services/ai_executor.dart';

class RuleChatbotScreen extends StatefulWidget {
  const RuleChatbotScreen({super.key});

  @override
  State<RuleChatbotScreen> createState() => _RuleChatbotScreenState();
}

class _RuleChatbotScreenState extends State<RuleChatbotScreen> {
  final TextEditingController _messageController = TextEditingController();
  final List<Map<String, dynamic>> _messages = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _addBotMessage('Hello! I\'m your AI assistant. How can I help you today?');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Rule-based Chatbot')),
      body: Column(
        children: [
          // Chat messages
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              reverse: true,
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[_messages.length - 1 - index];
                final isUser = message['isUser'];

                return Align(
                  alignment:
                      isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isUser
                          ? const Color(0xFFE3F2FD)
                          : const Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isUser
                            ? const Color(0xFFBBDEFB)
                            : const Color(0xFFE0E0E0),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              isUser ? Icons.person : Icons.smart_toy,
                              size: 16,
                              color: isUser ? Colors.blue : Colors.grey,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              isUser ? 'You' : 'AI Assistant',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: isUser
                                    ? const Color(0xFF1565C0)
                                    : const Color(0xFF616161),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          message['text'],
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Input area
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: const Color(0xFFE0E0E0))),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Type your message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _loading ? null : _sendMessage,
                  icon: _loading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    shape: const CircleBorder(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _addBotMessage(String text) {
    setState(() {
      _messages.add({'text': text, 'isUser': false});
    });
  }

  void _addUserMessage(String text) {
    setState(() {
      _messages.add({'text': text, 'isUser': true});
    });
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    _addUserMessage(text);
    _messageController.clear();

    setState(() {
      _loading = true;
    });

    try {
      final response = await AIExecutor.runTool(
        toolName: 'Rule-based Chatbot',
        module: 'Logic & Decision AI',
        input: text,
      );

      _addBotMessage(response.toString());
    } catch (e) {
      _addBotMessage('Sorry, I encountered an error: $e');
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }
}
