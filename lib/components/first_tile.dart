import 'package:flutter/material.dart';
import 'package:rain/app/modules/home.dart';

class firsTile extends StatelessWidget {
  const firsTile({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 16, left: 12, right: 8),
          child: GestureDetector(
            onTap: () {
              Navigator.push(
                  context, MaterialPageRoute(builder: (context) => HomePage()));
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
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              height: 12,
                            ),
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
                              '  2 MPH',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.black,
                                fontFamily: 'Coolvetica',
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(
                              height: 8,
                            )
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
                              '  8 KM',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Coolvetica',
                              ),
                            ),
                            SizedBox(
                              height: 8,
                            )
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
                              '  99%',
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
                    //   Padding(
                    // padding: const EdgeInsets.only(left: 6),
                    //     child: Image.asset(
                    //       'lib/assets/images/Natural Food@2x.png',
                    //       height: 30,
                    //     ),
                    //   ),
                    Text(
                      'AQI:',
                      style: TextStyle(fontFamily: "Coolvetica", fontSize: 20),
                    ),
                    Text(
                      ' 134',
                      style: TextStyle(fontFamily: "Coolvetica", fontSize: 28),
                    )
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
