unit DatabaseGrid.Colors;

{$I DatabaseGrid.Defines.inc}

interface

uses
  System.Classes, System.UITypes, DatabaseGrid.Consts
{$IFDEF ALPHASKINS}
  , sSkinManager
{$ENDIF};

type
{$IF DEFINED(DATABASE_GRID_VCL_STYLES) or DEFINED(ALPHASKINS)}
  TDatabaseGridBaseColors = record
    GrayText: TColor;
    Grid: TColor;
    GridLine: TColor;
    GroupRowLine: TColor;
    HeaderBackground: TColor;
    HeaderBackgroundHot: TColor;
    HeaderBackgroundPressed: TColor;
    HeaderForeground: TColor;
    Highlight: TColor;
    HighlightForeground: TColor;
    HighlightForegroundUnfocused: TColor;
    HighlightUnfocused: TColor;
    Line: TColor;
    MapStyleSystemColors: Boolean;
    Text: TColor;
    TitleBottomLine: TColor;
    TitleTopLine: TColor;
  end;
{$ENDIF}

  TDatabaseGridColors = class(TPersistent)
  strict private
    FActiveRowBackground: TColor;
    FActiveRowBackgroundUnfocused: TColor;
    FActiveRowForeground: TColor;
    FActiveRowForegroundUnfocused: TColor;
    FCurrentCellBorder: TColor;
    FCurrentRowBackground: TColor;
    FDataBackground: TColor;
    FDataBackgroundAlternate: TColor;
    FDataForeground: TColor;
    FEditButtonBackground: TColor;
    FEditButtonGlyph: TColor;
    FFooterBackground: TColor;
    FFooterForeground: TColor;
    FFooterLine: TColor;
    FGridBackground: TColor;
    FGroupRowBackground: TColor;
    FGroupRowExpander: TColor;
    FGroupRowForeground: TColor;
    FGroupRowLine: TColor;
    FHorizontalLine: TColor;
    FIndicatorArrow: TColor;
    FIndicatorBackground: TColor;
    FIndicatorCheckBoxBackground: TColor;
    FIndicatorCheckBoxBorder: TColor;
    FIndicatorCheckBoxMark: TColor;
    FIndicatorDropDownSign: TColor;
    FIndicatorLine: TColor;
    FOnChange: TNotifyEvent;
    FReadOnlyBackground: TColor;
    FReadOnlyForeground: TColor;
    FSearchMatchBackground: TColor;
    FSearchMatchForeground: TColor;
    FSearchPanelBackground: TColor;
    FSearchPanelBackgroundFocused: TColor;
    FSearchPanelBorder: TColor;
    FSearchPanelClearGlyph: TColor;
    FSearchPanelDefaultItemForeground: TColor;
    FSearchPanelFilterBackground: TColor;
    FSearchPanelGlyph: TColor;
    FSelectionBackground: TColor;
    FSelectionBackgroundUnfocused: TColor;
    FSelectionForeground: TColor;
    FSelectionForegroundUnfocused: TColor;
    FTitleBackground: TColor;
    FTitleBackgroundPressed: TColor;
    FTitleBackgroundSorted: TColor;
    FTitleBottomLine: TColor;
    FTitleForeground: TColor;
    FTitleSortMarker: TColor;
    FTitleSubCaptionForeground: TColor;
    FTitleTopLine: TColor;
    FTitleVerticalLine: TColor;
    FVerticalLine: TColor;
{$IF DEFINED(DATABASE_GRID_VCL_STYLES) or DEFINED(ALPHASKINS)}
    procedure ResolveBaseColors(const ASource: TDatabaseGridColors; const ABaseColors: TDatabaseGridBaseColors);
{$ENDIF}
    procedure DoChange;
    procedure SetActiveRowBackground(const AValue: TColor);
    procedure SetActiveRowBackgroundUnfocused(const AValue: TColor);
    procedure SetActiveRowForeground(const AValue: TColor);
    procedure SetActiveRowForegroundUnfocused(const AValue: TColor);
    procedure SetColor(var AColor: TColor; const AValue: TColor);
    procedure SetCurrentCellBorder(const AValue: TColor);
    procedure SetCurrentRowBackground(const AValue: TColor);
    procedure SetDataBackground(const AValue: TColor);
    procedure SetDataBackgroundAlternate(const AValue: TColor);
    procedure SetDataForeground(const AValue: TColor);
    procedure SetEditButtonBackground(const AValue: TColor);
    procedure SetEditButtonGlyph(const AValue: TColor);
    procedure SetFooterBackground(const AValue: TColor);
    procedure SetFooterForeground(const AValue: TColor);
    procedure SetFooterLine(const AValue: TColor);
    procedure SetGridBackground(const AValue: TColor);
    procedure SetGroupRowBackground(const AValue: TColor);
    procedure SetGroupRowExpander(const AValue: TColor);
    procedure SetGroupRowForeground(const AValue: TColor);
    procedure SetGroupRowLine(const AValue: TColor);
    procedure SetHorizontalLine(const AValue: TColor);
    procedure SetIndicatorArrow(const AValue: TColor);
    procedure SetIndicatorBackground(const AValue: TColor);
    procedure SetIndicatorCheckBoxBackground(const AValue: TColor);
    procedure SetIndicatorCheckBoxBorder(const AValue: TColor);
    procedure SetIndicatorCheckBoxMark(const AValue: TColor);
    procedure SetIndicatorDropDownSign(const AValue: TColor);
    procedure SetIndicatorLine(const AValue: TColor);
    procedure SetReadOnlyBackground(const AValue: TColor);
    procedure SetReadOnlyForeground(const AValue: TColor);
    procedure SetSearchMatchBackground(const AValue: TColor);
    procedure SetSearchMatchForeground(const AValue: TColor);
    procedure SetSearchPanelBackground(const AValue: TColor);
    procedure SetSearchPanelBackgroundFocused(const AValue: TColor);
    procedure SetSearchPanelBorder(const AValue: TColor);
    procedure SetSearchPanelClearGlyph(const AValue: TColor);
    procedure SetSearchPanelDefaultItemForeground(const AValue: TColor);
    procedure SetSearchPanelFilterBackground(const AValue: TColor);
    procedure SetSearchPanelGlyph(const AValue: TColor);
    procedure SetSelectionBackground(const AValue: TColor);
    procedure SetSelectionBackgroundUnfocused(const AValue: TColor);
    procedure SetSelectionForeground(const AValue: TColor);
    procedure SetSelectionForegroundUnfocused(const AValue: TColor);
    procedure SetTitleBackground(const AValue: TColor);
    procedure SetTitleBackgroundPressed(const AValue: TColor);
    procedure SetTitleBackgroundSorted(const AValue: TColor);
    procedure SetTitleBottomLine(const AValue: TColor);
    procedure SetTitleForeground(const AValue: TColor);
    procedure SetTitleSortMarker(const AValue: TColor);
    procedure SetTitleSubCaptionForeground(const AValue: TColor);
    procedure SetTitleTopLine(const AValue: TColor);
    procedure SetTitleVerticalLine(const AValue: TColor);
    procedure SetVerticalLine(const AValue: TColor);
  public
    constructor Create;
    procedure Assign(ASource: TPersistent); override;
{$IFDEF ALPHASKINS}
    procedure ResolveSkin(const ASource: TDatabaseGridColors; const ASkinManager: TsSkinManager);
{$ENDIF}
    procedure ResolveStyle(const ASource: TDatabaseGridColors);
    procedure SetDefaults;
    property OnChange: TNotifyEvent read FOnChange write FOnChange;
  published
    property ActiveRowBackground: TColor read FActiveRowBackground write SetActiveRowBackground default TColors.SysHighlight;
    property ActiveRowBackgroundUnfocused: TColor read FActiveRowBackgroundUnfocused write SetActiveRowBackgroundUnfocused default TColors.SysBtnFace;
    property ActiveRowForeground: TColor read FActiveRowForeground write SetActiveRowForeground default TColors.SysHighlightText;
    property ActiveRowForegroundUnfocused: TColor read FActiveRowForegroundUnfocused write SetActiveRowForegroundUnfocused default TColors.SysWindowText;
    property CurrentCellBorder: TColor read FCurrentCellBorder write SetCurrentCellBorder default TColors.SysNone;
    property CurrentRowBackground: TColor read FCurrentRowBackground write SetCurrentRowBackground default TDatabaseGridColor.CurrentRowBackground;
    property DataBackground: TColor read FDataBackground write SetDataBackground default TColors.SysWindow;
    property DataBackgroundAlternate: TColor read FDataBackgroundAlternate write SetDataBackgroundAlternate default TColors.SysNone;
    property DataForeground: TColor read FDataForeground write SetDataForeground default TColors.SysWindowText;
    property EditButtonBackground: TColor read FEditButtonBackground write SetEditButtonBackground default TColors.SysBtnFace;
    property EditButtonGlyph: TColor read FEditButtonGlyph write SetEditButtonGlyph default TColors.SysBtnText;
    property FooterBackground: TColor read FFooterBackground write SetFooterBackground default TColors.SysBtnFace;
    property FooterForeground: TColor read FFooterForeground write SetFooterForeground default TColors.SysBtnText;
    property FooterLine: TColor read FFooterLine write SetFooterLine default TColors.SysBtnShadow;
    property GridBackground: TColor read FGridBackground write SetGridBackground default TColors.SysWindow;
    property GroupRowBackground: TColor read FGroupRowBackground write SetGroupRowBackground default TDatabaseGridColor.GroupRowBackground;
    property GroupRowExpander: TColor read FGroupRowExpander write SetGroupRowExpander default TColors.SysGrayText;
    property GroupRowForeground: TColor read FGroupRowForeground write SetGroupRowForeground default TColors.SysWindowText;
    property GroupRowLine: TColor read FGroupRowLine write SetGroupRowLine default TDatabaseGridColor.GroupRowLine;
    property HorizontalLine: TColor read FHorizontalLine write SetHorizontalLine default TColors.SysBtnFace;
    property IndicatorArrow: TColor read FIndicatorArrow write SetIndicatorArrow default TColors.SysWindowText;
    property IndicatorBackground: TColor read FIndicatorBackground write SetIndicatorBackground default TColors.SysWindow;
    property IndicatorCheckBoxBackground: TColor read FIndicatorCheckBoxBackground write SetIndicatorCheckBoxBackground default TColors.SysWindow;
    property IndicatorCheckBoxBorder: TColor read FIndicatorCheckBoxBorder write SetIndicatorCheckBoxBorder default TColors.MedGray;
    property IndicatorCheckBoxMark: TColor read FIndicatorCheckBoxMark write SetIndicatorCheckBoxMark default TColors.SysWindowText;
    property IndicatorDropDownSign: TColor read FIndicatorDropDownSign write SetIndicatorDropDownSign default TColors.SysWindowText;
    property IndicatorLine: TColor read FIndicatorLine write SetIndicatorLine default TColors.SysBtnFace;
    property ReadOnlyBackground: TColor read FReadOnlyBackground write SetReadOnlyBackground default TDatabaseGridColor.ReadOnlyBackground;
    property ReadOnlyForeground: TColor read FReadOnlyForeground write SetReadOnlyForeground default TColors.SysGrayText;
    property SearchMatchBackground: TColor read FSearchMatchBackground write SetSearchMatchBackground default TDatabaseGridColor.SearchMatchBackground;
    property SearchMatchForeground: TColor read FSearchMatchForeground write SetSearchMatchForeground default TColors.SysWindowText;
    property SearchPanelBackground: TColor read FSearchPanelBackground write SetSearchPanelBackground default TColors.SysBtnFace;
    property SearchPanelBackgroundFocused: TColor read FSearchPanelBackgroundFocused write SetSearchPanelBackgroundFocused default TDatabaseGridColor.SearchPanelBackgroundFocused;
    property SearchPanelBorder: TColor read FSearchPanelBorder write SetSearchPanelBorder default TDatabaseGridColor.SearchPanelBorder;
    property SearchPanelClearGlyph: TColor read FSearchPanelClearGlyph write SetSearchPanelClearGlyph default TDatabaseGridColor.SearchPanelClearGlyph;
    property SearchPanelDefaultItemForeground: TColor read FSearchPanelDefaultItemForeground write SetSearchPanelDefaultItemForeground default TColors.SysGrayText;
    property SearchPanelFilterBackground: TColor read FSearchPanelFilterBackground write SetSearchPanelFilterBackground default TDatabaseGridColor.SearchPanelFilterBackground;
    property SearchPanelGlyph: TColor read FSearchPanelGlyph write SetSearchPanelGlyph default TColors.SysBtnText;
    property SelectionBackground: TColor read FSelectionBackground write SetSelectionBackground default TDatabaseGridColor.SelectionBackground;
    property SelectionBackgroundUnfocused: TColor read FSelectionBackgroundUnfocused write SetSelectionBackgroundUnfocused default TDatabaseGridColor.SelectionBackgroundUnfocused;
    property SelectionForeground: TColor read FSelectionForeground write SetSelectionForeground default TColors.SysWindowText;
    property SelectionForegroundUnfocused: TColor read FSelectionForegroundUnfocused write SetSelectionForegroundUnfocused default TColors.SysWindowText;
    property TitleBackground: TColor read FTitleBackground write SetTitleBackground default TColors.SysBtnFace;
    property TitleBackgroundPressed: TColor read FTitleBackgroundPressed write SetTitleBackgroundPressed default TDatabaseGridColor.TitleBackgroundPressed;
    property TitleBackgroundSorted: TColor read FTitleBackgroundSorted write SetTitleBackgroundSorted default TDatabaseGridColor.TitleBackgroundSorted;
    property TitleBottomLine: TColor read FTitleBottomLine write SetTitleBottomLine default TColors.SysBtnShadow;
    property TitleForeground: TColor read FTitleForeground write SetTitleForeground default TColors.SysBtnText;
    property TitleSortMarker: TColor read FTitleSortMarker write SetTitleSortMarker default TColors.SysBtnShadow;
    property TitleSubCaptionForeground: TColor read FTitleSubCaptionForeground write SetTitleSubCaptionForeground default TColors.SysGrayText;
    property TitleTopLine: TColor read FTitleTopLine write SetTitleTopLine default TColors.SysBtnFace;
    property TitleVerticalLine: TColor read FTitleVerticalLine write SetTitleVerticalLine default TColors.SysBtnShadow;
    property VerticalLine: TColor read FVerticalLine write SetVerticalLine default TColors.SysBtnFace;
  end;

