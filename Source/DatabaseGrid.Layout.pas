unit DatabaseGrid.Layout;

interface

uses
  Winapi.Windows, System.Classes, System.Types, Vcl.Graphics, DatabaseGrid.ColumnFilter, DatabaseGrid.Columns, DatabaseGrid.Indicator,
  DatabaseGrid.Title, DatabaseGrid.Types;

type
  TDatabaseGridLayout = class(TObject)
  strict private type
    TDatabaseGridColumnPlace = record
      Column: TDatabaseGridColumn;
      Offset: Integer;
      TitleLines: TArray<string>;
      TitleParts: TArray<string>;
      Width: Integer;
    end;
  strict private
    FCharWidth: Integer;
    FClientRect: TRect;
    FColumnFilter: TDatabaseGridColumnFilter;
    FColumnPlaces: TArray<TDatabaseGridColumnPlace>;
    FColumnsWidth: Integer;
    FDataRect: TRect;
    FDataTop: Integer;
    FFontHeight: Integer;
    FFooterHeight: Integer;
    FFooterVisible: Boolean;
    FGroupIndent: Integer;
    FGroupLevelWidth: Integer;
    FGroupRowHeight: Integer;
    FHorizontalPosition: Integer;
    FHotTitleColumn: TDatabaseGridColumn;
    FIndicator: TDatabaseGridIndicator;
    FIndicatorWidth: Integer;
    FLeftLineWidth: Integer;
    FMeasureBitmap: TBitmap;
    FPixelsPerInch: Integer;
    FRowHeight: Integer;
    FSearchPanelControlHeight: Integer;
    FSearchPanelTextHeight: Integer;
    FSortNumberFontHeight: Integer;
    FTextHeight: Integer;
    FTitle: TDatabaseGridTitle;
    FTitleHeight: Integer;
    FTitleLevelCount: Integer;
    FTitleLevelHeight: Integer;
    FTitleLineCount: Integer;
    FTitleTop: Integer;
    FVisibleRowCount: Integer;
    FZoomPercentage: Integer;
    function GetColumnsLeft: Integer;
    function GetColumnsRight: Integer;
    function GetRowsLeft: Integer;
    function GetTitleTextWidth(const AIndex: Integer): Integer;
    function GetVisibleColumn(const AIndex: Integer): TDatabaseGridColumn;
    function GetVisibleColumnCount: Integer;
    function ScaleUnzoomedMetric(const AValue: Integer): Integer;
    function WrapTitle(const AText: string; const AWidth: Integer): TArray<string>;
    procedure CalculateTitles;
  public
    constructor Create(const AColumnFilter: TDatabaseGridColumnFilter; const AIndicator: TDatabaseGridIndicator;
      const ATitle: TDatabaseGridTitle);
    destructor Destroy; override;
    function GetAreaAt(const AX, AY: Integer): TDatabaseGridArea;
    function GetCheckBoxRect(const ATop: Integer): TRect;
    function GetColumnAt(const AX: Integer; out ALeft: Integer): TDatabaseGridColumn;
    function GetColumnWidth(const AColumn: TDatabaseGridColumn): Integer;
    function GetEditButtonWidth: Integer;
    function GetResizeColumnAt(const AX: Integer): TDatabaseGridColumn;
    function GetTitleButtonsRect(const AColumn: TDatabaseGridColumn; const ATitleRect: TRect): TRect;
    function GetTitleButtonsWidth(const AColumn: TDatabaseGridColumn): Integer;
    function GetTitleColumnAt(const AX, AY: Integer; out ALeft: Integer): TDatabaseGridColumn;
    function GetTitleLines(const AIndex: Integer): TArray<string>;
    function GetTitleParts(const AIndex: Integer): TArray<string>;
    function GetTitleTop(const AIndex: Integer): Integer;
    function GetVisibleColumnLeft(const AIndex: Integer): Integer;
    function GetVisibleColumnRight(const AIndex: Integer): Integer;
    function IndexOfVisibleColumn(const AColumn: TDatabaseGridColumn): Integer;
    function ScaleMetric(const AValue: Integer): Integer;
    function ShowsFilterDropDown(const AColumn: TDatabaseGridColumn): Boolean;
    function ShowsFilterIcon(const AColumn: TDatabaseGridColumn): Boolean;
    function TryGetColumnLeft(const AColumn: TDatabaseGridColumn; out ALeft: Integer): Boolean;
    function UnzoomWidth(const AWidth: Integer): Integer;
    function ZoomWidth(const AWidth: Integer): Integer;
    procedure Calculate(const AClientRect: TRect; const ASearchPanelVisible, AFooterVisible: Boolean; const AGroupLevelCount: Integer; const ALeftLine: Boolean);
    procedure FitColumns(const AMinWidth: Integer);
    procedure UpdateColumns(const AColumns: TDatabaseGridColumns);
    procedure UpdateMetrics(const AFont: TFont; const APixelsPerInch, AZoomPercentage: Integer);
    property CharWidth: Integer read FCharWidth;
    property ColumnsLeft: Integer read GetColumnsLeft;
    property ColumnsRight: Integer read GetColumnsRight;
    property ColumnsWidth: Integer read FColumnsWidth;
    property DataLeft: Integer read FDataRect.Left;
    property DataRect: TRect read FDataRect;
    property DataTop: Integer read FDataTop;
    property FontHeight: Integer read FFontHeight;
    property FooterTop: Integer read FDataRect.Bottom;
    property FooterVisible: Boolean read FFooterVisible;
    property GroupIndent: Integer read FGroupIndent;
    property GroupLevelWidth: Integer read FGroupLevelWidth;
    property GroupRowHeight: Integer read FGroupRowHeight;
    property HorizontalPosition: Integer read FHorizontalPosition write FHorizontalPosition;
    property HotTitleColumn: TDatabaseGridColumn read FHotTitleColumn write FHotTitleColumn;
    property IndicatorWidth: Integer read FIndicatorWidth;
    property LeftLineWidth: Integer read FLeftLineWidth;
    property RowHeight: Integer read FRowHeight;
    property RowsLeft: Integer read GetRowsLeft;
    property SearchPanelControlHeight: Integer read FSearchPanelControlHeight;
    property SortNumberFontHeight: Integer read FSortNumberFontHeight;
    property TextHeight: Integer read FTextHeight;
    property TitleHeight: Integer read FTitleHeight;
    property TitleLevelCount: Integer read FTitleLevelCount;
    property TitleLevelHeight: Integer read FTitleLevelHeight;
    property TitleLineCount: Integer read FTitleLineCount;
    property TitleTop: Integer read FTitleTop;
    property VisibleColumnCount: Integer read GetVisibleColumnCount;
    property VisibleColumns[const AIndex: Integer]: TDatabaseGridColumn read GetVisibleColumn;
    property VisibleRowCount: Integer read FVisibleRowCount;
  end;

