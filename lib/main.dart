import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import 'dart:io';
import 'package:flutter/services.dart';
import './const.dart';
import './pgDetail.dart';
import './global.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:fluttertoast/fluttertoast.dart';

import 'firestoreUpd.dart';
RewardedAd? _rewardedAd;
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
  DateTime nowDt = new DateTime.now();
  String strSyncDt = '';
  int syncDt = 0;
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
    strSyncDt = '${nowDt.year}${nowDt.month.toString().padLeft(2,'0')}${nowDt.day.toString().padLeft(2,'0')}${nowDt.hour.toString().padLeft(2,'0')}${nowDt.minute.toString().padLeft(2,'0')}';
    syncDt = int.parse(strSyncDt);
    settingUpd(syncDt);
    debugPrint('初回セットsyncDt: $syncDt');

    //FireBaseからデータを登録
   // await firstFireStoreDBIns();
  } else {
    //print("Opening existing database");
  }
}
/*------------------------------------------------------------------
設定テーブルに更新
 -------------------------------------------------------------------*/
Future<void> settingUpd(int syncDt) async {
  String query = "";
  String dbPath = await getDatabasesPath();
  String path = p.join(dbPath, 'internal_assets.db');
  Database database = await openDatabase(path, version: 1);

  query =
  'UPDATE setting set syncdt = $syncDt ';
  await database.transaction((txn) async {
    await txn.rawInsert(query);
  });
}
/*------------------------------------------------------------------
FireStore初回登録
 -------------------------------------------------------------------*/
Future<void> firstFireStoreDBUpd(int fireStoreSyncDt) async {
  //PG MasterからSyncDtを基準に対象データ更新
  await getSyncPgMaster(fireStoreSyncDt);



  await getSyncVolMaster(fireStoreSyncDt);

}
/*------------------------------------------------------------------
PG MasterからSyncDtを基準に対象データを取得
 -------------------------------------------------------------------*/
Future<void> getSyncPgMaster(int fireStoreSyncDt) async{
  debugPrint('FireStoreから同時日時を取得');
  //FireStoreから同時日時を取得
  final query =
  FirebaseFirestore.instance.collection('pgMaster').where('syncDt',isGreaterThanOrEqualTo: fireStoreSyncDt); // DocumentReference
  int intpgNo = 0;
  bool updFlg = false;
  final querySnapshot = await query.get(); // QuerySnapshot

  //volMaster
  // await volMasterINS();
  final queryDocSnapshot = querySnapshot.docs; // List<QueryDocumentSnapshot>
  for (final snapshot in queryDocSnapshot) {
    final data = snapshot.data(); // `data()`で中身を取り出す
    intpgNo = data['pgNo'];
    debugPrint('SyncDtを順に対象データ取得:${intpgNo.toString()}');
    //対象データをSelect
    updFlg = await pgMasterSelect(data['pgNo']);
    debugPrint('updFlg:$updFlg');
    //存在する場合、UPD
    if(updFlg) {
      pgMasterUpd(data['pgNo'],data['pgName'],data['gengo'],data['pgKind'],data['airDtSt'],data['airDtEnd'],data['syncDt'],data['delFlg']);
    }else {
      //存在しない場合、INS
      pgMasterIns(data['pgNo'],data['pgName'],data['gengo'],data['pgKind'],data['airDtSt'],data['airDtEnd'],data['syncDt'],data['delFlg']);
    }
  }
}
/*------------------------------------------------------------------
対象データをSelect
 -------------------------------------------------------------------*/
Future<bool> pgMasterSelect(int pgNo) async{
  bool flg = false;
  List<Map> mapPgMaster = <Map>[];
  String dbPath = await getDatabasesPath();
  String query = '';
  String path = p.join(dbPath, 'internal_assets.db');
  Database database = await openDatabase(path, version: 1,);

  query = 'Select pgNo from pgMaster where pgNo = $pgNo';
  mapPgMaster = await database.rawQuery(query);
  for (Map item in mapPgMaster) {
    flg = true;
  }
  return flg;
}
/*------------------------------------------------------------------
pgMasterUpd
 -------------------------------------------------------------------*/
Future<void> pgMasterUpd(int pgNo, String pgName, int gengo,int pgKind, int airDtSt, int airDtEnd, int syncDt,int delFlg) async {
  String dbPath = await getDatabasesPath();
  String query = '';
  String path = p.join(dbPath, 'internal_assets.db');
  Database database = await openDatabase(path, version: 1,);
  debugPrint('pgName更新:$pgName');
  query = 'Update pgMaster set pgName = "$pgName",gengo = $gengo,pgKind = $pgKind,airDtSt = $airDtSt,airDtEnd = $airDtEnd,syncDt = $syncDt,delFlg = $delFlg where pgNo = $pgNo';
  await database.transaction((txn) async {
    await txn.rawInsert(query);
  });
}

