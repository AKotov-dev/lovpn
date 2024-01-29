unit start_trd;

{$mode objfpc}{$H+}

interface

uses
  Classes, Process, SysUtils, ComCtrls, Forms;

type
  StartDownload = class(TThread)
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

procedure StartDownload.Execute;
var
  ExProcess: TProcess;
begin
  try //Вывод лога и прогресса
    Synchronize(@StartProgress);

    FreeOnTerminate := True; //Уничтожить по завершении
    Result := TStringList.Create;

    ExProcess := TProcess.Create(nil);

    ExProcess.Executable := 'bash';
    ExProcess.Options := [poUsePipes, poStderrToOutPut];
    ExProcess.Parameters.Add('-c');

    ExProcess.Parameters.Add(
      //stage1
      'rm -f ./*.ovpn; > ./start; sleep 1; if [[ $(curl --max-time 60 -s ' +
      '$(echo "aHR0cHM6Ly9pcHNwZWVkLmluZm8vZnJlZXZwbl9vcGVudnBuLnBocD9sYW5ndWFnZT1lbg==" | base64 -di)) ]]; then '
      + ' s=$(curl -s $(echo "aHR0cHM6Ly9pcHNwZWVkLmluZm8vZnJlZXZwbl9vcGVudnBuLnBocD9sYW5ndWFnZT1lbg==" | '
      + 'base64 -di) | grep href= | cut -d"\"" -f6 | grep "^/"); for i in ${s[@]}; do [ ! -f ./start ] '
      + '&& break || curl -O $(echo "aHR0cHM6Ly9pcHNwZWVkLmluZm8=" | base64 -d)$i; done; '
      + 'if [[ $(find . -name "*.ovpn") ]]; then for f in ./*.ovpn; do sed -i "/Downloaded\|^$/d" $f; done; '
      + 'for f in ./*.ovpn; do sed -i $"s/[^[:print:]\t]//g" $f; done; fi; echo ""; [ ! -f ./start ] && exit 0; fi;'

      //stage2_(2)
      + 'u0=$(echo "aHR0cDovL3d3dy52cG5nYXRlLm5ldC9hcGkvaXBob25lLw==" | base64 -di); '
      + 'u1=$(echo "aHR0cHM6Ly9kb3dubG9hZC52cG5nYXRlLmpwL2FwaS9pcGhvbmUv" | base64 -di); '
      + 'for u in $u0 $u1; do '
//      + 'if [[ $(find . -name "*.ovpn") ]]; then rm -f ./start; exit 0; fi; '
      + 'echo -e "\n' + SAdditionalSearch + '"; '
      + 'if [ -f ./start ] && [[ $(curl --max-time 10 -s $u) ]]; then '
      + 'array=$(curl $u | awk -F ' + '''' + ',' + '''' + ' ' + '''' + '{print $NF}' + '''' + ' | grep IyM); '
      + 'for i in $array; do '
      + 'c=$(expr $c + 1); '
      + 'echo $i | base64 -di > ./stage2_config_$c.ovpn; '
      + 'done; '
      + 'fi; '
      + 'done; '

      //stage3_advanced (duplicates stage_2_(2) if it is not available)
//      + 'if [[ $(find . -name "*.ovpn") ]]; then rm -f ./start; exit 0; fi; '
      + 'echo -e "\n' + SAdvancedSearch + '"; ' +
      'advanced=$(echo aHR0cHM6Ly9yYXcuZ2l0aHVidXNlcmNvbnRlbnQuY29tL2ZkY2lhYmR1bC9WcG5nYXRlLVN'
      + 'jcmFwZXItQVBJL21haW4vanNvbi9kYXRhLmpzb24= | base64 -di); ' +
      'if [ -f ./start ] && [[ $(curl -m 10 -s $advanced) ]]; then ' +
      'array=$(curl $advanced | grep openvpn_configdata_base64 | cut -f2 -d":"); ' +
      'for i in $array; do c=$(expr $c + 1); echo $i | sed ' + '''' +
      's/\\r//' + '''' + ' | base64 -di | col -b > advanced_$c.ovpn; done; fi; ' +
      'rm -f ./start; exit 0');

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
procedure StartDownload.StartProgress;
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
procedure StartDownload.StopProgress;
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
procedure StartDownload.ShowLog;
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
