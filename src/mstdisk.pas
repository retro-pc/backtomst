{************************************************}
{                                                }
{  Copyright (C) MarinovSoft 2013-2014           }
{                                                }
{  http://marinovsoft.narod.ru                   }
{  mailto:super386@rambler.ru                    }
{                                                }
{************************************************}
{.$DEFINE UseAbstract}
(*

For Disk B type: mem[0:$491 := $54 ].
Simply, this turns the FDC controller to work with DD diskette
which has 80 tracks.

*)

{$R-}
{$ifdef fpc}
{$A1}
{$endif}

Unit MSTDisk;

Interface

{$ifdef fpc}
{$ifdef win32}
Uses fdrawcmd;
{$else}
Uses go32;
{$endif}
{$endif}

Type
  PEntry = ^TEntry;
  TEntry = Packed Record
    User: Byte;                { Hомер пользователя }
    Name: Array[0..7] Of Char; { Имя файла }
    Ext : Array[0..2] Of Char; { Расширение }
    Exn : Byte;                { Hомер экстента }
    Re0 : Byte;                { Зарезервировано DOS }
    Re1 : Byte;                { Зарезервировано DOS }
    Recs: Byte;                { Число блоков в экстенте }
    Fat : Array[0..7] Of Word; { Hомера занятых блоков }
  End;

Type
  PFormRec = ^TFormRec;
  TFormRec = Packed Record
    Ssize     : Byte;
    Gap1,Gap2 : Byte;
    Scount    : Byte;
    Tcount    : Byte;
    Side      : Byte;
    Track     : Byte;
    Sect      : Byte;
    Interl    : Byte;
  End;

Type
  TBufType = Array[0..1023] Of Byte;

  _Tblock = array[0..1023] of byte;
  _Pblock = ^_Tblock;

Type
  TFrm_Vec = Array[0..511] Of Byte;

Type
  TCatalog = Array[0..127] Of TEntry;

Type
  TDpb = Record
    Laddr : Word;             { Адрес загрузки }
    Saddr : Word;             { Адрес старта }
    Count : Word;             { Счетчик загрузки }
    P525  : Byte;             { 0 - 5"}
    Mfm   : Byte;             { 1 = MFM }
    Tpi   : Byte;             { 1 = 96tpi }
    Ifact : Byte;             { 1 = no factor }
    Ssize : Byte;             { 3 = 1024 bps }
    Fside : Byte;             { 1 = double }
(*    Spt   : Byte;             { 5 } *)
    Spt   : Word;
    Tcount: Word;             { 81 }
    Lspt  : Word;             { 40 }
(*    Lp1   : Word;             { 4 }*)
    Lp1   : Byte;
    Lp2   : Byte;             { 15 }
    Lp3   : Byte;             { 0 }
    Dsize : Word;             { blocks - 1 }
    Root  : Word;             { 127 }
    Al0   : Byte;             { 192 }
    Al1   : Byte;             { 0 }
    Lp4   : Word;             { 32 }
    Systrk: Word;             { }
    Crc   : Byte;
  End;

const
  systrk : word = 2;
{  BlockCount : Word = 390;}
  BlockCount : Word = 394;

{$ifndef fpc}
Type
  ShortString = String;
{$endif}

Type
  PMSTDisk = ^TMSTDisk;
  TMSTDisk = Object
    _Dpb:TDpb;
    _Frec:TFormRec;
    Constructor Init;
    Destructor Done;virtual;
    Function FormatTrack(Frec:TFormRec):Word;Virtual;  {$Ifdef UseAbstract} { Abstract; } {$endif}
    { Форматирование трека, с параметрами определюсь позже }
    Function FormatDisk:Byte;Virtual;                  {$Ifdef UseAbstract} { Abstract; } {$endif}   { Форматирование диска }
    Function ReadDisk:Byte;Virtual;                    {$Ifdef UseAbstract} { Abstract; } {$endif}
    Function WriteDisk:Byte;Virtual;                   {$Ifdef UseAbstract} { Abstract; } {$endif}
    Function SeekTrack(Frec:TFormRec):Word;Virtual;
    Function ReadSect(Frec:TFormRec;Var Buf:TBufType):Word;Virtual;              {$Ifdef UseAbstract} { Abstract; } {$endif}
    Function WriteSect(Frec:TFormRec;Var Buf:TBufType):Word;Virtual;             {$Ifdef UseAbstract} { Abstract; } {$endif}
    Procedure ResetDisk;Virtual;                                                 {$Ifdef UseAbstract} { Abstract; } {$endif}
    Function GetErrorDescription(Track, Sect, ErrorNumber:Byte):String;Virtual;  {$Ifdef UseAbstract} { Abstract; } {$endif}
    Procedure SetBlock(Block:Word;Ofs:Byte);virtual;                             {$Ifdef UseAbstract} { Abstract; } {$endif}
{    Function ReadDir:TCatalog;virtual; Turbo Pascal так не умеет!}
   Function ReadDir(var Catalog:TCatalog):Boolean;virtual;                       {$Ifdef UseAbstract} { Abstract; } {$endif}
   Procedure WriteDir(Catalog:TCatalog);virtual;                                 {$Ifdef UseAbstract} { Abstract; } {$endif}
   Procedure ReadDpb;virtual;                                                    {$Ifdef UseAbstract} { Abstract; } {$endif}
   Function GetDiskNameEx:ShortString;virtual;                                   {$Ifdef UseAbstract} { Abstract; } {$endif}
  End;

Type
  PMicroDOSDisk = ^TMicroDOSDisk;
  TMicroDOSDisk = Object(TMSTDisk)
  private
    DiskName:Char;
    DiskAddr:Word;
    {$ifdef fpc}
    hMST:THandle;
    {$ifdef win32}
    rwp :FD_READ_WRITE_PARAMS;
    sp  :FD_SEEK_PARAMS;
    {$endif}
    {$endif}
  public
    Constructor Init(_DiskName:Char;Frec:TFormRec);
    Destructor Done;virtual;
    Procedure ResetDisk;Virtual;
    Function FormatTrack(Frec:TFormRec):Word;Virtual;
    Function SeekTrack(Frec:TFormRec):Word;Virtual;
    Function ReadSect(Frec:TFormRec;Var Buf:TBufType):Word;Virtual;
    Function WriteSect(Frec:TFormRec;Var Buf:TBufType):Word;Virtual;
    Function GetErrorDescription(Track, Sect, ErrorNumber:Byte):String;Virtual;
    Procedure SetBlock(BlockNumber:Word;Ofs:Byte);virtual;
    Function ReadBlock(BlockNumber:Word;block:_pblock):Byte;virtual;
    Function WriteBlock(BlockNumber:Word;block:_pblock):Byte;virtual;
    Function ReadDir(var Catalog:TCatalog):Boolean;virtual;
    Procedure WriteDir(Catalog:TCatalog);virtual;
    Procedure ReadDpb;virtual;
    Function GetDiskNameEx:ShortString;virtual;
  End;

Type
  PMicroDOSDiskImage = ^TMicroDOSDiskImage;
{  TMicroDOSDiskImage = Object(TMSTDisk)}
  TMicroDOSDiskImage = Object(TMicroDOSDisk)
  private
  {$ifndef fpc}
    F:File;
  {$endif}
    FileName:String;
  public
    Constructor Init(_FileName:String;FRec:TFormRec);
    Destructor Done;virtual;
    Function ReadSect(Frec:TFormRec;Var Buf:TBufType):Word;Virtual;
    Function WriteSect(Frec:TFormRec;Var Buf:TBufType):Word;Virtual;
    Function FormatTrack(Frec:TFormRec):Word;Virtual;
    Function GetErrorDescription(Track, Sect, ErrorNumber:Byte):String;Virtual;
    Function SeekTrack(Frec:TFormRec):Word;Virtual;
    Function GetDiskNameEx:ShortString;virtual;
  end;

Const
  Dpb : TDpb = (
    Laddr : 0;             { Адрес загрузки }
    Saddr : 0;             { Адрес старта }
    Count : 0;             { Счетчик загрузки }
    P525  : 0;             { 0 - 5"}
    Mfm   : 1;             { 1 = MFM }
    Tpi   : 1;             { 1 = 96tpi }
    Ifact : 1;             { 1 = no factor }
    Ssize : 3;             { 3 = 1024 bps }
    Fside : 1;             { 1 = double }
    Spt   : 5;             { 5 }
    Tcount: 81;            { 81 }
    Lspt  : 40;            { 40 }
    Lp1   : 4;             { 4 }
    Lp2   : 15;            { 15 }
    Lp3   : 0;             { 0 }
(*    Dsize : 391;           { blocks - 1 }*)
    Dsize : 394;
    Root  : 127;           { 127 }
    Al0   : 192;           { 192 }
    Al1   : 0;             { 0 }
    Lp4   : 32;            { 32 }
    Systrk: 2;             { }
    Crc   : 0
    );

Implementation

Uses
{$ifdef fpc}
{$ifdef win32}
Windows,
{$else}
{$endif}
{$endif}

Service {$ifdef fpc}, SysUtils {$endif};

Constructor TMSTDisk.Init;
Begin
End;
Destructor TMSTDisk.Done;
Begin
End;
{$ifndef UseAbstract}
Function TMSTDisk.FormatTrack(Frec:TFormRec):Word;
Begin
  FormatTrack:=0;
End;
Function TMSTDisk.SeekTrack(Frec:TFormRec):Word;
Begin
  SeekTrack:=0;
End;
Function TMSTDisk.FormatDisk:Byte;
Begin
  FormatDisk:=0;
End;
Function TMSTDisk.ReadDisk:Byte;
Begin
  ReadDisk:=0;
End;
Function TMSTDisk.WriteDisk:Byte;
Begin
  WriteDisk:=0;
End;
Function TMSTDisk.ReadSect(Frec:TFormRec;Var Buf:TBufType):Word;
Begin
  ReadSect:=0;
End;
Function TMSTDisk.WriteSect(Frec:TFormRec;Var Buf:TBufType):Word;
Begin
  WriteSect:=0;
End;
Procedure TMSTDisk.ResetDisk;
Begin
End;
Function TMSTDisk.GetErrorDescription(Track, Sect, ErrorNumber:Byte):String;
Begin
  GetErrorDescription:='';
End;
Procedure TMSTDisk.SetBlock(Block:Word;Ofs:Byte);
begin
end;
Function TMSTDisk.ReadDir(var Catalog:TCatalog):Boolean;
begin
  ReadDir:=True;
end;
Procedure TMSTDisk.WriteDir(Catalog:TCatalog);
begin
end;
Procedure TMSTDisk.ReadDpb;
begin
end;
Function TMSTDisk.GetDiskNameEx:ShortString;
Begin
  GetDiskNameEx:='MST Disk';
End;
{$endif}

Constructor TMicroDOSDisk.Init(_DiskName:Char;Frec:TFormRec);
{$ifdef fpc}
{$ifdef win32}
Var
  lpFileName:PChar;
  DataRate  :Byte;
  dwRet     :LongWord;
{$else}
Var
  R:TRealRegs;
{$endif}
{$endif}
Begin
  DiskName:=UpCase(_Diskname);
  {$ifdef fpc}
  {$ifdef win32}
  Case DiskName Of
    'A': lpFileName:='\\.\fdraw0';
    'B': lpFileName:='\\.\fdraw1';
    Else DiskAddr:=0;
  End;
  DataRate:= FD_RATE_300K;
  { Проверить на реальном дисководе! // 0=500Kbps (HD), 1=300Kbps (DD 5.25"), 2=250Kbps (DD 3.5"), 3=1Mbps (ED) }
  hMST:=CreateFile(lpFileName, GENERIC_READ or GENERIC_WRITE, 0, nil, OPEN_EXISTING, 0, 0);
  { if hMST = INVALID_HANDLE_VALUE Then begin end }
  DeviceIoControl(hMST, IOCTL_FD_SET_DATA_RATE, @DataRate, SizeOf(DataRate), nil, 0, dwRet, nil);

  rwp.flags:=  FD_OPTION_MFM;
  rwp.phead:=  0;
  rwp.size:=   3;         { 0=128, 1=256, 2=512, 3=1024, ... }
  rwp.gap:=    $0a;
  rwp.datalen:= $ff;
  {$else}
  Case DiskName Of
    'A': begin DiskAddr:=$490; { outportb($3F7, (inportb($3F7) and $FE));} end;
    'B': begin DiskAddr:=$491; { outportb($377, (inportb($3F7) and $FE));} end;
    Else DiskAddr:=0;
  End;
  R.ah:=$17;
  R.al:=$02;
  R.dl:=DiskAddr - $490;
  RealIntr($13, R);
  {$endif}
  {$else}
  Case DiskName Of
    'A': DiskAddr:=$490;
    'B': DiskAddr:=$491;
    Else DiskAddr:=0;
  End;
  {$endif}
  _Frec:=Frec;
  ResetDisk;
  Inherited Init;
End;

Destructor TMicroDOSDisk.Done;
begin
  Inherited Done;
  {$ifdef fpc}
  {$ifdef win32}
  CloseHandle(hMST);
  {$endif}
  {$endif}
end;

Function TMicroDOSDisk.SeekTrack(Frec:TFormRec):Word;
{$ifdef fpc}
{$ifdef win32}
Var
  _Flag     :BOOL;
  dwRet     :LongWord;
{$else}
Var
  Regs:TRealRegs;
{$endif}
{$endif}
begin
  {$ifdef fpc}
  {$ifdef win32}
  sp.cyl:=Frec.Track shr 1;
 _Flag:=DeviceIoControl(hMST, IOCTL_FDCMD_SEEK, @sp.cyl, sizeof(sp.cyl), nil, 0, &dwRet, nil);

  if not _Flag Then
  begin
    SeekTrack:=GetLastError;
  End
  Else
    SeekTrack:=0;
  {$else}
    SeekTrack:=0;
  {$endif}
  {$endif}
end;

Procedure TMicroDOSDisk.ResetDisk;
{$ifndef win32}
Var
{$ifdef fpc}
  R:TrealRegs;
{$endif}
  Disk:Byte;
{$endif}
Begin
{$ifndef fpc}
  Disk:=DiskAddr - $490;
  Asm
    Mov AH, 0
    Mov DL, Disk
    Int 13H
  End;
  Mem[0:DiskAddr]:=$54; (* See comment above *)
{$else}
{$ifndef win32}
  dpmi_dosmemfillchar(0, DiskAddr, 1, Chr($54));
  Disk:= DiskAddr - $490;
  R.dl:= Disk;
  R.ah:= 0;
  RealIntr($13, R);
{$else}

{$endif}
{$endif}
End;

Function TMicroDOSDisk.FormatTrack(Frec:TFormRec):Word;
Var
  I:Word;
{$ifdef fpc}
{$ifdef win32}
  dwRet     :LongWord;
  pfp       :PFD_FORMAT_PARAMS;
  _Flag     :BOOL;
  ph        :PFD_ID_HEADER;
{$else}
  Block : Array[1..128,0..3] Of Byte;
  R     : TRealRegs;
  S,Err : Byte;
  Disk  : Byte;
{$endif}
{$else}
  Block : Array[1..128,0..3] Of Byte;
  Bs,Bo : Word;
  S,Err : Byte;
  Side,Track:Byte;
  Disk : Byte;
{$endif}
Begin
  {$ifndef fpc}
{  Mem[0:DiskAddr]:=$54;}
  Disk :=DiskAddr - $490;

  (* See comment above *)

  FillChar(Block,512,0);
  S:=0;
  Frec.Side:=Frec.Track And 1;
  Frec.Track:=Frec.Track ShR 1;
  For I:=1 To Frec.Scount Do
  Begin
    Block[I,0]:=Frec.Track;
    Block[I,1]:=Frec.Side;
    Block[I,2]:=S+1;
    Block[I,3]:=Frec.Ssize;
    S:=(S+Frec.Interl) Mod Frec.SCount;
  End;
  Bs:=Seg(Block);
  Bo:=Ofs(Block);
  Side:=Frec.Side;
  Track:=Frec.Track;

  Asm
    Push DS
    Push ES
    Mov ES,Bs
    Mov BX,Bo
    Mov AH,5
    Mov DL,Disk
    Mov DH,Side
    Mov CH,Track
    Int 13H
    Mov Err,AH
    Pop ES
    Pop DS
  End;

  FormatTrack:=Err;

  {$else}
  {$ifdef win32}
  GetMem(pfp, sizeof(FD_FORMAT_PARAMS) + sizeof(FD_ID_HEADER) * (Frec.SCount - 1));

  pfp^.flags  := FD_OPTION_MFM;
  pfp^.phead  := Frec.Track And 1;
  pfp^.Size   := Frec.SSize;   // 0=128, 1=256, 2=512, 3=1024, ...
  pfp^.Sectors:= Frec.SCount;  // sectors per track
  pfp^.gap    := $0A;
  pfp^.fill   := $00;

  For I:=0 To Frec.SCount - 1 Do
  Begin
//    ph:=(PFD_ID_HEADER(@pfp^.Header) + I * sizeof(FD_ID_HEADER));
    ph:=(@pfp^.Header + I * sizeof(FD_ID_HEADER));
    ph^.cyl := Frec.Track ShR 1;
    ph^.head := pfp^.phead;
    ph^.sector := 1 + ((I + ph^.cyl * (pfp^.sectors - 1)) mod pfp^.Sectors);
    ph^.size := pfp^.size;
  End;
  _Flag:=DeviceIoControl(hMST, IOCTL_FDCMD_FORMAT_TRACK, pfp,
                               sizeof(FD_FORMAT_PARAMS) + sizeof(FD_ID_HEADER) * (pfp^.Sectors - 1), nil, 0, @dwRet, nil);

  FreeMem(pfp, sizeof(FD_FORMAT_PARAMS) + sizeof(FD_ID_HEADER) * (Frec.SCount - 1));

  if not _Flag Then
  begin
    FormatTrack:=GetLastError;
    Exit;
  end
  else
    FormatTrack:=0;
  {$else}
  { dpmi_dosmemfillchar(0, DiskAddr, 1, Chr($54)); }
  Disk :=DiskAddr - $490;
  (* See comment above *)

  FillChar(Block,512,0);
  S:=0;
  For I:=1 To Frec.SCount Do
  Begin
    Block[I,0]:=Frec.Track ShR 1;
    Block[I,1]:=Frec.Track And 1;
    Block[I,2]:=S+1;
    Block[I,3]:=Frec.SSize;
    S:=(S+Frec.Interl) Mod Frec.SCount;
  End;

  CopyToDOS(Block, SizeOf(Block));
  R.es:=tb_segment;
  R.bx:=tb_offset;

  R.dl:=Disk;
  R.ch:=Frec.Track shr 1;
  R.dh:=Frec.Track and 1;
  R.ah:=5;

  RealIntr($13, R);

  if (R.flags and CarryFlag) <> 0 Then
    Err:=R.ah
  Else
    Err:=0;
  FormatTrack:=Err;

  {$endif}
  {$endif}
End;

Function TMicroDOSDisk.ReadSect(Frec:TFormRec;Var Buf:TBufType):Word;
Var
{$ifdef fpc}
{$ifdef win32}
  _Flag:BOOL;
  dwRet:LongWord;
{$else}
  R:TRealRegs;
  Disk: Byte;
  Err: Byte;
{$endif}
{$else}
  _Flag:Byte;
  Disk: Byte;
  Segbuf,Ofsbuf : Word;
  Err: Byte;
{$endif}
Begin

  {$ifndef fpc}
{  Mem[0:DiskAddr]:=$54;}

  Disk :=DiskAddr - $490;

  {  frec.side:=frec.track and 1;
  frec.track:=frec.track shr 1;}

  Segbuf:=Seg(Buf);
  Ofsbuf:=Ofs(Buf);

  Asm
    Push DS
    Push BX
    Push BP
    Mov ES,Segbuf
    Mov BX,Ofsbuf
    Mov DL,Disk        (*drive*)
    Mov CL,Frec.Sect   (*sector*)
    Mov CH,Frec.Track  (*track*)
    Mov DH,0           (*side*)
    ShR CH,1
    Jnc @R
    Mov DH,1
    @R:Mov AL,1      (*sector cnt*)
    Mov AH,2
    Int 13H
    Mov Err,AH
    Lahf
    Mov _Flag,AH
    Pop BP
    Pop BX
    Pop DS
  End;

  If (_Flag And 1) > 0 Then
    ReadSect:=Err
  Else
    ReadSect:=0;

  {$else}
  {$ifdef win32}

  rwp.cyl    := Frec.Track shr 1;
  rwp.head   := Frec.Track and 1;
  rwp.phead  := rwp.head;
  rwp.sector := Frec.Sect;
  rwp.eot    := rwp.sector + 1;

  _Flag:=DeviceIoControl(hMST, IOCTL_FDCMD_READ_DATA, @rwp, SizeOf(rwp), @Buf, {512} SizeOf(TBufType), dwRet, nil);

  if not _Flag Then
    ReadSect:=GetLastError
  Else
    ReadSect:=0;
  {$else}
  dpmi_dosmemfillchar(0, DiskAddr, 1, Chr($54));
  Disk :=DiskAddr - $490;

  CopyToDOS(Buf, SizeOf(Buf));
  R.es:=tb_segment;
  R.bx:=tb_offset;

  R.dl:=Disk;
  R.cl:=Frec.Sect;
  R.ch:=Frec.Track shr 1;
  R.dh:=Frec.Track and 1;
  R.al:=1;
  R.ah:=2;

  RealIntr($13, R);
  CopyFromDOS(Buf, SizeOf(Buf));
  if (R.flags and CarryFlag) <> 0 Then
    Err:=R.ah
  Else
    Err:=0;
  ReadSect:=Err;
  Exit;
  {$endif}
  {$endif}

End;

Function TMicroDOSDisk.WriteSect(Frec:TFormRec;Var Buf:TBufType):Word;
Var
{$ifdef fpc}
{$ifdef win32}
  _Flag:BOOL;
  dwRet:LongWord;
{$else}
  R:TRealRegs;
  Err           : Byte;
  Disk          : Byte;
{$endif}
{$else}
  _Flag         : Byte;
  Err           : Byte;
  Segbuf,Ofsbuf : Word;
  Disk          : Byte;
{$endif}
Begin
  {$ifndef fpc}
{  Mem[0:DiskAddr]:=$54;}
  Disk :=DiskAddr - $490;

  {  frec.side:=frec.track and 1;
  frec.track:=frec.track shr 1;}

  Segbuf:=Seg(Buf);
  Ofsbuf:=Ofs(Buf);
  Asm
    Push DS
    Push BX
    Push BP
    Mov ES,Segbuf
    Mov BX,Ofsbuf
    Mov DL,Disk
    Mov CL,Frec.Sect
    Mov CH,Frec.Track
    Mov DH,0
    ShR CH,1
    Jnc @R
    Mov DH,1
    @R:Mov AL,1
    Mov AH,3
    Int 13H
    Mov Err,AH
    Lahf
    Mov _Flag,AH
    Pop BP
    Pop BX
    Pop DS
  End;
  If (_Flag And 1) > 0 Then
    WriteSect:=Err
  Else
    WriteSect:=0;
  {$else}
  {$ifdef win32}
  rwp.cyl    := Frec.Track shr 1;
  rwp.head   := Frec.Track and 1;
  rwp.phead  := rwp.head;
  rwp.sector := Frec.Sect;
  rwp.eot    := rwp.sector + 1;

  sp.cyl     := rwp.cyl;
  sp.head    := rwp.head;
  _Flag:=DeviceIoControl(hMST, IOCTL_FDCMD_SEEK, @sp, sizeof(sp), nil, 0, &dwRet, nil);

  if not _Flag Then
  begin
    WriteSect:=GetLastError;
    Exit;
  End;

  _Flag:=DeviceIoControl(hMST, IOCTL_FDCMD_WRITE_DATA, @rwp, SizeOf(rwp), @Buf, {512} SizeOf(TBufType), dwRet, nil);

  if not _Flag Then
    WriteSect:=GetLastError
  Else
    WriteSect:=0;
  {$else}
  dpmi_dosmemfillchar(0, DiskAddr, 1, Chr($54));
  Disk :=DiskAddr - $490;

  CopyToDOS(Buf, SizeOf(Buf));
  R.es:=tb_segment;
  R.bx:=tb_offset;

  R.dl:=Disk;
  R.cl:=Frec.Sect;
  R.ch:=Frec.Track shr 1;
  R.dh:=Frec.Track and 1;
  R.al:=1;
  R.ah:=3;

  RealIntr($13, R);
  if (R.flags and CarryFlag) <> 0 Then
    Err:=R.ah
  Else
    Err:=0;
  WriteSect:=Err;
  Exit;

  {$endif}
  {$endif}
End;

Function TMicroDOSDisk.GetErrorDescription(Track, Sect, ErrorNumber:Byte):String;
Var
  Ios:String;
Begin
  {       If Errornumber = 6 Then Begin
    ErrorMessageBox:=cmYes;
    Exit;
  End;}
  {$ifndef fpc}
  Case ErrorNumber Of
    2: Ios:='Плохой адресный маркер';
    3: Ios:='Диск защищен от записи';
    4: Ios:='Сектор не найден';
    6: Ios:='Смена диска';
    9: Ios:='Сбой контроллера ПДП';
    16:Ios:='Ошибка в контрольном коде';
    $20:Ios:='Сбой контроллера';
    $40:Ios:='Дорожка не найдена';
    128:Ios:='Таймаут';
    $Aa:Ios:='Диск не готов';
    Else
      Ios:=IntToStr(ErrorNumber);
  End;
  {$else}
    Ios:=IntToStr(ErrorNumber);
  {$endif}
  Ios:=' Disk error: '+Ios;
  Ios:=Ios+'. Track='+IntToStr(Track);
  If Sect = 0 Then
    Ios:=Ios+'. Retry?'
  Else
    Ios:=Ios+', Sect='+IntToStr(Sect)+'. Retry?';

  GetErrorDescription:=Ios;

End;

Procedure TMicroDOSDisk.SetBlock(BlockNumber:Word;Ofs:Byte);
var
 i:word;
begin
{ Вычисление координат блока }
  i:=BlockNumber * 2 + Ofs;
 _Frec.sect:=1 + (i mod 5);
 _Frec.track:=_dpb.systrk + (i div 5);
end;

Function TMicroDOSDisk.ReadBlock(BlockNumber:Word;block:_pblock):Byte;
var
  b:word;
  buf:TBufType;
  Errc:Byte;
begin
  Errc:=0;
  If BlockNumber > BlockCount Then
    FillChar(_pblock(pointer(block))^, 2048, $00)
  Else
  Begin
    For b:=0 to 1 do
    begin
      SetBlock(BlockNumber, b);
      SeekTrack(_Frec);
      Errc:=ReadSect(_Frec, Buf);
      If Errc = 0 Then
      Begin
      {$ifndef fpc}
        move(buf,ptr(seg(block^),ofs(block^)+(1024*b))^,1024);
      {$else}
        move(buf,_pblock(pointer(block)+(1024 * b))^, 1024);
      {$endif}
      End
      Else
      {$ifndef fpc}
        { TODO BP }
      {$else}
        FillChar(_pblock(pointer(block)+(1024 * b))^, 1024, $E5);
      {$endif}
    end;
  End;
  ReadBlock:=Errc;
end;

Function TMicroDOSDisk.WriteBlock(BlockNumber:Word;block:_pblock):Byte;
var
   b:word;
   buf:TBufType;
   Errc:Byte;
begin
   Errc:=0;
   If BlockNumber > BlockCount Then
   Else
   Begin
     For b:=0 to 1 do
     begin
       {$ifndef fpc}
       move(ptr(seg(block^),ofs(block^)+(1024*b))^,buf,1024);
       {$else}
       move(_pblock(pointer(block)+(1024 * b))^,buf,1024);
       {$endif}
       SetBlock(BlockNumber, b);
       Errc:=WriteSect(_Frec, Buf);
     end;
   End;
   WriteBlock:=Errc;
end;

Function TMicroDOSDisk.ReadDir(var Catalog:TCatalog):Boolean;
var
   block:_PBlock;
   Errc:Word;
begin
   GetMem(Block,2048);
   ResetDisk;

   ReadDpb;

   Errc:=ReadBlock(0, Block);
   Move(Block^,Catalog[0],2048);
   Errc:= Errc Or ReadBlock(1, Block);
   Move(Block^,Catalog[64],2048);


   FreeMem(Block,2048);
   ReadDir:=Errc = 0;
end;

Procedure TMicroDOSDisk.WriteDir(Catalog:TCatalog);
var
   block:_PBlock;
begin
  GetMem(Block,2048);
  ResetDisk;

  Move(Catalog[0],Block^,2048);
  WriteBlock(0, Block);

  Move(Catalog[64],Block^,2048);
  WriteBlock(1, Block);

  FreeMem(Block,2048);
end;

Procedure TMicroDOSDisk.ReadDpb;
var
  Buf:TBufType;
  Errc:Byte;
  _crc:Byte;
  I:Byte;
begin
  _Frec.Track:=0;
  _Frec.Sect:=1;

  SeekTrack(_Frec);
  Errc:=ReadSect(_Frec, Buf);

  If Errc = 0 Then
  begin
    Move(Buf, _dpb, SizeOf(Dpb));
    _Crc:=$66;
    For I:=0 To 30 Do
      {$ifndef fpc}
      Inc(Mem[Seg(_Dpb):Ofs(_Dpb)+31],Mem[Seg(_Dpb):Ofs(_Dpb)+I]);
      {$else}
      Inc(_Crc, PByteArray(@_Dpb)^[I]);
      {$endif}
    If _Crc <> _Dpb.Crc Then
    _dpb:=dpb;
  end
  else
    _dpb:=dpb;

end;

Function TMicroDOSDisk.GetDiskNameEx:ShortString;
Begin
  GetDiskNameEx:='MST Disk ' + DiskName + ':';
End;

constructor TMicroDOSDiskImage.Init(_FileName:String;Frec:TFormRec);
begin
{  Inherited Init;}
  TMSTDisk.Init;
  _Frec:=Frec;
  FileName:=_FileName;
  {$ifndef fpc}
  {$I-}
  Assign(F,FileName);
  Reset(F,1);
  {$I+}
  {$else}
  hMST:=FileOpen(FileName, fmOpenReadWrite or fmShareDenyWrite);
  {$endif}
end;

destructor TMicroDOSDiskImage.Done;
begin
  {$ifndef fpc}
  Close(F);
  {$else}
  FileClose(hMST);
  {$endif}
  TMSTDisk.Done;
end;

Function TMicroDOSDiskImage.ReadSect(Frec:TFormRec;Var Buf:TBufType):Word;
var
  Pos:LongInt;
begin
  { Frec.Side:=Frec.Track And 1;  }
  { Frec.Track:=Frec.Track ShR 1; }
  { Frec.Sect:=Frec.Sect;         }
  Pos:=(LongInt(Frec.Track) * LongInt(Frec.Scount) + LongInt(Frec.Sect-1)) * 1024;
  {$ifndef fpc}
  {$I-}
{  Seek(F, (LongInt(Frec.Track) * LongInt(Frec.Scount) + LongInt(Frec.Sect-1)) * 1024); }
  Seek(F, Pos);
  BlockRead(F, Buf, SizeOf(Buf));
  {$I+}
  ReadSect:=IOResult;
  {$else}
  If Pos >= FileSeek(hMST, 0, fsFromEnd) Then
  Begin
    FillChar(Buf, SizeOf(Buf), 0);
    ReadSect:=$00;
    Exit;
  End;
//  If FileSeek(hMST, (LongInt(Frec.Track) * LongInt(Frec.Scount) + LongInt(Frec.Sect-1)) * 1024, fsFromBeginning) = -1 Then
  If FileSeek(hMST, Pos, fsFromBeginning) = -1 Then
  Begin
  {$ifdef win32}
    ReadSect:=GetLastOsError;
  {$else}
    ReadSect:=$FF;
  {$endif}
    Exit;
  End;
  If FileRead(hMST, Buf, SizeOf(Buf)) = -1 Then
  {$ifdef win32}
    ReadSect:=GetLastOsError
  {$else}
    ReadSect:=$FF
  {$endif}
  Else
    ReadSect:=0;
  {$endif}
end;

Function TMicroDOSDiskImage.WriteSect(Frec:TFormRec;Var Buf:TBufType):Word;
var
   L:LongInt;
begin
  { Frec.Side:=Frec.Track And 1;  }
  { Frec.Track:=Frec.Track ShR 1; }
  { Frec.Sect:=Frec.Sect;         }

  L:=(LongInt(Frec.Track) * LongInt(Frec.Scount) + LongInt(Frec.Sect-1)) * 1024;
  {$ifndef fpc}
  {$I-}
  Seek(F, (LongInt(Frec.Track) * LongInt(Frec.Scount) + LongInt(Frec.Sect-1)) * 1024);
  BlockWrite(F, Buf, SizeOf(Buf));
  {$I+}
  WriteSect:=IOResult;
  {$else}
  FileSeek(hMST, (LongInt(Frec.Track) * LongInt(Frec.Scount) + LongInt(Frec.Sect-1)) * 1024, fsFromBeginning);
  If FileWrite(hMST, Buf, SizeOf(Buf)) = -1 Then
  {$ifdef win32}
    WriteSect:=GetLastOsError
  {$else}
    WriteSect:=$FF
  {$endif}
  Else
    WriteSect:=0;
  {$endif}
end;

Function TMicroDOSDiskImage.FormatTrack(Frec:TFormRec):Word;
var
  Buf:TBufType;
  Sect:Byte;
begin
  FillChar(Buf,SizeOf(Buf),0);
  Sect:=1;
  While Sect <= Frec.Scount Do
  begin
    Frec.Sect:=Sect;
    WriteSect(Frec, Buf);
    Inc(Sect);
  end;
  FormatTrack:=0;
end;

Function TMicroDOSDiskImage.GetErrorDescription(Track, Sect, ErrorNumber:Byte):String;
begin
   GetErrorDescription:='Error read file. Retry?';
end;

Function TMicroDOSDiskImage.SeekTrack(Frec:TFormRec):Word;
Begin
  SeekTrack:=0;
End;

Function TMicroDOSDiskImage.GetDiskNameEx:ShortString;
Begin
{$Ifdef fpc}
  GetDiskNameEx:='MST Disk image ' + SysUtils.ExtractFileName(FileName);
{$else}
  GetDiskNameEx:='MST Disk image '; { TODO BP }
{$endif}
End;

End.
