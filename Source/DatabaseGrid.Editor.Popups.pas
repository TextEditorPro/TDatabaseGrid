unit DatabaseGrid.Editor.Popups;

{$I DatabaseGrid.Defines.inc}

interface

uses
  Winapi.CommCtrl, Winapi.Messages, Winapi.Windows, System.Classes, System.Types, System.UITypes, Vcl.ComCtrls, Vcl.Controls, Vcl.Forms,
  Vcl.Graphics, Vcl.StdCtrls, DatabaseGrid.ColumnFilter.Popup, DatabaseGrid.PopupForm, DatabaseGrid.Types
{$IFDEF ALPHASKINS}
  , sMemo, sMonthCalendar, sSpinEdit
{$ENDIF};

type
{$IFDEF ALPHASKINS}
  TDatabaseGridPopupCalendar = TsMonthCalendar;
  TDatabaseGridPopupMemo = TsMemo;
  TDatabaseGridPopupTimePicker = TsTimePicker;
{$ELSE}
  TDatabaseGridPopupCalendar = TMonthCalendar;
  TDatabaseGridPopupMemo = TMemo;
  TDatabaseGridPopupTimePicker = TDateTimePicker;
{$ENDIF}

  TDatabaseGridDateTimeEvent = procedure(ASender: TObject; const AValue: TDateTime) of object;
  TDatabaseGridTextEvent = procedure(ASender: TObject; const AText: string) of object;

  TDatabaseGridDropDownList = class(TCustomControl)
  strict private
    FCellRect: TRect;
    FDropped: Boolean;
    FFilter: string;
    FItemHeight: Integer;
    FItemIndex: Integer;
    FItems: TStringList;
    FMatchBackground: TColor;
    FMaxRowCount: Integer;
    FOnAccept: TNotifyEvent;
    FTopIndex: Integer;
    FVisibleItems: TArray<Integer>;
    function GetItemAt(const AY: Integer): Integer;
    function GetSelectedItem: Integer;
    function GetVisibleRowCount: Integer;
    function SystemColor(const AColor: TColor): TColor;
    procedure SetItemIndex(const AValue: Integer);
    procedure UpdateBounds;
    procedure UpdateScrollBar;
    procedure WMMouseActivate(var AMessage: TWMMouseActivate); message WM_MOUSEACTIVATE;
    procedure WMVScroll(var AMessage: TWMScroll); message WM_VSCROLL;
  protected
    procedure CreateParams(var AParams: TCreateParams); override;
    procedure MouseMove(AShift: TShiftState; AX, AY: Integer); override;
    procedure MouseUp(AButton: TMouseButton; AShift: TShiftState; AX, AY: Integer); override;
    procedure Paint; override;
    procedure WndProc(var AMessage: TMessage); override;
  public
{$IFDEF DATABASE_GRID_VCL_STYLES}
    class constructor Create;
    class destructor Destroy;
{$ENDIF}
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure CloseUp;
    procedure DropDown(const ACellRect: TRect; const AMaxRowCount: Integer);
    procedure MoveSelection(const ADistance: Integer);
    procedure ScrollBy(const ARowCount: Integer);
    procedure SelectText(const AText: string);
    procedure SetFilter(const AText: string; const ASelectFirst: Boolean);
    property Dropped: Boolean read FDropped;
    property Font;
    property Items: TStringList read FItems;
    property MatchBackground: TColor read FMatchBackground write FMatchBackground;
    property OnAccept: TNotifyEvent read FOnAccept write FOnAccept;
    property SelectedItem: Integer read GetSelectedItem;
  end;

  TDatabaseGridEditorPopup = class(TDatabaseGridPopupForm)
  strict private
    FActivated: Boolean;
    FClosedByDeactivation: Boolean;
    FPixelsPerInch: Integer;
    procedure WMActivate(var AMessage: TWMActivate); message WM_ACTIVATE;
  protected
    function Scale(const AValue: Integer): Integer;
    procedure CreateParams(var AParams: TCreateParams); override;
    procedure DoClose(var AAction: TCloseAction); override;
  public
    constructor CreatePopup(const AOwner: TComponent; const AFont: TFont; const APixelsPerInch: Integer);
    procedure Popup(const ACellRect: TRect);
    property ClosedByDeactivation: Boolean read FClosedByDeactivation;
    property OnClose;
  end;

  TDatabaseGridMonthCalendar = class(TDatabaseGridPopupCalendar)
  strict private
{$IFDEF ALPHASKINS}
    FGridWindowProc: TWndMethod;
{$ENDIF}
    FOnDateDoubleClick: TNotifyEvent;
    FOnSelect: TNotifyEvent;
{$IFDEF ALPHASKINS}
    function GetDate: TDateTime;
    function TrySelectDateAt(const AX, AY: Integer): Boolean;
    procedure GridMouseUp(ASender: TObject; AButton: TMouseButton; AShift: TShiftState; AX, AY: Integer);
    procedure GridWindowProc(var AMessage: TMessage);
    procedure SetDate(const AValue: TDateTime);
{$ELSE}
    procedure CNNotify(var AMessage: TWMNotifyMC); message CN_NOTIFY;
    procedure WMLButtonDblClk(var AMessage: TWMLButtonDblClk); message WM_LBUTTONDBLCLK;
{$ENDIF}
  public
{$IFDEF ALPHASKINS}
    constructor Create(AOwner: TComponent); override;
    property Date: TDateTime read GetDate write SetDate;
{$ENDIF}
    property OnDateDoubleClick: TNotifyEvent read FOnDateDoubleClick write FOnDateDoubleClick;
    property OnSelect: TNotifyEvent read FOnSelect write FOnSelect;
  end;

  TDatabaseGridCalendarPopup = class(TDatabaseGridEditorPopup)
  strict private
    FCalendar: TDatabaseGridMonthCalendar;
    FKind: TDatabaseGridEditorKind;
    FOKButton: TDatabaseGridPopupButton;
    FOnAccept: TDatabaseGridDateTimeEvent;
    FTimePicker: TDatabaseGridPopupTimePicker;
    function GetValue: TDateTime;
    procedure Accept;
    procedure CalendarDateDoubleClick(ASender: TObject);
    procedure CalendarSelect(ASender: TObject);
    procedure FormKeyDown(ASender: TObject; var AKey: Word; AShift: TShiftState);
    procedure OKButtonClick(ASender: TObject);
  public
    constructor CreateCalendar(const AOwner: TComponent; const AFont: TFont; const APixelsPerInch: Integer; const AKind: TDatabaseGridEditorKind; const AValue: TDateTime);
    property OnAccept: TDatabaseGridDateTimeEvent read FOnAccept write FOnAccept;
  end;

  TDatabaseGridMemoPopup = class(TDatabaseGridEditorPopup)
  strict private
    FCancelButton: TDatabaseGridPopupButton;
    FMemo: TDatabaseGridPopupMemo;
    FOKButton: TDatabaseGridPopupButton;
    FOnAccept: TDatabaseGridTextEvent;
    procedure Accept;
    procedure ButtonClick(ASender: TObject);
    procedure FormKeyDown(ASender: TObject; var AKey: Word; AShift: TShiftState);
  public
    constructor CreateMemo(const AOwner: TComponent; const AFont: TFont; const APixelsPerInch: Integer; const AText: string;
      const AMinWidth: Integer);
    property OnAccept: TDatabaseGridTextEvent read FOnAccept write FOnAccept;
  end;

