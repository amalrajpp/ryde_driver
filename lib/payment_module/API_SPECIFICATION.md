# Payment Module - Backend API Specification

This document describes the API endpoints needed to integrate the payment module with your backend.

## Base URL

```
https://api.yourapp.com/api/v1
```

## Authentication

All requests should include authentication token:

```
Authorization: Bearer {user_token}
```

---

## Endpoints

### 1. Get Payment Configuration

Get payment gateway configuration and settings.

**Endpoint:** `GET /payment/config`

**Response:**
```json
{
  "success": true,
  "data": {
    "stripe": true,
    "razor_pay": true,
    "paystack": false,
    "cash_free": false,
    "flutter_wave": false,
    "khalti_pay": false,
    "stripe_publishable_key": "pk_test_...",
    "razorpay_api_key": "rzp_test_...",
    "environment": "test",
    "currency_code": "USD",
    "currency_symbol": "$",
    "minimum_amount": "10",
    "enable_save_card": true
  }
}
```

---

### 2. Get Payment Gateways

Get list of available payment methods including saved cards.

**Endpoint:** `GET /payment/gateways`

**Query Parameters:**
- `user_id` (required): User ID

**Response:**
```json
{
  "success": true,
  "data": [
    {
      "id": "card_1",
      "gateway": "Visa",
      "type": "stripe",
      "enabled": true,
      "image": "https://example.com/visa.png",
      "url": "pm_1234567890",
      "is_card": true,
      "last_four_digits": "4242",
      "card_brand": "visa"
    },
    {
      "id": "stripe",
      "gateway": "Credit/Debit Card",
      "type": "stripe",
      "enabled": true,
      "image": "https://example.com/stripe.png",
      "url": "",
      "is_card": false
    },
    {
      "id": "razorpay",
      "gateway": "RazorPay",
      "type": "razorpay",
      "enabled": true,
      "image": "https://example.com/razorpay.png",
      "url": "",
      "is_card": false
    }
  ]
}
```

---

### 3. Create Stripe Setup Intent

Create a setup intent for adding a new card.

**Endpoint:** `POST /payment/stripe/setup-intent`

**Request Body:**
```json
{
  "user_id": "user_123"
}
```

**Response:**
```json
{
  "success": true,
  "message": "Setup intent created",
  "data": {
    "client_secret": "seti_1234567890_secret_abcdef",
    "customer_id": "cus_1234567890",
    "test_environment": true
  }
}
```

---

### 4. Save Card Details

Save card details after successful setup intent.

**Endpoint:** `POST /payment/stripe/save-card`

**Request Body:**
```json
{
  "user_id": "user_123",
  "payment_method_id": "pm_1234567890",
  "card_brand": "visa",
  "last_four_digits": "4242"
}
```

**Response:**
```json
{
  "success": true,
  "message": "Card saved successfully",
  "data": {
    "id": "card_3",
    "gateway": "Visa",
    "type": "stripe",
    "enabled": true,
    "image": "visa",
    "url": "pm_1234567890",
    "is_card": true,
    "last_four_digits": "4242",
    "card_brand": "visa"
  }
}
```

---

### 5. Delete Saved Card

Delete a saved card.

**Endpoint:** `DELETE /payment/cards/{card_token}`

**Request Body:**
```json
{
  "user_id": "user_123"
}
```

**Response:**
```json
{
  "success": true,
  "message": "Card deleted successfully"
}
```

---

### 6. Process Payment

Process a payment with selected gateway.

**Endpoint:** `POST /payment/process`

**Request Body:**
```json
{
  "user_id": "user_123",
  "amount": 50.00,
  "gateway_id": "stripe",
  "gateway_type": "stripe",
  "payment_method_id": "pm_1234567890",  // Optional, for saved cards
  "metadata": {
    "source": "payment_module",
    "timestamp": "2024-01-01T12:00:00Z"
  }
}
```

**Response (Success):**
```json
{
  "success": true,
  "message": "Payment processed successfully",
  "transaction_id": "pay_1234567890",
  "data": {
    "id": "txn_1234567890",
    "user_id": "user_123",
    "amount": 50.00,
    "currency_code": "USD",
    "currency_symbol": "$",
    "status": "success",
    "gateway": "stripe",
    "transaction_id": "pay_1234567890",
    "payment_intent_id": "pi_1234567890",
    "created_at": "2024-01-01T12:00:00Z",
    "completed_at": "2024-01-01T12:00:05Z"
  }
}
```

**Response (Failure):**
```json
{
  "success": false,
  "message": "Payment failed: Insufficient funds",
  "error": "card_declined"
}
```

