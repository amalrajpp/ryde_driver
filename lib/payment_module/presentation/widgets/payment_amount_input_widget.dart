import 'package:flutter/material.dart';

class PaymentAmountInputWidget extends StatefulWidget {
  final TextEditingController controller;
  final String currencySymbol;
  final Function(String) onChanged;

  const PaymentAmountInputWidget({
    Key? key,
    required this.controller,
    required this.currencySymbol,
    required this.onChanged,
  }) : super(key: key);

  @override
  State<PaymentAmountInputWidget> createState() =>
      _PaymentAmountInputWidgetState();
}

class _PaymentAmountInputWidgetState extends State<PaymentAmountInputWidget> {
  double? _selectedAmount;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select Amount',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildAmountButton(200)),
            const SizedBox(width: 12),
            Expanded(child: _buildAmountButton(400)),
            const SizedBox(width: 12),
            Expanded(child: _buildAmountButton(600)),
          ],
        ),
        if (_selectedAmount != null) ...[
          const SizedBox(height: 12),
          Text(
            'Selected: ${widget.currencySymbol}${_selectedAmount!.toStringAsFixed(0)}',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildAmountButton(double amount) {
    final isSelected = _selectedAmount == amount;
    return ElevatedButton(
      onPressed: () {
        setState(() {
          _selectedAmount = amount;
          widget.controller.text = amount.toStringAsFixed(2);
          widget.onChanged(amount.toStringAsFixed(2));
        });
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? Colors.black : Colors.grey[200],
        foregroundColor: isSelected ? Colors.white : Colors.black,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: isSelected ? Colors.black : Colors.grey[300]!,
            width: 2,
          ),
        ),
        elevation: isSelected ? 2 : 0,
      ),
      child: Text(
        '${widget.currencySymbol}${amount.toStringAsFixed(0)}',
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }
}
