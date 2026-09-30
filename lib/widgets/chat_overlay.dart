import 'package:GeniusHouse/services/auth_service.dart';
import 'package:GeniusHouse/widgets/floating_chat_button.dart';
import 'package:flutter/material.dart';

class ChatOverlay extends StatefulWidget {
  final Widget child;
  final AuthService? authService;
  final bool isGuest;

  const ChatOverlay({
    super.key,
    required this.child,
    this.authService,
    required this.isGuest,
  });

  @override
  State<ChatOverlay> createState() => _ChatOverlayState();
}

class _ChatOverlayState extends State<ChatOverlay> {
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        FloatingChatButton(
          authService: widget.authService,
          isGuest: widget.isGuest,
        ),
      ],
    );
  }
}
