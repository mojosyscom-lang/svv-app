import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://mvlebtgqacyqzacwqhyb.supabase.co',
    anonKey: 'sb_publishable_2rJGJpT_WHz7zpq8EiA-Ww_ZtZYtiiq',
  );

  runApp(const SVVApp());
}