implementation

uses
  System.Math, System.SysUtils, DatabaseGrid.Consts;

constructor TDatabaseGridLayout.Create(const AColumnFilter: TDatabaseGridColumnFilter; const AIndicator: TDatabaseGridIndicator;
  const ATitle: TDatabaseGridTitle);
begin
  inherited Create;

  FColumnFilter := AColumnFilter;
  FIndicator := AIndicator;
  FTitle := ATitle;
  FMeasureBitmap := TBitmap.Create;
  FPixelsPerInch := USER_DEFAULT_SCREEN_DPI;
  FTitleLevelCount := 1;
  FTitleLineCount := 1;
  FZoomPercentage := TDatabaseGridDefault.ZoomPercentage;
end;

destructor TDatabaseGridLayout.Destroy;
begin
  FMeasureBitmap.Free;

  inherited Destroy;
end;

function TDatabaseGridLayout.GetAreaAt(const AX, AY: Integer): TDatabaseGridArea;
begin
  if FFooterVisible and (AY >= FDataRect.Bottom) then
    Result := gaFooter
  else
  if AY < FTitleTop then
    Result := gaSearchPanel
  else
  if AY < FDataTop then
  begin
    if AX < FIndicatorWidth then
      Result := gaIndicatorTitle
    else
      Result := gaTitle;
  end
  else
  if AX < FIndicatorWidth then
    Result := gaIndicator
  else
    Result := gaData;
end;

function TDatabaseGridLayout.GetCheckBoxRect(const ATop: Integer): TRect;
var
  LSize: Integer;
