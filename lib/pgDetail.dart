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

  pgDetailScreen(this.pgNo, this.pgName);

  @override
  State<pgDetailScreen> createState() =>
      _pgDetailScreenState(this.pgNo, this.pgName);
}

class _pgDetailScreenState extends State<pgDetailScreen> {
  int pgNo;
  String pgName;
  _pgDetailScreenState(this.pgNo, this.pgName);
  //変数の宣言
  List<Map> mapPgDetailList = <Map>[];
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
        title: Text(
          pgName,
          style: const TextStyle(
            fontSize: 35.0,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.black,
        // AppBarの背景色を透明にする
        elevation: 0,
        // 影を無効にする
       // brightness: Brightness.light,
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
            Divider(color: Colors.white, thickness: 2,),
            Text("　　　公開日　　　作品名　　話数",
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
    await getPgDetail();
    await getItems();
  }
  /*------------------------------------------------------------------
  ロード処理
 -------------------------------------------------------------------*/
  Future<void> getPgDetail() async {
    String dbPath = await getDatabasesPath();
    String path = p.join(dbPath, 'internal_assets.db');
    Database database = await openDatabase(
      path,
      version: 1,
    );
    mapPgDetailList = await database.rawQuery(
        "SELECT * From volMaster where pgNo = $pgNo order by airDt");
  }


  /*------------------------------------------------------------------
リスト作成
 -------------------------------------------------------------------*/
  Future<void> getItems() async {
    List<Widget> list = <Widget>[];
    String strVol = "";
    String strAirDt = "";
    for (Map item in mapPgDetailList) {
      strVol = item['vol'].toString();
      strAirDt = '${item['airDt'].toString().substring(0,4)}年${item['airDt'].toString().substring(4,6)}月${item['airDt'].toString().substring(6,8)}日';
      list.add(
        Card(
          color: Colors.black,
        //  margin: const EdgeInsets.fromLTRB(15, 0, 15, 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          child: ListTile(
            title: Column(
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Text(strAirDt.toString(), style: const TextStyle(fontSize: 15.0, color: Colors.white,),),
                    ImageIcon(
                      AssetImage('assets/mv.png'),
                      size: 15,  // アイコンのサイズを調整します
                      color: Colors.blue,  // アイコンの色を指定します（省略可能）
                    ),
                    Text(pgName.toString(), style: const TextStyle(fontSize: 18.0, color: Colors.white,),),
                    Text(strVol.toString(), style: const TextStyle(fontSize: 18.0, color: Colors.white,),),
                    ],
                ),
              ],
            ),
            // selected: photoNo == item['photoNo'],
            // // tileColor: const Color(0xFFF5F5DC),
            // onTap: () {
            //   _tapTile(item['albumNo'], item['photoNo'],
            //       item['photoLocation'].toString());
            // },
            // trailing: PopupMenuButton(
            //   itemBuilder: (context) {
            //     return lists.map((String list) {
            //       return PopupMenuItem(
            //         value: list,
            //         child: Text(list),
            //       );
            //     }).toList();
            //   },
            //   onSelected: (String list) {
            //     switch (list) {
            //       case '除外':
            //         ejectPhoto(item['albumNo'], item['photoNo']);
            //         break;
            //     }
            //   },
            // ),
          ),
        ),
      );
    }
    setState(() {
      pgDetailList = list;
    });
  }

  // void _tapTile(int albumNo, int photoNo, String filePath) async {
  //   Navigator.push(
  //       context,
  //       MaterialPageRoute(
  //         builder: (context) => SingleGalleryScreen(albumNo, photoNo, filePath),
  //       ));
  // }

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
}
