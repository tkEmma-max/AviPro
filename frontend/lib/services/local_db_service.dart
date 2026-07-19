// lib/services/local_db_service.dart
import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class LocalDbService {
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'avipro_local.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Poulaillers
    await db.execute('''
      CREATE TABLE poulaillers (
        id TEXT PRIMARY KEY,
        nom TEXT NOT NULL,
        longueur REAL,
        largeur REAL,
        hauteur REAL,
        localisation TEXT,
        type_sol TEXT,
        nombre_mangeoires INTEGER DEFAULT 0,
        nombre_abreuvoirs INTEGER DEFAULT 0,
        is_archived INTEGER DEFAULT 0,
        is_deleted INTEGER DEFAULT 0,
        version INTEGER DEFAULT 1,
        created_by TEXT,
        data_json TEXT,
        synced INTEGER DEFAULT 0,
        last_sync_at TEXT,
        updated_at TEXT
      )
    ''');

    // Cycles
    await db.execute('''
      CREATE TABLE cycles (
        id TEXT PRIMARY KEY,
        nom TEXT NOT NULL,
        poulailler TEXT,
        type TEXT,
        type_poulet TEXT,
        date_debut TEXT,
        date_fin TEXT,
        nombre_sujets_initiaux INTEGER,
        nombre_sujets_actuels INTEGER,
        duree_estimee_jours INTEGER,
        is_active INTEGER DEFAULT 1,
        is_archived INTEGER DEFAULT 0,
        is_deleted INTEGER DEFAULT 0,
        nb_morts INTEGER DEFAULT 0,
        version INTEGER DEFAULT 1,
        created_by TEXT,
        data_json TEXT,
        synced INTEGER DEFAULT 0,
        last_sync_at TEXT,
        updated_at TEXT
      )
    ''');

    // Pending Sync
    await db.execute('''
      CREATE TABLE pending_sync (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        table_name TEXT NOT NULL,
        model TEXT NOT NULL,
        object_id TEXT NOT NULL,
        action TEXT NOT NULL,
        data_json TEXT NOT NULL,
        created_at TEXT NOT NULL,
        synced INTEGER DEFAULT 0
      )
    ''');
  }

  // ═══════════════════════════════════════════
  // CRUD GÉNÉRIQUE
  // ═══════════════════════════════════════════

  Future<int> insert(String table, Map<String, dynamic> data) async {
    final db = await database;
    data['data_json'] = jsonEncode(data);
    data['updated_at'] = DateTime.now().toIso8601String();
    return await db.insert(table, data, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<int> update(String table, Map<String, dynamic> data) async {
    final db = await database;
    data['data_json'] = jsonEncode(data);
    data['updated_at'] = DateTime.now().toIso8601String();
    data['version'] = (data['version'] ?? 0) + 1;
    return await db.update(table, data, where: 'id = ?', whereArgs: [data['id']]);
  }

  Future<int> softDelete(String table, String id) async {
    final db = await database;
    return await db.update(table, {
      'is_deleted': 1,
      'updated_at': DateTime.now().toIso8601String()
    }, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> hardDelete(String table, String id) async {
    final db = await database;
    return await db.delete(table, where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Map<String, dynamic>>> getAll(String table) async {
    final db = await database;
    return await db.query(table, where: 'is_deleted = ?', whereArgs: [0]);
  }

  Future<Map<String, dynamic>?> getById(String table, String id) async {
    final db = await database;
    final results = await db.query(table, where: 'id = ? AND is_deleted = ?', whereArgs: [id, 0]);
    return results.isNotEmpty ? results.first : null;
  }

  Future<List<Map<String, dynamic>>> getUnsynced(String table) async {
    final db = await database;
    return await db.query(table, where: 'synced = ? AND is_deleted = ?', whereArgs: [0, 0]);
  }

  Future<void> markAsSynced(String table, String id) async {
    final db = await database;
    await db.update(table, {
      'synced': 1,
      'last_sync_at': DateTime.now().toIso8601String()
    }, where: 'id = ?', whereArgs: [id]);
  }

  // ═══════════════════════════════════════════
  // FILE D'ATTENTE DE SYNCHRONISATION
  // ═══════════════════════════════════════════

  Future<void> addToPendingSync({
    required String tableName,
    required String model,
    required String objectId,
    required String action,
    required Map<String, dynamic> data,
  }) async {
    final db = await database;
    await db.insert('pending_sync', {
      'table_name': tableName,
      'model': model,
      'object_id': objectId,
      'action': action,
      'data_json': jsonEncode(data),
      'created_at': DateTime.now().toIso8601String(),
      'synced': 0,
    });
  }

  Future<List<Map<String, dynamic>>> getPendingSync() async {
    final db = await database;
    return await db.query('pending_sync', where: 'synced = ?', whereArgs: [0], orderBy: 'created_at ASC');
  }

  Future<void> markPendingSyncAsDone(int id) async {
    final db = await database;
    await db.update('pending_sync', {'synced': 1}, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> clearAll() async {
    final db = await database;
    await db.delete('poulaillers');
    await db.delete('cycles');
    await db.delete('pending_sync');
  }
}