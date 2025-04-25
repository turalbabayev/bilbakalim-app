import 'package:flutter/material.dart';
import 'package:bilbakalim/components/flying_baloon.dart';
import 'package:bilbakalim/pages/bolumler/bolum.dart';
import 'package:bilbakalim/pages/diger/diger.dart';
import 'package:firebase_database/firebase_database.dart';

class HomePage extends StatelessWidget {
  HomePage({super.key});

  final DatabaseReference _ref = FirebaseDatabase.instance.ref();

  Future<DataSnapshot> fetchTitles() {
    return _ref.child("konular").get();
  }

  void goPage(Widget page, BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => page),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          image: DecorationImage(
            image: const AssetImage("assets/images/background.png"),
            fit: BoxFit.fill,
            colorFilter: ColorFilter.mode(
                Colors.black.withOpacity(0.1), BlendMode.darken),
          ),
        ),
        child: FutureBuilder(
          future: fetchTitles(),
          builder: (context, AsyncSnapshot<DataSnapshot> snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Hata: ${snapshot.error}'));
            }
            if (!snapshot.hasData || snapshot.data!.value == null) {
              return const Center(child: Text('Veri bulunamadı.'));
            }
            List<dynamic> data = snapshot.data!.value as List<dynamic>;
            List<String> bolumler = data
                    .where((e) =>
                        e != null &&
                        e["baslik"] != null) // Null değerleri filtrele
                    .map((e) => e["baslik"].toString())
                    .toList() +
                ["Diğer"];

            return GridView.builder(
              itemCount: bolumler.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 20,
              ),
              itemBuilder: (context, index) {
                String title = bolumler[index];

                return BouncingImage(
                  text: title,
                  onTap: () {
                    if (index != bolumler.length - 1) {
                      goPage(
                          BolumPage(
                            appBarTitle: title,
                            bolumIndex: index + 1,
                          ),
                          context);
                    } else {
                      goPage(DigerPage(), context);
                    }
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}
