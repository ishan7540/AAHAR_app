import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

class SecondTile extends StatelessWidget {
  const SecondTile({super.key});

  // Function to open Google Maps with the given coordinates
  void _launchMaps(double lat, double lon) async {
    final Uri googleMapsUrl =
        Uri.parse("https://www.google.com/maps?q=$lat,$lon");

    if (!await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication)) {
      throw "Could not open the map.";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 12, right: 12, top: 16),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(),
          borderRadius: BorderRadius.circular(12),
          color: const Color.fromARGB(255, 255, 255, 255),
        ),
        height: 390,
        width: 360,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "  Your Field ➔ ",
              style: TextStyle(
                fontFamily: 'Coolvetica',
                fontSize: 28,
                color: Colors.black,
              ),
            ),
            Row(
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 12, bottom: 6),
                  child: GestureDetector(
                    onTap: () {
                      print("Long press detected!");
                      _launchMaps(30.21813, 76.40958);
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(width: 3),
                        borderRadius: BorderRadius.circular(12),
                        color: const Color.fromARGB(255, 255, 255, 255),
                        boxShadow: const [
                          BoxShadow(
                            blurRadius: 4,
                            color: Colors.grey,
                            offset: Offset(0.0, 2.0),
                          ),
                        ],
                      ),
                      height: 175,
                      width: 200,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: GestureDetector(
                          onLongPress: () {
                            _launchMaps(30.21813, 76.40958);
                          },
                          child: FlutterMap(
                            options: const MapOptions(
                              initialCenter: LatLng(30.21813, 76.40958),
                              initialZoom: 13.0,
                            ),
                            children: [
                              TileLayer(
                                urlTemplate:
                                    "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                                subdomains: const ['a', 'b', 'c'],
                              ),
                              const MarkerLayer(
                                markers: [
                                  Marker(
                                    point: LatLng(30.21813, 76.40958),
                                    child: Icon(
                                      Icons.location_on,
                                      color: Colors.red,
                                      size: 40,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(
                        right: 12,
                        top: 6,
                        left: 7,
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(width: 3),
                          borderRadius: BorderRadius.circular(12),
                          color: const Color.fromARGB(255, 255, 255, 255),
                          boxShadow: const [
                            BoxShadow(
                              blurRadius: 4,
                              color: Colors.grey,
                              offset: Offset(0.0, 2.0),
                            ),
                          ],
                        ),
                        height: 85,
                        width: 127,
                        child: Column(children: [
                          Row(
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(3),
                                child: Image.asset(
                                  'lib/assets/images/Virus@3x.png',
                                  height: 50,
                                  width: 50,
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(left: 8.0),
                                child: Image.asset(
                                  'lib/assets/images/Right Arrow@3x.png',
                                  height: 50,
                                  width: 50,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            'Disease Detection',
                            style: TextStyle(
                                fontSize: 13,
                                color: Colors.black,
                                fontFamily: 'Coolvetica'),
                          )
                        ]),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(
                        right: 12,
                        top: 6,
                        left: 7,
                        bottom: 12,
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(width: 3),
                          borderRadius: BorderRadius.circular(12),
                          color: const Color.fromARGB(255, 255, 255, 255),
                          boxShadow: const [
                            BoxShadow(
                              blurRadius: 4,
                              color: Colors.grey,
                              offset: Offset(0.0, 2.0),
                            ),
                          ],
                        ),
                        height: 85,
                        width: 127,
                        child: Column(children: [
                          Row(
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(3.0),
                                child: Image.asset(
                                  'lib/assets/images/Barley.png',
                                  height: 50,
                                  width: 50,
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(left: 8.0),
                                child: Image.asset(
                                  'lib/assets/images/Right Arrow@3x.png',
                                  height: 50,
                                  width: 50,
                                ),
                              ),
                            ],
                          ),
                          const Text(
                            'Crop Rotation',
                            style: TextStyle(
                                fontSize: 13,
                                color: Colors.black,
                                fontFamily: 'Coolvetica'),
                          )
                        ]),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(left: 7, right: 7),
              child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: const Color.fromARGB(255, 255, 255, 255),
                    boxShadow: const [
                      BoxShadow(
                        blurRadius: 4,
                        color: Colors.grey,
                        offset: Offset(0.0, 2.0),
                      ),
                    ],
                  ),
                  height: 140,
                  width: 355,
                  child: Image.asset(
                    'lib/assets/images/Group 116.png',
                    fit: BoxFit.fill,
                  )),
            ),
          ],
        ),
      ),
    );
  }
}
