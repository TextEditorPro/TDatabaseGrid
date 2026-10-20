unit DatabaseGrid.ColumnListDialog;

interface

uses
  Winapi.Messages, System.Classes, Vcl.Controls, Vcl.Forms, Vcl.Graphics, Data.DB, DatabaseGrid, DatabaseGrid.Columns, DatabaseGrid.Consts,
  DatabaseGrid.ListDataSet;

type
  TDatabaseGridColumnListDialog = class(TCustomForm)
  strict private
    FColumns: TArray<TDatabaseGridColumn>;
    FDataSet: TDatabaseGridListDataSet;
    FDataSource: TDataSource;
    FGrid: TDatabaseGrid;
    function GetValueText(const AColumn: TDatabaseGridColumn): string;
    procedure Accept;
    procedure FormKeyDown(ASender: TObject; var AKey: Word; AShift: TShiftState);
    procedure GridDblClick(ASender: TObject);
    procedure WMAccept(var AMessage: TMessage); message TDatabaseGridMessage.WM_ACCEPT;
  public
    constructor CreateDialog(const AGrid: TCustomDatabaseGrid; const AFont: TFont);
    class function Execute(const AGrid: TCustomDatabaseGrid; const AFont: TFont; var AColumn: TDatabaseGridColumn): Boolean;
  end;

implementation

uses
  Winapi.Windows, System.Math, System.SysUtils, System.Types, System.UITypes, DatabaseGrid.FieldValues, DatabaseGrid.Language,
  DatabaseGrid.Types;

const
  VALUE_FIELD_SIZE = 1024;

constructor TDatabaseGridColumnListDialog.CreateDialog(const AGrid: TCustomDatabaseGrid; const AFont: TFont);
var
  LBitmap: Vcl.Graphics.TBitmap;
  LColumn: TDatabaseGridColumn;
  LColumnWidth: Integer;
  LGridRect, LWorkArea: TRect;
  LDetails, LText: string;
begin
  inherited CreateNew(nil);

  BorderIcons := [biSystemMenu];
  BorderStyle := bsSizeToolWin;
  Caption := SDatabaseGridJumpToColumnCaption;
  Font.Assign(AFont);
  KeyPreview := True;
  Position := poDesigned;
  OnKeyDown := FormKeyDown;

  ClientWidth := MulDiv(480, AGrid.CurrentPPI, USER_DEFAULT_SCREEN_DPI);
  ClientHeight := MulDiv(400, AGrid.CurrentPPI, USER_DEFAULT_SCREEN_DPI);
  Constraints.MinWidth := Width div 2;
  Constraints.MinHeight := Height div 2;

  FDataSet := TDatabaseGridListDataSet.Create(Self);
  FDataSet.FieldDefs.Add('COLUMN', ftWideString, 256);
  FDataSet.FieldDefs.Add('VALUE', ftWideString, VALUE_FIELD_SIZE);

  LColumnWidth := 0;

  LBitmap := Vcl.Graphics.TBitmap.Create;
  try
    LBitmap.Canvas.Font.Assign(Font);

    for var LIndex := 0 to AGrid.Columns.Count - 1 do
    begin
      LColumn := AGrid.Columns[LIndex];

      if not LColumn.Visible then
        Continue;

      LText := LColumn.Title.DisplayCaption;
      LDetails := '';

      if not LColumn.FieldName.IsEmpty and not SameText(LColumn.FieldName, LText) then
        LDetails := LColumn.FieldName;

      if not LColumn.Title.SubCaption.IsEmpty then
        LDetails := if LDetails.IsEmpty then LColumn.Title.SubCaption else LDetails + ', ' + LColumn.Title.SubCaption;

      if not LDetails.IsEmpty then
        LText := LText + ' (' + LDetails + ')';

      FDataSet.AddRow([LText, GetValueText(LColumn)]);
      FColumns := FColumns + [LColumn];
      LColumnWidth := Max(LColumnWidth, LBitmap.Canvas.TextWidth(LText));
    end;
  finally
    LBitmap.Free;
  end;

  FDataSet.Open;

  FDataSource := TDataSource.Create(Self);
  FDataSource.DataSet := FDataSet;

  FGrid := TDatabaseGrid.Create(Self);
  FGrid.Parent := Self;
  FGrid.Align := alClient;
  FGrid.Colors.Assign(AGrid.Colors);
  FGrid.Indicator.Visible := False;
  FGrid.Indicator.TitleMenu.Commands.SetVisible([Low(TDatabaseGridTitleMenuCommand)..High(TDatabaseGridTitleMenuCommand)], False);
  FGrid.Options := [dgoAlwaysShowSelection, dgoAutoFitColumns, dgoColumnResize, dgoShowHints];
  FGrid.SearchPanel.Options := [spoFilterOnTyping, spoHighlightMatches];
  FGrid.SearchPanel.Visible := True;
  FGrid.OnDblClick := GridDblClick;

  LColumn := FGrid.Columns.Add;
  LColumn.Options := LColumn.Options - [coAutoFit];
  LColumn.FieldName := 'COLUMN';
  LColumn.Title.Caption := SDatabaseGridColumn;
  LColumn.Width := Min(LColumnWidth + MulDiv(24, AGrid.CurrentPPI, USER_DEFAULT_SCREEN_DPI), ClientWidth div 2);

  LColumn := FGrid.Columns.Add;
  LColumn.FieldName := 'VALUE';
  LColumn.Title.Caption := SDatabaseGridValue;

  FGrid.DataSource := FDataSource;

  ActiveControl := FGrid;

  LGridRect := TRect.Create(AGrid.ClientToScreen(Point(0, 0)), AGrid.ClientWidth, AGrid.ClientHeight);
  LWorkArea := Screen.MonitorFromRect(LGridRect).WorkareaRect;
  Left := EnsureRange(LGridRect.CenterPoint.X - Width div 2, LWorkArea.Left, Max(LWorkArea.Right - Width, LWorkArea.Left));
  Top := EnsureRange(LGridRect.CenterPoint.Y - Height div 2, LWorkArea.Top, Max(LWorkArea.Bottom - Height, LWorkArea.Top));
