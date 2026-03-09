import 'package:geolocator/geolocator.dart';

class UbicacionService {

  Future<Position> obtenerUbicacion() async {

    bool servicioActivo;
    LocationPermission permiso;

    servicioActivo = await Geolocator.isLocationServiceEnabled();

    if (!servicioActivo) {
      throw Exception("GPS desactivado");
    }

    permiso = await Geolocator.checkPermission();

    if (permiso == LocationPermission.denied) {
      permiso = await Geolocator.requestPermission();
    }

    if (permiso == LocationPermission.deniedForever) {
      throw Exception("Permisos de ubicación denegados");
    }

    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high
    );

  }

}
