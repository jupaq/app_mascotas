import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import '../models/animal.dart';
import '../models/avistamiento.dart';

class FirestoreService {
  final FirebaseFirestore db = FirebaseFirestore.instanceFor(
    app: Firebase.app(),
    databaseId: 'bd-mascotas',
  );

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

  Future<void> crearAvistamiento(Avistamiento avistamiento) async {
    await db.collection("avistamientos").add({
      "animalId": avistamiento.animalId,
      "lat": avistamiento.lat,
      "lng": avistamiento.lng,
      "foto": avistamiento.foto,
      "etiquetas": avistamiento.etiquetas.map((e) => e.name).toList(),
      "fecha": Timestamp.fromDate(avistamiento.fecha),
    });
  }

  Future<List<Avistamiento>> obtenerAvistamientosCercanos({
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

    final List<Avistamiento> resultado = [];

    for (final doc in query.docs) {
      final data = doc.data();

      final double latDoc = (data["lat"] as num).toDouble();
      final double lngDoc = (data["lng"] as num).toDouble();

      debugPrint("Documento ${doc.id}: lat=$latDoc ; lng=$lngDoc");

      if (lngDoc >= lng - rango && lngDoc <= lng + rango) {
        resultado.add(
          Avistamiento(
            id: doc.id,
            animalId: data["animalId"] ?? "",
            lat: latDoc,
            lng: lngDoc,
            foto: data["foto"] ?? "",
            etiquetas: _parseEtiquetas(data["etiquetas"]),
            fecha: data["fecha"] != null
                ? (data["fecha"] as Timestamp).toDate()
                : DateTime.now(),
          ),
        );
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
