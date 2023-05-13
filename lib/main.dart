import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import 'dart:io';
import 'package:flutter/services.dart';
import './const.dart';

List<Map> mapPgList = <Map>[];
List<Map> mapSetting = <Map>[];
List<Widget> itemsPgList = <Widget>[];
int syncDt = 0;
bool gengoShowaFlg = true;
bool gengoHeiseiFlg = true;
bool gengoReiwaFlg = true;

bool pgKindTVFlg = true;
bool pgKindMVFlg = true;
bool pgKindVSFlg = true;
bool pgKindOTHERFlg = true;

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
            Divider(color: Colors.white, thickness: 2,),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                ElevatedButton(onPressed: ()async{changeGengoPgList(cnsGengoShowa);}, style: ElevatedButton.styleFrom(backgroundColor: gengoShowaFlg ? Colors.blue : Colors.black,), child: Text('昭和')),
                ElevatedButton(onPressed: ()async{changeGengoPgList(cnsGengoHeisei);}, style: ElevatedButton.styleFrom(backgroundColor: gengoHeiseiFlg ? Colors.blue : Colors.black,),child: Text('平成')),
                ElevatedButton(onPressed: ()async{changeGengoPgList(cnsGengoRaiwa);},style: ElevatedButton.styleFrom(backgroundColor: gengoReiwaFlg ? Colors.blue : Colors.black,), child: Text('令和')),
              ],),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            ElevatedButton(onPressed: ()async{changepgKindPgList(cnsPgKindTV);}, style: ElevatedButton.styleFrom(backgroundColor: pgKindTVFlg ? Colors.orange : Colors.black,), child: Text('TV'),),
            ElevatedButton(onPressed: ()async{changepgKindPgList(cnsPgKindMV);}, style: ElevatedButton.styleFrom(backgroundColor: pgKindMVFlg ? Colors.orange : Colors.black,),  child: Text('映画'),),
            ElevatedButton(onPressed: ()async{changepgKindPgList(cnsPgKindVS);}, style: ElevatedButton.styleFrom(backgroundColor: pgKindVSFlg ? Colors.orange : Colors.black,), child: Text('Vシネ'),),
            ElevatedButton(onPressed: ()async{changepgKindPgList(cnsPgKindOTHERS);}, style: ElevatedButton.styleFrom(backgroundColor: pgKindOTHERFlg ? Colors.orange : Colors.black,), child: Text('その他'),),

          ],),
            Divider(color: Colors.white, thickness: 2,),
            Text("　　　公開日　　　番組名",
              style: const TextStyle(fontSize: 15.0, color: Colors.white,),),

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
元号変更
 -------------------------------------------------------------------*/
  Future<void> changeGengoPgList(int gengo) async {
    switch (gengo) {
      case cnsGengoShowa:
        gengoShowaFlg = !gengoShowaFlg;
        break;
      case cnsGengoHeisei:
        gengoHeiseiFlg = !gengoHeiseiFlg;
        break;
      case cnsGengoRaiwa:
        gengoReiwaFlg = !gengoReiwaFlg;
        break;
      default:
      // 上記のいずれのケースにも該当しない場合の処理
    }
    await updSettingGengoPgkind();
    await loadList();
    await getItems();
  }
  /*------------------------------------------------------------------
設定テーブルに更新
 -------------------------------------------------------------------*/
  Future<void> updSettingGengoPgkind() async {
    String query = "";
    String dbPath = await getDatabasesPath();
    String path = p.join(dbPath, 'internal_assets.db');
    Database database = await openDatabase(path, version: 1);

    int showa = 0;
    int heisei = 0;
    int reiwa = 0;
    int tv = 0;
    int movie = 0;
    int vshine = 0;
    int other = 0;

    showa = gengoShowaFlg?BtFlgOn:BtFlgOff;
    heisei = gengoHeiseiFlg?BtFlgOn:BtFlgOff;
    reiwa = gengoReiwaFlg?BtFlgOn:BtFlgOff;

    tv = pgKindTVFlg?BtFlgOn:BtFlgOff;
    movie = pgKindMVFlg?BtFlgOn:BtFlgOff;
    vshine = pgKindVSFlg?BtFlgOn:BtFlgOff;
    other = pgKindOTHERFlg?BtFlgOn:BtFlgOff;

    query =
    'UPDATE setting set showa = $showa ,heisei = $heisei ,reiwa = $reiwa ,tv = $tv ,movie = $movie ,vshine = $vshine ,other = $other  ';
    await database.transaction((txn) async {
      await txn.rawInsert(query);
    });


  }
  /*------------------------------------------------------------------
放映種類変更
 -------------------------------------------------------------------*/
  Future<void> changepgKindPgList(int pgKind) async {
    switch (pgKind) {
      case cnsPgKindTV:
        pgKindTVFlg = !pgKindTVFlg;
        break;
      case cnsPgKindMV:
        pgKindMVFlg = !pgKindMVFlg;
        break;
      case cnsPgKindVS:
        pgKindVSFlg = !pgKindVSFlg;
        break;
      case cnsPgKindOTHERS:
        pgKindOTHERFlg = !pgKindOTHERFlg;
        break;
      default:
      // 上記のいずれのケースにも該当しない場合の処理
    }
    await updSettingGengoPgkind();
    await loadList();
    await getItems();
  }
  /*------------------------------------------------------------------
pgMasterからロード
 -------------------------------------------------------------------*/
  Future<void> loadSelGengoList() async {
    String dbPath = await getDatabasesPath();
    String path = p.join(dbPath, 'internal_assets.db');
    Database database = await openDatabase(path, version: 1);
    mapPgList = await database.rawQuery("SELECT * From pgMaster order by pgNo");
  }


  /*------------------------------------------------------------------
初期処理
 -------------------------------------------------------------------*/
  Future<void> init() async {
    await getSetting();
    await loadList();
    await getItems();
  }
  /*------------------------------------------------------------------
設定テーブルからロード
 -------------------------------------------------------------------*/
  Future<void> getSetting() async {
    String dbPath = await getDatabasesPath();
    String path = p.join(dbPath, 'internal_assets.db');
    Database database = await openDatabase(path, version: 1);
    mapSetting = await database.rawQuery("SELECT * From setting ");
    for (Map item in mapSetting) {
       syncDt = item['syncdt'];
       gengoShowaFlg = (item['showa'] == 1)?true:false;
       gengoHeiseiFlg = (item['heisei'] == 1)?true:false;
       gengoReiwaFlg = (item['reiwa'] == 1)?true:false;

       pgKindTVFlg = (item['tv'] == 1)?true:false;
       pgKindMVFlg = (item['movie'] == 1)?true:false;
       pgKindVSFlg = (item['vshine'] == 1)?true:false;
       pgKindOTHERFlg = (item['other'] == 1)?true:false;

       debugPrint('syncdt: ${item['syncdt']} showa:${item['showa']} heisei:${item['heisei']} reiwa:${item['reiwa']} tv:${item['tv']} movie:${item['movie']} vshine:${item['vshine']} other:${item['other']}');
    }

  }
  /*------------------------------------------------------------------
pgMasterからロード
 -------------------------------------------------------------------*/
  Future<void> loadList() async {
    String strWheregengo = "(";
    String strWherePgKind = "(";
    bool Continue = false;
    String dbPath = await getDatabasesPath();
    String path = p.join(dbPath, 'internal_assets.db');
    Database database = await openDatabase(path, version: 1);

    //元号Where条件編集
    if(gengoShowaFlg) {
      strWheregengo = strWheregengo + cnsGengoShowa.toString();
      Continue = true;
    }
    if(gengoHeiseiFlg) {
      if (Continue) {
        strWheregengo = strWheregengo + ',' + cnsGengoHeisei.toString();
      }else{
        strWheregengo = strWheregengo + cnsGengoHeisei.toString();
      }
      Continue = true;
    }
    if(gengoReiwaFlg) {
      if (Continue) {
        strWheregengo = strWheregengo + ',' + cnsGengoRaiwa.toString();
      }else{
        strWheregengo = strWheregengo + cnsGengoRaiwa.toString();
      }
      Continue = true;
    }
    if(Continue){
      strWheregengo = strWheregengo + ')';
    }else{
      strWheregengo = '(0)';
    }

    //放送種類条件編集
    Continue = false;
    if(pgKindTVFlg) {
      strWherePgKind = strWherePgKind + cnsPgKindTV.toString();
      Continue = true;
    }
    if(pgKindMVFlg) {
      if (Continue) {
        strWherePgKind = strWherePgKind + ',' + cnsPgKindMV.toString();
      }else{
        strWherePgKind = strWherePgKind + cnsPgKindMV.toString();
      }
      Continue = true;
    }
    if(pgKindVSFlg) {
      if (Continue) {
        strWherePgKind = strWherePgKind + ',' + cnsPgKindVS.toString();
      }else{
        strWherePgKind = strWherePgKind + cnsPgKindVS.toString();
      }
      Continue = true;
    }
    if(pgKindOTHERFlg) {
      if (Continue) {
        strWherePgKind = strWherePgKind + ',' + cnsPgKindOTHERS.toString();
      }else{
        strWherePgKind = strWherePgKind + cnsPgKindOTHERS.toString();
      }
      Continue = true;
    }
    if(Continue){
      strWherePgKind = strWherePgKind + ')';
    }else{
      strWherePgKind = '(0)';
    }

    debugPrint('strWheregengo:$strWheregengo');
    debugPrint('strWherePgKind:$strWherePgKind');

    mapPgList = await database.rawQuery("SELECT * From pgMaster where gengo in $strWheregengo and pgKind in $strWherePgKind order by pgNo");
  }

  /*------------------------------------------------------------------
ListViewを作成する
 -------------------------------------------------------------------*/
  Future<void> getItems() async {
    List<Widget> list = <Widget>[];
    int albumNo = 0;
    String strAirDt = "";
    //Divider(color: Colors.white, thickness: 1),

    for (Map item in mapPgList) {
       strAirDt = '${item['airDtSt'].toString().substring(0,4)}年${item['airDtSt'].toString().substring(4,6)}月${item['airDtSt'].toString().substring(6,8)}日 ';
      list.add(
        Card(
          color: Colors.black26,
        //  margin: const EdgeInsets.fromLTRB(15, 0, 15, 15),
          shape: RoundedRectangleBorder(
          //  borderRadius: BorderRadius.circular(15),
          //  side: BorderSide(color: Colors.purple, width: 1), // 枠線の色を設定
          ),
          child: ListTile(
            title:
            Row(
              children: <Widget>[
                Text('$strAirDt', style: TextStyle(color: Colors.white, fontSize: 12),),
                Text('   ${item['pgName']}', style: TextStyle(color: Colors.white, fontSize: 20),),
              ],
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

  void _tapTile(int pgNo, String pgName) async {
       // Navigator.push(
       //     context,
       //     MaterialPageRoute(
       //       builder: (context) => pgDetailScreen(pgNo,pgName),
       //     ));
  }
}
