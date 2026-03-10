import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../models/animal.dart';
import '../models/avistamiento.dart';

class FirestoreService {

  final FirebaseFirestore db = FirebaseFirestore.instanceFor(
    app: Firebase.app(),
    databaseId: 'bd-mascotas',
  );

  /// crear animal
  Future<String> crearAnimal({
    required EspecieAnimal especie,
    required EstadoAnimal estado,
    required String fotoPrincipal,
  }) async {

    final docRef = await db.collection("animales").add({
      "especie": especie.name,
      "estado": estado.name,
      "fotoPrincipal": fotoPrincipal,
      "fechaCreacion": FieldValue.serverTimestamp(),
    });

    return docRef.id;
  }

  /// crear avistamiento
  Future<void> crearAvistamiento({
    required Avistamiento avistamiento,
    required EspecieAnimal especie,
  }) async {

    await db.collection("avistamientos").add({

      "animalId": avistamiento.animalId,

      "lat": avistamiento.lat,
      "lng": avistamiento.lng,

      "foto": avistamiento.foto,

      /// duplicación intencional para mapa
      "especie": especie.name,

      "etiquetas": avistamiento.etiquetas
          .map((e) => e.name)
          .toList(),

      "fecha": Timestamp.fromDate(avistamiento.fecha),

    });

  }

  /// obtener avistamientos cercanos
  Future<List<Map<String, dynamic>>> obtenerAvistamientosCercanos({
    required double lat,
    required double lng,
    double rango = 0.05,
  }) async {

    debugPrint("Buscando avistamientos cerca de: $lat, $lng");
    debugPrint("Rango usado: $rango");

    final query = await db
        .collection("avistamientos")
        .where("lat", isGreaterThanOrEqualTo: lat - rango)
        .where("lat", isLessThanOrEqualTo: lat + rango)
        .get();

    debugPrint("Documentos traídos por latitud: ${query.docs.length}");

    final List<Map<String, dynamic>> resultado = [];

    for (final doc in query.docs) {

      final data = doc.data();

      final double latDoc = (data["lat"] as num).toDouble();
      final double lngDoc = (data["lng"] as num).toDouble();

      if (lngDoc >= lng - rango && lngDoc <= lng + rango) {

        resultado.add({

          "id": doc.id,

          "animalId": data["animalId"] ?? "",

          "lat": latDoc,
          "lng": lngDoc,

          "foto": data["foto"] ?? "",

          "especie": data["especie"] ?? "",

          "etiquetas": _parseEtiquetas(data["etiquetas"]),

          "fecha": data["fecha"] != null
              ? (data["fecha"] as Timestamp).toDate()
              : DateTime.now(),

        });

      }

    }

    debugPrint("Avistamientos filtrados finales: ${resultado.length}");

    return resultado;

  }

  List<EtiquetaAvistamiento> _parseEtiquetas(dynamic value) {

    if (value == null) return [];

    final List lista = value as List;

    return lista
        .map((item) {

          final texto = item.toString();

          try {

            return EtiquetaAvistamiento.values.firstWhere(
              (e) => e.name == texto,
            );

          } catch (_) {

            return null;

          }

        })
        .whereType<EtiquetaAvistamiento>()
        .toList();

  }

}