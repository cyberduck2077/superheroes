import 'package:flutter/material.dart';
import 'package:superheroes/resources/superheroes_colors.dart';

import '../widgets/action_button.dart';

class SuperheroPage extends StatelessWidget {
  final String name;
  const SuperheroPage({Key? key, required this.name}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SuperheroesColors.background,
      body: SafeArea(
        minimum: EdgeInsets.only(bottom: 30),
        child: Stack(
          children: [
            Center(
              child: Text(
                name,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w600),
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: ActionButton(
                text: "Back",
                onTap: (){
                  Navigator.of(context).pop();
                },
              ),
            )
          ],
        ),
      ),
    );
  }
}
