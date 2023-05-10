import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import 'dart:io';
import 'package:flutter/services.dart';
List<Map> mapListtest = <Map>[];
/*------------------------------------------------------------------
全共通のメソッド
 -------------------------------------------------------------------*/
/*------------------------------------------------------------------
初回起動分
 -------------------------------------------------------------------*/
Future<void> firstRun() async {
  String dbpath = await getDatabasesPath();
  //設定テーブル作成
  String path = p.join(dbpath, "internal_assets.db");
  //設定テーブルがなければ、最初にassetsから作る
  var exists = await databaseExists(path);
  if (!exists) {
    // Make sure the parent directory exists
    //親ディレクリが存在することを確認
    try {
      await Directory(p.dirname(path)).create(recursive: true);
    } catch (_) {}
    // Copy from asset
    ByteData data = await rootBundle.load(p.join("assets", "exRiderLocal.db"));
    List<int> bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
    // Write and flush the bytes written
    await File(path).writeAsBytes(bytes, flush: true);
  } else {
    //print("Opening existing database");
  }
}
/*------------------------------------------------------------------
FireStore初回登録
 -------------------------------------------------------------------*/
Future<void> firstFireStoreDBIns() async{

  //PG Master
  await pgMasterDelete();
  await pgMasterINS();

  //volMaster
  await volMasterDelete();
  await volMasterINS();


}
/*------------------------------------------------------------------
pgMasterDelete
 -------------------------------------------------------------------*/
Future<void> pgMasterDelete() async{
  //PG MasterDrop
  String dbPath = await getDatabasesPath();
  String query = '';
  String path = p.join(dbPath, 'internal_assets.db');
  Database database = await openDatabase(
    path,
    version: 1,
  );
  query = 'Delete from pgMaster';
  await database.transaction((txn) async {
    await txn.rawInsert(query);
  });
}
/*------------------------------------------------------------------
pgMaster登録
 -------------------------------------------------------------------*/
Future<void> pgMasterINS() async{
  //PG Master登録
  final collectionRef = FirebaseFirestore.instance.collection('riderMaster'); // DocumentReference
  final querySnapshot = await collectionRef.get(); // QuerySnapshot
  final queryDocSnapshot = querySnapshot.docs; // List<QueryDocumentSnapshot>
  for (final snapshot in queryDocSnapshot) {
    final data = snapshot.data(); // `data()`で中身を取り出す
    // debugPrint("pgname:${data['pgName']}");
    insPgMaster(data['pgNo'], data['pgName'].toString(), data['pgKind'],data['airDtSt'],data['airDtEnd'],data['gengo'] );
  }

}
/*------------------------------------------------------------------
pgMaster登録
 -------------------------------------------------------------------*/
Future<void> insPgMaster(int pgNo, String pgName, int pgKind,int airDtSt,int airDtEnd,int gengo)  async {
  String dbPath = await getDatabasesPath();
  String query = '';
  String path = p.join(dbPath, 'internal_assets.db');
  Database database = await openDatabase(
    path,
    version: 1,
  );
  query =
  'INSERT INTO pgMaster(pgNo,pgName,pgKind,airDtSt,airDtEnd,gengo,kaku1,kaku2,kaku3,kaku4) values($pgNo,"$pgName",$pgKind,$airDtSt,$airDtEnd,$gengo,null,null,null,null) ';
  await database.transaction((txn) async {
    await txn.rawInsert(query);
  });
}
/*------------------------------------------------------------------
volMasterDelete
 -------------------------------------------------------------------*/
Future<void> volMasterDelete() async{
  //PG MasterDrop
  String dbPath = await getDatabasesPath();
  String query = '';
  String path = p.join(dbPath, 'internal_assets.db');
  Database database = await openDatabase(
    path,
    version: 1,
  );
  query = 'Delete from volMaster';
  await database.transaction((txn) async {
    await txn.rawInsert(query);
  });
}
/*------------------------------------------------------------------
pgMaster登録
 -------------------------------------------------------------------*/
Future<void> volMasterINS() async{
  //PG Master登録
  final collectionRef = FirebaseFirestore.instance.collection('volMaster'); // DocumentReference
  final querySnapshot = await collectionRef.get(); // QuerySnapshot
  final queryDocSnapshot = querySnapshot.docs; // List<QueryDocumentSnapshot>
  for (final snapshot in queryDocSnapshot) {
    final data = snapshot.data(); // `data()`で中身を取り出す
     debugPrint("airDt:${data['airDt']}");
    insvolMaster(data['pgNo'],  data['pgKind'],data['vol'] ,data['airDt']);
  }

}
/*------------------------------------------------------------------
pgMaster登録
 -------------------------------------------------------------------*/
Future<void> insvolMaster(int pgNo, int pgKind,int vol,int airDt)  async {
  String dbPath = await getDatabasesPath();
  String query = '';
  String path = p.join(dbPath, 'internal_assets.db');
  Database database = await openDatabase(
    path,
    version: 1,
  );
  query =
  'INSERT INTO volMaster(pgNo,pgKind,vol,airDt,airDt_mvEnd,volNm,kaku1,kaku2,kaku3,kaku4) values($pgNo,$pgKind,$vol,$airDt,null,null,null,null,null,null) ';
  await database.transaction((txn) async {
    await txn.rawInsert(query);
  });
}
/*------------------------------------------------------------------
テスト用ロード処理
 -------------------------------------------------------------------*/
Future<void> testLoad() async{
  mapListtest = <Map>[];
  String dbPath = await getDatabasesPath();
  String path = p.join(dbPath, 'internal_assets.db');
  Database database = await openDatabase(path, version: 1);
  mapListtest =
  await database.rawQuery("SELECT * From pgMaster order by pgNo");
  for(Map item in mapListtest){
    debugPrint("pgName:${item['pgName']}");

  }
  mapListtest =
  await database.rawQuery("SELECT * From volMaster order by pgNo");
  for(Map item in mapListtest){
    debugPrint("pgNo:${item['pgNo']} airDt:${item['airDt']} ");

  }
}
/*------------------------------------------------------------------
main開始
 -------------------------------------------------------------------*/
void main() async {
  //FireBaseのために実装
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  await firstRun();
  await firstFireStoreDBIns();
  await testLoad();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(

        home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen>  {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("test"),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text('You have pushed the button this many times:',),
          ],
        ),
      ),
    );
  }

}
