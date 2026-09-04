import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cryptography/cryptography.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ClipGhostApp());
}

class ClipGhostApp extends StatefulWidget {
  const ClipGhostApp({super.key});

  @override
  State<ClipGhostApp> createState() => _ClipGhostAppState();
}

class _ClipGhostAppState extends State<ClipGhostApp> {
  int _bgValue = 0xFF000000;
  int _accentValue = 0xFF00E676;

  @override
  void initState() {
    super.initState();
    _loadThemePreferences();
  }

  Future<void> _loadThemePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _bgValue = prefs.getInt('bg_color') ?? 0xFF000000;
      _accentValue = prefs.getInt('accent_color') ?? 0xFF00E676;
    });
  }

  Future<void> _updateColors(int bg, int accent) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('bg_color', bg);
    await prefs.setInt('accent_color', accent);
    setState(() {
      _bgValue = bg;
      _accentValue = accent;
    });
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = Color(_bgValue);
    final accentColor = Color(_accentValue);

    return MaterialApp(
      title: 'ClipGhost',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: bgColor,
        primaryColor: accentColor,
        colorScheme: ColorScheme.dark(
          primary: accentColor,
          surface: const Color(0xFF121212),
        ),
      ),
      home: MainScreen(
        backgroundColor: bgColor,
        accentColor: accentColor,
        bgValue: _bgValue,
        accentValue: _accentValue,
        onThemeChanged: _updateColors,
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  final Color backgroundColor;
  final Color accentColor;
  final int bgValue;
  final int accentValue;
  final Function(int, int) onThemeChanged;

  const MainScreen({
    super.key,
    required this.backgroundColor,
    required this.accentColor,
    required this.bgValue,
    required this.accentValue,
    required this.onThemeChanged,
  });

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final TextEditingController _passphraseController = TextEditingController();
  final TextEditingController _textController = TextEditingController();
  final TextEditingController _outputController = TextEditingController();

  bool _obscurePassphrase = true;
  bool _rememberPassphrase = false;
  bool _isLoading = false;

  static const String _fixedSalt = 'ipari_biztonsagi_fix_so_2026';
  static const int _pbkdf2Iterations = 480000;

  @override
  void initState() {
    super.initState();
    _loadPassphrase();
  }

  Future<void> _loadPassphrase() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('saved_passphrase');
    if (saved != null && saved.isNotEmpty) {
      setState(() {
        _passphraseController.text = saved;
        _rememberPassphrase = true;
      });
    }
  }

  Future<void> _handleRememberPassphrase(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _rememberPassphrase = value;
    });
    if (value) {
      await prefs.setString('saved_passphrase', _passphraseController.text);
    } else {
      await prefs.remove('saved_passphrase');
    }
  }

  Future<List<int>> _deriveRaw32Bytes(String passphrase) async {
    final pbkdf2 = Pbkdf2(
      macAlgorithm: Hmac.sha256(),
      iterations: _pbkdf2Iterations,
      bits: 256,
    );
    final secretKey = await pbkdf2.deriveKey(
      secretKey: SecretKey(utf8.encode(passphrase)),
      nonce: utf8.encode(_fixedSalt),
    );
    return await secretKey.extractBytes();
  }

  String _urlSafeBase64Encode(List<int> bytes) {
    return base64UrlEncode(bytes);
  }

  Uint8List _urlSafeBase64Decode(String text) {
    String normalized = text.replaceAll('-', '+').replaceAll('_', '/');
    while (normalized.length % 4 != 0) {
      normalized += '=';
    }
    return base64Decode(normalized);
  }

  List<int> _generateRandomBytes(int length) {
    final rnd = Random.secure();
    return List<int>.generate(length, (_) => rnd.nextInt(256));
  }

  Future<void> _encryptAndCopy() async {
    final text = _textController.text.trim();
    final pass = _passphraseController.text;

    if (pass.isEmpty) {
      _showSnackbar('Kérlek add meg a jelszót.');
      return;
    }
    if (text.isEmpty) {
      _showSnackbar('Kérlek írj be szöveget a kódoláshoz.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final rawKey = await _deriveRaw32Bytes(pass);
      final signingKey = rawKey.sublist(0, 16);
      final encryptionKey = rawKey.sublist(16, 32);

      // Web-biztos 64 bites big-endian időbélyeg (nem használ setUint64-et)
      final header = Uint8List(9);
      header[0] = 0x80; // Fernet verzió
      int timestampSec = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      for (int i = 8; i >= 1; i--) {
        header[i] = timestampSec & 0xFF;
        timestampSec = timestampSec >> 8;
      }

      final iv = _generateRandomBytes(16);

      // AES-128-CBC kódolás
      final algorithm = AesCbc.with128bits(macAlgorithm: MacAlgorithm.empty);
      final secretBox = await algorithm.encrypt(
        utf8.encode(text),
        secretKey: SecretKey(encryptionKey),
        nonce: iv,
      );

      final basicPayload = <int>[
        ...header,
        ...iv,
        ...secretBox.cipherText,
      ];

      // 32 bájtos HMAC-SHA256 aláírás
      final hmac = Hmac.sha256();
      final mac = await hmac.calculateMac(
        basicPayload,
        secretKey: SecretKey(signingKey),
      );

      final fullToken = <int>[
        ...basicPayload,
        ...mac.bytes,
      ];

      final base64Payload = _urlSafeBase64Encode(fullToken);
      final finalResult = 'ENC::$base64Payload';

      // Azonnal beállítjuk a kimeneti mezőt
      setState(() {
        _outputController.text = finalResult;
      });

      // Vágólapra másolás védett módon
      try {
        await Clipboard.setData(ClipboardData(text: finalResult));
        _showSnackbar('Kódolva és vágólapra másolva!');
      } catch (_) {
        _showSnackbar('Kódolva! Másold ki a kimeneti mezőből.');
      }
    } catch (e) {
      _showSnackbar('Hiba a kódolás során: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _decryptFromClipboard() async {
    final pass = _passphraseController.text;
    if (pass.isEmpty) {
      _showSnackbar('Kérlek add meg a jelszót először.');
      return;
    }

    String rawData = '';
    try {
      final clipData = await Clipboard.getData(Clipboard.kTextPlain);
      rawData = clipData?.text?.trim() ?? '';
    } catch (_) {}

    if (rawData.isEmpty && _textController.text.isNotEmpty) {
      rawData = _textController.text.trim();
    }

    if (!rawData.startsWith('ENC::')) {
      _showSnackbar('Nem található érvényes ENC:: kód.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final base64Part = rawData.replaceFirst('ENC::', '');
      final token = _urlSafeBase64Decode(base64Part);

      if (token.length < 57 || token[0] != 0x80) {
        throw Exception('Érvénytelen Fernet struktúra.');
      }

      final rawKey = await _deriveRaw32Bytes(pass);
      final signingKey = rawKey.sublist(0, 16);
      final encryptionKey = rawKey.sublist(16, 32);

      final signedData = token.sublist(0, token.length - 32);
      final receivedMac = token.sublist(token.length - 32);

      final hmac = Hmac.sha256();
      final expectedMac = await hmac.calculateMac(
        signedData,
        secretKey: SecretKey(signingKey),
      );

      if (!_constantTimeEquals(receivedMac, expectedMac.bytes)) {
        throw Exception('HMAC ellenőrzés sikertelen (hibás jelszó).');
      }

      final iv = signedData.sublist(9, 25);
      final cipherText = signedData.sublist(25);

      final algorithm = AesCbc.with128bits(macAlgorithm: MacAlgorithm.empty);
      final secretBox = SecretBox(
        cipherText,
        nonce: iv,
        mac: Mac.empty,
      );

      final decryptedBytes = await algorithm.decrypt(
        secretBox,
        secretKey: SecretKey(encryptionKey),
      );

      final clearText = utf8.decode(decryptedBytes);

      setState(() {
        _outputController.text = clearText;
      });
      _showSnackbar('Sikeres dekódolás!');
    } catch (e) {
      _showSnackbar('Sikertelen feloldás: hibás jelszó vagy sérült kód.');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  bool _constantTimeEquals(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    int result = 0;
    for (int i = 0; i < a.length; i++) {
      result |= a[i] ^ b[i];
    }
    return result == 0;
  }

  void _clearAll() {
    setState(() {
      _textController.clear();
      _outputController.clear();
    });
    _showSnackbar('Mezők törölve.');
  }

  void _showSnackbar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: const Color(0xFF1E1E1E),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'ClipGhost',
          style: TextStyle(
            color: widget.accentColor,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.clear_all),
            tooltip: 'Törlés',
            onPressed: _clearAll,
          ),
        ],
      ),
      drawer: _buildDrawer(),
      body: SafeArea(
        child: _isLoading
            ? Center(child: CircularProgressIndicator(color: widget.accentColor))
            : ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF121212),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF2A2A2A)),
                    ),
                    child: Column(
                      children: [
                        TextField(
                          controller: _passphraseController,
                          obscureText: _obscurePassphrase,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: 'Mester jelszó',
                            labelStyle: TextStyle(color: widget.accentColor),
                            border: InputBorder.none,
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassphrase
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                                color: Colors.grey,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassphrase = !_obscurePassphrase;
                                });
                              },
                            ),
                          ),
                          onChanged: (val) {
                            if (_rememberPassphrase) {
                              _handleRememberPassphrase(true);
                            }
                          },
                        ),
                        Row(
                          children: [
                            Checkbox(
                              value: _rememberPassphrase,
                              activeColor: widget.accentColor,
                              onChanged: (val) =>
                                  _handleRememberPassphrase(val ?? false),
                            ),
                            const Text(
                              'Jelszó megjegyzése ezen az eszközön',
                              style: TextStyle(color: Colors.grey, fontSize: 13),
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _textController,
                    maxLines: 4,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Írj be üzenetet vagy illessz be ENC:: kódot...',
                      hintStyle: const TextStyle(color: Colors.white30),
                      filled: true,
                      fillColor: const Color(0xFF121212),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFF2A2A2A)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _encryptAndCopy,
                          icon: const Icon(Icons.lock_outline, size: 18),
                          label: const Text('Encrypt & Copy'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: widget.accentColor,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _decryptFromClipboard,
                          icon: const Icon(Icons.lock_open, size: 18),
                          label: const Text('Decrypt'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: widget.accentColor,
                            side: BorderSide(color: widget.accentColor),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  if (_outputController.text.isNotEmpty) ...[
                    const Text(
                      'Eredmény / Payload',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF161616),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: widget.accentColor.withValues(alpha: 0.3)),
                      ),
                      child: SelectableText(
                        _outputController.text,
                        style: const TextStyle(
                          color: Colors.white,
                          fontFamily: 'monospace',
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: const Color(0xFF121212),
      child: Column(
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(color: Colors.black),
            child: Center(
              child: Text(
                'ClipGhost Beállítások',
                style: TextStyle(
                  color: widget.accentColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const ListTile(
            title: Text('Színtémák', style: TextStyle(color: Colors.white70)),
          ),
          Wrap(
            spacing: 12,
            children: [
              _colorOption(0xFF000000, 0xFF00E676),
              _colorOption(0xFF000000, 0xFF00B0FF),
              _colorOption(0xFF000000, 0xFFFF5252),
              _colorOption(0xFF181818, 0xFFFFD700),
            ],
          ),
          const Spacer(),
          const Divider(color: Colors.white12),
          ListTile(
            leading: const Icon(Icons.open_in_new, color: Colors.grey),
            title: const Text('Projekt & Támogatás', style: TextStyle(color: Colors.white)),
            subtitle: const Text('GitHub', style: TextStyle(color: Colors.grey, fontSize: 12)),
            onTap: () async {
              final uri = Uri.parse('https://github.com/kovacsmaxi/clipghost');
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _colorOption(int bgVal, int accentVal) {
    final isSelected = widget.bgValue == bgVal && widget.accentValue == accentVal;
    final accent = Color(accentVal);
    final bg = Color(bgVal);

    return GestureDetector(
      onTap: () => widget.onThemeChanged(bgVal, accentVal),
      child: Container(
        width: 38,
        height: 38,
        margin: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: bg,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? Colors.white : accent,
            width: isSelected ? 2.5 : 1.5,
          ),
        ),
        child: Center(
          child: Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
          ),
        ),
      ),
    );
  }
}