function BlendDatabaseGridColor(const AColor, AWithColor: TColor; const APercent: Integer): TColor;

implementation

uses
  Winapi.Windows, Vcl.Graphics
{$IFDEF DATABASE_GRID_VCL_STYLES}
  , Vcl.Themes
{$ENDIF};

function BlendDatabaseGridColor(const AColor, AWithColor: TColor; const APercent: Integer): TColor;
var
  LColor, LWithColor: Longint;
begin
  LColor := ColorToRGB(AColor);
  LWithColor := ColorToRGB(AWithColor);

  Result := RGB(GetRValue(LColor) + (GetRValue(LWithColor) - GetRValue(LColor)) * APercent div 100,
    GetGValue(LColor) + (GetGValue(LWithColor) - GetGValue(LColor)) * APercent div 100,
    GetBValue(LColor) + (GetBValue(LWithColor) - GetBValue(LColor)) * APercent div 100);
end;

constructor TDatabaseGridColors.Create;
begin
  inherited Create;

  SetDefaults;
end;

procedure TDatabaseGridColors.Assign(ASource: TPersistent);
begin
  if Assigned(ASource) and (ASource is TDatabaseGridColors) then
  with ASource as TDatabaseGridColors do
  begin
    Self.FActiveRowBackground := FActiveRowBackground;
    Self.FActiveRowBackgroundUnfocused := FActiveRowBackgroundUnfocused;
    Self.FActiveRowForeground := FActiveRowForeground;
    Self.FActiveRowForegroundUnfocused := FActiveRowForegroundUnfocused;
    Self.FCurrentCellBorder := FCurrentCellBorder;
    Self.FCurrentRowBackground := FCurrentRowBackground;
    Self.FDataBackground := FDataBackground;
    Self.FDataBackgroundAlternate := FDataBackgroundAlternate;
    Self.FDataForeground := FDataForeground;
    Self.FEditButtonBackground := FEditButtonBackground;
    Self.FEditButtonGlyph := FEditButtonGlyph;
    Self.FFooterBackground := FFooterBackground;
    Self.FFooterForeground := FFooterForeground;
    Self.FFooterLine := FFooterLine;
    Self.FGridBackground := FGridBackground;
    Self.FGroupRowBackground := FGroupRowBackground;
    Self.FGroupRowExpander := FGroupRowExpander;
    Self.FGroupRowForeground := FGroupRowForeground;
    Self.FGroupRowLine := FGroupRowLine;
    Self.FHorizontalLine := FHorizontalLine;
    Self.FIndicatorArrow := FIndicatorArrow;
    Self.FIndicatorBackground := FIndicatorBackground;
    Self.FIndicatorCheckBoxBackground := FIndicatorCheckBoxBackground;
    Self.FIndicatorCheckBoxBorder := FIndicatorCheckBoxBorder;
    Self.FIndicatorCheckBoxMark := FIndicatorCheckBoxMark;
    Self.FIndicatorDropDownSign := FIndicatorDropDownSign;
    Self.FIndicatorLine := FIndicatorLine;
    Self.FReadOnlyBackground := FReadOnlyBackground;
    Self.FReadOnlyForeground := FReadOnlyForeground;
    Self.FSearchMatchBackground := FSearchMatchBackground;
    Self.FSearchMatchForeground := FSearchMatchForeground;
    Self.FSearchPanelBackground := FSearchPanelBackground;
    Self.FSearchPanelBackgroundFocused := FSearchPanelBackgroundFocused;
    Self.FSearchPanelBorder := FSearchPanelBorder;
    Self.FSearchPanelClearGlyph := FSearchPanelClearGlyph;
    Self.FSearchPanelDefaultItemForeground := FSearchPanelDefaultItemForeground;
    Self.FSearchPanelFilterBackground := FSearchPanelFilterBackground;
    Self.FSearchPanelGlyph := FSearchPanelGlyph;
    Self.FSelectionBackground := FSelectionBackground;
    Self.FSelectionBackgroundUnfocused := FSelectionBackgroundUnfocused;
    Self.FSelectionForeground := FSelectionForeground;
    Self.FSelectionForegroundUnfocused := FSelectionForegroundUnfocused;
    Self.FTitleBackground := FTitleBackground;
    Self.FTitleBackgroundPressed := FTitleBackgroundPressed;
    Self.FTitleBackgroundSorted := FTitleBackgroundSorted;
    Self.FTitleBottomLine := FTitleBottomLine;
    Self.FTitleForeground := FTitleForeground;
    Self.FTitleSortMarker := FTitleSortMarker;
    Self.FTitleSubCaptionForeground := FTitleSubCaptionForeground;
    Self.FTitleTopLine := FTitleTopLine;
    Self.FTitleVerticalLine := FTitleVerticalLine;
    Self.FVerticalLine := FVerticalLine;

    Self.DoChange;
  end
  else
    inherited Assign(ASource);
