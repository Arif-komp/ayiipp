import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NotaScreen extends StatefulWidget {
  @override
  _NotaScreenState createState() => _NotaScreenState();
}

class _NotaScreenState extends State<NotaScreen> {
  File? _image;
  bool _isLoading = false;
  final _namaController = TextEditingController();
  final _totalController = TextEditingController();
  final supabase = Supabase.instance.client;

  // 1. Ambil Foto & Scan OCR
  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await ImagePicker().pickImage(source: source);
    if (pickedFile == null) return;

    setState(() {
      _image = File(pickedFile.path);
      _isLoading = true;
    });

    // Proses OCR (Membaca Teks)
    final inputImage = InputImage.fromFile(_image!);
    final textRecognizer = TextRecognizer();
    final recognizedText = await textRecognizer.processImage(inputImage);

    _extractTotal(recognizedText.text);
    textRecognizer.close();
  }

  // Logika mencari angka terbesar (asumsi itu Total Belanja)
  void _extractTotal(String text) {
    RegExp regExp = RegExp(r'(\d{1,3}(\.\d{3})+|(\d{4,}))');
    var matches = regExp.allMatches(text);
    List<double> prices = [];
    for (var m in matches) {
      prices.add(double.tryParse(m.group(0)!.replaceAll('.', '')) ?? 0);
    }
    if (prices.isNotEmpty) {
      prices.sort();
      _totalController.text = prices.last.toStringAsFixed(0);
    }
    setState(() => _isLoading = false);
  }

  // 2. Simpan ke Supabase (Storage & Database)
  Future<void> _uploadData() async {
    if (_image == null || _totalController.text.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      // A. Upload Foto ke Storage
      final fileName = 'nota_${DateTime.now().millisecondsSinceEpoch}.jpg';
      await supabase.storage.from('struk_belanja').upload(fileName, _image!);
      
      final imageUrl = supabase.storage.from('struk_belanja').getPublicUrl(fileName);

      // B. Simpan Data ke Tabel
      await supabase.from('nota_keluar').insert({
        'keterangan': _namaController.text,
        'total': double.parse(_totalController.text),
        'image_url': imageUrl,
      });

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Berhasil Tersimpan Online!")));
      setState(() { _image = null; _namaController.clear(); _totalController.clear(); });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Input Nota Online")),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            _image != null 
                ? Image.file(_image!, height: 200) 
                : Container(height: 200, color: Colors.grey[200], child: Icon(Icons.camera_alt, size: 50)),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(icon: Icon(Icons.camera), onPressed: () => _pickImage(ImageSource.camera)),
                IconButton(icon: Icon(Icons.photo_library), onPressed: () => _pickImage(ImageSource.gallery)),
              ],
            ),
            
            TextField(controller: _namaController, decoration: InputDecoration(labelText: "Keterangan")),
            TextField(controller: _totalController, decoration: InputDecoration(labelText: "Total (Rp)"), keyboardType: TextInputType.number),
            
            SizedBox(height: 30),
            
            _isLoading 
              ? CircularProgressIndicator() 
              : ElevatedButton(onPressed: _uploadData, child: Text("SIMPAN KE CLOUD")),
          ],
        ),
      ),
    );
  }
}