begin
  LSize := Min(ScaleMetric(TDatabaseGridSize.CheckBox), FRowHeight - 4);

  Result.Left := (FRowHeight - LSize) div 2;
  Result.Top := ATop + (FRowHeight - 1 - LSize) div 2;
  Result.Right := Result.Left + LSize;
  Result.Bottom := Result.Top + LSize;
end;

function TDatabaseGridLayout.GetColumnAt(const AX: Integer; out ALeft: Integer): TDatabaseGridColumn;
var
  LHigh, LLow, LMiddle, LOffset: Integer;
begin
  ALeft := GetColumnsLeft;

  if (AX < FDataRect.Left) or (AX >= GetColumnsRight) then
    Exit(nil);

  LOffset := AX - ALeft;
  LLow := 0;
  LHigh := High(FColumnPlaces);

  while LLow < LHigh do
  begin
    LMiddle := (LLow + LHigh) shr 1;

    if FColumnPlaces[LMiddle].Offset + FColumnPlaces[LMiddle].Width > LOffset then
      LHigh := LMiddle
    else
      LLow := LMiddle + 1;
  end;

  Inc(ALeft, FColumnPlaces[LLow].Offset);

  Result := FColumnPlaces[LLow].Column;
end;

function TDatabaseGridLayout.GetColumnWidth(const AColumn: TDatabaseGridColumn): Integer;
var
  LIndex: Integer;
begin
  LIndex := IndexOfVisibleColumn(AColumn);

  if LIndex >= 0 then
    Result := FColumnPlaces[LIndex].Width
  else
    Result := ZoomWidth(AColumn.Width);
end;

function TDatabaseGridLayout.GetEditButtonWidth: Integer;
begin
  Result := ScaleMetric(TDatabaseGridSize.EditButtonWidth);
end;

function TDatabaseGridLayout.GetColumnsLeft: Integer;
begin
  Result := FDataRect.Left - FHorizontalPosition;
end;

function TDatabaseGridLayout.GetColumnsRight: Integer;
begin
  Result := GetColumnsLeft + FColumnsWidth;
end;

function TDatabaseGridLayout.GetResizeColumnAt(const AX: Integer): TDatabaseGridColumn;
var
  LMargin: Integer;
begin
  Result := nil;

  LMargin := ScaleMetric(TDatabaseGridSize.ColumnResizeMargin);

  for var LIndex := 0 to High(FColumnPlaces) do
  if Abs(AX - GetVisibleColumnRight(LIndex)) <= LMargin then
    Result := FColumnPlaces[LIndex].Column;
end;

function TDatabaseGridLayout.GetRowsLeft: Integer;
begin
  Result := FIndicatorWidth + FLeftLineWidth;
end;

function TDatabaseGridLayout.GetTitleButtonsRect(const AColumn: TDatabaseGridColumn; const ATitleRect: TRect): TRect;
begin
  Result := ATitleRect;
  Result.Left := Max(Result.Right - 1 - GetTitleButtonsWidth(AColumn), ATitleRect.Left);
  Dec(Result.Right);
  Dec(Result.Bottom);
end;

function TDatabaseGridLayout.GetTitleButtonsWidth(const AColumn: TDatabaseGridColumn): Integer;
begin
  Result := 0;

  if ShowsFilterDropDown(AColumn) then
    Inc(Result, ScaleMetric(TDatabaseGridSize.FilterButtonWidth));

  if ShowsFilterIcon(AColumn) then
    Inc(Result, ScaleMetric(TDatabaseGridSize.FilterButtonWidth));
end;

function TDatabaseGridLayout.GetTitleColumnAt(const AX, AY: Integer; out ALeft: Integer): TDatabaseGridColumn;
var
  LIndex: Integer;
begin
  Result := GetColumnAt(AX, ALeft);

  if not Assigned(Result) then
    Exit;

  LIndex := IndexOfVisibleColumn(Result);

  if (AY < GetTitleTop(LIndex)) or (AY >= FDataTop) then
    Result := nil;
end;

function TDatabaseGridLayout.GetTitleLines(const AIndex: Integer): TArray<string>;
begin
  Result := FColumnPlaces[AIndex].TitleLines;
end;

function TDatabaseGridLayout.GetTitleParts(const AIndex: Integer): TArray<string>;
begin
  Result := FColumnPlaces[AIndex].TitleParts;
