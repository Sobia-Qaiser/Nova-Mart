/*import 'package:flutter/material.dart';

class QuantitySelector extends StatelessWidget {
  const QuantitySelector({
    super.key,
    required this.quantity,
    required this.maxQuantity,
    required this.stockStatus,
    required this.onIncrease,
    required this.onDecrease,
  });

  final int quantity;
  final int maxQuantity;
  final String stockStatus;
  final VoidCallback onIncrease;
  final VoidCallback onDecrease;

  @override
  Widget build(BuildContext context) {
    //  Ensure quantity never goes below 1
    final int safeQuantity = quantity < 1 ? 1 : quantity;

    final bool canDecrease = safeQuantity > 1;

    //  Modify canIncrease logic to consider stock status
    final bool canIncrease =
        safeQuantity < maxQuantity && stockStatus != "Limited Stock";

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Minus Button
        _buildButton(
          icon: Icons.remove,
          onPressed: canDecrease ? onDecrease : null,
          isMinus: true,
          isEnabled: canDecrease,
        ),
        const SizedBox(width: 10),
        // Quantity Display
        Text(
          '$safeQuantity',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            fontFamily: 'Poppins',
          ),
        ),
        const SizedBox(width: 10),
        // Plus Button
        _buildButton(
          icon: Icons.add,
          onPressed: canIncrease ? onIncrease : null,
          isMinus: false,
          isEnabled: canIncrease,
        ),
      ],
    );
  }

  Widget _buildButton({
    required IconData icon,
    required VoidCallback? onPressed,
    required bool isMinus,
    required bool isEnabled,
  }) {
    final Color backgroundColor = isMinus
        ? const Color(0xFFF1F1F1)
        : (isEnabled ? const Color(0xFFFF4A49) : const Color(0xFFF1F1F1));

    final Color iconColor = isMinus
        ? (isEnabled ? const Color(0xFFFF4A49) : Colors.grey)
        : (isEnabled ? Colors.white : Colors.grey);

    return GestureDetector(
      onTap: onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          size: 18,
          color: iconColor,
        ),
      ),
    );
  }
}*/



import 'package:flutter/material.dart';

class QuantitySelector extends StatelessWidget {
  const QuantitySelector({
    super.key,
    required this.quantity,
    required this.maxQuantity,
    required this.stockStatus,
    required this.onIncrease,
    required this.onDecrease,
  });

  final int quantity;
  final int maxQuantity;
  final String stockStatus;
  final VoidCallback onIncrease;
  final VoidCallback onDecrease;

  @override
  Widget build(BuildContext context) {
    // Ensure quantity never goes below 1
    final int safeQuantity = quantity < 1 ? 1 : quantity;

    final bool canDecrease = safeQuantity > 1;

    // ✅ Modified canIncrease logic
    final bool canIncrease = stockStatus == "In Stock"
        ? safeQuantity < 10
        : (safeQuantity < maxQuantity && stockStatus != "Limited Stock");

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Minus Button
        _buildButton(
          icon: Icons.remove,
          onPressed: canDecrease ? onDecrease : null,
          isMinus: true,
          isEnabled: canDecrease,
        ),
        const SizedBox(width: 10),

        // Quantity Display
        Text(
          '$safeQuantity',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            fontFamily: 'Poppins',
          ),
        ),
        const SizedBox(width: 10),

        // Plus Button
        _buildButton(
          icon: Icons.add,
          onPressed: canIncrease ? onIncrease : null,
          isMinus: false,
          isEnabled: canIncrease,
        ),
      ],
    );
  }

  Widget _buildButton({
    required IconData icon,
    required VoidCallback? onPressed,
    required bool isMinus,
    required bool isEnabled,
  }) {
    final Color backgroundColor = isMinus
        ? const Color(0xFFF1F1F1)
        : (isEnabled ? const Color(0xFFFF4A49) : const Color(0xFFF1F1F1));

    final Color iconColor = isMinus
        ? (isEnabled ? const Color(0xFFFF4A49) : Colors.grey)
        : (isEnabled ? Colors.white : Colors.grey);

    return GestureDetector(
      onTap: onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          size: 18,
          color: iconColor,
        ),
      ),
    );
  }
}

