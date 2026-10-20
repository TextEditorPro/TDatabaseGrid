unit DatabaseGrid.ColumnFilter.Popup;

{$I DatabaseGrid.Defines.inc}

interface

uses
  Winapi.Messages, Winapi.Windows, System.Classes, System.Types, System.UITypes, Vcl.Controls, Vcl.Forms, Vcl.Graphics, Vcl.StdCtrls,
  DatabaseGrid.Columns, DatabaseGrid.PopupForm, DatabaseGrid.Types
{$IFDEF ALPHASKINS}
  , sButton, sComboBox, sEdit, sLabel, sListBox
{$ENDIF};

type
{$IFDEF ALPHASKINS}
  TDatabaseGridPopupButton = TsButton;
  TDatabaseGridPopupComboBox = TsComboBox;
  TDatabaseGridPopupEdit = TsEdit;
  TDatabaseGridPopupLabel = TsLabel;
  TDatabaseGridPopupListBox = TsListBox;
{$ELSE}
  TDatabaseGridPopupButton = TButton;
  TDatabaseGridPopupComboBox = TComboBox;
  TDatabaseGridPopupEdit = TEdit;
  TDatabaseGridPopupLabel = TLabel;
  TDatabaseGridPopupListBox = TListBox;
{$ENDIF}

  TDatabaseGridPopupList = class(TDatabaseGridPopupListBox)
  strict private
    procedure CNDrawItem(var AMessage: TWMDrawItem); message CN_DRAWITEM;
  end;

  TDatabaseGridColumnSortEvent = procedure(ASender: TObject; const AColumn: TDatabaseGridColumn;
    const ASortMarker: TDatabaseGridSortMarker) of object;

  TDatabaseGridColumnFilterPopup = class(TDatabaseGridPopupForm)
  strict private
    FAllValues: TStringList;
    FCancelButton: TDatabaseGridPopupButton;
    FCheckedValues: TStringList;
    FClosedByDeactivation: Boolean;
    FColumn: TDatabaseGridColumn;
    FDragChecked: Boolean;
    FDragging: Boolean;
    FMenuList: TDatabaseGridPopupList;
    FOKButton: TDatabaseGridPopupButton;
    FOnClearAllColumnFilters: TNotifyEvent;
    FOnSort: TDatabaseGridColumnSortEvent;
    FOptions: TDatabaseGridColumnFilterOptions;
    FSearchEdit: TDatabaseGridPopupEdit;
    FValuesList: TDatabaseGridPopupList;
    function GetHasValueList: Boolean;
    function GetItemValue(const AIndex: Integer): string;
    function GetTextHeight: Integer;
    function IsItemChecked(const AIndex: Integer): Boolean;
    function Scale(const AValue: Integer): Integer;
    procedure ButtonClick(ASender: TObject);
    procedure FillValuesList;
    procedure FitHeight;
    procedure FormKeyDown(ASender: TObject; var AKey: Word; AShift: TShiftState);
    procedure MenuListClick(ASender: TObject);
    procedure MenuListDrawItem(AControl: TWinControl; AIndex: Integer; ARect: TRect; AState: TOwnerDrawState);
    procedure MenuListMeasureItem(AControl: TWinControl; AIndex: Integer; var AHeight: Integer);
    procedure MenuListMouseLeave(ASender: TObject);
    procedure MenuListMouseMove(ASender: TObject; AShift: TShiftState; AX, AY: Integer);
    procedure SearchEditChange(ASender: TObject);
    procedure SetItemChecked(const AIndex: Integer; const AChecked: Boolean);
    procedure ShowConditionDialog;
    procedure ToggleItem(const AIndex: Integer);
    procedure ValuesListDrawItem(AControl: TWinControl; AIndex: Integer; ARect: TRect; AState: TOwnerDrawState);
    procedure ValuesListKeyPress(ASender: TObject; var AKey: Char);
    procedure ValuesListMouseDown(ASender: TObject; AButton: TMouseButton; AShift: TShiftState; AX, AY: Integer);
    procedure ValuesListMouseLeave(ASender: TObject);
    procedure ValuesListMouseMove(ASender: TObject; AShift: TShiftState; AX, AY: Integer);
    procedure ValuesListMouseUp(ASender: TObject; AButton: TMouseButton; AShift: TShiftState; AX, AY: Integer);
    procedure WMActivate(var AMessage: TWMActivate); message WM_ACTIVATE;
    procedure WMNCHitTest(var AMessage: TWMNCHitTest); message WM_NCHITTEST;
  protected
    procedure CreateParams(var AParams: TCreateParams); override;
  public
    constructor CreatePopup(const AOwner: TComponent; const AColumn: TDatabaseGridColumn; const AValues: TStrings;
      const AFont: TFont; const AOptions: TDatabaseGridColumnFilterOptions);
    destructor Destroy; override;
    procedure Popup(const APosition: TPoint);
    property ClosedByDeactivation: Boolean read FClosedByDeactivation;
    property Column: TDatabaseGridColumn read FColumn;
    property HasValueList: Boolean read GetHasValueList;
    property OnClearAllColumnFilters: TNotifyEvent read FOnClearAllColumnFilters write FOnClearAllColumnFilters;
    property OnClose;
    property OnSort: TDatabaseGridColumnSortEvent read FOnSort write FOnSort;
  end;

  TDatabaseGridColumnFilterDialog = class(TCustomForm)
  strict private
    FAndLabel: TDatabaseGridPopupLabel;
    FColumn: TDatabaseGridColumn;
    FOperatorComboBox: TDatabaseGridPopupComboBox;
    FValue2Edit: TDatabaseGridPopupEdit;
    FValueEdit: TDatabaseGridPopupEdit;
    function GetOperator: TDatabaseGridColumnFilterOperator;
    procedure OperatorComboBoxChange(ASender: TObject);
  public
    constructor CreateDialog(const AOwner: TComponent; const AColumn: TDatabaseGridColumn; const AFont: TFont);
    function Execute: Boolean;
  end;

