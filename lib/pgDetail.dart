import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;

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
        //  actions: [IconButton(icon: Icon(Icons.settings), onPressed: () {})],
        // 背景画像を設定する
        // flexibleSpace: Container(
        //   decoration: BoxDecoration(
        //     image: DecorationImage(
        //       image: AssetImage('assets/mokume.png'),
        //       fit: BoxFit.cover,
        //     ),
        //   ),
        // ),
      ),
      body: Container(
        constraints: BoxConstraints(
          minWidth: double.infinity,
          minHeight: double.infinity,
        ),
        decoration: BoxDecoration(
          color: Colors.black,
        ),
        child: SingleChildScrollView(
          child: Column(
            children: <Widget>[
              ...pgDetailList,
            ],
          ),
        ),
      ),

    );
  }

  /*------------------------------------------------------------------
  ロード処理
 -------------------------------------------------------------------*/
  Future<void> load() async {
    await getPgDetail();
    //await getImageFromGallery();
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

    for (Map item in mapPgDetailList) {
      strVol = item['vol'].toString();
      list.add(
        Card(
          color: Colors.black,
        //  margin: const EdgeInsets.fromLTRB(15, 0, 15, 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(10),
            title: Column(
              children: <Widget>[
                Text(
                  strVol.toString(),
                  style: const TextStyle(fontSize: 18.0, color: Colors.white,),
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



}
