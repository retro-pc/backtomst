{************************************************}
{                                                }
{ Copyright (C) 2013-2018 MarinovSoft            }
{                                                }
{************************************************}
{*$X+,G+,D-,L-,S-,R-}

{$ifdef fpc}
{$A1}
{$endif}

unit AppWinEx;

interface

Uses Objects, GrowView, Dialogs, Views, Drivers, Service, App, AppWin;

Type

  PDiskProgressDialog = ^TDiskProgressDialog;
  TDiskProgressDialog = Object(TProgressDialog)
    constructor Init(var GV1: PGrowView; ATitle : String);
  end;

implementation

constructor TDiskProgressDialog.Init(var GV1: PGrowView; ATitle : String);
var
  R       : TRect;
  B       : PButton;
  T       : PStaticText;
begin
{  R.Assign( 0, 0, 40, 11 );}
  R.Assign( 0, 0, 44, 15 );
  TDialog.Init( R, ATitle );
  Options := Options or ofCentered;

  R.Assign(2,2,42,3);
  New(T, Init(R, #3'Current operation progress'));
  Insert(T);
  CurrentText := T;

  R.Assign( 2, 4, 38, 10 );
  If Not Assigned(GV1) Then
     GV1 := New( PGrowView, Init( R, 100 ));
  Insert( GV1 );

  R.Assign(0, 12, 12, 14);
  New(B, Init(R, '~C~ancel', cmCancel, 1));
  B^.Options := B^.Options or ofCenterX;
  Insert(B);

end;

end.