implementation

uses
  System.Math, System.SysUtils, DatabaseGrid.Consts, DatabaseGrid.Language
{$IFDEF DATABASE_GRID_VCL_STYLES}
  , Vcl.Themes, DatabaseGrid.StyleHooks
{$ENDIF};

{ TDatabaseGridDropDownList }

{$IFDEF DATABASE_GRID_VCL_STYLES}
class constructor TDatabaseGridDropDownList.Create;
begin
  TCustomStyleEngine.RegisterStyleHook(TDatabaseGridDropDownList, TVclStyleScrollBarsHook);
end;

class destructor TDatabaseGridDropDownList.Destroy;
begin
  TCustomStyleEngine.UnRegisterStyleHook(TDatabaseGridDropDownList, TVclStyleScrollBarsHook);
end;
{$ENDIF}

constructor TDatabaseGridDropDownList.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);

  ControlStyle := ControlStyle + [csOpaque];
  DoubleBuffered := True;
  Visible := False;

  FItems := TStringList.Create;
  FItemIndex := -1;
  FMatchBackground := TDatabaseGridColor.SearchMatchBackground;
end;

destructor TDatabaseGridDropDownList.Destroy;
begin
  FItems.Free;

  inherited Destroy;
end;

function TDatabaseGridDropDownList.GetItemAt(const AY: Integer): Integer;
begin
  Result := FTopIndex + AY div Max(FItemHeight, 1);

  if (AY < 0) or (Result >= Length(FVisibleItems)) then
    Result := -1;
