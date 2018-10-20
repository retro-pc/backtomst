{************************************************}
{                                                }
{  Copyright (C) MarinovSoft 2013-2014           }
{                                                }
{  http://marinovsoft.narod.ru                   }
{  mailto:super386@rambler.ru                    }
{                                                }
{************************************************}

Unit DosDlg;
Interface
Uses {$Ifdef fpc} SysUtils, {$Endif} Stddlg, Objects, Views, Drivers, Dialogs, Dos;
{---------------------------------------------------------}

{$Ifndef fpc}
Type
  ShortString = String;
  Sw_Integer  = Integer;
{$Endif}

Type
  TFileNames = Array[0..1] Of ShortString;

Type
  PDOSFileList = ^TDOSFileList;
  TDOSFileList = Object(TFileList)
    Procedure Draw; Virtual;
    Function GetPalette: PPalette; virtual;
    Procedure HandleEvent(Var Event: TEvent); Virtual;
    procedure GetData(var Rec); virtual;
    constructor Init(var Bounds: TRect; AScrollBar: PScrollBar);
    procedure ReadDirectory(AWildCard: PathStr);virtual;
    Function GetText(Item, MaxLen: Sw_Integer): String;virtual;
    function IsSelected(Item: Sw_Integer):Boolean;virtual;
  end;

Type
  PDOSLongFileList = ^TDOSLongFileList;
  TDOSLongFileList = Object(TDOSFileList)
    Procedure Draw; Virtual;
  End;

Type
  PDOSShortWindow = ^TDOSShortWindow;
  TDOSShortWindow = Object(TDialog)
    Public
    CurDir : PathStr;
    CurMask: NameStr;
    mFileList:PDOSFileList;
    Constructor Init(Dir, Mask: ShortString);
    Destructor Done; Virtual;
    Procedure HandleEvent(Var Event:TEvent); Virtual;
    Procedure ChangeDir; virtual;
    Procedure ViewFile; virtual;
    Procedure ViewFileEx; virtual;
    Procedure CopyFile; virtual;
    Procedure AddFile(FileNames:TFileNames); virtual;
    Function GetPalette: PPalette; virtual;
  End;
  {---------------------------------------------------------}
Type
  PDOSLongWindow = ^TDOSLongWindow;
  TDOSLongWindow = Object(TDOSShortWindow)
    Constructor Init(Dir, Mask: ShortString);
  End;
  {---------------------------------------------------------}
Type
  PDOSFileCollection = ^TDOSFileCollection;
  TDOSFileCollection = object(TFileCollection)
    {$ifdef fpc}
    function Compare(Key1, Key2: Pointer): LongInt; virtual;
    {$else}
    function Compare(Key1, Key2: Pointer): Integer; virtual;
    {$endif}
  end;
  {---------------------------------------------------------}
Implementation

Uses App, MsgBox, {$Ifdef fpc} FVConsts, FViewer, {$else} Service, {$Endif} MSTConst, part3msx;

{$Ifndef fpc}
Const
  MaxFName = 255;
{$Endif}

Type
  TDOSSearchRec = packed record
    Attr: Longint;
    Time: Longint;
    Size: Longint;
    Selected:Boolean;
    Name: string[MaxFName];
  end;
  PDOSSearchRec = ^TDOSSearchRec;


Function TruncPathStr(Str: String; MaxLength: Integer):String;
Var
  nLength:Integer;
Begin
  nLength:=Length(Str);
  If nLength > MaxLength Then
  Begin
    If (Str[2] = ':') And (Str[3] = '\') Then
    Begin
      {$ifdef fpc}
      TruncPathStr:=Copy(Str, 1, 3) + '...' + RightStr(Str, MaxLength - 6);
      {$else}
      TruncPathStr:=Copy(Str, 1, 3) + '...' + Copy(Str, 6, MaxLength - 6);
      {$Endif}
    End
    Else
    Begin
      If (Str[1] = '\') And (Str[2] = '\') Then
        {$ifdef fpc}
        TruncPathStr:=Copy(Str, 1, 2) + '...' + RightStr(Str, MaxLength - 5)
        {$else}
        TruncPathStr:=Copy(Str, 1, 2) + '...' + Copy(Str, 5, MaxLength - 5) { TODO BP }
        {$Endif}
      Else
        {$ifdef fpc}
        TruncPathStr:=RightStr(Str, MaxLength);
        {$else}
        TruncPathStr:=Copy(Str, 1, MaxLength); { TODO BP }
        {$Endif}
    End
  End
  Else
    TruncPathStr:=Str;
End;

function TDOSFileList.GetText(Item,MaxLen: Sw_Integer): String;
var
  S: String;
  SR: PDOSSearchRec;
begin
  SR := PDOSSearchRec(List^.At(Item));
  S := SR^.Name;
{  if SR^.Attr and Directory <> 0 then
  begin
    S[Length(S)+1] := DirSeparator;
    Inc(S[0]);
  end;}
  GetText := S;
end;

const
  ListSeparator=';';
{$ifndef fpc}
  DirSeparator = '\';
{$endif}
  function uppername(const s : string) : string;
  var
    i  : Sw_integer;
    in_name : boolean;
  begin
     in_name:=true;
     for i:=length(s) downto 1 do
      if in_name and (s[i] in ['a'..'z']) then
        uppername[i]:=char(byte(s[i])-32)
      else
       begin
          uppername[i]:=s[i];
          if s[i] = DirSeparator then
            in_name:=false;
       end;
     uppername[0]:=s[0];
  end;

{---------------------------------------------------------}
{$Ifdef fpc}
function TDOSFileCollection.Compare(Key1, Key2: Pointer): LongInt;
{$else}
function TDOSFileCollection.Compare(Key1, Key2: Pointer): Integer;
{$Endif}
Var
  Dir2,Dir1   : DirStr;
  Name2,Name1 : NameStr;
  Ext2,Ext1   : ExtStr;
begin
  If PDOSSearchRec(Key1)^.Name = PDOSSearchRec(Key2)^.Name Then Compare := 0
  Else If PDOSSearchRec(Key1)^.Name = '..' Then Compare := -1
  Else If PDOSSearchRec(Key2)^.Name = '..' Then Compare := 1
  Else If (PDOSSearchRec(Key1)^.Attr And Directory <> 0) And
          (PDOSSearchRec(Key2)^.Attr And Directory = 0) Then Compare := -1
  Else If (PDOSSearchRec(Key2)^.Attr And Directory <> 0) And
          (PDOSSearchRec(Key1)^.Attr And Directory = 0) Then Compare := 1
    {  else if PDOSSearchRec(Key1)^.Name > PDOSSearchRec(Key2)^.Name then
    Compare := 1
  else Compare := -1;}
  Else
  Begin
    {$Ifdef fpc}
    FSplit(UpperCase(PDOSSearchRec(Key1)^.Name),Dir1,Name1,Ext1);
    FSplit(UpperCase(PDOSSearchRec(Key2)^.Name),Dir2,Name2,Ext2);
    {$Else}
    FSplit(strupr(PDOSSearchRec(Key1)^.Name),Dir1,Name1,Ext1);
    FSplit(strupr(PDOSSearchRec(Key2)^.Name),Dir2,Name2,Ext2);
    {$Endif}
    If (PDOSSearchRec(Key2)^.Attr And Directory <> 0) And
       (PDOSSearchRec(Key1)^.Attr And Directory <> 0) Then
      If Name1>Name2 Then Compare:=1 Else Compare:=-1
    Else
    Begin
      If Ext1>Ext2 Then Compare:=1;
      If Ext2>Ext1 Then Compare:=-1;
      If Ext2=Ext1 Then
        If Name1>Name2 Then Compare:=1 Else Compare:=-1
    End;
  End
end;
{---------------------------------------------------------}
constructor TDOSFileList.Init(var Bounds: TRect; AScrollBar: PScrollBar);
begin
  TSortedListBox.Init(Bounds, 2, AScrollBar);
end;
{---------------------------------------------------------}
procedure TDOSFileList.Draw;
begin
  TFileList.Draw;
end;
{---------------------------------------------------------}
Procedure TDOSFileList.GetData(var Rec);
begin
   PDOSSearchRec(Rec):=PDOSSearchRec(List^.At(Focused));
end;
{---------------------------------------------------------}
Function TDOSFileList.GetPalette: PPalette;
(*
                   1    2    3    4    5
                ÉÍÍÍÍÑÍÍÍÍÑÍÍÍÍÑÍÍÍÍÑÍÍÍÍ»
  CListViewer   º 26 ³ 26 ³ 27 ³ 28 ³ 29 º
                ÈÍÍÑÍÏÍÍÑÍÏÍÍÑÍÏÍÍÑÍÏÍÍÑÍ¼
  ActiveÄÄÄÄÄÄÄÄÄÄÄÙ    ³    ³    ³    ÀÄÄÄDivider
  InactiveÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ    ³    ÀÄÄÄÄÄÄÄÄSelected
  FocusedÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

                  1    2    3    4    5    6    7    8
               ÉÍÍÍÍÑÍÍÍÍÑÍÍÍÍÑÍÍÍÍÑÍÍÍÍÑÍÍÍÍÑÍÍÍÍÑÍÍÍÍ»
  CGrayWindow  º 24 ³ 25 ³ 26 ³ 27 ³ 28 ³ 29 ³ 30 ³ 31 º
               ÌÍÍÍÍÏÍÍÍÍÏÍÍÍÍÏÍÍÍÍÏÍÍÍÍÏÍÍÍÍÏÍÍÍÍÏÍÍÍÍ¹
               ÌÍÍÍÍÑÍÍÍÍÑÍÍÍÍÑÍÍÍÍÑÍÍÍÍÑÍÍÍÍÑÍÍÍÍÑÍÍÍÍ¹
  CCyanWindow  º 16 ³ 17 ³ 18 ³ 19 ³ 20 ³ 21 ³ 22 ³ 23 º
               ÌÍÍÍÍÏÍÍÍÍÏÍÍÍÍÏÍÍÍÍÏÍÍÍÍÏÍÍÍÍÏÍÍÍÍÏÍÍÍÍ¹
               ÌÍÍÍÍÑÍÍÍÍÑÍÍÍÍÑÍÍÍÍÑÍÍÍÍÑÍÍÍÍÑÍÍÍÍÑÍÍÍÍ¹
  CBlueWindow  º  8 ³  9 ³ 10 ³ 11 ³ 12 ³ 13 ³ 14 ³ 15 º
               ÈÍÍÑÍÏÍÍÑÍÏÍÍÑÍÏÍÍÑÍÏÍÍÑÍÏÍÍÑÍÏÍÍÑÍÏÍÍÑÍ¼
  Frame PassiveÄÄÄÙ    ³    ³    ³    ³    ³    ³    ÀÄÄÄReserved
  Frame ActiveÄÄÄÄÄÄÄÄÄÙ    ³    ³    ³    ³    ÀÄÄÄÄÄÄÄÄScroller
                            ³    ³    ³    ³              Selected Text
  Frame IconÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ    ³    ³    ÀÄÄÄÄÄÄÄÄÄÄÄÄÄScroller Normal
                                 ³    ³                   Text
  ScrollBar PageÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ    ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄScrollBar
                                                          Reserved

*)
Const
  P:String[Length(CListViewer) + 1] = #1#2#5#6#2 + #1;
Begin
  GetPalette := @P;
End;
{---------------------------------------------------------}
Function TDOSShortWindow.GetPalette:PPalette;
Const
  P:String[Length(CBlueWindow)] = CBlueWindow;
Begin
  GetPalette := @P;
End;
{---------------------------------------------------------}
procedure TDOSShortWindow.ChangeDir;
Var
  P:PDOSSearchRec;
  CurDirName:NameStr;
  I:LongInt;
  isRootDir:Boolean;
  NewTitle:ShortString;
begin
  P:= PDOSSearchRec(@P);
  mFileList^.GetData(P);
  if (P^.Attr And Directory) <> 0 Then
  begin
    isRootDir:=False;
    If p^.name = '..' Then
    begin
      isRootDir:=True;
      CurDirName:=CurDir;
      While CurDirName[Length(CurDirName)] = '\' do
        {$Ifdef fpc}
        CurDirName:=LeftStr(CurDirName, Length(CurDirName) - 1);
        {$Else}
        CurDirName:=Copy(CurDirName, 1, Length(CurDirName) - 1);
        {$EndIf}
      CurDirName:=ExtractFileName(CurDirName);
      CurDirName:=UpperCase(CurDirName);
    end;

    CurDir:=ExpandFileName(CurDir + p^.name);

    While CurDir[Length(Curdir)] = '\' do
      CurDir:=LeftStr(CurDir, Length(CurDir) - 1);

    CurDir:=CurDir + '\';

    If Length(CurDir) = 3 Then
      NewTitle:=TruncPathStr(CurDir, Size.X - 16)
    Else
      NewTitle:=TruncPathStr(LeftStr(CurDir, Length(CurDir) - 1), Size.X - 16);

    DisposeStr(Title);
    Title :=NewStr(NewTitle);
    Redraw;

    mFileList^.ReadDirectory(CurDir + CurMask);

    If isRootDir And (Length(CurDirName) > 0) Then
      With mFileList^ do
      begin
        For I:=0 To List^.Count - 1 Do
        Begin
          P:= PDOSSearchRec(@P);
          P:=List^.At(I);
          If P^.Attr And Directory <> 0 Then
            If UpperCase(P^.Name) = CurDirName Then
            Begin
              SelectItem(I);
              FocusItem(I);
              Draw;
              Break;
            End;
        End;
      End;
  end;
end;

function MatchesMask(What, Mask: string): boolean;

  function upper(const s : string) : string;
  var
    i  : Sw_integer;
  begin
     for i:=1 to length(s) do
      if s[i] in ['a'..'z'] then
       upper[i]:=char(byte(s[i])-32)
      else
       upper[i]:=s[i];
     upper[0]:=s[0];
  end;

  Function CmpStr(const hstr1,hstr2:string):boolean;
  var
    found : boolean;
    i1,i2 : Sw_integer;
  begin
    i1:=0;
    i2:=0;
    if hstr1='' then
      begin
        CmpStr:=(hstr2='');
        exit;
      end;
    found:=true;
    repeat
      inc(i1);
      if (i1>length(hstr1)) then
        break;
      inc(i2);
      if (i2>length(hstr2)) then
        break;
      case hstr1[i1] of
        '?' :
          found:=true;
        '*' :
          begin
            found:=true;
            if (i1=length(hstr1)) then
             i2:=length(hstr2)
            else
             if (i1<length(hstr1)) and (hstr1[i1+1]<>hstr2[i2]) then
              begin
                if i2<length(hstr2) then
                 dec(i1)
              end
            else
             if i2>1 then
              dec(i2);
          end;
        else
          found:=(hstr1[i1]=hstr2[i2]) or (hstr2[i2]='?');
      end;
    until not found;
    if found then
      begin
        found:=(i2>=length(hstr2)) and
               (
                (i1>length(hstr1)) or
                ((i1=length(hstr1)) and
                 (hstr1[i1]='*'))
               );
      end;
    CmpStr:=found;
  end;

var
  D1,D2 : DirStr;
  N1,N2 : NameStr;
  E1,E2 : Extstr;
begin
{$ifdef Unix}
  FSplit(What,D1,N1,E1);
  FSplit(Mask,D2,N2,E2);
{$else}
  FSplit(Upper(What),D1,N1,E1);
  FSplit(Upper(Mask),D2,N2,E2);
{$endif}
  MatchesMask:=CmpStr(N2,N1) and (((E2 = '.*') And (E1 = '')) Or (CmpStr(E2,E1)));
end;

function MatchesMaskList(What, MaskList: string): boolean;
var P: integer;
    Match: boolean;
begin
  Match:=false;
  if What<>'' then
  repeat
    P:=Pos(ListSeparator, MaskList);
    if P=0 then P:=length(MaskList)+1;
    Match:=MatchesMask(What,copy(MaskList,1,P-1));
    Delete(MaskList,1,P);
  until Match or (MaskList='');
  MatchesMaskList:=Match;
end;

procedure TDOSShortWindow.ViewFile;
Var
  FileName:String;
  H: PFileWindow;
  P:PDOSSearchRec;
begin
  mFileList^.GetData(P);

  FileName:= CurDir;

  While FileName[Length(FileName)] = '\' do
    FileName:=LeftStr(FileName, Length(FileName) - 1);
  FileName:=FileName + '\' + P^.Name;

  If P^.Attr and Directory = 0 Then
    If FileExists(FileName) Then
    begin
      {$ifdef fpc}
      H := New(PFileWindow, Init(FileName, Trim(P^.Name), false));
      {$else}
      H := New(PFileWindow, Init(FileName, P^.Name, false));
      {$endif}
      Application^.InsertWindow(H);
    end;
end;

procedure TDOSShortWindow.ViewFileEx;
Var
  FileName:String;
  H: PFileWindow;
  P:PDOSSearchRec;
  BASFile:PBASFile;
  BASFileName:String;
begin
  mFileList^.GetData(P);

  FileName:= CurDir;

  While FileName[Length(FileName)] = '\' do
    FileName:=LeftStr(FileName, Length(FileName) - 1);
  FileName:=FileName + '\' + P^.Name;

  If P^.Attr and Directory = 0 Then
    If FileExists(FileName) Then
    begin
      {$ifdef fpc}
      If UpperCase(RightStr(FileName, 4)) = '.BAS' Then
      Begin
         BASFile:=New(PBASFile, Init(nil, FileName));
         BASFileName:=GetTempFileName;
         BASFile^.WriteBASFile(BASFileName);
         H := New(PFileWindow, Init(BASFileName, Trim(P^.Name), false));
         Application^.InsertWindow(H)
      End
      Else
         ViewFile;
      {$else}
      H := New(PFileWindow, Init(FileName, P^.Name, false));
      Application^.InsertWindow(H);
      {$endif}
    end;
end;

procedure TDOSFileList.ReadDirectory(AWildCard: PathStr);
const
  FindAttr = ReadOnly + Archive;
  PrevDir  = '..';
var
  S: DOS.SearchRec;
  P: PDOSSearchRec;
  FileList: PFileCollection;
  FindStr,
  WildName : ShortString;
  Dir: DirStr;
  Ext: ExtStr;
  Name: NameStr;
  Event : TEvent;
  Tmp: PathStr;
begin
  FileList := New(PDOSFileCollection, Init(5, 5));
  AWildCard := FExpand(AWildCard);
  FSplit(AWildCard, Dir, Name, Ext);
  if pos(ListSeparator,AWildCard)>0 then
   begin
     WildName:=Copy(AWildCard,length(Dir)+1,255);
     FindStr:=Dir+AllFiles;
   end
  else
   begin
     WildName:=Name+Ext;
     FindStr:=AWildCard;
   end; { for debug MessageBox(FindStr,nil,0); }
  FindFirst(FindStr, FindAttr, S);
  P := PDOSSearchRec(@P);
  while assigned(P) and (DosError = 0) do
   begin
     if (S.Attr and Directory = 0) and
        MatchesMaskList(S.Name,WildName) then
     begin
{       P := MemAlloc(SizeOf(P^));
       if assigned(P) then
       begin}
         new(P);
         P^.Attr:=S.Attr;
         P^.Time:=S.Time;
         P^.Size:=S.Size;
         P^.Name:=S.Name;
         P^.Selected:=False;
         FileList^.Insert(P);
{       end;}
     end;
     FindNext(S);
   end;
 {$ifdef fpc}
  FindClose(S);
 {$endif}

  Tmp := Dir + AllFiles;
  FindFirst(Tmp, Directory, S);
  while (P <> nil) and (DosError = 0) do
  begin
    if (S.Attr and Directory <> 0) and (S.Name <> '.') and (S.Name <> '..') then
    begin
{      P := MemAlloc(SizeOf(P^));
      if P <> nil then
      begin}
        new(p);
        P^.Attr:=S.Attr;
        P^.Time:=S.Time;
        P^.Size:=S.Size;
        P^.Name:=S.Name;
        P^.Selected:=False;
        FileList^.Insert(P);
{      end;}
    end;
    FindNext(S);
  end;
 {$ifdef fpc}
  FindClose(S);
 {$endif}
 {$ifndef Unix}
  if Length(Dir) > 4 then
 {$endif not Unix}
  begin
{
    P := MemAlloc(SizeOf(P^));
    if P <> nil then
    begin}
      new(p);
      FindFirst(Tmp, Directory, S);
      FindNext(S);
      if (DosError = 0) and (S.Name = PrevDir) then
       begin
         P^.Attr:=S.Attr;
         P^.Time:=S.Time;
         P^.Size:=S.Size;
         P^.Name:=S.Name;
         P^.Selected:=False;
       end
      else
       begin
         P^.Name := PrevDir;
         P^.Size := 0;
         P^.Time := $210000;
         P^.Attr := Directory;
         P^.Selected:=False;
       end;
      FileList^.Insert(PDOSSearchRec(P));
     {$ifdef fpc}
      FindClose(S);
     {$endif}
{    end;}
  end;
  if P = nil then
    MessageBox('Too many files.', nil, mfOkButton + mfWarning);
  NewList(FileList);
  if List^.Count > 0 then
  begin
    Event.What := evBroadcast;
    Event.Command := cmFileFocused;
    Event.InfoPtr := List^.At(0);
    Owner^.HandleEvent(Event);
  end;

end;

{---------------------------------------------------------}
procedure TDOSFileList.HandleEvent(Var Event: TEvent);
Var
  P:PDOSSearchRec;
  Item:LongInt;
begin
  Case Event.What of
    evKeyDown:
    Begin
      Case Event.Keycode Of
        kbIns:SelectItem(Focused);
        kbGrayAst:
        Begin
          If List^.Count > 0 Then
          Begin
            P := PDOSSearchRec(@P);
            For Item:=0 to List^.Count - 1 do
            Begin
              P := List^.At(Item);
              If P^.Attr And faDirectory <> faDirectory Then
                P^.Selected:=not P^.Selected;
            End;
            Draw;
          End
        End;
        kbGrayMinus:
        Begin
          If List^.Count > 0 Then
          Begin
            P := PDOSSearchRec(@P);
            For Item:=0 to List^.Count - 1 do
            Begin
              P := List^.At(Item);
              If P^.Attr And faDirectory <> faDirectory Then
                P^.Selected:=False;
            End;
            Draw;
          End
        End;
      End;
    End;
  evBroadCast:
    Case Event.Command of
      cmListItemSelected:
        Begin
          If List^.Count > 0 Then
          Begin
            P := PDOSSearchRec(@P);
            P := List^.At(Focused);
            If P^.Attr And faDirectory <> faDirectory Then
            Begin
              P^.Selected:=not P^.Selected;
              If List^.Count - 1 > Focused Then
                Inc(Focused);
              Draw;
            End;
          End;
        End;
    End;
  End;
  inherited HandleEvent(Event);
end;
{---------------------------------------------------------}
function TDOSFileList.IsSelected(Item: Sw_Integer):Boolean;
Begin
  IsSelected:=PDOSSearchRec(List^.At(Item))^.Selected;
End;
{---------------------------------------------------------}
PROCEDURE TDOSLongFileList.Draw;
VAR  I, J, ColWidth, Item, Indent, CurCol: Sw_Integer;
     Color: Word; SCOff: Byte;
     Text: String; B: TDrawBuffer;
BEGIN
   ColWidth := Size.X DIV NumCols + 1;                { Calc column width }
   If (HScrollBar = Nil) Then Indent := 0 Else        { Set indent to zero }
     Indent := HScrollBar^.Value;                     { Fetch any indent }
   For I := 0 To Size.Y - 1 Do Begin                  { For each line }
     For J := 0 To NumCols-1 Do Begin                 { For each column }
       Item := J*Size.Y + I + TopItem;                { Process this item }
       CurCol := J*ColWidth;                          { Current column }
       If (State AND (sfSelected + sfActive) =
       (sfSelected + sfActive)) AND (Focused = Item)  { Focused item }
       AND (Range > 0) Then Begin
       If IsSelected(Item) Then Color:=(GetColor(4) and $0F) + (GetColor(3) and $F0)  Else
         Color := GetColor(3);                        { Focused colour }
         SetCursor(CurCol+1,I);                       { Set the cursor }
         SCOff := 0;                                  { Zero colour offset }
       End Else If (Item < Range) AND IsSelected(Item){ Selected item }
       Then Begin
         Color := GetColor(4);                        { Selected color }
         SCOff := 2;                                  { Colour offset=2 }
       End Else Begin If State and sfActive = 0 Then Color := GetColor(1) Else
         Color := GetColor(2);                        { Normal Color }
         SCOff := 4;                                  { Colour offset=4 }
       End;
      MoveChar(B[CurCol], ' ', Color, ColWidth);     { Clear buffer }
       If (Item < Range) Then Begin                   { Within text range }
         Text := GetText(Item, ColWidth + Indent);    { Fetch text }
         Text := Copy(Text, Indent, ColWidth);        { Select right bit }
         MoveStr(B[CurCol+1], Text, Color);           { Transfer to buffer }
         If ShowMarkers Then Begin
           WordRec(B[CurCol]).Lo := Byte(
             SpecialChars[SCOff]);                        { Set marker character }
           WordRec(B[CurCol+ColWidth-2]).Lo := Byte(
             SpecialChars[SCOff+1]);                        { Set marker character }
         End;
       End;
       If State and sfActive <> 0 Then
         MoveChar(B[CurCol+ColWidth-1], #179,
           GetColor(5), 1)                             { Put centre line marker }
       Else
         MoveChar(B[CurCol+ColWidth-1], #179,
           GetColor(6), 1);                            { Put centre line marker }
     End;
     WriteLine(0, I, Size.X, 1, B);                 { Write line to screen }
   End;
END;
(*
PROCEDURE TDOSLongFileList.Draw;
VAR  I, J, ColWidth, Item, Indent, CurCol: Sw_Integer;
     Color: Word; SCOff: Byte;
     Text: String; B: TDrawBuffer;
BEGIN
   ColWidth := Size.X DIV NumCols + 1;                { Calc column width }
   If (HScrollBar = Nil) Then Indent := 0 Else        { Set indent to zero }
     Indent := HScrollBar^.Value;                     { Fetch any indent }
   For I := 0 To Size.Y - 1 Do Begin                  { For each line }
     For J := 0 To NumCols-1 Do Begin                 { For each column }
       Item := J*Size.Y + I + TopItem;                { Process this item }
       CurCol := J*ColWidth;                          { Current column }
       If (State AND (sfSelected + sfActive) =
       (sfSelected + sfActive)) AND (Focused = Item)  { Focused item }
       AND (Range > 0) Then Begin
       If IsSelected(Item) Then Color:=(GetColor(4) and $0F) + (GetColor(3) and $F0)  Else
         Color := GetColor(3);                        { Focused colour }
         SetCursor(CurCol+1,I);                       { Set the cursor }
         SCOff := 0;                                  { Zero colour offset }
       End Else If (Item < Range) AND IsSelected(Item){ Selected item }
       Then Begin
         Color := GetColor(4);                        { Selected color }
         SCOff := 2;                                  { Colour offset=2 }
       End Else Begin
         Color := GetColor(2);                        { Normal Color }
         SCOff := 4;                                  { Colour offset=4 }
       End;
      MoveChar(B[CurCol], ' ', Color, ColWidth);     { Clear buffer }
       If (Item < Range) Then Begin                   { Within text range }
         Text := GetText(Item, ColWidth + Indent);    { Fetch text }
         Text := Copy(Text, Indent, ColWidth);        { Select right bit }
         MoveStr(B[CurCol+1], Text, Color);           { Transfer to buffer }
         If ShowMarkers Then Begin
           WordRec(B[CurCol]).Lo := Byte(
             SpecialChars[SCOff]);                        { Set marker character }
           WordRec(B[CurCol+ColWidth-2]).Lo := Byte(
             SpecialChars[SCOff+1]);                        { Set marker character }
         End;
       End;
       MoveChar(B[CurCol+ColWidth-1], #179,
         GetColor(5), 1);                             { Put centre line marker }
     End;
     WriteLine(0, I, Size.X, 1, B);                 { Write line to screen }
   End;
END;
*)
{---------------------------------------------------------}

Constructor TDOSShortWindow.Init(Dir, Mask: ShortString);
Var
  R:TRect;
  name:NameStr;
  ext :ExtStr;
Begin
  Desktop^.GetExtent(R);
  R.A.X:=R.B.X div 2;
  R.B.Y:=R.B.Y - 1;
  FSplit(Dir, CurDir, name, ext);
  TDialog.Init(R, TruncPathStr(CurDir, R.B.X - R.A.X - 4));
{  Palette:=wpBlueWindow;}
  CurMask:=Mask;
  R.Assign(1, 1, Size.X - 1, Size.Y - 1);
  mFileList:=New(PDOSLongFileList, Init(R, Nil));
  mFileList^.SetState(sfCursorVis, False);
  Insert(mFileList);
  mFileList^.ReadDirectory(CurDir + '\' + CurMask);
End;
{---------------------------------------------------------}
Destructor TDOSShortWindow.Done;
Begin
  Dispose(mFileList,Done);
  Inherited Done;
End;
{---------------------------------------------------------}
Procedure TDOSShortWindow.HandleEvent(Var Event:TEvent);
Var
  FileNames:^TFileNames;
Begin
  Case Event.What Of
    evKeyDown:
    Begin
      Case Event.Keycode Of
        kbEnter: ChangeDir;
        kbF5: CopyFile;
        kbCtrlR:
        Begin
          mFileList^.ReadDirectory(CurDir + CurMask);
          ClearEvent(Event);
        End;
        kbShiftF3:
        Begin
          ViewFileEx;
          ClearEvent(Event);
        End;
      end;
    end;
    evMouseDown: if Event.Double And (Event.Buttons = mbLeftButton) Then
    begin
      ChangeDir;
      ClearEvent(Event);
    end;
    evCommand:
      Case Event.Command Of
        cmOpen:
        Begin
          ViewFile;
          ClearEvent(Event);
        End;
        cmClose:
        begin
          ClearEvent(Event);
        end;
(*        cmCopyFileMST:
        begin
          FileNames:=Event.InfoPtr;
          AddFile(FileNames^);
          ClearEvent(Event);
        End;*)
    end;
    evBroadCast:
      Case Event.Command Of
        cmCopyFileMST:
        begin
          FileNames:=Event.InfoPtr;
          AddFile(FileNames^);
          ClearEvent(Event);
        End;
      End;
  End;
  Inherited HandleEvent(Event);
End;
{---------------------------------------------------------}
procedure TDOSShortWindow.CopyFile;
Var
  FileName:String;
  lCurDir:String;
  P:PDOSSearchRec;
  ExistSelected:Boolean;
  Item:LongInt;
begin

  ExistSelected:=False;
  For Item:=0 to mFileList^.List^.Count - 1 do
    ExistSelected := ExistSelected Or mFileList^.IsSelected(Item);

  lCurDir:=CurDir;
  While lCurDir[Length(lCurDir)] = '\' do
    lCurDir:=LeftStr(lCurDir, Length(lCurDir) - 1);

  If ExistSelected Then
  Begin
    For Item:=0 to mFileList^.List^.Count - 1 do
    Begin
      P := PDOSSearchRec(mFileList^.List^.At(Item));
      If P^.Selected Then
      Begin
        FileName:=lCurDir + '\' + P^.Name;

        If P^.Attr and Directory = 0 Then
          If FileExists(FileName) Then
          begin
      //      Message(Application, evCommand, cmCopyFileDOS, @FileName);
            Message(Application, evBroadCast, cmCopyFileDOS, @FileName);
          end;
        P^.Selected:=False;
      End;
    End;
    Draw;
  End
  Else
  Begin
    mFileList^.GetData(P);

    FileName:=lCurDir + '\' + P^.Name;

    If P^.Attr and Directory = 0 Then
      If FileExists(FileName) Then
      begin
  //      Message(Application, evCommand, cmCopyFileDOS, @FileName);
        Message(Application, evBroadCast, cmCopyFileDOS, @FileName);
      end;
  End;

end;
{---------------------------------------------------------}
procedure TDOSShortWindow.AddFile(FileNames:TFileNames);
Var
  FileName:String;
{  Rslt:Word; }
begin

  FileName:= CurDir;

  While FileName[Length(FileName)] = '\' do
    FileName:=LeftStr(FileName, Length(FileName) - 1);
  FileName:=FileName + '\' + FileNames[0];

  If FileExists(FileName) Then
  begin
    If (FileGetAttr(FileName) and faDirectory) <> 0 Then
    begin
      MessageBox('Directory ' + FileNames[0] + ' exist, can''t erase!', nil, mfError or mfOKButton);
      Exit;
    end
    else
    begin
      if StdDlg.ReplaceFile(FileName) Then
        If Not SysUtils.DeleteFile(FileName) Then
        Begin
          MessageBox('Can''t erase file'#13 + FileNames[0], nil, mfError or mfOKButton);
          Exit;
        End;
    end;
  End;
  If (not RenameFile(FileNames[1], FileName)) Then
    MessageBox('Can''t rename file'#13 + FileNames[1] + #13'to'#13 + FileName, nil, mfError or mfOKButton)
  else
    mFileList^.ReadDirectory(CurDir + CurMask);
//  Dispose(FileNames, Done);
end;
{---------------------------------------------------------}
Constructor TDOSLongWindow.Init(Dir, Mask:String);
Var
  R:TRect;
  name:NameStr;
  ext :ExtStr;
Begin
  Desktop^.GetExtent(R);
  R.A.X:=R.B.X div 2;
  R.B.Y:=R.B.Y - 1;

  While Dir[Length(Dir)] = '\' do
    Dir:=LeftStr(Dir, Length(Dir) - 1);

  TDialog.Init(R, TruncPathStr(Dir, R.B.X - R.A.X - 16));

{  Palette:=wpCyanWindow; }

  Dir:=Dir + '\';

  FSplit(Dir, CurDir, name, ext);

  CurMask:=Mask;
  R.Assign(1, 1, Size.X - 1, Size.Y - 1);
  mFileList:=New(PDOSLongFileList, Init(R, Nil));
  mFileList^.SetState(sfCursorVis, False);
  Insert(mFileList);
  While CurDir[Length(CurDir)] = '\' do
    CurDir:=LeftStr(CurDir, Length(CurDir) - 1);
  CurDir:=CurDir + '\';
  mFileList^.ReadDirectory(CurDir + CurMask);
End;

End.
