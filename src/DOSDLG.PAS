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
Uses SysUtils, Stddlg, Objects, Views, Drivers, Dialogs, Dos;
{---------------------------------------------------------}

Type
  PDOSFileList = ^TDOSFileList;
  TDOSFileList = Object(TFileList)
    Procedure Draw; Virtual;
    Procedure HandleEvent(Var Event: TEvent); Virtual;
    procedure GetData(var Rec); virtual;
    constructor Init(var Bounds: TRect; AScrollBar: PScrollBar);
    procedure ReadDirectory(AWildCard: PathStr);virtual;
    Function GetText(Item, MaxLen: Sw_Integer): String;virtual;
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
    Procedure CopyFile; virtual;
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

Uses App, MsgBox, FVConsts, FViewer, MSTConst;

function TDOSFileList.GetText(Item,MaxLen: Sw_Integer): String;
var
  S: String;
  SR: PSearchRec;
begin
  SR := PSearchRec(List^.At(Item));
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
function TDOSFileCollection.Compare(Key1, Key2: Pointer): LongInt;
Var
  Dir2,Dir1   : DirStr;
  Name2,Name1 : NameStr;
  Ext2,Ext1   : ExtStr;
begin
  If PSearchRec(Key1)^.Name = PSearchRec(Key2)^.Name Then Compare := 0
  Else If PSearchRec(Key1)^.Name = '..' Then Compare := -1
  Else If PSearchRec(Key2)^.Name = '..' Then Compare := 1
  Else If (PSearchRec(Key1)^.Attr And Directory <> 0) And
          (PSearchRec(Key2)^.Attr And Directory = 0) Then Compare := -1
  Else If (PSearchRec(Key2)^.Attr And Directory <> 0) And
          (PSearchRec(Key1)^.Attr And Directory = 0) Then Compare := 1
    {  else if PSearchRec(Key1)^.Name > PSearchRec(Key2)^.Name then
    Compare := 1
  else Compare := -1;}
  Else
  Begin
    FSplit(UpperCase(PSearchRec(Key1)^.Name),Dir1,Name1,Ext1);
    FSplit(UpperCase(PSearchRec(Key2)^.Name),Dir2,Name2,Ext2);
    If (PSearchRec(Key2)^.Attr And Directory <> 0) And
       (PSearchRec(Key1)^.Attr And Directory <> 0) Then
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
   PSearchRec(Rec):=PSearchRec(List^.At(Focused));
end;
{---------------------------------------------------------}
procedure TDOSShortWindow.ChangeDir;
Var
  P:PSearchRec;
  CurDirName:NameStr;
  I:LongInt;
  isRootDir:Boolean;
begin
  P:= PSearchRec(@P);
  mFileList^.GetData(P);
  if (P^.Attr And Directory) <> 0 Then
  begin
    isRootDir:=False;
    If p^.name = '..' Then
    begin
      isRootDir:=True;
      CurDirName:=CurDir;
      While CurDirName[Length(CurDirName)] = '\' do
        CurDirName:=LeftStr(CurDirName, Length(CurDirName) - 1);
      CurDirName:=ExtractFileName(CurDirName);
      CurDirName:=UpperCase(CurDirName);
    end;

    CurDir:=ExpandFileName(CurDir + p^.name);
    While CurDir[Length(Curdir)] = '\' do
      CurDir:=LeftStr(CurDir, Length(CurDir) - 1);
    CurDir:=CurDir + '\';
    mFileList^.ReadDirectory(CurDir + CurMask);

    If isRootDir And (Length(CurDirName) > 0) Then
      With mFileList^ do
      begin
        For I:=0 To List^.Count - 1 Do
        Begin
          P:= PSearchRec(@P);
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
  MatchesMask:=CmpStr(N2,N1) and CmpStr(E2,E1);
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
  P:PSearchRec;
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

procedure TDOSFileList.ReadDirectory(AWildCard: PathStr);
const
  FindAttr = ReadOnly + Archive;
  PrevDir  = '..';
var
  S: SearchRec;
  P: StdDlg.PSearchRec;
  FileList: PFileCollection;
  NumFiles: Word;
  FindStr,
  WildName : string;
  Dir: DirStr;
  Ext: ExtStr;
  Name: NameStr;
  Event : TEvent;
  Tmp: PathStr;
begin
  NumFiles := 0;
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
  P := StdDlg.PSearchRec(@P);
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
       end
      else
       begin
         P^.Name := PrevDir;
         P^.Size := 0;
         P^.Time := $210000;
         P^.Attr := Directory;
       end;
      FileList^.Insert(PSearchRec(P));
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
begin
  inherited HandleEvent(Event);
end;
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
  TDialog.Init(R, Dir);
{  Palette:=wpBlueWindow;}
  FSplit(Dir, CurDir, name, ext);
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
Begin
  Case Event.What Of
    evKeyDown:
    Begin
      Case Event.Keycode Of
        kbEnter: ChangeDir;
        kbF5: CopyFile;
      end;
    end;
    evMouseDown: if Event.Double Then
    begin
      ChangeDir;
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
    end;
  End;
  Inherited HandleEvent(Event);
End;
{---------------------------------------------------------}
procedure TDOSShortWindow.CopyFile;
Var
  FileName:String;
  P:PSearchRec;
begin
  mFileList^.GetData(P);

  FileName:= CurDir;

  While FileName[Length(FileName)] = '\' do
    FileName:=LeftStr(FileName, Length(FileName) - 1);
  FileName:=FileName + '\' + P^.Name;

  If P^.Attr and Directory = 0 Then
    If FileExists(FileName) Then
    begin
      Message(Application, evCommand, cmCopyFileDOS, @FileName);
    end;
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
  TDialog.Init(R, ExtractFileDrive(Dir) + '\');
{  Palette:=wpBlueWindow;}

  While Dir[Length(Dir)] = '\' do
    Dir:=LeftStr(Dir, Length(Dir) - 1);
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
