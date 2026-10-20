unit DatabaseGrid.SearchPanel.Controls;

{$I DatabaseGrid.Defines.inc}

interface

uses
  Winapi.Messages, Winapi.Windows, System.Classes, System.Generics.Collections, System.Types, System.UITypes, Vcl.Controls, Vcl.ExtCtrls,
  Vcl.Graphics, Vcl.StdCtrls, DatabaseGrid.Colors, DatabaseGrid.SearchPanel, DatabaseGrid.Types
{$IFDEF ALPHASKINS}
  , sComboBox, sEdit
{$ENDIF};

type
{$IFDEF ALPHASKINS}
  TDatabaseGridSearchPanelComboBox = class(TsComboBox)
  strict private
    FCustomBackground: TColor;
    FCustomForeground: TColor;
    procedure SetCustomBackground(const AValue: TColor);
    procedure SetCustomForeground(const AValue: TColor);
  protected
    procedure CloseUp; override;
  public
    constructor Create(AOwner: TComponent); override;
    procedure DoDropDown; override;
    property CustomBackground: TColor read FCustomBackground write SetCustomBackground;
    property CustomForeground: TColor read FCustomForeground write SetCustomForeground;
  end;

  TDatabaseGridSearchPanelEdit = class(TsEdit)
  strict private
    FCustomBackground: TColor;
    FCustomForeground: TColor;
    procedure SetCustomBackground(const AValue: TColor);
    procedure SetCustomForeground(const AValue: TColor);
  public
    constructor Create(AOwner: TComponent); override;
    property CustomBackground: TColor read FCustomBackground write SetCustomBackground;
    property CustomForeground: TColor read FCustomForeground write SetCustomForeground;
  end;
{$ELSE}
  TDatabaseGridSearchPanelComboBox = class(TComboBox)
  strict private
    FBorderColor: TColor;
    FCustomBackground: TColor;
    FCustomBrush: TBrush;
    FCustomForeground: TColor;
    procedure SetBorderColor(const AValue: TColor);
    procedure SetCustomBackground(const AValue: TColor);
    procedure SetCustomForeground(const AValue: TColor);
    procedure WMPaint(var AMessage: TWMPaint); message WM_PAINT;
  protected
    procedure WndProc(var AMessage: TMessage); override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    property BorderColor: TColor read FBorderColor write SetBorderColor;
    property CustomBackground: TColor read FCustomBackground write SetCustomBackground;
    property CustomForeground: TColor read FCustomForeground write SetCustomForeground;
  end;

  TDatabaseGridSearchPanelEdit = class(TEdit)
  strict private
    FBorderColor: TColor;
    FCustomBackground: TColor;
    FCustomBrush: TBrush;
    FCustomForeground: TColor;
    function HasThemedBorder: Boolean;
    procedure RedrawBorder;
    procedure SetBorderColor(const AValue: TColor);
    procedure SetCustomBackground(const AValue: TColor);
    procedure SetCustomForeground(const AValue: TColor);
    procedure WMKillFocus(var AMessage: TWMKillFocus); message WM_KILLFOCUS;
    procedure WMNCCalcSize(var AMessage: TWMNCCalcSize); message WM_NCCALCSIZE;
    procedure WMNCPaint(var AMessage: TWMNCPaint); message WM_NCPAINT;
    procedure WMSetFocus(var AMessage: TWMSetFocus); message WM_SETFOCUS;
  protected
    procedure CreateWnd; override;
    procedure WndProc(var AMessage: TMessage); override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    property BorderColor: TColor read FBorderColor write SetBorderColor;
    property CustomBackground: TColor read FCustomBackground write SetCustomBackground;
    property CustomForeground: TColor read FCustomForeground write SetCustomForeground;
  end;
{$ENDIF}

  TDatabaseGridSearchPanelButton = class(TCustomControl)
  strict private
    FGlyph: TDatabaseGridGlyph;
    FGlyphColor: TColor;
    FMouseInside: Boolean;
    FPressed: Boolean;
    procedure CMEnabledChanged(var AMessage: TMessage); message CM_ENABLEDCHANGED;
    procedure CMMouseEnter(var AMessage: TMessage); message CM_MOUSEENTER;
    procedure CMMouseLeave(var AMessage: TMessage); message CM_MOUSELEAVE;
    procedure PaintGlyph(const ACanvas: TCanvas);
    procedure SetGlyph(const AValue: TDatabaseGridGlyph);
    procedure SetGlyphColor(const AValue: TColor);
    procedure WMEraseBkgnd(var AMessage: TWMEraseBkgnd); message WM_ERASEBKGND;
  protected
    procedure MouseDown(AButton: TMouseButton; AShift: TShiftState; AX, AY: Integer); override;
    procedure MouseUp(AButton: TMouseButton; AShift: TShiftState; AX, AY: Integer); override;
    procedure Paint; override;
  public
    constructor Create(AOwner: TComponent); override;
    property Glyph: TDatabaseGridGlyph read FGlyph write SetGlyph;
    property GlyphColor: TColor read FGlyphColor write SetGlyphColor;
  end;

  TDatabaseGridSearchPanelControls = class(TObject)
  strict private
    FAppliedText: string;
    FColors: TDatabaseGridColors;
    FComboBoxes: TList<TDatabaseGridSearchPanelComboBox>;
    FEdit: TDatabaseGridSearchPanelEdit;
    FFilterButton: TDatabaseGridSearchPanelButton;
    FFocusedWindow: HWND;
    FOnApplyFilter: TNotifyEvent;
    FOnRefresh: TNotifyEvent;
    FParent: TWinControl;
    FRect: TRect;
    FRedrawPosted: Boolean;
    FRefreshButton: TDatabaseGridSearchPanelButton;
    FSearchPanel: TDatabaseGridSearchPanel;
    FTimer: TTimer;
    FUpdating: Boolean;
    function CreateButton(const AGlyph: TDatabaseGridGlyph; const AOnClick: TNotifyEvent): TDatabaseGridSearchPanelButton;
    function GetBackgroundColor: TColor;
    function GetComboBoxItem(const AComboBox: TObject): TDatabaseGridSearchPanelItem;
    function GetControlBounds: TArray<TRect>;
    function GetControls: TArray<TWinControl>;
    function HasFocus(const AControl: TWinControl): Boolean;
    function HasSomethingToClear: Boolean;
    function IsControlWindow(const AWindow: HWND): Boolean;
    function SameControlBounds(const ABounds, AOtherBounds: TArray<TRect>): Boolean;
    procedure AcceptItem(const AItem: TDatabaseGridSearchPanelItem);
    procedure ApplyFilter;
    procedure ComboBoxChange(ASender: TObject);
    procedure ComboBoxCloseUp(ASender: TObject);
    procedure ComboBoxExit(ASender: TObject);
    procedure ComboBoxKeyDown(ASender: TObject; var AKey: Word; AShift: TShiftState);
    procedure ComboBoxKeyPress(ASender: TObject; var AKey: Char);
    procedure CreateControls;
    procedure EditChange(ASender: TObject);
    procedure EditKeyDown(ASender: TObject; var AKey: Word; AShift: TShiftState);
    procedure EditKeyPress(ASender: TObject; var AKey: Char);
    procedure FilterButtonClick(ASender: TObject);
    procedure RedrawControls(const AFlags: UINT);
    procedure RefreshButtonClick(ASender: TObject);
    procedure ResetItems;
    procedure SetAppliedText(const AValue: string);
    procedure SynchronizeComboBoxes;
    procedure TimerTimer(ASender: TObject);
    procedure UpdateComboBoxColors(const AIndex: Integer);
    procedure UpdateControlColors;
    procedure UpdateEditColors;
    procedure UpdateFilterButton;
  public
    constructor Create(const AParent: TWinControl; const ASearchPanel: TDatabaseGridSearchPanel; const AColors: TDatabaseGridColors);
    destructor Destroy; override;
    function GetFocusedControl: TWinControl;
    function HandleFocusNotification(const AWindow: HWND; const ANotifyCode: Word): Boolean;
    function IsHighlighted: Boolean;
    procedure BeginSearch(const AText: string);
    procedure Realign(const ARect: TRect; const AControlHeight, APixelsPerInch: Integer);
    procedure Redraw;
    procedure Synchronize;
    property AppliedText: string read FAppliedText write SetAppliedText;
    property OnApplyFilter: TNotifyEvent read FOnApplyFilter write FOnApplyFilter;
    property OnRefresh: TNotifyEvent read FOnRefresh write FOnRefresh;
    property Updating: Boolean read FUpdating;
  end;