end;

function TDatabaseGridDropDownList.GetSelectedItem: Integer;
begin
  if (FItemIndex >= 0) and (FItemIndex < Length(FVisibleItems)) then
    Result := FVisibleItems[FItemIndex]
  else
    Result := -1;
end;

function TDatabaseGridDropDownList.GetVisibleRowCount: Integer;
begin
  Result := Max(ClientHeight div Max(FItemHeight, 1), 1);
end;

procedure TDatabaseGridDropDownList.CreateParams(var AParams: TCreateParams);
begin
  inherited CreateParams(AParams);

  AParams.Style := WS_POPUP or WS_BORDER or WS_VSCROLL;
  AParams.ExStyle := WS_EX_TOOLWINDOW or WS_EX_NOACTIVATE;
  AParams.WindowClass.Style := AParams.WindowClass.Style or CS_SAVEBITS or CS_DROPSHADOW;
end;

procedure TDatabaseGridDropDownList.CloseUp;
begin
  if not FDropped then
    Exit;

  FDropped := False;

  if HandleAllocated then
    SetWindowPos(Handle, 0, 0, 0, 0, 0, SWP_NOZORDER or SWP_NOMOVE or SWP_NOSIZE or SWP_NOACTIVATE or SWP_HIDEWINDOW);
end;

procedure TDatabaseGridDropDownList.DropDown(const ACellRect: TRect; const AMaxRowCount: Integer);
var
  LTextHeight: Integer;
begin
  FCellRect := ACellRect;
  FMaxRowCount := AMaxRowCount;

  HandleNeeded;

  Canvas.Font := Font;
  LTextHeight := Canvas.TextHeight('Wg');
  FItemHeight := LTextHeight + Max(LTextHeight div 4, 2);
  FDropped := True;

  UpdateBounds;
end;

procedure TDatabaseGridDropDownList.MoveSelection(const ADistance: Integer);
var
  LCount: Integer;
begin
  LCount := Length(FVisibleItems);

  if LCount = 0 then
    Exit;

  if FItemIndex < 0 then
    SetItemIndex(if ADistance > 0 then 0 else LCount - 1)
  else
    SetItemIndex(EnsureRange(FItemIndex + ADistance, 0, LCount - 1));
end;

procedure TDatabaseGridDropDownList.MouseMove(AShift: TShiftState; AX, AY: Integer);
var
  LIndex: Integer;
begin
  inherited MouseMove(AShift, AX, AY);

  LIndex := GetItemAt(AY);

  if (LIndex >= 0) and (LIndex <> FItemIndex) then
  begin
    FItemIndex := LIndex;

    Invalidate;
  end;
end;

