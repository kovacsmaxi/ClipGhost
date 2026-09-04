code = """import 'dart:convert';
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

  Future<SecretKey> _deriveKey(String passphrase) async {
    final pbkdf2 = Pbkdf2(
      macAlgorithm: Hmac.sha256(),
      iterations: _pbkdf2Iterations,
      bits: 256,
    );
    return await pbkdf2.deriveKey(
      secretKey: SecretKey(utf8.encode(passphrase)),
      nonce: utf8.encode(_fixedSalt),
    );
  }

  List<int> _generateRandomBytes(int length) {
    final rnd = Random.secure();
    return List<int>.generate(length, (_) => rnd.nextInt(256));
  }

  Future<void> _encryptAndCopy() async {
    final text = _textController.text.trim();
    final pass = _passphraseController.text;

    if (pass.isEmpty) {
      _showSnackbar('Please enter a master passphrase.');
      return;
    }
    if (text.isEmpty) {
      _showSnackbar('Please enter text to encrypt.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final key = await _deriveKey(pass);
      final algorithm = AesCbc.with256bits(macAlgorithm: MacAlgorithm.empty);
      final iv = _generateRandomBytes(16);

      final secretBox = await algorithm.encrypt(
        utf8.encode(text),
        secretKey: key,
        nonce: iv,
      );

      final combined = Uint8List.fromList([
        ...secretBox.nonce,
        ...secretBox.cipherText,
      ]);

      final base64Payload = base64Encode(combined);
      final finalResult = 'ENC::' + base64Payload;

      setState(() {
        _outputController.text = finalResult;
      });

      await Clipboard.setData(ClipboardData(text: finalResult));
      _showSnackbar('Encrypted & copied to clipboard!');
    } catch (e) {
      _showSnackbar('Encryption failed: ' + e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _decryptFromClipboard() async {
    final pass = _passphraseController.text;
    if (pass.isEmpty) {
      _showSnackbar('Please enter the master passphrase first.');
      return;
    }

    final clipData = await Clipboard.getData(Clipboard.kTextPlain);
    String rawData = clipData?.text?.trim() ?? '';

    if (rawData.isEmpty && _textController.text.isNotEmpty) {
      rawData = _textController.text.trim();
    }

    if (!rawData.startsWith('ENC::')) {
      _showSnackbar('Clipboard does not contain valid ENC:: payload.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final base64Part = rawData.replaceFirst('ENC::', '');
      final payloadBytes = base64Decode(base64Part);

      if (payloadBytes.length < 32) {
        throw Exception('Invalid payload length.');
      }

      final iv = payloadBytes.sublist(0, 16);
      final cipherText = payloadBytes.sublist(16);

      final key = await _deriveKey(pass);
      final algorithm = AesCbc.with256bits(macAlgorithm: MacAlgorithm.empty);

      final secretBox = SecretBox(
        cipherText,
        nonce: iv,
        mac: Mac.empty,
      );

      final clearBytes = await algorithm.decrypt(secretBox, secretKey: key);
      final clearText = utf8.decode(clearBytes);

      setState(() {
        _outputController.text = clearText;
      });
      _showSnackbar('Decrypted successfully!');
    } catch (e) {
      _showSnackbar('Decryption failed. Incorrect passphrase or altered payload.');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _clearAll() {
    setState(() {
      _textController.clear();
      _outputController.clear();
    });
    _showSnackbar('Fields cleared.');
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
            tooltip: 'Clear fields',
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
                            labelText: 'Master Passphrase',
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
                              'Remember passphrase on this device',
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
                      hintText: 'Enter message to encrypt or paste ENC:: payload...',
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
                      'Result / Payload',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF161616),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: widget.accentColor.withOpacity(0.3)),
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
                'ClipGhost Settings',
                style: TextStyle(
                  color: widget.accentColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const ListTile(
            title: Text('Theme Color Presets', style: TextStyle(color: Colors.white70)),
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
            title: const Text('Project & Support', style: TextStyle(color: Colors.white)),
            subtitle: const Text('GitHub / Tip Jar', style: TextStyle(color: Colors.grey, fontSize: 12)),
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
"""

with open("lib/main.dart", "w") as f:
    f.write(code.strip())
print("KÉSZ")