implementation

uses
  Winapi.GDIPAPI, Winapi.GDIPOBJ, Winapi.UxTheme, System.Math, System.SysUtils, Vcl.Forms, Vcl.Themes, DatabaseGrid.Consts,
  DatabaseGrid.Glyphs, DatabaseGrid.Language
{$IFDEF ALPHASKINS}
  , sCommonData, sVCLUtils
{$ENDIF};

{$IFDEF ALPHASKINS}
type
  TDatabaseGridWinControlAccess = class(TWinControl);

procedure SetSkinCustomColors(const AControl: TWinControl; const ASkinData: TsCommonData; const ABackground, AForeground: TColor);
begin
  ASkinData.CustomColor := ABackground <> TColors.SysNone;
  ASkinData.CustomFont := AForeground <> TColors.SysNone;

  if ASkinData.CustomColor then
    TDatabaseGridWinControlAccess(AControl).Color := ABackground
  else
  if not ASkinData.Skinned then
    TDatabaseGridWinControlAccess(AControl).Color := TColors.SysWindow;

  if not ASkinData.CustomFont then
  begin
    if not ASkinData.Skinned then
      TDatabaseGridWinControlAccess(AControl).Font.Color := TColors.SysWindowText;
  end
  else
  if (AForeground = TColors.SysGrayText) and ASkinData.Skinned then
    TDatabaseGridWinControlAccess(AControl).Font.Color := TextHintColor(ASkinData, 0, False)
  else
    TDatabaseGridWinControlAccess(AControl).Font.Color := AForeground;
end;

{ TDatabaseGridSearchPanelComboBox }

constructor TDatabaseGridSearchPanelComboBox.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);

  FCustomBackground := TColors.SysNone;
  FCustomForeground := TColors.SysNone;
end;

procedure TDatabaseGridSearchPanelComboBox.CloseUp;
begin
  inherited CloseUp;

  SetSkinCustomColors(Self, SkinData, FCustomBackground, FCustomForeground);
end;

procedure TDatabaseGridSearchPanelComboBox.DoDropDown;
begin
  SetSkinCustomColors(Self, SkinData, TColors.SysNone, TColors.SysNone);

  inherited DoDropDown;
end;

procedure TDatabaseGridSearchPanelComboBox.SetCustomBackground(const AValue: TColor);
begin
  FCustomBackground := AValue;

  if not DroppedDown then
    SetSkinCustomColors(Self, SkinData, FCustomBackground, FCustomForeground);
end;

procedure TDatabaseGridSearchPanelComboBox.SetCustomForeground(const AValue: TColor);
begin
  FCustomForeground := AValue;

  if not DroppedDown then
    SetSkinCustomColors(Self, SkinData, FCustomBackground, FCustomForeground);
end;

{ TDatabaseGridSearchPanelEdit }

constructor TDatabaseGridSearchPanelEdit.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);

  FCustomBackground := TColors.SysNone;
  FCustomForeground := TColors.SysNone;
end;

procedure TDatabaseGridSearchPanelEdit.SetCustomBackground(const AValue: TColor);
begin
  FCustomBackground := AValue;

  SetSkinCustomColors(Self, SkinData, FCustomBackground, FCustomForeground);
end;

procedure TDatabaseGridSearchPanelEdit.SetCustomForeground(const AValue: TColor);
begin
  FCustomForeground := AValue;

  SetSkinCustomColors(Self, SkinData, FCustomBackground, FCustomForeground);
end;
{$ELSE}

