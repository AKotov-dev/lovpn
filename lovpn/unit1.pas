unit Unit1;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, Buttons,
  StdCtrls, ComCtrls, IniPropStorage, Process, DefaultTranslator;

type

  { TMainForm }

  TMainForm = class(TForm)
    Edit1: TEdit;
    IniPropStorage1: TIniPropStorage;
    LogMemo: TMemo;
    ProgressBar1: TProgressBar;
    DirBtn: TSpeedButton;
    SelectDirectoryDialog1: TSelectDirectoryDialog;
    StartBtn: TSpeedButton;
    StaticText1: TStaticText;
    StopBtn: TSpeedButton;
    procedure DirBtnClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure StartBtnClick(Sender: TObject);
    procedure KillAll;
    procedure StopBtnClick(Sender: TObject);

  private

  public

  end;

resourcestring
  SDirectoryNotExists = 'Download directory not found!';
  SLoadingConfig = 'Loading *.ovpn configurations. Please, wait (~30-60 sec)...';
  SDownloadCompleted = 'Download completed';


var
  MainForm: TMainForm;

implementation

uses start_trd;

{$R *.lfm}

{ TMainForm }

//Экстренный останов
procedure TMainForm.KillAll;
var
  ExProcess: TProcess;
begin
  Application.ProcessMessages;
  ExProcess := TProcess.Create(nil);
  try
    ExProcess.Executable := 'bash';
    ExProcess.Parameters.Add('-c');
    ExProcess.Parameters.Add('rm -f ./{start,ovpn.list}; killall curl');
    //  ExProcess.Options := ExProcess.Options + [poWaitOnExit];
    ExProcess.Execute;
  finally
    ExProcess.Free;
  end;
end;

//Останов
procedure TMainForm.StopBtnClick(Sender: TObject);
begin
  KillAll;
end;

//Старт
procedure TMainForm.StartBtnClick(Sender: TObject);
var
  FStartLoad: TThread;
begin
  if not DirectoryExists(Edit1.Text) then
  begin
    MessageDlg(SDirectoryNotExists, mtWarning, [mbOK], 0);
    Exit;
  end;

  //Устанавливаем рабочую директорию
  SetCurrentDir(Edit1.Text);

  //Запускаем скачивание
  FStartLoad := StartRestore.Create(False);
  FStartLoad.Priority := tpHighest;
end;

procedure TMainForm.FormCreate(Sender: TObject);
begin
  MainForm.Caption := Application.Title;
  DirBtn.Width := DirBtn.Height;

  IniPropStorage1.IniFileName := GetUserDir + '.config/lovpn.conf';
end;

//Для Plasma
procedure TMainForm.FormShow(Sender: TObject);
begin
  IniPropStorage1.Restore;
end;

//Завершение при закрытии
procedure TMainForm.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
  KillAll;
end;

//Выбор директории
procedure TMainForm.DirBtnClick(Sender: TObject);
begin
  if SelectDirectoryDialog1.Execute then
    Edit1.Text := SelectDirectoryDialog1.FileName;
end;

end.
