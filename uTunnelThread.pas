{
  Delphi Thread Unit by Aphex
  http://iamaphex.cjb.net
  unremote@knology.net
}

unit uTunnelThread;

interface

uses Windows;

type
  TTunnelThread = class;

  TThreadProcedure = procedure(Thread: TTunnelThread);

  TSynchronizeProcedure = procedure;

  TTunnelThread = class
  private
    FThreadHandle: longword;
    FThreadID: longword;
    FExitCode: longword;
    FTerminated: boolean;
    FExecute: TThreadProcedure;
    FData: pointer;
  protected
  public
    FTarget : String;
    FTargetPort : Integer;
    FSockTunnel : Integer;
    constructor Create(ThreadProcedure: TThreadProcedure; CreationFlags: Cardinal; target : String; targetport, socktunnel : Integer);
    destructor Destroy; override;
    procedure Synchronize(Synchronize: TSynchronizeProcedure);
    procedure Lock;
    procedure Unlock;
    property Terminated: boolean read FTerminated;
    property ThreadHandle: longword read FThreadHandle;
    property ThreadID: longword read FThreadID;
    property ExitCode: longword read FExitCode;
    property Data: pointer read FData write FData;
  end;

implementation

var
  ThreadLock: TRTLCriticalSection;

procedure ThreadWrapper(Thread: TTunnelThread);
var
  ExitCode: dword;
begin
  Thread.FTerminated := False;
  try
    Thread.FExecute(Thread);
  finally
    GetExitCodeThread(Thread.FThreadHandle, ExitCode);
    Thread.FExitCode := ExitCode;
    Thread.FTerminated := True;
    ExitThread(ExitCode);
  end;
end;

constructor TTunnelThread.Create(ThreadProcedure: TThreadProcedure; CreationFlags: Cardinal; target : String; targetport, socktunnel : Integer);
begin
  inherited Create;
  FTarget := target;
  FTargetport := targetport;
  FSockTunnel := socktunnel;
  FExitCode := 0;
  FExecute := ThreadProcedure;
  FThreadHandle := BeginThread(nil, 0, @ThreadWrapper, Pointer(Self), CreationFlags, FThreadID);
end;

destructor TTunnelThread.Destroy;
begin
  inherited;
  CloseHandle(FThreadHandle);
end;

procedure TTunnelThread.Synchronize(Synchronize: TSynchronizeProcedure);
begin
  EnterCriticalSection(ThreadLock);
  try
    Synchronize;
  finally
    LeaveCriticalSection(ThreadLock);
  end;
end;

procedure TTunnelThread.Lock;
begin
  EnterCriticalSection(ThreadLock);
end;

procedure TTunnelThread.Unlock;
begin
  LeaveCriticalSection(ThreadLock);
end;

initialization
  InitializeCriticalSection(ThreadLock);

finalization
  DeleteCriticalSection(ThreadLock);

end.
