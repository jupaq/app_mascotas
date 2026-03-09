import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

import 'reportar_screen.dart';

class MapaScreen extends StatefulWidget {
  const MapaScreen({super.key});

  @override
  State<MapaScreen> createState() => _MapaScreenState();
}

class _MapaScreenState extends State<MapaScreen> {

  /// controlador del mapa
  /// permite mover la cámara o hacer zoom programáticamente
  GoogleMapController? mapController;

  /// set de marcadores que se dibujan en el mapa
  Set<Marker> markers = {};

  /// posición que el usuario selecciona al tocar el mapa
  LatLng? posicionSeleccionada;

  /// ubicación actual del usuario obtenida por GPS
  LatLng? ubicacionActual;

  /// ubicación inicial (fallback) si aún no se obtiene GPS
  final LatLng ubicacionInicial = const LatLng(-39.8142, -73.2459);

  @override
  void initState() {
    super.initState();

    /// cuando se abre la pantalla
    /// intentamos obtener la ubicación del usuario
    obtenerUbicacion();
  }

  /// obtiene la ubicación actual usando GPS
  Future obtenerUbicacion() async {

    /// solicitar permiso de ubicación
    LocationPermission permiso = await Geolocator.requestPermission();

    /// obtener posición actual
    Position posicion = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    LatLng nuevaUbicacion = LatLng(
      posicion.latitude,
      posicion.longitude,
    );

    setState(() {
      ubicacionActual = nuevaUbicacion;
    });

    /// mover la cámara del mapa hacia la ubicación actual
    if (mapController != null) {

      mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(nuevaUbicacion, 16),
      );

    }

  }

  /// se ejecuta cuando el usuario toca el mapa
  void tocarMapa(LatLng posicion) {

    setState(() {

      /// guardamos la posición tocada
      posicionSeleccionada = posicion;

      /// eliminamos marcadores anteriores
      markers.clear();

      /// agregamos marcador temporal
      markers.add(
        Marker(
          markerId: const MarkerId("nuevo_avistamiento"),
          position: posicion,
        ),
      );

    });

  }

  /// abre la pantalla para reportar el avistamiento
  void abrirReportar() {

    if (posicionSeleccionada == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReportarScreen(
          lat: posicionSeleccionada!.latitude,
          lng: posicionSeleccionada!.longitude,
        ),
      ),
    );

  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: const Text("Mapa de animales"),
      ),

      /// usamos stack para poder poner elementos sobre el mapa
      body: Stack(
        children: [

          /// mapa principal
          GoogleMap(

            /// posición inicial del mapa
            initialCameraPosition: CameraPosition(
              target: ubicacionActual ?? ubicacionInicial,
              zoom: 14,
            ),

            /// habilita el punto azul del usuario
            myLocationEnabled: true,

            /// botón que centra en tu ubicación
            myLocationButtonEnabled: true,

            /// marcadores que se dibujan en el mapa
            markers: markers,

            /// evento cuando el usuario toca el mapa
            onTap: tocarMapa,

            /// cuando el mapa se crea guardamos el controlador
            onMapCreated: (controller) {
              mapController = controller;
            },

          ),

          /// botón para confirmar el lugar del reporte
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

        ],
      ),
    );

  }

}