end;

function TDatabaseGridLayout.GetTitleTextWidth(const AIndex: Integer): Integer;
var
  LColumn: TDatabaseGridColumn;
begin
  LColumn := FColumnPlaces[AIndex].Column;
  Result := FColumnPlaces[AIndex].Width - 1 - 2 * ScaleMetric(TDatabaseGridSize.CellPadding);

  if FColumnFilter.Visible then
    Dec(Result, ScaleMetric(TDatabaseGridSize.FilterButtonWidth));

  if LColumn.Title.SortMarker <> smNone then
    Dec(Result, ScaleMetric(TDatabaseGridSize.SortMarkerWidth));
end;

function TDatabaseGridLayout.GetTitleTop(const AIndex: Integer): Integer;
begin
  Result := FTitleTop + High(FColumnPlaces[AIndex].TitleParts) * FTitleLevelHeight;
end;

function TDatabaseGridLayout.GetVisibleColumn(const AIndex: Integer): TDatabaseGridColumn;
begin
  Result := FColumnPlaces[AIndex].Column;
end;

function TDatabaseGridLayout.GetVisibleColumnCount: Integer;
begin
  Result := Length(FColumnPlaces);
end;

function TDatabaseGridLayout.GetVisibleColumnLeft(const AIndex: Integer): Integer;
begin
  Result := GetColumnsLeft + FColumnPlaces[AIndex].Offset;
end;

function TDatabaseGridLayout.GetVisibleColumnRight(const AIndex: Integer): Integer;
begin
  Result := GetColumnsLeft + FColumnPlaces[AIndex].Offset + FColumnPlaces[AIndex].Width;
end;

function TDatabaseGridLayout.IndexOfVisibleColumn(const AColumn: TDatabaseGridColumn): Integer;
begin
  for var LIndex := 0 to High(FColumnPlaces) do
  if FColumnPlaces[LIndex].Column = AColumn then
    Exit(LIndex);

  Result := -1;
end;

function TDatabaseGridLayout.ScaleMetric(const AValue: Integer): Integer;
begin
  Result := MulDiv(AValue, FPixelsPerInch * FZoomPercentage, USER_DEFAULT_SCREEN_DPI * 100);
end;

function TDatabaseGridLayout.ScaleUnzoomedMetric(const AValue: Integer): Integer;
begin
  Result := MulDiv(AValue, FPixelsPerInch, USER_DEFAULT_SCREEN_DPI);
end;

function TDatabaseGridLayout.ShowsFilterDropDown(const AColumn: TDatabaseGridColumn): Boolean;
begin
  Result := FColumnFilter.Visible and ((AColumn = FHotTitleColumn) or (AColumn.Filter.Active and not ShowsFilterIcon(AColumn)));
end;

function TDatabaseGridLayout.ShowsFilterIcon(const AColumn: TDatabaseGridColumn): Boolean;
begin
  Result := FColumnFilter.Visible and AColumn.Filter.Active and (cfoShowFilterIcon in FColumnFilter.Options);
end;

function TDatabaseGridLayout.TryGetColumnLeft(const AColumn: TDatabaseGridColumn; out ALeft: Integer): Boolean;
var
  LIndex: Integer;
begin
  LIndex := IndexOfVisibleColumn(AColumn);
  Result := LIndex >= 0;
  ALeft := if Result then GetVisibleColumnLeft(LIndex) else 0;
end;

function TDatabaseGridLayout.UnzoomWidth(const AWidth: Integer): Integer;
begin
  Result := MulDiv(AWidth, 100, FZoomPercentage);
end;

function TDatabaseGridLayout.WrapTitle(const AText: string; const AWidth: Integer): TArray<string>;
var
  LLine: string;
  LWords: TArray<string>;
begin
  LWords := AText.Split([' '], TStringSplitOptions.ExcludeEmpty);

  if Length(LWords) = 0 then
    Exit(TArray<string>.Create(AText));

  Result := nil;
  LLine := LWords[0];

  for var LIndex := 1 to High(LWords) do
  if (Length(Result) < FTitle.MaxLineCount - 1) and
    (FMeasureBitmap.Canvas.TextWidth(LLine + ' ' + LWords[LIndex]) > AWidth) then
  begin
    Result := Result + [LLine];
    LLine := LWords[LIndex];
  end
  else
    LLine := LLine + ' ' + LWords[LIndex];

  Result := Result + [LLine];