procedure TDatabaseGridDropDownList.MouseUp(AButton: TMouseButton; AShift: TShiftState; AX, AY: Integer);
var
  LIndex: Integer;
begin
  inherited MouseUp(AButton, AShift, AX, AY);

  LIndex := GetItemAt(AY);

  if (AButton = mbLeft) and (LIndex >= 0) then
  begin
    FItemIndex := LIndex;

    if Assigned(FOnAccept) then
      FOnAccept(Self);
  end;
end;

procedure TDatabaseGridDropDownList.Paint;
var
  LMatchPosition, LPadding, LTop: Integer;
  LRect: TRect;
  LText: string;
begin
  Canvas.Font := Font;
  LPadding := Canvas.TextWidth('0') div 2 + 2;

  for var LRow := 0 to GetVisibleRowCount do
  begin
    LTop := LRow * FItemHeight;
    LRect := Rect(0, LTop, ClientWidth, LTop + FItemHeight);

    if FTopIndex + LRow >= Length(FVisibleItems) then
    begin
      Canvas.Brush.Color := SystemColor(TColors.SysWindow);
      Canvas.FillRect(Rect(0, LTop, ClientWidth, ClientHeight));

      Break;
    end;

    LText := FItems[FVisibleItems[FTopIndex + LRow]];

    if FTopIndex + LRow = FItemIndex then
    begin
      Canvas.Brush.Color := SystemColor(TColors.SysHighlight);
      Canvas.Font.Color := SystemColor(TColors.SysHighlightText);
    end
    else
    begin
      Canvas.Brush.Color := SystemColor(TColors.SysWindow);
      Canvas.Font.Color := SystemColor(TColors.SysWindowText);
    end;

    Canvas.FillRect(LRect);

    LMatchPosition := if FFilter.IsEmpty then 0 else Pos(FFilter, AnsiUpperCase(LText));

    if (LMatchPosition > 0) and (FTopIndex + LRow <> FItemIndex) then
    begin
      Canvas.Brush.Color := FMatchBackground;
      Canvas.FillRect(Rect(LPadding + Canvas.TextWidth(Copy(LText, 1, LMatchPosition - 1)), LTop + 1,
        LPadding + Canvas.TextWidth(Copy(LText, 1, LMatchPosition + Length(FFilter) - 1)), LTop + FItemHeight - 1));
    end;

    Canvas.Brush.Style := bsClear;
    Canvas.TextRect(LRect, LPadding, LTop + (FItemHeight - Canvas.TextHeight(LText)) div 2, LText);
    Canvas.Brush.Style := bsSolid;
  end;
end;

procedure TDatabaseGridDropDownList.ScrollBy(const ARowCount: Integer);
begin
  FTopIndex := EnsureRange(FTopIndex + ARowCount, 0, Max(Length(FVisibleItems) - GetVisibleRowCount, 0));

  UpdateScrollBar;
  Invalidate;
end;

procedure TDatabaseGridDropDownList.SelectText(const AText: string);
begin
  for var LIndex := 0 to High(FVisibleItems) do
  if SameText(FItems[FVisibleItems[LIndex]], AText) then
  begin
    SetItemIndex(LIndex);

    Exit;
  end;
end;

procedure TDatabaseGridDropDownList.SetFilter(const AText: string; const ASelectFirst: Boolean);
begin
  FFilter := AnsiUpperCase(AText);
  FVisibleItems := nil;

  for var LIndex := 0 to FItems.Count - 1 do
  if FFilter.IsEmpty or AnsiUpperCase(FItems[LIndex]).Contains(FFilter) then
    FVisibleItems := FVisibleItems + [LIndex];

  FTopIndex := 0;
  FItemIndex := if ASelectFirst and (Length(FVisibleItems) > 0) then 0 else -1;

  if FDropped then
    UpdateBounds;
end;

