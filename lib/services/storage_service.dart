import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

class StorageService {
  final FirebaseStorage storage = FirebaseStorage.instance;

  Future<String> subirImagen(String pathImagen) async {
    try {
      final File archivo = File(pathImagen);

      if (!await archivo.exists()) {
        throw Exception("El archivo no existe: $pathImagen");
      }

      final String nombreArchivo =
          DateTime.now().millisecondsSinceEpoch.toString();

      final Reference ref =
          storage.ref().child("avistamientos/$nombreArchivo.jpg");

      final UploadTask uploadTask = ref.putFile(
        archivo,
        SettableMetadata(contentType: "image/jpeg"),
      );

      final TaskSnapshot snapshot = await uploadTask;
      final String url = await snapshot.ref.getDownloadURL();

      return url;
    } on FirebaseException catch (e) {
      debugPrint("FIREBASE STORAGE ERROR: ${e.code} - ${e.message}");
      throw Exception("Storage ${e.code}: ${e.message}");
    } catch (e) {
      debugPrint("ERROR GENERAL STORAGE: $e");
      rethrow;
    }
  }
}