function DatabaseGridFilterOperatorCaption(const AOperator: TDatabaseGridColumnFilterOperator): string;

implementation

uses
  System.Math, System.SysUtils, DatabaseGrid.Colors, DatabaseGrid.Consts, DatabaseGrid.Glyphs, DatabaseGrid.Language;

const
  MENU_SORT_ASCENDING = 0;
  MENU_SORT_DESCENDING = 1;
  MENU_CLEAR_SORT = 2;
  MENU_SEPARATOR = 3;
  MENU_COLUMN_FILTER = 4;
  MENU_CLEAR_COLUMN_FILTER = 5;
  MENU_CLEAR_ALL_COLUMN_FILTERS = 6;
  MENU_ITEM_COUNT = 7;
  MENU_GLYPHS: array [0..MENU_ITEM_COUNT - 1] of TDatabaseGridGlyph = (glSortAscending, glSortDescending, glClear, glClear, glFilter, glClear, glClear);
  DIALOG_OPERATORS: array [0..12] of TDatabaseGridColumnFilterOperator = (foEquals, foNotEquals, foContains, foNotContains, foBeginsWith,
    foEndsWith, foGreater, foGreaterOrEqual, foLess, foLessOrEqual, foBetween, foEmpty, foNotEmpty);

function DatabaseGridFilterOperatorCaption(const AOperator: TDatabaseGridColumnFilterOperator): string;
begin
  case AOperator of
    foEquals:
      Result := SDatabaseGridEquals;
    foNotEquals:
      Result := SDatabaseGridDoesNotEqual;
    foContains:
      Result := SDatabaseGridContains;
    foNotContains:
      Result := SDatabaseGridDoesNotContain;
    foBeginsWith:
      Result := SDatabaseGridBeginsWith;
    foEndsWith:
      Result := SDatabaseGridEndsWith;
    foGreater:
      Result := SDatabaseGridGreater;
    foGreaterOrEqual:
      Result := SDatabaseGridGreaterOrEqual;
    foLess:
      Result := SDatabaseGridLess;
    foLessOrEqual:
      Result := SDatabaseGridLessOrEqual;
    foBetween:
      Result := SDatabaseGridBetween;
    foEmpty:
      Result := SDatabaseGridIsEmpty;
    foNotEmpty:
      Result := SDatabaseGridIsNotEmpty;
  else
    Result := '';
  end;
end;

{ TDatabaseGridPopupList }

procedure TDatabaseGridPopupList.CNDrawItem(var AMessage: TWMDrawItem);
begin
  AMessage.DrawItemStruct.itemState := AMessage.DrawItemStruct.itemState and not ODS_FOCUS;

  inherited;
end;

{ TDatabaseGridColumnFilterPopup }

constructor TDatabaseGridColumnFilterPopup.CreatePopup(const AOwner: TComponent; const AColumn: TDatabaseGridColumn;
  const AValues: TStrings; const AFont: TFont; const AOptions: TDatabaseGridColumnFilterOptions);
const
  MENU_CAPTIONS: array [0..MENU_ITEM_COUNT - 1] of Pointer = (@SDatabaseGridSortAscending, @SDatabaseGridSortDescending,
    @SDatabaseGridClearSort, nil, @SDatabaseGridColumnFilter, @SDatabaseGridClearColumnFilter, @SDatabaseGridClearAllColumnFilters);
