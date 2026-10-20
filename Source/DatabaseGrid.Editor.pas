unit DatabaseGrid.Editor;

interface

uses
  Winapi.Messages, System.Classes, Vcl.Controls, Vcl.StdCtrls;

type
  TDatabaseGridEditorKeyEvent = procedure(var AKey: Word; const AShift: TShiftState) of object;
  TDatabaseGridEditorModifyEvent = function: Boolean of object;

  TDatabaseGridEditor = class(TCustomEdit)
  strict private
    FOnBeginModify: TDatabaseGridEditorModifyEvent;
    FOnKeyCommand: TDatabaseGridEditorKeyEvent;
    function BeginModify: Boolean;
    procedure WMClear(var AMessage: TMessage); message WM_CLEAR;
    procedure WMCut(var AMessage: TMessage); message WM_CUT;
    procedure WMGetDlgCode(var AMessage: TWMGetDlgCode); message WM_GETDLGCODE;
    procedure WMPaste(var AMessage: TMessage); message WM_PASTE;
  protected
    procedure KeyDown(var AKey: Word; AShift: TShiftState); override;
    procedure KeyPress(var AKey: Char); override;
  public
    constructor Create(AOwner: TComponent); override;
    procedure SetMargins(const ALeft, ARight: Integer);
    property Alignment;
    property Color;
    property Font;
    property MaxLength;
    property OnBeginModify: TDatabaseGridEditorModifyEvent read FOnBeginModify write FOnBeginModify;
    property OnChange;
    property OnExit;
    property OnKeyCommand: TDatabaseGridEditorKeyEvent read FOnKeyCommand write FOnKeyCommand;
  end;

implementation

uses
  Winapi.Windows, System.UITypes, Vcl.Forms, DatabaseGrid.Consts;

constructor TDatabaseGridEditor.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);

  AutoSize := False;
  BorderStyle := bsNone;
  Ctl3D := False;
  ParentCtl3D := False;
  ParentFont := False;
  TabStop := False;
  Visible := False;
end;

function TDatabaseGridEditor.BeginModify: Boolean;
begin
  Result := not Assigned(FOnBeginModify) or FOnBeginModify;
end;

procedure TDatabaseGridEditor.SetMargins(const ALeft, ARight: Integer);
begin
  if HandleAllocated then
    SendMessage(Handle, EM_SETMARGINS, EC_LEFTMARGIN or EC_RIGHTMARGIN, MakeLong(ALeft, ARight));
end;

procedure TDatabaseGridEditor.KeyDown(var AKey: Word; AShift: TShiftState);
begin
  if Assigned(FOnKeyCommand) then
    FOnKeyCommand(AKey, AShift);

  if (AKey = vkDelete) and not BeginModify then
    AKey := 0;

  if AKey <> 0 then
    inherited KeyDown(AKey, AShift);
end;

procedure TDatabaseGridEditor.KeyPress(var AKey: Char);
begin
  case AKey of
    TControlCharacters.StartOfHeading, TControlCharacters.EndOfText:
      ;
    TControlCharacters.Tab, TControlCharacters.CarriageReturn, TControlCharacters.Escape, TCharacters.CtrlBackspace:
      AKey := TControlCharacters.Null;
  else
    if not BeginModify then
      AKey := TControlCharacters.Null;
  end;

  if AKey <> TControlCharacters.Null then
    inherited KeyPress(AKey);
end;

procedure TDatabaseGridEditor.WMClear(var AMessage: TMessage);
begin
  if BeginModify then
    inherited;
end;

procedure TDatabaseGridEditor.WMCut(var AMessage: TMessage);
begin
  if BeginModify then
    inherited;
end;

procedure TDatabaseGridEditor.WMGetDlgCode(var AMessage: TWMGetDlgCode);
begin
  inherited;

  AMessage.Result := AMessage.Result or DLGC_WANTARROWS or DLGC_WANTTAB or DLGC_WANTALLKEYS;
end;

procedure TDatabaseGridEditor.WMPaste(var AMessage: TMessage);
begin
  if BeginModify then
    inherited;
end;

end.
