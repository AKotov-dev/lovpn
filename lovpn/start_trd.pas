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
    ExProcess.Options := [poUsePipes, poStderrToOutPut];
    ExProcess.Parameters.Add('-c');

    ExProcess.Parameters.Add(
      //source_1
      'rm -f ./*; > ./start; sleep 1; if [[ $(curl --connect-timeout 3 -s ' +
      '$(echo "aHR0cHM6Ly9pcHNwZWVkLmluZm8vZnJlZXZwbl9vcGVudnBuLnBocD9sYW5ndWFnZT1lbg==" | base64 -d)) ]]; then '
      + ' s=$(curl -s $(echo "aHR0cHM6Ly9pcHNwZWVkLmluZm8vZnJlZXZwbl9vcGVudnBuLnBocD9sYW5ndWFnZT1lbg==" | '
      + 'base64 -d) | grep href= | cut -d"\"" -f6 | grep "^/"); for i in ${s[@]}; do [ ! -f ./start ] '
      + '&& break || curl -O $(echo "aHR0cHM6Ly9pcHNwZWVkLmluZm8=" | base64 -d)$i; done; '
      + '[[ $(find . -name "*.ovpn") ]] || exit 0; for f in ./*.ovpn; do sed -i "/Downloaded\|^$/d" $f; done; '
      + 'for f in ./*.ovpn; do sed -i $"s/[^[:print:]\t]//g" $f; done; fi; echo ""; [ ! -f ./start ] && exit 0; '
      //source_2
      + 'u0=$(echo "aHR0cDovL3d3dy52cG5nYXRlLm5ldC9hcGkvaXBob25lLw==" | base64 -d); '
      + 'u1=$(echo "aHR0cDovLzIwMi41LjIyMS42Njo2MDI3OS9hcGkvaXBob25lLw==" | base64 -d); '
      + 'u2=$(echo "aHR0cDovLzIwMi41LjIyMS4xMDY6NTk3MTAvYXBpL2lwaG9uZS8=" | base64 -d); '
      + 'u3=$(echo "aHR0cDovLzE1MC45NS4yOS4zMDoyMzM1Ny9hcGkvaXBob25lLw==" | base64 -d); '
      + 'u4=$(echo "aHR0cDovLzIxOC4xNTcuMjI2LjE2NDoyMDA2MC9hcGkvaXBob25lLw==" | base64 -d); '
      + 'u5=$(echo "aHR0cDovLzEwOS4xMTEuMjQzLjIwNjoxNzU3OS9hcGkvaXBob25lLw==" | base64 -d); '
      + 'u6=$(echo "aHR0cDovLzEwMy4yMDEuMTI5LjIyNjoxNDY4NC9hcGkvaXBob25lLw==" | base64 -d); '
      + 'u7=$(echo "aHR0cHM6Ly9kb3dubG9hZC52cG5nYXRlLmpwL2FwaS9pcGhvbmUv" | base64 -d); '
      + 'for i in $u0 $u1 $u2 $u3 $u4 $u5 $u6 $u7; do echo "' +
      SAdditionalSearch + '"; ' +
      'if [ -f ./start ] && [[ $(curl --connect-timeout 3 -s $i) ]]; then curl $i | cut -f15 -d"," | tail -n+3 | '
      + 'base64 -di | col -b | sed "/^#\|^$/d" > ./ovpn.list; break; fi; [ ! -f ./start ] && exit 0; '
      + 'done; c=0; while read i; do if [ "$i" != "</key>" ]; then echo $i >> ./config_$c.ovpn; else echo "</key>" >> '
      + './config_$c.ovpn; c=$(expr $c + 1); fi; done < ./ovpn.list; rm -f ./{start,ovpn.list}; exit 0');

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
