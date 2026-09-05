import 'dart:async';
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

// --- 22 NYELVŰ TÁMOGATÁS (I18N) ---
const Map<String, Map<String, String>> localizedStrings = {
  'en': {
    'app_title': 'ClipGhost',
    'settings_title': 'Settings & Security',
    'master_passphrase': 'Master Passphrase',
    'remember_passphrase': 'Remember passphrase on this device',
    'contacts_btn': 'Contacts / Keys',
    'manage_contacts': 'Manage Partner Keys',
    'contact_name': 'Contact Name',
    'contact_key': 'Secret Passphrase',
    'add_contact': 'Add Partner',
    'no_contacts': 'No saved partners yet.',
    'select': 'Select',
    'input_label': 'Input',
    'paste_button': 'Paste',
    'input_hint': 'Enter message or paste ENC:: payload...',
    'btn_decrypt': 'Decrypt',
    'btn_encrypt_copy': 'Encrypt & Copy',
    'btn_copy_plain': 'Copy Plaintext (Unencrypted)',
    'result_label': 'Result',
    'decrypted_badge': 'Decrypted',
    'encrypted_badge': 'Fernet',
    'copy_result': 'Copy',
    'sec_encryption': 'ENCRYPTION SETTINGS',
    'sec_decryption': 'DECRYPTION & CLIPBOARD',
    'sec_appearance': 'APPEARANCE & THEMES',
    'sec_general': 'GENERAL & FEEDBACK',
    'sec_language': 'LANGUAGE',
    'auto_clear_encrypt_title': 'Auto-Clear after Encrypt',
    'auto_clear_encrypt_sub': 'Clears input field immediately after encryption & copy',
    'strict_title': 'Strict Password Mode',
    'strict_sub': 'Disallows unencrypted copy; password is required at all times',
    'auto_paste_title': 'Auto-Paste on Open',
    'auto_paste_sub': 'Detects and inputs ENC code when app resumes',
    'auto_decrypt_wipe_title': 'Instant Decrypt & Clipboard Wipe',
    'auto_decrypt_wipe_sub': 'Auto-decrypts ENC input and immediately clears the clipboard',
    'enter_action_title': 'Execute Action with Enter',
    'enter_action_sub': 'Pressing Enter triggers Encrypt/Decrypt instead of a new line',
    'haptic_title': 'Haptic Feedback',
    'haptic_sub': 'Vibration on copy, decrypt and paste actions',
    'project_github': 'GitHub Project',
    'clear_fields': 'Clear fields',
    'fields_cleared': 'Fields cleared.',
    'clipboard_empty': 'Clipboard is empty.',
    'clipboard_read_failed': 'Failed to read clipboard.',
    'clipboard_pasted': 'Clipboard content pasted!',
    'auto_pasted_msg': 'ENC payload auto-pasted from clipboard!',
    'enter_input_msg': 'Please enter or paste an input message.',
    'pass_required_strict': 'Error: Strict mode is active. Password is required!',
    'plain_copied_warn': 'Warning: Copied to clipboard without encryption!',
    'encrypted_copied': 'Encrypted & copied to clipboard!',
    'encrypted_manual': 'Encrypted! (Copy manually from result box)',
    'enter_pass_decrypt': 'Please enter the master passphrase to decrypt.',
    'invalid_format': 'Invalid payload format or corrupted payload.',
    'auth_failed': 'Failed to decrypt: Incorrect passphrase or corrupted token.',
    'decrypted_success': 'Decrypted successfully!',
    'encryption_error': 'Encryption error: ',
    'result_copied': 'Result copied to clipboard!',
  },
  'hu': {
    'app_title': 'ClipGhost',
    'settings_title': 'Beállítások & Biztonság',
    'master_passphrase': 'Mester jelszó',
    'remember_passphrase': 'Jelszó megjegyzése az eszközön',
    'contacts_btn': 'Partnerek / Kulcsok',
    'manage_contacts': 'Partner kulcsok kezelése',
    'contact_name': 'Partner neve (pl. Ákos)',
    'contact_key': 'Titkos jelszó',
    'add_contact': 'Partner hozzáadása',
    'no_contacts': 'Nincsenek még mentett partnerek.',
    'select': 'Kiválaszt',
    'input_label': 'Bemenet',
    'paste_button': 'Beillesztés',
    'input_hint': 'Írj be üzenetet, vagy illessz be egy ENC:: kódot...',
    'btn_decrypt': 'Feloldás (Decrypt)',
    'btn_encrypt_copy': 'Titkosítás & Másolás',
    'btn_copy_plain': 'Másolás (Nyers szöveg)',
    'result_label': 'Eredmény',
    'decrypted_badge': 'Feloldva',
    'encrypted_badge': 'Fernet',
    'copy_result': 'Másolás',
    'sec_encryption': 'TITKOSÍTÁSI BEÁLLÍTÁSOK',
    'sec_decryption': 'DEKÓDOLÁS ÉS VÁGÓLAP',
    'sec_appearance': 'MEGJELENÉS ÉS SZÍNEK',
    'sec_general': 'ÁLTALÁNOS ÉS VISSZAJELZÉS',
    'sec_language': 'NYELV / LANGUAGE',
    'auto_clear_encrypt_title': 'Auto-Clear kódolás után',
    'auto_clear_encrypt_sub': 'Kódolás és másolás után azonnal kitörli a beírt szöveget',
    'strict_title': 'Szigorú jelszó-követelmény',
    'strict_sub': 'Üres jelszóval tilos a sima szövegmásolás, mindig kötelező a jelszó',
    'auto_paste_title': 'Automatikus beillesztés megnyitáskor',
    'auto_paste_sub': 'Alkalmazás előtérbe hozásakor észleli a vágólapon lévő ENC kódot',
    'auto_decrypt_wipe_title': 'Azonnali dekódolás & Vágólaptörlés',
    'auto_decrypt_wipe_sub': 'ENC kód észlelésekor azonnal feloldja és törli a vágólapot',
    'enter_action_title': 'Művelet futtatása Enterrel',
    'enter_action_sub': 'Az Enter leütése azonnal titkosít/felold új sor beszúrása helyett',
    'haptic_title': 'Haptikus visszajelzés (Rezgés)',
    'haptic_sub': 'Finom rezgés kódoláskor, dekódoláskor és beillesztéskor',
    'project_github': 'GitHub Projekt',
    'clear_fields': 'Mezők kiürítése',
    'fields_cleared': 'Mezők törölve.',
    'clipboard_empty': 'A vágólap üres.',
    'clipboard_read_failed': 'Nem sikerült olvasni a vágólapot.',
    'clipboard_pasted': 'Vágólap beillesztve!',
    'auto_pasted_msg': 'Vágólapról észlelt ENC kód automatikusan beillesztve!',
    'enter_input_msg': 'Kérlek írj be vagy illessz be egy üzenetet.',
    'pass_required_strict': 'Hiba: A szigorú mód aktív, a jelszó megadása kötelező!',
    'plain_copied_warn': 'Figyelem: Jelszó nélkül, sima szövegként került a vágólapra!',
    'encrypted_copied': 'Titkosítva és a vágólapra másolva!',
    'encrypted_manual': 'Titkosítva! (Másold ki az eredmény mezőből)',
    'enter_pass_decrypt': 'Kérlek add meg a jelszót a feloldáshoz.',
    'invalid_format': 'Érvénytelen formátum vagy sérült adat.',
    'auth_failed': 'Sikertelen feloldás: hibás jelszó vagy sérült kód.',
    'decrypted_success': 'Sikeres feloldás!',
    'encryption_error': 'Hiba a titkosítás során: ',
    'result_copied': 'Eredmény a vágólapra másolva!',
  },
  'de': {
    'app_title': 'ClipGhost', 'settings_title': 'Einstellungen', 'master_passphrase': 'Master-Passphrase', 'remember_passphrase': 'Speichern', 'contacts_btn': 'Kontakte', 'manage_contacts': 'Schlüssel verwalten', 'contact_name': 'Name', 'contact_key': 'Passwort', 'add_contact': 'Hinzufügen', 'no_contacts': 'Keine Kontakte.', 'select': 'Auswählen', 'input_label': 'Eingabe', 'paste_button': 'Einfügen', 'input_hint': 'Nachricht oder ENC::...', 'btn_decrypt': 'Entschlüsseln', 'btn_encrypt_copy': 'Verschlüsseln & Kopieren', 'btn_copy_plain': 'Klartext kopieren', 'result_label': 'Ergebnis', 'decrypted_badge': 'Entschlüsselt', 'encrypted_badge': 'Fernet', 'copy_result': 'Kopieren',
    'sec_encryption': 'VERSCHLÜSSELUNG', 'sec_decryption': 'ENTSCHLÜSSELUNG & ABLAGE', 'sec_appearance': 'FARBEN & THEMEN', 'sec_general': 'ALLGEMEIN', 'sec_language': 'SPRACHE',
    'auto_clear_encrypt_title': 'Auto-Löschen nach Verschlüsselung', 'auto_clear_encrypt_sub': 'Leert Eingabefeld nach Kopieren', 'strict_title': 'Strenger Modus', 'strict_sub': 'Passwort immer zwingend erforderlich', 'auto_paste_title': 'Auto-Einfügen beim Öffnen', 'auto_paste_sub': 'Erkennt ENC beim Start', 'auto_decrypt_wipe_title': 'Sofort entschlüsseln & Zwischenablage leeren', 'auto_decrypt_wipe_sub': 'Entschlüsselt sofort und löscht Zwischenablage', 'enter_action_title': 'Mit Enter ausführen', 'enter_action_sub': 'Enter löst Verschlüsselung aus', 'haptic_title': 'Haptisches Feedback', 'haptic_sub': 'Vibration bei Aktionen', 'project_github': 'GitHub Projekt', 'clear_fields': 'Felder leeren', 'fields_cleared': 'Felder geleert.', 'clipboard_empty': 'Ablage leer.', 'clipboard_read_failed': 'Fehler beim Lesen.', 'clipboard_pasted': 'Eingefügt!', 'auto_pasted_msg': 'ENC eingefügt!', 'enter_input_msg': 'Bitte Text eingeben.', 'pass_required_strict': 'Passwort erforderlich!', 'plain_copied_warn': 'Als Klartext kopiert!', 'encrypted_copied': 'Verschlüsselt!', 'encrypted_manual': 'Manuell kopieren', 'enter_pass_decrypt': 'Passphrase eingeben.', 'invalid_format': 'Ungültiges Format.', 'auth_failed': 'Entschlüsselung fehlgeschlagen.', 'decrypted_success': 'Erfolgreich!', 'encryption_error': 'Fehler: ', 'result_copied': 'Kopiert!'
  },
  'es': {
    'app_title': 'ClipGhost', 'settings_title': 'Ajustes', 'master_passphrase': 'Contraseña', 'remember_passphrase': 'Recordar', 'contacts_btn': 'Contactos', 'manage_contacts': 'Gestionar claves', 'contact_name': 'Nombre', 'contact_key': 'Contraseña', 'add_contact': 'Añadir', 'no_contacts': 'Sin contactos.', 'select': 'Seleccionar', 'input_label': 'Entrada', 'paste_button': 'Pegar', 'input_hint': 'Mensaje o ENC::...', 'btn_decrypt': 'Descifrar', 'btn_encrypt_copy': 'Cifrar y Copiar', 'btn_copy_plain': 'Copiar texto plano', 'result_label': 'Resultado', 'decrypted_badge': 'Descifrado', 'encrypted_badge': 'Fernet', 'copy_result': 'Copiar',
    'sec_encryption': 'CIFRADO', 'sec_decryption': 'DESCIFRADO Y PORTAPAPELES', 'sec_appearance': 'TEMAS VISUALES', 'sec_general': 'GENERAL', 'sec_language': 'IDIOMA',
    'auto_clear_encrypt_title': 'Limpieza tras cifrar', 'auto_clear_encrypt_sub': 'Limpia la entrada tras cifrar', 'strict_title': 'Modo estricto', 'strict_sub': 'Contraseña obligatoria', 'auto_paste_title': 'Pegado automático', 'auto_paste_sub': 'Detecta código ENC', 'auto_decrypt_wipe_title': 'Descifrado instantáneo y limpieza', 'auto_decrypt_wipe_sub': 'Descifra al instante y limpia el portapapeles', 'enter_action_title': 'Ejecutar con Enter', 'enter_action_sub': 'Enter activa la acción en vez de salto de línea', 'haptic_title': 'Respuesta háptica', 'haptic_sub': 'Vibración', 'project_github': 'Proyecto GitHub', 'clear_fields': 'Limpiar', 'fields_cleared': 'Campos limpiados.', 'clipboard_empty': 'Portapapeles vacío.', 'clipboard_read_failed': 'Error de lectura.', 'clipboard_pasted': '¡Pegado!', 'auto_pasted_msg': '¡ENC pegado!', 'enter_input_msg': 'Introduce mensaje.', 'pass_required_strict': '¡Contraseña requerida!', 'plain_copied_warn': '¡Sin cifrar!', 'encrypted_copied': '¡Cifrado!', 'encrypted_manual': 'Copia manual', 'enter_pass_decrypt': 'Contraseña requerida.', 'invalid_format': 'Formato inválido.', 'auth_failed': 'Fallo al descifrar.', 'decrypted_success': '¡Descifrado!', 'encryption_error': 'Error: ', 'result_copied': '¡Copiado!'
  },
  'fr': {'app_title': 'ClipGhost', 'settings_title': 'Paramètres', 'master_passphrase': 'Mot de passe', 'remember_passphrase': 'Mémoriser', 'contacts_btn': 'Contacts', 'manage_contacts': 'Gérer clés', 'contact_name': 'Nom', 'contact_key': 'Clé', 'add_contact': 'Ajouter', 'no_contacts': 'Aucun contact.', 'select': 'Choisir', 'input_label': 'Entrée', 'paste_button': 'Coller', 'input_hint': 'Message ou ENC::...', 'btn_decrypt': 'Déchiffrer', 'btn_encrypt_copy': 'Chiffrer & Copier', 'btn_copy_plain': 'Copier en clair', 'result_label': 'Résultat', 'decrypted_badge': 'Déchiffré', 'encrypted_badge': 'Fernet', 'copy_result': 'Copier', 'sec_encryption': 'CHIFFREMENT', 'sec_decryption': 'DÉCHIFFREMENT & PRESSE-PAPIERS', 'sec_appearance': 'APPARENCE', 'sec_general': 'GÉNÉRAL', 'sec_language': 'LANGUE', 'auto_clear_encrypt_title': 'Effacement après chiffrement', 'auto_clear_encrypt_sub': 'Vide le champ après copie', 'strict_title': 'Mode strict', 'strict_sub': 'Mot de passe obligatoire', 'auto_paste_title': 'Collage automatique', 'auto_paste_sub': 'Détecte le code ENC', 'auto_decrypt_wipe_title': 'Déchiffrement & Effacement immédiat', 'auto_decrypt_wipe_sub': 'Déchiffre et vide le presse-papiers direct', 'enter_action_title': 'Exécuter avec Entrée', 'enter_action_sub': 'Touche Entrée déclenche le chiffrement', 'haptic_title': 'Retour haptique', 'haptic_sub': 'Vibration', 'project_github': 'GitHub', 'clear_fields': 'Effacer', 'fields_cleared': 'Effacé.', 'clipboard_empty': 'Vide.', 'clipboard_read_failed': 'Erreur.', 'clipboard_pasted': 'Collé !', 'auto_pasted_msg': 'Code détecté !', 'enter_input_msg': 'Saisir message.', 'pass_required_strict': 'Mot de passe requis !', 'plain_copied_warn': 'Copié en clair !', 'encrypted_copied': 'Chiffré !', 'encrypted_manual': 'Manuel', 'enter_pass_decrypt': 'Mot de passe requis.', 'invalid_format': 'Invalide.', 'auth_failed': 'Échec.', 'decrypted_success': 'Succès !', 'encryption_error': 'Erreur : ', 'result_copied': 'Copié !'},
  'it': {'app_title': 'ClipGhost', 'settings_title': 'Impostazioni', 'master_passphrase': 'Password', 'remember_passphrase': 'Ricorda', 'contacts_btn': 'Contatti', 'manage_contacts': 'Chiavi', 'contact_name': 'Nome', 'contact_key': 'Password', 'add_contact': 'Aggiungi', 'no_contacts': 'Nessuno.', 'select': 'Scegli', 'input_label': 'Input', 'paste_button': 'Incolla', 'input_hint': 'Messaggio o ENC::...', 'btn_decrypt': 'Decifra', 'btn_encrypt_copy': 'Cifra', 'btn_copy_plain': 'Copia chiaro', 'result_label': 'Risultato', 'decrypted_badge': 'Decifrato', 'encrypted_badge': 'Fernet', 'copy_result': 'Copia', 'sec_encryption': 'CIFRATURA', 'sec_decryption': 'DECIFRATURA E APPUNTI', 'sec_appearance': 'TEMA', 'sec_general': 'GENERALE', 'sec_language': 'LINGUA', 'auto_clear_encrypt_title': 'Pulisci dopo cifratura', 'auto_clear_encrypt_sub': 'Svuota campo', 'strict_title': 'Rigido', 'strict_sub': 'Password obbligatoria', 'auto_paste_title': 'Incolla auto', 'auto_paste_sub': 'Rileva ENC', 'auto_decrypt_wipe_title': 'Auto-decifra & Svuota appunti', 'auto_decrypt_wipe_sub': 'Decifra e pulisce gli appunti', 'enter_action_title': 'Esegui con Invio', 'enter_action_sub': 'Invio attiva l\'azione', 'haptic_title': 'Feedback', 'haptic_sub': 'Vibrazione', 'project_github': 'GitHub', 'clear_fields': 'Pulisci', 'fields_cleared': 'Pulito.', 'clipboard_empty': 'Vuoto.', 'clipboard_read_failed': 'Errore.', 'clipboard_pasted': 'Incollato!', 'auto_pasted_msg': 'Rilevato!', 'enter_input_msg': 'Inserisci.', 'pass_required_strict': 'Password richiesta!', 'plain_copied_warn': 'In chiaro!', 'encrypted_copied': 'Cifrato!', 'encrypted_manual': 'Manuale', 'enter_pass_decrypt': 'Password.', 'invalid_format': 'Invalido.', 'auth_failed': 'Fallito.', 'decrypted_success': 'Decifrato!', 'encryption_error': 'Errore: ', 'result_copied': 'Copiato!'},
  'pt': {'app_title': 'ClipGhost', 'settings_title': 'Configurações', 'master_passphrase': 'Senha', 'remember_passphrase': 'Lembrar', 'contacts_btn': 'Contatos', 'manage_contacts': 'Chaves', 'contact_name': 'Nome', 'contact_key': 'Senha', 'add_contact': 'Adicionar', 'no_contacts': 'Nenhum.', 'select': 'Escolher', 'input_label': 'Entrada', 'paste_button': 'Colar', 'input_hint': 'Texto ou ENC::...', 'btn_decrypt': 'Decifrar', 'btn_encrypt_copy': 'Criptografar', 'btn_copy_plain': 'Copiar simples', 'result_label': 'Resultado', 'decrypted_badge': 'Decifrado', 'encrypted_badge': 'Fernet', 'copy_result': 'Copiar', 'sec_encryption': 'CRIPTOGRAFIA', 'sec_decryption': 'DESCRIPTOGRAFIA E ÁREA', 'sec_appearance': 'TEMAS', 'sec_general': 'GERAL', 'sec_language': 'IDIOMA', 'auto_clear_encrypt_title': 'Limpar após cifrar', 'auto_clear_encrypt_sub': 'Esvazia campo', 'strict_title': 'Modo estrito', 'strict_sub': 'Senha obrigatória', 'auto_paste_title': 'Colar auto', 'auto_paste_sub': 'Detecta ENC', 'auto_decrypt_wipe_title': 'Decifrar & Limpar área', 'auto_decrypt_wipe_sub': 'Decifra e limpa área na hora', 'enter_action_title': 'Executar com Enter', 'enter_action_sub': 'Enter aciona ação', 'haptic_title': 'Vibração', 'haptic_sub': 'Feedback', 'project_github': 'GitHub', 'clear_fields': 'Limpar', 'fields_cleared': 'Limpo.', 'clipboard_empty': 'Vazio.', 'clipboard_read_failed': 'Erro.', 'clipboard_pasted': 'Colado!', 'auto_pasted_msg': 'Detectado!', 'enter_input_msg': 'Digite algo.', 'pass_required_strict': 'Requer senha!', 'plain_copied_warn': 'Sem proteção!', 'encrypted_copied': 'Criptografado!', 'encrypted_manual': 'Manual', 'enter_pass_decrypt': 'Senha requerida.', 'invalid_format': 'Inválido.', 'auth_failed': 'Falhou.', 'decrypted_success': 'Sucesso!', 'encryption_error': 'Erro: ', 'result_copied': 'Copiado!'},
  'nl': {'app_title': 'ClipGhost', 'settings_title': 'Instellingen', 'master_passphrase': 'Wachtwoord', 'remember_passphrase': 'Onthouden', 'contacts_btn': 'Contacten', 'manage_contacts': 'Sleutels', 'contact_name': 'Naam', 'contact_key': 'Wachtwoord', 'add_contact': 'Toevoegen', 'no_contacts': 'Geen.', 'select': 'Kiezen', 'input_label': 'Invoer', 'paste_button': 'Plakken', 'input_hint': 'Bericht of ENC::...', 'btn_decrypt': 'Ontsleutelen', 'btn_encrypt_copy': 'Versleutelen', 'btn_copy_plain': 'Kopiëren', 'result_label': 'Resultaat', 'decrypted_badge': 'Ontsleuteld', 'encrypted_badge': 'Fernet', 'copy_result': 'Kopiëren', 'sec_encryption': 'VERSLEUTELING', 'sec_decryption': 'ONTSLEUTELING & KLEMBORD', 'sec_appearance': 'THEMA', 'sec_general': 'ALGEMEEN', 'sec_language': 'TAAL', 'auto_clear_encrypt_title': 'Wissen na versleutelen', 'auto_clear_encrypt_sub': 'Maakt leeg', 'strict_title': 'Strikte modus', 'strict_sub': 'Wachtwoord verplicht', 'auto_paste_title': 'Auto-plakken', 'auto_paste_sub': 'Detecteer ENC', 'auto_decrypt_wipe_title': 'Direct ontsleutelen & Klembord wissen', 'auto_decrypt_wipe_sub': 'Ontsleutelt en wist direct het klembord', 'enter_action_title': 'Uitvoeren met Enter', 'enter_action_sub': 'Enter start encryptie/decryptie', 'haptic_title': 'Trilling', 'haptic_sub': 'Feedback', 'project_github': 'GitHub', 'clear_fields': 'Wissen', 'fields_cleared': 'Gewist.', 'clipboard_empty': 'Leeg.', 'clipboard_read_failed': 'Fout.', 'clipboard_pasted': 'Geplakt!', 'auto_pasted_msg': 'Gedetecteerd!', 'enter_input_msg': 'Invoer nodig.', 'pass_required_strict': 'Wachtwoord vereist!', 'plain_copied_warn': 'Onversleuteld!', 'encrypted_copied': 'Versleuteld!', 'encrypted_manual': 'Handmatig', 'enter_pass_decrypt': 'Wachtwoord.', 'invalid_format': 'Ongeldig.', 'auth_failed': 'Mislukt.', 'decrypted_success': 'Succes!', 'encryption_error': 'Fout: ', 'result_copied': 'Gekopieerd!'},
  'pl': {'app_title': 'ClipGhost', 'settings_title': 'Ustawienia', 'master_passphrase': 'Hasło', 'remember_passphrase': 'Zapamiętaj', 'contacts_btn': 'Kontakty', 'manage_contacts': 'Klucze', 'contact_name': 'Nazwa', 'contact_key': 'Hasło', 'add_contact': 'Dodaj', 'no_contacts': 'Brak.', 'select': 'Wybierz', 'input_label': 'Wejście', 'paste_button': 'Wklej', 'input_hint': 'Tekst lub ENC::...', 'btn_decrypt': 'Odszyfruj', 'btn_encrypt_copy': 'Szyfruj', 'btn_copy_plain': 'Kopiuj zwykły', 'result_label': 'Wynik', 'decrypted_badge': 'Odszyfrowano', 'encrypted_badge': 'Fernet', 'copy_result': 'Kopiuj', 'sec_encryption': 'SZYFROWANIE', 'sec_decryption': 'ODSZYFROWYWANIE I SCHOWEK', 'sec_appearance': 'WYGLĄD', 'sec_general': 'OGÓLNE', 'sec_language': 'JĘZYK', 'auto_clear_encrypt_title': 'Czyść po szyfrowaniu', 'auto_clear_encrypt_sub': 'Czyści pole', 'strict_title': 'Tryb ścisły', 'strict_sub': 'Hasło wymagane', 'auto_paste_title': 'Auto-wklejanie', 'auto_paste_sub': 'Wykrywaj ENC', 'auto_decrypt_wipe_title': 'Auto-odszyfruj & Wyczyść schowek', 'auto_decrypt_wipe_sub': 'Odszyfrowuje i od razu czyści schowek', 'enter_action_title': 'Wykonaj Enterem', 'enter_action_sub': 'Enter szyfruje zamiast nowej linii', 'haptic_title': 'Wibracje', 'haptic_sub': 'Odpowiedź', 'project_github': 'GitHub', 'clear_fields': 'Wyczyść', 'fields_cleared': 'Wyczyszczono.', 'clipboard_empty': 'Pusto.', 'clipboard_read_failed': 'Błąd.', 'clipboard_pasted': 'Wklejono!', 'auto_pasted_msg': 'Wykryto ENC!', 'enter_input_msg': 'Wpisz tekst.', 'pass_required_strict': 'Hasło wymagane!', 'plain_copied_warn': 'Nieszyfrowane!', 'encrypted_copied': 'Zaszyfrowano!', 'encrypted_manual': 'Ręcznie', 'enter_pass_decrypt': 'Podaj hasło.', 'invalid_format': 'Zły format.', 'auth_failed': 'Błąd.', 'decrypted_success': 'Sukces!', 'encryption_error': 'Błąd: ', 'result_copied': 'Skopiowano!'},
  'ru': {'app_title': 'ClipGhost', 'settings_title': 'Настройки', 'master_passphrase': 'Пароль', 'remember_passphrase': 'Запомнить', 'contacts_btn': 'Контакты', 'manage_contacts': 'Ключи', 'contact_name': 'Имя', 'contact_key': 'Пароль', 'add_contact': 'Добавить', 'no_contacts': 'Нет.', 'select': 'Выбрать', 'input_label': 'Ввод', 'paste_button': 'Вставить', 'input_hint': 'Текст или ENC::...', 'btn_decrypt': 'Расшифровать', 'btn_encrypt_copy': 'Зашифровать', 'btn_copy_plain': 'Копировать текст', 'result_label': 'Результат', 'decrypted_badge': 'Расшифровано', 'encrypted_badge': 'Fernet', 'copy_result': 'Копировать', 'sec_encryption': 'ШИФРОВАНИЕ', 'sec_decryption': 'ДЕШИФРОВКА И БУФЕР', 'sec_appearance': 'ОФОРМЛЕНИЕ', 'sec_general': 'ОБЩИЕ', 'sec_language': 'ЯЗЫК', 'auto_clear_encrypt_title': 'Очистка после шифрования', 'auto_clear_encrypt_sub': 'Очищает ввод', 'strict_title': 'Строгий режим', 'strict_sub': 'Пароль обязателен', 'auto_paste_title': 'Авто-вставка', 'auto_paste_sub': 'Искать ENC', 'auto_decrypt_wipe_title': 'Авто-расшифровка и очистка буфера', 'auto_decrypt_wipe_sub': 'Сразу расшифровывает и очищает буфер', 'enter_action_title': 'Действие по Enter', 'enter_action_sub': 'Enter выполняет действие', 'haptic_title': 'Виброотклик', 'haptic_sub': 'Вибрация', 'project_github': 'GitHub', 'clear_fields': 'Очистить', 'fields_cleared': 'Очищено.', 'clipboard_empty': 'Пусто.', 'clipboard_read_failed': 'Ошибка.', 'clipboard_pasted': 'Вставлено!', 'auto_pasted_msg': 'Обнаружен код!', 'enter_input_msg': 'Введите текст.', 'pass_required_strict': 'Нужен пароль!', 'plain_copied_warn': 'Без шифрования!', 'encrypted_copied': 'Зашифровано!', 'encrypted_manual': 'Вручную', 'enter_pass_decrypt': 'Нужен пароль.', 'invalid_format': 'Ошибка формата.', 'auth_failed': 'Сбой.', 'decrypted_success': 'Успешно!', 'encryption_error': 'Ошибка: ', 'result_copied': 'Скопировано!'},
  'uk': {'app_title': 'ClipGhost', 'settings_title': 'Налаштування', 'master_passphrase': 'Пароль', 'remember_passphrase': 'Запам\'ятати', 'contacts_btn': 'Контакти', 'manage_contacts': 'Ключі', 'contact_name': 'Ім\'я', 'contact_key': 'Пароль', 'add_contact': 'Додати', 'no_contacts': 'Немає.', 'select': 'Обрати', 'input_label': 'Введення', 'paste_button': 'Вставити', 'input_hint': 'Текст або ENC::...', 'btn_decrypt': 'Розшифрувати', 'btn_encrypt_copy': 'Зашифрувати', 'btn_copy_plain': 'Копіювати текст', 'result_label': 'Результат', 'decrypted_badge': 'Розшифровано', 'encrypted_badge': 'Fernet', 'copy_result': 'Копіювати', 'sec_encryption': 'ШИФРУВАННЯ', 'sec_decryption': 'РОЗШИФРУВАННЯ ТА БУФЕР', 'sec_appearance': 'ВИГЛЯД', 'sec_general': 'ЗАГАЛЬНІ', 'sec_language': 'МОВА', 'auto_clear_encrypt_title': 'Очищення після шифрування', 'auto_clear_encrypt_sub': 'Очищає поле', 'strict_title': 'Суворий режим', 'strict_sub': 'Пароль обов\'язковий', 'auto_paste_title': 'Авто-вставка', 'auto_paste_sub': 'Пошук ENC', 'auto_decrypt_wipe_title': 'Авто-розшифрування і очищення буфера', 'auto_decrypt_wipe_sub': 'Розшифровує та одразу очищає буфер', 'enter_action_title': 'Дія по Enter', 'enter_action_sub': 'Enter виконує шифрування', 'haptic_title': 'Віпровідгук', 'haptic_sub': 'Вібрація', 'project_github': 'GitHub', 'clear_fields': 'Очистити', 'fields_cleared': 'Очищено.', 'clipboard_empty': 'Порожньо.', 'clipboard_read_failed': 'Помилка.', 'clipboard_pasted': 'Вставлено!', 'auto_pasted_msg': 'Виявлено ENC!', 'enter_input_msg': 'Введіть текст.', 'pass_required_strict': 'Потрібен пароль!', 'plain_copied_warn': 'Без захисту!', 'encrypted_copied': 'Зашифровано!', 'encrypted_manual': 'Вручну', 'enter_pass_decrypt': 'Потрібен пароль.', 'invalid_format': 'Збій.', 'auth_failed': 'Помилка.', 'decrypted_success': 'Успіх!', 'encryption_error': 'Помилка: ', 'result_copied': 'Скопійовано!'},
  'tr': {'app_title': 'ClipGhost', 'settings_title': 'Ayarlar', 'master_passphrase': 'Parola', 'remember_passphrase': 'Hatırla', 'contacts_btn': 'Kişiler', 'manage_contacts': 'Anahtarlar', 'contact_name': 'İsim', 'contact_key': 'Parola', 'add_contact': 'Ekle', 'no_contacts': 'Yok.', 'select': 'Seç', 'input_label': 'Giriş', 'paste_button': 'Yapıştır', 'input_hint': 'Mesaj veya ENC::...', 'btn_decrypt': 'Çöz', 'btn_encrypt_copy': 'Şifrele', 'btn_copy_plain': 'Kopyala', 'result_label': 'Sonuç', 'decrypted_badge': 'Çözüldü', 'encrypted_badge': 'Fernet', 'copy_result': 'Kopyala', 'sec_encryption': 'ŞİFRELEME AYARLARI', 'sec_decryption': 'ÇÖZME VE PANO', 'sec_appearance': 'TEMA', 'sec_general': 'GENEL', 'sec_language': 'DİL', 'auto_clear_encrypt_title': 'Şifreleme sonrası temizle', 'auto_clear_encrypt_sub': 'Girişi temizler', 'strict_title': 'Katı Mod', 'strict_sub': 'Parola zorunlu', 'auto_paste_title': 'Otomatik Yapıştır', 'auto_paste_sub': 'ENC algıla', 'auto_decrypt_wipe_title': 'Otomatik çöz & Panoyu sil', 'auto_decrypt_wipe_sub': 'Hemen çözer ve panoyu temizler', 'enter_action_title': 'Enter ile çalıştır', 'enter_action_sub': 'Enter tuşu işlemi başlatır', 'haptic_title': 'Titreşim', 'haptic_sub': 'Geri bildirim', 'project_github': 'GitHub', 'clear_fields': 'Temizle', 'fields_cleared': 'Temizlendi.', 'clipboard_empty': 'Pano boş.', 'clipboard_read_failed': 'Hata.', 'clipboard_pasted': 'Yapıştırıldı!', 'auto_pasted_msg': 'Algılandı!', 'enter_input_msg': 'Metin girin.', 'pass_required_strict': 'Parola gerekli!', 'plain_copied_warn': 'Şifresiz!', 'encrypted_copied': 'Şifrelendi!', 'encrypted_manual': 'Manuel', 'enter_pass_decrypt': 'Parola.', 'invalid_format': 'Geçersiz.', 'auth_failed': 'Başarısız.', 'decrypted_success': 'Çözüldü!', 'encryption_error': 'Hata: ', 'result_copied': 'Kopyalandı!'},
  'ar': {'app_title': 'ClipGhost', 'settings_title': 'الإعدادات', 'master_passphrase': 'كلمة المرور', 'remember_passphrase': 'تذكر', 'contacts_btn': 'جهات الاتصال', 'manage_contacts': 'المفاتيح', 'contact_name': 'الاسم', 'contact_key': 'المفتاح', 'add_contact': 'إضافة', 'no_contacts': 'لا يوجد.', 'select': 'اختيار', 'input_label': 'الإدخال', 'paste_button': 'لصق', 'input_hint': 'نص أو ENC::...', 'btn_decrypt': 'فك التشفير', 'btn_encrypt_copy': 'تشفير', 'btn_copy_plain': 'نسخ عادي', 'result_label': 'النتيجة', 'decrypted_badge': 'مفكوكة', 'encrypted_badge': 'Fernet', 'copy_result': 'نسخ', 'sec_encryption': 'التشفير', 'sec_decryption': 'فك التشفير والحافظة', 'sec_appearance': 'المظهر', 'sec_general': 'عام', 'sec_language': 'اللغة', 'auto_clear_encrypt_title': 'مسح بعد التشفير', 'auto_clear_encrypt_sub': 'تفريغ الحقل', 'strict_title': 'وضع صارم', 'strict_sub': 'كلمة المرور إلزامية', 'auto_paste_title': 'لصق تلقائي', 'auto_paste_sub': 'كشف ENC', 'auto_decrypt_wipe_title': 'فك فوري ومسح الحافظة', 'auto_decrypt_wipe_sub': 'فك الشفرة فوراً وتفريغ الحافظة', 'enter_action_title': 'تنفيذ بـ Enter', 'enter_action_sub': 'Enter يشغل التشفير بدلاً من سطر جديد', 'haptic_title': 'اهتزاز', 'haptic_sub': 'لمس', 'project_github': 'GitHub', 'clear_fields': 'مسح', 'fields_cleared': 'تم.', 'clipboard_empty': 'فارغة.', 'clipboard_read_failed': 'خطأ.', 'clipboard_pasted': 'تم اللصق!', 'auto_pasted_msg': 'تم الكشف!', 'enter_input_msg': 'أدخل نص.', 'pass_required_strict': 'مطلوبة!', 'plain_copied_warn': 'غير مشفر!', 'encrypted_copied': 'تم التشفير!', 'encrypted_manual': 'يدوي', 'enter_pass_decrypt': 'كلمة المرور.', 'invalid_format': 'غير صالح.', 'auth_failed': 'فشل.', 'decrypted_success': 'نجاح!', 'encryption_error': 'خطأ: ', 'result_copied': 'تم النسخ!'},
  'hi': {'app_title': 'ClipGhost', 'settings_title': 'सेटिंग्स', 'master_passphrase': 'पासवर्ड', 'remember_passphrase': 'याद रखें', 'contacts_btn': 'संपर्क', 'manage_contacts': 'कुंजियाँ', 'contact_name': 'नाम', 'contact_key': 'पासवर्ड', 'add_contact': 'जोड़ें', 'no_contacts': 'कोई नहीं।', 'select': 'चुनें', 'input_label': 'इनपुट', 'paste_button': 'पेस्ट', 'input_hint': 'संदेश या ENC::...', 'btn_decrypt': 'डिक्रिप्ट', 'btn_encrypt_copy': 'एन्क्रिप्ट', 'btn_copy_plain': 'सादा कॉपी', 'result_label': 'परिणाम', 'decrypted_badge': 'डिक्रिप्टेड', 'encrypted_badge': 'Fernet', 'copy_result': 'कॉपी', 'sec_encryption': 'एन्क्रिप्शन सेटिंग्स', 'sec_decryption': 'डिक्रिप्शन और क्लिपबोर्ड', 'sec_appearance': 'थीम', 'sec_general': 'सामान्य', 'sec_language': 'भाषा', 'auto_clear_encrypt_title': 'एन्क्रिप्ट बाद हटाएं', 'auto_clear_encrypt_sub': 'साफ़ करें', 'strict_title': 'सख्त मोड', 'strict_sub': 'पासवर्ड अनिवार्य', 'auto_paste_title': 'ऑटो-पेस्ट', 'auto_paste_sub': 'ENC खोजें', 'auto_decrypt_wipe_title': 'त्वरित डिक्रिप्ट और क्लिपबोर्ड साफ़', 'auto_decrypt_wipe_sub': 'तुरंत डिक्रिप्ट करें और क्लिपबोर्ड साफ़ करें', 'enter_action_title': 'Enter से चलाएं', 'enter_action_sub': 'Enter नई लाइन के बजाय कार्रवाई चलाएगा', 'haptic_title': 'कंपन', 'haptic_sub': 'फीडबैक', 'project_github': 'GitHub', 'clear_fields': 'साफ़ करें', 'fields_cleared': 'साफ़ हुआ।', 'clipboard_empty': 'खाली है।', 'clipboard_read_failed': 'त्रुटि।', 'clipboard_pasted': 'पेस्ट हुआ!', 'auto_pasted_msg': 'पता चला!', 'enter_input_msg': 'पाठ दर्ज करें।', 'pass_required_strict': 'पासवर्ड आवश्यक!', 'plain_copied_warn': 'बिना एन्क्रिप्शन!', 'encrypted_copied': 'एन्क्रिप्ट हुआ!', 'encrypted_manual': 'मैन्युअल', 'enter_pass_decrypt': 'पासवर्ड दें।', 'invalid_format': 'अमान्य।', 'auth_failed': 'विफल।', 'decrypted_success': 'सफल!', 'encryption_error': 'त्रुटि: ', 'result_copied': 'कॉपी हुआ!'},
  'zh': {'app_title': 'ClipGhost', 'settings_title': '设置', 'master_passphrase': '主密码', 'remember_passphrase': '记住密码', 'contacts_btn': '联系人', 'manage_contacts': '管理密钥', 'contact_name': '名称', 'contact_key': '密钥', 'add_contact': '添加', 'no_contacts': '暂无。', 'select': '选择', 'input_label': '输入', 'paste_button': '粘贴', 'input_hint': '文本或 ENC::...', 'btn_decrypt': '解密', 'btn_encrypt_copy': '加密并复制', 'btn_copy_plain': '复制明文', 'result_label': '结果', 'decrypted_badge': '解密消息', 'encrypted_badge': 'Fernet', 'copy_result': '复制', 'sec_encryption': '加密设置', 'sec_decryption': '解密与剪贴板', 'sec_appearance': '外观与主题', 'sec_general': '通用设置', 'sec_language': '语言', 'auto_clear_encrypt_title': '加密后自动清空', 'auto_clear_encrypt_sub': '复制后清空输入框', 'strict_title': '严格密码模式', 'strict_sub': '必须输入密码', 'auto_paste_title': '打开时自动粘贴', 'auto_paste_sub': '检测 ENC 码', 'auto_decrypt_wipe_title': '立即解密并擦除剪贴板', 'auto_decrypt_wipe_sub': '识别到 ENC 立即解密并清空剪贴板', 'enter_action_title': '回车键执行', 'enter_action_sub': '按 Enter 直接触发加解密而非换行', 'haptic_title': '触觉反馈', 'haptic_sub': '操作振动', 'project_github': 'GitHub', 'clear_fields': '清空', 'fields_cleared': '已清空。', 'clipboard_empty': '剪贴板为空。', 'clipboard_read_failed': '读取失败。', 'clipboard_pasted': '已粘贴！', 'auto_pasted_msg': '已识别！', 'enter_input_msg': '请输入内容。', 'pass_required_strict': '必须输入密码！', 'plain_copied_warn': '未加密！', 'encrypted_copied': '已加密！', 'encrypted_manual': '手动复制', 'enter_pass_decrypt': '请输入密码。', 'invalid_format': '格式无效。', 'auth_failed': '解密失败。', 'decrypted_success': '解密成功！', 'encryption_error': '错误：', 'result_copied': '已复制！'},
  'ja': {'app_title': 'ClipGhost', 'settings_title': '設定', 'master_passphrase': 'パスフレーズ', 'remember_passphrase': '記憶', 'contacts_btn': '連絡先', 'manage_contacts': '鍵管理', 'contact_name': '名前', 'contact_key': '秘密鍵', 'add_contact': '追加', 'no_contacts': 'なし。', 'select': '選択', 'input_label': '入力', 'paste_button': '貼付け', 'input_hint': 'メッセージまたは ENC::...', 'btn_decrypt': '復号化', 'btn_encrypt_copy': '暗号化', 'btn_copy_plain': '平文コピー', 'result_label': '結果', 'decrypted_badge': '復号メッセージ', 'encrypted_badge': 'Fernet', 'copy_result': 'コピー', 'sec_encryption': '暗号化設定', 'sec_decryption': '復号化とクリップボード', 'sec_appearance': 'テーマ', 'sec_general': '全般', 'sec_language': '言語', 'auto_clear_encrypt_title': '暗号化後クリア', 'auto_clear_encrypt_sub': '入力欄消去', 'strict_title': '厳格モード', 'strict_sub': 'パスワード必須', 'auto_paste_title': '自動貼付け', 'auto_paste_sub': 'ENC検出', 'auto_decrypt_wipe_title': '即時復号＆クリップボード消去', 'auto_decrypt_wipe_sub': 'ENCを即座に復号しクリップボード消去', 'enter_action_title': 'Enterキーで実行', 'enter_action_sub': 'Enterキーで改行の代わりに実行', 'haptic_title': '触覚振動', 'haptic_sub': '操作時の振動', 'project_github': 'GitHub', 'clear_fields': 'クリア', 'fields_cleared': '消去完了。', 'clipboard_empty': '空です。', 'clipboard_read_failed': '読取失敗。', 'clipboard_pasted': '貼付完了！', 'auto_pasted_msg': '検出完了！', 'enter_input_msg': '入力して下さい。', 'pass_required_strict': 'パスワード必須！', 'plain_copied_warn': '未暗号化！', 'encrypted_copied': '暗号化完了！', 'encrypted_manual': '手動コピー', 'enter_pass_decrypt': 'パスワード要求。', 'invalid_format': '無効な形式。', 'auth_failed': '復号失敗。', 'decrypted_success': '成功！', 'encryption_error': 'エラー：', 'result_copied': 'コピー完了！'},
  'ko': {'app_title': 'ClipGhost', 'settings_title': '설정', 'master_passphrase': '암호', 'remember_passphrase': '기억', 'contacts_btn': '연락처', 'manage_contacts': '키 관리', 'contact_name': '이름', 'contact_key': '암호', 'add_contact': '추가', 'no_contacts': '없음.', 'select': '선택', 'input_label': '입력', 'paste_button': '붙여넣기', 'input_hint': '메시지 또는 ENC::...', 'btn_decrypt': '복호화', 'btn_encrypt_copy': '암호화', 'btn_copy_plain': '텍스트 복사', 'result_label': '결과', 'decrypted_badge': '복호화 메시지', 'encrypted_badge': 'Fernet', 'copy_result': '복사', 'sec_encryption': '암호화 설정', 'sec_decryption': '복호화 및 클립보드', 'sec_appearance': '테마', 'sec_general': '일반', 'sec_language': '언어', 'auto_clear_encrypt_title': '암호화 후 지우기', 'auto_clear_encrypt_sub': '입력창 비우기', 'strict_title': '엄격 모드', 'strict_sub': '비밀번호 필수', 'auto_paste_title': '자동 붙여넣기', 'auto_paste_sub': 'ENC 감지', 'auto_decrypt_wipe_title': '즉시 복호화 & 클립보드 삭제', 'auto_decrypt_wipe_sub': 'ENC 즉시 복호화 및 클립보드 비우기', 'enter_action_title': 'Enter 키로 실행', 'enter_action_sub': '줄바꿈 대신 Enter로 즉시 실행', 'haptic_title': '진동', 'haptic_sub': '피드백', 'project_github': 'GitHub', 'clear_fields': '지우기', 'fields_cleared': '지워짐.', 'clipboard_empty': '비어있음.', 'clipboard_read_failed': '실패.', 'clipboard_pasted': '붙여넣음!', 'auto_pasted_msg': '감지됨!', 'enter_input_msg': '입력하세요.', 'pass_required_strict': '비밀번호 필요!', 'plain_copied_warn': '암호화 안됨!', 'encrypted_copied': '암호화됨!', 'encrypted_manual': '수동 복사', 'enter_pass_decrypt': '비밀번호 입력.', 'invalid_format': '유효하지 않음.', 'auth_failed': '실패.', 'decrypted_success': '성공!', 'encryption_error': '오류: ', 'result_copied': '복사 완료!'},
  'vi': {'app_title': 'ClipGhost', 'settings_title': 'Cài đặt', 'master_passphrase': 'Mật khẩu', 'remember_passphrase': 'Lưu', 'contacts_btn': 'Danh bạ', 'manage_contacts': 'Khóa', 'contact_name': 'Tên', 'contact_key': 'Mật khẩu', 'add_contact': 'Thêm', 'no_contacts': 'Không có.', 'select': 'Chọn', 'input_label': 'Đầu vào', 'paste_button': 'Dán', 'input_hint': 'Văn bản hoặc ENC::...', 'btn_decrypt': 'Giải mã', 'btn_encrypt_copy': 'Mã hóa', 'btn_copy_plain': 'Chép thô', 'result_label': 'Kết quả', 'decrypted_badge': 'Đã giải mã', 'encrypted_badge': 'Fernet', 'copy_result': 'Chép', 'sec_encryption': 'CÀI ĐẶT MÃ HÓA', 'sec_decryption': 'GIẢI MÃ & BỘ NHỚ TẠM', 'sec_appearance': 'GIAO DIỆN', 'sec_general': 'CHUNG', 'sec_language': 'NGÔN NGỮ', 'auto_clear_encrypt_title': 'Xóa sau mã hóa', 'auto_clear_encrypt_sub': 'Làm sạch ô', 'strict_title': 'Nghiêm ngặt', 'strict_sub': 'Bắt buộc mật khẩu', 'auto_paste_title': 'Tự động dán', 'auto_paste_sub': 'Tìm ENC', 'auto_decrypt_wipe_title': 'Giải mã tức thì & Xóa bộ nhớ tạm', 'auto_decrypt_wipe_sub': 'Giải mã ngay và xóa sạch bộ nhớ tạm', 'enter_action_title': 'Thực thi bằng Enter', 'enter_action_sub': 'Nhấn Enter để chạy thao tác thay vì xuống dòng', 'haptic_title': 'Rung', 'haptic_sub': 'Phản hồi', 'project_github': 'GitHub', 'clear_fields': 'Xóa', 'fields_cleared': 'Đã xóa.', 'clipboard_empty': 'Trống.', 'clipboard_read_failed': 'Lỗi.', 'clipboard_pasted': 'Đã dán!', 'auto_pasted_msg': 'Đã tìm thấy!', 'enter_input_msg': 'Nhập tin nhắn.', 'pass_required_strict': 'Cần mật khẩu!', 'plain_copied_warn': 'Chưa mã hóa!', 'encrypted_copied': 'Đã mã hóa!', 'encrypted_manual': 'Thủ công', 'enter_pass_decrypt': 'Nhập mật khẩu.', 'invalid_format': 'Lỗi định dạng.', 'auth_failed': 'Thất bại.', 'decrypted_success': 'Thành công!', 'encryption_error': 'Lỗi: ', 'result_copied': 'Đã chép!'},
  'id': {'app_title': 'ClipGhost', 'settings_title': 'Pengaturan', 'master_passphrase': 'Sandi', 'remember_passphrase': 'Ingat', 'contacts_btn': 'Kontak', 'manage_contacts': 'Kunci', 'contact_name': 'Nama', 'contact_key': 'Sandi', 'add_contact': 'Tambah', 'no_contacts': 'Kosong.', 'select': 'Pilih', 'input_label': 'Input', 'paste_button': 'Tempel', 'input_hint': 'Pesan atau ENC::...', 'btn_decrypt': 'Dekripsi', 'btn_encrypt_copy': 'Enkripsi', 'btn_copy_plain': 'Salin Teks', 'result_label': 'Hasil', 'decrypted_badge': 'Terbuka', 'encrypted_badge': 'Fernet', 'copy_result': 'Salin', 'sec_encryption': 'ENKRIPSI', 'sec_decryption': 'DEKRIPSI & PAPAN KLIP', 'sec_appearance': 'TEMA', 'sec_general': 'UMUM', 'sec_language': 'BAHASA', 'auto_clear_encrypt_title': 'Bersihkan usai enkripsi', 'auto_clear_encrypt_sub': 'Kosongkan input', 'strict_title': 'Mode ketat', 'strict_sub': 'Sandi wajib', 'auto_paste_title': 'Tempel otomatis', 'auto_paste_sub': 'Deteksi ENC', 'auto_decrypt_wipe_title': 'Dekripsi instan & Hapus papan klip', 'auto_decrypt_wipe_sub': 'Langsung dekripsi dan kosongkan papan klip', 'enter_action_title': 'Eksekusi dengan Enter', 'enter_action_sub': 'Enter menjalankan enkripsi/dekripsi', 'haptic_title': 'Getar', 'haptic_sub': 'Umpan balik', 'project_github': 'GitHub', 'clear_fields': 'Bersihkan', 'fields_cleared': 'Dibersihkan.', 'clipboard_empty': 'Kosong.', 'clipboard_read_failed': 'Gagal.', 'clipboard_pasted': 'Ditempel!', 'auto_pasted_msg': 'Terdeteksi!', 'enter_input_msg': 'Masukkan teks.', 'pass_required_strict': 'Sandi wajib!', 'plain_copied_warn': 'Tanpa proteksi!', 'encrypted_copied': 'Terenkripsi!', 'encrypted_manual': 'Manual', 'enter_pass_decrypt': 'Perlu sandi.', 'invalid_format': 'Tidak sah.', 'auth_failed': 'Gagal.', 'decrypted_success': 'Berhasil!', 'encryption_error': 'Kesalahan: ', 'result_copied': 'Disalin!'},
  'sv': {'app_title': 'ClipGhost', 'settings_title': 'Inställningar', 'master_passphrase': 'Lösenord', 'remember_passphrase': 'Spara', 'contacts_btn': 'Kontakter', 'manage_contacts': 'Nycklar', 'contact_name': 'Namn', 'contact_key': 'Lösenord', 'add_contact': 'Lägg till', 'no_contacts': 'Inga.', 'select': 'Välj', 'input_label': 'Inmatning', 'paste_button': 'Klistra', 'input_hint': 'Text eller ENC::...', 'btn_decrypt': 'Dekryptera', 'btn_encrypt_copy': 'Kryptera', 'btn_copy_plain': 'Klartext', 'result_label': 'Resultat', 'decrypted_badge': 'Dekrypterat', 'encrypted_badge': 'Fernet', 'copy_result': 'Kopiera', 'sec_encryption': 'KRYPTERING', 'sec_decryption': 'DEKRYPTERING & URKLIPP', 'sec_appearance': 'FÄRGER', 'sec_general': 'ALLMÄNT', 'sec_language': 'SPRÅK', 'auto_clear_encrypt_title': 'Rensa efter kryptering', 'auto_clear_encrypt_sub': 'Tömmer fält', 'strict_title': 'Strikt läge', 'strict_sub': 'Lösenord krävs', 'auto_paste_title': 'Auto-klistra', 'auto_paste_sub': 'Läs ENC', 'auto_decrypt_wipe_title': 'Direktdekryptera & Rensa urklipp', 'auto_decrypt_wipe_sub': 'Avkodar direkt och tömmer urklipp', 'enter_action_title': 'Kör med Enter', 'enter_action_sub': 'Enter kör kryptering istället för ny rad', 'haptic_title': 'Vibration', 'haptic_sub': 'Feedback', 'project_github': 'GitHub', 'clear_fields': 'Rensa', 'fields_cleared': 'Rensat.', 'clipboard_empty': 'Tomt.', 'clipboard_read_failed': 'Fel.', 'clipboard_pasted': 'Inklistrat!', 'auto_pasted_msg': 'Upptäckt!', 'enter_input_msg': 'Ange text.', 'pass_required_strict': 'Lösenord saknas!', 'plain_copied_warn': 'Okrypterat!', 'encrypted_copied': 'Krypterat!', 'encrypted_manual': 'Manuell', 'enter_pass_decrypt': 'Lösenord behövs.', 'invalid_format': 'Ogiltigt.', 'auth_failed': 'Misslyckades.', 'decrypted_success': 'Klart!', 'encryption_error': 'Fel: ', 'result_copied': 'Kopierat!'},
  'no': {'app_title': 'ClipGhost', 'settings_title': 'Innstillinger', 'master_passphrase': 'Passord', 'remember_passphrase': 'Husk', 'contacts_btn': 'Kontakter', 'manage_contacts': 'Nøkler', 'contact_name': 'Navn', 'contact_key': 'Passord', 'add_contact': 'Legg til', 'no_contacts': 'Ingen.', 'select': 'Velg', 'input_label': 'Inndata', 'paste_button': 'Lim inn', 'input_hint': 'Tekst eller ENC::...', 'btn_decrypt': 'Dekrypter', 'btn_encrypt_copy': 'Krypter', 'btn_copy_plain': 'Ren tekst', 'result_label': 'Resultat', 'decrypted_badge': 'Dekryptert', 'encrypted_badge': 'Fernet', 'copy_result': 'Kopier', 'sec_encryption': 'KRYPTERING', 'sec_decryption': 'DEKRYPTERING & UTKLIPP', 'sec_appearance': 'TEMAER', 'sec_general': 'GENERELT', 'sec_language': 'SPRÅK', 'auto_clear_encrypt_title': 'Tøm etter kryptering', 'auto_clear_encrypt_sub': 'Tømmer felt', 'strict_title': 'Streng modus', 'strict_sub': 'Passord påkrevd', 'auto_paste_title': 'Auto-lim', 'auto_paste_sub': 'Finn ENC', 'auto_decrypt_wipe_title': 'Umiddelbar dekryptering & Tøm utklipp', 'auto_decrypt_wipe_sub': 'Dekrypterer og sletter utklippstavle umiddelbart', 'enter_action_title': 'Kjør med Enter', 'enter_action_sub': 'Enter starter handling i stedet for ny linje', 'haptic_title': 'Vibrasjon', 'haptic_sub': 'Feedback', 'project_github': 'GitHub', 'clear_fields': 'Tøm', 'fields_cleared': 'Tømt.', 'clipboard_empty': 'Tomt.', 'clipboard_read_failed': 'Feil.', 'clipboard_pasted': 'Limt inn!', 'auto_pasted_msg': 'Oppdaget!', 'enter_input_msg': 'Skriv melding.', 'pass_required_strict': 'Passord kreves!', 'plain_copied_warn': 'Ukryptert!', 'encrypted_copied': 'Kryptert!', 'encrypted_manual': 'Manuell', 'enter_pass_decrypt': 'Passord trengs.', 'invalid_format': 'Ugyldig.', 'auth_failed': 'Feilet.', 'decrypted_success': 'Suksess!', 'encryption_error': 'Feil: ', 'result_copied': 'Kopiert!'},
  'cs': {'app_title': 'ClipGhost', 'settings_title': 'Nastavení', 'master_passphrase': 'Heslo', 'remember_passphrase': 'Pamatovat', 'contacts_btn': 'Kontakty', 'manage_contacts': 'Klíče', 'contact_name': 'Jméno', 'contact_key': 'Heslo', 'add_contact': 'Přidat', 'no_contacts': 'Žádné.', 'select': 'Vybrat', 'input_label': 'Vstup', 'paste_button': 'Vložit', 'input_hint': 'Zpráva nebo ENC::...', 'btn_decrypt': 'Dešifrovat', 'btn_encrypt_copy': 'Zašifrovat', 'btn_copy_plain': 'Prostý text', 'result_label': 'Výsledek', 'decrypted_badge': 'Dešifrováno', 'encrypted_badge': 'Fernet', 'copy_result': 'Kopírovat', 'sec_encryption': 'NASTAVENÍ ŠIFROVÁNÍ', 'sec_decryption': 'DEŠIFROVÁNÍ A SCHRÁNKA', 'sec_appearance': 'VZHLED', 'sec_general': 'OBECNÉ', 'sec_language': 'JAZYK', 'auto_clear_encrypt_title': 'Vymazat po šifrování', 'auto_clear_encrypt_sub': 'Vyprázdní pole', 'strict_title': 'Striktní režim', 'strict_sub': 'Heslo povinné', 'auto_paste_title': 'Auto-vložení', 'auto_paste_sub': 'Hledat ENC', 'auto_decrypt_wipe_title': 'Okamžité dešifrování & Vymazání schránky', 'auto_decrypt_wipe_sub': 'Ihned dešifruje a vymaže schránku', 'enter_action_title': 'Spustit Enterem', 'enter_action_sub': 'Enter spustí šifrování místo nového řádku', 'haptic_title': 'Vibrace', 'haptic_sub': 'Odezva', 'project_github': 'GitHub', 'clear_fields': 'Vymazat', 'fields_cleared': 'Vymazáno.', 'clipboard_empty': 'Prázdno.', 'clipboard_read_failed': 'Chyba.', 'clipboard_pasted': 'Vloženo!', 'auto_pasted_msg': 'Zjištěno!', 'enter_input_msg': 'Zadejte text.', 'pass_required_strict': 'Heslo nutné!', 'plain_copied_warn': 'Nezašifrováno!', 'encrypted_copied': 'Zašifrováno!', 'encrypted_manual': 'Ručně', 'enter_pass_decrypt': 'Zadejte heslo.', 'invalid_format': 'Neplatné.', 'auth_failed': 'Chyba.', 'decrypted_success': 'Hotovo!', 'encryption_error': 'Chyba: ', 'result_copied': 'Zkopírováno!'},
};