end;

{$IF DEFINED(DATABASE_GRID_VCL_STYLES) or DEFINED(ALPHASKINS)}
procedure TDatabaseGridColors.ResolveBaseColors(const ASource: TDatabaseGridColors; const ABaseColors: TDatabaseGridBaseColors);
var
  LDefaults: TDatabaseGridColors;

  function MapUserColor(const AColor: TColor): TColor;
  begin
{$IFDEF DATABASE_GRID_VCL_STYLES}
    if ABaseColors.MapStyleSystemColors then
      Exit(StyleServices.GetSystemColor(AColor));
{$ENDIF}
    Result := AColor;
  end;

  function Mapped(const AColor, ADefault, ABaseColor: TColor): TColor;
  begin
    Result := if AColor = ADefault then ABaseColor else MapUserColor(AColor);
  end;

begin
  LDefaults := TDatabaseGridColors.Create;
  try
    FActiveRowBackground := Mapped(ASource.FActiveRowBackground, LDefaults.FActiveRowBackground, ABaseColors.Highlight);
    FActiveRowBackgroundUnfocused := Mapped(ASource.FActiveRowBackgroundUnfocused, LDefaults.FActiveRowBackgroundUnfocused, ABaseColors.HighlightUnfocused);
    FActiveRowForeground := Mapped(ASource.FActiveRowForeground, LDefaults.FActiveRowForeground, ABaseColors.HighlightForeground);
    FActiveRowForegroundUnfocused := Mapped(ASource.FActiveRowForegroundUnfocused, LDefaults.FActiveRowForegroundUnfocused, ABaseColors.HighlightForegroundUnfocused);
    FCurrentCellBorder := MapUserColor(ASource.FCurrentCellBorder);
    FCurrentRowBackground := Mapped(ASource.FCurrentRowBackground, LDefaults.FCurrentRowBackground, BlendDatabaseGridColor(ABaseColors.Grid, ABaseColors.Highlight, 20));
    FDataBackground := Mapped(ASource.FDataBackground, LDefaults.FDataBackground, ABaseColors.Grid);
    FDataBackgroundAlternate := MapUserColor(ASource.FDataBackgroundAlternate);
    FDataForeground := Mapped(ASource.FDataForeground, LDefaults.FDataForeground, ABaseColors.Text);
    FEditButtonBackground := Mapped(ASource.FEditButtonBackground, LDefaults.FEditButtonBackground, ABaseColors.HeaderBackground);
    FEditButtonGlyph := Mapped(ASource.FEditButtonGlyph, LDefaults.FEditButtonGlyph, ABaseColors.HeaderForeground);
    FFooterBackground := Mapped(ASource.FFooterBackground, LDefaults.FFooterBackground, ABaseColors.HeaderBackground);
    FFooterForeground := Mapped(ASource.FFooterForeground, LDefaults.FFooterForeground, ABaseColors.HeaderForeground);
    FFooterLine := Mapped(ASource.FFooterLine, LDefaults.FFooterLine, ABaseColors.Line);
    FGridBackground := Mapped(ASource.FGridBackground, LDefaults.FGridBackground, ABaseColors.Grid);
    FGroupRowBackground := Mapped(ASource.FGroupRowBackground, LDefaults.FGroupRowBackground, BlendDatabaseGridColor(ABaseColors.Grid, ABaseColors.HeaderBackground, 50));
    FGroupRowExpander := Mapped(ASource.FGroupRowExpander, LDefaults.FGroupRowExpander, ABaseColors.GrayText);
    FGroupRowForeground := Mapped(ASource.FGroupRowForeground, LDefaults.FGroupRowForeground, ABaseColors.Text);
    FGroupRowLine := Mapped(ASource.FGroupRowLine, LDefaults.FGroupRowLine, ABaseColors.GroupRowLine);
    FHorizontalLine := Mapped(ASource.FHorizontalLine, LDefaults.FHorizontalLine, ABaseColors.GridLine);
    FIndicatorArrow := Mapped(ASource.FIndicatorArrow, LDefaults.FIndicatorArrow, ABaseColors.HeaderForeground);
    FIndicatorBackground := Mapped(ASource.FIndicatorBackground, LDefaults.FIndicatorBackground, ABaseColors.Grid);
    FIndicatorCheckBoxBackground := Mapped(ASource.FIndicatorCheckBoxBackground, LDefaults.FIndicatorCheckBoxBackground, ABaseColors.Grid);
    FIndicatorCheckBoxBorder := Mapped(ASource.FIndicatorCheckBoxBorder, LDefaults.FIndicatorCheckBoxBorder, ABaseColors.Line);
    FIndicatorCheckBoxMark := Mapped(ASource.FIndicatorCheckBoxMark, LDefaults.FIndicatorCheckBoxMark, ABaseColors.Text);
    FIndicatorDropDownSign := Mapped(ASource.FIndicatorDropDownSign, LDefaults.FIndicatorDropDownSign, ABaseColors.HeaderForeground);
    FIndicatorLine := Mapped(ASource.FIndicatorLine, LDefaults.FIndicatorLine, ABaseColors.GridLine);
    FReadOnlyBackground := Mapped(ASource.FReadOnlyBackground, LDefaults.FReadOnlyBackground, BlendDatabaseGridColor(ABaseColors.Grid, ABaseColors.HeaderBackground, 50));
    FReadOnlyForeground := Mapped(ASource.FReadOnlyForeground, LDefaults.FReadOnlyForeground, ABaseColors.GrayText);
    FSearchMatchBackground := ASource.FSearchMatchBackground;
    FSearchMatchForeground := ASource.FSearchMatchForeground;
    FSearchPanelBackground := Mapped(ASource.FSearchPanelBackground, LDefaults.FSearchPanelBackground, ABaseColors.Grid);
    FSearchPanelBackgroundFocused := Mapped(ASource.FSearchPanelBackgroundFocused, LDefaults.FSearchPanelBackgroundFocused, BlendDatabaseGridColor(ABaseColors.Grid, ABaseColors.Highlight, 20));
    FSearchPanelBorder := Mapped(ASource.FSearchPanelBorder, LDefaults.FSearchPanelBorder, ABaseColors.Line);
    FSearchPanelClearGlyph := Mapped(ASource.FSearchPanelClearGlyph, LDefaults.FSearchPanelClearGlyph, LDefaults.FSearchPanelClearGlyph);
    FSearchPanelDefaultItemForeground := Mapped(ASource.FSearchPanelDefaultItemForeground, LDefaults.FSearchPanelDefaultItemForeground, LDefaults.FSearchPanelDefaultItemForeground);
    FSearchPanelFilterBackground := Mapped(ASource.FSearchPanelFilterBackground, LDefaults.FSearchPanelFilterBackground, BlendDatabaseGridColor(ABaseColors.Grid, TColors.Yellow, 20));
    FSearchPanelGlyph := Mapped(ASource.FSearchPanelGlyph, LDefaults.FSearchPanelGlyph, ABaseColors.HeaderForeground);
    FSelectionBackground := Mapped(ASource.FSelectionBackground, LDefaults.FSelectionBackground, BlendDatabaseGridColor(ABaseColors.Grid, ABaseColors.Highlight, 35));
    FSelectionBackgroundUnfocused := Mapped(ASource.FSelectionBackgroundUnfocused, LDefaults.FSelectionBackgroundUnfocused, BlendDatabaseGridColor(ABaseColors.Grid, ABaseColors.HeaderBackground, 60));
    FSelectionForeground := Mapped(ASource.FSelectionForeground, LDefaults.FSelectionForeground, ABaseColors.Text);
    FSelectionForegroundUnfocused := Mapped(ASource.FSelectionForegroundUnfocused, LDefaults.FSelectionForegroundUnfocused, ABaseColors.Text);
    FTitleBackground := Mapped(ASource.FTitleBackground, LDefaults.FTitleBackground, ABaseColors.HeaderBackground);
    FTitleBackgroundPressed := Mapped(ASource.FTitleBackgroundPressed, LDefaults.FTitleBackgroundPressed, ABaseColors.HeaderBackgroundPressed);
    FTitleBackgroundSorted := Mapped(ASource.FTitleBackgroundSorted, LDefaults.FTitleBackgroundSorted, ABaseColors.HeaderBackgroundHot);
    FTitleBottomLine := Mapped(ASource.FTitleBottomLine, LDefaults.FTitleBottomLine, ABaseColors.TitleBottomLine);
    FTitleForeground := Mapped(ASource.FTitleForeground, LDefaults.FTitleForeground, ABaseColors.HeaderForeground);
    FTitleSortMarker := Mapped(ASource.FTitleSortMarker, LDefaults.FTitleSortMarker, ABaseColors.HeaderForeground);
    FTitleSubCaptionForeground := Mapped(ASource.FTitleSubCaptionForeground, LDefaults.FTitleSubCaptionForeground, ABaseColors.GrayText);
    FTitleTopLine := Mapped(ASource.FTitleTopLine, LDefaults.FTitleTopLine, ABaseColors.TitleTopLine);
    FTitleVerticalLine := Mapped(ASource.FTitleVerticalLine, LDefaults.FTitleVerticalLine, ABaseColors.Line);
    FVerticalLine := Mapped(ASource.FVerticalLine, LDefaults.FVerticalLine, ABaseColors.GridLine);
  finally
    LDefaults.Free;
  end;

  DoChange;
