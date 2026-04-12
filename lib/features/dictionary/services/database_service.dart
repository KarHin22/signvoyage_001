import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:io' show Platform;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../models/vocab.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._init();
  static Database? _database;

  DatabaseService._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('dictionary.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    if (Platform.isWindows || Platform.isLinux) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 2,
      onCreate: _createDB,
      onUpgrade: (db, oldVersion, newVersion) async {
        await db.execute('DROP TABLE IF EXISTS vocab');
        await _createDB(db, newVersion);
      },
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE vocab (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        word TEXT NOT NULL,
        category TEXT NOT NULL,
        videoPaths TEXT NOT NULL
      )
    ''');
    
    // Seed initial data
    final initialData = [
      // Basics
      Vocab(word: 'Hello', category: 'Basics', videoPaths: ['assets/videos/Hello001.mp4', 'assets/videos/Hello002.mp4']),
      Vocab(word: 'Thank you', category: 'Basics', videoPaths: ['assets/videos/ThankYou001.mp4']),
      Vocab(word: 'Please', category: 'Basics', videoPaths: ['assets/videos/Please001.mp4', 'assets/videos/Please002.mp4']),
      Vocab(word: 'Yes', category: 'Basics', videoPaths: ['assets/videos/Yes001.mp4']),
      Vocab(word: 'No', category: 'Basics', videoPaths: ['assets/videos/No001.mp4', 'assets/videos/No002.mp4', 'assets/videos/No003.mp4']),
      Vocab(word: 'Good', category: 'Basics', videoPaths: ['assets/videos/Good001.mp4']),
      // Transport
      Vocab(word: 'Where', category: 'Transport', videoPaths: ['assets/videos/Where001.mp4', 'assets/videos/Where002.mp4']),
      Vocab(word: 'Follow', category: 'Transport', videoPaths: ['assets/videos/Follow001.mp4']),
      Vocab(word: 'Toilet', category: 'Transport', videoPaths: ['assets/videos/Toilet001.mp4', 'assets/videos/Toilet002.mp4']),
      Vocab(word: 'Airport', category: 'Transport', videoPaths: ['assets/videos/Airport001.mp4', 'assets/videos/Airport002.mp4']),
      Vocab(word: 'Hotel', category: 'Transport', videoPaths: ['assets/videos/Hotel001.mp4']),
      Vocab(word: 'Taxi', category: 'Transport', videoPaths: ['assets/videos/Taxi001.mp4']),
      // Needs
      Vocab(word: 'Water', category: 'Needs', videoPaths: ['assets/videos/Water001.mp4']),
      Vocab(word: 'Food', category: 'Needs', videoPaths: ['assets/videos/Food001.mp4']),
      Vocab(word: 'How much / \nHow many', category: 'Needs', videoPaths: ['assets/videos/HowMany001.mp4']),
      Vocab(word: 'Phone', category: 'Needs', videoPaths: ['assets/videos/Phone001.mp4']),
      // Support
      Vocab(word: 'Wait', category: 'Support', videoPaths: ['assets/videos/Wait001.mp4']),
      Vocab(word: 'What', category: 'Support', videoPaths: ['assets/videos/What001.mp4']),
      Vocab(word: 'I don\'t understand', category: 'Support', videoPaths: ['assets/videos/IDontUnderstand001.mp4', 'assets/videos/IDontUnderstand002.mp4']),
      Vocab(word: 'Deaf', category: 'Support', videoPaths: ['assets/videos/Deaf001.mp4']),
    ];

    for (final vocab in initialData) {
      await db.insert('vocab', vocab.toMap());
    }
  }

  Future<List<Vocab>> getVocabs() async {
    final db = await instance.database;
    final result = await db.query('vocab');
    return result.map((map) => Vocab.fromMap(map)).toList();
  }
}
