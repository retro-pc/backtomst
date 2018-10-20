{/////////////////////////////////////////////////////////////////////////
//
//  Dos Navigator Open Source 1.51.08
//  Based on Dos Navigator (C) 1991-99 RIT Research Labs
//
//  This programs is free for commercial and non-commercial use as long as
//  the following conditions are aheared to.
//
//  Copyright remains RIT Research Labs, and as such any Copyright notices
//  in the code are not to be removed. If this package is used in a
//  product, RIT Research Labs should be given attribution as the RIT Research
//  Labs of the parts of the library used. This can be in the form of a textual
//  message at program startup or in documentation (online or textual)
//  provided with the package.
//
//  Redistribution and use in source and binary forms, with or without
//  modification, are permitted provided that the following conditions are
//  met:
//
//  1. Redistributions of source code must retain the copyright
//     notice, this list of conditions and the following disclaimer.
//  2. Redistributions in binary form must reproduce the above copyright
//     notice, this list of conditions and the following disclaimer in the
//     documentation and/or other materials provided with the distribution.
//  3. All advertising materials mentioning features or use of this software
//     must display the following acknowledgement:
//     "Based on Dos Navigator by RIT Research Labs."
//
//  THIS SOFTWARE IS PROVIDED BY RIT RESEARCH LABS "AS IS" AND ANY EXPRESS
//  OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
//  WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
//  DISCLAIMED. IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE FOR
//  ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
//  DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE
//  GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
//  INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER
//  IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR
//  OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
//  ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//
//  The licence and distribution terms for any publically available
//  version or derivative of this code cannot be changed. i.e. this code
//  cannot simply be copied and put under another distribution licence
//  (including the GNU Public Licence).
//
//////////////////////////////////////////////////////////////////////////}

{$ASMMODE INTEL}
{.$I STDEFINE.INC}
{AK155 = Alexey Korop, 2:461/155@fidonet}
{$R-}

unit FViewer;

interface

uses
  SysUtils,
  Views, Drivers, Objects;

const
  MaxILines = 200; { максимальный индекс масива Lines }
  MaxWrapW = 1023;
  { максимальная ширина для заворачивания
    строк в режиме unwrap }

type
  PComp = ^LongInt;
  PXLat = ^TXlat;
  TXlat = array[Char] of Char;
  {`Таблица перекодировки. Символ в исходной кодировке - индекс,
     соответствующий элемент - символ в новой кодировке `}
  AInt = SmallInt;

type
  TPosArray = array[1..9] of TPoint;

  TFPos = record X: Integer; Y: LongInt end;
  TFPosArray = array [1..9] of TFPos;

type
  PHighliteParams = ^THighliteParams;
  THighliteParams = record
    GenFlags: Word;
    HexFlags: Word;
    DecFlags: Word;
    OctFlagsQ: Word;
    OctFlagsO: Word;
    BinFlags: Word;
    StrFlags: Word;
    RulesBuffer: array[1..$800] of Char;
  end;

  TSize = Comp; {64 bit integer type for file sizes}
type
  LongString = AnsiString;

type
  TUseLFN = Boolean;

type
  PDiz = ^TDIZ;
  TDIZ = record
    {` Описание файла для использования в TFileRec }
    Container: PString;
    {` Полный путь файла описаний. Освобождать его не надо.
       В Арвиде не используется. `}
    DIZText: LongString;
    {` Описание без имени файла. Строки разделяются CrLf`}
    Line: LongInt;
    {` У ритлабов это был номер строки в файле описаний, где
       начинается это описание, но это нигде не использовалось.
       Используется это поле только в Арвиде, но совершенно
       в другом смысле.`}
  end;

type
  PHandleDosStream = ^THandleDosStream;
  THandleDosStream = Object(TDosStream)
    FileName: FNameStr;
    Constructor Init (_FileName: FNameStr; Mode: Word; ExtMode: Word);
    Destructor Done;                                               Virtual;
    Procedure Close;                                               Virtual;
    Procedure Truncate;                                            Virtual;
    Procedure Seek (Pos: LongInt);                                 Virtual;
    Procedure OpenEx (OpenMode: Word; ExtOpenMode: Word);          Virtual;
    Procedure Read (Var Buf; Count: Longint);                      Virtual;
    Procedure Write (Var Buf; Count: Longint);                     Virtual;
  end;

type
  TShortName = String[12];
  PFlName = ^TFlName;
  TFlName = array[TUseLFN] of TShortName;

  PFileRec = ^TFileRec;
  TFileRec = record
    Size: TSize;
    { Если размер неизвестнен, Size=-1 (типично для каталогов) }
    PSize: TSize;
    Owner: PString;
    DIZ: PDiz;
    Yr: Word;
    YrCreat: Word;
    YrLAcc: Word;
    TType: Byte;
    Attr: Word;
    Second: Byte;
    SecondCreat: Byte;
    SecondLAcc: Byte;
    Selected: Boolean;
    UsageCount: Byte; {DataCompBoy}
    FDate, FDateCreat, FDateLAcc: LongInt; {фактически - TDate4}
    FlName: TFlName;
    {см. files.pas }
    Dummy: array[1..SizeOf(ShortString)-SizeOf(TShortName)] of Char;
    {а это место, куда будет свешиваться хвост длинного имени в тех
      случаях, когда заводится локальная переменна типа TFileRec или
      при временном динамическом резервировании в стиле new(PFilerec).
      Нормально динамическое резервирование должно делаться через
      CreateFileRec или NewFileRec, где памяти резервируется ровно
      столько, сколько нужно. Из-за этого фокуса поле FlName
      обязательно должно быть в самом конце этой структуры.
      Копировать длинное имя надо не при помощи ':=', а при помощи
      CopyShortString. AK155 }
    {<filescol.001>}
  end;

  { TFileViewer }

  PFileViewer = ^TFileViewer;
  TFileViewer = object(TView)
    {Cat: этот объект вынесен в плагинную модель; изменять крайне осторожно!}
    Filtr: Boolean;
    NoEdit: Boolean;
    FileName: String; {DataCompBoy}
    VFileName: String; {DataCompBoy}
    Buf: PByteArray;
    Fl: PStream;
    {   UpdateViewTmr: TEventTimer; }
    XDelta, ViewMode, HexPos: AInt;
    SearchActive: Boolean;
    SearchResultVisible: Boolean; {AK155}
    PrevSearchDir: Boolean; {Эта переменная принимается во внимание
      только при SearchResultVisible }
    SearchX: LongInt;
    SB: PView;
    Wrap: Byte; {DataCompBoy}
    Lines: array[0..MaxILines] of record
      Pos: LongInt;
      len: Word;
    end;
    FilePos, FileSize: LongInt;
    NumLines: LongInt;
    ExposedPos, ExposedLine: LongInt; {AK155}
    Cur: TPoint;
    Info: PView;
    BufPos: LongInt;
    BufSize, MaxLines: LongInt;
    BufLines: AInt;
    KillAfterUse, isValid, QuickView, Loaded, HexEdit, BufModified:
    Boolean;
    FakeKillAfterUse: Boolean; {временная пустышка}
    Filter: Byte;
    {   XCoder: TXCoder;}
    MarkPos: TFPosArray;
    CtrlK: Boolean;
    CtrlQ: Boolean;
    HiLite: Boolean; {PZ 2000.06.09}
    ScrollEOF: Boolean; {AK155}
    HiLitePar: THighliteParams;
    constructor Init(var Bounds: TRect; AStream: PStream;
      const AFileName, AVFileName: String;
      ASB: PView; Quick, Hex: Boolean; ViOpt: Byte); {DataCompBoy}
    constructor Load(var S: TStream);
    procedure Store(var S: TStream);
    destructor Done; virtual;
    procedure Draw; virtual;
    function ReadFile(const FName, VFName: String; NewStream: Boolean)
    : Boolean; {DataCompBoy}
    procedure SetState(AState: Word; Enable: Boolean); virtual;
    procedure HandleEvent(var Event: TEvent); virtual;
    procedure CountDown(ANumber: Integer); virtual;
    procedure CountUp(ANumber: Integer); virtual;
    procedure Seek(APos: LongInt);
    procedure MakeLines; virtual;
    function Valid(Command: Word): Boolean; virtual;
    procedure ChangeBounds(var Bounds: TRect); virtual;
    function GetPalette: PPalette; virtual;
    procedure DoHighlite(var B; const S: String; const Attr: String);
    (*    procedure Update; virtual; {AK155} *)
    procedure SeekEof;
    procedure SeekBof;
    function BreakOnStreamReadError: Boolean;
    procedure ChangeFile(FR: PFileRec); virtual;
    private
    procedure AdjustBuf;
  end;

  PFileWindow = ^TFileWindow;
  TFileWindow = object( {TStd}TWindow)
    constructor Init(const FileName, VFileName: String; Hex: Boolean);
    {DataCompBoy}
    function GetPalette: PPalette; virtual;
    function ReactOnCmd: Boolean; virtual;
    procedure ChangeBounds(var Bounds: TRect); virtual;
  end;

const
  CHViewer = #13#14#117#118#199#200#201#202#203#204;
  CViewer = #6#7#8#9#10#11#12#13;
  // CViewWindow = #112#113#114#115#116#117#118#199#200#201#202#203#204;
  CViewWindow = #8#9#10#11#12#13#14#15;

type
  TViewSearch = record
    What: String[250];
    Opts: Word;
    Dir: Word
  end;

const
  cmChangeValue = 9990;
  SearchString: TViewSearch = (What: ''; Opts: 0; Dir: 0);
  MaxStringLength = 255;

  {Cat: порядок переменных не менять, сохраняются подряд в DSK-файл}

var
  LastViewerBounds: TRect;
  LastViewerDeskSize: TPoint {= (X:0;Y:0)};
  LastEditDeskSize: TPoint {= (X:0;Y:0)};

implementation

uses
  Dos, {Commands,} Memory, Dialogs, MsgBox, StdDlg, App, FV_Const {$ifdef win32}, Messages, Mst_Ext {$endif};

{$include koi2asc.inc}

procedure XLatBuf(var B; Len: Integer; const XTable: TXLat);
Var
  W:LongInt;
Begin
  For W:=0 To Len - 1 Do
    PByteArray(@B)^[W]:=Byte(XTable[Char(PByteArray(@B)^[W])]);
End;


Type
  AWord = Word;
  PAWordArray = ^TAWordArray;
  TAWordArray = array[0..MaxWords-1] of AWord;


function MaxAvail: LongInt;
begin
  { MaxAvail := MemAdjust(System.MaxAvail);}
  MaxAvail := $FFFF;
end;

const
  ViewerBufSize = (1+MaxILines)*(MaxWrapW+2);
  HexStr: array[0..$F] of Char = '0123456789ABCDEF';

Var
  FreeStr:String;
  TempFile: String;

Type
  Str8 = String[8];

function i32(x: LongInt): LongInt;
begin
  i32 := Round(x);
end;

function MinBufSize(x: LongInt; y: LongInt): LongInt;
begin
  MinBufSize := y;
  if MinBufSize > x then
    MinBufSize := i32(x);
end;

function HexChar(a: Byte): Char;
begin
  a := a and 15;
  if a < 10 then
    HexChar := Char(Ord('0')+a)
  else
    HexChar := Char(Ord('A')+a-10);
end;

procedure Hex8Lo(L: LongInt; var HexLo :array of char);
type
  ChArr = array[1..8] of Char;
var
  i: integer;
begin { Hex8Lo }
  for i := 1 to 8 do ChArr(HexLo)[i] := HexStr[L shr (32-(i*4)) and $F];
end { Hex8Lo };


function Hex8(a: LongInt): Str8;
var
  s: Str8;
begin
  s[0] := #8;
  Hex8Lo(a, s[1]);
  Hex8 := s;
end;

function HexFilePos(C: Comp): String;
var
  FilePosRec: record lo32, hi32: Longint end absolute C;
begin
  HexFilePos := HexChar($0F and FilePosRec.hi32) + Hex8(FilePosRec.lo32);
end;

function StoI(const s: String): LongInt;
var
  i: LongInt;
  j: Integer;
begin
  Val(s, i, j);
  StoI := i;
end;

function PosChar(C: Char; const S: String): Byte;
{Cat}
var
  I: Integer;
begin { PosChar }
  for I := 1 to Length(S) do
    if S[I] = C then
    begin
      PosChar := I;
      Exit;
    end;
  PosChar := 0;
end { PosChar };
{/Cat}

const
  SCViewer: String[Length(CViewer)] = CViewer;
  SCHViewer: String[Length(CHViewer)] = CHViewer;
  SCNViewer: String[Length(CInputLine)] = CInputLine;
  SCViewWindow: String[Length(CViewWindow)] = CViewWindow;

function TFileViewer.GetPalette: PPalette;
begin
  GetPalette := @SCViewer;
end;

function TFileWindow.GetPalette: PPalette;
begin
  GetPalette := @SCViewWindow;
end;

{ TFileViewer }

procedure TFileViewer.ChangeBounds(var Bounds: TRect);
var
  R: TRect;
begin
  inherited ChangeBounds(Bounds);
  if  (Wrap > wmNone) or (ViewMode = vmDump) then
    MakeLines;
  DrawView;
  {
  if Info <> nil then
  begin
    R := Bounds;
    R.A.Y := R.B.Y - 1;
    Dec(R.B.X, 2);
    Info^.SetBounds(R)
  end
  }
end;

{AK155
   Обеспечить буфер подходящего размера. Этот размер не
превосходит размера файла. Прежний буфер, если он был
не такого размера, освобождается }
procedure TFileViewer.AdjustBuf;
var
  NewBufSize: LongInt;
begin
  NewBufSize := MinBufSize(FileSize, ViewerBufSize);
  if  (Buf <> nil) and (NewBufSize = BufSize) then
    Exit;
  if Buf <> nil then
    FreeMem(Buf, BufSize);
  if MaxAvail < NewBufSize then
    NewBufSize := MaxAvail;
  BufSize := NewBufSize;
  GetMem(Buf, BufSize);
end;

{AK155
   Автодочитывание файла, если на экране виден его конец }
(*procedure TFileViewer.Update;
begin
  inherited Update;
  if  ( (EditorDefaults.ViOpt and vbfAutoscroll) <> 0) and
    not BufModified and
    not SearchResultVisible and
      (ViewMode = vmText) and
      (ExposedPos+FilePos = FileSize) and
    TimerExpired(UpdateViewTmr)
  then
    begin
    SeekEof;
    NewTimer(UpdateViewTmr, 500); { обновлять 2 раза в секунду }
    end;
  end;*)

constructor TFileViewer.Init(var Bounds: TRect; AStream: PStream;
        const AFileName, AVFileName: String;
        ASB: PView; Quick, Hex: Boolean; ViOpt: Byte); {DataCompBoy}
var
  C: Char;
begin
  inherited Init(Bounds);
  ViewMode := vmText;
  NoEdit:=True;
  { XCoder.Init(8);}
  FillChar(MarkPos, SizeOf(MarkPos), $FF);
  HelpCtx := hcView;
  GrowMode := gfGrowHiX+gfGrowHiY;
  Options := Options or ofSelectable or (LongInt(Quick)*ofTopSelect);
  EventMask := $FFFF;
  SB := ASB;
  QuickView := Quick;
  Buf := nil;
  isValid := True;
  Loaded := False;
  KillAfterUse := False;
  Wrap := wmNone; { 0 }
  if {EditorDefaults.ViOpt and} ViOpt and vbfWrap <> 0 then
    Wrap := wmWidth; { 1 }
  if {EditorDefaults.ViOpt and} ViOpt and vbfWordWrap <> 0 then
    Wrap := wmWords; { 2 }
  ViewMode := {EditorDefaults.ViOpt and} ViOpt and Byte(Hex);
  Fl := AStream;
  if  (AFileName = '') and (Fl = nil) then
    Exit;
  TempFile := '';

  {$I-}
  if Fl = nil then
    ReadFile(AFileName, AVFileName, True)
  else if Fl^.Status = stOK then
    ReadFile(' ', ' ', False);
  {$I+}
  if IOResult <> 0 Then
    Exit;

end { TFileViewer.Init };

destructor TFileViewer.Done;
begin
  EnableCommands([cmUnWrap]);
  if Buf <> nil then
    FreeMem(Buf, BufSize);
  Buf := nil;
  if Fl <> nil then
    Dispose(Fl, Done);
  Fl := nil;
  Info := nil;
  inherited Done;
end;

procedure TStream_ReadStrV(Stream:TStream; var S: String);
var
  L: LongInt;
begin
  L := 0;
  Stream.Read(L, 1);
  if L > 0 then
  begin
    SetLength(S, L);
    Stream.Read(S[1], L);
  end
  else
    S := '';
end;


constructor TFileViewer.Load(var S: TStream);
var
  FP: LongInt;
begin
  inherited Load(S);
  NoEdit := False;
  BufModified := False;
  GetPeerViewPtr(S, SB);
  GetPeerViewPtr(S, Info);
  TStream_ReadStrV(S, FileName);
  {S.Read(FileName[0], 1); S.Read(FileName[1], Length(FileName));}
  TStream_ReadStrV(S, VFileName);
  {S.Read(VFileName[0], 1); S.Read(VFileName[1], Length(VFileName));}
  S.Read(FP, SizeOf(FP));
  S.Read(QuickView, 1);
  S.Read(Wrap, 1);
  {???}
  S.Read(FakeKillAfterUse, 1);
  KillAfterUse := False;
  S.Read(Filter, 1);
  S.Read(ViewMode, 2);
  {  XCoder.Load(S);}
  S.Read(MarkPos, SizeOf(MarkPos));
  Fl := nil;
  Buf := nil;
  isValid := True;
  Loaded := True;
  if  (FileName = '') and (VFileName = '') then
    isValid := False
  else
  begin
    {$I-}
    ReadFile(FileName, VFileName, True);
    Seek(FP);
    isValid := True;
    {$I+}
    {AK155 так бывает, например, при перезапуске DN
       с запомненным просмотром на отсутствующей дискете }
  end;
end { TFileViewer.Load };

procedure TFileViewer.Store(var S: TStream);
var
  FP: LongInt;
begin
  inherited Store(S);
  PutPeerViewPtr(S, SB);
  PutPeerViewPtr(S, Info);
  S.WriteStr(@FileName); {S.Write(FileName[0], 1 + Length(FileName));}
  S.WriteStr(@VFileName); {S.Write(VFileName[0], 1 + Length(VFileName));}
  FP := FilePos+LongInt(BufPos);
  S.Write(FP, SizeOf(FP));
  S.Write(QuickView, 1);
  S.Write(Wrap, 1);
  S.Write(FakeKillAfterUse, 1);
  S.Write(Filter, 1);
  S.Write(ViewMode, 2);
  {  XCoder.Store(S);}
  S.Write(MarkPos, SizeOf(MarkPos));
end;

procedure XDumpStr(var S: String; var B; Addr: Comp; Count: LongInt;
     Filter: Byte);
begin
  S := HexFilePos(Addr)+' ';
  asm
    push ESI
    push EDI
    push EBX
    push ECX
    mov  ESI, B
    mov  ECX, Count
    mov  EDI, S
    mov  EBX, 11
    mov  AH, Filter
    jcxz @@3
    @@1:
    mov  AL, [ESI]
    or   AH, AH
    jz   @@2
    cmp  AL, 32
    jnc  @@4
    @@5:
    mov  AL, 250
    jmp  @@2
    @@4:
    cmp  AH, 1
    jnz  @@2
    cmp  AL, 128
    jnc  @@5
    @@2:
    mov  [EDI+EBX], AL
    inc  byte ptr [EDI]
    inc  ESI
    inc  EBX
    loop @@1
    @@3:
    pop  ECX
    pop  EBX
    pop  EDI
    pop  ESI
  end;
end { XDumpStr };

{ размер поля табуляции }
function GetTabSize: Word;
var
  TS: Word;
begin
  GetTabSize := 8;
end;
function DumpStr
  {` Сформировать представление Hex+Text c 9-значным
     адресом слева. Первый Hex-символ -  S[12]`}
  (var B; Addr: Comp; Count: Integer; Filter: Byte): String;
var
  S: String;
  i, j, l, l0, l1: Byte;
  Buf: array[0..$FF] of Byte absolute B;
begin { DumpStr }
  DumpStr := '';
  if Count <= 0 then
    Exit;
  S := HexFilePos(Addr);
  j := 10;
  SetLength(S, Count*4+12);
  S[j] := ':';
  S[j+1] := ' ';
  Inc(j, 2);
  S[j+Count*3] := Char($B3);
  S[j+1+Count*3] := ' ';
  for i := 0 to Count-1 do
  begin
    l := Buf[i];
    l0 := (l shr 4)+$30;
    l1 := (l and $0F)+$30;
    if l0 > $39 then
      Inc(l0, 7);
    if l1 > $39 then
      Inc(l1, 7);
    if Filter <> 0 then
    begin
      if l < $20 then
        l := 250
      else if (Filter = 1) and (l >= $80) then
        l := 250;
    end;
    S[j] := Char(l0);
    Inc(j);
    S[j] := Char(l1);
    Inc(j);
    S[j] := ' ';
    Inc(j);
    S[i+13+Count*3] := Char(l);
  end;
  DumpStr := S;
end { DumpStr };

(*procedure MoveColor(var Buf:Word; Num: Word; Attr: Byte);register;
  assembler;
asm
   push EAX
   push EBX
   push ECX
   mov    EBX,Buf
   xor    ECX,ECX
   mov    CX, Num
   or     ECX,ECX
   jz     @End
   mov    AL,Attr
@Rep:
   mov    [EBX+1],al
   add    bx,2
   loop   @Rep
@End:
   pop ECX
   pop EBX
   pop EAX
end; *)

procedure  MoveColor(var Buf; Num: Word; Attr: Byte);
var
  I:Word;
Type
  TB = Array[0..0] of byte;
begin
  I:=1;
  {   while true do}
  While Num > 0 do
  begin
    {      if Num = 0 Then Break;}
    Dec(Num);
    {$R-}
    TB(Buf)[I]:=Attr;
    {$R+}
    Inc(I,2);
  end;
end;

function Min(X,Y: Longint): Longint; inline;
begin
  Min := Y;
  if X < Y then
    Min := X;
end;
Function Max( a,b : Longint ) : Longint; inline;
begin
  if a > b then
    Max := a
  else
    Max := b;
end;

procedure TPoint_Assign(R:TPoint;AX, AY: LongInt);
begin
  R.X := AX;
  R.Y := AY;
end;

procedure TFileViewer.Draw;
var
  B: TDrawBuffer;
  C: Byte;
  I, K, M, Src: Integer;
  J: LongInt;
  L: LongInt;
  S, SZ: String;
  IZ: Byte;
  TS: Word;
  C1: Byte;
  C2: Char;
  HP: String[6];
  CC: array[1..8] of Byte;
  SaveXDelta: Word;
  {$IFDEF DisAsm}
  D: XCHGData; {GRM!}
  {$ENDIF}
  SearchLineNum: Integer;
  {номер строки на экране с найденным тестом или -1 }
  SearchTextStart: Word;
  {X-координата в окне начала этого текста }
  ExpandTabs: Boolean;
  { Табуляции заменять на пробелы }
var
  W, W2, W3: Integer;
  WDH: Integer;
begin { TFileViewer.Draw }
  {$R-}
  ExposedPos := Lines[0].Pos;
  for I := 1 to 8 do
    CC[I] := GetColor(I);
  TS := GetTabSize;
  ExpandTabs := {EditorDefaults.EdOpt and} ebfTRp <> 0;
  if  (Buf = nil) and not QuickView and
      not (VFileName = ' ')
      {AK155 11-01-2004
      бывает в просмотре dbf при просмотре memo, когда memo-файл то ли
      пустой, то ли битый. VFileName = ' ' - это внешний поток и при
      нормальной работе , вроде, не должно быть Buf = nil}
  then
  begin
    ReadFile(FileName, VFileName, True);
    BufPos := 0;
    MakeLines;
  end
  (* {AK155 11-01-2003 эти бредовые проверки, вероятно, когда-то
        служили для компенсации  последствий каких-то багов.
        Но после того, как BufSize стал не $8000, а поболее, они
        стали в прежнем виде вредны, а обновлять их не хочется,
        так как самих багов, наверно, уже давно нет}
  else
  if (BufPos < 0) or (BufPos > BufSize + 20000) or
     (BufPos > 65000) then
  begin
    BufPos:=0;
    MakeLines;
  end *);
  C := CC[1];
  {AK155  if Info <> nil then Info^.DrawView;}
  if {(FileName = '') or }(Buf = nil) then
  begin
    HideCursor;
    inherited Draw;
    Exit;
  end;
  SearchResultVisible := SearchActive;
  SearchResultVisible:=False;
  case ViewMode of
    vmHex:
    begin
      DisableCommands([cmUnWrap]);
      HexPos := (Size.X-12) div 4;
      if HexPos <= 0 then
        HexPos := 1;
      XDelta := 0;
      Src := 0;
      if not ScrollEOF then
        {AK155}
      begin
        while (LongInt(Cur.Y*HexPos)+BufPos+FilePos >= FileSize) do
          Dec(Cur.Y);
        while (LongInt(Cur.Y*HexPos)+BufPos+FilePos+Cur.X
                div (Byte(HexEdit)+1) >= FileSize)
        do
          Dec(Cur.X);
      end;
      if Cur.Y < 0 then
      begin
        W := -Cur.Y;
        Cur.Y := 0;
        CountUp(W);
      end
      else if Cur.Y >= Size.Y then
      begin
        W := Cur.Y-Size.Y+1;
        Dec(Cur.Y, W);
        CountDown(W);
      end;
      W := BufPos;
      L := FilePos+LongInt(BufPos);
      if HexEdit
      then
        SetCursor(11+(Cur.X div 2)*3+Cur.X and 1, Cur.Y)
      else
        SetCursor(12+HexPos*3+Cur.X, Cur.Y);
      ShowCursor;
      for I := 0 to Size.Y-1 do
      begin
        {MoveChar(B[XDelta], ' ', C, Size.X);} {???}
        if Size.X+XDelta > 255 then
        begin
          WDH := 255-XDelta;
          if WDH < 0 then
            WDH := 0;
        end
        else
          WDH := Size.X;
        MoveChar(B[XDelta], ' ', C, WDH);
        J := MinBufSize(FileSize-L, HexPos);
        if J > 0 then
        begin
          S := DumpStr(Buf^[W], L, J, Filter);
          W2 := Pos(#179, S);
          SetLength(SZ, Length(S)-W2);
          for IZ := 1 to Length(SZ) do
            if S[W2+IZ] = #0 then
            begin
              SZ[IZ] := #1;
              S[W2+IZ] := '.';
            end
            else
              SZ[IZ] := #0;
            XLatBuf(S[W2+1], Length(S)-W2, koi2asc);
          {-DataCompBoy & Axel: apply filter-}
          case Filter of
            0:
              ;
            1:
              for W3 := W2+1 to Length(S) do
              if not (Byte(S[W3]) in [32..127]) then
                S[W3] := #250;
            else {case}
              for W3 := W2+1 to Length(S) do
                if not (Byte(S[W3]) in [32..255]) then
                  S[W3] := #250;
          end {case};
          {-DataCompBoy & Axel: done-}
          if J = HexPos then
            Drivers.MoveStr(B, S, C)
          else
          begin
            Drivers.MoveStr(B, Copy(S, 1, J*3+10), C);
            Drivers.MoveStr(B[10+HexPos*3], Copy(S, J*3+11,
              MaxStringLength), C);
          end;

          for IZ := 1 to Length(SZ) do
            if SZ[IZ] = #1 then
              MoveColor(B[11+HexPos*3+WORD(IZ)], 1, (CC[1] and $F0)+(CC[3] and $0F));
          if SearchActive then
          begin
            if  (L <= SearchX) and (L+J > SearchX) then
            begin
              Cur.Y:= I;
              Cur.X := i32(SearchX-L)*2;
              if HexEdit then
                SetCursor(11+(Cur.X div 2)*3+Cur.X and 1, Cur.Y)
              else
                SetCursor(12+HexPos*3+Cur.X, Cur.Y);
              ShowCursor;
              Src := Min(i32(L+J-SearchX), Length(SearchString.What));
              MoveColor(B[11+i32(SearchX-L)*3], Src*3-1, CC[2]);
              MoveColor(B[12+HexPos*3+i32(SearchX-L)], Src, CC[2]);
              Src := Length(SearchString.What)-Src;
            end
            else if Src > 0 then
            begin
              K := Min(Src, J);
              MoveColor(B[11], K*3-1, CC[2]);
              MoveColor(B[12+HexPos*3], K, CC[2]);
              Dec(Src, J);
            end;
          end
          else {+piwamoto}
            if I = Cur.Y then
            begin
              K := Cur.X div (1+Byte(HexEdit));
              MoveColor(B[11+K*3], 2, CC[2]);
              { MoveColor(B[11+K*3], 2, 2);}
              MoveColor(B[12+HexPos*3+K], 1, CC[2]);
            end; {-piwamoto}
          Inc(W, J);
          L := L + J;
        end;
        {WriteLine(0, I, Size.X, 1, B[XDelta]);} {???}
        WriteLine(0, I, WDH, 1, B[XDelta]);
      end;
    end;
    vmDump:
    begin
      DisableCommands([cmUnWrap]);
      HideCursor;
      HexPos := ((Size.X-10) div 16)*16;
      if HexPos < 16 then
        HexPos := 16;
      W := BufPos;
      L := FilePos+LongInt(BufPos);
      Src := 0;
      for I := 0 to Size.Y-1 do
      begin
        {MoveChar(B[XDelta], ' ', C, Size.X);}
        if Size.X+XDelta > 255 then
        begin
          WDH := 255-XDelta;
          if WDH < 0 then
            WDH := 0;
        end
        else
          WDH := Size.X;
        MoveChar(B[XDelta], ' ', C, WDH);
        J := MinBufSize(FileSize-L, HexPos);
        if J > 0 then
        begin
          XDumpStr(S, Buf^[W], L, J, Filter); //!!s
          XLatBuf(S[10], Length(S)-9, koi2asc);
          Drivers.MoveStr(B, S, C);
          if SearchActive then
          begin
            if  (L <= SearchX) and (L+J > SearchX) then
            begin
              Src := Min(i32(L+J-SearchX), Length(SearchString.What));
              MoveColor(B[9+i32(SearchX-L)], Src, CC[2]);
              Src := Length(SearchString.What)-Src;
            end
            else if Src > 0 then
            begin
              MoveColor(B[9], Min(Src, J), CC[2]);
              Dec(Src, J);
            end;
          end;
          Inc(W, J);
          L := L + J;
        end;
        WriteLine(0, I, WDH, 1, B[XDelta]);
      end;
      {$IFNDEF DisAsm}
    end
      {$ELSE}
  end;
  {GRM!}
  vmAsm:
begin
  DisableCommands([cmUnWrap]);
  XDelta := 0;
  L := FilePos+LongInt(BufPos);
  D.MemBuff := Buf;
  D.Offset := BufPos;
  XDelta := 0;

  SetCursor(Cur.X, Cur.Y);
  ShowCursor;
  for I := 0 to Size.Y-1 do
  begin
    if Size.X+XDelta > 255 then
    begin
      WDH := 255-XDelta;
      if WDH < 0 then
        WDH := 0;
    end
    else
      WDH := Size.X;
    MoveChar(B[XDelta], ' ', C, WDH);
    if L < FileSize-1 then
    begin
      if Cur.Y = I then
        HexPos := i32(L-FilePos-BufPos)+((Cur.X-10) div 2);
      D.InstrMaxLen := MinBufSize(FileSize-L, 15);
      {Draw - doesn't matter}
      ScanCode(D);
      S := HexFilePos(L)
      +': '+D.CodeStr+Strg(' ', 29-Length(D.CodeStr))+
      D.Command+Strg(' ', 10-Length(D.Command))+
      D.Operands;
      Drivers.MoveStr(B, S, C);
      L := L + D.InstrLen;
    end;
    WriteLine(0, I, WDH, 1, B[XDelta]);
  end;
end
      {GRM!}
      {$ENDIF} {DisAsm}
    else {case}
    begin {vmText}
      ExposedLine := 0;
      EnableCommands([cmUnWrap]);
      {ak155        HideCursor;}
      { возможный сдвиг XDelta, чтобы стал виден найденный текст,
и определение его X-позиции (с учетом табуляций) для будущей раскраски }
      SearchLineNum := -1;
      if SearchActive then
      begin
        for I := 0 to Size.Y-1 do
        begin
          J := i32(SearchX-FilePos-Lines[I].Pos);
          if  (J >= 0) and (J < Lines[I].len) then
          begin
            if not ExpandTabs then
              W := J
            else
            begin
              W := 0;
              for M := Lines[I].Pos to Lines[I].Pos+J-1 do
              begin
                if Buf^[M] = 9 then
                  Inc(W, TS-(W mod TS))
                else
                  Inc(W);
              end;
            end;
            if  (XDelta+Size.X < W+Length(SearchString.What))
                or (XDelta > W)
            then
              XDelta := W+(Length(SearchString.What)-Size.X) div 2;
            if XDelta < 0 then
              XDelta := 0;
            SearchLineNum := I;
            SearchTextStart := W-XDelta;
            Break;
          end;
        end;
      end;

      for I := 0 to Size.Y-1 do
      begin
        MoveChar(B[0], ' ', C, Size.X);
        S := '';
        if  (Lines[I].Pos >= 0) then
        begin
          ExposedLine := I;

          {-DataCompBoy: Expand tabs...-} {AK155: и применить фильтр }
          W := 0;
          for M := Lines[I].Pos to Lines[I].Pos+Lines[I].len-1 do
          begin
            C2 := Char(Buf^[M]);
            if  (C2 = #9) and ExpandTabs then
              repeat
                Inc(W);
                if W > XDelta then
                  S[W-XDelta] := ' ';
              until W mod TS = 0
            else
            begin
              Inc(W);
              if W > XDelta then
                S[W-XDelta] := C2;
            end;
            if W-XDelta > Size.X then
              Break;
          end;
          if W > XDelta then
          begin
            SetLength(S, W-XDelta);
            XLatBuf(S[1], Length(S), Koi2Asc);
            {Cat: фильтр перенесён сюда - он должен быть использован
      уже после применения таблицы перекодировки}
            case Filter of
              1:
                for W := 1 to Length(S) do
                if not (Byte(S[W]) in [32..127]) then
                  S[W] := #250;
              2:
                for W := 1 to Length(S) do
                if not (Byte(S[W]) in [32..255]) then
                  S[W] := #250;
            end {case};
            {/Cat}
            MoveStr(B, S, C (*, Filter, TS*));
            if HiLite and not QuickView then
            begin
              (*              Highlites(Length(S), @S[1], HiLitePar);*)
              C1 := C and $F0; { Background }
              SetLength(HP, 6); { Attr. size }
              HP[Ord(hhComment)] := Chr(CC[3]); { Comments   }
              HP[Ord(hhNumber)] := Chr(C1 or (CC[6] and 15));
              { Numbers    }
              HP[Ord(hhString)] := Chr(C1 or (CC[5] and 15));
              { Strings    }
              HP[Ord(hhSymbol)] := Chr(C1 or (CC[4] and 15));
              { Symbols    }
              HP[Ord(hhKeyword1)] := Chr(C1 or (CC[7] and 15));
              { Keywords 1 }
              HP[Ord(hhKeyword2)] := Chr(C1 or (CC[8] and 15));
              { Keywords 2 }
              DoHighlite(B, S, HP);
            end;
          end;

        end;
        if I = SearchLineNum then
          { раскраска найденного текста }
          MoveColor(B[SearchTextStart], Length(SearchString.What), CC[2]);
        WriteLine(0, I, Size.X, 1, B[0]);
      end;
    end;
    if ExposedLine > MaxLines then
      ExposedPos := Lines[ExposedLine].Pos+Lines[ExposedLine].len
    else if Lines[ExposedLine+1].Pos < 0 then
      ExposedPos := BufSize
    else
      ExposedPos := Lines[ExposedLine+1].Pos
      end {case};
  if Info <> nil then
    Info^.DrawView;
{$R+}
  end { TFileViewer.Draw };

procedure UpStr(var s: String);
begin
  { XLatBuf(s[1], Length(s), UpCaseArray);}
end;

function UpStrg(s: String): String;
begin
  UpStr(s);
  UpStrg := s;
end;


function TFileViewer.ReadFile(const FName, VFName: String; NewStream: Boolean)
      : Boolean; {DataCompBoy}
var
  {CodePageDetector: TCodePageDetector;}
  I, J: Integer;
  P: Pointer;
  Macros: PCollection;
  ClusterLen: TSize;
  NumFiles, NumDirs: Integer;
  DirLen: TSize;
  DirString: String;
  ReadDir: Boolean;
  Nm: String; {John_SW 14-09-2002}
  Xt: String; {John_SW 14-09-2002}
begin
  ReadFile := True;
  if Buf <> nil then
    FreeMem(Buf, BufSize);
  Buf := nil;
  BufModified := False;
  isValid := True;
  FileName := FName;
  VFileName := VFName;
  if NewStream then
  begin
    if Fl <> nil then
      Dispose(Fl, Done);
    Fl := nil;
    if FName = '' then
      Exit;
    Fl := New(PHandleDosStream, Init(FName, stOpenRead, fmOpenRead or fmShareDenyNone));
  end;

  { Если FName - имя каталога, то формируем буфер (без Stream) с
текстовыми данными о содержимом каталога. Это используется в QuickView,
если куросор стоит на каталоге AK155}
  ReadDir := True;
  I := Length(FName);
  if Copy(FName, I-2, 3) = '\..' then
  begin
    SetLength(FileName, I-3);
    DirString := FileName;
  end
  else if (I = 2) and (FileName[2] = ':') then
    DirString := FileName
    {так бывает, например, при перезапуске
     DN с запомненным состоянием с Branch в корне диска }
  else if (FileName = ' ') or not IsDir(FileName) then
    {Cat: проверка на пробел нужна, т.к. IsDir вернёт для него True, что нас
        не устраивает, поскольку пробел означает использование просмотрщика
        не для конкретного файла, а для заданного конструктору потока}
    ReadDir := False;
  (*  if ReadDir then
    begin
    DirLen := CountDirLen(FileName, True, ClusterLen, NumFiles, NumDirs);
    DirString := FileName+#$0D#$0A#$0D#$0A+
      GetString(dlDirectories)+': '+FStr(NumDirs)+#$0D#$0A#$0D#$0A+
      GetString(dlDIFiles)+': '+FStr(NumFiles-NumDirs)+#$0D#$0A#$0D#$0A+
      GetString(dlDIBytes)+': '+FStr(DirLen);
    BufSize := Length(DirString);
    BufPos := 0;
    FilePos := 0;
    FileSize := BufSize;
    GetMem(Buf, 100);
    Move(DirString[1], Buf^, Length(DirString));
    MakeLines;
    Fl^.Status := stOK; { сбрасываем stInitError }
    Exit;
    end;*)
  BreakOnStreamReadError;
  {см. flpanelx, TFilePanelRoot.SendLocated;}

  (*  if (not ExistFile(FName) or isDir(FName)) and
     (FName <> '') and (FName <> ' ') then begin ReadFile:=false; Exit; end;
*)
  Macros := nil;
  FSplit(VFName, FreeStr, Nm, Xt); {John_SW 14-09-2002}
  {PZ 2000.06.09 }
  if  ({EditorDefaults.ViOpt and} vbfHlt) <> 0 then
    HiLite := False;{Macro.InitHighLight(Nm+Xt, HiLitePar, Macros, nil);}
  {PZ end}
  ScrollEOF := ({EditorDefaults.ViOpt and} vbfScrollAfterEOF) <> 0;
  {AK155}
  FileSize := Fl^.GetSize;
  FilePos := 0;
  I := 1;
  NumLines := 1;
  if FileSize < 0 then
    FileSize := 0;
  AdjustBuf;
  {  if SB <> nil then
    PViewScroll(SB)^.MaxV := FileSize;}
  Seek(0);
  XDelta := 0;
  if  (UpStrg(VFileName) <> UpStrg(FileName)) then
  begin
    KillAfterUse := True;
    Filtr := True;
  end
  else
    Filtr := False;
  BreakOnStreamReadError;
  { XCoder.KeyMap := ProcessDefCodepage(DefCodePageView); }
  { if XCoder.KeyMap = kmNone then
    begin
    CodePageDetector.Init;
    CodePageDetector.CheckString(PChar(Buf), BufSize);
    XCoder.KeyMap := CodePageDetector.DetectedCodePage;
    XCoder.UseKeyMap;
    end; }
end { TFileViewer.ReadFile };

procedure TFileViewer.ChangeFile(FR: PFileRec);
  begin
  end;
Const
  BreakChars: set of Char = [',', ' ', '[', ']', '{', '}', '(', ')',
  ':', ';', '.', '^',
  '&', '*', '!', '#', '$', '/', '\', '"', '%', '>', '<',
  '-', '+', '=', '|', '?', #13, #10, #9, #26, #12, '@'];

procedure TFileViewer.SetState(AState: Word; Enable: Boolean);
begin
  inherited SetState(AState, Enable);
  if  (AState and (sfActive+sfSelected) <> 0) then
  begin
    if GetState(sfSelected) and (Owner^.GetState(sfActive)) then
    begin
      if SB <> nil then
      begin
        SB^.Show;
        SB^.EventMask := $FFFF
      end;
      DrawView
    end
    else if SB <> nil then
    begin
      SB^.Hide;
      SB^.EventMask := 0;
    end;
  end;
  if  (Info <> nil) then
    if  (AState and sfDragging <> 0)
        or (AState and (sfSelected+sfActive) <> 0)
    then
      Info^.Draw;
end { TFileViewer.SetState };

procedure TFileViewer.Seek(APos: LongInt);
var
  NewPos: LongInt;
begin
  if Buf = nil then
    Exit;
  FileSize := Fl^.GetSize;
  if APos < 0 then
    APos := 0;
  FilePos := APos;
  if FilePos < 0 then
    FilePos := 0;
  if FilePos = 0 then
  begin
    AdjustBuf;
    if Buf = nil then
      Exit;
  end;
  if APos+BufSize >= FileSize then
    FilePos := FileSize-BufSize;
  Fl^.Seek(FilePos);
  if  (FileSize-FilePos < BufSize) then
  begin
    FreeMem(Buf, BufSize);
    BufSize := Max(i32(FileSize-FilePos), 0);
    Buf := MemAlloc(BufSize);
    if Buf = nil then
      Exit;
  end;
  BufPos := i32(APos-FilePos);
  if BufPos < 0 then
    BufPos := 0;
  if BufPos >= BufSize then
    BufPos := BufSize-1;
  Fl^.Read(Buf^, BufSize);
  BreakOnStreamReadError;
  If FileSize > 0 Then
    MakeLines;
  NewPos := FilePos+BufPos;
  Message(SB, evCommand, cmChangeValue, @NewPos);
end { TFileViewer.Seek };

procedure TFileViewer.MakeLines;
var
  K: LongInt;
  LineLen: LongInt;
  LineStart: LongInt;
  TabsWith: LongInt; { Tab characters additional with }
  MaxX: LongInt;
  LineSeparatorLen: LongInt;
  TabSize: Integer;
  CurChar, NextChar: Byte;
  WrappedLine: Boolean;
  {$IFDEF DisAsm}
  X: XCHGData; {GRM!}
  {$ENDIF}
label
  LineBegin;
begin
  if Buf = nil then
    Exit;
  LineStart := BufPos;
  LineLen := BufSize-LineStart;
  FillChar(Lines, SizeOf(Lines), $FF); {AK155}
  TabSize := GetTabSize;
  MaxLines := MaxILines;
  case ViewMode of
    vmHex, vmDump:
    begin
      MaxX := 255;
      LineLen := BufPos;
      for K := 0 to MaxLines do
      begin
        Lines[K].Pos := LineLen;
        Lines[K].len := HexPos;
        Inc(LineLen, HexPos);
      end;
      {$IFNDEF DisAsm}
    end
      {$ELSE}
  end;
  {GRM!}
  vmAsm:
begin
  MaxX := 255;
  X.MemBuff := Buf;
  X.Offset := BufPos;
  for K := 0 to MaxLines do
  begin
    Lines[K].Pos := X.Offset;
    X.InstrMaxLen := MinBufSize(FileSize-X.Offset-FilePos-1, 15);
    ScanCode(X);
    Lines[K].len := X.InstrLen;
    if X.InstrLen = 0 then
      Lines[K].Pos := -1;
  end;
end
      {GRM!}
      {$ENDIF}
    else {vmText}
    begin
      if Wrap > wmNone then
        MaxX := Size.X
      else
        MaxX := MaxWrapW;
      WrappedLine := False;
      for K := 0 to MaxLines do
      begin {-DataCompBoy-}
        {AK155}
        LineBegin:
        if LineStart >= BufSize then
        begin
          Lines[K].Pos := -1;
          Continue;
        end;
        Lines[K].Pos := LineStart;
        {Search for e.nd of line}
        LineLen := 0;
        TabsWith := 0;
        LineSeparatorLen := 0;
        while (LineLen+TabsWith < MaxX) and (LineStart+LineLen < BufSize) {and (BufSize <> 0)}
        do
        begin
          CurChar := Buf^[LineStart+LineLen];
          NextChar := 0;
          if  (LineStart+LineLen+1 < BufSize) then
            NextChar := Buf^[LineStart+LineLen+1];
          if  (CurChar in [$0D, $0A]) then
          begin
            LineSeparatorLen := 1;
            if  (NextChar in [$0D, $0A]) and (CurChar <> NextChar) then
              LineSeparatorLen := 2;
            if WrappedLine and (LineLen = 0) then
            begin {ignore line separator exact after wrapped line}
              Inc(LineStart, LineSeparatorLen);
              WrappedLine := False;
              goto LineBegin;
            end;
            WrappedLine := False;
            Break;
          end;
          if CurChar = 9 then
            Inc(TabsWith, TabSize-1-((LineLen+TabsWith) mod TabSize));
          Inc(LineLen);
          WrappedLine := True;
        end;
        Lines[K].len := LineLen;

        {Decrease length of word-wrapped line}
        if  (Wrap = wmWords) and (LineLen+TabsWith >= MaxX) then
        begin
          while (LineLen > 1) and
                not (Char(CurChar) in BreakChars) and
                not (Char(NextChar) in BreakChars)
          do
          begin
            Dec(LineLen);
            NextChar := CurChar;
            CurChar := Buf^[LineStart+LineLen-1];
          end;
          if LineLen > 1 then
          begin
            Lines[K].len := LineLen;
            WrappedLine := True;
          end;
        end;

        Inc(LineStart, Lines[K].len+LineSeparatorLen);
      end; {-DataCompBoy-}
    end;
  end {case};
  end { TFileViewer.MakeLines };

procedure TFileViewer.SeekBof;
begin
  SearchX := 0;
  Seek(0);
  if ViewMode = vmAsm
  then
    TPoint_Assign(Cur, 10, 0)
  else
    TPoint_Assign(Cur, 0, 0);
  XDelta := 0;
  DrawView
end;

procedure MessFileNotOpen(const Path: String; RC: LongInt);
begin
  MessageBox(^C'Невозможно открыть файл'^M^C+Path+^M^C'(RC=%d)',
    @RC, mfError+mfOKButton);
end;

procedure MessFileNotRename(const s1, s2: String; ErrCode: LongInt);
begin
  MessageBox(^C'Невозможно переименовать файл'
    +^M^C'(RC=%d)'+^M^C+ s1
    +^M^C'на '+ s2,
    @ErrCode, mfError+mfOKButton)
end;

procedure MessFileNotRead(const Path: String; RC: LongInt);
  begin
    MessageBox(^C'Невозможно читать исходный файл'^M^C+Path+^M^C'(RC=%d)',
      @RC, mfError+mfOKButton);
  end;



{AK155}
{ Выдача сообщения, закрытие окна и возбуждение исключения }
function TFileViewer.BreakOnStreamReadError: Boolean;
  begin
    BreakOnStreamReadError := False;
    if Fl^.Status <> stOK then
    begin
      if Fl^.Status = stInitError then
        MessFileNotOpen(FileName, Fl^.ErrorInfo)
      else
        MessFileNotRead(FileName, Fl^.ErrorInfo);
      BreakOnStreamReadError := True;
      { на самом деле это собщение и RC никому не нужны, но это может
      пригодиться, если не все вызовы BreakOnStreamReadError обложены
      try - except и исключение окажется фатальным}

      { При QuickView просмотрщик вставлен не в самостоятельное окно,
а прямо в менеджер файлов, так что при QuickView закрывать владельца
не просто не нужно, а недопустимо }
      if  (Owner <> nil) and not QuickView then
        Owner^.Free;
      isValid := False;
    end;
  end { TFileViewer.BreakOnStreamReadError: };
{/AK155}

procedure TFileViewer.SeekEof;
var
  i, j: Integer;
  OldFileSize: LongInt;
  OldStart: LongInt;
  WC: LongInt;
  WL: Longint absolute WC;
  OldLen1: LongInt;
  Temp: LongInt;
label
  EndProc;
begin
  with Lines[Cur.Y] do
  begin
    if Pos < 0 then
      Exit;
    if Pos+len >= Fl^.StreamSize then
      Exit;
  end;
  if ViewMode = vmText then
  begin
    OldStart := FilePos+Lines[0].Pos;
    OldLen1 := Lines[0].len;
  end
  else
  begin
    OldStart := FilePos+Lines[Cur.Y].Pos;
    OldLen1 := HexPos;
  end;
  WC := FilePos+BufPos;
  i := WL mod 16;
  Owner^.Lock;
  {AK155}
  if TypeOf(Fl^) = TypeOf(THandleDOSStream) then
  begin
    with PHandleDosStream(Fl)^ do
    begin
      if  (Status <> stOK) then
        goto EndProc;

      OldFileSize := FileSize;
      { SysFileSeek(Handle, 0, 2, StreamSize);}
      FileSize := StreamSize;
      if FileSize < OldFileSize then
      begin { Файл сжался }
        if Position > FileSize then
          Position := StreamSize;
      end;
      { SysFileSeek(Handle, Position, 0, Temp);}
      Seek(Position);
    end;

    if  (OldFileSize < FileSize) and (BufSize < FileSize) then
    begin
      AdjustBuf;
      if Buf = nil then
        goto EndProc;
    end;
  end;

  Seek(FileSize-BufSize);
  if  (ViewMode = vmHex) or (ViewMode = vmDump) then
  begin
    BufPos := BufSize-Size.Y*HexPos;
    if BufPos < OldStart-FilePos then
      BufPos := i32(OldStart-FilePos);
    MakeLines;
  end
  else
  begin
    BufPos := BufSize;
    {AK155: Зачем качать на 3 строки туда-сюда, непонятно. Для глюков?
   CountUp(Size.Y+3);
   CountDown(3);}
    CountUp(Size.Y); {AK155}
    MakeLines;

    i := 0;
    while (i < MaxLines) and (FilePos+Lines[i].Pos < OldStart) do
      Inc(i);
    if i <> 0 then
    begin
      if FilePos+Lines[i].Pos > OldStart then
      begin
        Lines[0].Pos := i32(OldStart-FilePos);
        Lines[0].len := OldLen1;
        j := 1;
      end
      else
        j := 0;
      Move(Lines[i], Lines[j], SizeOf(Lines[0])*(MaxLines-i-j));
      Dec(MaxLines, i-j);
    end;
    BufPos := Lines[0].Pos;
  end;

  if  (ViewMode = vmHex) and (FileSize <> 0) then
  begin
    i := i32(FileSize-(FilePos+BufPos)-1);
    Cur.Y := i div HexPos;
    Cur.X := i mod HexPos*2;
  end;
  DrawView;

  EndProc:
  Owner^.UnLock;
end { TFileViewer.SeekEof };

procedure DelSpace(var s: String);
var
  a, b, j: Byte;
begin { DelSpace }
  if s = '' then
    Exit;
  b := 1;
  j := Length(s);
  s[0] := #0;
  for a := 1 to j do
    if not (s[a] in [' ', #9]) then
    begin
      s[b] := s[a];
      Inc(s[0]);
      Inc(b);
    end;
end { DelSpace };

function DelSpaces(s: String): String;
begin
  DelSpace(s);
  DelSpaces := s;
end;


procedure TFileViewer.HandleEvent(var Event: TEvent);
var
  P: TPoint;
  LR: Integer;
  I: Integer;
  LLR, LFR: LongInt;
  ALLR, ALFR: LongInt;
  F: File;
  Ch: Char;
  Lin: Byte;

procedure CE;
begin
  ClearEvent(Event)
end;

procedure CM_END;
var
  I, MaxW: Integer;
  w, l: Integer;
  TabSize: Integer;

begin
  if Buf = nil then
    Exit;
  TabSize := GetTabSize;
  MaxW := 0;
  CE;
  {$R-}
  for I := 0 to Size.Y-1 do
  begin
    w := 0;
    for l := Lines[I].Pos to Lines[I].Pos+Lines[I].len-1 do
    begin
      Inc(w);
      if Buf^[l] = 9 then
        Inc(w, TabSize-1-l mod TabSize);
    end;
    if MaxW < w then
      MaxW := w;
  end;
  {$R+}
  Dec(MaxW, Size.X);

  if MaxW < 0 then
    XDelta := 0
  else
    XDelta := MaxW;
  DrawView;
end { CM_END };

(*  procedure ContinueSearch(Reverse: Boolean);
    var
      I {, J, JJ}: Integer;
      Backward: Boolean;
      CaseSensitive: Boolean;
    begin
    if  (SearchString.What = '') then
      Exit;
    if SearchX < 0 then
      SearchX := 0;
    if  (SearchX < FilePos+Lines[0].Pos)
      { or
     (SearchX > FilePos + Lines[1].Pos+1)} {AK155}
      then
      SearchX := FilePos+BufPos;
    Backward := (SearchString.Dir = 1) xor Reverse;
    if SearchResultVisible and (Backward <> PrevSearchDir)
    then { смена направления поиска: надо пропустить
          текст, только что найденный в другом направлении }
      begin
      if Backward then
        SearchX := SearchX - length(SearchString.What)
      else
        SearchX := SearchX + length(SearchString.What);
      end;
    CaseSensitive := SearchString.Opts and 1 <> 0;
    SearchX := SearchFileStr(Fl,
        XCoder.XLatCP[Ord(CaseSensitive)],
        SearchString.What, SearchX,
        CaseSensitive,
        True,
        SearchString.Opts and 2 <> 0, Backward,
        SearchString.Opts and 4 <> 0,
        SearchString.Opts and 8 <> 0);
    if SearchX >= 0 then
      begin
      {if HexPos > 0 then JJ := (FilePos+BufPos) mod HexPos;}
      Seek(SearchX);
      CountUp(3);
      SearchActive := True;
      BufPos := Lines[0].Pos;
      MakeLines;
      DrawView;
      SearchActive := False;
      if not Backward then
        SearchX := SearchX + length(SearchString.What);
      PrevSearchDir := Backward;
      end
    else if SearchX <> -2 then
      MessageBox(GetString(dlDBViewSearchNot), nil,
         mfInformation+mfOKButton);
    end { ContinueSearch };

  procedure StartSearch;
    var
      D: PDialog;
      SR: TViewSearch;
      R: TRect;
      P: PView;
      PP: PInputline;
      I: Integer;

    begin
    if LowMemory then
      Exit;

    D := PDialog(LoadResource(dlgViewerFind));
    D^.SetData(SearchString);
    I := Desktop^.ExecView(D);
    D^.GetData(SR);
    Dispose(D, Done);
    if I = cmCancel then
      Exit;
    SearchString := SR;
    {AK155}
    SearchX := FilePos+Lines[0].Pos;
    if SR.Dir = 1 then
      begin {назад}
      I := Size.Y-1;
      while (I <> 0) and (Lines[I].Pos < 0) do
        Dec(I);
      SearchX := FilePos+Lines[I].Pos+Lines[I].len + 1;
      end;
    {/AK155}
    ContinueSearch(False);
    end { StartSearch };
*)

label 1, 2, DoSave, KBCheck, NotKb;

var
  ScrollerPos: LongInt;
  WC: LongInt;
  WL: Longint absolute WC;

begin { TFileViewer.HandleEvent }


  inherited HandleEvent(Event);
  case ViewMode of
    vmText,
    vmHex:
    begin
      HexPos := (Size.X-12) div 4;
      if HexPos <= 0 then
        HexPos := 1;
    end;
    vmDump:
    begin
      HexPos := ((Size.X-9) div 16)*16;
      if HexPos < 16 then
        HexPos := 16;
    end;
  end {case};
  if Loaded then
  begin
    Loaded := False;
    if SB <> nil then
    begin
      {        PViewScroll(SB)^.MaxV := FileSize;
        PViewScroll(SB)^.Value := FilePos+BufPos;}
    end;
    {      PViewScroll(SB)^.DrawView;}
  end;
  case Event.What of
    evBroadcast:
    case Event.Command of
      cmFindView:
      if  (PString(Event.InfoPtr)^ = FileName) or
          (PString(Event.InfoPtr)^ = VFileName)
      then
        if (Owner <> nil) and not QuickView then
        begin
          Owner^.Select;
          ClearEvent(Event);
        end;
      cmReleaseFile:
      begin
        if UpStrg(FileName) = UpStrg(PString(Event.InfoPtr)^) then
        begin
          ReadFile('', '', True);
          {if not QuickView then Message(Owner, evCommand, cmClose, nil);}
        end;
      end;
    end {case};
    evCommand:
    case Event.Command of
      cmGetName:
      if VFileName <> ''
      then
        PString(Event.InfoPtr)^:= 'Просмотp'+' - '+
        {$IFDEF RecodeWhenDraw}CharToOemStr {$ENDIF}(VFileName)
      else
        PString(Event.InfoPtr)^:= 'Просмотp';
      cmLoadViewFile:
      begin
        ChangeFile(Event.InfoPtr);
        CE;
      end;
      cmClose, cmQuit:;
      cmHexMode:
      begin
        case ViewMode of
          vmText:
          begin
            ViewMode := vmHex;
            HexEdit := True;
          end;
          vmHex:
          begin
            ViewMode := vmDump;
          end;
          {$IFDEF DisAsm}
          vmDump:
          if  ( (EditorDefaults.ViOpt and vbfDisAsm) <> 0) then
          begin
            ViewMode := vmAsm;
            HexEdit := True;
            MakeLines;
            Cur.X := 10;
          end {GRM!}
            else
            begin
              ViewMode := vmText;
              MakeLines
            end;
          {$ENDIF}
          else {case}
          begin
            ViewMode := vmText;
            HideCursor;
            MakeLines
          end;
        end {case};
        if ViewMode <> vmDump then
        begin
          HexPos := (Size.X-12) div 4;
          if HexPos <= 0 then
            HexPos := 1;
        end
        else
        begin
          HexPos := ((Size.X-9) div 16)*16;
          if HexPos < 16 then
            HexPos := 16;
          MakeLines
        end;
        DrawView;
        CE
      end;
      cmUnWrap:
      begin
        Inc(Wrap);
        if Wrap > wmWords then
          Wrap := wmNone;
        MakeLines;
        if Lines[Size.Y-1].Pos < 0 then
          SeekEof;
        DrawView;
        CE;
      end;
      cmScrollBarChanged:
      begin
        Desktop^.Lock;
        Seek(PComp(Event.InfoPtr)^);
        if  (ViewMode = vmText) and (Event.InfoLong <> 0) then
        begin
          { стать на начало строки, но так,
                 чтобы не сдвинуть вверх ползунок курсора }
          CountDown(1);
          {              ScrollerPos := PViewScroll(SB)^.GetPartCode;}
          CountUp(1);
          {              if ScrollerPos <> PViewScroll(SB)^.GetPartCode then
                CountDown(1);}
        end;
        if Lines[Size.Y-1].Pos < 0 then
          SeekEof
        else
          DrawView;
        Desktop^.UnLock;
      end;
    end {case};

    evKeyDown:
    case Event.KeyCode of
      kbCtrlHome:
      if ViewMode = vmHex then
      begin
        Cur.Y := 0;
        DrawView;
        CE;
      end
        else
          goto 1;
      kbCtrlEnd:
      if ViewMode = vmHex then
      begin
        Cur.Y := Size.Y-1;
        DrawView;
        CE;
      end
        else
          goto 2;
      kbESC {, kbEnter}:
      if not QuickView then
      begin
        CE;
        Message(Application, evCommand, cmClose, nil)
      end;
      kbCtrlLeft:
      if ViewMode = vmText then
      begin
        CE;
        if XDelta > 19 then
          Dec(XDelta, 20)
        else
          XDelta := 0;
        DrawView
      end
        else (*if ViewMode <> vmAsm then {GRM!}*)
        begin
          if BufPos > 0 then
            Dec(BufPos)
          else if FilePos > 100 then
          begin
            Owner^.Lock;
            Seek(FilePos-100);
            BufPos := 99;
            Owner^.UnLock;
          end;
          DrawView;
          CE
        end;

      kbCtrlRight:
      if ViewMode = vmText then
      begin
        CE;
        if XDelta < MaxWrapW*8-Size.X-19 then
          Inc(XDelta, 20);
        DrawView
      end
        else (*if ViewMode <> vmAsm then {GRM!}*)
        begin
          if BufPos < BufSize-1024 then
            Inc(BufPos)
          else
          begin
            Owner^.Lock;
            Seek(FilePos+BufPos+1);
            Owner^.UnLock;
          end;
          DrawView;
          CE
        end;
      kbTab:
      if ViewMode = vmHex then
      begin
        if HexEdit then
          Cur.X := Cur.X div 2
        else
          Cur.X := Cur.X*2;
        HexEdit := not HexEdit;
        DrawView;
        CE
      end;
      kbCtrlPgUp:
      begin
        1:
          CE;
        SeekBof;
      end;
      kbCtrlPgDn:
      begin
        2:
          Lines[Size.Y].Pos := 0; {piwamoto}
        SeekEof;
        SearchX := FileSize;
        CE
      end;
      kbHome:
      begin
        CE;
        if ViewMode = vmHex then
          Cur.X := 0
        else
          XDelta := 0;
        DrawView
      end;
      kbEnd:
      if ViewMode <> vmHex then
        CM_END
      else
      begin
        Cur.X := HexPos*(Byte(HexEdit)+1)-1;
        DrawView
      end;
      kbDown:
      case ViewMode of
        {GRM!}
        vmText, vmDump:
        begin
          CE;
          CountDown(1);
          DrawView;
        end;
        vmHex:
        begin
          Inc(Cur.Y);
          DrawView;
          CE;
        end;
        {$IFDEF DisAsm}
        vmAsm:
        if Cur.Y = Size.Y-1 then
        begin
          CountDown(1);
          DrawView;
          CE;
        end
          else if Lines[Cur.Y+1].Pos <> -1 then
          begin
            Inc(Cur.Y);
            Cur.X := 10;
            DrawView;
            CE;
          end;

        {$ENDIF}
      end {case}; {GRM!}
      kbPgDn:
      begin
        CE;
        CountDown(Size.Y-1);
        DrawView;
      end;
      kbSpace:
      if ViewMode in [vmText, vmDump]
      then
      begin
        CE;
        CountDown(Size.Y-1);
        DrawView;
      end
        else
          goto KBCheck;
      kbUp:
      case ViewMode of
        {GRM!}
        vmText,
        vmDump:
        begin
          CE;
          CountUp(1);
          DrawView;
        end;
        vmHex:
        begin
          Dec(Cur.Y);
          DrawView;
          CE;
        end;
        {$IFDEF DisAsm}
        vmAsm:
        if Cur.Y = 0 then
        begin
          CountUp(1);
          DrawView;
          CE;
        end
          else
          begin
            Cur.X := 10;
            Dec(Cur.Y);
            DrawView;
            CE;
          end;
        {$ENDIF}
      end {case}; {GRM!}
      kbPgUp:
      begin
        CE;
        CountUp(Size.Y-1);
        DrawView;
        if BufPos = 0 then
        begin
          {              PViewScroll(SB)^.Value := 0;}
          SB^.DrawView;
        end;
      end;
      kbLeft:
      if ViewMode = vmText then
      begin
        CE;
        if XDelta > 0 then
          Dec(XDelta);
        DrawView
      end
        else
          {$IFDEF DisAsm}
          {GRM!}
          if ViewMode = vmAsm then
          begin
            CE;
            if Cur.X > 10 then
              Dec(Cur.X)
            else
            begin
              Message(@Self, evKeyDown, kbUp, nil);
              if  (BufPos+FilePos <> 0) then
                Cur.X := Lines[Cur.Y].len*2+9;
            end;
            DrawView;
          end
          else
            {GRM!}
            {$ENDIF}
          begin
            if Cur.X > 0 then
              Dec(Cur.X)
            else
            begin
              Cur.X := HexPos*(Byte(HexEdit)+1)-1;
              Dec(Cur.Y)
            end;
            {     if ViewMode = vmHex then
                                 Message(Owner, evCommand, cmSetMargins, nil);}
            DrawView;
            CE
          end;
      kbRight:
      if ViewMode = vmText then
      begin
        CE;
        if XDelta < MaxWrapW*8-Size.X then
          Inc(XDelta);
        DrawView
      end
        else
          {$IFDEF DisAsm}
          {GRM!}
          if ViewMode = vmAsm then
          begin
            if Cur.X >= Lines[Cur.Y].len*2+9 then
              Message(@Self, evKeyDown, kbDown, nil)
            else
              Inc(Cur.X);
            DrawView;
            CE
          end
          else
            {GRM!}
            {$ENDIF}
          begin
            if Cur.X < HexPos*(Byte(HexEdit)+1)-1 then
              Inc(Cur.X)
            else
            begin
              Cur.X := 0;
              Inc(Cur.Y)
            end;
            {       if ViewMode = vmHex then SearchX := HexPos;}
            DrawView;
            CE
          end;
      {JO}kbEnter:
      case UseEnterInViewer of
        1:
        if not QuickView then
        begin
          CE;
          Message(Application, evCommand, cmClose, nil)
        end;
        2:
          Message(Owner, evCommand, cmHexMode, nil);
      end
        else {case}
          KBCheck:
          if Event.What <> evNothing then
          begin
            if  (Event.CharCode = #11) and not CtrlK then
            begin
              CtrlK := True;
              CE;
            end
            else if CtrlK then
            begin
              Ch := Event.CharCode;
              if  (Ch >= '1') and (Ch <= '9') then
              begin
                Event.What := evCommand;
                Event.Command := cmPlaceMarker1+Ord(Ch)-Ord('1');
                PutEvent(Event);
              end;
              CtrlK := False;
              CE;
            end
              else
              begin
                goto NotKb;
                Event.What := evCommand;
                PutEvent(Event);
                CE;
                Exit;
              end;
            NotKb:
            if  (Event.CharCode = #17) and not CtrlQ then
            begin
              CtrlQ := True;
              CE;
            end
              else if CtrlQ then

              else if (Event.CharCode >= #32) and not NoEdit then
              begin
                {GRM!}
                if  ( (ViewMode = vmHex) and (Buf <> nil) and
                      (Cur.X div (Byte(HexEdit)+1)+Cur.Y*HexPos+BufPos
                      < BufSize))
                    {$IFDEF DisAsm}
                    or (ViewMode = vmAsm)
                    {$ENDIF}
                then
                begin
                  {GRM!}
                  if Filtr then
                  begin
                    case MessageBox(^C'После модификации сохранение этого файла в его настоящее'^M+
                        ^C'местоположение и/или в настоящем формате будет невозможно.'^M+
                        ^C'Произвести модификацию (будет возможно "Сохранить как")?', nil,
                        mfConfirmation+mfYesButton+mfNoButton) of
                      cmYes:
                      begin
                        Filtr := False;
                        VFileName := '';
                        DisposeStr(PWindow(Owner)^.Title);
                        PWindow(Owner)^.Title := NewStr
                        (^C'После модификации сохранение этого файла в его настоящее'^M+
                          ^C'местоположение и/или в настоящем формате будет невозможно.'^M+
                          ^C'Произвести модификацию (будет возможно "Сохранить как")?');
                        PWindow(Owner)^.Redraw;
                      end;
                      else {case}
                      begin
                        CE;
                        Exit
                      end;
                    end {case};
                  end;
                  if HexEdit then
                  begin
                    Event.CharCode := UpCase(Event.CharCode);
                    if Event.CharCode in ['A'..'F', '0'..'9'] then
                    begin
                      BufModified := True;
                      I := PosChar(Event.CharCode, HexStr)-1;
                      {$IFDEF DisAsm}
                      if  (ViewMode <> vmAsm) then
                        {JO}
                        {$ENDIF}
                        P.X := Cur.X div 2+Cur.Y*HexPos+BufPos
                        {JO} {$IFDEF DisAsm}
                      else
                      begin
                        MakeLines;
                        P.X := 0;
                        for Lin := 0 to (Cur.Y-1) do
                          P.X := P.X+Lines[Lin].len;
                        P.X := P.X+((Cur.X-10) div 2)+BufPos;
                        if P.X < 0 then
                          P.X := 0;
                      end
                      {/JO} {$ENDIF}
                      ;
                      if odd(Cur.X) then
                        Buf^[P.X] := (Buf^[P.X] and $F0) or I
                      else
                        Buf^[P.X] := (Buf^[P.X] and $F) or (I shl 4);
                      if ViewMode = vmAsm then
                        MakeLines; {JO}
                      Message(@Self, evKeyDown, kbRight, nil);
                      CE
                    end;
                  end
                  else
                  begin
                    BufModified := True;
                    { Event.CharCode := XCoder.XLatCP[FromAscii][Event.CharCode]; } // TODO Исправить
                    Char(Buf^[Cur.X+Cur.Y*HexPos+BufPos])
                    := Event.CharCode;
                    Message(@Self, evKeyDown, kbRight, nil);
                    CE
                  end;
                end;
              end;
          end;
    end {case};
    evMouseDown:
    begin
      LR := RepeatDelay;
      LLR := AutoRepeat;
      repeat
        MakeLocal(Event.Where, P);
        I := Abs((Size.Y shr 1)-P.Y);
        if I = 0 then
          RepeatDelay := 0
        else if MouseInView(Event.Where) then
        begin
          RepeatDelay := 6-Round((I/(Size.Y shr 1))*6);
          AutoRepeat := RepeatDelay;
          if P.X < Size.X div 4 then
            Message(@Self, evKeyDown, kbLeft, nil)
          else if P.X >= (Size.X*3) div 4 then
            Message(@Self, evKeyDown, kbRight, nil)
          else if P.Y < Size.Y div 2 then
            Message(@Self, evKeyDown, kbUp, nil)
          else
            Message(@Self, evKeyDown, kbDown, nil)
        end
          else
            RepeatDelay := 0;
      until not MouseEvent(Event, evMouseMove+evMouseAuto);
      RepeatDelay := LR;
      AutoRepeat := LLR;
      CE
    end;
  end {case};
end { TFileViewer.HandleEvent };

procedure TFileViewer.DoHighlite(var B; const S: String; const Attr: String);
var
  i: Integer;
  j: Integer;
  k: Integer;
  l: Integer;
  c: Char;
begin
  i := 1;
  j := 0;
  l := Length(S);
  while (i <= l) do
  begin
    c := S[i];
    k := i+1;
    while (k <= l) and (S[k] = c) do
      Inc(k);
    if  (c <> #0) and (Ord(c) <= Length(Attr)) then
      // MoveColor(TAWordArray(B)[j], k-i, Ord(Attr[Ord(c)]));
    Inc(j, k-i);
    i := k;
  end;
end { TFileViewer.DoHighlite };

{AK155 05.2001 Процедура CountDown почти полностью переписана;
части, соотвествующие vmAsm, собраны до кучи, но не проверялись}

procedure TFileViewer.CountDown(ANumber: Integer);
  {$IFDEF DisAsm}
var
  D: XCHGData; {GRM!}
  {$ENDIF}
var
  NewPos: LongInt;
begin
  if Buf = nil then
    Exit;
  case ViewMode of

    vmHex, vmDump:
    begin
      if not ScrollEOF and
         (FilePos+BufPos+HexPos*(Size.Y) >= FileSize)
      then
        Exit;
      if FilePos+BufPos+HexPos*ANumber >= FileSize then
        Exit;
      while (BufPos+HexPos < BufSize) and (ANumber > 0) do
      begin
        Inc(BufPos, HexPos);
        Dec(ANumber)
      end;
      if BufPos+HexPos*Size.Y > BufSize then
        Seek(FilePos+LongInt(BufPos));
      Inc(BufPos, ANumber*HexPos);
    end {vmHex, vmDump};

    {$IFDEF DisAsm} {GRM!}

    vmAsm:
    begin
      if  (Lines[ANumber].Pos < 0) or (Lines[Size.Y].Pos < 0) then
        Exit;
      D.MemBuff := Buf;
      while (ANumber > 0) do
      begin
        D.InstrMaxLen := MinBufSize(FileSize-FilePos-BufPos-1, 15);
        D.Offset := BufPos;
        ScanCode(D);
        if BufPos+D.InstrLen+15*Size.Y > BufSize then
          Seek(FilePos+LongInt(BufPos));
        if FilePos+BufPos+D.InstrLen >= FileSize then
          Break;
        Inc(BufPos, D.InstrLen);
        Dec(ANumber);
      end;
      MakeLines;
      while (Cur.Y <> 0) and (Lines[Cur.Y].Pos < 0) do
        Dec(Cur.Y);
      Cur.X := 10;
    end {vmAsm};
    {$ENDIF} {GRM!}

    else {vmText}
    begin
      if not ScrollEOF and (ExposedPos+FilePos = FileSize) then
        Exit;
      if  ( (MaxLines < Size.Y+ANumber-1) or (Lines[Size.Y+ANumber-1].Pos
            = -1))
          and (FilePos+BufSize < FileSize)
      then
        Seek(FilePos+Lines[0].Pos);
      if Lines[ANumber].Pos < 0 then
        Exit;
      BufPos := Lines[ANumber].Pos;
      if ANumber <> 0 then
      begin
        if  (ANumber+Size.Y < MaxLines) then
        begin
          Move(Lines[ANumber], Lines[0],
            SizeOf(Lines[0])*(MaxLines-ANumber));
          Dec(MaxLines, ANumber);
        end
        else
          MakeLines;
      end;
    end {vmText};
  end {case};

  DrawView;
  NewPos := FilePos+BufPos;
  Message(SB, evCommand, cmChangeValue, @NewPos);
end { TFileViewer.CountDown };

procedure TFileViewer.CountUp(ANumber: Integer);
var
  I, LineStart, LineEnd: LongInt;
  NextLineStart: LongInt;
  NewFilePos: LongInt;
  ReadLen: LongInt;
  {$IFDEF DisAsm}
  D: XCHGData; {GRM!}
  {$ENDIF}
  N: LongInt;
  MaxX: LongInt;

label 1;

  {AK155}
procedure ScrollUp;
    { Поиск в буфере начала предыдущей строчки для показа
  (режим TextView, с учетом Wrap и Size.X).
 Вход: NextLineStart - текущее начало строки в буфере
   (_после_ маркера типа CR LF, если он есть);
 Выход: LineStart - начало предыдущей строки;
        LineEnd - ее конец (на маркере, если он есть;
                  обычно LineEnd=NextLineStart-1).
 Если при поиске начала упираемся в начало буфера, то читать предыдущий
 файл не пытаемся, а просто возвращаем LineStart=0. }

var
  I, M, W: LongInt;
  TS: Integer;
  c1, c2: Byte;
begin
  TS := GetTabSize;
  LineEnd := NextLineStart;
  LineStart := LineEnd;
  if LineEnd <= 0 then
    Exit;
  { Пропуск маркера конца }
  if  (LineEnd > 0) then
  begin
    c1 := Buf^[LineEnd-1];
    if c1 in [$0D, $0A] then
    begin
      Dec(LineEnd);
      if LineEnd > 0 then
      begin
        c2 := Buf^[LineEnd-1];
        if  (c2 in [$0D, $0A]) and (c1 <> c2) then
          Dec(LineEnd);
      end;
    end;
  end;

  { Поиска начала строки в буфере. Ограничиться шириной экрана
  прямо сейчас нельзя, так как правильный учет табуляций возможен
  только при просмотре от самого начала строки.}
  LineStart := LineEnd;
  while (LineStart > 0) and not (Buf^[LineStart-1] in [$0D, $0A]) do
  begin
    if  (LineEnd-LineStart >= MaxWrapW) then
    begin
      if Wrap = wmNone then
        Exit;
      { Так бывает при просмотре файла без CR и LF. В этом
         случае границы строк чисто условные, так что нет никакого
         смысла сканировать на неизвестную глубину назад, а потом
         снова сканировать вперед, нарезая на куски максимальной
         длины. Так что теперь просто ищем от текущей точки назад
         начало экранной строки.}
      LineStart := LineEnd;
      W := MaxX;
      while W > 0 do
      begin
        Dec(LineStart);
        Dec(W);
        if Buf^[LineStart-1] = 9 then
          Dec(W, W mod TS);
      end;
      if Wrap = wmWords then
      begin
        if  (Char(Buf^[LineStart])) in BreakChars then
          Exit;
        if  (Char(Buf^[LineStart-1])) in BreakChars then
          Exit;
        { граница экранной строки лежит внутри слова }
        I := LineStart;
        Inc(LineStart, 2);
        while LineStart < LineEnd do
        begin
          if  (Char(Buf^[LineStart])) in BreakChars then
            Exit;
          Inc(LineStart);
        end;
        LineStart := I; { ну очень длинное слово }
      end;
      Exit;
    end;
    Dec(LineStart);
  end;

  { Сейчас LineStart - настоящее начало строчки в буфере. Но с учетом wrap
   она может разделиться на несколько строчек экрана. Ниже это проверяется
   и в качестве LineStart возвращается начало последней из них. }

  M := LineStart; { M - кандидат на конец строки }
  W := 0;
  while M < LineEnd-1 do
  begin
    repeat
      Inc(W)
    until (Buf^[M] <> 9) or (W mod TS = 0);
    if W <= MaxX then
      Inc(M)
    else
    begin { нужен разрез строки }
      if Wrap = wmWords then
      begin { вернуться до границы слова }
        I := M;
        while I > LineStart do
        begin
          if Char(Buf^[I-1]) in BreakChars then
          begin { граница слова найдена }
            M := I;
            Break;
          end;
          Dec(I);
        end;
      end;
      LineStart := M;
      W := 0; { выполнили разрез }
    end;
  end;
end { ScrollUp };
  {/AK155}

  begin { TFileViewer.CountUp }
    if Buf = nil then
      Exit;
    (* {AK155 11-01-2003 эти бредовые проверки, вероятно, когда-то
        служили для компенсации  последствий каких-то багов.
        Но после того, как BufSize стал не $8000, а поболее, они
        стали в прежнем виде вредны, а обновлять их не хочется,
        так как самих багов, наверно, уже давно нет}
  if BufPos > 65000 then
    begin BufPos := 0; MakeLines; end; {AK155: IMHO так не бывает}
*)
    NextLineStart := BufPos;
    {$IFDEF DisAsm}
    D.MemBuff := Buf; {GRM!}
    D.Offset := BufPos; {GRM!}
    {$ENDIF}
    if Wrap > wmNone then
      MaxX := Size.X
    else
      MaxX := MaxWrapW;
    for N := 1 to ANumber do
    begin
      if  (NextLineStart <= 0) and (FilePos <= 0) then
        Break; { уже стоим в начале, двигаться некуда }
      1:
      {GRM!}
      case ViewMode of
        vmText:
          ScrollUp;
        vmHex, vmDump:
        begin
          LineStart := Max(0, NextLineStart-HexPos);
          LineEnd := NextLineStart;
        end;
        {$IFDEF DisAsm}
        vmAsm:
        begin
          ScanUp(D);
          LineStart := BufPos-D.InstrLen;
        end;
        {$ENDIF}
      end {case};
      {GRM!}
      if  (ViewMode = vmText) and (LineEnd = Lines[0].Pos) and
          (LineEnd <> 0) {AK155 такое бывает в самом начале буфера}
          and (Lines[0].len+Lines[0].Pos-LineStart <= MaxX)
          {AK155 > MaxWrapW бывает при просмотре файла без CR и LF }
      then
      begin
        {AK155 При переходе от Hex/Dump к Text начало первой строчки
  экрана могло оказаться не началом строки в буфере. В момент смены
  режима на настоящее начало строки скакать было нехорошо,
  чтобы переключение режима не сбивало позицию, а сейчас надо
  таки перейти к настоящему началу строки. Реально такое
  может быть только при I=1 }
        Inc(Lines[0].len, Lines[0].Pos-LineStart);
        Lines[0].Pos := LineStart;
        BufPos := LineStart;
      end
      else {if ViewMode = vmText then }
        {/AK155}
      begin
        if (LineStart > 0) and (LineStart < BufSize) then
          BufPos := LineStart { нормальное начало строки }
        else if FilePos = 0 then
        begin { начало файла }
          if BufPos = 0 then
            Exit; { и так уже были в начале }
          BufPos := 0; { нормальное начало строки }
        end
          else
          begin
            { начало буфера не в начале файла: сдвинуться по файлу
              на полбуфера и повторить поиск начала строки }
            NewFilePos := FilePos-(BufSize div 2);
            if NewFilePos < 0 then
              NewFilePos := 0;
            ReadLen := i32(FilePos-NewFilePos);
            Move(Buf^[0], Buf^[ReadLen], BufSize-ReadLen);
            Fl^.Seek(NewFilePos);
            Fl^.Read(Buf^, ReadLen);
            BreakOnStreamReadError;
            FilePos := NewFilePos;
            BufPos := ReadLen;
            for I := 0 to MaxLines do
            begin
              if Lines[I].Pos < 0 then
                Break;
              Inc(Lines[I].Pos, ReadLen);
              if Lines[I].Pos+Lines[I].len > BufSize then
              begin
                MaxLines := I-1;
                if I = 0 then
                  Break;
                Break;
              end;
            end;
            Inc(NextLineStart, ReadLen);
            goto 1;
          end;

        System.Move(Lines[0], Lines[1], (MaxLines-1)*SizeOf(Lines[0]));
        if MaxLines < MaxILines then
          Inc(MaxLines);
        Lines[0].Pos := LineStart;
        Lines[0].len := LineEnd-LineStart;
      end;

      NextLineStart := LineStart;
    end;
    {$IFDEF DisAsm}
    if ViewMode = vmAsm then
      Cur.X := 10; {GRM!}
    {$ENDIF}
    DrawView;
    NewFilePos := FilePos+BufPos;
    Message(SB, evCommand, cmChangeValue, @NewFilePos);
  end { TFileViewer.CountUp };

function TFileViewer.Valid(Command: Word): Boolean;
  begin
    Valid := isValid or QuickView;
    if  (Command = cmClose) or (Command = cmQuit) then
      if  (Owner <> nil) and (not QuickView) then
        {StoreViewInfo(Owner)};
  end;

procedure AdjustToDesktopSize(var R: TRect; OldDeskSize: TPoint);
var
  KX, KY: Real;
begin
  if OldDeskSize.X = 0 then
    OldDeskSize.X := Desktop^.Size.X;
  if OldDeskSize.Y = 0 then
    OldDeskSize.Y := Desktop^.Size.Y;
  {  if Desktop^.Size.Equals(OldDeskSize) then
    Exit; }
  KX := Desktop^.Size.X/OldDeskSize.X;
  R.A.X := Trunc(R.A.X*KX);
  R.B.X := Trunc(R.B.X*KX);
  KY := Desktop^.Size.Y/OldDeskSize.Y;
  R.A.Y := Trunc(R.A.Y*KY);
  R.B.Y := Trunc(R.B.Y*KY);
  if R.Empty or (R.A.X >= Desktop^.Size.X) or (R.B.X < 0)
     or (R.A.Y >= Desktop^.Size.Y) or (R.B.Y < 0)
     or (R.B.X-R.A.X < MinWinSize.X)
     or (R.B.Y-R.A.Y < MinWinSize.Y)
  then
    Desktop^.GetExtent(R);
end { AdjustToDesktopSize };

{ TFileWindow }
constructor TFileWindow.Init(const FileName, VFileName: String; Hex: Boolean);
var
  R: TRect;
  P: PView;
  PV: PFileViewer;
begin
  if LastViewerBounds.Empty or ({InterfaceData.Options and}
       {ouiStoreViewerPosition = 0} true )
  then
  begin
    Desktop^.GetExtent(LastViewerBounds);
    LastViewerDeskSize := Desktop^.Size;
  end;
  R := LastViewerBounds;
  AdjustToDesktopSize(R, LastViewerDeskSize);
  TWindow.Init(R, {$IFDEF RecodeWhenDraw}CharToOemStr {$ENDIF}(VFileName),
    0);
  Flags := Flags or wfMaxi;
  Options := Options or ofTileable;
  GetExtent(R);
  R.Grow(-1, -1);
  R.A.X := R.B.X;
  // Inc(R.B.X);
  {P := New(PViewScroll, Init(R));}
  P := New(PView, Init(R));
  P^.GrowMode := gfGrowHiX+gfGrowLoX+gfGrowHiY;
  Insert(P);
  GetExtent(R);
  R.Grow(-1, -1);
  PV := New(PFileViewer, Init(R, nil, FileName, VFileName, P, False, Hex, 0));
  Insert(PV); {Вставить надо даже при ошибке для последующего контроля }
  if not PV^.isValid then
    {AK155}
    Exit;
  GetExtent(R);
  Inc(R.A.X);
  R.A.Y := R.B.Y-1;
  Dec(R.B.X, 2);
end { TFileWindow.Init };

procedure TFileWindow.ChangeBounds(var Bounds: TRect);
  begin
    inherited ChangeBounds(Bounds);
    if not GetState(sfModal) then
    begin
      GetBounds(LastViewerBounds);
      LastViewerDeskSize := Desktop^.Size;
    end;
  end;

function TFileWindow.ReactOnCmd: Boolean;
  begin
    ReactOnCmd := True
  end;

Constructor THandleDosStream.Init(_FileName: FNameStr; Mode: Word; ExtMode: Word);
Var
  DosStreamError : LongWord;
Begin
  TStream.Init;                                      { Call ancestor }
  FileName :=_FileName;
  FileName := FileName+#0;                           { Make asciiz }
  Move(FileName[1], FName, Length(FileName));        { Create asciiz name }
  Handle := InvalidHandle;
  DosStreamError := 0;
  SetLastOSError(0);
  if Mode = stCreate then
  Begin
    Handle := FileCreate(FileName, ExtMode);
  End
  Else
  Begin
    Handle := FileOpen(FileName, ExtMode);
  End;
  If Handle <> -1 Then
  Begin
    SetLastOSError(0);
    StreamSize := FileSeek(Handle, 0, fsFromEnd);
    If StreamSize = -1 Then
    {$ifdef win32}
      DosStreamError := GetLastOSError
    {$else}
      DosStreamError := $FF
    {$endif}
    Else
      FileSeek(Handle, 0, fsFromBeginning);
  End
  Else
    {$ifdef win32}
      DosStreamError := GetLastOSError;
    {$else}

    {$endif}
  If (DosStreamError <> 0) Then
    Error(stInitError, DosStreamError)               { Call stream error }
  else
    Status := StOK;
End;

Destructor THandleDosStream.Done;
var
  DosStreamError : LongWord;
Begin
  DosStreamError := $00;
  if Handle <> InvalidHandle then
  Begin
    SetLastOSError(0);
    FileClose(Handle);
    {$ifdef win32}
      DosStreamError := GetLastOSError;
    {$else}

    {$endif}
    If DosStreamError = 0 then
      Status := stOk
    else
      Error(stError, DosStreamError);
  End;
  Position := 0;                                     { Zero the position }
  Handle := InvalidHandle;
  TStream.Done;
End;

Procedure THandleDosStream.Close;
var
  DosStreamError : LongWord;
Begin
  DosStreamError := $00;
  if Handle <> InvalidHandle then
  Begin
    SetLastOSError(0);
    FileClose(Handle);
    {$ifdef win32}
    DosStreamError := GetLastOSError;
    {$else}

    {$endif}
    If DosStreamError = 0 then
      Status := stOk
    else
      Error(stError, DosStreamError);
  End;
  Position := 0;                                     { Zero the position }
  Handle := InvalidHandle;
End;

Procedure THandleDosStream.Truncate;
var
  DosStreamError : LongWord;
Begin
  DosStreamError := $00;
  If Status = stOk then
  Begin
    SetLastOSError(0);
    If Not FileTruncate(Handle, FileSeek(Handle, 0, fsFromCurrent)) Then
      {$ifdef win32}
      DosStreamError := GetLastOSError;
      {$else}
      DosStreamError := $FF;
      {$endif}
    If DosStreamError = 0 then
      StreamSize := Position
    else
      Error(stError, DosStreamError);
  End;
End;

Procedure THandleDosStream.Seek(Pos: LongInt);
var
  DosStreamError : Word;
Begin
  DosStreamError := $00;
  If (Status=stOk) Then
  Begin
    If (Pos < 0) Then
      Pos := 0;                                      { Negatives removed }
    SetLastOSError(0);
    If FileSeek(Handle, Pos, fsFromBeginning) = -1 Then
      {$ifdef win32}
      DosStreamError := GetLastOSError;
      {$else}
      DosStreamError := $FF;
      {$endif}
    If DosStreamError = 0 then
      Position := Pos
    else
      Error(stSeekError, DosStreamError)             { Specific seek error }
  End;
End;

Procedure THandleDosStream.OpenEx(OpenMode: Word; ExtOpenMode: Word);
var
  DosStreamError : Word;
Begin
  DosStreamError := $00;
  If (Status=stOk) Then
  Begin
    If (Handle = InvalidHandle) Then
    Begin
      SetLastOSError(0);
      if OpenMode = stCreate then
      Begin
        Handle := FileCreate(FileName, ExtOpenMode);
      End
      Else
      Begin
        Handle := FileOpen(FileName, ExtOpenMode);
      End;
      If Handle <> -1 Then
      Begin
        SetLastOSError(0);
        StreamSize := FileSeek(Handle, 0, fsFromEnd);
        If StreamSize = -1 Then
        {$ifdef win32}
          DosStreamError := GetLastOSError
        {$else}
          DosStreamError := $FF
        {$endif}
        Else
          FileSeek(Handle, 0, fsFromBeginning);
      End
      Else
        {$ifdef win32}
        DosStreamError := GetLastOSError;
        {$else}

        {$endif}
      If (DosStreamError <> 0) Then
        Error(stInitError, DosStreamError)               { Call stream error }
      else
        Status := StOK;
      Position := 0;
    End
    Else
      Error(stOpenError, 104);                { File already open }
  End;
End;

Procedure THandleDosStream.Read(Var Buf; Count: Longint);
Var
  BytesMoved: Longint;
  DosStreamError : Word;
Begin
   DosStreamError := $00;
   If Status = StOK then
     Begin
        If (Position + Count > StreamSize) Then            { Insufficient data }
          Error(stReadError, 0);                           { Read beyond end!!! }
        If (Handle = InvalidHandle) Then
          Error(stReadError, 103);                         { File not open }
        SetLastOSError(0);
        BytesMoved:= FileRead(Handle, Buf, Count );        { Read from file }
        {$ifdef win32}
        DosStreamError := GetLastOSError;
        {$else}

        {$endif}
        If ((DosStreamError<>0) OR (BytesMoved<>Count)) Then
           Begin  { Error was detected }
             BytesMoved := 0;                              { Clear bytes moved }
             If (DosStreamError <> 0) Then
                Error(stReadError, DosStreamError)         { Specific read error }
             Else
                Error(stReadError, 0);                     { Non specific error }
           End;
        Inc(Position, BytesMoved);                         { Adjust position }
     End;
   { If there was already an error, or an error was just
     generated, fill the vuffer with NULL
   }
   If Status <> StOK then
     FillChar(Buf, Count, #0);                        { Error clear buffer }
End;

Procedure THandleDosStream.Write(Var Buf; Count: Longint);
Var
  BytesMoved: Longint;
  DosStreamError : Word;
Begin
   DosStreamError := $00;
   { If status is not OK, simply exit }
   if Status <> StOK then
     exit;
   If (Handle = InvalidHandle) Then
    Error(stWriteError, 103);                    { File not open }
   SetLastOSError(0);
   BytesMoved:=FileWrite(Handle, Buf, Count );   { Write to file }
   {$ifdef win32}
   DosStreamError := GetLastOSError;
   {$else}

   {$endif}
   If ((DosStreamError<>0) OR (BytesMoved<>Count)) Then
      Begin  { Error was detected }
          BytesMoved := 0;                          { Clear bytes moved }
          If (DosStreamError<>0) Then
             Error(stWriteError, DOSStreamError)    { Specific write error }
          Else
             Error(stWriteError, 0);                { Non specific error }
      End;
   Inc(Position, BytesMoved);                       { Adjust position }
   If (Position > StreamSize) Then                  { File expanded }
     StreamSize := Position;                        { Adjust stream size }
End;


end.