end;
{$ENDIF}

{$IFDEF ALPHASKINS}
procedure TDatabaseGridColors.ResolveSkin(const ASource: TDatabaseGridColors; const ASkinManager: TsSkinManager);
var
  LBaseColors: TDatabaseGridBaseColors;
begin
  if not Assigned(ASkinManager) or not ASkinManager.IsActive then
  begin
    ResolveStyle(ASource);
    Exit;
  end;

  LBaseColors.Grid := ASkinManager.Palette[pcEditBG];
  LBaseColors.Text := ASkinManager.Palette[pcEditText];
  LBaseColors.GrayText := BlendDatabaseGridColor(LBaseColors.Grid, LBaseColors.Text, 55);
  LBaseColors.Highlight := ASkinManager.Palette[pcSelectionBG_Focused];
  LBaseColors.HighlightForeground := ASkinManager.Palette[pcSelectionText_Focused];
  LBaseColors.HighlightUnfocused := ASkinManager.Palette[pcSelectionBG];
  LBaseColors.HighlightForegroundUnfocused := ASkinManager.Palette[pcSelectionText];
  LBaseColors.HeaderBackground := ASkinManager.Palette[pcMainColor];
  LBaseColors.HeaderForeground := ASkinManager.Palette[pcLabelText];
  LBaseColors.HeaderBackgroundHot := BlendDatabaseGridColor(LBaseColors.HeaderBackground, LBaseColors.Highlight, 20);
  LBaseColors.HeaderBackgroundPressed := BlendDatabaseGridColor(LBaseColors.HeaderBackground, LBaseColors.HeaderForeground, 20);
  LBaseColors.Line := BlendDatabaseGridColor(LBaseColors.Grid, LBaseColors.Text, 30);
  LBaseColors.GridLine := BlendDatabaseGridColor(LBaseColors.Grid, LBaseColors.Text, 12);
  LBaseColors.GroupRowLine := TColors.SysNone;
  LBaseColors.TitleBottomLine := LBaseColors.HeaderBackground;
  LBaseColors.TitleTopLine := LBaseColors.HeaderBackground;
  LBaseColors.MapStyleSystemColors := False;

  ResolveBaseColors(ASource, LBaseColors);
