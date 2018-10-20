Unit Mst_Ext;
interface
Procedure SetLastOSError(ErrorCode:Integer);
implementation
uses windows;

Procedure SetLastOSError(ErrorCode:Integer);inline;

begin
  SetLastError(ErrorCode);
end;

end.