/*------------------------------------------------------------------
pgMaster登録
 -------------------------------------------------------------------*/
Future<void> pgMasterIns(int pgNo, String pgName, int gengo,int pgKind, int airDtSt, int airDtEnd, int syncDt,int delFlg)  async {
  String dbPath = await getDatabasesPath();
  String query = '';
  String path = p.join(dbPath, 'internal_assets.db');
  Database database = await openDatabase(
    path,
    version: 1,
  );
  query =
  'INSERT INTO pgMaster(pgNo,pgName,gengo,pgKind,airDtSt,airDtEnd,syncDt,delFlg, kaku1,kaku2,kaku3,kaku4) values($pgNo,"$pgName",$gengo,$pgKind,$airDtSt,$airDtEnd,$syncDt,$delFlg,null,null,null,null) ';
  await database.transaction((txn) async {
    await txn.rawInsert(query);
  });
}
/*------------------------------------------------------------------
Vol MasterからSyncDtを基準に対象データを取得
 -------------------------------------------------------------------*/
Future<void> getSyncVolMaster(int fireStoreSyncDt) async{
  debugPrint('volMaster:FireStoreから同時日時を取得');
  //FireStoreから同時日時を取得
  final query =
  FirebaseFirestore.instance.collection('volMaster').where('syncDt',isGreaterThanOrEqualTo: fireStoreSyncDt); // DocumentReference
  int intpgNo = 0;int intVol = 0;bool updFlg = false;

  final querySnapshot = await query.get(); // QuerySnapshot
  final queryDocSnapshot = querySnapshot.docs; // List<QueryDocumentSnapshot>
  for (final snapshot in queryDocSnapshot) {
    final data = snapshot.data(); // `data()`で中身を取り出す
    intpgNo = data['pgNo'];
    intVol = data['vol'];

    //対象データをSelect
    updFlg = await volMasterSelect(intpgNo,intVol);
    debugPrint('updFlg:$updFlg');
    //存在する場合、UPD
    if(updFlg) {
      volMasterUpd(data['pgNo'],data['vol'],data['pgKind'],data['airDt'],data['airDt_mvEnd'],data['volNm'],data['syncDt'],data['delFlg']);
    }else {
      //存在しない場合、INS
      volMasterIns(data['pgNo'],data['vol'],data['pgKind'],data['airDt'],data['airDt_mvEnd'],data['volNm'],data['syncDt'],data['delFlg']);
    }
  }
}
/*------------------------------------------------------------------
対象データをSelect
 -------------------------------------------------------------------*/
Future<bool> volMasterSelect(int pgNo,int vol) async{
  bool flg = false;
  List<Map> mapVolMaster = <Map>[];
  String dbPath = await getDatabasesPath();
  String query = '';
  String path = p.join(dbPath, 'internal_assets.db');
  Database database = await openDatabase(path, version: 1,);

  query = 'Select pgNo , vol from volMaster where pgNo = $pgNo and vol = $vol';
  mapVolMaster = await database.rawQuery(query);
  for (Map item in mapVolMaster) {
    flg = true;
  }
  return flg;
}
/*------------------------------------------------------------------
pgMasterUpd
 -------------------------------------------------------------------*/
Future<void> volMasterUpd(int pgNo, int vol, int pgKind, int airDt, int airDt_mvEnd, String volNm ,int syncDt,int delFlg) async {
  String dbPath = await getDatabasesPath();
  String query = '';
  String path = p.join(dbPath, 'internal_assets.db');
  Database database = await openDatabase(path, version: 1,);
  query = 'Update volMaster set pgKind = $pgKind,airDt = $airDt,pgKind = $pgKind,airDt = $airDt,airDt_mvEnd = $airDt_mvEnd,volNm = "$volNm" ,syncDt = $syncDt,delFlg = $delFlg where pgNo = $pgNo and vol = $vol';
  await database.transaction((txn) async {
    await txn.rawInsert(query);
  });
}

/*------------------------------------------------------------------
pgMaster登録
 -------------------------------------------------------------------*/