end;

function TDatabaseGridLayout.ZoomWidth(const AWidth: Integer): Integer;
begin
  Result := MulDiv(AWidth, FZoomPercentage, 100);
end;

procedure TDatabaseGridLayout.Calculate(const AClientRect: TRect; const ASearchPanelVisible, AFooterVisible: Boolean;
  const AGroupLevelCount: Integer; const ALeftLine: Boolean);
begin
  FClientRect := AClientRect;
  FFooterVisible := AFooterVisible;
  FIndicatorWidth := 0;
  FLeftLineWidth := Ord(ALeftLine and not FIndicator.Visible);

  if FIndicator.Visible then
  begin
    if ioShowRowIndicator in FIndicator.Options then
      Inc(FIndicatorWidth, ScaleMetric(TDatabaseGridSize.RowIndicatorWidth));

    if ioShowCheckBox in FIndicator.Options then
      Inc(FIndicatorWidth, FRowHeight);

    if FIndicatorWidth = 0 then
      FIndicatorWidth := ScaleMetric(TDatabaseGridSize.RowIndicatorWidth);
  end;

  FTitleTop := 0;
  FSearchPanelControlHeight := 0;

  if ASearchPanelVisible then
  begin
    FSearchPanelControlHeight := FSearchPanelTextHeight + 2 * ScaleUnzoomedMetric(TDatabaseGridSize.SearchPanelControlPadding);
    FTitleTop := FSearchPanelControlHeight + 2 * ScaleUnzoomedMetric(TDatabaseGridSize.SearchPanelPadding) + 1;
  end;

  FGroupLevelWidth := ScaleMetric(TDatabaseGridSize.GroupLevelWidth);
  FGroupIndent := AGroupLevelCount * FGroupLevelWidth;

  FDataRect.Left := Min(GetRowsLeft + FGroupIndent, AClientRect.Right);
  FDataRect.Right := AClientRect.Right;

  CalculateTitles;
end;

procedure TDatabaseGridLayout.CalculateTitles;
var
  LColumn: TDatabaseGridColumn;
  LParts: TArray<string>;
begin
  FTitleLineCount := 1;

  for var LIndex := 0 to High(FColumnPlaces) do
  begin
    LColumn := FColumnPlaces[LIndex].Column;
    LParts := FColumnPlaces[LIndex].TitleParts;

    if toWordWrap in LColumn.Title.Options then
      FColumnPlaces[LIndex].TitleLines := WrapTitle(LParts[High(LParts)], GetTitleTextWidth(LIndex))
    else
      FColumnPlaces[LIndex].TitleLines := [LParts[High(LParts)]];

    FTitleLineCount := Max(FTitleLineCount, Length(FColumnPlaces[LIndex].TitleLines) + Ord(not LColumn.Title.SubCaption.IsEmpty));
  end;

  FTitleLevelHeight := FTextHeight + 2 * ScaleMetric(TDatabaseGridSize.TitlePadding);

  if FTitle.Visible then
    FTitleHeight := (FTitleLevelCount - 1) * FTitleLevelHeight + FTitleLineCount * FTextHeight +
      2 * ScaleMetric(TDatabaseGridSize.TitlePadding)
  else
    FTitleHeight := 0;

  FDataTop := FTitleTop + FTitleHeight;

  FDataRect.Top := Min(FDataTop, FClientRect.Bottom);
  FDataRect.Bottom := FClientRect.Bottom;

  if FFooterVisible then
    FDataRect.Bottom := Max(FClientRect.Bottom - FFooterHeight, FDataRect.Top);

  FVisibleRowCount := Max(FDataRect.Height div FRowHeight, 1);
end;

procedure TDatabaseGridLayout.FitColumns(const AMinWidth: Integer);
var
  LColumn: TDatabaseGridColumn;
  LFixedWidth, LOffset, LPreviousRight, LRight, LSpace, LWeight, LWeightSum: Integer;