var
  LButtonHeight, LButtonWidth, LControlHeight, LMargin, LTop: Integer;
begin
  inherited CreateNew(AOwner);

  FColumn := AColumn;
  FOptions := AOptions;
  FAllValues := TStringList.Create;
  FAllValues.Assign(AValues);
  FCheckedValues := TStringList.Create;
  FCheckedValues.CaseSensitive := False;
  FCheckedValues.Duplicates := dupIgnore;

  if AColumn.Filter.Operator = foValues then
    FCheckedValues.Assign(AColumn.Filter.Values)
  else
    FCheckedValues.Assign(FAllValues);

  FCheckedValues.Sorted := True;

  Font.Assign(AFont);
  SetBounds(0, 0, Scale(TDatabaseGridSize.FilterPopupWidth), Scale(TDatabaseGridSize.FilterPopupHeight));
  Constraints.MinWidth := Scale(TDatabaseGridSize.FilterPopupWidth);
  Constraints.MinHeight := Scale(TDatabaseGridSize.FilterPopupHeight) div 2;
  OnKeyDown := FormKeyDown;

  LMargin := Scale(6);
  LControlHeight := Scale(23);
  LButtonHeight := Scale(25);
  LButtonWidth := Scale(75);

  FMenuList := TDatabaseGridPopupList.Create(Self);
  FMenuList.Parent := Self;
  FMenuList.Anchors := [akLeft, akTop, akRight];
  FMenuList.BorderStyle := bsNone;
  FMenuList.Style := lbOwnerDrawVariable;
  FMenuList.ItemHeight := LControlHeight;
  FMenuList.SetBounds(0, Scale(2), ClientWidth, (MENU_ITEM_COUNT - 1) * LControlHeight + Scale(TDatabaseGridSize.MenuSeparatorHeight));
  FMenuList.OnClick := MenuListClick;
  FMenuList.OnDrawItem := MenuListDrawItem;
  FMenuList.OnMeasureItem := MenuListMeasureItem;
  FMenuList.OnMouseLeave := MenuListMouseLeave;
  FMenuList.OnMouseMove := MenuListMouseMove;

  for var LIndex := 0 to MENU_ITEM_COUNT - 1 do
  if Assigned(MENU_CAPTIONS[LIndex]) then
    FMenuList.Items.Add(LoadResString(MENU_CAPTIONS[LIndex]))
  else
    FMenuList.Items.Add('-');

  LTop := FMenuList.Top + FMenuList.Height + LMargin;

  if not (cfoShowValueList in FOptions) then
  begin
    Constraints.MinHeight := 0;
    ClientHeight := LTop;

    Exit;
  end;

  FSearchEdit := TDatabaseGridPopupEdit.Create(Self);
  FSearchEdit.Parent := Self;
  FSearchEdit.Anchors := [akLeft, akTop, akRight];
  FSearchEdit.SetBounds(LMargin, LTop, ClientWidth - 2 * LMargin, LControlHeight);
  FSearchEdit.TextHint := SDatabaseGridSearch;
  FSearchEdit.OnChange := SearchEditChange;

  Inc(LTop, LControlHeight + LMargin);

  FValuesList := TDatabaseGridPopupList.Create(Self);
  FValuesList.Parent := Self;
  FValuesList.Anchors := [akLeft, akTop, akRight, akBottom];
  FValuesList.DoubleBuffered := True;
  FValuesList.Style := lbOwnerDrawFixed;
  FValuesList.ItemHeight := GetTextHeight + 2 * Scale(TDatabaseGridSize.RowPadding);
  FValuesList.SetBounds(LMargin, LTop, ClientWidth - 2 * LMargin, ClientHeight - LTop - 2 * LMargin - LButtonHeight);
  FValuesList.OnDrawItem := ValuesListDrawItem;
  FValuesList.OnKeyPress := ValuesListKeyPress;
  FValuesList.OnMouseDown := ValuesListMouseDown;
  FValuesList.OnMouseLeave := ValuesListMouseLeave;
  FValuesList.OnMouseMove := ValuesListMouseMove;
  FValuesList.OnMouseUp := ValuesListMouseUp;

  FOKButton := TDatabaseGridPopupButton.Create(Self);
  FOKButton.Parent := Self;
  FOKButton.Anchors := [akRight, akBottom];
  FOKButton.Caption := SDatabaseGridOK;
  FOKButton.Default := True;
  FOKButton.SetBounds(ClientWidth - 2 * (LButtonWidth + LMargin), ClientHeight - LMargin - LButtonHeight, LButtonWidth, LButtonHeight);
  FOKButton.OnClick := ButtonClick;

  FCancelButton := TDatabaseGridPopupButton.Create(Self);
  FCancelButton.Parent := Self;
  FCancelButton.Anchors := [akRight, akBottom];
  FCancelButton.Caption := SDatabaseGridCancel;
  FCancelButton.Cancel := True;
  FCancelButton.SetBounds(ClientWidth - LButtonWidth - LMargin, ClientHeight - LMargin - LButtonHeight, LButtonWidth, LButtonHeight);
  FCancelButton.OnClick := ButtonClick;

  FillValuesList;
  FitHeight;