function GetTextHintColor: TColor;
var
  LColor: COLORREF;
  LTheme: HTHEME;
begin
  Result := TColors.SysGrayText;

  if not InitThemeLibrary then
    Exit;

  try
    LTheme := OpenThemeData(0, 'EDIT');

    if LTheme <> 0 then
    try
      if Succeeded(GetThemeColor(LTheme, EP_EDITTEXT, ETS_CUEBANNER, TMT_TEXTCOLOR, LColor)) then
        Result := TColor(LColor);
    finally
      CloseThemeData(LTheme);
    end;
  finally
    FreeThemeLibrary;
  end;
end;

procedure ApplyCustomColors(var AMessage: TMessage; const ABrush: TBrush; const ABackground, AForeground: TColor);
begin
  if AForeground = TColors.SysGrayText then
    SetTextColor(AMessage.WParam, ColorToRGB(GetTextHintColor))
  else
  if AForeground <> TColors.SysNone then
    SetTextColor(AMessage.WParam, ColorToRGB(AForeground));

  if ABackground <> TColors.SysNone then
  begin
    ABrush.Color := ABackground;
    SetBkColor(AMessage.WParam, ColorToRGB(ABackground));
    AMessage.Result := LRESULT(ABrush.Handle);
  end;
end;

procedure RedrawControl(const AControl: TWinControl);
begin
  if AControl.HandleAllocated then
    RedrawWindow(AControl.Handle, nil, 0, RDW_INVALIDATE or RDW_ERASE or RDW_FRAME or RDW_ALLCHILDREN);
end;

{ TDatabaseGridSearchPanelComboBox }

constructor TDatabaseGridSearchPanelComboBox.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);

  FBorderColor := TColors.SysNone;
  FCustomBackground := TColors.SysNone;
  FCustomBrush := TBrush.Create;
  FCustomForeground := TColors.SysNone;
end;

destructor TDatabaseGridSearchPanelComboBox.Destroy;
begin
  inherited Destroy;

  FCustomBrush.Free;
end;

procedure TDatabaseGridSearchPanelComboBox.SetBorderColor(const AValue: TColor);
begin
  if FBorderColor <> AValue then
  begin
    FBorderColor := AValue;

    if HandleAllocated then
      Invalidate;
  end;
end;

procedure TDatabaseGridSearchPanelComboBox.SetCustomBackground(const AValue: TColor);
begin
  if FCustomBackground <> AValue then
  begin
    FCustomBackground := AValue;

    RedrawControl(Self);
  end;
end;

procedure TDatabaseGridSearchPanelComboBox.SetCustomForeground(const AValue: TColor);
begin
  if FCustomForeground <> AValue then
  begin
    FCustomForeground := AValue;

    RedrawControl(Self);
  end;
end;

procedure TDatabaseGridSearchPanelComboBox.WndProc(var AMessage: TMessage);
begin
  inherited WndProc(AMessage);

  if (AMessage.Msg = WM_CTLCOLOREDIT) or (AMessage.Msg = CN_CTLCOLOREDIT) then
    ApplyCustomColors(AMessage, FCustomBrush, FCustomBackground, FCustomForeground);
end;

procedure TDatabaseGridSearchPanelComboBox.WMPaint(var AMessage: TWMPaint);
var
  LBrush: HBRUSH;
  LDC: HDC;
  LFocus: HWND;
begin
  inherited;

  LFocus := GetFocus;

  if (FBorderColor = TColors.SysNone) or not Enabled or DroppedDown or (LFocus = Handle) or IsChild(Handle, LFocus) or
    not StyleServices.Enabled or not StyleServices.IsSystemStyle then
    Exit;

  LDC := GetWindowDC(Handle);
  try
    LBrush := CreateSolidBrush(ColorToRGB(FBorderColor));
    try
      FrameRect(LDC, Rect(0, 0, Width, Height), LBrush);
    finally
      DeleteObject(LBrush);
    end;
  finally
    ReleaseDC(Handle, LDC);
  end;
end;

{ TDatabaseGridSearchPanelEdit }

constructor TDatabaseGridSearchPanelEdit.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);

  FBorderColor := TColors.SysNone;
  FCustomBackground := TColors.SysNone;
  FCustomBrush := TBrush.Create;
  FCustomForeground := TColors.SysNone;
end;

destructor TDatabaseGridSearchPanelEdit.Destroy;
begin
  inherited Destroy;

  FCustomBrush.Free;
end;

function TDatabaseGridSearchPanelEdit.HasThemedBorder: Boolean;
begin
  Result := (BorderStyle = bsSingle) and Ctl3D and StyleServices.Enabled and StyleServices.IsSystemStyle;
end;

procedure TDatabaseGridSearchPanelEdit.CreateWnd;
begin
  inherited CreateWnd;

  if HasThemedBorder then
    SendMessage(Handle, EM_SETMARGINS, EC_LEFTMARGIN or EC_RIGHTMARGIN, MakeLParam(2, 2));
end;

procedure TDatabaseGridSearchPanelEdit.RedrawBorder;
begin
  if HandleAllocated and HasThemedBorder then
    RedrawWindow(Handle, nil, 0, RDW_FRAME or RDW_INVALIDATE or RDW_NOCHILDREN);
end;

procedure TDatabaseGridSearchPanelEdit.SetBorderColor(const AValue: TColor);
begin
  if FBorderColor <> AValue then
  begin
    FBorderColor := AValue;

    RedrawBorder;
  end;
end;

procedure TDatabaseGridSearchPanelEdit.SetCustomBackground(const AValue: TColor);
begin
  if FCustomBackground <> AValue then
  begin
    FCustomBackground := AValue;

    RedrawControl(Self);
  end;
end;

procedure TDatabaseGridSearchPanelEdit.SetCustomForeground(const AValue: TColor);
begin
  if FCustomForeground <> AValue then
  begin
    FCustomForeground := AValue;

    RedrawControl(Self);
  end;
end;

