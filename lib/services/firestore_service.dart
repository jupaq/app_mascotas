import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
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
}