procedure TDatabaseGridDropDownList.SetItemIndex(const AValue: Integer);
begin
  FItemIndex := AValue;

  if FItemIndex >= 0 then
  begin
    if FItemIndex < FTopIndex then
      FTopIndex := FItemIndex
    else
    if FItemIndex >= FTopIndex + GetVisibleRowCount then
      FTopIndex := FItemIndex - GetVisibleRowCount + 1;
  end;

  UpdateScrollBar;
  Invalidate;
end;

procedure TDatabaseGridDropDownList.UpdateBounds;
var
  LHeight, LLeft, LTop, LWidth: Integer;
  LWorkArea: TRect;
begin
  if not FDropped then
    Exit;

  LWorkArea := Screen.MonitorFromRect(FCellRect).WorkareaRect;
  LWidth := FCellRect.Width;

  Canvas.Font := Font;

  for var LIndex := 0 to FItems.Count - 1 do
    LWidth := Max(LWidth, Canvas.TextWidth(FItems[LIndex]) + Canvas.TextWidth('0') + 4 + GetSystemMetrics(SM_CXVSCROLL) + 2);

  LWidth := Min(LWidth, LWorkArea.Width div 2);
  LHeight := EnsureRange(Length(FVisibleItems), 1, FMaxRowCount) * FItemHeight + 2;
  LLeft := Max(Min(FCellRect.Left, LWorkArea.Right - LWidth), LWorkArea.Left);
  LTop := FCellRect.Bottom;

  if LTop + LHeight > LWorkArea.Bottom then
    LTop := Max(FCellRect.Top - LHeight, LWorkArea.Top);

  SetWindowPos(Handle, HWND_TOP, LLeft, LTop, LWidth, LHeight, SWP_NOACTIVATE or SWP_SHOWWINDOW);

  if FItemIndex >= 0 then
    SetItemIndex(FItemIndex)
  else
    UpdateScrollBar;

  Invalidate;
end;

procedure TDatabaseGridDropDownList.UpdateScrollBar;
var
  LScrollInfo: TScrollInfo;
begin
  if not HandleAllocated then
    Exit;

  LScrollInfo.cbSize := SizeOf(TScrollInfo);
  LScrollInfo.fMask := SIF_ALL;
  LScrollInfo.nMin := 0;
  LScrollInfo.nMax := Max(Length(FVisibleItems) - 1, 0);
  LScrollInfo.nPage := GetVisibleRowCount;
  LScrollInfo.nPos := FTopIndex;
  LScrollInfo.nTrackPos := 0;

  SetScrollInfo(Handle, SB_VERT, LScrollInfo, True);
end;

procedure TDatabaseGridDropDownList.WMMouseActivate(var AMessage: TWMMouseActivate);
begin
  AMessage.Result := MA_NOACTIVATE;
end;

procedure TDatabaseGridDropDownList.WMVScroll(var AMessage: TWMScroll);
begin
  AMessage.Result := 0;

  case AMessage.ScrollCode of
    SB_LINEUP:
      ScrollBy(-1);
    SB_LINEDOWN:
      ScrollBy(1);
    SB_PAGEUP:
      ScrollBy(-GetVisibleRowCount);
    SB_PAGEDOWN:
      ScrollBy(GetVisibleRowCount);
    SB_THUMBPOSITION, SB_THUMBTRACK:
      ScrollBy(AMessage.Pos - FTopIndex);
  end;
end;

function TDatabaseGridDropDownList.SystemColor(const AColor: TColor): TColor;
begin
  Result := GetDatabaseGridSystemColor(AColor);
end;

procedure TDatabaseGridDropDownList.WndProc(var AMessage: TMessage);
begin
  inherited WndProc(AMessage);

  if ((AMessage.Msg = WM_NCPAINT) or (AMessage.Msg = WM_NCACTIVATE)) and HandleAllocated then
    PaintDatabaseGridStyledBorder(Handle);
end;

{ TDatabaseGridEditorPopup }

