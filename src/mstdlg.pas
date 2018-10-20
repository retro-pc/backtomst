{************************************************}
{                                                }
{  Copyright (C) MarinovSoft 2013-2014           }
{                                                }
{  http://marinovsoft.narod.ru                   }
{  mailto:super386@rambler.ru                    }
{                                                }
{************************************************}
{.$DEFINE DEB}

{$ifdef fpc}
{$A1}
{$endif}

Unit MstDlg;

Interface

Uses

{$ifdef fpc}
SysUtils,
{$endif}

Views, StdDlg, Dialogs, Drivers, Objects, MSTDisk, MsgBox;

Type

  PMSTFileList = ^TMSTFileList;
  TMSTFileList = Object(TFileList)
    constructor Init(var Bounds: TRect; AScrollBar: PScrollBar);
    procedure SetData(var Rec); virtual;
    Procedure ReadDir;virtual;
    {$ifdef fpc}
    function GetText(Item: LongInt; MaxLen: LongInt): ShortString; virtual;
    {$else}
    function GetText(Item: Integer; MaxLen: Integer): String; virtual;
    {$endif}
    function GetKey(var S: String): Pointer; virtual;
    procedure HandleEvent(Var Event: TEvent); virtual;
    procedure GetData(var Rec); virtual;

  end;

Type
  PMSTShortWindow = ^TMSTShortWindow;
  TMSTShortWindow = Object(TDialog)
  Public
    CurDir:String;
    Msk:String;
    Lb:PMSTFileList;
    MSTDisk:PMSTDisk;
  {  Constructor Init(Dir,Mask:String);}
    Constructor Init(lMSTDisk:PMSTDisk);
    Destructor Done;Virtual;
    Procedure HandleEvent(Var Event:TEvent);Virtual;
    Procedure SaveFile;virtual;
    Procedure SaveFileAs(FileName:ShortString);virtual;
    Procedure AddFile(FileName:ShortString);virtual;
    Procedure ViewFile;virtual;
    Procedure DeleteFile;Virtual;
    Procedure CopyFile;Virtual;
    Function FileExists(FileName:ShortString; User:Byte):Boolean;virtual;
  End;
  {---------------------------------------------------------}

Type

  PCPMFileCollection = ^TCPMFileCollection;
  TCPMFileCollection = object(TFileCollection)
    {$ifdef fpc}
    function Compare(Key1, Key2: Pointer): LongInt; virtual;
    {$else}
    function Compare(Key1, Key2: Pointer): Integer; virtual;
    {$endif}
    procedure FreeItem(Item: Pointer); virtual;
    function GetItem(var S: TStream): Pointer; virtual;
    procedure PutItem(var S: TStream; Item: Pointer); virtual;
  end;

  PEntryCollection = ^TEntryCollection;
  TEntryCollection = object(TSortedCollection)
    {$ifdef fpc}
    function Compare(Key1, Key2: Pointer): Sw_Integer; virtual;
    {$else}
    function Compare(Key1, Key2: Pointer): Integer; virtual;
    {$endif}
  end;

Implementation

Uses App, Dos, MstConst, FViewer;


type
  PSearchRec = ^TSearchRec;

  PMSTSearchRec = ^TMSTSearchRec;
  TMSTSearchRec = packed record
{    Attr: Longint;}
    User: Byte;
    Time: Longint;
    Size: Longint;
    case Integer of
      1:(Name: string[12]);
      2:(Res:Char;FName:Array[0..7] Of Char;Dot:Char;FExt:Array[0..2] Of Char);
  end;

{---------------------------------------------------------}
constructor TMSTFileList.Init(var Bounds: TRect; AScrollBar: PScrollBar);
Var
   ColCount:Byte;
begin
  ColCount:=2;
  If (Bounds.B.X - Bounds.A.X - 2) div 2 < 26 Then
    ColCount:=1;
  TSortedListBox.Init(Bounds, ColCount, AScrollBar);
end;
{---------------------------------------------------------}
procedure TMSTFileList.SetData(var Rec);
begin
    ReadDir;
end;
{---------------------------------------------------------}
procedure TMSTFileList.ReadDir;
Var
  Filelist:PCPMFileCollection;
  P: PMSTSearchRec;
  S: TMSTSearchRec;
  I: Word;
  Catalog:TCatalog;
  J: Word;
  _F:File;

  fExist:Boolean;

begin

  PMSTShortWindow(Owner)^.MSTDisk^.ReadDir(Catalog);

  {$IFDEF DEB}
  Assign(_F,'1.DEB');
  Rewrite(_F,1);
  BlockWrite(_F,Catalog,SizeOf(Catalog));
  Close(_F);
  {$ENDIF}

  Filelist:=New(PCPMFileCollection,Init(5, 5));

  P := PMSTSearchRec(@P);

  I:=0;
(*  While (P <> nil) and (I <= (SizeOf(TCatalog) div SizeOf(TEntry)) - 1) do
  begin

    { if Catalog[I].Recs<>$80 Then }
    begin

      P := MemAlloc(SizeOf(P^));
      if P <> nil then
      begin
        S.Name:= Catalog[I].Name + '.' + Char(Byte(Catalog[I].Ext[0]) And $7F)
                                       + Char(Byte(Catalog[I].Ext[1]) And $7F)
                                       + Char(Byte(Catalog[I].Ext[2]) And $7F);
        S.Size:= LongInt(Catalog[I].Recs) * 128 + LongInt(Catalog[I].Exn);

        If Byte(Catalog[I].User) = $E5 Then
        begin
           I:=I+1;
           continue;
        end;

        fExist:=False;
        If FileList^.Count > 0 Then
        begin
        For J:=0 To FileList^.Count - 1 do
        begin
           P:= FileList^.At(J);
{           MessageBox('S.Name = ' + S.Name + ', FileList.Name = ' + TMSTSearchRec(FileList^.At(J)^).Name, Nil,0);}
           if TMSTSearchRec(FileList^.At(J)^).Name = S.Name Then
           begin
              P:= FileList^.At(J);
             { MessageBox(S.Name,Nil,0);}
              fExist:=True;
              Break;
           end;
        end;
        end;
        If fExist Then
        begin
          P^.Size:=P^.Size + S.Size;
        end
        else
        begin
          new(P);
          P^.Attr:=S.Attr;
          P^.Time:=S.Time;
          P^.Size:=S.Size;
          P^.Name:=S.Name;
          FileList^.Insert(P);
        end;
      end;

    end;

    I:=I+1;

  end; *)

  While (P <> nil) and (I <= (SizeOf(TCatalog) div SizeOf(TEntry)) - 1) do { На первом проходе заполняем список имен файлов }
  begin
    if Catalog[I].Recs < $80 Then
    begin
        S.Name:= Catalog[I].Name + '.' + Char(Byte(Catalog[I].Ext[0]) And $7F)
                                       + Char(Byte(Catalog[I].Ext[1]) And $7F)
                                       + Char(Byte(Catalog[I].Ext[2]) And $7F);
        S.User:= Catalog[I].User;
        new(P);
        FillChar(P^,SizeOf(P^), 0);
        P^.Name:=UpperCase(String(S.Name));
        P^.User:=S.User;
        FileList^.Insert(P);

    end;
    I:=I+1;
  end;

  If FileList^.Count > 0 Then
  begin
     For J:=0 To FileList^.Count - 1 do
     begin
        P:= FileList^.At(J);
        For I:=0 to ((SizeOf(TCatalog) div SizeOf(TEntry)) - 1) do
        begin
          S.Name:= Catalog[I].Name + '.' + Char(Byte(Catalog[I].Ext[0]) And $7F)
                                         + Char(Byte(Catalog[I].Ext[1]) And $7F)
                                         + Char(Byte(Catalog[I].Ext[2]) And $7F);
          S.Name:= UpperCase(S.Name);
          S.User:= Catalog[I].User;
          if (TMSTSearchRec(FileList^.At(J)^).Name = S.Name) And (TMSTSearchRec(FileList^.At(J)^).User = S.User) Then
          begin
{             S.Size:= LongInt(Catalog[I].Recs) * 128 + LongInt(Catalog[I].Re0);}
            S.Size:= LongInt(Catalog[I].Recs) shl $07 + LongInt(Catalog[I].Re0);
            P:= FileList^.At(J);
            P^.Size:=P^.Size + S.Size;
          end;
        end;
     end;
  end;

  Newlist(Filelist);
end;

function TMSTFileList.GetKey(var S: String): Pointer;
const
  SR: TMSTSearchRec = ();

procedure UpStr(var S: String);
var
  I: Integer;
begin
  for I := 1 to Length(S) do S[I] := UpCase(S[I]);
end;

begin
  GetKey := @S;
end;

{$ifdef fpc}
function TMSTFileList.GetText(Item: LongInt; MaxLen: LongInt): ShortString;
{$else}
function TMSTFileList.GetText(Item: Integer; MaxLen: Integer): String;
{$endif}
var
  S: String;
  SR: PMSTSearchRec;
begin
  SR := PMSTSearchRec(List^.At(Item));
  {$ifdef fpc}
  {S := SR^.Name + '.' + Chr(Byte(SR^.Ext[0]) And $7F) +
                        Chr(Byte(SR^.Ext[1]) And $7F) +
                        Chr(Byte(SR^.Ext[2]) And $7F) + '  ' + Format('%8d', [LongInt(SR^.Recs) * 128 + LongInt(SR^.Exn)]);}
  S:= SR^.Name + '  ' + Format('%8d', [SR^.Size]) + Format('%4d', [SR^.User]);
  {$else}
  S := SR^.Name;
  {$endif}
  GetText := S;
end;


procedure TMSTFileList.HandleEvent(Var Event: TEvent);
begin
  If Event.What = evCommand Then
{    Case Event.Command Of
      cmSave:
      Begin
        MessageBox('qqq', nil, 0);
        ClearEvent(Event);
      End;
    End}
  Else If (Event.What = evKeyDown) Then
  Begin
    Case Event.Keycode Of
      kbIns:SelectItem(Focused);
    End;
  End;
  TSortedListBox.HandleEvent(Event);
end;

procedure TMSTFileList.GetData(var Rec);
begin
  PMSTSearchRec(Rec):=PMSTSearchRec(List^.At(Focused));
end;

{---------------------------------------------------------}
{Constructor TMSTShortWindow.Init(Dir,Mask:String);}
Constructor TMSTShortWindow.Init(lMSTDisk:PMSTDisk);
Var
  R:TRect;
  Sb:PScrollBar;
  ST:PStaticText;
Begin

  Desktop^.GetExtent(R);
  R.B.X:= R.A.X + ((R.B.X - R.A.X) div 2);

{  TWindow.GetExtent(R);}

  R.B.Y:=R.B.Y-1;
{  R.Assign(0,0,40,22);}

{  Inherited Init(R,Dir);}
  Inherited Init(R,'MST Disk');

  {  R.Assign(39,1,40,21);
  Sb:=New(PScrollBar,Init(R));}

{  R.Assign(1,1,39,2);
  ST:=New(PStaticText,Init(R,Dir[1]+Dir[2]+#25' Имя     │    Имя     │    Имя'));
  Insert(ST);}

  MSTDisk:= lMSTDisk;

  R.Assign(1 ,1 {2}, Size.X - 1, Size.Y - 1);
  Lb:=New(PMSTFileList,Init(R, Nil));

  Lb^.SetState(sfCursorVis, False);

  Insert(Lb);

{  Lb^.ReadDirectory(Dir,Mask);}
  {  SetState(sfShadow,False);}
   Lb^.ReadDir;
End;
{---------------------------------------------------------}
Destructor TMSTShortWindow.Done;
Begin
  Dispose(MSTDisk, Done);
  Dispose(Lb,Done);
  Inherited Done;
End;
{---------------------------------------------------------}
Procedure TMSTShortWindow.HandleEvent(Var Event:TEvent);
Begin
  Case Event.What Of
    evCommand:
    Case Event.Command Of
(*
      cmSave:
      Begin
        SaveFile;
        ClearEvent(Event);
      End;
*)
      cmOpen:
      Begin
        ViewFile;
        ClearEvent(Event);
      End;
      cmDelete:
      begin
        DeleteFile;
        ClearEvent(Event);
      End;
      cmCopyFileDOS:
      begin
        AddFile(String(Event.InfoPtr^));
        ClearEvent(Event);
      end;
    End;
    evKeyDown:
    Case Event.KeyCode of
      kbF5: CopyFile;
    End;
    evBroadCast:
    Case Event.Command Of
      cmCopyFileDOS:
      begin
        AddFile(String(Event.InfoPtr^));
        ClearEvent(Event);
      end;
    End;
{    evKeyDown:
    Case Event.Keycode Of
      kbF4:
      Begin
        ViewFile;
        ClearEvent(Event);
      End;
    End;}
  End;
  Inherited HandleEvent(Event);
End;
{---------------------------------------------------------}
Procedure TMSTShortWindow.DeleteFile;
Var
  Catalog:TCatalog;
  P:PMSTSearchRec;
  I:Word;
begin
  P := PMSTSearchRec(@P);

  Lb^.GetData(P);

  MSTDisk^.ReadDir(Catalog);

  If P^.User = $E5 Then
    Exit;

  I:=0;

  While (I <= (SizeOf(TCatalog) div SizeOf(TEntry)) - 1) do
  begin

    Catalog[I].Ext[0]:=Char(Byte(Catalog[I].Ext[0]) And $7F);
    Catalog[I].Ext[1]:=Char(Byte(Catalog[I].Ext[1]) And $7F);
    Catalog[I].Ext[2]:=Char(Byte(Catalog[I].Ext[2]) And $7F);

    If ((Catalog[I].Name = P^.FName) and (Catalog[I].Ext = P^.FExt) and (Catalog[I].User = P^.User)) Then
      Catalog[I].User:=$E5;
    I:=I+1;
  end;

  MSTDisk^.WriteDir(Catalog);

  Lb^.ReadDir;
end;
{---------------------------------------------------------}
Procedure TMSTShortWindow.SaveFileAs(FileName:ShortString);
Var
  Catalog:TCatalog;
  _F:File;
  I,J:Word;

  pcat:PEntryCollection;
  Entry:PEntry;
  buf:Array[0..1024 * 2 - 1] Of Byte;

  FileSize:LongInt;

  P:PMSTSearchRec;

begin

  P := PMSTSearchRec(@P);

  Lb^.GetData(P);

  MSTDisk^.ReadDir(Catalog);

  Assign(_F, FileName);
  ReWrite(_F,1);

  I:=0;

  pcat:=New(PEntryCollection, Init(1,1));

  While (I <= (SizeOf(TCatalog) div SizeOf(TEntry)) - 1) do
  begin

    Catalog[I].Ext[0]:=Char(Byte(Catalog[I].Ext[0]) And $7F);
    Catalog[I].Ext[1]:=Char(Byte(Catalog[I].Ext[1]) And $7F);
    Catalog[I].Ext[2]:=Char(Byte(Catalog[I].Ext[2]) And $7F);

    If ((UpperCase(Catalog[I].Name) = P^.FName) and (UpperCase(Catalog[I].Ext) = P^.FExt) and (Catalog[I].User = P^.User)) Then
      pcat^.Insert(@Catalog[I]);
    I:=I+1;
  end;

  If pcat^.Count > 0 Then
  begin
    For I:=0 To pcat^.Count - 1 do
    begin
      Entry:= pcat^.At(I);
      FileSize:=(LongInt(Entry^.Recs) shl $07) + Entry^.Re0;
      J:=0;
      while (FileSize > 0) Do
      begin
        PMicroDOSDisk(MSTDisk)^.ReadBlock(Entry^.Fat[J], @buf);
        If FileSize >= SizeOf(Buf) Then
          BlockWrite(_F, buf, SizeOf(Buf))
        else
          BlockWrite(_F, buf, FileSize);
        FileSize:=FileSize - SizeOf(Buf);
        J:=J+1;
      end;
    end;
  end;
  System.Close(_F);
end;
{---------------------------------------------------------}
Procedure TMSTShortWindow.SaveFile;
Var
  P:PMSTSearchRec;
  FileName:ShortString;
  w:Word;
Const
  IllegalChars:set of char = ['*',':','?','<','>','|','"','/','\'];
begin
  P := PMSTSearchRec(@P);

  Lb^.GetData(P);

  {$ifdef fpc}

  FileName:=Trim(P^.FName) + '.' + Trim(P^.FExt);

  for w:=1 to Length(FileName) do
    if FileName[w] in IllegalChars Then FileName[w]:='_';

  SaveFileAs(FileName);

{   Dispose(pcat, Done);}
  {$endif}
end;
{---------------------------------------------------------}
Procedure TMSTShortWindow.ViewFile;
Var
  FileName:ShortString;
  H: PFileWindow;
  R: TRect;
  P: PMSTSearchRec;
begin

  P := PMSTSearchRec(@P);

  Lb^.GetData(P);

  FileName:=GetTempFileName;
  SaveFileAs(FileName);
  If SysUtils.FileExists(FileName) Then
  begin
{     R.Assign(0,0,72,15);  }
{     Desktop^.GetExtent(R);}
    {$ifdef fpc}
    H := New(PFileWindow, Init(FileName, Trim(P^.FName) + '.' + Trim(P^.FExt), false));
    {$else}
    H := New(PFileWindow, Init(FileName, FileName, false));
    {$endif}
    Application^.InsertWindow(H);
{     Desktop^.Insert(H);   }
  end;
end;
(*
var
  H: PHexWindow;
  R: TRect;
begin
  R.Assign(0,0,72,15);
  H := New(PHexWindow, Init(R, FileName));
  H^.Options := H^.Options or ofCentered;
  Desktop^.Insert(H);
end;
*)
{---------------------------------------------------------}
Procedure TMSTShortWindow.AddFile(FileName:ShortString);
Var
  Catalog:TCatalog;
  I,J:Word;
  FreeVec:Word;
  F:File;
  FileSize:LongInt;
  buf:Array[0..1024 * 2 - 1] Of Byte;

  Frm_Vec:TFrm_Vec;
  ExN:Word;
  FatRec:Byte;
  Errc:Byte;
begin
  // FileName:='C:\UTIL\FPC\SAVE\MST.NEW\TV\fdrawcmd.ppu';

  MSTDisk^.ReadDir(Catalog);

  { TODO: Добавить проверку на наличие места в каталоге   }
  { TODO: Добавить проверку на то что файл уже существует }

  FileName:=UpperCase(FileName);

  If Self.FileExists(ExtractFileName(FileName) + ExtractFileExt(FileName), 0) Then
  Begin
    MessageBox('File'#13 + ExtractFileName(FileName) + ExtractFileExt(FileName) + #13'for user 0 exist, can''t add file', Nil, mfError +
      mfOKButton);
    Exit;
  End;

  { Не совсем верный подсчет количества незанятых экстентов }
  { Должен ли драйвер ФС обнулять незанятые записи FAT ???  }
  I:=0;
  FreeVec:=BlockCount - 2;

  FillChar(Frm_Vec, SizeOf(Frm_Vec), 0);
  Frm_Vec[0]:=1;
  Frm_Vec[1]:=1;

  While (I <= (SizeOf(TCatalog) div SizeOf(TEntry)) - 1) do
  begin
    if Catalog[I].User <> $E5 Then
    begin
      For J:=0 to 7 do
        If (Catalog[I].Fat[J] < BlockCount) And (Catalog[I].Fat[J] > 1) Then
        begin
          Frm_Vec[Catalog[I].Fat[J]]:=1;
          Dec(FreeVec);
        end;
    end;
    I:=I+1;
  end;

  Assign(F, FileName);
  {$I-}
  Reset(F, 1);
  FileSize:=System.FileSize(F);
  System.Close(F);
  {$I+}
  If IOResult <> 0 Then
  Begin
    FileName:=ExtractFileName(FileName) + ExtractFileExt(FileName);
    MessageBox('Error open file: '#13 + FileName, nil, mfError or mfOKButton);
    Exit;
  End;
  If LongInt(FreeVec) * 2048 < FileSize Then
  Begin
    FileName:=ExtractFileName(FileName) + ExtractFileExt(FileName);
    MessageBox('Not enough free space for file: '#13 + FileName, nil, mfError or mfOKButton);
    Exit;
  End;

  //FileName:=ExtractFileName(FileName);
  //FileName:=UpperCase(FileName);
  Reset(F, 1);
  I:=0;
  J:=2;
  ExN:=0;
  FatRec:=0;
  while (FileSize > 0) Do
  begin
    FillChar(Buf, SizeOf(Buf), 0);

    If FatRec = 0 Then
      While (I < (SizeOf(TCatalog) div SizeOf(TEntry)) - 1) do
      begin
        if Catalog[I].User = $E5 Then
        begin
          FillChar(Catalog[I], SizeOf(Catalog[I]), 0);
//          Catalog[I].User:=0;
          Catalog[I].Name:=LeftStr(ExtractFileName(FileName) + '        ', 8);
          Catalog[I].Ext:=Copy(ExtractFileExt(FileName) + '   ', 2, 3);
          Catalog[I].Exn:=Exn;
          Catalog[I].Recs:=0;
          Inc(Exn);
          Break;
        end;
        Inc(I);
      End;

 {
    While Frm_Vec[J]=1 do
      Inc(J);

    Catalog[I].Fat[FatRec]:=J;
    Frm_Vec[J]:=1;

    If FileSize >= SizeOf(Buf) Then
      BlockRead(F, Buf, SizeOf(Buf))
    else
      BlockRead(F, Buf, FileSize);

    Errc:=PMicroDOSDisk(MSTDisk)^.WriteBlock(J, @buf);

    If Errc <> 0 Then
    begin
    end;
}
    If FileSize >= SizeOf(Buf) Then
      BlockRead(F, Buf, SizeOf(Buf))
    else
      BlockRead(F, Buf, FileSize);

    Errc:=$FF;
    While Errc <> 0 do
    begin
      While (Frm_Vec[J] = 1) and (J < BlockCount) do
        Inc(J);
      If J < BlockCount Then
      Begin
        Catalog[I].Fat[FatRec]:=J;
        Frm_Vec[J]:=1;
        Errc:=PMicroDOSDisk(MSTDisk)^.WriteBlock(J, @buf);
      End
      else
      Begin
        MessageBox('Not enough free space for file: '#13 + FileName, nil, mfError or mfOKButton);
        Exit;
      End;
    end;

    Inc(FatRec);
    If FatRec = 8 Then
      FatRec:=0;

    If FileSize >= SizeOf(Buf) Then
      Inc(Catalog[I].Recs, $10)
    Else
      If FileSize mod $80 = 0 Then
        Inc(Catalog[I].Recs, (FileSize shr $7))
      Else
        Inc(Catalog[I].Recs, (FileSize shr $7) + 1);

    FileSize:=FileSize - SizeOf(Buf);
  end;
  System.Close(F);

  MSTDisk^.WriteDir(Catalog);
  Lb^.ReadDir;

end;
{---------------------------------------------------------}
Procedure TMSTShortWindow.CopyFile;
Var
  FileName:ShortString;
  P:PMSTSearchRec;
  W:Word;
  FileNames:Array[0..1] Of ShortString;
Const
  IllegalChars:set of char = ['*',':','?','<','>','|','"','/','\'];
begin

  P := PMSTSearchRec(@P);

  Lb^.GetData(P);

  FileName:=Trim(P^.FName) + '.' + Trim(P^.FExt);

  for w:=1 to Length(FileName) do
    if FileName[w] in IllegalChars Then FileName[w]:='_';
  FileNames[0]:=FileName;

  FileName:=GetTempFileName;
  FileNames[1]:=FileName;

  SaveFileAs(FileName);
  If SysUtils.FileExists(FileName) Then
  begin
//    Message(Application, evCommand, cmCopyFileMST, @FileNames);
    Message(Application, evBroadCast, cmCopyFileMST, @FileNames);
  end;

end;
{---------------------------------------------------------}
Function TMSTShortWindow.FileExists(FileName: ShortString; User: Byte):Boolean;
Var
  Catalog:TCatalog;
  I:Word;
begin
  MSTDisk^.ReadDir(Catalog);

  I:=0;

  While (I <= (SizeOf(TCatalog) div SizeOf(TEntry)) - 1) do
  begin

    Catalog[I].Ext[0]:=Char(Byte(Catalog[I].Ext[0]) And $7F);
    Catalog[I].Ext[1]:=Char(Byte(Catalog[I].Ext[1]) And $7F);
    Catalog[I].Ext[2]:=Char(Byte(Catalog[I].Ext[2]) And $7F);
    If (Catalog[I].User = User) and ((Trim(Catalog[I].Name) + '.' + Trim(Catalog[I].Ext)) = FileName) Then
    Begin
      FileExists:=True;
      Exit;
    End;

    I:=I+1;
  end;

  FileExists:=False;

End;
{---------------------------------------------------------}
{ TMSTFileCollection }
{$ifdef fpc}
function TCPMFileCollection.Compare(Key1, Key2: Pointer): LongInt;
{$else}
function TCPMFileCollection.Compare(Key1, Key2: Pointer): Integer;
{$endif}
begin
  if PMSTSearchRec(Key1)^.FExt > PMSTSearchRec(Key2)^.FExt Then Compare := 1
  else if PMSTSearchRec(Key2)^.FExt > PMSTSearchRec(Key1)^.FExt Then Compare := -1
  else if PMSTSearchRec(Key1)^.FName > PMSTSearchRec(Key2)^.FName then Compare := 1
  else if PMSTSearchRec(Key2)^.FName > PMSTSearchRec(Key1)^.FName then Compare := -1
  else If PMSTSearchRec(Key1)^.User > PMSTSearchRec(Key2)^.User Then Compare := 1
  else If PMSTSearchRec(Key2)^.User > PMSTSearchRec(Key1)^.User Then Compare := -1
  else Compare := 0;
end;

procedure TCPMFileCollection.FreeItem(Item: Pointer);
begin
  Dispose(PMSTSearchrec(Item));
end;

function TCPMFileCollection.GetItem(var S: TStream): Pointer;
var
  Item: PMSTSearchRec;
begin
  New(Item);
  S.Read(Item^, SizeOf(TMSTSearchRec));
  GetItem := Item;
end;

procedure TCPMFileCollection.PutItem(var S: TStream; Item: Pointer);
begin
  S.Write(Item^, SizeOf(TMSTSearchRec));
end;

{$ifdef fpc}
function TEntryCollection.Compare(Key1, Key2: Pointer): Sw_Integer;
{$else}
function TEntryCollection.Compare(Key1, Key2: Pointer): Integer;
{$endif}
begin
  if PEntry(Key1)^.Exn > PEntry(Key2)^.Exn Then
    Compare := 1
  Else
    If PEntry(Key1)^.Exn = PEntry(Key2)^.Exn Then
      Compare :=0
    Else
      Compare := -1;
end;


end.