const Map<String, String> languageNames = {
  'en': 'English (US/UK)',
  'hu': 'Magyar (Hungarian)',
  'de': 'Deutsch (German)',
  'es': 'Español (Spanish)',
  'fr': 'Français (French)',
  'it': 'Italiano (Italian)',
  'pt': 'Português (Portuguese)',
  'nl': 'Nederlands (Dutch)',
  'pl': 'Polski (Polish)',
  'ru': 'Русский (Russian)',
  'uk': 'Українська (Ukrainian)',
  'tr': 'Türkçe (Turkish)',
  'ar': 'العربية (Arabic)',
  'hi': 'हिन्दी (Hindi)',
  'zh': '简体中文 (Chinese)',
  'ja': '日本語 (Japanese)',
  'ko': '한국어 (Korean)',
  'vi': 'Tiếng Việt (Vietnamese)',
  'id': 'Bahasa Indonesia (Indonesian)',
  'sv': 'Svenska (Swedish)',
  'no': 'Norsk (Norwegian)',
  'cs': 'Čeština (Czech)',
};

class ClipGhostApp extends StatefulWidget {
  const ClipGhostApp({super.key});

  @override
  State<ClipGhostApp> createState() => _ClipGhostAppState();
}

class _ClipGhostAppState extends State<ClipGhostApp> {
  int _bgValue = 0xFF0A0E14;
  int _accentValue = 0xFF00E676;
  String _currentLanguage = 'en';

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _bgValue = prefs.getInt('bg_color') ?? 0xFF0A0E14;
      _accentValue = prefs.getInt('accent_color') ?? 0xFF00E676;
      _currentLanguage = prefs.getString('app_language') ?? 'en';
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