end;

class function TDatabaseGridColumnListDialog.Execute(const AGrid: TCustomDatabaseGrid; const AFont: TFont;
  var AColumn: TDatabaseGridColumn): Boolean;
var
  LDialog: TDatabaseGridColumnListDialog;
begin
  LDialog := TDatabaseGridColumnListDialog.CreateDialog(AGrid, AFont);
  try
    for var LIndex := 0 to High(LDialog.FColumns) do
    if LDialog.FColumns[LIndex] = AColumn then
      LDialog.FDataSet.RecNo := LIndex + 1;

    Result := (LDialog.ShowModal = mrOk) and (LDialog.FDataSet.RowIndex >= 0);

    if Result then
      AColumn := LDialog.FColumns[LDialog.FDataSet.RowIndex];
  finally
    LDialog.Free;
  end;
end;

function TDatabaseGridColumnListDialog.GetValueText(const AColumn: TDatabaseGridColumn): string;
var
  LDataSet: TDataSet;
begin
  if not Assigned(AColumn.Field) then
    Exit('');

  LDataSet := AColumn.Field.DataSet;

  if not LDataSet.Active or LDataSet.IsEmpty and (LDataSet.State <> dsInsert) or AColumn.Field.IsNull then
    Exit('');

  Result := Copy(AdjustLineBreaks(GetFieldText(AColumn.Field), tlbsLF).Replace(TControlCharacters.LineFeed, ' '), 1, VALUE_FIELD_SIZE);
end;

procedure TDatabaseGridColumnListDialog.Accept;
begin
  if FDataSet.RowIndex >= 0 then
    ModalResult := mrOk;
end;

procedure TDatabaseGridColumnListDialog.FormKeyDown(ASender: TObject; var AKey: Word; AShift: TShiftState);
begin
  case AKey of
    vkEscape:
      begin
        AKey := 0;

        ModalResult := mrCancel;
      end;
    vkReturn:
      if FGrid.Focused then
      begin
        AKey := 0;

        Accept;
      end
      else
        PostMessage(Handle, TDatabaseGridMessage.WM_ACCEPT, 0, 0);
  end;
end;

procedure TDatabaseGridColumnListDialog.GridDblClick(ASender: TObject);
var
  LPoint: TPoint;
begin
  LPoint := FGrid.ScreenToClient(Mouse.CursorPos);

  if FGrid.GetAreaAt(LPoint.X, LPoint.Y) = gaData then
    Accept;
end;

procedure TDatabaseGridColumnListDialog.WMAccept(var AMessage: TMessage);
begin
  Accept;
end;

end.
