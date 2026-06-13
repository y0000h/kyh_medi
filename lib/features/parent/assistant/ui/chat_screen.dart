// lib/features/parent/assistant/ui/chat_screen.dart
//
// 부모 모드 도우미 챗봇 — Supabase Edge Function `chat`을 통해
// LLM(Gemini/OpenAI) 응답을 받는다. system prompt는 assets/prompts/medi_helper.md.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/theme/tokens.dart';

class _Message {
  final String text;
  final bool fromUser;
  _Message(this.text, {required this.fromUser});

  Map<String, String> toOpenAi() => {
        'role': fromUser ? 'user' : 'assistant',
        'content': text,
      };
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});
  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  static const _promptPath = 'assets/prompts/medi_helper.md';

  String? _systemPrompt;
  final List<_Message> _messages = [];
  final TextEditingController _ctrl = TextEditingController();
  final ScrollController _scroll = ScrollController();
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadPrompt();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _loadPrompt() async {
    final p = await rootBundle.loadString(_promptPath);
    if (!mounted) return;
    setState(() {
      _systemPrompt = p;
      _messages.add(_Message(
        '안녕하세요. 약 복용 도우미입니다. 약에 대해 궁금하신 점이나 앱 사용법을 편하게 물어보세요.',
        fromUser: false,
      ));
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _send() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty || _loading || _systemPrompt == null) return;

    setState(() {
      _messages.add(_Message(text, fromUser: true));
      _ctrl.clear();
      _loading = true;
    });
    _scrollToBottom();

    try {
      final res = await Supabase.instance.client.functions.invoke(
        'chat',
        body: {
          'messages': [
            {'role': 'system', 'content': _systemPrompt!},
            ..._messages.map((m) => m.toOpenAi()),
          ],
        },
      );
      final data = (res.data as Map?)?.cast<String, dynamic>();
      final reply = (data?['reply'] as String?)?.trim();
      if (!mounted) return;
      setState(() {
        _messages.add(_Message(
          (reply == null || reply.isEmpty) ? '(응답 없음)' : reply,
          fromUser: false,
        ));
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _messages.add(_Message('⚠️ 오류: $e', fromUser: false));
        _loading = false;
      });
    }
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('도움 챗봇',
            style: TextStyle(fontWeight: FontWeight.w800)),
        toolbarHeight: 72,
      ),
      body: SafeArea(
        child: _systemPrompt == null
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      controller: _scroll,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 16),
                      itemCount: _messages.length + (_loading ? 1 : 0),
                      itemBuilder: (_, i) {
                        if (_loading && i == _messages.length) {
                          return const _TypingBubble();
                        }
                        return _MessageBubble(message: _messages[i]);
                      },
                    ),
                  ),
                  const Divider(height: 1),
                  _InputBar(
                    controller: _ctrl,
                    onSend: _send,
                    enabled: !_loading,
                  ),
                ],
              ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final _Message message;
  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isUser = message.fromUser;
    final bg = isUser
        ? theme.colorScheme.primary
        : theme.colorScheme.surfaceContainerHighest;
    final fg = isUser
        ? theme.colorScheme.onPrimary
        : theme.colorScheme.onSurface;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isUser ? 18 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 18),
          ),
        ),
        child: Text(
          message.text,
          style: TextStyle(color: fg, fontSize: 17, height: 1.4),
        ),
      ),
    );
  }
}

class _TypingBubble extends StatelessWidget {
  const _TypingBubble();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(18),
            topRight: Radius.circular(18),
            bottomLeft: Radius.circular(4),
            bottomRight: Radius.circular(18),
          ),
        ),
        child: SizedBox(
          width: 40,
          height: 14,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children:
                List.generate(3, (i) => _Dot(delayMs: i * 200)),
          ),
        ),
      ),
    );
  }
}

class _Dot extends StatefulWidget {
  final int delayMs;
  const _Dot({required this.delayMs});
  @override
  State<_Dot> createState() => _DotState();
}

class _DotState extends State<_Dot> with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    Future.delayed(Duration(milliseconds: widget.delayMs), () {
      if (mounted) _c.repeat();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(begin: 0.3, end: 1).animate(_c),
      child: Container(
        width: 9,
        height: 9,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

class _InputBar extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  final bool enabled;
  const _InputBar({
    required this.controller,
    required this.onSend,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 8, 12),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              enabled: enabled,
              minLines: 1,
              maxLines: 4,
              style: const TextStyle(fontSize: 17),
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => onSend(),
              decoration: InputDecoration(
                hintText: enabled ? '메시지를 입력하세요' : '응답 대기 중…',
                filled: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 14,
                ),
                border: const OutlineInputBorder(
                  borderRadius: AppRadius.pillAll,
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          Material(
            color: enabled
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.surfaceContainerHighest,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: enabled ? onSend : null,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Icon(
                  Icons.send,
                  color: enabled
                      ? Theme.of(context).colorScheme.onPrimary
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
