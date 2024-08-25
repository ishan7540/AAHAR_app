import 'package:flutter/material.dart';

class SecondTile extends StatelessWidget {
  const SecondTile({super.key});

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
        height: 350,
        width: 360,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("  Your Field ➔ ",
                style: TextStyle(
                    fontFamily: 'Coolvetica',
                    fontSize: 28,
                    color: Colors.black)),
            Row(
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 12, bottom: 6),
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(width: 3),
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
                    height: 140,
                    width: 200,
                  ),
                ),
                Column(
                  children: [
                    Padding(
                      padding:
                          const EdgeInsets.only(right: 12, top: 6, left: 7),
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(width: 3),
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
                        height: 66,
                        width: 127,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(
                          right: 12, top: 6, left: 7, bottom: 12),
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(width: 3),
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
                        height: 66,
                        width: 127,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(left: 12, right: 12),
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(width: 3),
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
                height: 140,
                width: 337,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
