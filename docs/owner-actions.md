# Owner Action Checklist
**KiosDarma (PPSI) - External Setup & Configuration**

This document lists all configuration and setup tasks that must be performed outside the codebase (Firebase Console, DNS, third-party services, etc.).

---

## 🔥 Firebase Configuration

### F1. Firebase Project Setup ✅ (Assumed Complete)
- [x] Firebase project created: `gunadarma-pos-marketplace`
- [x] Realtime Database configured
- [x] Storage bucket configured
- [x] Authentication enabled (Email/Password)

### F2. Firebase Security Rules

#### Database Rules
- [ ] **Deploy Database Rules**
  - File: `firebase_database.rules.json`
  - Command: `firebase deploy --only database`
  - **Action**: Review and deploy the rules file to production
  - **Verify**: Rules are active in Firebase Console > Realtime Database > Rules

#### Storage Rules
- [ ] **Deploy Storage Rules**
  - File: `storage.rules`
  - Command: `firebase deploy --only storage`
  - **Action**: Review and deploy the rules file to production
  - **Verify**: Rules are active in Firebase Console > Storage > Rules
  - **Note**: Review product image access rules (see audit P2-004)

### F3. Firebase Authentication Settings

- [ ] **Email Verification Template**
  - Location: Firebase Console > Authentication > Templates
  - **Action**: Customize email verification template (if needed)
  - **Recommendation**: Make it match your brand

- [ ] **Password Reset Template**
  - Location: Firebase Console > Authentication > Templates
  - **Action**: Customize password reset email template

- [ ] **Enable Email Verification Enforcement** (Recommended)
  - Location: Firebase Console > Authentication > Settings > User actions
  - **Action**: Consider requiring email verification (aligns with audit recommendation P2-003)

- [ ] **Configure Authorized Domains** (for web)
  - Location: Firebase Console > Authentication > Settings > Authorized domains
  - **Action**: Add production domain if deploying web version

### F4. Firebase Environment Configuration

- [ ] **Create `.env` File** (if not exists)
  - Location: Root directory (`ppsi/.env`)
  - **Required Variables**:
    ```env
    # Firebase Web Config
    WEB_API_KEY=your_web_api_key
    WEB_AUTH_DOMAIN=your_project.firebaseapp.com
    WEB_PROJECT_ID=gunadarma-pos-marketplace
    WEB_STORAGE_BUCKET=your_storage_bucket.appspot.com
    WEB_MESSAGING_SENDER_ID=your_sender_id
    WEB_APP_ID=your_web_app_id
    WEB_MEASUREMENT_ID=your_measurement_id
    
    # Firebase Android Config
    ANDROID_API_KEY=your_android_api_key
    ANDROID_APP_ID=your_android_app_id
    ANDROID_MESSAGING_SENDER_ID=your_sender_id
    ANDROID_PROJECT_ID=gunadarma-pos-marketplace
    ANDROID_STORAGE_BUCKET=your_storage_bucket.appspot.com
    
    # Firebase iOS Config
    IOS_API_KEY=your_ios_api_key
    IOS_APP_ID=your_ios_app_id
    IOS_MESSAGING_SENDER_ID=your_sender_id
    IOS_PROJECT_ID=gunadarma-pos-marketplace
    IOS_STORAGE_BUCKET=your_storage_bucket.appspot.com
    IOS_BUNDLE_ID=com.example.ppsi
    
    # Firebase macOS Config
    MACOS_API_KEY=your_macos_api_key
    MACOS_APP_ID=your_macos_app_id
    MACOS_MESSAGING_SENDER_ID=your_sender_id
    MACOS_PROJECT_ID=gunadarma-pos-marketplace
    MACOS_STORAGE_BUCKET=your_storage_bucket.appspot.com
    MACOS_BUNDLE_ID=com.example.ppsi
    
    # Firebase Windows Config
    WINDOWS_API_KEY=your_windows_api_key
    WINDOWS_AUTH_DOMAIN=your_project.firebaseapp.com
    WINDOWS_PROJECT_ID=gunadarma-pos-marketplace
    WINDOWS_STORAGE_BUCKET=your_storage_bucket.appspot.com
    WINDOWS_MESSAGING_SENDER_ID=your_sender_id
    WINDOWS_APP_ID=your_windows_app_id
    WINDOWS_MEASUREMENT_ID=your_measurement_id
    
    # Encryption Key (CRITICAL - Generate Strong Key)
    ENCRYPTION_KEY=your_secure_32_character_encryption_key_here_minimum
    
    # Xendit Payment Gateway (Currently Disabled)
    XENDIT_SECRET_KEY=your_xendit_secret_key
    XENDIT_PUBLIC_KEY=your_xendit_public_key
    ```
  - **How to Get Values**:
    - Firebase Console > Project Settings > General > Your apps
    - Copy values from `google-services.json` (Android) and `GoogleService-Info.plist` (iOS)
    - Or use FlutterFire CLI: `flutterfire configure`