constructor TDatabaseGridEditorPopup.CreatePopup(const AOwner: TComponent; const AFont: TFont; const APixelsPerInch: Integer);
begin
  inherited CreateNew(AOwner);

  FPixelsPerInch := APixelsPerInch;

  Font.Assign(AFont);
end;

function TDatabaseGridEditorPopup.Scale(const AValue: Integer): Integer;
begin
  Result := MulDiv(AValue, FPixelsPerInch, USER_DEFAULT_SCREEN_DPI);
end;

procedure TDatabaseGridEditorPopup.CreateParams(var AParams: TCreateParams);
begin
  inherited CreateParams(AParams);

  AParams.Style := (AParams.Style and not WS_CHILD) or WS_POPUP or WS_BORDER;
  AParams.ExStyle := AParams.ExStyle or WS_EX_TOOLWINDOW or WS_EX_TOPMOST;
  AParams.WindowClass.Style := AParams.WindowClass.Style or CS_DROPSHADOW;
end;

procedure TDatabaseGridEditorPopup.DoClose(var AAction: TCloseAction);
begin
  inherited DoClose(AAction);

  AAction := caFree;
end;

procedure TDatabaseGridEditorPopup.Popup(const ACellRect: TRect);
var
  LLeft, LTop: Integer;
  LWorkArea: TRect;
begin
  LWorkArea := Screen.MonitorFromRect(ACellRect).WorkareaRect;
  LLeft := Max(Min(ACellRect.Left, LWorkArea.Right - Width), LWorkArea.Left);
  LTop := ACellRect.Bottom;

  if LTop + Height > LWorkArea.Bottom then
    LTop := Max(ACellRect.Top - Height, LWorkArea.Top);

  SetBounds(LLeft, LTop, Width, Height);

  Show;
end;

procedure TDatabaseGridEditorPopup.WMActivate(var AMessage: TWMActivate);
begin
  if (AMessage.Active <> WA_INACTIVE) and Assigned(PopupParent) and PopupParent.HandleAllocated then
    SendMessage(PopupParent.Handle, WM_NCACTIVATE, WPARAM(True), -1);

  inherited;

  if AMessage.Active <> WA_INACTIVE then
    FActivated := True
  else
  if FActivated and Visible then
  begin
    FClosedByDeactivation := True;

    Close;
  end;
end;

{ TDatabaseGridMonthCalendar }

{$IFDEF ALPHASKINS}
constructor TDatabaseGridMonthCalendar.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);

  FGrid.OnMouseUp := GridMouseUp;
  FGridWindowProc := FGrid.WindowProc;
  FGrid.WindowProc := GridWindowProc;
end;

function TDatabaseGridMonthCalendar.GetDate: TDateTime;
begin
  Result := CalendarDate;
end;

function TDatabaseGridMonthCalendar.TrySelectDateAt(const AX, AY: Integer): Boolean;
var
  LColumn, LRow: Integer;
begin
  FGrid.MouseToCell(AX, AY, LColumn, LRow);

  if (LRow < 1) or (LRow > 6) or ShowWeeks and (LColumn < 1) or not IsValidDate(CellDate[LColumn, LRow]) then
    Exit(False);

  CalendarDate := CellDate[LColumn, LRow];

  Result := True;
end;

procedure TDatabaseGridMonthCalendar.GridWindowProc(var AMessage: TMessage);
begin
  FGridWindowProc(AMessage);

  if (AMessage.Msg = WM_LBUTTONDBLCLK) and TrySelectDateAt(TWMMouse(AMessage).XPos, TWMMouse(AMessage).YPos) and
    Assigned(FOnDateDoubleClick) then
    FOnDateDoubleClick(Self);
end;

procedure TDatabaseGridMonthCalendar.GridMouseUp(ASender: TObject; AButton: TMouseButton; AShift: TShiftState; AX, AY: Integer);
begin
  if (AButton = mbLeft) and TrySelectDateAt(AX, AY) and Assigned(FOnSelect) then
    FOnSelect(Self);
