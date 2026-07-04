import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import 'dart:async';

class ChatScreen extends StatefulWidget {
  final Map userProfile;
  const ChatScreen({super.key, required this.userProfile});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  List _messages = [];
  bool _loading = true;
  bool _sending = false;
  String? _error;
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Timer? _pollTimer;

  String get _myUsername => widget.userProfile['community_username'] ?? '';

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) => _loadMessages());
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    try {
      final msgs = await ApiService.getChatMessages();
      setState(() {
        _messages = msgs;
        _loading = false;
      });
      _scrollToBottom();
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      final result = await ApiService.sendChatMessage(text);
      if (result['error'] != null) {
        setState(() => _error = result['error']);
      } else {
        _controller.clear();
        await _loadMessages();
      }
    } catch (e) {
      setState(() => _error = 'Failed to send');
    }
    setState(() => _sending = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF111827),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF00D4FF), size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Community Chat',
              style: GoogleFonts.orbitron(
                fontSize: 14,
                color: const Color(0xFF00D4FF),
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Anonymous · Developers only',
              style: GoogleFonts.rajdhani(
                fontSize: 11,
                color: Colors.grey,
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Icon(Icons.group, color: const Color(0xFF00D4FF).withValues(alpha: 0.7), size: 20),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF00D4FF)))
                : _messages.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.group, color: const Color(0xFF00D4FF).withValues(alpha: 0.3), size: 60),
                            const SizedBox(height: 16),
                            Text(
                              'No messages yet',
                              style: GoogleFonts.orbitron(color: Colors.white38, fontSize: 14),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Be the first to say something',
                              style: GoogleFonts.rajdhani(color: Colors.white24, fontSize: 13),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        itemCount: _messages.length,
                        itemBuilder: (context, i) {
                          final msg = _messages[i];
                          final isMe = msg['community_username'] == _myUsername;
                          return _buildBubble(msg, isMe);
                        },
                      ),
          ),
          if (_error != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              color: Colors.red.withValues(alpha: 0.1),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber, color: Colors.redAccent, size: 14),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _error!,
                      style: GoogleFonts.rajdhani(color: Colors.redAccent, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildBubble(Map msg, bool isMe) {
    final time = DateTime.tryParse(msg['created_at'] ?? '');
    final timeStr = time != null
        ? '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}'
        : '';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          if (!isMe)
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 4),
              child: Text(
                msg['community_username'] ?? 'Dev_anon',
                style: GoogleFonts.orbitron(
                  fontSize: 9,
                  color: const Color(0xFF00D4FF).withValues(alpha: 0.7),
                  letterSpacing: 0.5,
                ),
              ),
            ),
          Row(
            mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!isMe)
                Container(
                  width: 28,
                  height: 28,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF00D4FF).withValues(alpha: 0.1),
                    border: Border.all(color: const Color(0xFF00D4FF).withValues(alpha: 0.3)),
                  ),
                  child: Center(
                    child: Text(
                      (msg['community_username'] ?? 'D')[0].toUpperCase(),
                      style: GoogleFonts.orbitron(
                        fontSize: 10,
                        color: const Color(0xFF00D4FF),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isMe
                        ? const Color(0xFF00D4FF).withValues(alpha: 0.15)
                        : const Color(0xFF111827),
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(isMe ? 16 : 4),
                      bottomRight: Radius.circular(isMe ? 4 : 16),
                    ),
                    border: Border.all(
                      color: isMe
                          ? const Color(0xFF00D4FF).withValues(alpha: 0.3)
                          : const Color(0xFF1E2D45),
                    ),
                  ),
                  child: Text(
                    msg['message'] ?? '',
                    style: GoogleFonts.rajdhani(
                      fontSize: 14,
                      color: isMe ? const Color(0xFF00D4FF) : Colors.white70,
                    ),
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: EdgeInsets.only(
              top: 4,
              left: isMe ? 0 : 36,
              right: isMe ? 4 : 0,
            ),
            child: Text(
              timeStr,
              style: GoogleFonts.rajdhani(fontSize: 10, color: Colors.white24),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      decoration: const BoxDecoration(
        color: Color(0xFF111827),
        border: Border(top: BorderSide(color: Color(0xFF1E2D45))),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF0A0E1A),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFF1E2D45)),
              ),
              child: TextField(
                controller: _controller,
                style: GoogleFonts.rajdhani(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Share an idea...',
                  hintStyle: GoogleFonts.rajdhani(color: Colors.white24, fontSize: 14),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
                maxLines: null,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: _sendMessage,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF00D4FF),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF00D4FF).withValues(alpha: 0.3),
                    blurRadius: 12,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: _sending
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2),
                    )
                  : const Icon(Icons.send, color: Colors.black, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}