end;

destructor TDatabaseGridColumnFilterPopup.Destroy;
begin
  FAllValues.Free;
  FCheckedValues.Free;

  inherited Destroy;
end;

procedure TDatabaseGridColumnFilterPopup.FitHeight;
var
  LListHeight: Integer;
begin
  FValuesList.HandleNeeded;

  LListHeight := EnsureRange(FValuesList.Items.Count, 1, DATABASE_GRID_FILTER_POPUP_MAX_ROW_COUNT) * FValuesList.ItemHeight +
    FValuesList.Height - FValuesList.ClientHeight;

  ClientHeight := ClientHeight + LListHeight - FValuesList.Height;
end;

function TDatabaseGridColumnFilterPopup.GetHasValueList: Boolean;
begin
  Result := Assigned(FValuesList);
end;

function TDatabaseGridColumnFilterPopup.GetItemValue(const AIndex: Integer): string;
begin
  Result := FValuesList.Items[AIndex];

  if Result = SDatabaseGridEmpty then
    Result := '';
end;

function TDatabaseGridColumnFilterPopup.GetTextHeight: Integer;
var
  LBitmap: TBitmap;
begin
  LBitmap := TBitmap.Create;
  try
    LBitmap.Canvas.Font := Font;

    Result := LBitmap.Canvas.TextHeight('Wg');
  finally
    LBitmap.Free;
  end;
end;

function TDatabaseGridColumnFilterPopup.IsItemChecked(const AIndex: Integer): Boolean;
var
  LValueIndex: Integer;
begin
  if AIndex = 0 then
  begin
    for var LIndex := 1 to FValuesList.Items.Count - 1 do
    if not FCheckedValues.Find(GetItemValue(LIndex), LValueIndex) then
      Exit(False);

    Result := FValuesList.Items.Count > 1;
  end
  else
    Result := FCheckedValues.Find(GetItemValue(AIndex), LValueIndex);
end;

function TDatabaseGridColumnFilterPopup.Scale(const AValue: Integer): Integer;
begin
  Result := MulDiv(AValue, Screen.PixelsPerInch, USER_DEFAULT_SCREEN_DPI);
end;

procedure TDatabaseGridColumnFilterPopup.ButtonClick(ASender: TObject);
begin
  if ASender = FOKButton then
  begin
    if FCheckedValues.Count >= FAllValues.Count then
      FColumn.Filter.Clear
    else
      FColumn.Filter.SetValues(FCheckedValues);
  end;

  Close;
end;

procedure TDatabaseGridColumnFilterPopup.CreateParams(var AParams: TCreateParams);
begin
  inherited CreateParams(AParams);

  AParams.Style := (AParams.Style and not WS_CHILD) or WS_POPUP or WS_BORDER;
  AParams.ExStyle := AParams.ExStyle or WS_EX_TOOLWINDOW or WS_EX_TOPMOST;

  if cfoDropDownShadow in FOptions then
    AParams.WindowClass.Style := AParams.WindowClass.Style or CS_DROPSHADOW;
end;

procedure TDatabaseGridColumnFilterPopup.FillValuesList;
var
  LSearchText, LValue: string;
begin
  FValuesList.Items.BeginUpdate;
  try
    FValuesList.Items.Clear;
    FValuesList.Items.Add(SDatabaseGridSelectAll);

    LSearchText := AnsiUpperCase(Trim(FSearchEdit.Text));

    for var LIndex := 0 to FAllValues.Count - 1 do
    begin
      LValue := FAllValues[LIndex];

      if LSearchText.IsEmpty or AnsiUpperCase(LValue).Contains(LSearchText) then
        FValuesList.Items.Add(if LValue.IsEmpty then SDatabaseGridEmpty else LValue);
    end;
  finally
    FValuesList.Items.EndUpdate;
  end;
end;

