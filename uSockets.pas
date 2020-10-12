unit uSockets;

interface
uses windows, winsock;
function Connect(address : String;  port : Integer) : Integer;
procedure Disconnect(sock : TSocket);
function SendBuffer(sock : Integer; var buf; buflen : Integer) : Integer;
function SendString(sock : Integer; strBuffer : String) : Integer;
function ReceiveBuffer(sock : Integer; var buf; buflen : Integer) : Integer;
function ReceiveLength(sock : Integer) : Integer;
function Listen(Address : string; Port : Integer) : Integer;
function Accept(sock : Integer) : Integer;
implementation

function Connect(address : String;  port : Integer) : Integer;
var
  sinsock           : TSocket;
  SockAddrIn        : TSockAddrIn;
  hostent           : PHostEnt;
begin
  sinsock := Winsock.socket(PF_INET, SOCK_STREAM, IPPROTO_TCP);
  SockAddrIn.sin_family := AF_INET;
  SockAddrIn.sin_port := htons(Port);
  SockAddrIn.sin_addr.s_addr := inet_addr(pchar(address));
  if SockAddrIn.sin_addr.s_addr = INADDR_NONE then
  begin
    HostEnt := gethostbyname(pchar(Address));
    if HostEnt = nil then
    begin
      result := SOCKET_ERROR;
      Exit;
    end;
    SockAddrIn.sin_addr.s_addr := Longint(PLongint(HostEnt^.h_addr_list^)^);
  end;                           //CHANGE MADE
  if Winsock.Connect(sinSock, SockAddrIn, SizeOf(SockAddrIn)) = SOCKET_ERROR Then
    result := SOCKET_ERROR
  else
    result := sinsock;
end;
function SendBuffer(sock : Integer; var buf; buflen : Integer) : Integer;
begin
  Result := send(sock, Buf, Buflen, 0);
end;
function SendString(sock : Integer; strBuffer : String) : Integer;
begin
  result := SendBuffer(sock, pointer(strBuffer)^, Length(strBuffer));
end;
function ReceiveBuffer(sock : Integer; var buf; buflen : Integer) : Integer;
begin
  Result := recv(sock, buf, buflen, 0);
end;
procedure Disconnect(sock : TSocket);
begin
  closesocket(sock);
end;
function ReceiveLength(sock : Integer) : Integer;
begin
  if ioctlsocket(sock, FIONREAD, Longint(Result)) <> 0 Then begin
    result := SOCKET_ERROR;
  end;
end;
function Listen(Address : string; Port : Integer) : Integer;
var
  sinsock           : TSocket;
  SockAddrIn        : TSockAddrIn;
  hostent           : PHostEnt;
begin
  sinsock := Winsock.socket(AF_INET, SOCK_STREAM, IPPROTO_TCP);
  SockAddrIn.sin_family := AF_INET;
  SockAddrIn.sin_port := htons(Port);
  SockAddrIn.sin_addr.s_addr := inet_addr(pchar(address));
  if SockAddrIn.sin_addr.s_addr = INADDR_NONE then
  begin
    HostEnt := gethostbyname(pchar(Address));
    if HostEnt = nil then
    begin
      result := SOCKET_ERROR;
      Exit;
    end;
    SockAddrIn.sin_addr.s_addr := Longint(PLongint(HostEnt^.h_addr_list^)^);
  end;                           //CHANGE MADE
  //if Winsock.Connect(sinSock, SockAddrIn, SizeOf(SockAddrIn)) = SOCKET_ERROR Then
  if winsock.bind(sinsock, SockAddrIn, SizeOf(SockAddrIn)) <> 0 then begin
    result := socket_error;
    exit;
  end;
  if winsock.listen(sinsock, SOMAXCONN ) <> 0 Then
    result := SOCKET_ERROR
  else
    result := sinsock;
end;
function Accept(sock : Integer) : Integer;
var
  addr : sockaddr_in;
  Len : Integer;
begin
  len := SizeOf(sockaddr_in);
  result := winsock.accept(sock, @addr, @len);
end;
end.