begin
  LFixedWidth := 0;
  LWeightSum := 0;

  for var LIndex := 0 to High(FColumnPlaces) do
  begin
    LColumn := FColumnPlaces[LIndex].Column;

    if coAutoFit in LColumn.Options then
      Inc(LWeightSum, LColumn.Width)
    else
      Inc(LFixedWidth, ZoomWidth(LColumn.Width));
  end;

  if LWeightSum <= 0 then
    Exit;

  LSpace := Max(FDataRect.Width - LFixedWidth, 0);
  LOffset := 0;
  LPreviousRight := 0;
  LWeight := 0;

  for var LIndex := 0 to High(FColumnPlaces) do
  begin
    LColumn := FColumnPlaces[LIndex].Column;

    if coAutoFit in LColumn.Options then
    begin
      Inc(LWeight, LColumn.Width);

      LRight := MulDiv(LWeight, LSpace, LWeightSum);

      FColumnPlaces[LIndex].Width := Max(LRight - LPreviousRight, AMinWidth);

      LPreviousRight := LRight;
    end
    else
      FColumnPlaces[LIndex].Width := ZoomWidth(LColumn.Width);

    FColumnPlaces[LIndex].Offset := LOffset;

    Inc(LOffset, FColumnPlaces[LIndex].Width);
  end;

  FColumnsWidth := LOffset;

  CalculateTitles;
end;

procedure TDatabaseGridLayout.UpdateColumns(const AColumns: TDatabaseGridColumns);
var
  LColumn: TDatabaseGridColumn;
  LCount: Integer;
begin
  SetLength(FColumnPlaces, AColumns.Count);

  LCount := 0;
  FColumnsWidth := 0;
  FTitleLevelCount := 1;

  for var LIndex := 0 to AColumns.Count - 1 do
  begin
    LColumn := AColumns[LIndex];

    if LColumn.Visible then
    begin
      FColumnPlaces[LCount].Column := LColumn;
      FColumnPlaces[LCount].Offset := FColumnsWidth;
      FColumnPlaces[LCount].TitleParts := LColumn.Title.GetCaptionParts;
      FColumnPlaces[LCount].TitleLines := [FColumnPlaces[LCount].TitleParts[High(FColumnPlaces[LCount].TitleParts)]];
      FColumnPlaces[LCount].Width := ZoomWidth(LColumn.Width);

      FTitleLevelCount := Max(FTitleLevelCount, Length(FColumnPlaces[LCount].TitleParts));

      Inc(FColumnsWidth, FColumnPlaces[LCount].Width);
      Inc(LCount);
    end;
  end;

  SetLength(FColumnPlaces, LCount);
end;

procedure TDatabaseGridLayout.UpdateMetrics(const AFont: TFont; const APixelsPerInch, AZoomPercentage: Integer);
var
  LBitmap: TBitmap;
  LTextMetric, LZoomedTextMetric: TTextMetric;
begin
  FPixelsPerInch := APixelsPerInch;
  FZoomPercentage := AZoomPercentage;
  FFontHeight := MulDiv(AFont.Height, FZoomPercentage, 100);
  FSortNumberFontHeight := -MulDiv(DATABASE_GRID_SORT_NUMBER_FONT_SIZE, FPixelsPerInch * FZoomPercentage, 72 * 100);

  LBitmap := TBitmap.Create;
  try
    LBitmap.Canvas.Font := AFont;
    LBitmap.Canvas.Font.Height := AFont.Height;

    GetTextMetrics(LBitmap.Canvas.Handle, LTextMetric);

    LBitmap.Canvas.Font.Height := FFontHeight;

    GetTextMetrics(LBitmap.Canvas.Handle, LZoomedTextMetric);
  finally
    LBitmap.Free;
  end;

  FMeasureBitmap.Canvas.Font := AFont;
  FMeasureBitmap.Canvas.Font.Height := FFontHeight;

  FCharWidth := LTextMetric.tmAveCharWidth;
  FSearchPanelTextHeight := LTextMetric.tmHeight;
  FTextHeight := LZoomedTextMetric.tmHeight;
  FRowHeight := FTextHeight + 2 * ScaleMetric(TDatabaseGridSize.RowPadding);
  FGroupRowHeight := FRowHeight + ScaleMetric(TDatabaseGridSize.GroupRowExtraHeight);
  FFooterHeight := FTextHeight + 2 * ScaleMetric(TDatabaseGridSize.TitlePadding);
end;

end.
