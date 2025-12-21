import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/payment_gateway_model.dart';
import '../../services/payment_service.dart';

class PaymentGatewayItemWidget extends StatelessWidget {
  final PaymentGatewayItem gateway;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback? onDelete;
  final Color? primaryColor;

  const PaymentGatewayItemWidget({
    Key? key,
    required this.gateway,
    required this.isSelected,
    required this.onTap,
    this.onDelete,
    this.primaryColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final effectivePrimaryColor =
        primaryColor ?? Theme.of(context).primaryColor;

    return InkWell(
      onTap: gateway.enabled ? onTap : null,
      child: Container(
        padding: EdgeInsets.all(size.width * 0.04),
        margin: EdgeInsets.only(bottom: size.width * 0.03),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            width: isSelected ? 2 : 1,
            color: isSelected ? effectivePrimaryColor : Colors.grey[300]!,
          ),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: effectivePrimaryColor.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: Row(
          children: [
            // Payment icon/logo
            Container(
              width: size.width * 0.12,
              height: size.width * 0.12,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              padding: EdgeInsets.all(size.width * 0.02),
              child: _buildIcon(size),
            ),
            SizedBox(width: size.width * 0.04),

            // Payment info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    gateway.name,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: gateway.enabled ? Colors.black87 : Colors.grey,
                    ),
                  ),
                  if (gateway.isCard && gateway.lastFourDigits != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        'Ends in **** ${gateway.lastFourDigits}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                  if (!gateway.enabled)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        'Not available',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.red[400],
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Delete button for saved cards
            if (gateway.isCard && onDelete != null)
              IconButton(
                icon: Icon(
                  Icons.delete_outline,
                  color: Colors.red[400],
                  size: 20,
                ),
                onPressed: onDelete,
                padding: const EdgeInsets.all(8),
                constraints: const BoxConstraints(),
              ),

            SizedBox(width: size.width * 0.02),

            // Radio button
            Container(
              width: size.width * 0.06,
              height: size.width * 0.06,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? effectivePrimaryColor : Colors.transparent,
                border: Border.all(
                  width: 2,
                  color: isSelected ? effectivePrimaryColor : Colors.grey[400]!,
                ),
              ),
              alignment: Alignment.center,
              child: isSelected
                  ? Container(
                      width: size.width * 0.03,
                      height: size.width * 0.03,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                      ),
                    )
                  : const SizedBox(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIcon(Size size) {
    if (gateway.isCard && gateway.cardBrand != null) {
      // Try to load card brand image from assets
      return Image.asset(
        PaymentService.getCardBrandImage(gateway.cardBrand),
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return _buildDefaultCardIcon();
        },
      );
    } else if (gateway.image.isNotEmpty) {
      // Check if it's a URL or asset path
      if (gateway.image.startsWith('http')) {
        return CachedNetworkImage(
          imageUrl: gateway.image,
          fit: BoxFit.contain,
          placeholder: (context, url) => const Center(
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          errorWidget: (context, url, error) => _buildDefaultPaymentIcon(),
        );
      } else {
        // Try to load from assets
        return Image.asset(
          gateway.image,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return _buildDefaultPaymentIcon();
          },
        );
      }
    }

    return _buildDefaultPaymentIcon();
  }

  Widget _buildDefaultCardIcon() {
    return Icon(
      Icons.credit_card,
      size: 24,
      color: Colors.grey[600],
    );
  }

  Widget _buildDefaultPaymentIcon() {
    return Icon(
      Icons.payment,
      size: 24,
      color: Colors.grey[600],
    );
  }
}