procedure TDatabaseGridSearchPanelEdit.WndProc(var AMessage: TMessage);
begin
  inherited WndProc(AMessage);

  if AMessage.Msg = CN_CTLCOLOREDIT then
    ApplyCustomColors(AMessage, FCustomBrush, FCustomBackground, FCustomForeground);
end;

procedure TDatabaseGridSearchPanelEdit.WMKillFocus(var AMessage: TWMKillFocus);
begin
  inherited;

  RedrawBorder;
end;

procedure TDatabaseGridSearchPanelEdit.WMNCCalcSize(var AMessage: TWMNCCalcSize);
var
  LBitmap: TBitmap;
  LExtraHeight: Integer;
begin
  inherited;

  if not HasThemedBorder then
    Exit;

  LBitmap := TBitmap.Create;
  try
    LBitmap.Canvas.Font := Font;

    LExtraHeight := AMessage.CalcSize_Params.rgrc[0].Height - LBitmap.Canvas.TextHeight('Wg') - 1;
  finally
    LBitmap.Free;
  end;

  if LExtraHeight > 0 then
  begin
    Inc(AMessage.CalcSize_Params.rgrc[0].Top, LExtraHeight div 2);
    Dec(AMessage.CalcSize_Params.rgrc[0].Bottom, LExtraHeight - LExtraHeight div 2);
  end;
end;

procedure TDatabaseGridSearchPanelEdit.WMNCPaint(var AMessage: TWMNCPaint);
var
  LBorder: TThemedComboBox;
  LBrush: HBRUSH;
  LClientRect, LWindowRect: TRect;
  LDC: HDC;
begin
  inherited;

  if not HasThemedBorder then
    Exit;

  if not Enabled then
    LBorder := tcBorderDisabled
  else
  if Focused then
    LBorder := tcBorderFocused
  else
    LBorder := tcBorderNormal;

  LDC := GetWindowDC(Handle);
  try
    GetWindowRect(Handle, LWindowRect);
    Winapi.Windows.GetClientRect(Handle, LClientRect);
    MapWindowPoints(Handle, 0, LClientRect, 2);
    LClientRect.Offset(-LWindowRect.Left, -LWindowRect.Top);
    LWindowRect.Offset(-LWindowRect.Left, -LWindowRect.Top);

    ExcludeClipRect(LDC, LClientRect.Left, LClientRect.Top, LClientRect.Right, LClientRect.Bottom);

    LBrush := CreateSolidBrush(ColorToRGB(if FCustomBackground = TColors.SysNone then Color else FCustomBackground));
    try
      FillRect(LDC, LWindowRect, LBrush);
    finally
      DeleteObject(LBrush);
    end;

    if (LBorder = tcBorderNormal) and (FBorderColor <> TColors.SysNone) then
    begin
      LBrush := CreateSolidBrush(ColorToRGB(FBorderColor));
      try
        FrameRect(LDC, LWindowRect, LBrush);
      finally
        DeleteObject(LBrush);
      end;
    end
    else
      StyleServices.DrawElement(LDC, StyleServices.GetElementDetails(LBorder), LWindowRect);
  finally
    ReleaseDC(Handle, LDC);
  end;
end;

procedure TDatabaseGridSearchPanelEdit.WMSetFocus(var AMessage: TWMSetFocus);
begin
  inherited;

  RedrawBorder;
end;
{$ENDIF}

{ TDatabaseGridSearchPanelButton }

constructor TDatabaseGridSearchPanelButton.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);

  ControlStyle := ControlStyle + [csCaptureMouse, csClickEvents, csOpaque] - [csDoubleClicks];
  FGlyphColor := TColors.SysBtnText;
  ShowHint := True;
  TabStop := False;
end;

procedure TDatabaseGridSearchPanelButton.CMEnabledChanged(var AMessage: TMessage);
begin
  inherited;

  Invalidate;
end;

procedure TDatabaseGridSearchPanelButton.CMMouseEnter(var AMessage: TMessage);
begin
  inherited;

  FMouseInside := True;

  Invalidate;
end;

procedure TDatabaseGridSearchPanelButton.CMMouseLeave(var AMessage: TMessage);
begin
  inherited;

  FMouseInside := False;

  Invalidate;
end;

procedure TDatabaseGridSearchPanelButton.MouseDown(AButton: TMouseButton; AShift: TShiftState; AX, AY: Integer);
begin
  inherited MouseDown(AButton, AShift, AX, AY);

  if AButton = mbLeft then
  begin
    FPressed := True;

    Invalidate;
  end;
end;

procedure TDatabaseGridSearchPanelButton.MouseUp(AButton: TMouseButton; AShift: TShiftState; AX, AY: Integer);
begin
  FPressed := False;

  Invalidate;

  inherited MouseUp(AButton, AShift, AX, AY);
end;

procedure TDatabaseGridSearchPanelButton.Paint;
var
  LBitmap: TBitmap;
begin
  LBitmap := TBitmap.Create;
  try
    LBitmap.SetSize(Width, Height);
    LBitmap.Canvas.Brush.Color := Color;
    LBitmap.Canvas.FillRect(Rect(0, 0, Width, Height));

    PaintGlyph(LBitmap.Canvas);

    Canvas.Draw(0, 0, LBitmap);
  finally
    LBitmap.Free;
  end;
end;

procedure TDatabaseGridSearchPanelButton.PaintGlyph(const ACanvas: TCanvas);
var
  LGraphics: TGPGraphics;
  LGlyphColor: TColor;
  LSize: Integer;

  procedure PaintBackground(const AAlpha: Byte);
  var
    LBrush: TGPSolidBrush;
  begin
    LBrush := TGPSolidBrush.Create(MakeColor(AAlpha, 0, 0, 0));
    try
      LGraphics.FillRectangle(LBrush, 0, 0, Width, Height);
    finally
      LBrush.Free;
    end;
  end;

