enum EtiquetaAvistamiento {
  normal,
  suelto,
  posibleExtraviado,
  herido,
  malEstado,
  hambriento,
  abandonado
}

class Avistamiento {
  String id;
  String animalId;
  double lat;
  double lng;
  String foto;
  EtiquetaAvistamiento etiqueta;
  DateTime fecha;

  Avistamiento({
    required this.id,
    required this.animalId,
    required this.lat,
    required this.lng,
    required this.foto,
    required this.etiqueta,
    required this.fecha,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'animalId': animalId,
      'lat': lat,
      'lng': lng,
      'foto': foto,
      'etiqueta': etiqueta.name,
      'fecha': fecha.toIso8601String(),
    };
  }

  factory Avistamiento.fromMap(Map<String, dynamic> map) {
    return Avistamiento(
      id: map['id'],
      animalId: map['animalId'],
      lat: map['lat'],
      lng: map['lng'],
      foto: map['foto'],
      etiqueta: EtiquetaAvistamiento.values.byName(map['etiqueta']),
      fecha: DateTime.parse(map['fecha']),
    );
  }
}
