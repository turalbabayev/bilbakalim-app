import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DenemeSinavlariPage extends StatefulWidget {
  const DenemeSinavlariPage({super.key});

  @override
  State<DenemeSinavlariPage> createState() => _DenemeSinavlariPageState();
}

class _DenemeSinavlariPageState extends State<DenemeSinavlariPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late Future<List<Map<String, dynamic>>> _denemeSinavlariFuture;
  bool _isFiltering = false;
  String _selectedCategory = "Hepsi";
  
  @override
  void initState() {
    super.initState();
    _denemeSinavlariFuture = _fetchDenemeSinavlari();
  }
  
  Future<List<Map<String, dynamic>>> _fetchDenemeSinavlari() async {
    try {
      final QuerySnapshot<Map<String, dynamic>> snapshot = 
          await _firestore.collection('denemeSinavlari').get();
          
      return snapshot.docs.map((doc) => {
        'id': doc.id,
        ...doc.data(),
      }).toList();
    } catch (e) {
      print('Deneme sınavları çekilirken hata: $e');
      return [];
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Deneme Sınavları',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _denemeSinavlariFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Bir hata oluştu: ${snapshot.error}',
                style: GoogleFonts.poppins(color: Colors.red),
              ),
            );
          }
          
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Text(
                'Henüz deneme sınavı bulunmuyor.',
                style: GoogleFonts.poppins(),
              ),
            );
          }
          
          final denemeler = snapshot.data!;
          
          // Kategoriye göre filtreleme
          final filteredDenemeler = _selectedCategory == "Hepsi"
              ? denemeler
              : denemeler.where((deneme) => 
                  deneme['kategori']?.toString().toLowerCase() == 
                  _selectedCategory.toLowerCase()).toList();
          
          return Column(
            children: [
              // Kategori filtreleme butonu
              if (_isFiltering) ...[
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      const SizedBox(width: 8),
                      _buildFilterChip("Hepsi"),
                      const SizedBox(width: 8),
                      ...denemeler
                          .map((e) => e['kategori']?.toString() ?? '')
                          .toSet()
                          .map((kategori) => Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: _buildFilterChip(kategori),
                              )),
                    ],
                  ),
                ),
              ],
              
              // Deneme sınavları listesi
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredDenemeler.length,
                  itemBuilder: (context, index) {
                    final deneme = filteredDenemeler[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: ListTile(
                        title: Text(
                          deneme['baslik'] ?? '',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          deneme['aciklama'] ?? '',
                          style: GoogleFonts.poppins(),
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios),
                        onTap: () {
                          // TODO: Deneme sınavı detay sayfasına yönlendir
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            _isFiltering = !_isFiltering;
          });
        },
        child: Icon(_isFiltering ? Icons.filter_list_off : Icons.filter_list),
      ),
    );
  }
  
  Widget _buildFilterChip(String label) {
    return FilterChip(
      label: Text(
        label,
        style: GoogleFonts.poppins(
          color: _selectedCategory == label ? Colors.white : Colors.black,
        ),
      ),
      selected: _selectedCategory == label,
      onSelected: (bool selected) {
        setState(() {
          _selectedCategory = selected ? label : "Hepsi";
        });
      },
    );
  }
} 