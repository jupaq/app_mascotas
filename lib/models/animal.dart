enum EspecieAnimal {
  perro,
  gato,
  otro
}

enum EstadoAnimal {
  callejero,
  conDueno,
  abandonado,
  enAdopcion,
  adoptado
}

class Animal {
  String id;
  EspecieAnimal especie;
  EstadoAnimal estado;
  String fotoPrincipal;

  Animal({
    required this.id,
    required this.especie,
    required this.estado,
    required this.fotoPrincipal,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'especie': especie.name,
      'estado': estado.name,
      'fotoPrincipal': fotoPrincipal,
    };
  }

  factory Animal.fromMap(Map<String, dynamic> map) {
    return Animal(
      id: map['id'],
      especie: EspecieAnimal.values.byName(map['especie']),
      estado: EstadoAnimal.values.byName(map['estado']),
      fotoPrincipal: map['fotoPrincipal'],
    );
  }
}
