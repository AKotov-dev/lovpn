unit Unit1;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, Buttons,
  StdCtrls, ComCtrls, IniPropStorage, Process, DefaultTranslator, ExtCtrls;

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
    Timer1: TTimer;
    procedure DirBtnClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure StartBtnClick(Sender: TObject);
    procedure KillAll;
    procedure StopBtnClick(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);

  private

  public

  end;

resourcestring
  SDirectoryNotExists = 'Download directory not found!';
  SLoadingConfig = 'Loading *.ovpn configurations. Please, wait (~30-60 sec)...';
  SAdditionalSearch = 'Search for additional sources, wait...';
  SDownloadCompleted = 'Download completed';
  SDownloaded = 'Downloaded:';

var
  MainForm: TMainForm;

implementation

uses start_trd;

{$R *.lfm}

{ TMainForm }

//Количество файлов в папке загрузки
function GetFileCount(Directory: string): integer;
var
  fs: TSearchRec;
begin
  try
    Result := 0;
    if FindFirst(Directory + '/*.ovpn', faAnyFile, fs) = 0 then
      repeat
        Inc(Result);
      until FindNext(fs) <> 0;
  finally
    SysUtils.FindClose(fs);
  end;
end;

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
    ExProcess.Parameters.Add('killall curl; rm -f ./{start,ovpn.list}; killall curl');
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

//Количество загруженных конфигураций
procedure TMainForm.Timer1Timer(Sender: TObject);
var
  s: string = '0';
begin
  if DirectoryExists(Edit1.Text) then
    s := IntToStr(GetFileCount(Edit1.Text));

  MainForm.Caption := Concat(Application.Title, ' [', SDownloaded, ' ', s, ']');
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
  FStartLoad := StartDownload.Create(False);
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