end;

procedure TDatabaseGridMonthCalendar.SetDate(const AValue: TDateTime);
begin
  CalendarDate := AValue;
end;
{$ELSE}
procedure TDatabaseGridMonthCalendar.CNNotify(var AMessage: TWMNotifyMC);
begin
  inherited;

  if (AMessage.NMHdr.code = MCN_SELECT) and Assigned(FOnSelect) then
    FOnSelect(Self);
end;

procedure TDatabaseGridMonthCalendar.WMLButtonDblClk(var AMessage: TWMLButtonDblClk);
var
  LHitTest: TMCHitTestInfo;
begin
  inherited;

  LHitTest := Default(TMCHitTestInfo);
  LHitTest.cbSize := SizeOf(LHitTest);
  LHitTest.pt := Point(AMessage.XPos, AMessage.YPos);

  Perform(MCM_HITTEST, 0, LPARAM(@LHitTest));

  if (LHitTest.uHit and MCHT_CALENDARDATE = MCHT_CALENDARDATE) and Assigned(FOnDateDoubleClick) then
    FOnDateDoubleClick(Self);
end;
{$ENDIF}

{ TDatabaseGridCalendarPopup }

constructor TDatabaseGridCalendarPopup.CreateCalendar(const AOwner: TComponent; const AFont: TFont; const APixelsPerInch: Integer;
  const AKind: TDatabaseGridEditorKind; const AValue: TDateTime);
var
  LButtonWidth, LMargin, LTop, LWidth: Integer;
begin
  inherited CreatePopup(AOwner, AFont, APixelsPerInch);

  FKind := AKind;
  OnKeyDown := FormKeyDown;

  LMargin := Scale(6);
  LTop := 0;
  LWidth := 0;

  if FKind <> ekTime then
  begin
    FCalendar := TDatabaseGridMonthCalendar.Create(Self);
    FCalendar.Parent := Self;
{$IFNDEF ALPHASKINS}
    FCalendar.HandleNeeded;
    FCalendar.AutoSize := True;
    FCalendar.Left := -1;
    FCalendar.Top := -1;
{$ENDIF}
    FCalendar.OnDateDoubleClick := CalendarDateDoubleClick;
    FCalendar.OnSelect := CalendarSelect;
    FCalendar.Date := if AValue = 0 then System.SysUtils.Date else Trunc(AValue);

{$IFDEF ALPHASKINS}
    FCalendar.SetBounds(0, 0, Scale(FCalendar.Width), Scale(FCalendar.Height));

    LTop := FCalendar.Height;
    LWidth := FCalendar.Width;
{$ELSE}
    LTop := FCalendar.Height - 2;
    LWidth := FCalendar.Width - 2;
{$ENDIF}

    ActiveControl := FCalendar;
  end;

  if FKind in [ekDateTime, ekTime] then
  begin
    LButtonWidth := Scale(64);
    LWidth := Max(LWidth, Scale(80) + LButtonWidth + 3 * LMargin);
    LTop := LTop + LMargin;

    FTimePicker := TDatabaseGridPopupTimePicker.Create(Self);
    FTimePicker.Parent := Self;
{$IFNDEF ALPHASKINS}
    FTimePicker.Kind := dtkTime;
{$ENDIF}
    FTimePicker.Time := Frac(AValue);
    FTimePicker.SetBounds(LMargin, LTop, LWidth - LButtonWidth - 3 * LMargin, Scale(23));

    FOKButton := TDatabaseGridPopupButton.Create(Self);
    FOKButton.Parent := Self;
    FOKButton.Caption := SDatabaseGridOK;
    FOKButton.SetBounds(LWidth - LMargin - LButtonWidth, LTop, LButtonWidth, Scale(25));
    FOKButton.OnClick := OKButtonClick;

    LTop := LTop + FOKButton.Height + LMargin;

    if not Assigned(FCalendar) then
      ActiveControl := FTimePicker;
  end;

  ClientWidth := LWidth;
  ClientHeight := LTop;
