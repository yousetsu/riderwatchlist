import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import './global.dart';
import './const.dart';
List<Widget> pgDetailList = <Widget>[];

class pgDetailScreen extends StatefulWidget {
  int pgNo;
  String pgName;
  int airDtSt;
  int airDtEnd;

  pgDetailScreen(this.pgNo, this.pgName, this.airDtSt, this.airDtEnd);

  @override
  State<pgDetailScreen> createState() =>
      _pgDetailScreenState(this.pgNo, this.pgName, this.airDtSt, this.airDtEnd);
}

class _pgDetailScreenState extends State<pgDetailScreen> {
  int pgNo;
  String pgName;
  int airDtSt;
  int airDtEnd;

  _pgDetailScreenState(this.pgNo, this.pgName, this.airDtSt, this.airDtEnd);

  //変数の宣言
  List<Map> mapPgDetailList = <Map>[];
  String strAirDtSt = '';
  String strAirDtEnd = '';

  @override
  void initState() {
    super.initState();
    load();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Text(pgName, style: const TextStyle(fontSize: 20.0, color: Colors.white,),),
            SizedBox(height: 10),
            Text('($strAirDtSt～$strAirDtEnd)', style: const TextStyle(fontSize: 13.0, color: Colors.white,),),
          ],
        ),
        backgroundColor: Colors.black,
        elevation: 0,
        // ステータスバーのテキスト色を明るくする
        iconTheme: IconThemeData(color: Colors.white),
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
                ElevatedButton(onPressed: ()async{chgPgKindDetail(cnsPgKindTV);}, style: ElevatedButton.styleFrom(backgroundColor: pgKindTVFlg ? Colors.orange : Colors.black,), child: Text('TV'),),
                ElevatedButton(onPressed: ()async{chgPgKindDetail(cnsPgKindMV);}, style: ElevatedButton.styleFrom(backgroundColor: pgKindMVFlg ? Colors.orange : Colors.black,),  child: Text('映画'),),
                ElevatedButton(onPressed: ()async{chgPgKindDetail(cnsPgKindVS);}, style: ElevatedButton.styleFrom(backgroundColor: pgKindVSFlg ? Colors.orange : Colors.black,), child: Text('Vシネ'),),
                ElevatedButton(onPressed: ()async{chgPgKindDetail(cnsPgKindOTHERS);}, style: ElevatedButton.styleFrom(backgroundColor: pgKindOTHERFlg ? Colors.orange : Colors.black,), child: Text('その他'),),
              ],),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            ElevatedButton(onPressed: ()async{chgPgOtherDetail();}, style: ElevatedButton.styleFrom(backgroundColor: pg_otherFlg ? Colors.green : Colors.grey,), child: Text('放映期間中、他ライダー作品の表示'),),
          ],),
            Divider(color: Colors.white, thickness: 2,),
            Text("　　　　公開日　　　　作品名・話数",
              style: const TextStyle(fontSize: 15.0, color: Colors.white,),),
            Expanded(
                child: ListView(
                  children: pgDetailList,
                )),
          ],
        ),
      ),

    );
  }

  /*------------------------------------------------------------------
  ロード処理
 -------------------------------------------------------------------*/
  Future<void> load() async {
    strAirDtSt = await getDtFormat(airDtSt.toString());
    strAirDtEnd = await getDtFormat(airDtEnd.toString());
    await getPgDetail();
    await getItems();
  }
  /*------------------------------------------------------------------
  ロード処理
 -------------------------------------------------------------------*/
  Future<void> getPgDetail() async {
    String strWherePgKind = "(";
    bool Continue = false;
    String dbPath = await getDatabasesPath();
    String path = p.join(dbPath, 'internal_assets.db');
    Database database = await openDatabase(path, version: 1,);
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
        strWherePgKind = strWherePgKind + ',' + wherePgKindOTHERS.toString();
      }else{
        strWherePgKind = strWherePgKind + wherePgKindOTHERS.toString();
      }
      Continue = true;
    }
    if(Continue){
      strWherePgKind = strWherePgKind + ')';
    }else{
      strWherePgKind = '(0)';
    }
    if(pg_otherFlg == false) {
      mapPgDetailList = await database.rawQuery(
          "SELECT A.pgNo , B.pgName ,A.vol ,A.pgKind ,A.airDt, A.volNm from volMaster A LEFT outer JOIN pgMaster B on A.pgNo = B.pgNo where A.pgNo = $pgNo and A.pgKind in $strWherePgKind and A.delFlg = 0 order by A.airDt ,A.pgKind");
    }else{
      //放映期間中、他ライダー作品も表示する
      mapPgDetailList = await database.rawQuery(
          "SELECT A.pgNo , B.pgName ,A.vol ,A.pgKind ,A.airDt , A.volNm from volMaster A LEFT outer JOIN pgMaster B on A.pgNo = B.pgNo where A.pgNo = $pgNo and A.pgKind in $strWherePgKind and A.delFlg = 0 UNION SELECT A.pgNo , B.pgName ,A.vol ,A.pgKind ,A.airDt , A.volNm from volMaster A LEFT outer JOIN pgMaster B on A.pgNo = B.pgNo where A.pgKind in $strWherePgKind and A.airDt >= $airDtSt and A.airDt <= $airDtEnd and A.delFlg = 0 order by A.airDt ,A.pgKind");
    }
  }
  /*------------------------------------------------------------------
リスト作成
 -------------------------------------------------------------------*/
  Future<void> getItems() async {
    List<Widget> list = <Widget>[];
    String strTitle = "";
    String strVol = "";
    String strAirDt = "";
    String strAssetPath = "";
    bool chkFlg = false;
    double titleFont = 0;
    for (Map item in mapPgDetailList) {

      if(item['pgKind'] == cnsPgKindTV) {
        strTitle = item['pgName'].toString();
        strVol = await editVol(item['vol']);
      }else{
        strTitle = item['volNm'].toString();
        strVol = "";
      }
      if(strTitle.length <= 10){
        titleFont = 16;
      }else if (strTitle.length > 10 && strTitle.length <= 20){
        titleFont = 13;
      }else{
        titleFont = 10;
      }
      strAirDt = await getDtFormat(item['airDt'].toString());
      switch (item['pgKind']) {
        case cnsPgKindTV:
          strAssetPath = 'assets/no.png';
          break;
        case cnsPgKindMV:
          strAssetPath = 'assets/mv.png';
          break;
        case cnsPgKindVS:
          strAssetPath = 'assets/vs.png';
          break;
        default:
           strAssetPath = 'assets/other.png';
            break;
      }
      chkFlg = await chkRireki(item['pgNo'], item['vol']);

      list.add(
        Card(
          margin: EdgeInsets.fromLTRB(0, 0, 0, 0),
          color: Colors.black,
         // shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15),),
          child: ListTile(
            title: Column(
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Padding(padding: EdgeInsets.fromLTRB(0,0,5,0), child: Icon(Icons.check,size: 20.0,color: chkFlg?Colors.green:Colors.black ),),
                    Text(strAirDt.toString(), style: const TextStyle(fontSize: 10.0, color: Colors.white,),),
                    Padding(padding: EdgeInsets.fromLTRB(3,0,3,0), child: Image.asset(strAssetPath, width: 20, height: 20,),),
                    Container(height: 30.0, width: 200.0,
                      child:Align(
                        alignment: Alignment.centerLeft,
                        child:Text('${strTitle.toString()} ${strVol.toString()}', maxLines: null, overflow: TextOverflow.visible,style:  TextStyle(fontSize: titleFont, color: Colors.white,),),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            onTap: () {_tapTile(item['pgNo'], item['vol']);},
          ),
        ),
      );
    }
    setState(() {
      pgDetailList = list;
    });
  }
  /*------------------------------------------------------------------
vol編集
 -------------------------------------------------------------------*/
  Future<String> editVol(double vol) async {
    String strVol = '';
    if (vol % 1 == 0) {
      strVol =  '#${vol.toInt().toString()}';
    } else {
      strVol ='#${vol.toString()}';
    }
    return strVol;
  }
  /*------------------------------------------------------------------
タップ時の動作
 -------------------------------------------------------------------*/
  Future<bool> chkRireki(int pgNo, double vol) async{
    bool chkFlg = false;
    String dbPath = await getDatabasesPath();
    String path = p.join(dbPath, 'internal_assets.db');
    Database database = await openDatabase(path, version: 1);
    List<Map> mapRireki = await database.rawQuery("SELECT 1 From rireki where pgNo = $pgNo and vol = $vol " );
    for (Map item in mapRireki) {
      setState(() {
        chkFlg = true;
      });
    }
    return chkFlg;
  }
  /*------------------------------------------------------------------
タップ時の動作
 -------------------------------------------------------------------*/
  Future<void>  _tapTile(int pgNo, double vol) async {
    bool chkFlg = false;
    chkFlg = await chkRireki(pgNo, vol);
   if(!chkFlg) {
     await rirekiIns(pgNo, vol);
   }else{
     await rirekiDel(pgNo, vol);
   }
    await getPgDetail();
    await getItems();
  }
  /*------------------------------------------------------------------
履歴テーブル挿入
 -------------------------------------------------------------------*/
  Future<void> rirekiIns( int pgNo, double vol) async{
    String dbPath = await getDatabasesPath();
    String query = '';
    String path = p.join(dbPath, 'internal_assets.db');
    Database database = await openDatabase(path, version: 1,);
    query =
    'INSERT INTO rireki(pgNo,vol,kaku1,kaku2,kaku3,kaku4) values($pgNo,$vol,null,null,null,null) ';
    await database.transaction((txn) async {
      await txn.rawInsert(query);
    });
  }
  /*------------------------------------------------------------------
履歴テーブル削除
 -------------------------------------------------------------------*/
  Future<void> rirekiDel(int pgNo, double vol) async{
    String dbPath = await getDatabasesPath();
    String query = '';
    String path = p.join(dbPath, 'internal_assets.db');
    Database database = await openDatabase(path, version: 1,);
    query =
    'Delete From rireki where pgNo = $pgNo and vol = $vol';
    await database.transaction((txn) async {
      await txn.rawInsert(query);
    });
  }
  /*------------------------------------------------------------------
放映種類変更
 -------------------------------------------------------------------*/
  Future<void> chgPgKindDetail(int pgKind) async {
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
    await getPgDetail();
    await getItems();
  }
  /*------------------------------------------------------------------
期間中、他の作品も表示する
 -------------------------------------------------------------------*/
  Future<void> chgPgOtherDetail() async {
    setState(() {
      pg_otherFlg = !pg_otherFlg;
    });

    await updSettingGengoPgkind();
    await getPgDetail();
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

    int showa = 0;int heisei = 0;int reiwa = 0;int tv = 0;
    int movie = 0;int vshine = 0;int other = 0;int pg_other = 0;
    //元号
    showa = gengoShowaFlg?BtFlgOn:BtFlgOff;
    heisei = gengoHeiseiFlg?BtFlgOn:BtFlgOff;
    reiwa = gengoReiwaFlg?BtFlgOn:BtFlgOff;

    //放送種類
    tv = pgKindTVFlg?BtFlgOn:BtFlgOff;
    movie = pgKindMVFlg?BtFlgOn:BtFlgOff;
    vshine = pgKindVSFlg?BtFlgOn:BtFlgOff;
    other = pgKindOTHERFlg?BtFlgOn:BtFlgOff;

    //放送期間外でも作品を表示する
    pg_other = pg_otherFlg?BtFlgOn:BtFlgOff;

    query =
    'UPDATE setting set showa = $showa ,heisei = $heisei ,reiwa = $reiwa ,tv = $tv ,movie = $movie ,vshine = $vshine ,other = $other ,pg_other = $pg_other ';
    await database.transaction((txn) async {
      await txn.rawInsert(query);
    });


  }
}
