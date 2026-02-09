import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'nota_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // GANTI DENGAN KREDENSI SUPABASE ANDA
  await Supabase.initialize(
    url: 'https://dwswcjxteizscoqogctn.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImR3c3djanh0ZWl6c2NvcW9nY3RuIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzA2NDU4NjEsImV4cCI6MjA4NjIyMTg2MX0.-nKZab7ArLM_CNL3fnsZSx6wKOlZw5e1eI-MfziDXiY',
  );

  runApp(MaterialApp(
    title: 'Nota Keluar Online',
    theme: ThemeData(primarySwatch: Colors.indigo, useMaterial3: true),
    home: NotaScreen(),
  ));
}
