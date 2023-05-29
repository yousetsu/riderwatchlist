List<Map> mapPgList = <Map>[];
List<Map> mapSetting = <Map>[];
int syncDtLocal = 0;
bool gengoShowaFlg = true;
bool gengoHeiseiFlg = true;
bool gengoReiwaFlg = true;

bool pgKindTVFlg = true;
bool pgKindMVFlg = true;
bool pgKindVSFlg = true;
bool pgKindOTHERFlg = true;

bool pg_otherFlg = false;
/*------------------------------------------------------------------
日付を年月日に変換
 -------------------------------------------------------------------*/
Future<String> getDtFormat(String strDate) async {
  String strFormatDate = "";
  if(strDate.length >= 8) {
    strFormatDate = '${strDate.substring(0, 4)}年${strDate.substring(4, 6)}月${strDate.substring(6, 8)}日 ';
  }else{
    strFormatDate = '00000000';
  }
  return strFormatDate;
}