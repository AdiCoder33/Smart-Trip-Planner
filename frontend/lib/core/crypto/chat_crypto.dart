import 'dart:convert';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

class ChatCrypto {
  final AesGcm _cipher;

  ChatCrypto({AesGcm? cipher}) : _cipher = cipher ?? AesGcm.with256bits();

  Future<String> encrypt(String plaintext, String base64Key) async {
    final secretKey = SecretKey(_decodeKey(base64Key));
    final nonce = _cipher.newNonce();
    final secretBox = await _cipher.encrypt(
      utf8.encode(plaintext),
      secretKey: secretKey,
      nonce: nonce,
    );
    final combined = Uint8List.fromList(
      nonce + secretBox.cipherText + secretBox.mac.bytes,
    );
    return base64UrlEncode(combined);
  }

  Future<String> decrypt(String base64Payload, String base64Key) async {
    final payload = base64Url.decode(base64Url.normalize(base64Payload));
    if (payload.length < 12 + 16) {
      throw const FormatException('Invalid payload length');
    }
    final nonce = payload.sublist(0, 12);
    final macBytes = payload.sublist(payload.length - 16);
    final cipherText = payload.sublist(12, payload.length - 16);
    final secretKey = SecretKey(_decodeKey(base64Key));
    final secretBox = SecretBox(
      cipherText,
      nonce: nonce,
      mac: Mac(macBytes),
    );
    final clearText = await _cipher.decrypt(secretBox, secretKey: secretKey);
    return utf8.decode(clearText);
  }

  Uint8List _decodeKey(String base64Key) {
    return base64Url.decode(base64Url.normalize(base64Key));
  }
}
