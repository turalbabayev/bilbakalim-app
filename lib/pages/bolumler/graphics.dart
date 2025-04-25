import 'package:bilbakalim/services/fetch_subtitles.dart';
import 'package:bilbakalim/services/graphics_services.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class GraphicsPage extends StatefulWidget {
  final int bolumIndex;
  GraphicsPage({
    super.key,
    required this.bolumIndex,
  });
  final Color leftBarColor = Colors.green;
  final Color rightBarColor = Colors.red;
  final Color avgColor = Colors.orange;
  late Future<DataSnapshot> subtitles;
  @override
  State<StatefulWidget> createState() => GraphicsPageState();
}

class GraphicsPageState extends State<GraphicsPage> {
  final double width = 7;

  late List<BarChartGroupData> rawBarGroups;
  late List<BarChartGroupData> showingBarGroups;

  int touchedGroupIndex = -1;

  Future<DataSnapshot> _fetchSubtitles() async {
    return await fetch_subtitles(widget.bolumIndex);
  }

  Future<DataSnapshot> _fetchGraphicsData() async {
    return await fetchGraphic(widget.bolumIndex);
  }

  @override
  void initState() {
    super.initState();

    widget.subtitles = _fetchSubtitles();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Grafikler"),
      ),
      body: FutureBuilder(
        future: _fetchGraphicsData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            // Veriler yüklenirken bir yükleme animasyonu göster
            return const Center(
              child: CircularProgressIndicator(),
            );
          } else if (snapshot.hasError) {
            // Hata durumunda bir mesaj göster
            return Center(
              child: Text(
                'Hata oluştu: ${snapshot.error}',
                style: const TextStyle(color: Colors.red),
              ),
            );
          } else if (snapshot.hasData && snapshot.data != null) {
            // Veriler başarıyla yüklendiğinde BarChart oluştur
            final data = snapshot.data!;
            print(data.value);

            // BarChartGroupData'ları oluşturmak için verileri işleme
            final barGroups = _createBarGroupsFromData(data.value);

            return Column(
              children: [
                Flexible(
                  child: RotatedBox(
                    quarterTurns: 1,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: BarChart(
                        BarChartData(
                          maxY: 20,
                          barGroups: barGroups,
                          titlesData: FlTitlesData(
                            show: true,
                            rightTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            topTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: bottomTitles,
                                reservedSize: 42,
                              ),
                            ),
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 28,
                                interval: 1,
                                getTitlesWidget: leftTitles,
                              ),
                            ),
                          ),
                          borderData: FlBorderData(
                            show: false,
                          ),
                          gridData: const FlGridData(show: false),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          } else {
            return const Center(
              child: Text("Beklenmeyen bir durum oluştu."),
            );
          }
        },
      ),
    );
  }

  Widget leftTitles(double value, TitleMeta meta) {
    const style = TextStyle(
      color: Color(0xff7589a2),
      fontWeight: FontWeight.bold,
      fontSize: 14,
    );
    String text;
    if (value == 0) {
      text = '1K';
    } else if (value == 10) {
      text = '5K';
    } else if (value == 19) {
      text = '10K';
    } else {
      return Container();
    }
    return SideTitleWidget(
      axisSide: meta.axisSide,
      space: 0,
      child: Text(text, style: style),
    );
  }

  Widget bottomTitles(double value, TitleMeta meta) {
    return FutureBuilder<DataSnapshot>(
      future: widget.subtitles,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox.shrink();
        } else if (snapshot.hasError) {
          return const Text(
            'Hata',
            style: TextStyle(
              color: Colors.red,
              fontSize: 8,
            ),
          );
        } else if (snapshot.hasData && snapshot.data != null) {
          final titles = <String>[];
          Map val = snapshot.data!.value as Map;
          for (var e in val.values) {
            titles.add(e["baslik"]);
          }

          // value.toInt() sınır kontrolü
          if (value.toInt() >= titles.length) {
            return const SizedBox.shrink();
          }

          final Widget text = SizedBox(
            width: 75,
            child: Text(
              titles[value.toInt()],
              style: const TextStyle(
                color: Color(0xff7589a2),
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          );

          return SideTitleWidget(
            axisSide: meta.axisSide,
            space: 16,
            child: text,
          );
        } else {
          return const SizedBox.shrink(); // Veri yoksa boş döndür
        }
      },
    );
  }

  List<BarChartGroupData> _createBarGroupsFromData(data) {
    final List<BarChartGroupData> barGroups = [];
    int index = 0;

    data.forEach((n) {
      if (n != null) {
        final y1 = n['correct'] ?? 0.0; // İlk çubuk değeri
        final y2 = n['incorrect'] ?? 0.0; // İkinci çubuk değeri

        barGroups.add(makeGroupData(index, y1.toDouble(), y2.toDouble()));
        index++;
      }
    });
    return barGroups;
  }

  BarChartGroupData makeGroupData(int x, double y1, double y2) {
    return BarChartGroupData(
      barsSpace: 4,
      x: x,
      barRods: [
        BarChartRodData(
          toY: y1,
          color: widget.leftBarColor,
          width: width,
        ),
        BarChartRodData(
          toY: y2,
          color: widget.rightBarColor,
          width: width,
        ),
      ],
    );
  }
}