end;
{$ENDIF}

procedure TDatabaseGridColors.ResolveStyle(const ASource: TDatabaseGridColors);
{$IFDEF DATABASE_GRID_VCL_STYLES}
var
  LBaseColors: TDatabaseGridBaseColors;

  function ElementColor(const AHeader: TThemedHeader; const AElementColor: TElementColor; const ADefault: TColor): TColor;
  begin
    if not StyleServices.GetElementColor(StyleServices.GetElementDetails(AHeader), AElementColor, Result) or
      (Result = TColors.SysNone) then
      Result := StyleServices.GetSystemColor(ADefault);
  end;

begin
  if not TStyleManager.IsCustomStyleActive then
  begin
    Assign(ASource);
    Exit;
  end;

  LBaseColors.Grid := StyleServices.GetStyleColor(scGrid);
  LBaseColors.Text := StyleServices.GetStyleFontColor(sfGridItemNormal);
  LBaseColors.GrayText := StyleServices.GetSystemColor(TColors.SysGrayText);
  LBaseColors.Highlight := StyleServices.GetSystemColor(TColors.SysHighlight);
  LBaseColors.HighlightForeground := StyleServices.GetStyleFontColor(sfGridItemSelected);
  LBaseColors.Line := BlendDatabaseGridColor(LBaseColors.Grid, StyleServices.GetSystemColor(TColors.SysBtnShadow), 60);
  LBaseColors.GridLine := BlendDatabaseGridColor(LBaseColors.Grid, StyleServices.GetSystemColor(TColors.SysBtnShadow), 25);
  LBaseColors.HeaderBackground := ElementColor(thHeaderItemNormal, ecFillColor, TColors.SysBtnFace);
  LBaseColors.HeaderBackgroundHot := ElementColor(thHeaderItemHot, ecFillColor, TColors.SysBtnFace);
  LBaseColors.HeaderBackgroundPressed := ElementColor(thHeaderItemPressed, ecFillColor, TColors.SysBtnShadow);
  LBaseColors.HeaderForeground := ElementColor(thHeaderItemNormal, ecTextColor, TColors.SysBtnText);
  LBaseColors.HighlightUnfocused := LBaseColors.HeaderBackground;
  LBaseColors.HighlightForegroundUnfocused := LBaseColors.Text;
  LBaseColors.GroupRowLine := LBaseColors.GridLine;
  LBaseColors.TitleBottomLine := LBaseColors.Line;
  LBaseColors.TitleTopLine := LBaseColors.GridLine;
  LBaseColors.MapStyleSystemColors := True;

  ResolveBaseColors(ASource, LBaseColors);
