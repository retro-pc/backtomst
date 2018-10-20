unit DrvSel;

interface

Uses {$ifdef win32} Windows, {$endif} Objects, Dialogs, Drivers, Views, StdDlg;

Type
  PDriveSelectDialog = ^TDriveSelectDialog;
  TDriveSelectDialog = Object(TDialog)
  {$ifdef fpc}
  protected
  {$endif}
    CurrentDrive:Char;
    Lb:PListBox;
  public
    {$ifdef fpc}
    Constructor Init(_CurrentDrive:Char);
    {$endif}
    Constructor Init(R:TRect; _CurrentDrive:Char);
    Destructor Done;Virtual;
    Procedure HandleEvent(Var Event:TEvent);Virtual;
    Function GetPalette: PPalette; virtual;
    Procedure SelectDrive(Var Event:TEvent);Virtual;
    Function GetDrive:Char;virtual;
  End;

Type
  PDriveListBox = ^TDriveListBox;
  TDriveListBox = Object(TListBox)
    Function GetPalette: PPalette; virtual;
  End;

implementation

Uses App, MSTConst;

type
  TDriveSet   = Set of 'A'..'Z';

procedure GetValidDrives( var Drives : TDriveSet);
var
  _Drives:Set Of 0..31;
  DrivesWord : Longint absolute _Drives;
  Ch:Char;
begin
  {$ifdef win32}
  DrivesWord := GetlogicalDrives;
  For Ch:='A' to 'Z' do
    If Byte(Ch) - Byte('A') in _Drives
      Then Include(Drives, Ch);
  {$endif}
end;

Function TDriveListBox.GetPalette: PPalette;
{
                   1    2    3    4    5
                ÉÍÍÍÍÑÍÍÍÍÑÍÍÍÍÑÍÍÍÍÑÍÍÍÍ»
  CListViewer   º 26 ³ 26 ³ 27 ³ 28 ³ 29 º
                ÈÍÍÑÍÏÍÍÑÍÏÍÍÑÍÏÍÍÑÍÏÍÍÑÍ¼
  ActiveÄÄÄÄÄÄÄÄÄÄÄÙ    ³    ³    ³    ÀÄÄÄDivider
  InactiveÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ    ³    ÀÄÄÄÄÄÄÄÄSelected
  FocusedÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
}
Const
  P:String[Length(CListViewer)] = #1#2#5#6#2;
Begin
  GetPalette := @P;
End;

Constructor TDriveSelectDialog.Init(R:TRect; _CurrentDrive:Char);
Var
{$ifdef fpc}
  S:ShortString;
  P:PShortString;
{$else}
  S:String;
  P:PString;
{$endif}
  DriveSet:TDriveSet;
  Ch:Char;
  DriveCollection:PStringCollection;
  B:Byte;

Begin

  DriveSet:=[];
  GetValidDrives(DriveSet);
  DriveCollection:=New(PStringCollection, Init(1, 1));
  For Ch:='A' To 'Z' Do
    If Ch in DriveSet Then
    Begin
      DriveCollection^.Insert(NewStr(Ch));
    End;

  GrowMode:=0;
  Inherited Init(R,'Drive');

  CurrentDrive:=_CurrentDrive;

  GetClipRect(R);
  R.Grow(-1,-1);
  State:=State XOr sfShadow;

  Lb:=New(PDriveListBox,Init(R, 1, Nil));
  Insert(Lb);
  Lb^.Newlist(DriveCollection);

  {$ifdef fpc}
  P:=PShortString(@P);
  {$else}
  P:=PString(@P);
  {$endif}

  If Lb^.List^.Count > 0 Then
    For B:=0 To Lb^.List^.Count - 1 do
    Begin
      P:=Lb^.List^.At(B);
      If P^ = CurrentDrive Then
        Lb^.FocusItem(B);
    End;

End;

{$ifdef fpc}
Constructor TDriveSelectDialog.Init(_CurrentDrive:Char);
Var
  R:TRect;
Begin
  R.Assign(5, 8, 25, 15);
  Init(R, _CurrentDrive);
End;
{$endif}

Destructor TDriveSelectDialog.Done;
Begin
  Dispose(Lb^.List, Done);
  Dispose(Lb,Done);
  Inherited Done;
End;

Procedure TDriveSelectDialog.HandleEvent(Var Event:TEvent);
Begin
  Case Event.What Of
    evKeyDown:
    Case Event.Keycode Of
      kbEsc:
      Begin
        Event.What:=evCommand;
        Event.Command:=cmClose;
        Putevent(Event);
        ClearEvent(Event);
      End;
      kbEnter:SelectDrive(Event);
    End;
    evMouseDown:
      If MouseInView(MouseWhere) and Event.Double Then
        SelectDrive(Event);
  End;
  Inherited HandleEvent(Event);
End;

Procedure TDriveSelectDialog.SelectDrive(Var Event:TEvent);
Var
{$ifdef fpc}
  A:ShortString;
{$else}
  A:String;
{$endif}
Begin
  A:=Lb^.GetText(Lb^.Focused, 1);
  CurrentDrive:=A[1];
  Event.What:=evCommand;
  Event.Command:=cmOk;
  Putevent(Event);
  ClearEvent(Event);
End;

Function TDriveSelectDialog.GetPalette:PPalette;
Const
  P:String[Length(CBlueWindow)] = #16#17#18#19#0#21#22#23;
Begin
  GetPalette := @P;
End;

Function TDriveSelectDialog.GetDrive:Char;
Begin
  GetDrive:=CurrentDrive;
End;

end.
