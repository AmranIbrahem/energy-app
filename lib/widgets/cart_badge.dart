import 'package:flutter/material.dart';
import 'package:GeniusHouse/services/cart_service.dart';

class CartBadge extends StatefulWidget {
  final Widget child;

  const CartBadge({super.key, required this.child});

  @override
  State<CartBadge> createState() => _CartBadgeState();
}

class _CartBadgeState extends State<CartBadge> {
  int _itemCount = 0;

  @override
  void initState() {
    super.initState();
    _loadCartCount();
  }

  Future<void> _loadCartCount() async {
    await CartService.instance.loadCart();
    setState(() {
      _itemCount = CartService.instance.totalQuantity;
    });
  }

  void _refresh() {
    setState(() {
      _itemCount = CartService.instance.totalQuantity;
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      builder: (context, snapshot) {
        return Stack(
          clipBehavior: Clip.none,
          children: [
            widget.child,
            if (_itemCount > 0)
              Positioned(
                right: -4,
                top: -4,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 18,
                    minHeight: 18,
                  ),
                  child: Text(
                    '$_itemCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        );
      },
      stream: null,
    );
  }
}
