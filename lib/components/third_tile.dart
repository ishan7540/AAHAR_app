import 'package:flutter/material.dart';

class thirdTile extends StatelessWidget {
  const thirdTile({super.key});

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
        height: 200,
        width: 400,
        child: const Text("  Community ➔ ",
            style: TextStyle(fontFamily: 'Coolvetica', fontSize: 28)),
      ),
    );
  }
}
