# Xendit Payment Integration Setup

This document explains how to set up Xendit payment integration for QRIS and Virtual Account payments in the KiosDarma application.

## Prerequisites

1. Xendit account (sign up at https://xendit.co)
2. Xendit API credentials (Secret Key)

## Setup Instructions

### 1. Get Your Xendit Secret Key

1. Log in to your Xendit dashboard
2. Go to Settings > API Keys
3. Copy your Secret Key (starts with `xnd_secret_...`)

### 2. Configure Environment Variables

1. Create a `.env` file in the root directory of your project (if it doesn't exist)
2. Add your Xendit Secret Key to the `.env` file:

```
XENDIT_SECRET_KEY=your_xendit_secret_key_here
```

**Important:** 
- Never commit the `.env` file to version control
- The `.env` file is already in `.gitignore`
- Make sure to add `XENDIT_SECRET_KEY` to your production environment variables

### 3. Public Key

The public key is already configured in the code:
- Public Key: `xnd_public_development_uXR8rpP0d1GJyjhsNJQsUTN1_YA7QEsq3PXRs5Fa2TZ9ofFPaRgyOQHUkaWWjpP`

This is a development key. For production, you'll need to:
1. Get your production public key from Xendit dashboard
2. Update the `publicKey` constant in `lib/services/xendit_service.dart`

## Payment Methods

### QRIS Payment

1. Customer selects "QRIS" as payment method
2. System creates a QRIS code via Xendit API
3. QR code is displayed for customer to scan
4. System polls Xendit API to check payment status
5. Payment is automatically verified when completed

### Virtual Account Payment

1. Customer selects "Virtual Account" as payment method
2. Customer selects a bank (BCA, BNI, BRI, Mandiri, or Permata)
3. System creates a Virtual Account via Xendit API
4. Virtual Account number is displayed to customer
5. Customer transfers money to the Virtual Account
6. System polls Xendit API to check payment status
7. Payment is automatically verified when completed

## Available Banks for Virtual Account

- Bank Central Asia (BCA)
- Bank Negara Indonesia (BNI)
- Bank Rakyat Indonesia (BRI)
- Bank Mandiri
- Bank Permata

## API Endpoints Used

- Create QRIS: `POST /qr_codes`
- Get QRIS Status: `GET /qr_codes/{id}`
- Create Virtual Account: `POST /virtual_accounts`
- Get Virtual Account Status: `GET /virtual_accounts/{id}`

## Testing

### Development Mode

The application uses Xendit's development/sandbox environment. You can test payments using:

1. **QRIS Testing:**
   - Use Xendit's test QRIS codes
   - Payment status can be manually updated in Xendit dashboard

2. **Virtual Account Testing:**
   - Virtual Accounts created in development mode are for testing only
   - Use Xendit's test accounts for verification

### Production Mode

1. Update the public key to production key
2. Ensure your Xendit account is activated for production
3. Configure webhook URLs for payment callbacks (optional but recommended)

## Troubleshooting

### Error: "Xendit secret key is not set"

- Make sure you've added `XENDIT_SECRET_KEY` to your `.env` file
- Restart your application after adding the key
- Check that the `.env` file is in the root directory

### Error: "Failed to create QRIS/VA"

- Verify your Xendit secret key is correct
- Check your Xendit account balance and limits
- Ensure you're using the correct API endpoint (development vs production)
- Check Xendit dashboard for API error logs

### Payment Status Not Updating

- The app polls Xendit API every 3-5 seconds
- If status doesn't update, manually check in Xendit dashboard
- Verify your Xendit account has proper webhook configuration (for automatic updates)

## Security Notes

1. **Never expose your Secret Key:**
   - Secret key should only be in `.env` file
   - Never commit `.env` to version control
   - Use environment variables in production

2. **Use HTTPS:**
   - All API calls to Xendit use HTTPS
   - Ensure your callback URLs use HTTPS in production

3. **Validate Payments:**
   - Always verify payment status on your server
   - Use webhooks for real-time payment notifications
   - Don't rely solely on client-side status checks

## Additional Resources

- Xendit Documentation: https://docs.xendit.co
- Xendit Dashboard: https://dashboard.xendit.co
- Xendit Support: support@xendit.co

## Support

If you encounter any issues with the Xendit integration, please:
1. Check the Xendit documentation
2. Review error messages in the application logs
3. Check your Xendit dashboard for API logs
4. Contact Xendit support if needed