- [ ] **Generate Encryption Key**
  - **Action**: Generate a secure 32+ character encryption key
  - **Methods**:
    ```bash
    # Option 1: Using OpenSSL
    openssl rand -base64 32
    
    # Option 2: Using Python
    python -c "import secrets; print(secrets.token_urlsafe(32))"
    
    # Option 3: Online generator (use trusted source)
    # Generate at least 32 random characters
    ```
  - **Security**: 
    - Store securely (password manager)
    - Never commit to git
    - Document key rotation procedure
    - **CRITICAL**: If key is lost, encrypted data cannot be decrypted

- [ ] **Verify `.env` in `.gitignore`**
  - File: `.gitignore` (should already include `.env`)
  - **Verify**: Line 14 should contain `.env`
  - **Action**: Ensure `.env` file is not committed to version control

### F5. Firebase Monitoring & Observability

- [ ] **Enable Firebase Crashlytics** (Recommended)
  - Location: Firebase Console > Crashlytics
  - **Action**: Enable and integrate (see audit recommendation P2-015)
  - **Steps**:
    1. Add `firebase_crashlytics` to `pubspec.yaml`
    2. Initialize in `main.dart`
    3. Configure for production builds

- [ ] **Enable Firebase Performance Monitoring** (Optional but Recommended)
  - Location: Firebase Console > Performance
  - **Action**: Enable to track app performance metrics
  - **Steps**: Add `firebase_performance` to `pubspec.yaml`

- [ ] **Set Up Firebase Alerts**
  - Location: Firebase Console > Alerts
  - **Action**: Configure alerts for:
    - Database usage spikes
    - Storage usage limits
    - Authentication failures
    - Crash rate increases

### F6. Firebase Backup & Recovery

- [ ] **Configure Automated Backups**
  - Location: Firebase Console > Realtime Database > Backups
  - **Action**: Enable daily backups
  - **Retention**: Configure retention period (recommend 30 days minimum)

- [ ] **Test Backup Restoration**
  - **Action**: Periodically test backup restoration procedure
  - **Document**: Document restore procedure for disaster recovery

- [ ] **Set Up Storage Lifecycle Rules** (Optional)
  - Location: Firebase Console > Storage > Rules
  - **Action**: Configure automatic deletion of old files if needed

---

## 💳 Xendit Payment Gateway Setup

### X1. Xendit Account Configuration

- [ ] **Create/Verify Xendit Account**
  - URL: https://www.xendit.co/
  - **Action**: 
    - Create account if not exists
    - Verify account (email, business info)
    - Complete KYC if required for production

- [ ] **Get API Keys**
  - Location: Xendit Dashboard > Settings > API Keys
  - **Required Keys**:
    - Secret Key (starts with `xnd_secret_...`)
    - Public Key (development or production)
  - **Action**: Copy keys to `.env` file (see F4 above)

- [ ] **Configure Webhook URLs** (If using webhooks)
  - Location: Xendit Dashboard > Settings > Webhooks
  - **Action**: Add webhook URLs for payment status updates
  - **URL Format**: `https://your-domain.com/webhook/xendit`

- [ ] **Enable Production Mode** (When ready)
  - **Action**: Switch from development to production environment
  - **Note**: Requires account verification and activation

### X2. Xendit Payment Methods

- [ ] **Verify QRIS Setup**
  - **Action**: Test QRIS payment flow in development
  - **Documentation**: See `XENDIT_SETUP.md`

- [ ] **Verify Virtual Account Setup**
  - **Action**: Test VA creation for supported banks
  - **Supported Banks**: BCA, BNI, BRI, Mandiri, Permata

### X3. Xendit Security

- [ ] **Rotate API Keys Periodically**
  - **Schedule**: Every 90 days or after security incident
  - **Procedure**:
    1. Generate new keys in Xendit Dashboard
    2. Update `.env` file
    3. Deploy updated app
    4. Revoke old keys after verification

- [ ] **Monitor Xendit Usage**
  - Location: Xendit Dashboard > Transactions
  - **Action**: Set up alerts for unusual activity

---

## 🌐 DNS & Domain Configuration (If Deploying Web)

### D1. Domain Setup

- [ ] **Purchase/Configure Domain**
  - **Action**: Purchase domain or configure existing domain
  - **Recommendation**: Use HTTPS-only domain

- [ ] **Configure DNS Records**
  - **A/AAAA Records**: Point to hosting provider IPs
  - **CNAME Records**: If using CDN (e.g., Firebase Hosting)
  - **Action**: Configure with domain registrar

### D2. SSL/TLS Certificate

