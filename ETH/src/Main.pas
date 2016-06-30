﻿unit Main;

interface

uses Vcl.Samples.Spin, Vcl.ImgList, Vcl.Controls, Vcl.StdCtrls, Vcl.Dialogs,
  Vcl.ExtCtrls, Vcl.ComCtrls, System.Classes, Forms, Types, Winapi.Messages,
  System.Generics.Collections, Graphics,
  //
  AGTHServer,
  jsCore,
  jsHighlighter,
  Translator;

type
  TMainForm = class(TForm)
    OSDTimer: TTimer;
    FontDialog: TFontDialog;
    PageControl: TPageControl;
    TabOSD: TTabSheet;
    TabAGTH: TTabSheet;
    Memo: TMemo;
    TabText: TTabSheet;
    AGTHMemo: TMemo;
    cbStreams: TComboBox;
    GroupBox2: TGroupBox;
    cbProcess: TComboBox;
    Label7: TLabel;
    edHCode: TEdit;
    Label8: TLabel;
    btnHook: TButton;
    ProcIcon: TImageList;
    Images: TImageList;
    TabTranslate: TTabSheet;
    GroupBox1: TGroupBox;
    Label1: TLabel;
    DoTranslate: TCheckBox;
    SrcLang: TComboBox;
    DestLang: TComboBox;
    GroupBox3: TGroupBox;
    rbClipboard: TRadioButton;
    rbText: TRadioButton;
    cbEnableOSD: TCheckBox;
    GroupBox4: TGroupBox;
    tbX: TTrackBar;
    Label2: TLabel;
    Label9: TLabel;
    Label10: TLabel;
    Label11: TLabel;
    tbY: TTrackBar;
    tbWidth: TTrackBar;
    tbHeight: TTrackBar;
    seDelay: TSpinEdit;
    Label12: TLabel;
    Label13: TLabel;
    Font: TGroupBox;
    btnOsdFontSelect: TButton;
    Label14: TLabel;
    Label15: TLabel;
    imgTextColor: TImage;
    imgOutlineColor: TImage;
    ColorDialog1: TColorDialog;
    tbOutline: TTrackBar;
    Label16: TLabel;
    TabJs_preProcess: TTabSheet;
    Panel1: TPanel;
    btnScriptLoad: TButton;
    OpenDialog: TOpenDialog;
    chbTextProcessor: TCheckBox;
    ScriptArea: TRichEdit;
    mScriptPath: TMemo;
    Panel2: TPanel;
    FontSet: TButton;
    ClipboardCopy: TCheckBox;
    Label3: TLabel;
    Label4: TLabel;
    cbSticky: TCheckBox;
    rbSpyWindow: TRadioButton;
    imgSelectWindow: TImage;
    CrossIcon: TImageList;
    procedure OSDTimerTimer(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormCreate(Sender: TObject);
    procedure FontSetClick(Sender: TObject);
    procedure cbStreamsChange(Sender: TObject);
    procedure cbEnableOSDClick(Sender: TObject);
    procedure cbProcessDropDown(Sender: TObject);
    procedure cbProcessDrawItem(Control: TWinControl; Index: Integer;
      Rect: TRect; State: TOwnerDrawState);
    procedure btnHookClick(Sender: TObject);
    procedure OSDPosChange(Sender: TObject);
    procedure seDelayChange(Sender: TObject);
    procedure btnOsdFontSelectClick(Sender: TObject);
    procedure imgTextColorClick(Sender: TObject);
    procedure imgOutlineColorClick(Sender: TObject);
    procedure tbOutlineChange(Sender: TObject);
    procedure btnScriptLoadClick(Sender: TObject);
    procedure cbStickyClick(Sender: TObject);
    procedure cbProcessChange(Sender: TObject);
    procedure OnLangSelect(Sender: TObject);
    procedure rbSpyWindowChange(Sender: TObject);
    procedure imgSelectWindowMouseMove(Sender: TObject; Shift: TShiftState;
      X, Y: Integer);
    procedure imgSelectWindowMouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
  private
    procedure OnNewStream(lines: TStrings);
    procedure OnNewText(Text: widestring);

    procedure SaveSettings;
    procedure LoadSettings;
    procedure UpdateColorBoxes;

    procedure LoadScript(path: string);
    function GetSpyWindowText(Hwnd: THandle): string;
  private
    agserv: TAGTHServer;
    jstp: JavaScriptTextProcessor;
    trans: TTranslator;
    SpyWindowHwnd: THandle;
    IsSpyWindowSearch: boolean;
  protected
    procedure WMSyscommand(var Message: TWmSysCommand); message WM_SYSCOMMAND;
  end;

const
  crCustomCrossHair = 1;

var
  MainForm: TMainForm;

implementation

uses psapi, shellapi, CLIPBRD, SysUtils, Windows,
  System.UITypes,
  //
  OSD,
  Inject,
  GoogleTranslate,
  YandexTranslate,
  uSettings;

{$R *.dfm}

procedure TMainForm.WMSyscommand(var Message: TWmSysCommand);
begin
  case (message.CmdType and $FFF0) of
    SC_MINIMIZE:
      begin
        ShowWindow(Handle, SW_MINIMIZE);
        message.Result := 0;
      end;
    SC_RESTORE:
      begin
        ShowWindow(Handle, SW_RESTORE);
        message.Result := 0;
      end;
  else
    inherited;
  end;
end;

procedure TMainForm.SaveSettings;
var
  Settings: TSettingsFile;
begin
  Settings := TSettingsFile.Create('Config', 'Easy Text Hooker', True);
  try
    Settings.WriteBool('Main', 'ClipboardCopy', ClipboardCopy.checked);
    Settings.WriteInteger('Main', 'CurrentTab', PageControl.TabIndex);

    Settings.BeginSection('TextareaFont');
    Settings.WriteString('Name', Memo.Font.Name);
    Settings.WriteInteger('CharSet', Memo.Font.CharSet);
    Settings.WriteString('Color', inttohex(Memo.Font.Color, 8));
    Settings.WriteInteger('Size', Memo.Font.Size);
    Settings.WriteInteger('Style', Byte(Memo.Font.Style));
    Settings.EndSection;

    Settings.BeginSection('Translate');
    Settings.WriteBool('DoTranslate', DoTranslate.checked);
    Settings.WriteString('SrcLang', SrcLang.Text);
    Settings.WriteString('DestLang', DestLang.Text);
    Settings.EndSection;

    Settings.BeginSection('OSD');
    Settings.WriteBool('EnableOSD', cbEnableOSD.checked);
    Settings.WriteBool('FromClipboard', rbClipboard.checked);
    Settings.WriteBool('FromTextarea', rbText.checked);
    Settings.WriteBool('FromSpyWindow', rbSpyWindow.checked);
    Settings.WriteInteger('PositionX', tbX.Position);
    Settings.WriteInteger('PositionY', tbY.Position);
    Settings.WriteInteger('PositionWidth', tbWidth.Position);
    Settings.WriteInteger('PositionHeight', tbHeight.Position);
    Settings.WriteString('FontName', OSDForm.TextFont.Name);
    Settings.WriteInteger('FontCharSet', OSDForm.TextFont.CharSet);
    Settings.WriteInteger('FontSize', OSDForm.TextFont.Size);
    Settings.WriteInteger('FontStyle', Byte(OSDForm.TextFont.Style));
    Settings.WriteString('FontColor', inttohex(OSDForm.TextColor, 8));
    Settings.WriteString('OutlineColor', inttohex(OSDForm.OutlineColor, 8));
    Settings.WriteInteger('OutlineWidth', OSDForm.OutlineWidth);
    Settings.WriteBool('Sticky', cbSticky.checked);
    Settings.EndSection;

    Settings.BeginSection('AGTH');
    Settings.WriteString('HCode', edHCode.Text);
    Settings.WriteInteger('CopyDelay', seDelay.Value);
    Settings.EndSection;

    Settings.BeginSection('jstp');
    Settings.WriteString('ScriptPath', jstp.ScriptPath);
    Settings.WriteBool('EnablePreProcess', chbTextProcessor.checked);
    Settings.EndSection;
  finally
    Settings.Free;
  end;
end;

procedure TMainForm.LoadSettings;
var
  Settings: TSettingsFile;
  str: string;
begin
  Settings := TSettingsFile.Create('Config', 'Easy Text Hooker', True);
  try
    Settings.BeginSection('Main');
    ClipboardCopy.checked := Settings.ReadBool('ClipboardCopy', False);
    PageControl.TabIndex := Settings.ReadInteger('CurrentTab', 0);

    Settings.BeginSection('TextareaFont');
    Memo.Font.Name := Settings.ReadString('Name', Memo.Font.Name);
    Memo.Font.CharSet := Byte(Settings.ReadInteger('CharSet',
      Memo.Font.CharSet));
    Memo.Font.Color := StrToInt('$' + Settings.ReadString('Color',
      inttohex(Memo.Font.Color, 8)));
    Memo.Font.Size := Settings.ReadInteger('Size', Memo.Font.Size);
    Memo.Font.Style :=
      TFontStyles(Byte(Settings.ReadInteger('Style', Byte(Memo.Font.Style))));

    Settings.BeginSection('Translate');
    DoTranslate.checked := Settings.ReadBool('DoTranslate', False);

    str := Settings.ReadString('SrcLang', 'Japanese');
    SrcLang.ItemIndex := SrcLang.Items.IndexOf(str);

    str := Settings.ReadString('DestLang', 'Russian');
    DestLang.ItemIndex := DestLang.Items.IndexOf(str);

    OnLangSelect(SrcLang);
    Settings.EndSection;

    Settings.BeginSection('OSD');
    cbEnableOSD.checked := Settings.ReadBool('EnableOSD', False);
    rbClipboard.checked := Settings.ReadBool('FromClipboard', False);
    rbText.checked := Settings.ReadBool('FromTextarea', True);
    rbSpyWindow.checked := Settings.ReadBool('FromSpyWindow', False);
    rbSpyWindowChange(rbSpyWindow);

    tbX.Position := Settings.ReadInteger('PositionX', 50);
    tbY.Position := Settings.ReadInteger('PositionY', 100);
    tbWidth.Position := Settings.ReadInteger('PositionWidth', 100);
    tbHeight.Position := Settings.ReadInteger('PositionHeight', 20);

    OSDForm.TextFont.Name := Settings.ReadString('FontName',
      'Arial Unicode MS');
    OSDForm.TextFont.CharSet := Byte(Settings.ReadInteger('FontCharSet', 0));
    OSDForm.TextFont.Size := Settings.ReadInteger('FontSize', 15);
    OSDForm.TextFont.Style :=
      TFontStyles(Byte(Settings.ReadInteger('FontStyle', 0)));

    OSDForm.TextColor := StrToInt('$' + Settings.ReadString('FontColor',
      inttohex(clWhite, 8)));
    OSDForm.OutlineColor := StrToInt('$' + Settings.ReadString('OutlineColor',
      inttohex(clBlack, 8)));

    OSDForm.OutlineWidth := Settings.ReadInteger('OutlineWidth', 1);
    cbSticky.checked := Settings.ReadBool('Sticky', True);
    Settings.EndSection;

    tbOutline.Position := OSDForm.OutlineWidth;

    Settings.BeginSection('AGTH');
    edHCode.Text := Settings.ReadString('HCode', '');
    seDelay.Value := Settings.ReadInteger('CopyDelay', 150);
    Settings.EndSection;

    Settings.BeginSection('jstp');
    LoadScript(Settings.ReadString('ScriptPath', ''));
    chbTextProcessor.checked := Settings.ReadBool('EnablePreProcess', False);
    Settings.EndSection;
  finally
    Settings.Free;
  end;
end;

procedure TMainForm.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  trans.Free;
  agserv.Free;
  SaveSettings;
  jstp.Free;
  OSDForm.Free;
end;

procedure TMainForm.FormCreate(Sender: TObject);
var
  Settings: TSettingsFile;
  YandexApiKey: string;
begin
  SpyWindowHwnd := INVALID_HANDLE_VALUE;
  IsSpyWindowSearch := False;
  Screen.Cursors[crCustomCrossHair] := LoadCursor(hInstance, 'Cursor_1');

  Settings := TSettingsFile.Create('Config', 'Easy Text Hooker', True);
  try
    Settings.BeginSection('Translate');
    YandexApiKey := Settings.ReadString('YandexApiKey', '');
  finally
    Settings.Free;
  end;
  trans := TGoogleTranslate.Create();

  jstp := JavaScriptTextProcessor.Create;
  OSDForm := TOSDForm.Create(nil);
  agserv := TAGTHServer.Create;
  agserv.OnNewStream := OnNewStream;
  agserv.OnNewText := OnNewText;
  agserv.EndLineDelay := 200;

  trans.GetFromLanguages(SrcLang.Items);
  trans.GetToLanguages(DestLang.Items);

  LoadSettings;
  UpdateColorBoxes;
end;

function TMainForm.GetSpyWindowText(Hwnd: THandle): string;
var
  Text: string;
begin
  if Hwnd <> INVALID_HANDLE_VALUE then
  begin
    SetLength(Text, SendMessage(Hwnd, WM_GETTEXTLENGTH, 0, 0) + 1);
    SendMessage(Hwnd, WM_GETTEXT, length(Text), Integer(PChar(Text)));
    Result := Text;
  end
  else
    Result := '';
end;

procedure TMainForm.OSDTimerTimer(Sender: TObject);
begin
  try
    if rbClipboard.checked then
      OSDForm.SetText(Clipboard.AsText)
    else if rbSpyWindow.checked and not IsSpyWindowSearch then
    begin
      OSDForm.SetText(GetSpyWindowText(SpyWindowHwnd));
    end;
  except
    // who cares?
  end;
end;

procedure TMainForm.rbSpyWindowChange(Sender: TObject);
begin
  if rbSpyWindow.checked then
    CrossIcon.GetBitmap(1, imgSelectWindow.Picture.Bitmap)
  else
    CrossIcon.GetBitmap(0, imgSelectWindow.Picture.Bitmap);
  imgSelectWindow.Repaint;
end;

procedure TMainForm.OSDPosChange(Sender: TObject);
begin
  OSDForm.SetPosition(tbX.Position, tbY.Position, tbWidth.Position,
    tbHeight.Position);
end;

procedure TMainForm.UpdateColorBoxes;
begin
  with imgTextColor.Canvas do
  begin
    Brush.Style := bsSolid;
    Brush.Color := OSDForm.TextColor;
    FillRect(ClipRect);

    Pen.Color := clBlack;
    Rectangle(0, 0, imgTextColor.Width, imgTextColor.Height);
  end;

  with imgOutlineColor.Canvas do
  begin
    Brush.Style := bsSolid;
    Brush.Color := OSDForm.OutlineColor;
    FillRect(ClipRect);

    Pen.Color := clBlack;
    Rectangle(0, 0, imgOutlineColor.Width, imgOutlineColor.Height);
  end;
end;

procedure TMainForm.imgOutlineColorClick(Sender: TObject);
begin
  ColorDialog1.Color := OSDForm.OutlineColor;
  if ColorDialog1.Execute(Handle) then
    OSDForm.OutlineColor := ColorDialog1.Color;
  UpdateColorBoxes;
end;

procedure TMainForm.imgSelectWindowMouseMove(Sender: TObject;
  Shift: TShiftState; X, Y: Integer);
var
  CustomHwnd: THandle;
begin
  if rbSpyWindow.checked then
  begin
    if ssLeft in Shift then
    begin
      Screen.Cursor := crCustomCrossHair;
      IsSpyWindowSearch := True;
      CustomHwnd := windowFromPoint(Mouse.CursorPos);
      OSDForm.SetText(GetSpyWindowText(CustomHwnd));
    end
    else
      Screen.Cursor := crDefault;
  end;
end;

procedure TMainForm.imgSelectWindowMouseUp(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  IsSpyWindowSearch := False;
  if rbSpyWindow.checked then
  begin
    Screen.Cursor := crDefault;
    SpyWindowHwnd := windowFromPoint(Mouse.CursorPos);
  end;
end;

procedure TMainForm.imgTextColorClick(Sender: TObject);
begin
  ColorDialog1.Color := OSDForm.TextColor;
  if ColorDialog1.Execute(Handle) then
    OSDForm.TextColor := ColorDialog1.Color;
  UpdateColorBoxes;
end;

procedure TMainForm.seDelayChange(Sender: TObject);
begin
  agserv.EndLineDelay := seDelay.Value;
end;

procedure TMainForm.OnLangSelect(Sender: TObject);
begin
  trans.SetTranslationDirection(SrcLang.Text, DestLang.Text);
end;

procedure TMainForm.tbOutlineChange(Sender: TObject);
begin
  OSDForm.OutlineWidth := tbOutline.Position;
end;

procedure TMainForm.FontSetClick(Sender: TObject);
begin
  FontDialog.Font := Memo.Font;
  if FontDialog.Execute then
    Memo.Font := FontDialog.Font;
end;

procedure TMainForm.btnHookClick(Sender: TObject);
var
  pid: Cardinal;
  idx: Integer;
begin
  idx := cbProcess.ItemIndex;
  if (idx >= 0) and (idx < cbProcess.Items.Count) then
  begin
    pid := Cardinal(cbProcess.Items.Objects[cbProcess.ItemIndex]);
    THooker.HookProcess(pid, edHCode.Text);
  end;
  cbProcessChange(cbProcess);
end;

procedure TMainForm.btnOsdFontSelectClick(Sender: TObject);
begin
  FontDialog.Font := OSDForm.TextFont;
  if FontDialog.Execute then
    OSDForm.TextFont := FontDialog.Font;
end;

procedure TMainForm.btnScriptLoadClick(Sender: TObject);
begin
  OpenDialog.Filter := '*.js|*.js';
  OpenDialog.InitialDir := ExtractFilePath(paramstr(0));
  if OpenDialog.Execute(Self.Handle) then
    LoadScript(OpenDialog.FileName);
end;

procedure TMainForm.LoadScript(path: string);
begin
  mScriptPath.Text := path;
  jstp.LoadScript(path);
  ScriptArea.Text := jstp.Script;
  TRichEditJsHighlighter.jsHighlight(ScriptArea);
end;

procedure TMainForm.cbEnableOSDClick(Sender: TObject);
begin
  if cbEnableOSD.checked then
    OSDForm.Show
  else
    OSDForm.Hide;
end;

procedure TMainForm.cbStickyClick(Sender: TObject);
begin
  OSDForm.Sticky := cbSticky.checked;
end;

procedure TMainForm.cbProcessChange(Sender: TObject);
var
  itindex: Integer;
  pid: Cardinal;
begin
  itindex := cbProcess.ItemIndex;
  pid := Cardinal(cbProcess.Items.Objects[itindex]);
  btnHook.Enabled := not THooker.IsHooked(pid);
end;

procedure TMainForm.cbProcessDrawItem(Control: TWinControl; Index: Integer;
  Rect: TRect; State: TOwnerDrawState);
var
  ComboBox: TComboBox;
  Bitmap: Graphics.TBitmap;
begin
  ComboBox := (Control as TComboBox);
  Bitmap := Graphics.TBitmap.Create;
  try
    ProcIcon.GetBitmap(index, Bitmap);
    with ComboBox.Canvas do
    begin
      FillRect(Rect);
      if Bitmap.Handle <> 0 then
        Draw(Rect.Left + 2, Rect.Top, Bitmap);
      Rect := Bounds(Rect.Left + ComboBox.ItemHeight + 2 + 5, Rect.Top,
        Rect.Right - Rect.Left, Rect.Bottom - Rect.Top);
      DrawText(Handle, PChar(ComboBox.Items[index]),
        length(ComboBox.Items[index]), Rect, DT_VCENTER + DT_SINGLELINE);
    end;
  finally
    Bitmap.Free;
  end;
end;

procedure TMainForm.cbProcessDropDown(Sender: TObject);
var
  itindex: Integer;
  i: Integer;
  pid: Cardinal;
  proc: THandle;
  buffer: array [0 .. MAX_PATH] of WideChar;
  res: Integer;
  ico: TIcon;
  hico: THandle;
begin
  itindex := cbProcess.ItemIndex;
  THooker.GetProcessList(cbProcess.Items);
  ProcIcon.Clear;
  for i := 0 to cbProcess.Items.Count - 1 do
  begin
    FillChar(buffer, MAX_PATH, 0);

    pid := Cardinal(cbProcess.Items.Objects[i]);
    proc := OpenProcess(PROCESS_QUERY_INFORMATION or PROCESS_VM_READ,
      False, pid);

    res := 0;
    if proc <> 0 then
    begin
      res := GetModuleFileNameEx(proc, 0, buffer, MAX_PATH);
      CloseHandle(proc);
    end;

    if res > 0 then
    begin
      hico := ExtractIcon(hInstance, buffer, 0);
      if hico <> 0 then
      begin
        ico := TIcon.Create;
        ico.Handle := hico;
        ProcIcon.AddIcon(ico);
        ico.Free;
        DestroyIcon(hico);
      end
      else
        ProcIcon.AddImage(Images, 0);
    end
    else
      ProcIcon.AddImage(Images, 0);
  end;

  cbProcess.ItemIndex := itindex;
end;

procedure TMainForm.cbStreamsChange(Sender: TObject);
begin
  agserv.SelectStream(cbStreams.ItemIndex);
  agserv.GetStreamText(AGTHMemo.lines);
  AGTHMemo.SelStart := AGTHMemo.Perform(EM_LINEINDEX, AGTHMemo.lines.Count, 0);
  AGTHMemo.Perform(EM_SCROLLCARET, 0, 0);
end;

procedure TMainForm.OnNewStream(lines: TStrings);
var
  i: Integer;
begin
  i := cbStreams.ItemIndex;
  cbStreams.Items.Assign(lines);
  cbStreams.ItemIndex := i;
end;

procedure TMainForm.OnNewText(Text: widestring);
var
  s: string;
begin
  agserv.GetStreamText(AGTHMemo.lines);
  AGTHMemo.SelStart := AGTHMemo.Perform(EM_LINEINDEX, AGTHMemo.lines.Count, 0);
  AGTHMemo.Perform(EM_SCROLLCARET, 0, 0);

  if chbTextProcessor.checked then
    s := jstp.ProcessText(Text)
  else
    s := Text;

  if s = '' then
    exit;

  if DoTranslate.checked then
    s := trans.Translate(s);

  if (cbEnableOSD.checked) and (rbText.checked) then
    OSDForm.SetText(s);

  if ClipboardCopy.checked then
    try
      Clipboard.AsText := s;
    except
      // what can i do?
    end;

  Memo.Text := s;
end;

end.
