{************************************************}
{                                                }
{  Copyright (C) MarinovSoft 2013-2014           }
{                                                }
{  http://marinovsoft.narod.ru                   }
{  mailto:super386@rambler.ru                    }
{                                                }
{************************************************}
Unit FileView;

Interface

Uses Views, Objects;

Type
  PMSTSCroller = ^TMSTSCroller;
  TMSTSCroller = object (TScroller)
    Lines:Pcollection;
    constructor Init(R:TRect;SX,SY:PScrollbar);
    procedure Draw;Virtual;
  end;

Implementation

Uses Drivers;

{---------------------------------------------------------}
constructor TMSTSCroller.Init(R:TRect;SX,SY:PScrollbar);
begin
  Inherited Init(R,SX,SY);
  GrowMode:=gfGrowHiX+gfGrowHiY;
  SetLimit(128,Lines^.Count-1);
end;
{---------------------------------------------------------}
procedure TMSTSCroller.Draw;
var
  Y:Integer;
  B:TDrawBuffer;
  S:String;
begin
  for Y:=0 to pred(Size.Y) do
    begin
      MoveChar(B,' ',GetColor(1),Size.X);
      if (Y+Delta.Y<Lines^.Count) and
         (Lines^.At(Y+Delta.Y)<> NIL) then
        begin
          s:=PString(Lines^.At(Y+Delta.Y))^;
          MoveStr(B,copy(s,Delta.X+1,Length(s)-
            Delta.X),GetColor(1))
        end;
      WriteLine(0,Y,Size.X,1,B)
    end
end;
{---------------------------------------------------------}
end.
