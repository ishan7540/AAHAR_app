import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:rain/app/modules/home.dart';

// Replace with your actual API key
const String openWeatherAPIKey = 'e2145fe464ca609566f440966b5caa4c';

class FirstTile extends StatefulWidget {
  const FirstTile({super.key});

  @override
  State<FirstTile> createState() => _FirsTileState();
}

class _FirsTileState extends State<FirstTile> {
  late Future<List<Map<String, dynamic>>> weatherAndAqi;

  Future<Map<String, dynamic>> getCurrentWeather() async {
    try {
      final res = await http.get(
        Uri.parse(
          'https://api.openweathermap.org/data/2.5/weather?lat=30.3398&lon=76.3869&appid=$openWeatherAPIKey&units=metric',
        ),
      );

      final data = jsonDecode(res.body);

      if (data['cod'] != 200) {
        throw 'An unexpected error occurred';
      }

      return data;
    } catch (e) {
      throw e.toString();
    }
  }

  Future<Map<String, dynamic>> getCurrentAqi() async {
    try {
      String lat = '30.3398';
      String lon = '76.3869';
      final res = await http.get(
        Uri.parse(
          'http://api.openweathermap.org/data/2.5/air_pollution/forecast?lat=$lat&lon=$lon&appid=$openWeatherAPIKey',
        ),
      );

      final data = jsonDecode(res.body);

      if (res.statusCode != 200) {
        throw 'An unexpected error occurred';
      }

      return data;
    } catch (e) {
      throw e.toString();
    }
  }

  @override
  void initState() {
    super.initState();
    weatherAndAqi = Future.wait([getCurrentWeather(), getCurrentAqi()]);
  }

  String getIconForWeather(String weatherMain) {
    switch (weatherMain.toLowerCase()) {
      case 'clear':
        return 'assets/images/sun.png';
      case 'rain':
        return 'assets/images/rainfall.png';
      case 'thunderstorm':
        return 'assets/images/thunder.png';
      case 'snow':
        return 'assets/images/snow.png';
      case 'clouds':
        return 'assets/images/cloud.png';
      case 'mist':
      case 'smoke':
      case 'haze':
      case 'dust':
      case 'fog':
      case 'sand':
      case 'ash':
      case 'squall':
      case 'tornado':
        return 'assets/images/fog.png';
      default:
        return 'assets/images/sun.png'; // Fallback icon
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: weatherAndAqi,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(snapshot.error.toString()),
          );
        }

        final weatherData = snapshot.data![0];
        final aqiData = snapshot.data![1];

        final windSpeed = weatherData['wind']['speed'];
        final visibility = weatherData['visibility'] / 1000; // converting to km
        final humidity = weatherData['main']['humidity'];

        // Extract temperature and weather main condition
        final temperature = weatherData['main']['temp'];
        final weatherMain = weatherData['weather'][0]['main'];

        // Get the appropriate icon for the weather condition
        final iconPath = getIconForWeather(weatherMain);

        // Get AQI value from the AQI data
        final aqiValue = aqiData['list'][0]['main']['aqi'];

        return Row(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 16, left: 12, right: 8),
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => HomePage()),
                  );
                },
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(),
                    borderRadius: BorderRadius.circular(12),
                    color: const Color.fromARGB(255, 255, 255, 255),
                    boxShadow: [
                      BoxShadow(
                        blurRadius: 4,
                        color: Colors.grey,
                        offset: Offset(0.0, 2.0),
                      ),
                    ],
                  ),
                  height: 181,
                  width: 250,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Weather Icon
                      Row(
                        children: [
                          // Temperature
                          Padding(
                            padding: const EdgeInsets.only(left: 12),
                            child: Text(
                              '${temperature.toStringAsFixed(0)}',
                              style: const TextStyle(
                                  fontSize: 90,
                                  fontFamily: 'Coolvetica',
                                  color: Colors.black),
                            ),
                          ),
                          const Padding(
                            padding: const EdgeInsets.only(bottom: 40),
                            child: Text(
                              '°C',
                              style: TextStyle(
                                  fontSize: 30,
                                  fontFamily: "Coolvetica",
                                  color: Colors.black),
                            ),
                          ),
                          SizedBox(
                            width: 25,
                          ),
                          Image.asset(
                            iconPath,
                            height: 80,
                            width: 80,
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(left: 12.0),
                            child: Icon(
                              Icons.location_on,
                              size: 30,
                              color: Colors.black,
                            ),
                          ),
                          Text(
                            'Patiala',
                            style: TextStyle(
                                fontFamily: 'Coolvetica',
                                color: Colors.black,
                                fontSize: 30),
                          ),
                          SizedBox(
                            width: 30,
                          ),
                          Text(
                            weatherMain,
                            style: const TextStyle(
                                fontSize: 20,
                                fontFamily: "Coolvetica",
                                color: Colors.black),
                          ),
                        ],
                      ),
                      // Weather Description
                      Spacer()
                    ],
                  ),
                ),
              ),
            ),
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 8, top: 17),
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      border: Border.all(),
                      borderRadius: BorderRadius.circular(12),
                      color: const Color.fromARGB(255, 255, 255, 255),
                      boxShadow: [
                        BoxShadow(
                          blurRadius: 4,
                          color: Colors.grey,
                          offset: Offset(0.0, 2.0),
                        ),
                      ],
                    ),
                    height: 130,
                    width: 104,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(height: 12),
                                Text(
                                  '  Wind:',
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: Colors.black,
                                    fontFamily: 'Coolvetica',
                                    height: 0.4,
                                  ),
                                ),
                                Text(
                                  '  $windSpeed m/s',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.black,
                                    fontFamily: 'Coolvetica',
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 8),
                              ],
                            ),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '  Visibility:',
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: Colors.black,
                                    fontFamily: 'Coolvetica',
                                    height: 0.4,
                                  ),
                                ),
                                Text(
                                  '  $visibility KM',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.black,
                                    fontFamily: 'Coolvetica',
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 8),
                              ],
                            ),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '  Humidity:',
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: Colors.black,
                                    fontFamily: 'Coolvetica',
                                    height: 0.4,
                                  ),
                                ),
                                Text(
                                  '  $humidity%',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'Coolvetica',
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 8, top: 6),
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(),
                      borderRadius: BorderRadius.circular(12),
                      color: const Color.fromARGB(255, 255, 255, 255),
                      boxShadow: [
                        BoxShadow(
                          blurRadius: 4,
                          color: Colors.grey,
                          offset: Offset(0.0, 2.0),
                        ),
                      ],
                    ),
                    height: 45,
                    width: 104,
                    child: Row(
                      children: [
                        Text(
                          '  AQI:',
                          style: TextStyle(
                              fontFamily: "Coolvetica",
                              fontSize: 20,
                              color: Colors.black),
                        ),
                        Text(
                          ' $aqiValue',
                          style: TextStyle(
                              fontFamily: "Coolvetica",
                              fontSize: 28,
                              color: Colors.black),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}
