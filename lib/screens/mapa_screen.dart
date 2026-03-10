import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

import '../services/firestore_service.dart';
import 'reportar_screen.dart';

class MapaScreen extends StatefulWidget {
  const MapaScreen({super.key});

  @override
  State<MapaScreen> createState() => _MapaScreenState();
}

class _MapaScreenState extends State<MapaScreen> {
  GoogleMapController? mapController;
  final FirestoreService firestoreService = FirestoreService();

  Set<Marker> markers = {};

  LatLng? posicionSeleccionada;
  LatLng? ubicacionActual;

  final LatLng ubicacionInicial = const LatLng(-39.8142, -73.2459);

  bool cargando = true;

  BitmapDescriptor? iconoPerro;
  BitmapDescriptor? iconoGato;

  /// FLAGS DEBUG
  bool debugIconosCargados = false;
  bool debugUsoPinPerro = false;
  bool debugUsoPinGato = false;
  bool debugUsoPinDefault = false;

  @override
  void initState() {
    super.initState();
    iniciarMapa();
  }

  Future<void> iniciarMapa() async {
    try {
      debugPrint("=== INICIO MAPA ===");

      await cargarIconos();
      await obtenerUbicacion();
      await cargarAvistamientosCercanos();

      debugPrint("=== FIN INICIO MAPA ===");
    } catch (e, st) {
      debugPrint("ERROR al iniciar mapa: $e");
      debugPrint("$st");
    } finally {
      if (mounted) {
        setState(() {
          cargando = false;
        });
      }
    }
  }

  Future<void> cargarIconos() async {
    try {
      debugPrint("=== CARGA ICONOS ===");
      debugPrint("Intentando cargar assets:");
      debugPrint("assets/images/pin_perro.png");
      debugPrint("assets/images/pin_gato.png");

      iconoPerro = await BitmapDescriptor.asset(
        const ImageConfiguration(size: Size(64, 64)),
        "assets/images/pin_perro.png",
      );
      debugPrint("OK iconoPerro cargado");

      iconoGato = await BitmapDescriptor.asset(
        const ImageConfiguration(size: Size(64, 64)),
        "assets/images/pin_gato.png",
      );
      debugPrint("OK iconoGato cargado");

      debugIconosCargados = true;
      debugPrint("FLAG debugIconosCargados = true");
    } catch (e, st) {
      debugIconosCargados = false;
      debugPrint("ERROR cargando iconos: $e");
      debugPrint("$st");
    }
  }