begin
  if Enabled and (FPressed or FMouseInside) then
  begin
    LGraphics := TGPGraphics.Create(ACanvas.Handle);
    try
      PaintBackground(if FPressed then TDatabaseGridButton.PressedAlpha else TDatabaseGridButton.HotAlpha);
    finally
      LGraphics.Free;
    end;
  end;

  LGlyphColor := if Enabled then FGlyphColor else TColors.SysGrayText;
  LSize := Min(Width, Height) * TDatabaseGridButton.GlyphPercent div 100;

  PaintDatabaseGridGlyph(ACanvas, Bounds((Width - LSize) div 2, (Height - LSize) div 2, LSize, LSize), FGlyph, LGlyphColor);
end;

procedure TDatabaseGridSearchPanelButton.SetGlyph(const AValue: TDatabaseGridGlyph);
begin
  if FGlyph <> AValue then
  begin
    FGlyph := AValue;

    Invalidate;
  end;
end;

procedure TDatabaseGridSearchPanelButton.SetGlyphColor(const AValue: TColor);
begin
  if FGlyphColor <> AValue then
  begin
    FGlyphColor := AValue;

    Invalidate;
  end;
end;

procedure TDatabaseGridSearchPanelButton.WMEraseBkgnd(var AMessage: TWMEraseBkgnd);
begin
  AMessage.Result := 1;
end;

{ TDatabaseGridSearchPanelControls }

constructor TDatabaseGridSearchPanelControls.Create(const AParent: TWinControl; const ASearchPanel: TDatabaseGridSearchPanel;
  const AColors: TDatabaseGridColors);
begin
  inherited Create;

  FColors := AColors;
  FParent := AParent;
  FSearchPanel := ASearchPanel;
  FComboBoxes := TList<TDatabaseGridSearchPanelComboBox>.Create;
end;

destructor TDatabaseGridSearchPanelControls.Destroy;
begin
  for var LIndex := FComboBoxes.Count - 1 downto 0 do
    FComboBoxes[LIndex].Free;

  FComboBoxes.Free;
  FTimer.Free;
  FEdit.Free;
  FFilterButton.Free;
  FRefreshButton.Free;

  inherited Destroy;
end;

function TDatabaseGridSearchPanelControls.CreateButton(const AGlyph: TDatabaseGridGlyph;
  const AOnClick: TNotifyEvent): TDatabaseGridSearchPanelButton;
begin
  Result := TDatabaseGridSearchPanelButton.Create(FParent);
  Result.Visible := False;
  Result.Parent := FParent;
  Result.Glyph := AGlyph;
  Result.OnClick := AOnClick;
end;

function TDatabaseGridSearchPanelControls.GetBackgroundColor: TColor;
begin
  Result := if IsHighlighted then FColors.SearchPanelBackgroundFocused else FColors.SearchPanelBackground;
end;

function TDatabaseGridSearchPanelControls.GetControlBounds: TArray<TRect>;
begin
  Result := nil;

  for var LControl in GetControls do
    Result := Result + [if LControl.Visible then LControl.BoundsRect else TRect.Empty];
end;

function TDatabaseGridSearchPanelControls.GetControls: TArray<TWinControl>;
begin
  Result := [FEdit, FFilterButton, FRefreshButton];

  for var LComboBox in FComboBoxes do
    Result := Result + [LComboBox];
end;

function TDatabaseGridSearchPanelControls.HasFocus(const AControl: TWinControl): Boolean;
begin
  Result := (FFocusedWindow <> 0) and AControl.HandleAllocated and (AControl.Handle = FFocusedWindow);
end;

function TDatabaseGridSearchPanelControls.HasSomethingToClear: Boolean;
begin
  Result := not FSearchPanel.Text.IsEmpty or (spoClearResetsItems in FSearchPanel.Options) and FSearchPanel.IsAnyItemFiltering;
end;

function TDatabaseGridSearchPanelControls.IsControlWindow(const AWindow: HWND): Boolean;
begin
  if Assigned(FEdit) and FEdit.HandleAllocated and (FEdit.Handle = AWindow) then
    Exit(True);

  for var LComboBox in FComboBoxes do
  if LComboBox.HandleAllocated and (LComboBox.Handle = AWindow) then
    Exit(True);

  Result := False;
end;

function TDatabaseGridSearchPanelControls.SameControlBounds(const ABounds, AOtherBounds: TArray<TRect>): Boolean;
begin
  if Length(ABounds) <> Length(AOtherBounds) then
    Exit(False);

  for var LIndex := 0 to High(ABounds) do
  if ABounds[LIndex] <> AOtherBounds[LIndex] then
    Exit(False);

  Result := True;
end;

procedure TDatabaseGridSearchPanelControls.AcceptItem(const AItem: TDatabaseGridSearchPanelItem);
begin
  AItem.AcceptedText := AItem.Text;

  if Assigned(AItem.OnAccept) then
    AItem.OnAccept(FParent, AItem);
end;

procedure TDatabaseGridSearchPanelControls.ApplyFilter;
begin
  if Assigned(FTimer) then
    FTimer.Enabled := False;

  if Assigned(FOnApplyFilter) then
    FOnApplyFilter(Self);
end;

function TDatabaseGridSearchPanelControls.GetComboBoxItem(const AComboBox: TObject): TDatabaseGridSearchPanelItem;
var
  LIndex: Integer;
begin
  LIndex := FComboBoxes.IndexOf(AComboBox as TDatabaseGridSearchPanelComboBox);

  if (LIndex < 0) or (LIndex >= FSearchPanel.Items.Count) then
    Exit(nil);

  Result := FSearchPanel.Items[LIndex];
end;

function TDatabaseGridSearchPanelControls.GetFocusedControl: TWinControl;
begin
  if Assigned(FEdit) and FEdit.Focused then
    Exit(FEdit);

  for var LComboBox in FComboBoxes do
  if LComboBox.Focused then
    Exit(LComboBox);

  Result := nil;
end;

function TDatabaseGridSearchPanelControls.HandleFocusNotification(const AWindow: HWND; const ANotifyCode: Word): Boolean;
begin
  if not IsControlWindow(AWindow) then
    Exit(False);

  case ANotifyCode of
    EN_SETFOCUS, CBN_SETFOCUS:
      FFocusedWindow := AWindow;
    EN_KILLFOCUS, CBN_KILLFOCUS:
      FFocusedWindow := 0;
  else
    Exit(False);
  end;

  FFilterButton.Color := GetBackgroundColor;
  FRefreshButton.Color := GetBackgroundColor;

  UpdateControlColors;

  Result := spoHighlightOnFocus in FSearchPanel.Options;
