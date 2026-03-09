import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

import '../models/avistamiento.dart';
import '../services/firestore_service.dart';
import 'reportar_screen.dart';

class MapaScreen extends StatefulWidget {
  const MapaScreen({super.key});

  @override
  State<MapaScreen> createState() => _MapaScreenState();
}

class _MapaScreenState extends State<MapaScreen> {
  /// controlador del mapa
  GoogleMapController? mapController;

  /// servicio de firestore
  final FirestoreService firestoreService = FirestoreService();

  /// marcadores visibles en el mapa
  Set<Marker> markers = {};

  /// posición seleccionada para nuevo reporte
  LatLng? posicionSeleccionada;

  /// ubicación actual del usuario
  LatLng? ubicacionActual;

  /// fallback inicial
  final LatLng ubicacionInicial = const LatLng(-39.8142, -73.2459);

  /// estado de carga
  bool cargando = true;

  @override
  void initState() {
    super.initState();
    iniciarMapa();
  }

  Future<void> iniciarMapa() async {
    try {
      await obtenerUbicacion();
      await cargarAvistamientosCercanos();
    } catch (e) {
      debugPrint("Error al iniciar mapa: $e");
    } finally {
      if (mounted) {
        setState(() {
          cargando = false;
        });
      }
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
      "Ubicación actual obtenida: ${nuevaUbicacion.latitude}, ${nuevaUbicacion.longitude}",
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

  Future<void> cargarAvistamientosCercanos() async {
    final LatLng centro = ubicacionActual ?? ubicacionInicial;

    debugPrint(
      "Centro de búsqueda: ${centro.latitude}, ${centro.longitude}",
    );

    final List<Avistamiento> avistamientos =
        await firestoreService.obtenerAvistamientosCercanos(
      lat: centro.latitude,
      lng: centro.longitude,
    );

    debugPrint(
      "Cantidad de avistamientos encontrados: ${avistamientos.length}",
    );

    final Set<Marker> nuevosMarkers = avistamientos.map((av) {
      debugPrint("Creando marker para ${av.id} en ${av.lat}, ${av.lng}");

      return Marker(
        markerId: MarkerId(av.id),
        position: LatLng(av.lat, av.lng),
        icon: BitmapDescriptor.defaultMarkerWithHue(
          BitmapDescriptor.hueRed,
        ),
        infoWindow: InfoWindow(
          title: "Avistamiento",
          snippet: av.etiquetas.isNotEmpty
              ? av.etiquetas.map((e) => e.name).join(", ")
              : "Sin etiquetas",
        ),
      );
    }).toSet();

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

    debugPrint("Cantidad total de markers dibujados: ${markers.length}");

    /// para probar visualmente:
    /// si hay al menos un avistamiento, centra el mapa en el primero
    if (avistamientos.isNotEmpty && mapController != null) {
      final primerPunto = LatLng(avistamientos.first.lat, avistamientos.first.lng);

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
    } catch (e) {
      debugPrint("Error al recentrar mapa: $e");
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