procedure TDatabaseGridColumnFilterPopup.FormKeyDown(ASender: TObject; var AKey: Word; AShift: TShiftState);
begin
  if AKey = vkEscape then
  begin
    AKey := 0;

    Close;
  end;
end;

procedure TDatabaseGridColumnFilterPopup.MenuListClick(ASender: TObject);
begin
  case FMenuList.ItemIndex of
    MENU_SORT_ASCENDING:
      if Assigned(FOnSort) then
        FOnSort(Self, FColumn, TDatabaseGridSortMarker.smAscending);
    MENU_SORT_DESCENDING:
      if Assigned(FOnSort) then
        FOnSort(Self, FColumn, TDatabaseGridSortMarker.smDescending);
    MENU_CLEAR_SORT:
      if Assigned(FOnSort) then
        FOnSort(Self, FColumn, TDatabaseGridSortMarker.smNone);
    MENU_COLUMN_FILTER:
      begin
        ShowConditionDialog;

        Exit;
      end;
    MENU_CLEAR_COLUMN_FILTER:
      FColumn.Filter.Clear;
    MENU_CLEAR_ALL_COLUMN_FILTERS:
      if Assigned(FOnClearAllColumnFilters) then
        FOnClearAllColumnFilters(Self);
  else
    Exit;
  end;

  Close;
end;

procedure TDatabaseGridColumnFilterPopup.MenuListDrawItem(AControl: TWinControl; AIndex: Integer; ARect: TRect;
  AState: TOwnerDrawState);
var
  LCanvas: TCanvas;
  LGlyphRect: TRect;
  LGlyphSize: Integer;
begin
  LCanvas := (AControl as TDatabaseGridPopupListBox).Canvas;

  if AIndex = MENU_SEPARATOR then
  begin
    LCanvas.Brush.Color := Color;
    LCanvas.FillRect(ARect);
    LCanvas.Pen.Color := BlendDatabaseGridColor(Color, SystemColor(TColors.SysBtnText), 35);
    LCanvas.MoveTo(ARect.Left + Scale(6), ARect.CenterPoint.Y);
    LCanvas.LineTo(ARect.Right - Scale(6), ARect.CenterPoint.Y);

    Exit;
  end;

  if odSelected in AState then
  begin
    LCanvas.Brush.Color := SystemColor(TColors.SysHighlight);
    LCanvas.Font.Color := SystemColor(TColors.SysHighlightText);
  end
  else
  begin
    LCanvas.Brush.Color := Color;
    LCanvas.Font.Color := SystemColor(TColors.SysBtnText);
  end;

  LCanvas.FillRect(ARect);

  LGlyphSize := ARect.Height - Scale(8);
  LGlyphRect := Bounds(ARect.Left + Scale(8), ARect.Top + (ARect.Height - LGlyphSize) div 2, LGlyphSize, LGlyphSize);

  LCanvas.TextRect(Rect(LGlyphRect.Right, ARect.Top, ARect.Right, ARect.Bottom), LGlyphRect.Right + Scale(8),
    ARect.Top + (ARect.Height - LCanvas.TextHeight('Wg')) div 2, FMenuList.Items[AIndex]);

  PaintDatabaseGridGlyph(LCanvas, LGlyphRect, MENU_GLYPHS[AIndex], LCanvas.Font.Color);
end;

procedure TDatabaseGridColumnFilterPopup.MenuListMeasureItem(AControl: TWinControl; AIndex: Integer; var AHeight: Integer);
begin
  if AIndex = MENU_SEPARATOR then
    AHeight := Scale(TDatabaseGridSize.MenuSeparatorHeight);
end;

procedure TDatabaseGridColumnFilterPopup.MenuListMouseLeave(ASender: TObject);
begin
  FMenuList.ItemIndex := -1;
end;

procedure TDatabaseGridColumnFilterPopup.MenuListMouseMove(ASender: TObject; AShift: TShiftState; AX, AY: Integer);
var
  LIndex: Integer;
begin
  LIndex := FMenuList.ItemAtPos(Point(AX, AY), True);

  if LIndex = MENU_SEPARATOR then
    LIndex := -1;

  if LIndex <> FMenuList.ItemIndex then
    FMenuList.ItemIndex := LIndex;
end;

procedure TDatabaseGridColumnFilterPopup.Popup(const APosition: TPoint);
var
  LLeft, LTop: Integer;
  LMonitor: TMonitor;