end;
{$ELSE}
begin
  Assign(ASource);
end;
{$ENDIF}

procedure TDatabaseGridColors.SetDefaults;
begin
  FActiveRowBackground := TColors.SysHighlight;
  FActiveRowBackgroundUnfocused := TColors.SysBtnFace;
  FActiveRowForeground := TColors.SysHighlightText;
  FActiveRowForegroundUnfocused := TColors.SysWindowText;
  FCurrentCellBorder := TColors.SysNone;
  FCurrentRowBackground := TDatabaseGridColor.CurrentRowBackground;
  FDataBackground := TColors.SysWindow;
  FDataBackgroundAlternate := TColors.SysNone;
  FDataForeground := TColors.SysWindowText;
  FEditButtonBackground := TColors.SysBtnFace;
  FEditButtonGlyph := TColors.SysBtnText;
  FFooterBackground := TColors.SysBtnFace;
  FFooterForeground := TColors.SysBtnText;
  FFooterLine := TColors.SysBtnShadow;
  FGridBackground := TColors.SysWindow;
  FGroupRowBackground := TDatabaseGridColor.GroupRowBackground;
  FGroupRowExpander := TColors.SysGrayText;
  FGroupRowForeground := TColors.SysWindowText;
  FGroupRowLine := TDatabaseGridColor.GroupRowLine;
  FHorizontalLine := TColors.SysBtnFace;
  FIndicatorArrow := TColors.SysWindowText;
  FIndicatorBackground := TColors.SysWindow;
  FIndicatorCheckBoxBackground := TColors.SysWindow;
  FIndicatorCheckBoxBorder := TColors.MedGray;
  FIndicatorCheckBoxMark := TColors.SysWindowText;
  FIndicatorDropDownSign := TColors.SysWindowText;
  FIndicatorLine := TColors.SysBtnFace;
  FReadOnlyBackground := TDatabaseGridColor.ReadOnlyBackground;
  FReadOnlyForeground := TColors.SysGrayText;
  FSearchMatchBackground := TDatabaseGridColor.SearchMatchBackground;
  FSearchMatchForeground := TColors.SysWindowText;
  FSearchPanelBackground := TColors.SysBtnFace;
  FSearchPanelBackgroundFocused := TDatabaseGridColor.SearchPanelBackgroundFocused;
  FSearchPanelBorder := TDatabaseGridColor.SearchPanelBorder;
  FSearchPanelClearGlyph := TDatabaseGridColor.SearchPanelClearGlyph;
  FSearchPanelDefaultItemForeground := TColors.SysGrayText;
  FSearchPanelFilterBackground := TDatabaseGridColor.SearchPanelFilterBackground;
  FSearchPanelGlyph := TColors.SysBtnText;
  FSelectionBackground := TDatabaseGridColor.SelectionBackground;
  FSelectionBackgroundUnfocused := TDatabaseGridColor.SelectionBackgroundUnfocused;
  FSelectionForeground := TColors.SysWindowText;
  FSelectionForegroundUnfocused := TColors.SysWindowText;
  FTitleBackground := TColors.SysBtnFace;
  FTitleBackgroundPressed := TDatabaseGridColor.TitleBackgroundPressed;
  FTitleBackgroundSorted := TDatabaseGridColor.TitleBackgroundSorted;
  FTitleBottomLine := TColors.SysBtnShadow;
  FTitleForeground := TColors.SysBtnText;
  FTitleSortMarker := TColors.SysBtnShadow;
  FTitleSubCaptionForeground := TColors.SysGrayText;
  FTitleTopLine := TColors.SysBtnFace;
  FTitleVerticalLine := TColors.SysBtnShadow;
  FVerticalLine := TColors.SysBtnFace;

  DoChange;
