import 'package:flutter/material.dart';

class sideMenu extends StatelessWidget {
  const sideMenu({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      shape: Border.all(width: 3),
      child: ListView(
        padding: EdgeInsets.all(0),
        children: [
          const SizedBox(
            height: 300,
            child: const DrawerHeader(
              decoration: BoxDecoration(
                color: Color.fromRGBO(50, 152, 99, 1),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.person,
                    size: 165,
                  ),
                  Padding(
                    padding: EdgeInsets.only(),
                    child: Row(
                      children: [
                        SizedBox(width: 8),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Farmer",
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 17,
                                  fontFamily: "Inter"),
                            ),
                            SizedBox(height: 2),
                            Text(
                              "famer@gmail.com",
                              style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 15,
                                  fontFamily: "Inter"),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text(' dummy '),
            onTap: () {
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.book),
            title: const Text(' dummy '),
            onTap: () {
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.workspace_premium),
            title: const Text(' dummy '),
            onTap: () {
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.video_label),
            title: const Text(' dummy '),
            onTap: () {
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.edit),
            title: const Text(' dummy '),
            onTap: () {
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('LogOut'),
            onTap: () {
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}
