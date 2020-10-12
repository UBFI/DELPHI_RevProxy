unit uSlaveFuncs;

interface
uses Windows, winsock;
function GetComputerName: string;
function GetUserName: string;

implementation
function GetComputerName : String;
var
  buffer : array[0..MAX_PATH] of Char;
  Size: DWORD;
begin
  Size := sizeof(buffer);
  windows.GetComputerName(buffer, Size);
  SetString(result, buffer, lstrlen(buffer));
end;

function GetUserName: string;
var
  buffer : array[0..MAX_PATH] of Char;
  Size: DWORD;
begin
  Size := sizeof(buffer);
  windows.GetUserName(buffer, Size);
  SetString(result, buffer, lstrlen(buffer));
end;
end.