end;

procedure TDatabaseGridColors.DoChange;
begin
  if Assigned(FOnChange) then
    FOnChange(Self);
end;

procedure TDatabaseGridColors.SetColor(var AColor: TColor; const AValue: TColor);
begin
  if AColor <> AValue then
  begin
    AColor := AValue;

    DoChange;
  end;
end;

procedure TDatabaseGridColors.SetActiveRowBackground(const AValue: TColor);
begin
  SetColor(FActiveRowBackground, AValue);
end;

procedure TDatabaseGridColors.SetActiveRowBackgroundUnfocused(const AValue: TColor);
begin
  SetColor(FActiveRowBackgroundUnfocused, AValue);
end;

procedure TDatabaseGridColors.SetActiveRowForeground(const AValue: TColor);
begin
  SetColor(FActiveRowForeground, AValue);
end;

procedure TDatabaseGridColors.SetActiveRowForegroundUnfocused(const AValue: TColor);
begin
  SetColor(FActiveRowForegroundUnfocused, AValue);
end;

procedure TDatabaseGridColors.SetCurrentCellBorder(const AValue: TColor);
begin
  SetColor(FCurrentCellBorder, AValue);
end;

procedure TDatabaseGridColors.SetCurrentRowBackground(const AValue: TColor);
begin
  SetColor(FCurrentRowBackground, AValue);
end;

procedure TDatabaseGridColors.SetDataBackground(const AValue: TColor);
begin
  SetColor(FDataBackground, AValue);
end;

procedure TDatabaseGridColors.SetDataBackgroundAlternate(const AValue: TColor);
begin
  SetColor(FDataBackgroundAlternate, AValue);
end;

procedure TDatabaseGridColors.SetDataForeground(const AValue: TColor);
begin
  SetColor(FDataForeground, AValue);
end;

procedure TDatabaseGridColors.SetEditButtonBackground(const AValue: TColor);
begin
  SetColor(FEditButtonBackground, AValue);
end;

procedure TDatabaseGridColors.SetEditButtonGlyph(const AValue: TColor);
begin
  SetColor(FEditButtonGlyph, AValue);
end;

procedure TDatabaseGridColors.SetFooterBackground(const AValue: TColor);
begin
  SetColor(FFooterBackground, AValue);
end;

procedure TDatabaseGridColors.SetFooterForeground(const AValue: TColor);
begin
  SetColor(FFooterForeground, AValue);
end;

procedure TDatabaseGridColors.SetFooterLine(const AValue: TColor);
begin
  SetColor(FFooterLine, AValue);
end;

procedure TDatabaseGridColors.SetGridBackground(const AValue: TColor);
begin
  SetColor(FGridBackground, AValue);
end;

procedure TDatabaseGridColors.SetGroupRowBackground(const AValue: TColor);
begin
  SetColor(FGroupRowBackground, AValue);
end;

procedure TDatabaseGridColors.SetGroupRowExpander(const AValue: TColor);
begin
  SetColor(FGroupRowExpander, AValue);
