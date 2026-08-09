import 'package:flutter/material.dart';
import '../../core/api/api_client.dart';
import '../../core/theme/app_theme.dart';

class _ChatMessage {
  final String role;
  final String content;
  _ChatMessage(this.role, this.content);
}

class AiChatPage extends StatefulWidget {
  const AiChatPage({super.key});
  @override
  State<AiChatPage> createState() => _AiChatPageState();
}

class _AiChatPageState extends State<AiChatPage> {
  final List<_ChatMessage> _messages = [
    _ChatMessage('assistant',
        'Halo! Saya Asisten Perelek. Tanya apa saja seputar tagihan, iuran, status pembayaran, atau cara pakai aplikasi ini.'),
  ];
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  bool _sending = false;

  Future<void> _send() async {
    final text = _textController.text.trim();
    if (text.isEmpty || _sending) return;

    final historyToSend =
        _messages.map((m) => {'role': m.role, 'content': m.content}).toList();

    setState(() {
      _messages.add(_ChatMessage('user', text));
      _sending = true;
    });
    _textController.clear();

    try {
      final res = await ApiClient().post('/ai/chat', data: {
        'message': text,
        'history': historyToSend,
      });
      if (res.data['success'] == true) {
        final reply = res.data['data']['reply'] as String;
        setState(() => _messages.add(_ChatMessage('assistant', reply)));
      } else {
        setState(() => _messages.add(_ChatMessage(
            'assistant', 'Maaf, terjadi kesalahan. Coba tanyakan ulang ya.')));
      }
    } catch (e) {
      setState(() => _messages.add(_ChatMessage('assistant',
          'Maaf, asisten AI sedang tidak bisa dihubungi. Coba lagi sebentar lagi.')));
    }

    if (mounted) setState(() => _sending = false);
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final display = <_ChatMessage>[
      if (_sending) _ChatMessage('typing', ''),
      ..._messages.reversed,
    ];

    return Scaffold(
      backgroundColor: context.colorBg,
      body: Column(children: [
        // ── Gradient header ──
        Container(
          padding: EdgeInsets.fromLTRB(
              4,
              MediaQuery.of(context).padding.top + 12,
              16,
              16), // Diubah kiri ke 4 agar tombol back pas
          decoration: BoxDecoration(
            gradient: context.headerGradient,
            borderRadius:
                const BorderRadius.vertical(bottom: Radius.circular(24)),
          ),
          child: Row(children: [
            // Tombol Kembali (Back Button)
            IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: Colors.white, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
            const SizedBox(width: 4),
            Container(
              width: 46,
              height: 46,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.18),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Image.asset('assets/images/robot-cerdas.png',
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) =>
                      const Icon(Icons.smart_toy_rounded, color: Colors.white)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Asisten Perelek',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white)),
                  Text('Ditenagai Groq AI',
                      style: TextStyle(
                          fontSize: 11, color: Colors.white.withOpacity(0.8))),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: AppColors.success.withOpacity(0.5), width: 1),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                        color: AppColors.success, shape: BoxShape.circle)),
                const SizedBox(width: 5),
                const Text('Online',
                    style: TextStyle(
                        fontSize: 11,
                        color: AppColors.success,
                        fontWeight: FontWeight.w600)),
              ]),
            ),
          ]),
        ),

        // ── Chat messages ──
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            reverse: true,
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            itemCount: display.length,
            itemBuilder: (context, index) {
              final msg = display[index];
              if (msg.role == 'typing') return const _TypingBubble();
              return _Bubble(message: msg);
            },
          ),
        ),

        // ── Input bar ──
        SafeArea(
          top: false,
          child: Container(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            decoration: BoxDecoration(
              color: context.colorSurface,
              border:
                  Border(top: BorderSide(color: context.colorBorder, width: 1)),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 12,
                    offset: const Offset(0, -3)),
              ],
            ),
            child: Row(children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: context.colorSurfaceAlt,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: context.colorBorder),
                  ),
                  child: TextField(
                    controller: _textController,
                    minLines: 1,
                    maxLines: 4,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _send(),
                    style: TextStyle(
                        fontSize: 14, color: context.colorTextPrimary),
                    decoration: InputDecoration(
                      hintText: 'Tulis pertanyaan...',
                      hintStyle:
                          TextStyle(color: context.colorTextHint, fontSize: 14),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                decoration: BoxDecoration(
                    gradient: AppGradients.brand,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                          color: AppColors.primary.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 3)),
                    ]),
                child: Material(
                  color: Colors.transparent,
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: _sending ? null : _send,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: _sending
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2))
                          : const Icon(Icons.send_rounded,
                              color: Colors.white, size: 20),
                    ),
                  ),
                ),
              ),
            ]),
          ),
        ),
      ]),
    );
  }
}

class _Bubble extends StatelessWidget {
  final _ChatMessage message;
  const _Bubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == 'user';
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            Container(
              width: 32,
              height: 32,
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Image.asset('assets/images/robot-cerdas.png',
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Icon(
                      Icons.smart_toy_rounded,
                      size: 18,
                      color: AppColors.primary)),
            ),
            const SizedBox(width: 8),
          ],
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.72),
            decoration: BoxDecoration(
              gradient: isUser ? AppGradients.brand : null,
              color: isUser ? null : context.colorSurface,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(18),
                topRight: const Radius.circular(18),
                bottomLeft: Radius.circular(isUser ? 18 : 4),
                bottomRight: Radius.circular(isUser ? 4 : 18),
              ),
              border: isUser ? null : Border.all(color: context.colorBorder),
              boxShadow: [
                BoxShadow(
                    color: Colors.black
                        .withOpacity(context.isDarkMode ? 0.15 : 0.04),
                    blurRadius: 6,
                    offset: const Offset(0, 2)),
              ],
            ),
            child: Text(
              message.content,
              style: TextStyle(
                fontSize: 13.5,
                color: isUser ? Colors.white : context.colorTextPrimary,
                height: 1.45,
              ),
            ),
          ),
          if (isUser) const SizedBox(width: 4),
        ],
      ),
    );
  }
}

class _TypingBubble extends StatelessWidget {
  const _TypingBubble();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            width: 32,
            height: 32,
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Image.asset('assets/images/robot-cerdas.png',
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Icon(
                    Icons.smart_toy_rounded,
                    size: 18,
                    color: AppColors.primary)),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: context.colorSurface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: context.colorBorder),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              _Dot(delay: 0),
              const SizedBox(width: 4),
              _Dot(delay: 200),
              const SizedBox(width: 4),
              _Dot(delay: 400),
            ]),
          ),
        ],
      ),
    );
  }
}

class _Dot extends StatefulWidget {
  final int delay;
  const _Dot({required this.delay});
  @override
  State<_Dot> createState() => _DotState();
}

class _DotState extends State<_Dot> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _anim = Tween<double>(begin: 0, end: 1)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
    Future.delayed(Duration(milliseconds: widget.delay),
        () => mounted ? _ctrl.repeat(reverse: true) : null);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
        opacity: _anim,
        child: Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
                color: context.colorTextHint, shape: BoxShape.circle)),
      );
}
