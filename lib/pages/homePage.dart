import 'package:rain/components/first_tile.dart';
import 'package:flutter/material.dart';
import 'package:rain/components/sideMenu.dart';
import 'package:rain/components/second_tile.dart';
import 'package:rain/components/third_tile.dart';

class Name extends StatelessWidget {
  const Name({super.key});

  @override
  Widget build(BuildContext context) {
    return Container();
  }
}

class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Padding(
            padding: const EdgeInsets.only(left: 80),
            child: Image.asset('lib/assets/images/AAHAR_logo.png'),
          ),
          backgroundColor: Color.fromRGBO(59, 180, 118, 1),
        ),
        drawer: sideMenu(),
        body: Container(
          color: Color.fromRGBO(
            243,
            233,
            233,
            1,
          ),
          child: ListView(
            children: const [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  firsTile(),
                  SecondTile(),
                  thirdTile(),
                ],
              ),
            ],
          ),
        ));
  }
}