begin
  LMonitor := Screen.MonitorFromPoint(APosition);

  Height := Min(Height, Max(LMonitor.WorkareaRect.Bottom - APosition.Y, APosition.Y - LMonitor.WorkareaRect.Top));

  LLeft := Min(APosition.X, LMonitor.WorkareaRect.Right - Width);
  LTop := APosition.Y;

  if LTop + Height > LMonitor.WorkareaRect.Bottom then
    LTop := Max(APosition.Y - Height, LMonitor.WorkareaRect.Top);

  SetBounds(LLeft, LTop, Width, Height);

  Show;

  if Assigned(FSearchEdit) then
    FSearchEdit.SetFocus
  else
    FMenuList.SetFocus;
end;

procedure TDatabaseGridColumnFilterPopup.SearchEditChange(ASender: TObject);
begin
  FillValuesList;
end;

procedure TDatabaseGridColumnFilterPopup.SetItemChecked(const AIndex: Integer; const AChecked: Boolean);
var
  LValueIndex: Integer;
begin
  if (AIndex <= 0) or (IsItemChecked(AIndex) = AChecked) then
    Exit;

  if AChecked then
    FCheckedValues.Add(GetItemValue(AIndex))
  else
  if FCheckedValues.Find(GetItemValue(AIndex), LValueIndex) then
    FCheckedValues.Delete(LValueIndex);

  FValuesList.Invalidate;
end;

procedure TDatabaseGridColumnFilterPopup.ShowConditionDialog;
var
  LDialog: TDatabaseGridColumnFilterDialog;
begin
  Hide;

  LDialog := TDatabaseGridColumnFilterDialog.CreateDialog(Owner, FColumn, Font);
  try
    LDialog.Execute;
  finally
    LDialog.Free;
  end;

  Close;
end;

procedure TDatabaseGridColumnFilterPopup.ToggleItem(const AIndex: Integer);
var
  LValueIndex: Integer;
begin
  if AIndex = 0 then
  begin
    if IsItemChecked(0) then
    for var LIndex := 1 to FValuesList.Items.Count - 1 do
    begin
      if FCheckedValues.Find(GetItemValue(LIndex), LValueIndex) then
        FCheckedValues.Delete(LValueIndex);
    end
    else
    begin
      FCheckedValues.Sorted := False;

      for var LIndex := 1 to FValuesList.Items.Count - 1 do
        FCheckedValues.Add(GetItemValue(LIndex));

      FCheckedValues.Sorted := True;
    end;
  end
  else
  if AIndex > 0 then
  begin
    if FCheckedValues.Find(GetItemValue(AIndex), LValueIndex) then
      FCheckedValues.Delete(LValueIndex)
    else
      FCheckedValues.Add(GetItemValue(AIndex));
  end;

  FValuesList.Invalidate;
end;

procedure TDatabaseGridColumnFilterPopup.ValuesListDrawItem(AControl: TWinControl; AIndex: Integer; ARect: TRect; AState: TOwnerDrawState);
var
  LBoxRect: TRect;
  LCanvas: TCanvas;
  LPoints: array [0..2] of TPoint;
  LSize: Integer;
begin
  LCanvas := (AControl as TDatabaseGridPopupListBox).Canvas;

  if odSelected in AState then
  begin
    LCanvas.Brush.Color := SystemColor(TColors.SysHighlight);
    LCanvas.Font.Color := SystemColor(TColors.SysHighlightText);
  end
  else
  begin
    LCanvas.Brush.Color := SystemColor(TColors.SysWindow);
    LCanvas.Font.Color := SystemColor(TColors.SysWindowText);
  end;

  LCanvas.FillRect(ARect);

  LSize := Min(Scale(TDatabaseGridSize.CheckBox), ARect.Height - 4);
  LBoxRect := Bounds(ARect.Left + Scale(4), ARect.Top + (ARect.Height - LSize) div 2, LSize, LSize);

  LCanvas.TextRect(Rect(LBoxRect.Right, ARect.Top, ARect.Right, ARect.Bottom), LBoxRect.Right + Scale(6),
    ARect.Top + (ARect.Height - LCanvas.TextHeight('Wg')) div 2, FValuesList.Items[AIndex]);

  LCanvas.Brush.Color := SystemColor(TColors.SysBtnShadow);
  LCanvas.FrameRect(LBoxRect);
  LCanvas.Brush.Color := SystemColor(TColors.SysWindow);
  LCanvas.FillRect(Rect(LBoxRect.Left + 1, LBoxRect.Top + 1, LBoxRect.Right - 1, LBoxRect.Bottom - 1));

  if IsItemChecked(AIndex) then
  begin
    LPoints[0] := Point(LBoxRect.Left + MulDiv(LSize, 3, 13), LBoxRect.Top + MulDiv(LSize, 6, 13));
    LPoints[1] := Point(LBoxRect.Left + MulDiv(LSize, 5, 13), LBoxRect.Top + MulDiv(LSize, 8, 13));
    LPoints[2] := Point(LBoxRect.Left + MulDiv(LSize, 10, 13), LBoxRect.Top + MulDiv(LSize, 3, 13));

    LCanvas.Pen.Color := SystemColor(TColors.SysWindowText);

    for var LOffset := 0 to Max(Scale(2), 2) - 1 do
    begin
      LCanvas.Polyline(LPoints);

      for var LIndex := Low(LPoints) to High(LPoints) do
        Inc(LPoints[LIndex].Y);
    end;
  end;