---

### 7. Get Payment History

Get user's payment transaction history.

**Endpoint:** `GET /payment/history`

**Query Parameters:**
- `user_id` (required): User ID
- `page` (optional): Page number (default: 1)
- `per_page` (optional): Items per page (default: 20)

**Response:**
```json
{
  "success": true,
  "data": [
    {
      "id": "txn_1234567890",
      "user_id": "user_123",
      "amount": 50.00,
      "currency_code": "USD",
      "currency_symbol": "$",
      "status": "success",
      "gateway": "stripe",
      "transaction_id": "pay_1234567890",
      "payment_intent_id": "pi_1234567890",
      "created_at": "2024-01-01T12:00:00Z",
      "completed_at": "2024-01-01T12:00:05Z",
      "metadata": {
        "source": "payment_module"
      }
    }
  ],
  "meta": {
    "current_page": 1,
    "per_page": 20,
    "total": 50,
    "total_pages": 3
  }
}
```

---

### 8. Get Transaction Details

Get details of a specific transaction.

**Endpoint:** `GET /payment/transactions/{transaction_id}`

**Response:**
```json
{
  "success": true,
  "data": {
    "id": "txn_1234567890",
    "user_id": "user_123",
    "amount": 50.00,
    "currency_code": "USD",
    "currency_symbol": "$",
    "status": "success",
    "gateway": "stripe",
    "transaction_id": "pay_1234567890",
    "payment_intent_id": "pi_1234567890",
    "error_message": null,
    "created_at": "2024-01-01T12:00:00Z",
    "completed_at": "2024-01-01T12:00:05Z",
    "metadata": {
      "source": "payment_module",
      "ip_address": "192.168.1.1",
      "user_agent": "..."
    }
  }
}
```

---

## Error Responses

All error responses follow this format:

```json
{
  "success": false,
  "message": "Error description",
  "error": "error_code",
  "details": {
    "field": "error details"
  }
}
```

### Common Error Codes

| Code | Description |
|------|-------------|
| `unauthorized` | Invalid or missing authentication token |
| `invalid_amount` | Amount is below minimum or invalid |
| `payment_failed` | Payment processing failed |
| `card_declined` | Card was declined |
| `insufficient_funds` | Insufficient funds |
| `invalid_card` | Invalid card details |
| `card_not_found` | Saved card not found |
| `gateway_error` | Payment gateway error |
| `server_error` | Internal server error |

---

## Webhook Endpoints

### Payment Success Webhook

Stripe/other gateways will send webhook to:

**Endpoint:** `POST /webhooks/payment/success`

**Payload:**
```json
{
  "event": "payment.success",
  "transaction_id": "pay_1234567890",
  "amount": 50.00,
  "currency": "USD",
  "status": "succeeded",
  "payment_method": "pm_1234567890",
  "metadata": {
    "user_id": "user_123"
  }
}
```

### Payment Failed Webhook

**Endpoint:** `POST /webhooks/payment/failed`

**Payload:**
```json
{
  "event": "payment.failed",
  "transaction_id": "pay_1234567890",
  "amount": 50.00,
  "currency": "USD",
  "status": "failed",
  "error": {
    "code": "card_declined",
    "message": "Your card was declined"
  },
  "metadata": {
    "user_id": "user_123"
  }
}
```

---

## Database Schema

### Suggested Tables

#### transactions

```sql
CREATE TABLE transactions (
  id VARCHAR(255) PRIMARY KEY,
  user_id VARCHAR(255) NOT NULL,
  amount DECIMAL(10, 2) NOT NULL,
  currency_code VARCHAR(3) NOT NULL,
  currency_symbol VARCHAR(10),
  status ENUM('pending', 'processing', 'success', 'failed', 'cancelled'),
  gateway VARCHAR(50),
  transaction_id VARCHAR(255),
  payment_intent_id VARCHAR(255),
  error_message TEXT,
  metadata JSON,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  completed_at TIMESTAMP NULL,
  INDEX idx_user_id (user_id),
  INDEX idx_status (status),
  INDEX idx_created_at (created_at)
);
```

#### saved_cards

```sql
CREATE TABLE saved_cards (
  id VARCHAR(255) PRIMARY KEY,
  user_id VARCHAR(255) NOT NULL,
  payment_method_id VARCHAR(255) NOT NULL UNIQUE,
  card_brand VARCHAR(50),
  last_four_digits VARCHAR(4),
  expiry_month INT,
  expiry_year INT,
  is_default BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX idx_user_id (user_id)
);
```