end;

function TDatabaseGridSearchPanelControls.IsHighlighted: Boolean;
begin
  Result := (FFocusedWindow <> 0) and (spoHighlightOnFocus in FSearchPanel.Options);
end;

procedure TDatabaseGridSearchPanelControls.BeginSearch(const AText: string);
begin
  if not Assigned(FEdit) or not FEdit.CanFocus then
    Exit;

  if not AText.IsEmpty then
    FEdit.Text := AText;

  FEdit.SetFocus;

  if AText.IsEmpty then
    FEdit.SelectAll
  else
    FEdit.SelStart := Length(FEdit.Text);
end;

procedure TDatabaseGridSearchPanelControls.ComboBoxChange(ASender: TObject);
var
  LIndex: Integer;
  LItem: TDatabaseGridSearchPanelItem;
begin
  LIndex := FComboBoxes.IndexOf(ASender as TDatabaseGridSearchPanelComboBox);

  if FUpdating or (LIndex < 0) or (LIndex >= FSearchPanel.Items.Count) then
    Exit;

  LItem := FSearchPanel.Items[LIndex];

  FUpdating := True;
  try
    LItem.ItemIndex := FComboBoxes[LIndex].ItemIndex;
    LItem.Text := FComboBoxes[LIndex].Text;
  finally
    FUpdating := False;
  end;

  UpdateComboBoxColors(LIndex);
  UpdateFilterButton;

  if Assigned(LItem.OnChange) then
    LItem.OnChange(FParent, LItem);
end;

procedure TDatabaseGridSearchPanelControls.ComboBoxCloseUp(ASender: TObject);
var
  LItem: TDatabaseGridSearchPanelItem;
begin
  if FParent.HandleAllocated then
    PostMessage(FParent.Handle, TDatabaseGridMessage.WM_FOCUS, 0, 0);

  LItem := GetComboBoxItem(ASender);

  if Assigned(LItem) and Assigned(LItem.OnAccept) and ((ASender as TDatabaseGridSearchPanelComboBox).ItemIndex >= 0) then
    AcceptItem(LItem);
end;

procedure TDatabaseGridSearchPanelControls.ComboBoxExit(ASender: TObject);
var
  LItem: TDatabaseGridSearchPanelItem;
begin
  LItem := GetComboBoxItem(ASender);

  if Assigned(LItem) and Assigned(LItem.OnAccept) and LItem.Text.IsEmpty and not LItem.AcceptedText.IsEmpty then
    AcceptItem(LItem);
end;

procedure TDatabaseGridSearchPanelControls.ComboBoxKeyDown(ASender: TObject; var AKey: Word; AShift: TShiftState);
var
  LItem: TDatabaseGridSearchPanelItem;
begin
  if (AKey <> VK_SPACE) or (AShift <> [ssCtrl]) then
    Exit;

  LItem := GetComboBoxItem(ASender);

  if Assigned(LItem) and Assigned(LItem.OnCompletion) then
  begin
    AKey := 0;
    LItem.OnCompletion(FParent, LItem);
  end;
end;

procedure TDatabaseGridSearchPanelControls.ComboBoxKeyPress(ASender: TObject; var AKey: Char);
var
  LItem: TDatabaseGridSearchPanelItem;
begin
  LItem := GetComboBoxItem(ASender);

  if not Assigned(LItem) then
    Exit;

  if (AKey = TCharacters.Space) and (GetKeyState(VK_CONTROL) < 0) and Assigned(LItem.OnCompletion) then
    AKey := TControlCharacters.Null
  else
  if (AKey = TControlCharacters.CarriageReturn) and Assigned(LItem.OnAccept) then
  begin
    AKey := TControlCharacters.Null;
    AcceptItem(LItem);
  end;
end;

procedure TDatabaseGridSearchPanelControls.CreateControls;
begin
  FEdit := TDatabaseGridSearchPanelEdit.Create(FParent);
  FEdit.Visible := False;
  FEdit.Parent := FParent;
  FEdit.AutoSize := False;
  FEdit.OnChange := EditChange;
  FEdit.OnKeyDown := EditKeyDown;
  FEdit.OnKeyPress := EditKeyPress;

  FFilterButton := CreateButton(glFilter, FilterButtonClick);
  FRefreshButton := CreateButton(glRefresh, RefreshButtonClick);
  FRefreshButton.Hint := SDatabaseGridRefresh;

  FTimer := TTimer.Create(nil);
  FTimer.Enabled := False;
  FTimer.OnTimer := TimerTimer;
end;

procedure TDatabaseGridSearchPanelControls.EditChange(ASender: TObject);
begin
  if FUpdating then
    Exit;

  FUpdating := True;
  try
    FSearchPanel.Text := FEdit.Text;
  finally
    FUpdating := False;
  end;

  UpdateEditColors;
  UpdateFilterButton;

  if spoFilterOnTyping in FSearchPanel.Options then
  begin
    FTimer.Enabled := False;

    if FSearchPanel.FilterDelay = 0 then
      ApplyFilter
    else
    begin
      FTimer.Interval := FSearchPanel.FilterDelay;
      FTimer.Enabled := True;
    end;
  end;
end;

procedure TDatabaseGridSearchPanelControls.EditKeyDown(ASender: TObject; var AKey: Word; AShift: TShiftState);
begin
  if (AKey = vkDown) and (AShift = []) and FParent.CanFocus then
  begin
    AKey := 0;

    FParent.SetFocus;
  end;
end;

procedure TDatabaseGridSearchPanelControls.EditKeyPress(ASender: TObject; var AKey: Char);
begin
  case AKey of
    TControlCharacters.CarriageReturn:
      begin
        AKey := TControlCharacters.Null;

        ApplyFilter;
      end;
    TControlCharacters.Escape:
      begin
        AKey := TControlCharacters.Null;

        FEdit.Clear;

        ApplyFilter;
      end;
  end;
