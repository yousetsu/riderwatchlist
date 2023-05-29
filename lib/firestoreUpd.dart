import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';

/*------------------------------------------------------------------
書き込み
 -------------------------------------------------------------------*/
Future<void> writeFireStoreRiderMaster() async {
  final collection = FirebaseFirestore.instance.collection('riderMaster');
  List<Map<String, dynamic>> dataList =[
    {'pgNo':1,'pgName':'仮面ライダー','gengo':1,'pgKind':1,'airDtSt':19710403,'airDtEnd':19730210,'syncDt':0,'delFlg':''},
    {'pgNo':2,'pgName':'仮面ライダーV3','gengo':1,'pgKind':1,'airDtSt':19730217,'airDtEnd':19740209,'syncDt':0,'delFlg':''},
    {'pgNo':3,'pgName':'仮面ライダーX','gengo':1,'pgKind':1,'airDtSt':19740216,'airDtEnd':19741012,'syncDt':0,'delFlg':''}
  ];
  dataList.forEach((data) {
    collection.add(data);
  });
}
/*------------------------------------------------------------------
書き込み
 -------------------------------------------------------------------*/
Future<void> writeFireStoreVolMaster() async {
  final collection = FirebaseFirestore.instance.collection('volMaster');
  List<Map<String, dynamic>> dataList =[
    {'pgNo':1,'vol':1,'pgKind':1,'airDt':19710403,'airDt_mvEnd':0,'volNm':'','syncDt':0,'delFlg':''},
    {'pgNo':1,'vol':2,'pgKind':1,'airDt':19710410,'airDt_mvEnd':0,'volNm':'','syncDt':0,'delFlg':''},
    {'pgNo':1,'vol':3,'pgKind':1,'airDt':19710417,'airDt_mvEnd':0,'volNm':'','syncDt':0,'delFlg':''},
    {'pgNo':1,'vol':4,'pgKind':1,'airDt':19710424,'airDt_mvEnd':0,'volNm':'','syncDt':0,'delFlg':''},
    {'pgNo':1,'vol':5,'pgKind':1,'airDt':19710501,'airDt_mvEnd':0,'volNm':'','syncDt':0,'delFlg':''}
  ];
  dataList.forEach((data) {
    collection.add(data);
  });
}