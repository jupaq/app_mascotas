enum EtiquetaAvistamiento {
  normal,
  suelto,
  posibleExtraviado,
  herido,
  malEstado,
  hambriento,
}

class Avistamiento {
  String id;
  String animalId;
  double lat;
  double lng;
  String foto;
  List<EtiquetaAvistamiento> etiquetas;
  DateTime fecha;

  Avistamiento({
    required this.id,
    required this.animalId,
    required this.lat,
    required this.lng,
    required this.foto,
    required this.etiquetas,
    required this.fecha,
  });
}
