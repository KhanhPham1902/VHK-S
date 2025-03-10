
import 'package:flutter/cupertino.dart';
import 'package:sqflite/sqflite.dart';
import 'package:vhks/database/DatabaseService.dart';

import '../api/response/ShipResponse.dart';

class ShipInfoDB{

    String TAG = "ShipInfoDB";

    final tableName = "ShipData";
    final id = "id";
    final idResponse = "idResponse";
    final imei = "imei";
    final shipNumber = "shipNumber";
    final owner = "owner";
    final captain = "captain";
    final phone = "phone";

    Future<void> createTable(Database database) async {
        await database.execute("DROP TABLE IF EXISTS $tableName");
        await database.execute("""
            CREATE TABLE $tableName (
                $id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
                $shipNumber TEXT NOT NULL UNIQUE,
                $imei TEXT NOT NULL UNIQUE,
                $idResponse TEXT NOT NULL UNIQUE,
                $owner TEXT NOT NULL,
                $captain TEXT NOT NULL,
                $phone TEXT NOT NULL
            );
        """);
    }

    // Kiem tra xem ban ghi co ton tai hay khong theo so imei
    Future<bool> isDataExist(String imeiResponse) async {
        final database = await DatabaseService().database;
        final result = await database.rawQuery(
            '''SELECT EXISTS(SELECT 1 FROM $tableName WHERE $imei = ?)''',
            [imeiResponse],
        );
        return Sqflite.firstIntValue(result) == 1;
    }

    // The ban ghi moi
    Future<int?> insertData({required ShipResponse shipResponse}) async {
        try {
            final database = await DatabaseService().database;

            if (database == null) {
                debugPrint("$TAG - Database chưa được khởi tạo.");
                return null;
            }

            return await database.rawInsert(
                '''INSERT INTO $tableName ($shipNumber, $imei, $idResponse, $owner, $captain, $phone) VALUES (?,?,?,?,?,?)''',
                [
                    shipResponse.shipNumber,
                    shipResponse.imei,
                    shipResponse.id,
                    shipResponse.owner,
                    shipResponse.captain,
                    shipResponse.phone,
                ],
            );
        } catch (e) {
            debugPrint("$TAG - Lỗi khi chèn dữ liệu: $e");
            return null;
        }
    }

    // Lay tat ca ban ghi gps theo thoi gian giam dan
    Future<List<ShipResponse>> getAllData() async {
        final database = await DatabaseService().database;
        final shipInfo = await database.rawQuery(
            '''SELECT * FROM $tableName ORDER BY $id ASC''',
        );
        return shipInfo.map((info) => ShipResponse.fromSqliteDatabase(info)).toList();
    }

    // Lay thong tin tau dua tren so hieu tau
    Future<ShipResponse?> getShipDataByShipNumber(String shipName) async {
        final database = await DatabaseService().database;
        final List<Map<String, dynamic>> result = await database.query(
            tableName,
            where: "$shipNumber = ?",
            whereArgs: [shipName],
            limit: 1,
        );

        if (result.isNotEmpty) {
            return ShipResponse.fromSqliteDatabase(result.first);
        }
        return null;
    }

    // Lay tat ca so hieu tau
    Future<List<String>> getAllShipNumbers() async {
        final database = await DatabaseService().database;
        final results = await database.rawQuery(
            '''SELECT $shipNumber FROM $tableName'''
        );
        return results.map((row) => row[shipNumber] as String).toList();
    }

    // Lay tat ca thuyen truong
    Future<List<String>> getAllCaptains() async {
        final database = await DatabaseService().database;
        final results = await database.rawQuery(
            '''SELECT $captain FROM $tableName'''
        );
        return results.map((row) => row[captain] as String).toList();
    }

    // Xóa tất cả bản ghi
    Future<int> deleteAllLogs() async {
        final database = await DatabaseService().database;
        final count = await database.rawDelete(
            '''DELETE FROM $tableName'''
        );
        return count; // Trả về số bản ghi đã bị xóa
    }
}