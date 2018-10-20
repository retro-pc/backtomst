{************************************************}
{                                                }
{  Copyright (C) MarinovSoft 2013-2014           }
{                                                }
{  http://marinovsoft.narod.ru                   }
{  mailto:super386@rambler.ru                    }
{                                                }
{************************************************}
{$ifdef fpc}
{$A1}
{$endif}

unit MSTConst;

interface

Uses md5;

const
  cmAbout      = 170;
  cmReadDisc   = 171;
  cmWriteDisc  = 172;
  cmFormatDisc = 173;
  cmSelectDriveA = 174;
  cmSelectDriveB = 175;
  cmSelectDriveImage = 176;
  cmOptions    = 177;

  cmListDisk   = 178;
  cmView       = 179;
  cmDelete     = 13;

  cmCopyFileDOS = 180;
  cmCopyFileMST = 181;

  cmMSTDiskOpen = 182;

  cmFileInfo    = 183;
//  cmClearDataBase = 184;
  cmFileInfoShow = 185;
  cmEditCategories = 186;

  cmSelectDriveA5 = 190;
  cmSelectDriveA3 = 191;
  cmSelectDriveB5 = 192;
  cmSelectDriveB3 = 193;

Const
  kbGrayAst     = $372A;

type
  PFileInfoRec = ^TFileInfoRec;
  TFileInfoRec = packed record
    FileName:ShortString;
    TempFileName:ShortString;
    hash:TMD5Digest;
    comment:ShortString;
  end;

implementation

end.