  Future<void> obtenerUbicacion() async {
    final bool servicioHabilitado =
        await Geolocator.isLocationServiceEnabled();

    if (!servicioHabilitado) {
      throw Exception("El servicio de ubicación está deshabilitado");
    }

    LocationPermission permiso = await Geolocator.checkPermission();

    if (permiso == LocationPermission.denied) {
      permiso = await Geolocator.requestPermission();
    }

    if (permiso == LocationPermission.denied) {
      throw Exception("Permiso de ubicación denegado");
    }

    if (permiso == LocationPermission.deniedForever) {
      throw Exception("Permiso de ubicación denegado permanentemente");
    }

    final Position posicion = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    final LatLng nuevaUbicacion = LatLng(
      posicion.latitude,
      posicion.longitude,
    );

    debugPrint(
      "Ubicación actual: ${nuevaUbicacion.latitude}, ${nuevaUbicacion.longitude}",
    );

    if (mounted) {
      setState(() {
        ubicacionActual = nuevaUbicacion;
      });
    }

    if (mapController != null) {
      await mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(nuevaUbicacion, 16),
      );
    }
  }

  String textoEtiquetaMapa(dynamic etiqueta) {
    if (etiqueta is String) {
      switch (etiqueta) {
        case "normal":
          return "Normal";
        case "suelto":
          return "Suelto";
        case "posibleExtraviado":
          return "Posible extraviado";
        case "herido":
          return "Herido";
        case "malEstado":
          return "Mal estado";
        case "hambriento":
          return "Hambriento";
        default:
          return etiqueta;
      }
    }

    final texto = etiqueta.toString();

    if (texto.contains("normal")) return "Normal";
    if (texto.contains("suelto")) return "Suelto";
    if (texto.contains("posibleExtraviado")) return "Posible extraviado";
    if (texto.contains("herido")) return "Herido";
    if (texto.contains("malEstado")) return "Mal estado";
    if (texto.contains("hambriento")) return "Hambriento";

    return texto;
  }

  Future<void> cargarAvistamientosCercanos() async {
    final LatLng centro = ubicacionActual ?? ubicacionInicial;

    debugPrint("=== CARGA AVISTAMIENTOS ===");
    debugPrint("Centro búsqueda: ${centro.latitude}, ${centro.longitude}");
    debugPrint("debugIconosCargados: $debugIconosCargados");
    debugPrint("iconoPerro null?: ${iconoPerro == null}");
    debugPrint("iconoGato null?: ${iconoGato == null}");

    final datos = await firestoreService.obtenerAvistamientosCercanos(
      lat: centro.latitude,
      lng: centro.longitude,
    );

    debugPrint("Cantidad de avistamientos encontrados: ${datos.length}");

    final Set<Marker> nuevosMarkers = {};

    for (final av in datos) {
      final double lat = av["lat"];
      final double lng = av["lng"];
      final String id = av["id"];
      final String especie = (av["especie"] ?? "").toString();
      final List etiquetas = (av["etiquetas"] ?? []) as List;

      debugPrint("----------------------------------");
      debugPrint("Procesando avistamiento id=$id");
      debugPrint("lat=$lat ; lng=$lng");
      debugPrint("especie='$especie'");
      debugPrint("etiquetas=$etiquetas");

      BitmapDescriptor icono = BitmapDescriptor.defaultMarker;
      String tipoIconoUsado = "default";

      if (especie == "perro") {
        debugPrint("Es perro, intentará usar iconoPerro");
        if (iconoPerro != null) {
          icono = iconoPerro!;
          tipoIconoUsado = "perro";
          debugUsoPinPerro = true;
        } else {
          debugPrint("iconoPerro es null, cae a default");
        }
      }

      if (especie == "gato") {
        debugPrint("Es gato, intentará usar iconoGato");
        if (iconoGato != null) {
          icono = iconoGato!;
          tipoIconoUsado = "gato";
          debugUsoPinGato = true;
        } else {
          debugPrint("iconoGato es null, cae a default");
        }
      }

      if (tipoIconoUsado == "default") {
        debugUsoPinDefault = true;
      }

      debugPrint("Icono final usado: $tipoIconoUsado");

      nuevosMarkers.add(
        Marker(
          markerId: MarkerId(id),
          position: LatLng(lat, lng),
          icon: icono,
          infoWindow: InfoWindow(
            title: especie.isNotEmpty
                ? "Avistamiento de ${especie[0].toUpperCase()}${especie.substring(1)}"
                : "Avistamiento",
            snippet: etiquetas.isNotEmpty
                ? etiquetas.map((e) => textoEtiquetaMapa(e)).join(", ")
                : "Sin etiquetas",
          ),
        ),
      );
    }

    if (posicionSeleccionada != null) {
      nuevosMarkers.add(
        Marker(
          markerId: const MarkerId("nuevo_avistamiento"),
          position: posicionSeleccionada!,
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueAzure,
          ),
          infoWindow: const InfoWindow(
            title: "Nuevo reporte",
          ),
        ),
      );
    }

    if (mounted) {
      setState(() {
        markers = nuevosMarkers;
      });
    }

    debugPrint("=== RESUMEN FLAGS ===");
    debugPrint("debugIconosCargados: $debugIconosCargados");
    debugPrint("debugUsoPinPerro: $debugUsoPinPerro");
    debugPrint("debugUsoPinGato: $debugUsoPinGato");
    debugPrint("debugUsoPinDefault: $debugUsoPinDefault");
    debugPrint("Cantidad total markers: ${markers.length}");

    if (datos.isNotEmpty && mapController != null) {
      final primerPunto = LatLng(
        datos.first["lat"],
        datos.first["lng"],
      );

      await mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(primerPunto, 18),
      );

      debugPrint(
        "Cámara movida al primer avistamiento: ${primerPunto.latitude}, ${primerPunto.longitude}",
      );
    }
  }

  void tocarMapa(LatLng posicion) {
    setState(() {
      posicionSeleccionada = posicion;

      markers.removeWhere(
        (marker) => marker.markerId.value == "nuevo_avistamiento",
      );

      markers.add(
        Marker(
          markerId: const MarkerId("nuevo_avistamiento"),
          position: posicion,
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueAzure,
          ),
          infoWindow: const InfoWindow(
            title: "Nuevo reporte",
          ),
        ),
      );
    });
  }

  Future<void> abrirReportar() async {
    if (posicionSeleccionada == null) return;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReportarScreen(
          lat: posicionSeleccionada!.latitude,
          lng: posicionSeleccionada!.longitude,
        ),
      ),
    );

    if (mounted) {
      setState(() {
        posicionSeleccionada = null;
      });
    }

    await cargarAvistamientosCercanos();
  }

  Future<void> recentrarMapa() async {
    try {
      await obtenerUbicacion();
      await cargarAvistamientosCercanos();
    } catch (e, st) {
      debugPrint("Error al recentrar mapa: $e");
      debugPrint("$st");
    }
  }

  @override
  Widget build(BuildContext context) {
    if (cargando) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Mapa de animales"),
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: ubicacionActual ?? ubicacionInicial,
              zoom: 14,
            ),
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            markers: markers,
            onTap: tocarMapa,
            onMapCreated: (controller) async {
              mapController = controller;

              if (ubicacionActual != null) {
                await controller.animateCamera(
                  CameraUpdate.newLatLngZoom(ubicacionActual!, 16),
                );
              }
            },
          ),
          if (posicionSeleccionada != null)
            Positioned(
              bottom: 30,
              left: 20,
              right: 20,
              child: ElevatedButton(
                onPressed: abrirReportar,
                child: const Text("Reportar animal aquí"),
              ),
            ),
          Positioned(
            top: 16,
            right: 16,
            child: FloatingActionButton(
              mini: true,
              onPressed: recentrarMapa,
              child: const Icon(Icons.my_location),
            ),
          ),
        ],
      ),
    );
  }
}