end;

procedure TDatabaseGridColors.SetGroupRowForeground(const AValue: TColor);
begin
  SetColor(FGroupRowForeground, AValue);
end;

procedure TDatabaseGridColors.SetGroupRowLine(const AValue: TColor);
begin
  SetColor(FGroupRowLine, AValue);
end;

procedure TDatabaseGridColors.SetHorizontalLine(const AValue: TColor);
begin
  SetColor(FHorizontalLine, AValue);
end;

procedure TDatabaseGridColors.SetIndicatorArrow(const AValue: TColor);
begin
  SetColor(FIndicatorArrow, AValue);
end;

procedure TDatabaseGridColors.SetIndicatorBackground(const AValue: TColor);
begin
  SetColor(FIndicatorBackground, AValue);
end;

procedure TDatabaseGridColors.SetIndicatorCheckBoxBackground(const AValue: TColor);
begin
  SetColor(FIndicatorCheckBoxBackground, AValue);
end;

procedure TDatabaseGridColors.SetIndicatorCheckBoxBorder(const AValue: TColor);
begin
  SetColor(FIndicatorCheckBoxBorder, AValue);
end;

procedure TDatabaseGridColors.SetIndicatorCheckBoxMark(const AValue: TColor);
begin
  SetColor(FIndicatorCheckBoxMark, AValue);
end;

procedure TDatabaseGridColors.SetIndicatorDropDownSign(const AValue: TColor);
begin
  SetColor(FIndicatorDropDownSign, AValue);
end;

procedure TDatabaseGridColors.SetIndicatorLine(const AValue: TColor);
begin
  SetColor(FIndicatorLine, AValue);
end;

procedure TDatabaseGridColors.SetReadOnlyBackground(const AValue: TColor);
begin
  SetColor(FReadOnlyBackground, AValue);
end;

procedure TDatabaseGridColors.SetReadOnlyForeground(const AValue: TColor);
begin
  SetColor(FReadOnlyForeground, AValue);
end;

procedure TDatabaseGridColors.SetSearchMatchBackground(const AValue: TColor);
begin
  SetColor(FSearchMatchBackground, AValue);
end;

procedure TDatabaseGridColors.SetSearchMatchForeground(const AValue: TColor);
begin
  SetColor(FSearchMatchForeground, AValue);
end;

procedure TDatabaseGridColors.SetSearchPanelBackground(const AValue: TColor);
begin
  SetColor(FSearchPanelBackground, AValue);
end;

procedure TDatabaseGridColors.SetSearchPanelBackgroundFocused(const AValue: TColor);
begin
  SetColor(FSearchPanelBackgroundFocused, AValue);
end;

procedure TDatabaseGridColors.SetSearchPanelBorder(const AValue: TColor);
begin
  SetColor(FSearchPanelBorder, AValue);
end;

procedure TDatabaseGridColors.SetSearchPanelClearGlyph(const AValue: TColor);
begin
  SetColor(FSearchPanelClearGlyph, AValue);
end;

procedure TDatabaseGridColors.SetSearchPanelDefaultItemForeground(const AValue: TColor);
begin
  SetColor(FSearchPanelDefaultItemForeground, AValue);
end;

procedure TDatabaseGridColors.SetSearchPanelFilterBackground(const AValue: TColor);
begin
  SetColor(FSearchPanelFilterBackground, AValue);
end;

procedure TDatabaseGridColors.SetSearchPanelGlyph(const AValue: TColor);
begin
  SetColor(FSearchPanelGlyph, AValue);
end;

procedure TDatabaseGridColors.SetSelectionBackground(const AValue: TColor);
begin
  SetColor(FSelectionBackground, AValue);
end;

procedure TDatabaseGridColors.SetSelectionBackgroundUnfocused(const AValue: TColor);
begin
  SetColor(FSelectionBackgroundUnfocused, AValue);
end;

procedure TDatabaseGridColors.SetSelectionForeground(const AValue: TColor);
begin
  SetColor(FSelectionForeground, AValue);
end;

procedure TDatabaseGridColors.SetSelectionForegroundUnfocused(const AValue: TColor);
begin
  SetColor(FSelectionForegroundUnfocused, AValue);
end;

procedure TDatabaseGridColors.SetTitleBackground(const AValue: TColor);
begin
  SetColor(FTitleBackground, AValue);
end;

procedure TDatabaseGridColors.SetTitleBackgroundPressed(const AValue: TColor);
begin
  SetColor(FTitleBackgroundPressed, AValue);
end;

procedure TDatabaseGridColors.SetTitleBackgroundSorted(const AValue: TColor);
begin
  SetColor(FTitleBackgroundSorted, AValue);
end;

procedure TDatabaseGridColors.SetTitleBottomLine(const AValue: TColor);
begin
  SetColor(FTitleBottomLine, AValue);
end;

procedure TDatabaseGridColors.SetTitleForeground(const AValue: TColor);
begin
  SetColor(FTitleForeground, AValue);
end;

procedure TDatabaseGridColors.SetTitleTopLine(const AValue: TColor);
begin
  SetColor(FTitleTopLine, AValue);
end;

procedure TDatabaseGridColors.SetTitleSortMarker(const AValue: TColor);
begin
  SetColor(FTitleSortMarker, AValue);
end;

procedure TDatabaseGridColors.SetTitleSubCaptionForeground(const AValue: TColor);
begin
  SetColor(FTitleSubCaptionForeground, AValue);
end;

procedure TDatabaseGridColors.SetTitleVerticalLine(const AValue: TColor);
begin
  SetColor(FTitleVerticalLine, AValue);
end;

procedure TDatabaseGridColors.SetVerticalLine(const AValue: TColor);
begin
  SetColor(FVerticalLine, AValue);
end;

end.
