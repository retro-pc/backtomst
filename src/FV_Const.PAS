{************************************************}
{                                                }
{  Copyright (C) MarinovSoft 2013-2014           }
{                                                }
{  http://marinovsoft.narod.ru                   }
{  mailto:super386@rambler.ru                    }
{                                                }
{************************************************}
Unit FV_Const;

Interface

const
  { ViewMode constants }
  vmText = 0;
  vmHex = 1;
  vmDump = 2;
  vmAsm = 3;
  vmInternal = 16;
  vmExternal = 32;
  vmDB = 100;
  vmSpread = 101;
  vmSpreadSL = 111; {AK155: это с линиями между колонками}
  vmPKT = 102;
  vmMSG = 103;

  {Wrap constants} {DataCompBoy}
  wmNone = 0;
  wmWidth = 1;
  wmWords = 2;

  hcView  = 11021;
  hcFilePanel = 01100;

  vbfHex = 1 shl 0;
  vbfWrap = 1 shl 1;
  vbfWordWrap = 1 shl 2;
  vbfHlt = 1 shl 3;
  vbfScrollAfterEOF = 1 shl 4;
  vbfAutoscroll = 1 shl 5;
  vbfDisAsm = 1 shl 6;

  cmUnWrap = 197;

  ebfTRp = 1 shl 13;

  hhNothing = #$00; {No highlighted text}
  hhNumber = #$01; {The text that seems to be a number}
  hhString = #$02; {The text that seems to be a string}
  hhComment = #$03; {The text that seems to be a comment}
  hhSymbol = #$04; {The text that seems to be a symbol}
  hhKeyword1 = #$05; {Keyword from bank 1}
  hhKeyword2 = #$06; {Keyword from bank 2}

  cmFindView = 10102;
  cmAddFilter = 19012;
  cmGetName = 3028;
  cmReanimator = 3019;
  cmReleaseFile = 19024;
  cmFileEdit = 10013;
  hsEditSave = 115;
  cmHexMode = 10607;
  cmLoadViewFile = 10404;
  UseEnterInViewer: Byte = 0; {JO}
  kbSpace = $003920;
  evMouseDown = $0001;

  cmPlaceMarker1 = 14001;
  cmPlaceMarker2 = 14002;
  cmPlaceMarker3 = 14003;
  cmPlaceMarker4 = 14004;
  cmPlaceMarker5 = 14005;
  cmPlaceMarker6 = 14006;
  cmPlaceMarker7 = 14007;
  cmPlaceMarker8 = 14008;
  cmPlaceMarker9 = 14009;
  cmGoToMarker1 = 14011;
  cmGoToMarker2 = 14012;
  cmGoToMarker3 = 14013;
  cmGoToMarker4 = 14014;
  cmGoToMarker5 = 14015;
  cmGoToMarker6 = 14016;
  cmGoToMarker7 = 14017;
  cmGoToMarker8 = 14018;
  cmGoToMarker9 = 14019;
  AutoRepeat: Word = 1;
  wfMaxi = $10;

implementation

end.
