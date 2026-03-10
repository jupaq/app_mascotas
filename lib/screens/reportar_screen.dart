import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/animal.dart';
import '../models/avistamiento.dart';
import '../services/firestore_service.dart';
import '../services/storage_service.dart';

class ReportarScreen extends StatefulWidget {
  final double lat;
  final double lng;

  const ReportarScreen({
    super.key,
    required this.lat,
    required this.lng,
  });

  @override
  State<ReportarScreen> createState() => _ReportarScreenState();
}

class _ReportarScreenState extends State<ReportarScreen> {
  final FirestoreService firestoreService = FirestoreService();
  final StorageService storageService = StorageService();
  final ImagePicker imagePicker = ImagePicker();

  EspecieAnimal? especieSeleccionada;
  EstadoAnimal? estadoSeleccionado;
  List<EtiquetaAvistamiento> etiquetasSeleccionadas = [];

  String? fotoPath;
  bool guardando = false;

  Future<void> tomarFoto() async {
    final XFile? imagen = await imagePicker.pickImage(
      source: ImageSource.camera,
      imageQuality: 70,
    );

    if (imagen == null) return;

    setState(() {
      fotoPath = imagen.path;
    });
  }

  void toggleEtiqueta(EtiquetaAvistamiento etiqueta) {
    setState(() {
      if (etiquetasSeleccionadas.contains(etiqueta)) {
        etiquetasSeleccionadas.remove(etiqueta);
      } else {
        etiquetasSeleccionadas.add(etiqueta);
      }
    });
  }

  String textoEstado(EstadoAnimal estado) {
    switch (estado) {
      case EstadoAnimal.callejero:
        return "Callejero";
      case EstadoAnimal.conDueno:
        return "Con dueño";
      case EstadoAnimal.abandonado:
        return "Abandonado";
      case EstadoAnimal.enAdopcion:
        return "En adopción";
      case EstadoAnimal.adoptado:
        return "Adoptado";
    }
  }

  String textoEtiqueta(EtiquetaAvistamiento etiqueta) {
    switch (etiqueta) {
      case EtiquetaAvistamiento.normal:
        return "Normal";
      case EtiquetaAvistamiento.suelto:
        return "Suelto";
      case EtiquetaAvistamiento.posibleExtraviado:
        return "Posible extraviado";
      case EtiquetaAvistamiento.herido:
        return "Herido";
      case EtiquetaAvistamiento.malEstado:
        return "Mal estado";
      case EtiquetaAvistamiento.hambriento:
        return "Hambriento";
    }
  }

  String textoEspecie(EspecieAnimal especie) {
    switch (especie) {
      case EspecieAnimal.perro:
        return "Perro";
      case EspecieAnimal.gato:
        return "Gato";
      default:
        return "Otro";
    }
  }

  Future<void> guardarReporte() async {
    if (guardando) return;

    if (especieSeleccionada == null) {
      mostrarMensaje("Debes seleccionar la especie");
      return;
    }

    if (estadoSeleccionado == null) {
      mostrarMensaje("Debes seleccionar el estado del animal");
      return;
    }

    if (fotoPath == null) {
      mostrarMensaje("Debes tomar una foto");
      return;
    }

    if (etiquetasSeleccionadas.isEmpty) {
      mostrarMensaje("Debes seleccionar al menos una etiqueta");
      return;
    }

    setState(() {
      guardando = true;
    });

    try {
      debugPrint("PASO 1: subir imagen");
      final String urlFoto = await storageService.subirImagen(fotoPath!);
      debugPrint("OK PASO 1: $urlFoto");

      debugPrint("PASO 2: crear animal");
      final String animalId = await firestoreService.crearAnimal(
        especie: especieSeleccionada!,
        estado: estadoSeleccionado!,
        fotoPrincipal: urlFoto,
      );
      debugPrint("OK PASO 2: $animalId");

      debugPrint("PASO 3: crear avistamiento");
      final Avistamiento avistamiento = Avistamiento(
        id: "",
        animalId: animalId,
        lat: widget.lat,
        lng: widget.lng,
        foto: urlFoto,
        etiquetas: etiquetasSeleccionadas,
        fecha: DateTime.now(),
      );

      await firestoreService.crearAvistamiento(
        avistamiento: avistamiento,
        especie: especieSeleccionada!,
      );

      debugPrint("OK PASO 3");

      if (!mounted) return;

      mostrarMensaje("Reporte guardado correctamente");
      Navigator.pop(context);
    } catch (e, stackTrace) {
      debugPrint("ERROR AL GUARDAR: $e");
      debugPrint("STACKTRACE: $stackTrace");
      mostrarMensaje("Error al guardar: $e");
    } finally {
      if (mounted) {
        setState(() {
          guardando = false;
        });
      }
    }
  }

  void mostrarMensaje(String texto) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(texto)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Reportar animal"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Foto",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),

            if (fotoPath != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  File(fotoPath!),
                  height: 220,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              )
            else
              Container(
                height: 180,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade400),
                ),
                child: const Center(
                  child: Text("Aún no has tomado foto"),
                ),
              ),

            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: tomarFoto,
                child: const Text("Tomar foto"),
              ),
            ),

            const SizedBox(height: 24),

            const Text(
              "Especie",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),

            DropdownButtonFormField<EspecieAnimal>(
              value: especieSeleccionada,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: "Selecciona especie",
              ),
              items: EspecieAnimal.values.map((especie) {
                return DropdownMenuItem(
                  value: especie,
                  child: Text(textoEspecie(especie)),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  especieSeleccionada = value;
                });
              },
            ),

            const SizedBox(height: 24),

            const Text(
              "Estado del animal",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),

            DropdownButtonFormField<EstadoAnimal>(
              value: estadoSeleccionado,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: "Selecciona estado",
              ),
              items: EstadoAnimal.values.map((estado) {
                return DropdownMenuItem(
                  value: estado,
                  child: Text(textoEstado(estado)),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  estadoSeleccionado = value;
                });
              },
            ),

            const SizedBox(height: 24),

            const Text(
              "Etiquetas del avistamiento",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),

            ...EtiquetaAvistamiento.values.map((etiqueta) {
              return CheckboxListTile(
                value: etiquetasSeleccionadas.contains(etiqueta),
                title: Text(textoEtiqueta(etiqueta)),
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                onChanged: (_) {
                  toggleEtiqueta(etiqueta);
                },
              );
            }),

            const SizedBox(height: 16),

            Text(
              "Ubicación: ${widget.lat}, ${widget.lng}",
              style: const TextStyle(fontSize: 16),
            ),

            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: guardando ? null : guardarReporte,
                child: Text(
                  guardando ? "Guardando..." : "REPORTAR",
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