end;

function TDatabaseGridCalendarPopup.GetValue: TDateTime;
begin
  Result := 0;

  if Assigned(FCalendar) then
    Result := Trunc(FCalendar.Date);

  if Assigned(FTimePicker) then
    Result := Result + Frac(FTimePicker.Time);
end;

procedure TDatabaseGridCalendarPopup.Accept;
begin
  if Assigned(FOnAccept) then
    FOnAccept(Self, GetValue);

  Close;
end;

procedure TDatabaseGridCalendarPopup.CalendarDateDoubleClick(ASender: TObject);
begin
  Accept;
end;

procedure TDatabaseGridCalendarPopup.CalendarSelect(ASender: TObject);
begin
  if FKind = ekDate then
    Accept;
end;

procedure TDatabaseGridCalendarPopup.FormKeyDown(ASender: TObject; var AKey: Word; AShift: TShiftState);
begin
  case AKey of
    vkEscape:
      begin
        AKey := 0;

        Close;
      end;
    vkReturn:
      begin
        AKey := 0;

        Accept;
      end;
  end;
end;

procedure TDatabaseGridCalendarPopup.OKButtonClick(ASender: TObject);
begin
  Accept;
end;

{ TDatabaseGridMemoPopup }

constructor TDatabaseGridMemoPopup.CreateMemo(const AOwner: TComponent; const AFont: TFont; const APixelsPerInch: Integer;
  const AText: string; const AMinWidth: Integer);
var
  LButtonHeight, LButtonWidth, LMargin: Integer;
begin
  inherited CreatePopup(AOwner, AFont, APixelsPerInch);

  OnKeyDown := FormKeyDown;

  LMargin := Scale(6);
  LButtonHeight := Scale(25);
  LButtonWidth := Scale(75);

  ClientWidth := Max(Scale(420), AMinWidth);
  ClientHeight := Scale(240);

  FMemo := TDatabaseGridPopupMemo.Create(Self);
  FMemo.Parent := Self;
  FMemo.SetBounds(LMargin, LMargin, ClientWidth - 2 * LMargin, ClientHeight - 3 * LMargin - LButtonHeight);
  FMemo.ScrollBars := ssVertical;
  FMemo.Text := AText;

  FCancelButton := TDatabaseGridPopupButton.Create(Self);
  FCancelButton.Parent := Self;
  FCancelButton.Caption := SDatabaseGridCancel;
  FCancelButton.SetBounds(ClientWidth - LMargin - LButtonWidth, ClientHeight - LMargin - LButtonHeight, LButtonWidth, LButtonHeight);
  FCancelButton.OnClick := ButtonClick;

  FOKButton := TDatabaseGridPopupButton.Create(Self);
  FOKButton.Parent := Self;
  FOKButton.Caption := SDatabaseGridOK;
  FOKButton.SetBounds(FCancelButton.Left - LMargin - LButtonWidth, FCancelButton.Top, LButtonWidth, LButtonHeight);
  FOKButton.OnClick := ButtonClick;

  ActiveControl := FMemo;
end;

procedure TDatabaseGridMemoPopup.Accept;
begin
  if Assigned(FOnAccept) then
    FOnAccept(Self, FMemo.Text);

  Close;
end;

procedure TDatabaseGridMemoPopup.ButtonClick(ASender: TObject);
begin
  if ASender = FOKButton then
    Accept
  else
    Close;
end;

procedure TDatabaseGridMemoPopup.FormKeyDown(ASender: TObject; var AKey: Word; AShift: TShiftState);
begin
  if AKey = vkEscape then
  begin
    AKey := 0;

    Close;
  end
  else
  if (AKey = vkReturn) and (AShift = [ssCtrl]) then
  begin
    AKey := 0;

    Accept;
  end;
end;

end.
