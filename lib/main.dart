import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import 'dart:io';
import 'package:flutter/services.dart';

List<Map> mapPgList = <Map>[];
List<Widget> itemsPgList = <Widget>[];
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
    List<int> bytes =
        data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
    // Write and flush the bytes written
    await File(path).writeAsBytes(bytes, flush: true);
  } else {
    //print("Opening existing database");
  }
}

/*------------------------------------------------------------------
FireStore初回登録
 -------------------------------------------------------------------*/
Future<void> firstFireStoreDBIns() async {
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
Future<void> pgMasterDelete() async {
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
Future<void> pgMasterINS() async {
  //PG Master登録
  final collectionRef =
      FirebaseFirestore.instance.collection('riderMaster'); // DocumentReference
  final querySnapshot = await collectionRef.get(); // QuerySnapshot
  final queryDocSnapshot = querySnapshot.docs; // List<QueryDocumentSnapshot>
  for (final snapshot in queryDocSnapshot) {
    final data = snapshot.data(); // `data()`で中身を取り出す
    // debugPrint("pgname:${data['pgName']}");
    insPgMaster(data['pgNo'], data['pgName'].toString(), data['pgKind'],
        data['airDtSt'], data['airDtEnd'], data['gengo']);
  }
}

/*------------------------------------------------------------------
pgMaster登録
 -------------------------------------------------------------------*/
Future<void> insPgMaster(int pgNo, String pgName, int pgKind, int airDtSt,
    int airDtEnd, int gengo) async {
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
Future<void> volMasterDelete() async {
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
Future<void> volMasterINS() async {
  //PG Master登録
  final collectionRef =
      FirebaseFirestore.instance.collection('volMaster'); // DocumentReference
  final querySnapshot = await collectionRef.get(); // QuerySnapshot
  final queryDocSnapshot = querySnapshot.docs; // List<QueryDocumentSnapshot>
  for (final snapshot in queryDocSnapshot) {
    final data = snapshot.data(); // `data()`で中身を取り出す
    debugPrint("airDt:${data['airDt']}");
    insvolMaster(data['pgNo'], data['pgKind'], data['vol'], data['airDt']);
  }
}

/*------------------------------------------------------------------
pgMaster登録
 -------------------------------------------------------------------*/
Future<void> insvolMaster(int pgNo, int pgKind, int vol, int airDt) async {
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
main開始
 -------------------------------------------------------------------*/
void main() async {
  //FireBaseのために実装
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  await firstRun();
  await firstFireStoreDBIns();
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

class _MainScreenState extends State<MainScreen> {
  @override
  void initState() {
    super.initState();
    init();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          "仮面ライダー番組一覧",
          style: const TextStyle(
            fontSize: 30.0,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.black,
      ),
      body: Container(
        constraints: BoxConstraints(
          minWidth: double.infinity,
          minHeight: double.infinity,
        ),
        decoration: BoxDecoration(
          color: Colors.black,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            ElevatedButton(
              onPressed: () {
                // ボタンが押された時の処理
              },
              child: Text('ボタン'),
            ),
            ElevatedButton(
              onPressed: () {
                // ボタンが押された時の処理
              },
              child: Text('ボタン2'),
            ),

            Divider(
              color: Colors.white,
              thickness: 2,
            ),
            Text("公開日　　　番組名", style: const TextStyle(fontSize: 15.0, color: Colors.white,),),

            //   SingleChildScrollView(
            //  child: Column(
            //    children: <Widget>[
            Expanded(
                child: ListView(
              children: itemsPgList,
            )),
            //     ...itemsPgList
            //  ],
            //    ),
            //  ),
          ],
        ),
      ),
    );
  }

  /*------------------------------------------------------------------
初期処理
 -------------------------------------------------------------------*/
  Future<void> init() async {
    await loadList();
    await getItems();
  }

  /*------------------------------------------------------------------
pgMasterからロード
 -------------------------------------------------------------------*/
  Future<void> loadList() async {
    String dbPath = await getDatabasesPath();
    String path = p.join(dbPath, 'internal_assets.db');
    Database database = await openDatabase(path, version: 1);
    mapPgList = await database.rawQuery("SELECT * From pgMaster order by pgNo");
  }

  /*------------------------------------------------------------------
ListViewを作成する
 -------------------------------------------------------------------*/
  Future<void> getItems() async {
    List<Widget> list = <Widget>[];
    int albumNo = 0;
//最初の1行目はタイトル
//     list.add(
//       Card(
//         color: Colors.black,
//         margin: const EdgeInsets.fromLTRB(15, 0, 15, 15),
//         shape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.circular(15),
//         ),
//         child: ListTile(
//           title: Text(
//             '公開日',
//             style: TextStyle(
//               fontSize: 18.0,
//               fontWeight: FontWeight.bold,
//             ),
//           ),
//           subtitle: Text(
//             '番組名',
//             style: TextStyle(
//               fontSize: 16.0,
//               fontWeight: FontWeight.bold,
//             ),
//           ),
//         ),
//       ),
//     );

    //Divider(color: Colors.white, thickness: 1),

    for (Map item in mapPgList) {
      list.add(
        Card(
          color: Colors.black,
          margin: const EdgeInsets.fromLTRB(15, 0, 15, 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(5),
            title: Text(
              '${item['airDtSt']}   ${item['pgName']}  ',
              style: TextStyle(color: Colors.white, fontSize: 10),
            ),
            selected: albumNo == item['pgNo'],
            // tileColor: const Color(0xFFF5F5DC),
            onTap: () {
              //albumNo = item['albumNo'];
              _tapTile(item['pgNo'], item['pgName'].toString());
            },
          ),
        ),
      );
    }
    setState(() {
      itemsPgList = list;
    });
  }

  void _tapTile(int albumNo, String albumName) async {
    //   Navigator.push(
    //       context,
    //       MaterialPageRoute(
    //         builder: (context) => ListGalleryScreen(albumNo,albumName),
    //       ));
  }
}