Future<void> volMasterIns(int pgNo, int vol, int pgKind, int airDt, int airDt_mvEnd, String volNm ,int syncDt,int delFlg)   async {
  String dbPath = await getDatabasesPath();
  String query = '';
  String path = p.join(dbPath, 'internal_assets.db');
  Database database = await openDatabase(
    path,
    version: 1,
  );
  query =
  'INSERT INTO volMaster(pgNo,vol,pgKind,airDt,airDt_mvEnd,volNm,syncDt,delFlg, kaku1,kaku2,kaku3,kaku4) values($pgNo,$vol,$pgKind,$airDt,$airDt_mvEnd,"$volNm",$syncDt,$delFlg,null,null,null,null) ';
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

  runApp(MyApp());
}
class MyApp extends StatelessWidget {
  MyApp({super.key});
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: const MainScreen(),
      theme: ThemeData(
        fontFamily: 'Kosugi',
      ),
    );
  }
}
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});
  @override
  State<MainScreen> createState() => _MainScreenState();
}
class _MainScreenState extends State<MainScreen> {
  int _numRewardedLoadAttempts = 0;
  @override
  void initState() {
    super.initState();

    init();
    _createRewardedAd();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text("仮面ライダー作品一覧", style: const TextStyle(fontSize: 30.0, color: Colors.white,),),
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
            Text("　　放映期間　　　作品名",
              style: const TextStyle(fontSize: 15.0, color: Colors.white,),),

            Expanded(
                child: ListView(
                  children: itemsPgList,
                )),
            Divider(color: Colors.white, thickness: 2,),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            ElevatedButton(onPressed:()async{syncDB();}, style: ElevatedButton.styleFrom(backgroundColor:Colors.red ), child: Text('最新情報と同期'),),
          ],),
          ],
        ),
      ),
    );
  }

  /*------------------------------------------------------------------
同期ボタン
 -------------------------------------------------------------------*/
  Future<void> syncDB() async {
   int  syncDtFirestore = 0;
   //settingテーブル再取得

   syncDtFirestore = await getSyncFireStore();
   syncDtLocal = await getSettingSync();

   debugPrint('syncDtFirestore: $syncDtFirestore');
   debugPrint('syncDtLocal: $syncDtLocal');

   //最新チェック
   syncDtFirestore = await getSyncFireStore();
    if(syncDtLocal < syncDtFirestore) {
      //最新がある旨のダイアログを出す
      confirmMovieDialog(syncDtFirestore);

    }else{
      //最新が無い旨のダイアログを出す
      noSyncDialog();
    }
  }

  /*------------------------------------------------------------------
設定テーブルからロード
 -------------------------------------------------------------------*/
  Future<int> getSettingSync() async {
    int syncDtLocal = 0;
    String dbPath = await getDatabasesPath();
    String path = p.join(dbPath, 'internal_assets.db');
    Database database = await openDatabase(path, version: 1);
    mapSetting = await database.rawQuery("SELECT syncdt From setting ");
    for (Map item in mapSetting) {
      syncDtLocal = item['syncdt'];
     }
    return syncDtLocal;
  }

  /*------------------------------------------------------------------
動画確認ボタン
 -------------------------------------------------------------------*/
  Future<void> confirmMovieDialog(int syncDtFirestore) async {
    final formKey = GlobalKey<FormState>();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('新しい情報に同期'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text("最新情報があります。更新しますか？(動画視聴1回で更新できます)"),
                ],
              ),
            ),
          ),
          actions: <Widget>[
            ElevatedButton(
              child: Text('動画視聴して同期'),
              onPressed: () async {
                await _showRewardedAd();
                await firstFireStoreDBUpd(syncDtFirestore);
                await settingUpd(syncDtFirestore);
                await loadList();
                await getItems();
            //    await syncComp();
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
                child: Text('キャンセル'),
                onPressed: () {
                  Navigator.of(context).pop();
                }),
          ],
        );
      },
    );
  }
  /*------------------------------------------------------------------
動画確認ボタン
 -------------------------------------------------------------------*/
  Future<void> noSyncDialog() async {
    final formKey = GlobalKey<FormState>();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('確認結果'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text("最新情報はありませんでした。"),
                ],
              ),
            ),
          ),
          actions: <Widget>[
            ElevatedButton(
                child: Text('OK'),
                onPressed: () {
                  Navigator.of(context).pop();
                }),
          ],
        );
      },
    );
  }
  /*------------------------------------------------------------------
動画確認ボタン
 -------------------------------------------------------------------*/
  Future<void> syncComp() async {
    final formKey = GlobalKey<FormState>();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('同期完了'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text("最新情報に更新しました。"),
                ],
              ),
            ),
          ),
          actions: <Widget>[
            ElevatedButton(
                child: Text('OK'),
                onPressed: () {
                  Navigator.of(context).pop();
                }),
          ],
        );
      },
    );
  }
  /*------------------------------------------------------------------
同期ボタン
 -------------------------------------------------------------------*/
  Future<int> getSyncFireStore() async {
    int syncDtFirestore = 0;

    //FireStoreから同時日時を取得
    final collectionRef =
    FirebaseFirestore.instance.collection('sync'); // DocumentReference
    final querySnapshot = await collectionRef.get(); // QuerySnapshot
    final queryDocSnapshot = querySnapshot.docs; // List<QueryDocumentSnapshot>
    for (final snapshot in queryDocSnapshot) {
      final data = snapshot.data(); // `data()`で中身を取り出す
      syncDtFirestore = data['syncdt'];
    }

    return syncDtFirestore;
  }

  /*------------------------------------------------------------------
動画準備
 -------------------------------------------------------------------*/
  void _createRewardedAd() {
    RewardedAd.load(
        adUnitId: strCnsRewardID,
        request: const AdRequest(),
        rewardedAdLoadCallback: RewardedAdLoadCallback(
          onAdLoaded: (RewardedAd ad) {
            print('$ad loaded.');
            _rewardedAd = ad;
            _numRewardedLoadAttempts = 0;
          },
          onAdFailedToLoad: (LoadAdError error) {
            print('RewardedAd failed to load: $error');
            _rewardedAd = null;
            _numRewardedLoadAttempts += 1;
            if (_numRewardedLoadAttempts < maxFailedLoadAttempts) {
              _createRewardedAd();
            }
          },
        ));
  }
  /*------------------------------------------------------------------
動画実行
 -------------------------------------------------------------------*/
  Future<void> _showRewardedAd() async {
    _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (RewardedAd ad) =>
          print('ad onAdShowedFullScreenContent.'),
      onAdDismissedFullScreenContent: (RewardedAd ad) {
        print('$ad onAdDismissedFullScreenContent.');
        ad.dispose();
        _createRewardedAd();
      },
      onAdFailedToShowFullScreenContent: (RewardedAd ad, AdError error) {
        print('$ad onAdFailedToShowFullScreenContent: $error');
        ad.dispose();
        _createRewardedAd();
      },
    );
    _rewardedAd!.setImmersiveMode(true);
    _rewardedAd!.show(
        onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
          print('$ad with reward $RewardItem(${reward.amount}, ${reward.type})');
        });
    _rewardedAd = null;
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

    int showa = 0;int heisei = 0;int reiwa = 0;
    int tv = 0;int movie = 0;int vshine = 0;int other = 0;

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
       syncDtLocal = item['syncdt'];
       gengoShowaFlg = (item['showa'] == 1)?true:false;
       gengoHeiseiFlg = (item['heisei'] == 1)?true:false;
       gengoReiwaFlg = (item['reiwa'] == 1)?true:false;

       pgKindTVFlg = (item['tv'] == 1)?true:false;
       pgKindMVFlg = (item['movie'] == 1)?true:false;
       pgKindVSFlg = (item['vshine'] == 1)?true:false;
       pgKindOTHERFlg = (item['other'] == 1)?true:false;
       pg_otherFlg = (item['pg_other'] == 1)?true:false;

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

    mapPgList = await database.rawQuery("SELECT * From pgMaster where gengo in $strWheregengo and pgKind in $strWherePgKind and delFlg = 0 order by pgNo");
  }

  /*------------------------------------------------------------------
ListViewを作成する
 -------------------------------------------------------------------*/
  Future<void> getItems() async {
    List<Widget> list = <Widget>[];
    int albumNo = 0;
    String strAirDtSt = "";
    String strAirDtEnd = "";
    double pgNameFont = 18;
    //Divider(color: Colors.white, thickness: 1),

    for (Map item in mapPgList) {
       strAirDtSt = await getDtFormat(item['airDtSt'].toString());
       strAirDtEnd = await getDtFormat(item['airDtEnd'].toString());
       if(item['pgName'].toString().length <= 10){
         pgNameFont = 18;
       }else{
         pgNameFont = 14;
       }
      list.add(
        Card(
          color: Colors.black26,
          margin: EdgeInsets.fromLTRB(0, 0, 0, 0),
          shape: RoundedRectangleBorder(
          //  borderRadius: BorderRadius.circular(15),
          //  side: BorderSide(color: Colors.purple, width: 1), // 枠線の色を設定
          ),
          child: ListTile(
            title:
            Row(
              children: <Widget>[
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text('$strAirDtSt～', style: TextStyle(color: Colors.white, fontSize: 11),),
                    Text('$strAirDtEnd', style: TextStyle(color: Colors.white, fontSize: 11),),
               ],
                ),
            Text('   ${item['pgName']}', overflow: TextOverflow.clip ,maxLines: 2,style: TextStyle(color: Colors.white, fontSize: pgNameFont),),
              ],
            ),
            selected: albumNo == item['pgNo'],
            // tileColor: const Color(0xFFF5F5DC),
            onTap: () {
              //albumNo = item['albumNo'];
              _tapTile(item['pgNo'], item['pgName'].toString(),item['airDtSt'],item['airDtEnd']);
            },
          ),
        ),
      );
    }
    setState(() {
      itemsPgList = list;
    });
  }

  void _tapTile(int pgNo, String pgName,int airDtSt,int airDtEnd) async {
        Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => pgDetailScreen(pgNo,pgName,airDtSt,airDtEnd),
            ));
  }
}