end;

procedure TDatabaseGridColumnFilterPopup.ValuesListKeyPress(ASender: TObject; var AKey: Char);
begin
  if AKey = ' ' then
  begin
    AKey := TControlCharacters.Null;

    ToggleItem(FValuesList.ItemIndex);
  end;
end;

procedure TDatabaseGridColumnFilterPopup.ValuesListMouseDown(ASender: TObject; AButton: TMouseButton; AShift: TShiftState;
  AX, AY: Integer);
var
  LIndex: Integer;
begin
  if AButton <> mbLeft then
    Exit;

  LIndex := FValuesList.ItemAtPos(Point(AX, AY), True);

  ToggleItem(LIndex);

  if LIndex > 0 then
  begin
    FDragging := True;
    FDragChecked := IsItemChecked(LIndex);
  end;
end;

procedure TDatabaseGridColumnFilterPopup.ValuesListMouseLeave(ASender: TObject);
begin
  FValuesList.ItemIndex := -1;
end;

procedure TDatabaseGridColumnFilterPopup.ValuesListMouseMove(ASender: TObject; AShift: TShiftState; AX, AY: Integer);
var
  LIndex: Integer;
begin
  LIndex := FValuesList.ItemAtPos(Point(AX, AY), True);

  if LIndex <> FValuesList.ItemIndex then
    FValuesList.ItemIndex := LIndex;

  if FDragging and (ssLeft in AShift) then
    SetItemChecked(LIndex, FDragChecked);
end;

procedure TDatabaseGridColumnFilterPopup.ValuesListMouseUp(ASender: TObject; AButton: TMouseButton; AShift: TShiftState;
  AX, AY: Integer);
begin
  FDragging := False;
end;

procedure TDatabaseGridColumnFilterPopup.WMActivate(var AMessage: TWMActivate);
begin
  if (AMessage.Active <> WA_INACTIVE) and Assigned(PopupParent) and PopupParent.HandleAllocated then
    SendMessage(PopupParent.Handle, WM_NCACTIVATE, WPARAM(True), -1);

  inherited;

  if (AMessage.Active = WA_INACTIVE) and Visible then
  begin
    FClosedByDeactivation := True;

    Close;
  end;
end;

procedure TDatabaseGridColumnFilterPopup.WMNCHitTest(var AMessage: TWMNCHitTest);
var
  LMargin: Integer;
  LPoint: TPoint;
begin
  inherited;

  if (AMessage.Result <> HTCLIENT) or not (cfoDropDownSizeable in FOptions) or not (cfoShowValueList in FOptions) then
    Exit;

  LMargin := Scale(TDatabaseGridSize.FilterPopupSizingMargin);
  LPoint := ScreenToClient(SmallPointToPoint(AMessage.Pos));

  if LPoint.Y < LMargin then
  begin
    if LPoint.X < LMargin then
      AMessage.Result := HTTOPLEFT
    else
    if LPoint.X >= ClientWidth - LMargin then
      AMessage.Result := HTTOPRIGHT
    else
      AMessage.Result := HTTOP;
  end
  else
  if LPoint.Y >= ClientHeight - LMargin then
  begin
    if LPoint.X < LMargin then
      AMessage.Result := HTBOTTOMLEFT
    else
    if LPoint.X >= ClientWidth - LMargin then
      AMessage.Result := HTBOTTOMRIGHT
    else
      AMessage.Result := HTBOTTOM;
  end
  else
  if LPoint.X < LMargin then
    AMessage.Result := HTLEFT
  else
  if LPoint.X >= ClientWidth - LMargin then
    AMessage.Result := HTRIGHT;
end;

{ TDatabaseGridColumnFilterDialog }

constructor TDatabaseGridColumnFilterDialog.CreateDialog(const AOwner: TComponent; const AColumn: TDatabaseGridColumn;
  const AFont: TFont);
