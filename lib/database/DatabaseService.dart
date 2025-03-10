import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import 'ShipInfoDB.dart';

class DatabaseService{
    Database? _database;

    Future<Database> get database async {
        if(_database != null){
            return _database!;
        }
        _database = await _initDatabase();
        return _database!;
    }

    Future<String> get fullPath async {
        const name = 'shipdata.db';
        final path = await getDatabasesPath();
        return join(path, name);
    }

    Future<Database> _initDatabase() async {
        final path = await fullPath;
        var database = await openDatabase(
            path,
            version: 1,
            onCreate: create,
            singleInstance: true
        );
        return database;
    }

    Future<void> create(Database database, int version) async =>
        await ShipInfoDB().createTable(database);
}