#### payment_config

```sql
CREATE TABLE payment_config (
  id INT PRIMARY KEY AUTO_INCREMENT,
  stripe_enabled BOOLEAN DEFAULT FALSE,
  razorpay_enabled BOOLEAN DEFAULT FALSE,
  paystack_enabled BOOLEAN DEFAULT FALSE,
  stripe_publishable_key VARCHAR(255),
  razorpay_key VARCHAR(255),
  environment VARCHAR(10) DEFAULT 'test',
  currency_code VARCHAR(3) DEFAULT 'USD',
  currency_symbol VARCHAR(10) DEFAULT '$',
  minimum_amount DECIMAL(10, 2) DEFAULT 10.00,
  enable_save_card BOOLEAN DEFAULT TRUE,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);
```

---

## Security Considerations

### 1. API Key Security

- Never expose secret keys to client
- Use environment variables
- Rotate keys regularly
- Use different keys for test/live

### 2. Request Validation

- Validate all amounts on server
- Check user authentication
- Verify user owns the card
- Rate limit requests

### 3. Data Protection

- Never store card numbers
- Store only payment method IDs
- Use HTTPS for all requests
- Encrypt sensitive data at rest

### 4. Webhook Verification

- Verify webhook signatures
- Check webhook source IP
- Use idempotency keys
- Handle duplicate webhooks

---

## Implementation Checklist

### Backend Setup

- [ ] Set up Stripe account
- [ ] Install Stripe SDK (PHP/Node/Python/etc.)
- [ ] Create database tables
- [ ] Implement API endpoints
- [ ] Set up webhook handlers
- [ ] Configure webhook URLs in Stripe dashboard
- [ ] Implement error handling
- [ ] Add logging and monitoring
- [ ] Set up rate limiting
- [ ] Test with Stripe test cards

### Security

- [ ] Use HTTPS
- [ ] Validate all inputs
- [ ] Implement authentication
- [ ] Verify webhook signatures
- [ ] Use environment variables for keys
- [ ] Implement CSRF protection
- [ ] Add request rate limiting
- [ ] Log all transactions
- [ ] Set up alerts for failed payments

### Testing

- [ ] Test with Stripe test cards
- [ ] Test webhook handling
- [ ] Test error scenarios
- [ ] Load testing
- [ ] Security testing

---

## Example Backend Implementation (Node.js)

```javascript
const express = require('express');
const stripe = require('stripe')(process.env.STRIPE_SECRET_KEY);

const app = express();
app.use(express.json());

// Get payment configuration
app.get('/api/v1/payment/config', async (req, res) => {
  res.json({
    success: true,
    data: {
      stripe: true,
      stripe_publishable_key: process.env.STRIPE_PUBLISHABLE_KEY,
      currency_code: 'USD',
      currency_symbol: '$',
      minimum_amount: '10',
      enable_save_card: true,
    }
  });
});

// Create setup intent
app.post('/api/v1/payment/stripe/setup-intent', async (req, res) => {
  try {
    const { user_id } = req.body;
    
    // Create or get Stripe customer
    const customer = await stripe.customers.create({
      metadata: { user_id }
    });
    
    // Create setup intent
    const setupIntent = await stripe.setupIntents.create({
      customer: customer.id,
      payment_method_types: ['card'],
    });
    
    res.json({
      success: true,
      message: 'Setup intent created',
      data: {
        client_secret: setupIntent.client_secret,
        customer_id: customer.id,
        test_environment: true,
      }
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message,
    });
  }
});

// Process payment
app.post('/api/v1/payment/process', async (req, res) => {
  try {
    const { user_id, amount, payment_method_id } = req.body;
    
    // Create payment intent
    const paymentIntent = await stripe.paymentIntents.create({
      amount: Math.round(amount * 100), // Convert to cents
      currency: 'usd',
      payment_method: payment_method_id,
      confirm: true,
      metadata: { user_id }
    });
    
    // Save transaction to database
    // ...
    
    res.json({
      success: true,
      message: 'Payment processed successfully',
      transaction_id: paymentIntent.id,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message,
    });
  }
});

app.listen(3000, () => {
  console.log('Server running on port 3000');
});
```

---

## Support

For Stripe-specific questions, refer to:
- [Stripe API Reference](https://stripe.com/docs/api)
- [Stripe Payment Intents](https://stripe.com/docs/payments/payment-intents)
- [Stripe Setup Intents](https://stripe.com/docs/payments/setup-intents)
- [Stripe Webhooks](https://stripe.com/docs/webhooks)

---

**Last Updated:** December 2024