var
  LButton: TDatabaseGridPopupButton;
  LLabel: TDatabaseGridPopupLabel;
  LScale: Single;
  LTop: Integer;

  function S(const AValue: Integer): Integer;
  begin
    Result := Round(AValue * LScale);
  end;

begin
  inherited CreateNew(AOwner);

  FColumn := AColumn;
  LScale := Screen.PixelsPerInch / USER_DEFAULT_SCREEN_DPI;

  BorderIcons := [biSystemMenu];
  BorderStyle := bsDialog;
  Caption := SDatabaseGridColumnFilterTitle;
  Font.Assign(AFont);
  Position := poScreenCenter;
  ClientWidth := S(340);
  ClientHeight := S(150);

  LLabel := TDatabaseGridPopupLabel.Create(Self);
  LLabel.Parent := Self;
  LLabel.Caption := Format(SDatabaseGridShowRowsWhere, [AColumn.Title.DisplayCaption]);
  LLabel.SetBounds(S(12), S(12), ClientWidth - S(24), S(16));

  LTop := S(34);

  FOperatorComboBox := TDatabaseGridPopupComboBox.Create(Self);
  FOperatorComboBox.Parent := Self;
  FOperatorComboBox.Style := csDropDownList;
  FOperatorComboBox.SetBounds(S(12), LTop, ClientWidth - S(24), S(23));
  FOperatorComboBox.OnChange := OperatorComboBoxChange;

  for var LIndex := Low(DIALOG_OPERATORS) to High(DIALOG_OPERATORS) do
    FOperatorComboBox.Items.Add(DatabaseGridFilterOperatorCaption(DIALOG_OPERATORS[LIndex]));

  Inc(LTop, S(32));

  FValueEdit := TDatabaseGridPopupEdit.Create(Self);
  FValueEdit.Parent := Self;
  FValueEdit.SetBounds(S(12), LTop, (ClientWidth - S(24) - S(40)) div 2, S(23));

  FAndLabel := TDatabaseGridPopupLabel.Create(Self);
  FAndLabel.Parent := Self;
  FAndLabel.Caption := '-';
  FAndLabel.Alignment := taCenter;
  FAndLabel.SetBounds(FValueEdit.Left + FValueEdit.Width, LTop + S(4), S(40), S(16));

  FValue2Edit := TDatabaseGridPopupEdit.Create(Self);
  FValue2Edit.Parent := Self;
  FValue2Edit.SetBounds(FAndLabel.Left + FAndLabel.Width, LTop, FValueEdit.Width, S(23));

  LButton := TDatabaseGridPopupButton.Create(Self);
  LButton.Parent := Self;
  LButton.Caption := SDatabaseGridOK;
  LButton.Default := True;
  LButton.ModalResult := mrOk;
  LButton.SetBounds(ClientWidth - S(12) - 2 * S(75) - S(6), ClientHeight - S(12) - S(25), S(75), S(25));

  LButton := TDatabaseGridPopupButton.Create(Self);
  LButton.Parent := Self;
  LButton.Caption := SDatabaseGridCancel;
  LButton.Cancel := True;
  LButton.ModalResult := mrCancel;
  LButton.SetBounds(ClientWidth - S(12) - S(75), ClientHeight - S(12) - S(25), S(75), S(25));

  FOperatorComboBox.ItemIndex := 0;

  for var LIndex := Low(DIALOG_OPERATORS) to High(DIALOG_OPERATORS) do
  if DIALOG_OPERATORS[LIndex] = AColumn.Filter.Operator then
  begin
    FOperatorComboBox.ItemIndex := LIndex;
    FValueEdit.Text := AColumn.Filter.Value;
    FValue2Edit.Text := AColumn.Filter.Value2;
  end;

  OperatorComboBoxChange(nil);

  ActiveControl := FValueEdit;
end;

function TDatabaseGridColumnFilterDialog.Execute: Boolean;
begin
  Result := ShowModal = mrOk;

  if Result then
    FColumn.Filter.SetCondition(GetOperator, FValueEdit.Text, FValue2Edit.Text);
end;

function TDatabaseGridColumnFilterDialog.GetOperator: TDatabaseGridColumnFilterOperator;
begin
  if FOperatorComboBox.ItemIndex >= 0 then
    Result := DIALOG_OPERATORS[FOperatorComboBox.ItemIndex]
  else
    Result := foNone;
end;

procedure TDatabaseGridColumnFilterDialog.OperatorComboBoxChange(ASender: TObject);
begin
  FValueEdit.Enabled := not (GetOperator in [foEmpty, foNotEmpty]);
  FValue2Edit.Visible := GetOperator = foBetween;
  FAndLabel.Visible := FValue2Edit.Visible;
end;

end.
