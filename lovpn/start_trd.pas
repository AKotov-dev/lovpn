unit start_trd;

{$mode objfpc}{$H+}

interface

uses
  Classes, Process, SysUtils, ComCtrls, Forms;

type
  StartRestore = class(TThread)
  private

    { Private declarations }
  protected
  var
    Result: TStringList;

    procedure Execute; override;

    procedure ShowLog;
    procedure StartProgress;
    procedure StopProgress;

  end;

implementation

uses Unit1;

{ TRD }

procedure StartRestore.Execute;
var
  ExProcess: TProcess;
begin
  try //Вывод лога и прогресса
    Synchronize(@StartProgress);

    FreeOnTerminate := True; //Уничтожить по завершении
    Result := TStringList.Create;

    ExProcess := TProcess.Create(nil);

    ExProcess.Executable := 'bash';
    ExProcess.Parameters.Add('-c');

    ExProcess.Parameters.Add(
      '> ./start; s=$(curl -s $(echo "aHR0cHM6Ly9pcHNwZWVkLmluZm8vZnJlZXZwbl9vcGVudnBuLnBocD9sYW5ndWFnZT1lbg==" | '
      + 'base64 -d) | grep href= | cut -d"\"" -f6 | grep "^/"); rm -f ./*.ovpn; for i in ${s[@]}; do [ ! -f start ] '
      + '&& break || curl -O $(echo "aHR0cHM6Ly9pcHNwZWVkLmluZm8=" | base64 -d)$i; done');

    ExProcess.Options := [poUsePipes, poStderrToOutPut];

    ExProcess.Execute;

    //Выводим лог динамически
    while ExProcess.Running do
    begin
      Result.LoadFromStream(ExProcess.Output);

      if Result.Count <> 0 then
        Synchronize(@ShowLog);
    end;

  finally
    Synchronize(@StopProgress);
    Result.Free;
    ExProcess.Free;
    Terminate;
  end;
end;

{ БЛОК ОТОБРАЖЕНИЯ ЛОГА }

//Старт
procedure StartRestore.StartProgress;
begin
  with MainForm do
  begin
    LogMemo.Clear;
    LogMemo.Lines.Add(SLoadingConfig);
    Application.ProcessMessages;
    ProgressBar1.Style := pbstMarquee;
    ProgressBar1.Refresh;
    DirBtn.Enabled := False;
    StartBtn.Enabled := False;
  end;
end;

//Стоп
procedure StartRestore.StopProgress;
begin
  with MainForm do
  begin
    LogMemo.Lines.Append('');
    LogMemo.Lines.Append(SDownloadCompleted);
    Application.ProcessMessages;
    ProgressBar1.Style := pbstNormal;
    ProgressBar1.Refresh;
    DirBtn.Enabled := True;
    StartBtn.Enabled := True;
  end;
end;

//Вывод лога
procedure StartRestore.ShowLog;
var
  i: integer;
begin
  //Вывод построчно
  for i := 0 to Result.Count - 1 do
    MainForm.LogMemo.Lines.Append(Result[i]);

  //Промотать список вниз
  MainForm.LogMemo.SelStart := Length(MainForm.LogMemo.Text);
  MainForm.LogMemo.SelLength := 0;

  //Вывод пачками
  //MainForm.LogMemo.Lines.Assign(Result);
end;

end.
