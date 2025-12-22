import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class LocationMap extends StatefulWidget {
  final GeoPoint location;
  final String hotelName;

  const LocationMap({
    Key? key,
    required this.location,
    required this.hotelName,
  }) : super(key: key);

  @override
  _LocationMapState createState() => _LocationMapState();
}

class _LocationMapState extends State<LocationMap> {
  late GoogleMapController _mapController;
  late LatLng _center;
  final Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _center = LatLng(widget.location.latitude, widget.location.longitude);
    _markers.add(
      Marker(
        markerId: MarkerId(widget.hotelName),
        position: _center,
        infoWindow: InfoWindow(
          title: widget.hotelName,
        ),
      ),
    );
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 250,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: GoogleMap(
          onMapCreated: _onMapCreated,
          initialCameraPosition: CameraPosition(
            target: _center,
            zoom: 14.0,
          ),
          markers: _markers,
          scrollGesturesEnabled: false,
          zoomGesturesEnabled: false,
        ),
      ),
    );
  }
}