end;

procedure TDatabaseGridSearchPanelControls.FilterButtonClick(ASender: TObject);
begin
  if FFilterButton.Glyph = glClear then
  begin
    if spoClearResetsItems in FSearchPanel.Options then
      ResetItems;

    FEdit.Clear;
  end;

  ApplyFilter;
end;

procedure TDatabaseGridSearchPanelControls.Realign(const ARect: TRect; const AControlHeight, APixelsPerInch: Integer);
var
  LBounds: TArray<TRect>;
  LComboBox: TDatabaseGridSearchPanelComboBox;
  LControls: TArray<TWinControl>;
  LLeft, LRight, LSpacing, LTop, LWidth: Integer;
  LShown: TArray<Boolean>;
  LVisible: Boolean;

  procedure AddControl(const AControl: TWinControl; const AShown: Boolean; const ABounds: TRect);
  begin
    LControls := LControls + [AControl];
    LShown := LShown + [AShown];
    LBounds := LBounds + [ABounds];
  end;

  procedure AlignButton(const AButton: TDatabaseGridSearchPanelButton; const AShown: Boolean);
  begin
    if LVisible and AShown then
    begin
      AButton.Color := GetBackgroundColor;

      Dec(LRight, AControlHeight);

      AddControl(AButton, True, Bounds(LRight, LTop, AControlHeight, AControlHeight));

      Dec(LRight, LSpacing);
    end
    else
      AddControl(AButton, False, AButton.BoundsRect);
  end;

  procedure MoveControls;
  var
    LPosition: HDWP;
  begin
    for var LIndex := 0 to High(LControls) do
    if not LShown[LIndex] then
      LControls[LIndex].Visible := False;

    LPosition := 0;

    if FParent.HandleAllocated then
      LPosition := BeginDeferWindowPos(Length(LControls));

    for var LIndex := 0 to High(LControls) do
    if LControls[LIndex].BoundsRect <> LBounds[LIndex] then
    begin
      if (LPosition <> 0) and LControls[LIndex].HandleAllocated then
        LPosition := DeferWindowPos(LPosition, LControls[LIndex].Handle, 0, LBounds[LIndex].Left, LBounds[LIndex].Top,
          LBounds[LIndex].Width, LBounds[LIndex].Height, SWP_NOZORDER or SWP_NOACTIVATE)
      else
        LControls[LIndex].BoundsRect := LBounds[LIndex];
    end;

    if LPosition <> 0 then
      EndDeferWindowPos(LPosition);

    for var LIndex := 0 to High(LControls) do
    if LShown[LIndex] then
      LControls[LIndex].Visible := True;
  end;

begin
  if not Assigned(FEdit) then
    Exit;

  var LPreviousBounds := GetControlBounds;

  FRect := ARect;
  LVisible := not ARect.IsEmpty;
  LSpacing := MulDiv(TDatabaseGridSize.SearchPanelSpacing, APixelsPerInch, USER_DEFAULT_SCREEN_DPI);
  LLeft := ARect.Left + LSpacing;
  LRight := ARect.Right - LSpacing;
  LTop := ARect.Top + (ARect.Height - AControlHeight) div 2;
  LControls := nil;
  LShown := nil;
  LBounds := nil;

{$IFNDEF ALPHASKINS}
  FEdit.BorderColor := FColors.SearchPanelBorder;
{$ENDIF}

  for var LIndex := 0 to FComboBoxes.Count - 1 do
  begin
    LComboBox := FComboBoxes[LIndex];
{$IFNDEF ALPHASKINS}
    LComboBox.BorderColor := FColors.SearchPanelBorder;
{$ENDIF}

    if LVisible and FSearchPanel.Items[LIndex].Visible then
    begin
      LWidth := MulDiv(FSearchPanel.Items[LIndex].Width, APixelsPerInch, USER_DEFAULT_SCREEN_DPI);

      AddControl(LComboBox, True, Bounds(LLeft, ARect.Top + (ARect.Height - LComboBox.Height) div 2, LWidth, LComboBox.Height));

      Inc(LLeft, LWidth + LSpacing);
    end
    else
      AddControl(LComboBox, False, LComboBox.BoundsRect);
  end;

  AlignButton(FRefreshButton, spoShowRefreshButton in FSearchPanel.Options);
  AlignButton(FFilterButton, True);

  if LVisible then
    AddControl(FEdit, True, Bounds(LLeft, LTop, Max(LRight - LLeft, 0), AControlHeight))
  else
    AddControl(FEdit, False, FEdit.BoundsRect);

  MoveControls;

  UpdateControlColors;
  UpdateFilterButton;

  if LVisible and FParent.HandleAllocated and not SameControlBounds(LPreviousBounds, GetControlBounds) then
  begin
    RedrawControls(RDW_UPDATENOW);

    if not FRedrawPosted then
    begin
      FRedrawPosted := True;

      PostMessage(FParent.Handle, TDatabaseGridMessage.WM_REDRAW_SEARCH_PANEL, 0, 0);
    end;
  end;
end;

procedure TDatabaseGridSearchPanelControls.Redraw;
begin
  FRedrawPosted := False;

  RedrawControls(0);
end;

procedure TDatabaseGridSearchPanelControls.RedrawControls(const AFlags: UINT);
begin
  if not FParent.HandleAllocated or FRect.IsEmpty or not IsWindowVisible(FParent.Handle) then
    Exit;

  RedrawWindow(FParent.Handle, @FRect, 0, RDW_INVALIDATE or RDW_ERASE or AFlags);

  for var LControl in GetControls do
  if LControl.Visible and LControl.HandleAllocated then
    RedrawWindow(LControl.Handle, nil, 0, RDW_INVALIDATE or RDW_FRAME or RDW_ALLCHILDREN or AFlags);
{$IFDEF ALPHASKINS}

  SetParentUpdated(FParent);
{$ENDIF}
end;