- [ ] **Obtain SSL Certificate**
  - **Option 1**: Firebase Hosting (automatic Let's Encrypt)
  - **Option 2**: Cloudflare (free SSL)
  - **Option 3**: Custom certificate from CA
  - **Action**: Ensure HTTPS is enforced

- [ ] **Enable HSTS** (HTTP Strict Transport Security)
  - **Action**: Configure HSTS headers (if using custom server)
  - **Header**: `Strict-Transport-Security: max-age=31536000; includeSubDomains`
  - **Note**: Firebase Hosting handles this automatically

- [ ] **Configure CSP** (Content Security Policy) - If deploying web
  - **Action**: Add CSP headers to restrict resource loading
  - **Recommendation**: 
    ```
    Content-Security-Policy: default-src 'self'; script-src 'self' 'unsafe-inline' https://*.firebaseapp.com; style-src 'self' 'unsafe-inline'; img-src 'self' data: https:; font-src 'self' data:; connect-src 'self' https://*.firebaseio.com https://*.firebaseapp.com https://api.xendit.co;
    ```

### D3. Email Configuration (If Custom Domain)

- [ ] **Configure SPF Record**
  - **Purpose**: Prevent email spoofing
  - **Record**: `v=spf1 include:_spf.google.com ~all`
  - **Action**: Add TXT record to DNS

- [ ] **Configure DKIM** (If using custom email)
  - **Action**: Set up DKIM signing for email domain
  - **Note**: Usually handled by email service provider

- [ ] **Configure DMARC**
  - **Purpose**: Email authentication policy
  - **Record**: `v=DMARC1; p=quarantine; rua=mailto:admin@yourdomain.com`
  - **Action**: Add TXT record to DNS

---

## 📱 Mobile App Store Configuration

### M1. Android (Google Play Store)

- [ ] **Create Google Play Console Account**
  - URL: https://play.google.com/console
  - **Action**: Create developer account ($25 one-time fee)

- [ ] **Configure App Signing**
  - Location: Google Play Console > Setup > App integrity
  - **Action**: Upload signing key or use Play App Signing

- [ ] **Prepare Store Listing**
  - **Required**: App name, description, screenshots, privacy policy URL
  - **Action**: Complete store listing information

- [ ] **Configure App Permissions**
  - **Review**: `AndroidManifest.xml` permissions
  - **Action**: Document why each permission is needed

- [ ] **Set Up Internal Testing Track**
  - **Action**: Create internal testing release before production

### M2. iOS (App Store)

- [ ] **Create Apple Developer Account**
  - URL: https://developer.apple.com
  - **Cost**: $99/year
  - **Action**: Enroll in Apple Developer Program

- [ ] **Configure App ID & Certificates**
  - Location: Apple Developer Portal > Certificates, Identifiers & Profiles
  - **Action**: Create App ID, development and distribution certificates

- [ ] **Configure Provisioning Profiles**
  - **Action**: Create provisioning profiles for development and distribution

- [ ] **Prepare App Store Connect Listing**
  - **Required**: App name, description, screenshots, privacy policy URL
  - **Action**: Complete App Store Connect information

---

## 🔐 Security & Compliance Setup

### S1. Privacy Policy & Terms of Service

- [ ] **Create Privacy Policy**
  - **Required Content**:
    - Data collection (what data is collected)
    - Data usage (how data is used)
    - Data storage (where data is stored - Firebase)
    - Data sharing (third parties - Xendit, Firebase)
    - User rights (access, deletion, export)
    - Contact information
  - **Action**: Create privacy policy document/webpage
  - **URL**: Host at `https://yourdomain.com/privacy-policy`

- [ ] **Create Terms of Service**
  - **Required Content**:
    - Service description
    - User obligations
    - Payment terms (if applicable)
    - Liability limitations
    - Dispute resolution
  - **Action**: Create terms of service document/webpage
  - **URL**: Host at `https://yourdomain.com/terms`

- [ ] **Add Privacy Policy & Terms Links to App**
  - **Location**: Account settings page or registration screen
  - **Action**: Add links to privacy policy and terms (see audit P2-019)

### S2. Data Protection Compliance

- [ ] **GDPR Compliance** (If serving EU users)
  - **Actions**:
    - Implement data export functionality (see audit P2-017)
    - Implement account deletion functionality (see audit P2-018)
    - Add cookie consent banner (if web version)
    - Document data processing activities

- [ ] **Data Processing Agreement (DPA)**
  - **With Firebase**: Review and accept Firebase DPA
  - **With Xendit**: Review and accept Xendit DPA
  - **Action**: Ensure all third-party vendors have DPAs in place

### S3. Security Monitoring

- [ ] **Set Up Security Alerts**
  - **Firebase**: Configure alerts for unusual database/storage activity
  - **Xendit**: Monitor for suspicious payment activity
  - **Action**: Configure email/SMS alerts

- [ ] **Regular Security Audits**
  - **Schedule**: Quarterly security reviews
  - **Action**: Review access logs, audit logs, user activity

---

## 🔄 Maintenance & Operations

### O1. Key Rotation Schedule

- [ ] **Encryption Key Rotation Plan**
  - **Current Key**: Document location and backup
  - **Rotation Schedule**: Every 12 months or after security incident
  - **Procedure**: 
    1. Generate new encryption key
    2. Re-encrypt all encrypted data (customer names in transactions)
    3. Update `.env` file
    4. Deploy updated app
    5. Archive old key securely
  - **Risk**: If key is lost, encrypted data cannot be decrypted

- [ ] **Firebase Service Account Keys**
  - **Action**: Rotate service account keys if used
  - **Schedule**: Every 90 days

- [ ] **Xendit API Keys** (See X3 above)

### O2. Backup Procedures

- [ ] **Database Backup Verification**
  - **Schedule**: Monthly
  - **Action**: 
    1. Download backup from Firebase Console
    2. Verify backup integrity
    3. Test restore procedure (in test environment)

- [ ] **Backup Retention Policy**
  - **Action**: Document backup retention periods
  - **Recommendation**: 
    - Daily backups: 30 days
    - Weekly backups: 12 weeks
    - Monthly backups: 12 months

### O3. Monitoring & Alerting

- [ ] **Set Up Uptime Monitoring**
  - **Service Options**: UptimeRobot, Pingdom, StatusCake
  - **Action**: Monitor app availability
  - **Alerts**: Email/SMS on downtime

- [ ] **Configure Error Tracking Alerts**
  - **If Using Crashlytics**: Set up alerts for crash rate spikes
  - **If Using Sentry**: Configure alert rules

- [ ] **Set Up Usage Alerts**
  - **Firebase**: Alerts for database/storage quota usage
  - **Xendit**: Alerts for API rate limits or unusual activity

### O4. Cost Management

- [ ] **Set Up Firebase Budget Alerts**
  - Location: Firebase Console > Usage and billing
  - **Action**: Set budget limits and alerts
  - **Recommendation**: Start with $100/month, adjust based on usage

- [ ] **Monitor Xendit Fees**
  - **Action**: Review Xendit pricing and fees
  - **Document**: Document fee structure for accounting

---

## 📋 Environment-Specific Configuration

### E1. Development Environment

- [ ] **Development Firebase Project**
  - **Action**: Create separate Firebase project for development
  - **Benefit**: Isolate test data from production

- [ ] **Development `.env` File**
  - **Action**: Create `.env.development` with development keys
  - **Note**: Use Firebase development keys and Xendit sandbox keys

### E2. Staging Environment (Recommended)

- [ ] **Staging Firebase Project**
  - **Action**: Create staging Firebase project
  - **Purpose**: Pre-production testing

- [ ] **Staging `.env` File**
  - **Action**: Create `.env.staging` with staging keys

### E3. Production Environment

- [ ] **Production `.env` File**
  - **Action**: Create `.env.production` with production keys
  - **Security**: Store securely, never commit to git
  - **Access**: Limit access to production keys

---

## ✅ Pre-Launch Checklist

Before launching to production, verify:

- [ ] All Firebase rules deployed and tested
- [ ] `.env` file configured with production keys
- [ ] Encryption key generated and secured
- [ ] Privacy policy and terms of service published
- [ ] Firebase backups enabled
- [ ] Error tracking configured (Crashlytics or Sentry)
- [ ] Monitoring and alerts set up
- [ ] SSL certificate configured (if web)
- [ ] App Store listings prepared (if mobile)
- [ ] Security audit findings addressed (see `audit.md`)
- [ ] Test coverage added for critical paths
- [ ] Performance testing completed
- [ ] Accessibility testing completed

---

## 📞 Support & Contacts

### Emergency Contacts

- **Firebase Support**: https://firebase.google.com/support
- **Xendit Support**: support@xendit.co
- **Security Incident**: Document your security incident response procedure

### Documentation References

- **Firebase Documentation**: https://firebase.google.com/docs
- **Xendit Documentation**: https://docs.xendit.co
- **Flutter Documentation**: https://flutter.dev/docs
- **Audit Report**: `/docs/audit.md`

---

## 🔄 Regular Maintenance Schedule

### Monthly
- [ ] Review Firebase usage and costs
- [ ] Review error logs and crash reports
- [ ] Verify backups are running
- [ ] Review security alerts

### Quarterly
- [ ] Security audit review
- [ ] Dependency update review
- [ ] Performance metrics review
- [ ] User feedback review

### Annually
- [ ] Rotate encryption key (if policy requires)
- [ ] Review and update privacy policy/terms
- [ ] Comprehensive security audit
- [ ] Disaster recovery drill

---

**Last Updated**: December 2024  
**Next Review**: March 2025


