<div align="center">

# 🛡️ ClipGhost

**Zero-Knowledge, Air-Gapped Clipboard Encryption Tool**

[![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg?style=for-the-badge)](LICENSE)
[![Security: AES--128--CBC](https://img.shields.io/badge/Security-AES--128--CBC-00E676?style=for-the-badge)]()
[![Support on Ko-fi](https://img.shields.io/badge/Support-Ko--fi-FF5E5B?style=for-the-badge&logo=kofi&logoColor=white)](https://ko-fi.com/kovacsmaxi)

<p align="center">
  <b>ClipGhost</b> is a lightweight, offline security utility designed to turn any messaging app, email client, or note-taking service into an end-to-end encrypted channel without relying on third-party servers, network sockets, or account registrations.
</p>

</div>

---

## ⚡ Key Highlights

- **Air-Gapped Operation:** Zero internet permissions required. No analytics, no telemetry, no tracking, and no external APIs.
- **Payload-Aware Reactive UI:** Automatically detects `ENC::` tokens upon pasting or opening the app, instantly decrypting the plaintext and cleaning up sensitive data.
- **Military-Grade Cryptographic Stack:** Full implementation of the Fernet specification utilizing AES-128-CBC with 480,000 PBKDF2 iterations and HMAC-SHA256 authentication.
- **Multi-Contact Keyring:** Manage individual secret passphrases for different partners (e.g., Alice, Bob, Charlie) with one-tap switching.
- **Instant Clipboard Sanitization:** Optional automatic clipboard wiping immediately after plaintext exposure to mitigate Android clipboard-history logging.
- **Bilingual & Global Ready:** Native support for 22 world languages and adaptive high-contrast Cyber Dark and Clean White themes.

---

## 🔒 Cryptographic Architecture

ClipGhost adheres strictly to authenticated symmetric encryption standards, fully compatible with Python's standard `cryptography.fernet` engine:

| Layer | Specification |
| :--- | :--- |
| **Cipher** | AES-128 in CBC mode (PKCS7 Padding) |
| **Key Derivation** | PBKDF2 with HMAC-SHA256, 480,000 iterations |
| **Authentication** | HMAC-SHA256 across Version + Timestamp + IV + Ciphertext |
| **Transport Format** | URL-Safe Base64 string prefixed with `ENC::` |

### Token Anatomy (`ENC::<base64>`)

```
0x80 (1 byte) || Timestamp (8 bytes) || IV (16 bytes) || Ciphertext (N bytes) || HMAC-SHA256 (32 bytes)
```

1. **Version (0x80):** Identifies the Fernet payload version.
2. **Timestamp:** 64-bit big-endian unsigned integer recording token creation time down to the second.
3. **IV (Nonce):** 16 cryptographically secure random bytes generated uniquely per encryption routine.
4. **Ciphertext:** AES-128-CBC encrypted plaintext with PKCS7 padding.
5. **HMAC Signature:** 32-byte message authentication code verified via constant-time byte comparison to prevent timing attacks.

---

## 🚀 Features

### 1. Smart Action Dispatcher
The primary action button dynamically shifts state based on the input context:
- **`Encrypt & Copy`:** Active when typing standard plaintext with a passphrase set.
- **`Decrypt`:** Automatically engages the moment an `ENC::` payload is inserted or pasted.
- **`Copy Plaintext (Warning)`:** Visual fallback when operating without an active passphrase in non-strict mode.

### 2. Streamlined Clipboard Hygiene
- **Auto-Paste on Open:** Automatically reads valid `ENC::` tokens when returning from background apps.
- **Instant Decrypt & Wipe:** Immediately decrypts incoming tokens and wipes the system clipboard memory.
- **Configurable Auto-Clear:** Automated field purging post-encryption to keep screens clear of sensitive drafts.

### 3. Contact Key Manager
Store partner profiles locally. Switch communication channels without manually retyping long, complex master keys each turn.

### 4. Custom Themes & Adaptivity
- **Cyber Dark:** Deep navy and dark obsidian backgrounds with neon green, electric blue, red alert, or amber accents.
- **Clean White:** High-contrast daylight theme with teal accents and dark typography.

---

## 🛠️ Installation & Building

### Prerequisites
- [Flutter SDK](https://flutter.dev/docs/get-started/install) (3.x or later)
- Android SDK (API Level 21+)

### Build APK
Clone the repository and build the release binary locally:

```bash
git clone [https://github.com/kovacsmaxi/clipghost.git](https://github.com/kovacsmaxi/clipghost.git)
cd clipghost

flutter pub get
flutter build apk --release
```

The compiled binary will be located at:
```
build/app/outputs/flutter-apk/app-release.apk
```

---

## 🤝 Cross-Platform Interoperability (Python CLI)

ClipGhost was architected to be 100% interoperable with standard Python terminals. You can encrypt or decrypt messages on your PC using the companion script:

```bash
python clipghost_cli.py --decrypt "ENC::gAAAAABqm0..."
```

---

## ☕ Support the Project

ClipGhost is free, open-source, and entirely independent. If this tool helps secure your private communications or workflow, consider supporting its continued maintenance and development:

<div align="center">

<br>

[![Buy Me a Coffee at Ko-fi](https://storage.ko-fi.com/cdn/kofi3.png?v=3)](https://ko-fi.com/kovacsmaxi)

**[Support via Ko-fi (PayPal)](https://ko-fi.com/kovacsmaxi)**

<br>

</div>

---

## 📄 License

This project is licensed under the MIT License — see the [LICENSE](LICENSE) file for full details.