procedure TDatabaseGridSearchPanelControls.RefreshButtonClick(ASender: TObject);
begin
  if Assigned(FOnRefresh) then
    FOnRefresh(Self);
end;

procedure TDatabaseGridSearchPanelControls.ResetItems;
var
  LResetItems: TArray<TDatabaseGridSearchPanelItem>;
begin
  FUpdating := True;
  try
    for var LIndex := 0 to FSearchPanel.Items.Count - 1 do
    if FSearchPanel.Items[LIndex].IsFiltering then
    begin
      FSearchPanel.Items[LIndex].Reset;

      LResetItems := LResetItems + [FSearchPanel.Items[LIndex]];
    end;

    SynchronizeComboBoxes;
  finally
    FUpdating := False;
  end;

  UpdateControlColors;
  UpdateFilterButton;

  for var LItem in LResetItems do
  begin
    if Assigned(LItem.OnChange) then
      LItem.OnChange(FParent, LItem);

    AcceptItem(LItem);
  end;
end;

procedure TDatabaseGridSearchPanelControls.SetAppliedText(const AValue: string);
begin
  if FAppliedText = AValue then
    Exit;

  FAppliedText := AValue;

  if Assigned(FEdit) then
  begin
    UpdateEditColors;
    UpdateFilterButton;
  end;
end;

procedure TDatabaseGridSearchPanelControls.Synchronize;
begin
  if FUpdating or not Assigned(FEdit) and not FSearchPanel.Visible then
    Exit;

  FUpdating := True;
  try
    if not Assigned(FEdit) then
      CreateControls;

    SynchronizeComboBoxes;

    if FEdit.Text <> FSearchPanel.Text then
      FEdit.Text := FSearchPanel.Text;

    FEdit.TextHint := if FSearchPanel.TextHint.IsEmpty then SDatabaseGridSearch else FSearchPanel.TextHint;

    UpdateControlColors;
    UpdateFilterButton;
  finally
    FUpdating := False;
  end;
end;

procedure TDatabaseGridSearchPanelControls.SynchronizeComboBoxes;
var
  LComboBox: TDatabaseGridSearchPanelComboBox;
  LItem: TDatabaseGridSearchPanelItem;
begin
  while FComboBoxes.Count > FSearchPanel.Items.Count do
  begin
    FComboBoxes.Last.Free;
    FComboBoxes.Delete(FComboBoxes.Count - 1);
  end;

  while FComboBoxes.Count < FSearchPanel.Items.Count do
  begin
    LComboBox := TDatabaseGridSearchPanelComboBox.Create(FParent);
    LComboBox.Visible := False;
    LComboBox.Parent := FParent;
    LComboBox.TabOrder := FComboBoxes.Count;
    LComboBox.OnChange := ComboBoxChange;
    LComboBox.OnCloseUp := ComboBoxCloseUp;
    LComboBox.OnExit := ComboBoxExit;
    LComboBox.OnKeyDown := ComboBoxKeyDown;
    LComboBox.OnKeyPress := ComboBoxKeyPress;

    FComboBoxes.Add(LComboBox);
  end;

  if not FParent.HandleAllocated then
    Exit;

  for var LIndex := 0 to FComboBoxes.Count - 1 do
  begin
    LComboBox := FComboBoxes[LIndex];
    LItem := FSearchPanel.Items[LIndex];

    if LComboBox.Items.Text <> LItem.Items.Text then
      LComboBox.Items.Assign(LItem.Items);

    LComboBox.TextHint := LItem.TextHint;

    LComboBox.ItemIndex := Min(LItem.ItemIndex, LComboBox.Items.Count - 1);

    if (LComboBox.ItemIndex < 0) and (LComboBox.Text <> LItem.Text) then
      LComboBox.Text := LItem.Text;
  end;
end;

procedure TDatabaseGridSearchPanelControls.TimerTimer(ASender: TObject);
begin
  ApplyFilter;
end;

procedure TDatabaseGridSearchPanelControls.UpdateComboBoxColors(const AIndex: Integer);
var
  LComboBox: TDatabaseGridSearchPanelComboBox;
  LItem: TDatabaseGridSearchPanelItem;
begin
  LComboBox := FComboBoxes[AIndex];
  LItem := FSearchPanel.Items[AIndex];

  LComboBox.CustomBackground := if (spoHighlightFiltering in FSearchPanel.Options) and LItem.IsFiltering and not HasFocus(LComboBox) then
    FColors.SearchPanelFilterBackground else TColors.SysNone;
  LComboBox.CustomForeground := if LItem.IsDefaultItemSelected then FColors.SearchPanelDefaultItemForeground else TColors.SysNone;
end;

procedure TDatabaseGridSearchPanelControls.UpdateControlColors;
begin
  for var LIndex := 0 to Min(FComboBoxes.Count, FSearchPanel.Items.Count) - 1 do
    UpdateComboBoxColors(LIndex);

  UpdateEditColors;
end;

procedure TDatabaseGridSearchPanelControls.UpdateEditColors;
begin
  FEdit.CustomBackground := if (spoHighlightFiltering in FSearchPanel.Options) and not FAppliedText.IsEmpty and not HasFocus(FEdit) then
    FColors.SearchPanelFilterBackground else TColors.SysNone;
end;

procedure TDatabaseGridSearchPanelControls.UpdateFilterButton;
begin
  FRefreshButton.GlyphColor := FColors.SearchPanelGlyph;

  FFilterButton.Enabled := not (spoFilterOnTyping in FSearchPanel.Options) or HasSomethingToClear;

  if (spoFilterOnTyping in FSearchPanel.Options) or HasSomethingToClear and (Trim(FSearchPanel.Text) = FAppliedText) then
  begin
    FFilterButton.Glyph := glClear;
    FFilterButton.GlyphColor := FColors.SearchPanelClearGlyph;
    FFilterButton.Hint := SDatabaseGridClear;
  end
  else
  begin
    FFilterButton.Glyph := glFilter;
    FFilterButton.GlyphColor := FColors.SearchPanelGlyph;
    FFilterButton.Hint := SDatabaseGridFilter;
  end;
end;

end.