  Future<void> _updateLanguage(String langCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_language', langCode);
    setState(() {
      _currentLanguage = langCode;
    });
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = Color(_bgValue);
    final accentColor = Color(_accentValue);
    final isLight = _bgValue == 0xFFF5F7FA;

    return MaterialApp(
      title: 'ClipGhost',
      debugShowCheckedModeBanner: false,
      theme: isLight
          ? ThemeData.light().copyWith(
              scaffoldBackgroundColor: bgColor,
              primaryColor: accentColor,
              colorScheme: ColorScheme.light(
                primary: accentColor,
                surface: Colors.white,
              ),
            )
          : ThemeData.dark().copyWith(
              scaffoldBackgroundColor: bgColor,
              primaryColor: accentColor,
              colorScheme: ColorScheme.dark(
                primary: accentColor,
                surface: const Color(0xFF141923),
              ),
            ),
      home: MainScreen(
        backgroundColor: bgColor,
        accentColor: accentColor,
        bgValue: _bgValue,
        accentValue: _accentValue,
        isLight: isLight,
        currentLanguage: _currentLanguage,
        onThemeChanged: _updateColors,
        onLanguageChanged: _updateLanguage,
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  final Color backgroundColor;
  final Color accentColor;
  final int bgValue;
  final int accentValue;
  final bool isLight;
  final String currentLanguage;
  final Function(int, int) onThemeChanged;
  final Function(String) onLanguageChanged;

  const MainScreen({
    super.key,
    required this.backgroundColor,
    required this.accentColor,
    required this.bgValue,
    required this.accentValue,
    required this.isLight,
    required this.currentLanguage,
    required this.onThemeChanged,
    required this.onLanguageChanged,
  });

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with WidgetsBindingObserver {
  final TextEditingController _passphraseController = TextEditingController();
  final TextEditingController _textController = TextEditingController();
  final TextEditingController _outputController = TextEditingController();

  bool _obscurePassphrase = true;
  bool _rememberPassphrase = false;
  bool _isLoading = false;

  // Strukturált beállítások
  bool _autoClearInputOnEncrypt = true; // Kódolás utáni törlés (Toggle, default: TRUE)
  bool _strictPasswordRequired = false;

  bool _autoPasteOnResume = false;
  bool _instantDecryptAndWipe = true;

  bool _enterTriggersAction = false;
  bool _hapticFeedbackEnabled = false;

  bool _isDecryptedOutput = false;
  String? _timestampInfo;
  int _charCount = 0;

  Map<String, String> _contacts = {};

  static const String _fixedSalt = 'ipari_biztonsagi_fix_so_2026';
  static const int _pbkdf2Iterations = 480000;

  String tr(String key) {
    return localizedStrings[widget.currentLanguage]?[key] ??
        localizedStrings['en']?[key] ??
        key;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadAllSettings();
    _loadContacts();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _passphraseController.dispose();
    _textController.dispose();
    _outputController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _autoPasteOnResume) {
      _checkAndAutoPaste();
    }
  }

  Future<void> _checkAndAutoPaste() async {
    try {
      final clipData = await Clipboard.getData(Clipboard.kTextPlain);
      final text = clipData?.text?.trim() ?? '';
      if (text.startsWith('ENC::') && text != _textController.text) {
        if (_instantDecryptAndWipe && _passphraseController.text.isNotEmpty) {
          await _decryptText(text, wipeClipboardNow: true);
        } else {
          setState(() => _textController.text = text);
          _triggerHaptic();
          _showToast(tr('auto_pasted_msg'));
        }
      }
    } catch (_) {}
  }

  Future<void> _loadAllSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('saved_passphrase');
    setState(() {
      if (saved != null && saved.isNotEmpty) {
        _passphraseController.text = saved;
        _rememberPassphrase = true;
      }
      _autoClearInputOnEncrypt = prefs.getBool('setting_auto_clear_encrypt') ?? true;
      _strictPasswordRequired = prefs.getBool('setting_strict') ?? false;

      _autoPasteOnResume = prefs.getBool('setting_auto_paste') ?? false;
      _instantDecryptAndWipe = prefs.getBool('setting_instant_decrypt_wipe') ?? true;
      _enterTriggersAction = prefs.getBool('setting_enter_action') ?? false;

      _hapticFeedbackEnabled = prefs.getBool('setting_haptic') ?? false;
    });
  }

  Future<void> _saveSetting(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  Future<void> _loadContacts() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('saved_contacts_json');
    if (raw != null) {
      try {
        final decoded = jsonDecode(raw) as Map<String, dynamic>;
        setState(() {
          _contacts = decoded.map((k, v) => MapEntry(k, v.toString()));
        });
      } catch (_) {}
    }
  }

  Future<void> _saveContacts() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('saved_contacts_json', jsonEncode(_contacts));
  }

  static const MethodChannel _vibrateChannel = MethodChannel("com.kovacsmaxi.clipghost/vibrate");

  void _triggerHaptic() async {
    if (_hapticFeedbackEnabled) {
      try {
        await _vibrateChannel.invokeMethod('vibrateHardware');
      } catch (_) {
        HapticFeedback.vibrate();
      }
    }
  }

  Future<void> _wipeClipboardImmediately() async {
    try {
      await Clipboard.setData(const ClipboardData(text: ''));
    } catch (_) {}
  }

  void _showToast(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline_rounded : Icons.check_circle_outline_rounded,
              color: isError ? const Color(0xFFFF5252) : widget.accentColor,
              size: 22,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                msg,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 13.5,
                  letterSpacing: 0.2,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF1E2532),
        behavior: SnackBarBehavior.floating,
        elevation: 8,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: isError ? const Color(0xFFFF5252).withValues(alpha: 0.6) : widget.accentColor.withValues(alpha: 0.4),
            width: 1.2,
          ),
        ),
        duration: Duration(seconds: isError ? 3 : 2),
      ),
    );
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

  String _urlSafeBase64Encode(List<int> bytes) => base64UrlEncode(bytes);

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

  Future<void> _handleSmartAction() async {
    final input = _textController.text.trim();
    if (input.isEmpty) {
      _showToast(tr('enter_input_msg'), isError: true);
      return;
    }

    if (input.startsWith('ENC::')) {
      await _decryptText(input);
    } else {
      await _encryptText(input);
    }
  }

  Future<void> _encryptText(String text) async {
    final pass = _passphraseController.text;

    if (pass.isEmpty) {
      if (_strictPasswordRequired) {
        _showToast(tr('pass_required_strict'), isError: true);
        return;
      }
      setState(() {
        _outputController.text = text;
        _isDecryptedOutput = false;
        _timestampInfo = null;
        _charCount = text.length;
        if (_autoClearInputOnEncrypt) {
          _textController.clear();
        }
      });
      try {
        await Clipboard.setData(ClipboardData(text: text));
        _triggerHaptic();
        _showToast(tr('plain_copied_warn'));
      } catch (_) {}
      return;
    }

    setState(() => _isLoading = true);

    try {
      final rawKey = await _deriveRaw32Bytes(pass);
      final signingKey = rawKey.sublist(0, 16);
      final encryptionKey = rawKey.sublist(16, 32);

      final header = Uint8List(9);
      header[0] = 0x80;
      int timestampSec = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      for (int i = 8; i >= 1; i--) {
        header[i] = timestampSec & 0xFF;
        timestampSec = timestampSec >> 8;
      }

      final iv = _generateRandomBytes(16);
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

      setState(() {
        _outputController.text = finalResult;
        _isDecryptedOutput = false;
        _timestampInfo = null;
        _charCount = text.length;
        if (_autoClearInputOnEncrypt) {
          _textController.clear();
        }
      });

      try {
        await Clipboard.setData(ClipboardData(text: finalResult));
        _triggerHaptic();
        _showToast(tr('encrypted_copied'));
      } catch (_) {
        _showToast(tr('encrypted_manual'));
      }
    } catch (e) {
      _showToast('${tr('encryption_error')}$e', isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // DEKÓDOLÁS: SIKERES FELOLDÁSKOR AZ INPUT MEZŐ MINDIG KÖTELEZŐEN TÖRLŐDIK
  Future<void> _decryptText(String rawPayload, {bool wipeClipboardNow = false}) async {
    final pass = _passphraseController.text;
    if (pass.isEmpty) {
      _showToast(tr('enter_pass_decrypt'), isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final base64Part = rawPayload.replaceFirst('ENC::', '').trim();
      final token = _urlSafeBase64Decode(base64Part);

      if (token.length < 57 || token[0] != 0x80) {
        throw Exception(tr('invalid_format'));
      }

      int tokenSec = 0;
      for (int i = 1; i <= 8; i++) {
        tokenSec = (tokenSec << 8) | token[i];
      }
      final tokenDate = DateTime.fromMillisecondsSinceEpoch(tokenSec * 1000);
      final formattedTime =
          '${tokenDate.hour.toString().padLeft(2, '0')}:${tokenDate.minute.toString().padLeft(2, '0')}:${tokenDate.second.toString().padLeft(2, '0')}';

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
        throw Exception('HMAC');
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
        _isDecryptedOutput = true;
        _timestampInfo = formattedTime;
        _charCount = clearText.length;
        // Dekódoláskor kötelezően mindig kitisztítjuk a beviteli mezőt
        _textController.clear();
      });

      _triggerHaptic();

      if (wipeClipboardNow || _instantDecryptAndWipe) {
        await _wipeClipboardImmediately();
      }

      _showToast(tr('decrypted_success'));
    } catch (e) {
      _showToast(tr('auth_failed'), isError: true);
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

  Future<void> _quickPasteFromClipboard() async {
    try {
      final clipData = await Clipboard.getData(Clipboard.kTextPlain);
      final text = clipData?.text?.trim() ?? '';
      if (text.isNotEmpty) {
        setState(() => _textController.text = text);
        if (_instantDecryptAndWipe && text.startsWith('ENC::') && _passphraseController.text.isNotEmpty) {
          await _decryptText(text, wipeClipboardNow: true);
        } else {
          _triggerHaptic();
          _showToast(tr('clipboard_pasted'));
        }
      } else {
        _showToast(tr('clipboard_empty'), isError: true);
      }
    } catch (_) {
      _showToast(tr('clipboard_read_failed'), isError: true);
    }
  }

  Future<void> _copyResultToClipboard() async {
    if (_outputController.text.isNotEmpty) {
      await Clipboard.setData(ClipboardData(text: _outputController.text));
      _triggerHaptic();
      _showToast(tr('result_copied'));
    }
  }

  void _clearAll() {
    setState(() {
      _textController.clear();
      _outputController.clear();
      _isDecryptedOutput = false;
      _timestampInfo = null;
      _charCount = 0;
    });
    _triggerHaptic();
    _showToast(tr('fields_cleared'));
  }

  void _openContactsDialog() {
    final nameCtrl = TextEditingController();
    final keyCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: widget.isLight ? Colors.white : const Color(0xFF141923),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
              left: 20,
              right: 20,
              top: 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      tr('manage_contacts'),
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: widget.isLight ? const Color(0xFF0F172A) : Colors.white,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const Divider(),
                if (_contacts.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Center(
                      child: Text(
                        tr('no_contacts'),
                        style: TextStyle(color: widget.isLight ? Colors.grey : Colors.white54),
                      ),
                    ),
                  )
                else
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 180),
                    child: ListView(
                      shrinkWrap: true,
                      children: _contacts.entries.map((e) {
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(
                            backgroundColor: widget.accentColor.withValues(alpha: 0.2),
                            child: Text(
                              e.key.substring(0, 1).toUpperCase(),
                              style: TextStyle(color: widget.accentColor, fontWeight: FontWeight.bold),
                            ),
                          ),
                          title: Text(e.key, style: TextStyle(color: widget.isLight ? Colors.black : Colors.white)),
                          subtitle: const Text('••••••••••••', style: TextStyle(letterSpacing: 2)),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ElevatedButton(
                                onPressed: () {
                                  setState(() {
                                    _passphraseController.text = e.value;
                                  });
                                  Navigator.pop(ctx);
                                  _showToast('${e.key} (${tr('contacts_btn')})');
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: widget.accentColor,
                                  foregroundColor: Colors.black,
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  minimumSize: Size.zero,
                                ),
                                child: Text(tr('select'), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                                onPressed: () {
                                  setSheetState(() => _contacts.remove(e.key));
                                  setState(() {});
                                  _saveContacts();
                                },
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                const Divider(),
                Text(tr('add_contact'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 8),
                TextField(
                  controller: nameCtrl,
                  decoration: InputDecoration(
                    labelText: tr('contact_name'),
                    isDense: true,
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: keyCtrl,
                  decoration: InputDecoration(
                    labelText: tr('contact_key'),
                    isDense: true,
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      final n = nameCtrl.text.trim();
                      final k = keyCtrl.text.trim();
                      if (n.isNotEmpty && k.isNotEmpty) {
                        setSheetState(() => _contacts[n] = k);
                        setState(() {});
                        _saveContacts();
                        nameCtrl.clear();
                        keyCtrl.clear();
                      }
                    },
                    icon: const Icon(Icons.person_add_alt, size: 16),
                    label: Text(tr('add_contact')),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: widget.accentColor,
                      foregroundColor: Colors.black,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLight = widget.isLight;
    final textColor = isLight ? const Color(0xFF1E293B) : Colors.white;
    final secondaryTextColor = isLight ? const Color(0xFF64748B) : Colors.grey.shade400;

    final inputText = _textController.text.trim();
    final isEncryptedPayload = inputText.startsWith('ENC::');
    final isPassEmpty = _passphraseController.text.isEmpty;

    String buttonText;
    IconData buttonIcon;
    Color buttonColor;
    Color buttonTextColor = Colors.black;

    if (isEncryptedPayload) {
      buttonText = tr('btn_decrypt');
      buttonIcon = Icons.lock_open_rounded;
      buttonColor = const Color(0xFF00B0FF);
    } else if (isPassEmpty && !_strictPasswordRequired) {
      buttonText = tr('btn_copy_plain');
      buttonIcon = Icons.copy_rounded;
      buttonColor = const Color(0xFFFFB300);
    } else {
      buttonText = tr('btn_encrypt_copy');
      buttonIcon = Icons.enhanced_encryption_rounded;
      buttonColor = widget.accentColor;
    }

    return Scaffold(
      backgroundColor: widget.backgroundColor,
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.shield_outlined, color: widget.accentColor, size: 22),
            const SizedBox(width: 8),
            Text(
              tr('app_title'),
              style: TextStyle(
                color: isLight ? const Color(0xFF0F172A) : widget.accentColor,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
        iconTheme: IconThemeData(color: isLight ? const Color(0xFF0F172A) : Colors.white),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.people_alt_rounded),
            tooltip: tr('contacts_btn'),
            onPressed: _openContactsDialog,
          ),
          IconButton(
            icon: const Icon(Icons.cleaning_services_outlined),
            tooltip: tr('clear_fields'),
            onPressed: _clearAll,
          ),
        ],
      ),
      drawer: _buildSettingsDrawer(),
      body: SafeArea(
        child: Container(
          width: double.infinity,
          height: double.infinity,
          color: widget.backgroundColor,
          child: _isLoading
              ? Center(child: CircularProgressIndicator(color: widget.accentColor))
              : ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  children: [
                    // Mesterjelszó Kártya
                    _buildCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextField(
                            controller: _passphraseController,
                            obscureText: _obscurePassphrase,
                            style: TextStyle(color: textColor, fontSize: 15),
                            decoration: InputDecoration(
                              isDense: true,
                              labelText: tr('master_passphrase'),
                              labelStyle: TextStyle(
                                color: isLight ? const Color(0xFF0F766E) : widget.accentColor,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                              border: InputBorder.none,
                              suffixIcon: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    _passphraseController.text.isNotEmpty
                                        ? Icons.verified_user_rounded
                                        : Icons.gpp_bad_outlined,
                                    color: _passphraseController.text.isNotEmpty
                                        ? (isLight ? const Color(0xFF0D9488) : widget.accentColor)
                                        : Colors.grey.withValues(alpha: 0.5),
                                    size: 18,
                                  ),
                                  IconButton(
                                    icon: Icon(
                                      _obscurePassphrase
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                      color: secondaryTextColor,
                                      size: 18,
                                    ),
                                    onPressed: () => setState(() => _obscurePassphrase = !_obscurePassphrase),
                                  ),
                                ],
                              ),
                            ),
                            onChanged: (val) async {
                              setState(() {});
                              if (_rememberPassphrase) {
                                final prefs = await SharedPreferences.getInstance();
                                await prefs.setString('saved_passphrase', val);
                              }
                            },
                          ),
                          Row(
                            children: [
                              Checkbox(
                                value: _rememberPassphrase,
                                activeColor: widget.accentColor,
                                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                onChanged: (val) async {
                                  final prefs = await SharedPreferences.getInstance();
                                  setState(() => _rememberPassphrase = val ?? false);
                                  if (_rememberPassphrase) {
                                    await prefs.setString('saved_passphrase', _passphraseController.text);
                                  } else {
                                    await prefs.remove('saved_passphrase');
                                  }
                                },
                              ),
                              Expanded(
                                child: Text(
                                  tr('remember_passphrase'),
                                  style: TextStyle(color: secondaryTextColor, fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Bemeneti Kártya
                    _buildCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                tr('input_label'),
                                style: TextStyle(
                                  color: secondaryTextColor,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.8,
                                ),
                              ),
                              TextButton.icon(
                                onPressed: _quickPasteFromClipboard,
                                icon: const Icon(Icons.content_paste_go, size: 14),
                                label: Text(tr('paste_button'), style: const TextStyle(fontSize: 12)),
                                style: TextButton.styleFrom(
                                  foregroundColor: isLight ? const Color(0xFF0F766E) : widget.accentColor,
                                  padding: EdgeInsets.zero,
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _textController,
                            maxLines: _enterTriggersAction ? 1 : 4,
                            textInputAction: _enterTriggersAction ? TextInputAction.done : TextInputAction.newline,
                            style: TextStyle(color: textColor, fontSize: 14),
                            decoration: InputDecoration(
                              hintText: tr('input_hint'),
                              hintStyle: TextStyle(
                                color: isLight ? Colors.black26 : Colors.white30,
                                fontSize: 13,
                              ),
                              border: InputBorder.none,
                            ),
                            onSubmitted: _enterTriggersAction ? (_) => _handleSmartAction() : null,
                            onChanged: (val) {
                              final trimmed = val.trim();
                              if (_instantDecryptAndWipe &&
                                  trimmed.startsWith('ENC::') &&
                                  _passphraseController.text.isNotEmpty) {
                                _decryptText(trimmed, wipeClipboardNow: true);
                              } else {
                                setState(() {});
                              }
                            },
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Smart Action Gomb
                    ElevatedButton.icon(
                      onPressed: _handleSmartAction,
                      icon: Icon(buttonIcon, size: 20),
                      label: Text(
                        buttonText,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: buttonColor,
                        foregroundColor: buttonTextColor,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        elevation: 2,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),

                    const SizedBox(height: 18),

                    // Eredmény Kártya
                    if (_outputController.text.isNotEmpty) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Icon(
                                  _isDecryptedOutput ? Icons.lock_open_rounded : Icons.lock_outline_rounded,
                                  size: 16,
                                  color: _isDecryptedOutput
                                      ? (isLight ? const Color(0xFF0284C7) : const Color(0xFF00E5FF))
                                      : secondaryTextColor,
                                ),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    _isDecryptedOutput
                                        ? '${tr('decrypted_badge')} • $_charCount chars'
                                        : '${tr('result_label')} • $_charCount chars',
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: _isDecryptedOutput
                                          ? (isLight ? const Color(0xFF0284C7) : const Color(0xFF00E5FF))
                                          : secondaryTextColor,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 6),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: _isDecryptedOutput
                                      ? (isLight ? const Color(0xFFE0F2FE) : const Color(0xFF00E5FF).withValues(alpha: 0.15))
                                      : widget.accentColor.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  _isDecryptedOutput
                                      ? (_timestampInfo != null ? 'SECURE • $_timestampInfo' : 'DECRYPTED')
                                      : 'Fernet',
                                  style: TextStyle(
                                    color: _isDecryptedOutput
                                        ? (isLight ? const Color(0xFF0369A1) : const Color(0xFF00E5FF))
                                        : (isLight ? const Color(0xFF0F766E) : widget.accentColor),
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              InkWell(
                                onTap: _copyResultToClipboard,
                                borderRadius: BorderRadius.circular(4),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                  child: Row(
                                    children: [
                                      Icon(Icons.copy_rounded, size: 14, color: isLight ? const Color(0xFF0F766E) : widget.accentColor),
                                      const SizedBox(width: 4),
                                      Text(
                                        tr('copy_result'),
                                        style: TextStyle(
                                          color: isLight ? const Color(0xFF0F766E) : widget.accentColor,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: _isDecryptedOutput
                              ? (isLight ? const Color(0xFFF0F9FF) : const Color(0xFF0D1C2A))
                              : (isLight ? Colors.white : const Color(0xFF141923)),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: _isDecryptedOutput
                                ? (isLight ? const Color(0xFF38BDF8) : const Color(0xFF00E5FF).withValues(alpha: 0.5))
                                : (isLight ? const Color(0xFFE2E8F0) : widget.accentColor.withValues(alpha: 0.3)),
                            width: _isDecryptedOutput ? 1.5 : 1.0,
                          ),
                        ),
                        child: SelectableText(
                          _outputController.text,
                          style: TextStyle(
                            color: textColor,
                            fontFamily: _isDecryptedOutput ? null : 'monospace',
                            fontSize: _isDecryptedOutput ? 15 : 13,
                            fontWeight: _isDecryptedOutput ? FontWeight.w500 : FontWeight.normal,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildCard({required Widget child}) {
    final isLight = widget.isLight;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isLight ? Colors.white : const Color(0xFF141923),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isLight ? const Color(0xFFE2E8F0) : const Color(0xFF222B38)),
        boxShadow: isLight
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ]
            : [],
      ),
      child: child,
    );
  }

  // STRUKTURÁLT BEÁLLÍTÁSOK MENÜ
  Widget _buildSettingsDrawer() {
    final isLight = widget.isLight;
    final drawerBg = isLight ? Colors.white : const Color(0xFF0F141C);
    final drawerHeaderBg = isLight ? const Color(0xFFF8FAFC) : const Color(0xFF070A0E);
    final titleColor = isLight ? const Color(0xFF0F172A) : Colors.white;
    final subtitleColor = isLight ? const Color(0xFF64748B) : Colors.grey;

    return Drawer(
      backgroundColor: drawerBg,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: drawerHeaderBg),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.shield_rounded, color: widget.accentColor, size: 28),
                    const SizedBox(width: 10),
                    Text(
                      tr('app_title'),
                      style: TextStyle(
                        color: isLight ? const Color(0xFF0F172A) : widget.accentColor,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  tr('settings_title'),
                  style: TextStyle(color: subtitleColor, fontSize: 12),
                ),
              ],
            ),
          ),

          // 1. TITKOSÍTÁSI BEÁLLÍTÁSOK (ENCRYPTION)
          _buildSectionHeader(tr('sec_encryption'), Icons.enhanced_encryption_rounded),

          // Enkriptálás utáni mezőtörlés (Toggle, default: TRUE)
          SwitchListTile(
            title: Text(tr('auto_clear_encrypt_title'), style: TextStyle(fontSize: 13.5, color: titleColor)),
            subtitle: Text(tr('auto_clear_encrypt_sub'), style: TextStyle(fontSize: 11, color: subtitleColor)),
            value: _autoClearInputOnEncrypt,
            activeColor: widget.accentColor,
            onChanged: (val) {
              setState(() => _autoClearInputOnEncrypt = val);
              _saveSetting('setting_auto_clear_encrypt', val);
            },
          ),

          SwitchListTile(
            title: Text(tr('strict_title'), style: TextStyle(fontSize: 13.5, color: titleColor)),
            subtitle: Text(tr('strict_sub'), style: TextStyle(fontSize: 11, color: subtitleColor)),
            value: _strictPasswordRequired,
            activeColor: widget.accentColor,
            onChanged: (val) {
              setState(() => _strictPasswordRequired = val);
              _saveSetting('setting_strict', val);
            },
          ),

          Divider(color: isLight ? const Color(0xFFE2E8F0) : const Color(0xFF222B38), height: 24),

          // 2. DEKÓDOLÁS ÉS VÁGÓLAP (DECRYPTION & CLIPBOARD)
          _buildSectionHeader(tr('sec_decryption'), Icons.lock_open_rounded),

          SwitchListTile(
            title: Text(tr('auto_decrypt_wipe_title'), style: TextStyle(fontSize: 13.5, color: titleColor, fontWeight: FontWeight.w600)),
            subtitle: Text(tr('auto_decrypt_wipe_sub'), style: TextStyle(fontSize: 11, color: subtitleColor)),
            value: _instantDecryptAndWipe,
            activeColor: widget.accentColor,
            onChanged: (val) {
              setState(() => _instantDecryptAndWipe = val);
              _saveSetting('setting_instant_decrypt_wipe', val);
            },
          ),

          SwitchListTile(
            title: Text(tr('auto_paste_title'), style: TextStyle(fontSize: 13.5, color: titleColor)),
            subtitle: Text(tr('auto_paste_sub'), style: TextStyle(fontSize: 11, color: subtitleColor)),
            value: _autoPasteOnResume,
            activeColor: widget.accentColor,
            onChanged: (val) {
              setState(() => _autoPasteOnResume = val);
              _saveSetting('setting_auto_paste', val);
            },
          ),

          Divider(color: isLight ? const Color(0xFFE2E8F0) : const Color(0xFF222B38), height: 24),

          // 3. MEGJELENÉS ÉS TÉMÁK (APPEARANCE)
          _buildSectionHeader(tr('sec_appearance'), Icons.palette_outlined),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Wrap(
              spacing: 12,
              children: [
                _colorOption(0xFF0A0E14, 0xFF00E676, 'Cyber Dark'),
                _colorOption(0xFF0A0E14, 0xFF00B0FF, 'Neon Blue'),
                _colorOption(0xFF0A0E14, 0xFFFF5252, 'Red Alert'),
                _colorOption(0xFF0F0F12, 0xFFFFB300, 'Amber Dark'),
                _colorOption(0xFFF5F7FA, 0xFF0D9488, 'Clean White'),
              ],
            ),
          ),

          Divider(color: isLight ? const Color(0xFFE2E8F0) : const Color(0xFF222B38), height: 24),

          // 4. ÁLTALÁNOS ÉS INTERAKCIÓ (GENERAL)
          _buildSectionHeader(tr('sec_general'), Icons.tune_rounded),

          SwitchListTile(
            title: Text(tr('enter_action_title'), style: TextStyle(fontSize: 13.5, color: titleColor)),
            subtitle: Text(tr('enter_action_sub'), style: TextStyle(fontSize: 11, color: subtitleColor)),
            value: _enterTriggersAction,
            activeColor: widget.accentColor,
            onChanged: (val) {
              setState(() => _enterTriggersAction = val);
              _saveSetting('setting_enter_action', val);
            },
          ),

          SwitchListTile(
            title: Text(tr('haptic_title'), style: TextStyle(fontSize: 13.5, color: titleColor)),
            subtitle: Text(tr('haptic_sub'), style: TextStyle(fontSize: 11, color: subtitleColor)),
            value: _hapticFeedbackEnabled,
            activeColor: widget.accentColor,
            onChanged: (val) {
              setState(() => _hapticFeedbackEnabled = val);
              _saveSetting('setting_haptic', val);
            },
          ),

          Divider(color: isLight ? const Color(0xFFE2E8F0) : const Color(0xFF222B38), height: 24),

          // 5. NYELV (22 NYELV)
          _buildSectionHeader(tr('sec_language'), Icons.language_rounded),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: isLight ? const Color(0xFFF1F5F9) : const Color(0xFF141923),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: isLight ? const Color(0xFFCBD5E1) : const Color(0xFF222B38)),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: widget.currentLanguage,
                  isExpanded: true,
                  dropdownColor: isLight ? Colors.white : const Color(0xFF141923),
                  style: TextStyle(color: titleColor, fontSize: 13.5),
                  icon: Icon(Icons.keyboard_arrow_down_rounded, color: widget.accentColor, size: 20),
                  items: languageNames.entries.map((e) {
                    return DropdownMenuItem(
                      value: e.key,
                      child: Text(e.value),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      widget.onLanguageChanged(val);
                    }
                  },
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),
          Divider(color: isLight ? const Color(0xFFE2E8F0) : const Color(0xFF222B38), height: 24),

          ListTile(
            leading: Icon(Icons.code_rounded, color: subtitleColor, size: 20),
            title: Text(tr('project_github'), style: TextStyle(color: titleColor, fontSize: 13)),
            onTap: () async {
              final uri = Uri.parse('https://github.com/kovacsmaxi/clipghost');
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    final isLight = widget.isLight;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
      child: Row(
        children: [
          Icon(icon, size: 14, color: widget.accentColor),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              color: isLight ? const Color(0xFF0F766E) : widget.accentColor,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.9,
            ),
          ),
        ],
      ),
    );
  }

  Widget _colorOption(int bgVal, int accentVal, String tooltip) {
    final isSelected = widget.bgValue == bgVal && widget.accentValue == accentVal;
    final accent = Color(accentVal);
    final bg = Color(bgVal);

    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: () => widget.onThemeChanged(bgVal, accentVal),
        child: Container(
          width: 36,
          height: 36,
          margin: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: bg,
            shape: BoxShape.circle,
            border: Border.all(
              color: isSelected ? (bgVal == 0xFFF5F7FA ? Colors.black : Colors.white) : accent,
              width: isSelected ? 2.5 : 1.5,
            ),
          ),
          child: Center(
            child: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
            ),
          ),
        ),
      ),
    );
  }
}