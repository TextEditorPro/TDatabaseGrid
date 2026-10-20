unit DatabaseGrid.Painter;

interface

uses
  Winapi.Windows, System.Classes, System.Generics.Collections, System.Types, System.UITypes, Vcl.Graphics, Vcl.ImgList, Data.DB,
  DatabaseGrid.Colors, DatabaseGrid.Columns, DatabaseGrid.DataLink, DatabaseGrid.Groups, DatabaseGrid.Indicator, DatabaseGrid.Layout,
  DatabaseGrid.SelectedRows, DatabaseGrid.Types;

type
  TDatabaseGridDrawCellCallback = procedure(const AColumn: TDatabaseGridColumn; const ACanvas: TCanvas; const ARect: TRect;
    const AState: TDatabaseGridDrawCellStates; var AParams: TDatabaseGridDrawCellParams) of object;
  TDatabaseGridDrawGroupRowCallback = procedure(const ANode: TDatabaseGridGroupNode; const ACanvas: TCanvas; const ARect: TRect;
    const AState: TDatabaseGridDrawCellStates; var AParams: TDatabaseGridDrawGroupRowParams) of object;
  TDatabaseGridColumnPredicate = function(const AColumn: TDatabaseGridColumn): Boolean of object;

  TDatabaseGridPaintState = record
    ClientRect: TRect;
    CurrentColumn: TDatabaseGridColumn;
    DrawColumnCell: TDatabaseGridDrawCellCallback;
    DrawFooterCell: TDatabaseGridDrawCellCallback;
    DrawGroupRow: TDatabaseGridDrawGroupRowCallback;
    DropRow: Integer;
    EditButtonGlyph: TDatabaseGridGlyph;
    EditingColumn: TDatabaseGridColumn;
    Focused: Boolean;
    FooterVerticalLines: Boolean;
    GroupImages: TCustomImageList;
    IsReadOnlyColumn: TDatabaseGridColumnPredicate;
    Options: TDatabaseGridOptions;
    PressedTitleColumn: TDatabaseGridColumn;
    RangeEnd: TBookmark;
    RangeFirstColumn: Integer;
    RangeLastColumn: Integer;
    RangeStart: TBookmark;
    SearchPanelHighlighted: Boolean;
    SearchWords: TArray<string>;
    ShowEditButton: Boolean;
    TitleImages: TCustomImageList;
    TitleVerticalLines: Boolean;
    TopRow: Integer;
  end;

  TDatabaseGridPainter = class(TObject)
  strict private type
    TDatabaseGridCutCell = record
      Rect: TRect;
      Text: string;
    end;

    TDatabaseGridPaintCell = record
      Column: TDatabaseGridColumn;
      Params: TDatabaseGridDrawCellParams;
      Prepared: Boolean;
      Rect: TRect;
      State: TDatabaseGridDrawCellStates;
    end;
  strict private
    FBaseFont: TFont;
    FCanvas: TCanvas;
    FCells: TArray<TDatabaseGridPaintCell>;
    FColors: TDatabaseGridColors;
    FCutCells: TList<TDatabaseGridCutCell>;
    FDataLink: TDatabaseGridDataLink;
    FGroups: TDatabaseGridGroups;
    FIndicator: TDatabaseGridIndicator;
    FLayout: TDatabaseGridLayout;
    FSelectedRows: TDatabaseGridSelectedRows;
    FSortMarkedColumns: TList<TDatabaseGridColumn>;
    FState: TDatabaseGridPaintState;
    function CanOverflowInto(const AIndex, ANextIndex: Integer): Boolean;
    function FindSearchMatches(const AText: string; out AMatches: TArray<Boolean>): Boolean;
    function GetCellText(const AColumn: TDatabaseGridColumn): string;
    function GetCellTextRects(const ARect: TRect; const ARightIndent, ALeftIndent: Integer; out AClipRect, ATextRect: TRect): Boolean;
    function GetLineColor(const ALine, ABackground: TColor): TColor;
    function IsCheckBoxCell(const AIndex: Integer): Boolean;
    function IsEmptyCell(const AIndex: Integer): Boolean;
    function IsRowInRange: Boolean;
    procedure CallDrawCell(const ACallback: TDatabaseGridDrawCellCallback; var ACell: TDatabaseGridPaintCell; const AState: TDatabaseGridDrawCellStates);
    procedure CallDrawGroupRow(const ANode: TDatabaseGridGroupNode; const ARect: TRect; const AState: TDatabaseGridDrawCellStates; var AParams: TDatabaseGridDrawGroupRowParams);
    procedure FillGradient(const ARect: TRect; const ATopColor, ABottomColor: TColor);
    procedure FillRectangle(const ARect: TRect; const AColor: TColor);
    procedure GetCharacterEdges(const AText: string; out ALefts, ARights: TArray<Integer>);
    procedure PaintArrow(const ACenter: TPoint; const ADirection: TDatabaseGridArrowDirection; const AColor: TColor);
    procedure PaintCell(const ARect: TRect; const AText: string; const AAlignment: TAlignment; const ABackground, AForeground, AHorizontalLine, AVerticalLine: TColor;
      const ARightIndent: Integer = 0; const ALeftIndent: Integer = 0; const ALastColumn: Boolean = False);
    procedure PaintCellBackground(const ACell: TDatabaseGridPaintCell; const AHorizontalLine, AVerticalLine: TColor);
    procedure PaintCellCheckBox(const AIndex: Integer);
    procedure PaintCellImage(const AIndex: Integer);
    procedure PaintCells(const AHorizontalLine, AVerticalLine: TColor; const ADataRow: Boolean; const AHideLastVerticalLine: Boolean = False);
    procedure PaintCellText(const AIndex: Integer; const ADataRow: Boolean);
    procedure PaintCheckBox(const ARect: TRect; const AChecked: Boolean);
    procedure PaintDropLine;
    procedure PaintEditButton(const AIndex: Integer);
    procedure PaintEmptyCell(const ALeft, ARight, ATop: Integer);
    procedure PaintEmptyRow(const ATop: Integer);
    procedure PaintEmptyRows(const ATop: Integer);
    procedure PaintFooter;
    procedure PaintGroupedRow(const ARow, ATop: Integer; const AActive: Boolean);
    procedure PaintGroupRow(const ANode: TDatabaseGridGroupNode; const ATop: Integer; const AActive: Boolean);
    procedure PaintImage(const AImages: TCustomImageList; const AImageIndex, AX, AY: Integer; const AClipRect: TRect);
    procedure PaintHighlightedText(const AClipRect: TRect; const ALeft, ATop: Integer; const AText: string; const AMatches: TArray<Boolean>; const AForeground: TColor);
    procedure PaintIndicatorBackground(const ARect: TRect; const ABackground, ABottomLine, ARightLine: TColor);
    procedure PaintIndicatorCell(const ATop, AHeight: Integer; const AActive, ACheckBox, ASelected: Boolean);
    procedure PaintIndicatorTitle;
    procedure PaintLeftLine(const ATop, ABottom: Integer; const ALine, ABackground: TColor);
    procedure PaintRow(const ARowNumber, ATop: Integer; const AActive: Boolean);
    procedure PaintRows(const AClipRect: TRect);
    procedure PaintSearchPanel;
    procedure PaintTextLine(const AClipRect, ATextRect: TRect; const AText: string; const AAlignment: TAlignment; const ATop: Integer; const ABackground, AForeground: TColor);
    procedure PaintTitle;
    procedure PaintTitleGroups(const AVerticalLine: TColor);
    procedure PrepareCellPlaces(const ATop, AHeight: Integer);
    procedure PrepareFooterCells;
    procedure PrepareRowCells(const ABackground, AForeground: TColor; const AState: TDatabaseGridDrawCellStates; const APlainRow, AShowCurrentCell, AInRange: Boolean);
  public
    constructor Create(const AColors: TDatabaseGridColors; const ADataLink: TDatabaseGridDataLink; const AGroups: TDatabaseGridGroups;
      const AIndicator: TDatabaseGridIndicator; const ALayout: TDatabaseGridLayout; const ASelectedRows: TDatabaseGridSelectedRows;
      const ASortMarkedColumns: TList<TDatabaseGridColumn>);
    destructor Destroy; override;
    function TryGetCutCellText(const APoint: TPoint; out AText: string; out ARect: TRect): Boolean;
    procedure Paint(const ACanvas: TCanvas; const AState: TDatabaseGridPaintState);
  end;

implementation

uses
  System.Generics.Defaults, System.Math, System.SysUtils, DatabaseGrid.Consts, DatabaseGrid.Glyphs;

const
  SSA_FALLBACK = $00000020;
  SSA_GLYPHS = $00000080;

{ Uniscribe, not declared by the RTL }
function ScriptStringAnalyse(ADC: HDC; AString: PChar; ALength, AGlyphCount, ACharset: Integer; AFlags: DWORD; AReqWidth: Integer;
  AControl, AState, ADx, ATabDef, AInClass: Pointer; out AAnalysis: Pointer): HRESULT; stdcall; external 'usp10.dll';
function ScriptStringCPtoX(AAnalysis: Pointer; ACharacter: Integer; ATrailing: BOOL; out AX: Integer): HRESULT; stdcall;
  external 'usp10.dll';
function ScriptStringFree(var AAnalysis: Pointer): HRESULT; stdcall; external 'usp10.dll';

constructor TDatabaseGridPainter.Create(const AColors: TDatabaseGridColors; const ADataLink: TDatabaseGridDataLink;
  const AGroups: TDatabaseGridGroups; const AIndicator: TDatabaseGridIndicator; const ALayout: TDatabaseGridLayout;
  const ASelectedRows: TDatabaseGridSelectedRows; const ASortMarkedColumns: TList<TDatabaseGridColumn>);
begin
  inherited Create;

  FColors := AColors;
  FDataLink := ADataLink;
  FGroups := AGroups;
  FIndicator := AIndicator;
  FLayout := ALayout;
  FSelectedRows := ASelectedRows;
  FSortMarkedColumns := ASortMarkedColumns;
  FBaseFont := TFont.Create;
  FCutCells := TList<TDatabaseGridCutCell>.Create;
end;

destructor TDatabaseGridPainter.Destroy;
begin
  FCutCells.Free;
  FBaseFont.Free;

  inherited Destroy;
end;

function TDatabaseGridPainter.TryGetCutCellText(const APoint: TPoint; out AText: string; out ARect: TRect): Boolean;
begin
  for var LCutCell in FCutCells do
  if LCutCell.Rect.Contains(APoint) then
  begin
    AText := LCutCell.Text;
    ARect := LCutCell.Rect;

    Exit(True);
  end;

  AText := '';
  ARect := TRect.Empty;
  Result := False;
end;

function TDatabaseGridPainter.FindSearchMatches(const AText: string; out AMatches: TArray<Boolean>): Boolean;
var
  LPosition: Integer;
  LText: string;
begin
  AMatches := nil;
  Result := False;

  LText := AnsiUpperCase(AText);

  if Length(LText) <> Length(AText) then
    Exit;

  for var LWord in FState.SearchWords do
  begin
    LPosition := Pos(LWord, LText);

    while LPosition > 0 do
    begin
      if not Result then
      begin
        SetLength(AMatches, Length(AText));

        Result := True;
      end;

      for var LIndex := LPosition - 1 to LPosition + Length(LWord) - 2 do
        AMatches[LIndex] := True;

      LPosition := Pos(LWord, LText, LPosition + 1);
    end;
  end;
end;

function TDatabaseGridPainter.GetCellText(const AColumn: TDatabaseGridColumn): string;
var
  LLineBreak: Integer;
begin
  if not Assigned(AColumn.Field) then
    Exit('');

  if not (AColumn.Field.DataType in [ftMemo, ftWideMemo, ftFmtMemo]) or (AColumn.GetEditorKind <> ekMemo) and not (dgoShowMemoText in FState.Options) then
    Exit(AColumn.Field.DisplayText);

  Result := AColumn.Field.AsString;
  LLineBreak := Result.IndexOfAny([TControlCharacters.CarriageReturn, TControlCharacters.LineFeed]);

  if LLineBreak >= 0 then
    Result := Result.Substring(0, LLineBreak) + ' '#$2026;
end;

function TDatabaseGridPainter.GetCellTextRects(const ARect: TRect; const ARightIndent, ALeftIndent: Integer; out AClipRect, ATextRect: TRect): Boolean;
begin
  ATextRect := Rect(ARect.Left + ALeftIndent, ARect.Top, ARect.Right - ARightIndent - 1, ARect.Bottom - 1);
  AClipRect := Rect(Max(ARect.Left, FLayout.DataLeft), ARect.Top, ATextRect.Right, ARect.Bottom - 1);

  Result := AClipRect.Right > AClipRect.Left;
end;

function TDatabaseGridPainter.GetLineColor(const ALine, ABackground: TColor): TColor;
begin
  Result := if ALine = TColors.SysNone then ABackground else ALine;
end;

function TDatabaseGridPainter.IsCheckBoxCell(const AIndex: Integer): Boolean;
begin
  Result := (FCells[AIndex].Column.GetEditorKind = ekCheckBox) and (FCells[AIndex].Column.Field is TBooleanField);
end;

function TDatabaseGridPainter.CanOverflowInto(const AIndex, ANextIndex: Integer): Boolean;
begin
  Result := IsEmptyCell(ANextIndex) and
    ((dcHighlighted in FCells[AIndex].State) = (dcHighlighted in FCells[ANextIndex].State));
end;

function TDatabaseGridPainter.IsEmptyCell(const AIndex: Integer): Boolean;
begin
  Result := (AIndex >= 0) and (AIndex <= High(FCells)) and FCells[AIndex].Prepared and FCells[AIndex].Params.DefaultDrawing and
    FCells[AIndex].Params.Text.IsEmpty;
end;

function TDatabaseGridPainter.IsRowInRange: Boolean;
var
  LBookmark: TBookmark;
  LDataSet: TDataSet;
begin
  if not Assigned(FState.RangeStart) then
    Exit(False);

  LDataSet := FDataLink.DataSet;
  LBookmark := LDataSet.Bookmark;

  Result := (LDataSet.CompareBookmarks(FState.RangeStart, LBookmark) <= 0) and
    (LDataSet.CompareBookmarks(LBookmark, FState.RangeEnd) <= 0);
end;

procedure TDatabaseGridPainter.CallDrawCell(const ACallback: TDatabaseGridDrawCellCallback; var ACell: TDatabaseGridPaintCell;
  const AState: TDatabaseGridDrawCellStates);
var
  LContentRect: TRect;
  LHasRegion: Boolean;
  LRegion: HRGN;
begin
  LContentRect := Rect(ACell.Rect.Left, ACell.Rect.Top, ACell.Rect.Right - 1, ACell.Rect.Bottom - 1);
  LRegion := CreateRectRgn(0, 0, 0, 0);
  try
    LHasRegion := GetClipRgn(FCanvas.Handle, LRegion) = 1;

    IntersectClipRect(FCanvas.Handle, Max(LContentRect.Left, FLayout.DataLeft), LContentRect.Top,
      Min(LContentRect.Right, FState.ClientRect.Right), LContentRect.Bottom);
    try
      ACallback(ACell.Column, FCanvas, LContentRect, AState, ACell.Params);
    finally
      if LHasRegion then
        SelectClipRgn(FCanvas.Handle, LRegion)
      else
        SelectClipRgn(FCanvas.Handle, 0);

      FCanvas.Font.Assign(FBaseFont);
    end;
  finally
    DeleteObject(LRegion);
  end;
end;

procedure TDatabaseGridPainter.CallDrawGroupRow(const ANode: TDatabaseGridGroupNode; const ARect: TRect;
  const AState: TDatabaseGridDrawCellStates; var AParams: TDatabaseGridDrawGroupRowParams);
var
  LHasRegion: Boolean;
  LRegion: HRGN;
begin
  LRegion := CreateRectRgn(0, 0, 0, 0);
  try
    LHasRegion := GetClipRgn(FCanvas.Handle, LRegion) = 1;

    IntersectClipRect(FCanvas.Handle, ARect.Left, ARect.Top, ARect.Right, ARect.Bottom);
    try
      FState.DrawGroupRow(ANode, FCanvas, ARect, AState, AParams);
    finally
      SelectClipRgn(FCanvas.Handle, if LHasRegion then LRegion else 0);

      FCanvas.Font.Assign(FBaseFont);
    end;
  finally
    DeleteObject(LRegion);
  end;
end;

procedure TDatabaseGridPainter.FillGradient(const ARect: TRect; const ATopColor, ABottomColor: TColor);
var
  LBottomColor, LTopColor: COLORREF;
  LGradientRect: TGradientRect;
  LVertices: array [0..1] of TTriVertex;
begin
  if (ARect.Right <= ARect.Left) or (ARect.Bottom <= ARect.Top) then
    Exit;

  LTopColor := ColorToRGB(ATopColor);
  LBottomColor := ColorToRGB(ABottomColor);

  LVertices[0].x := ARect.Left;
  LVertices[0].y := ARect.Top;
  LVertices[0].Red := GetRValue(LTopColor) shl 8;
  LVertices[0].Green := GetGValue(LTopColor) shl 8;
  LVertices[0].Blue := GetBValue(LTopColor) shl 8;
  LVertices[0].Alpha := 0;

  LVertices[1].x := ARect.Right;
  LVertices[1].y := ARect.Bottom;
  LVertices[1].Red := GetRValue(LBottomColor) shl 8;
  LVertices[1].Green := GetGValue(LBottomColor) shl 8;
  LVertices[1].Blue := GetBValue(LBottomColor) shl 8;
  LVertices[1].Alpha := 0;

  LGradientRect.UpperLeft := 0;
  LGradientRect.LowerRight := 1;

  GradientFill(FCanvas.Handle, @LVertices[0], Length(LVertices), @LGradientRect, 1, GRADIENT_FILL_RECT_V);
end;

procedure TDatabaseGridPainter.FillRectangle(const ARect: TRect; const AColor: TColor);
var
  LDC: HDC;
  LOldColor: COLORREF;
begin
  if (ARect.Right > ARect.Left) and (ARect.Bottom > ARect.Top) then
  begin
    LDC := FCanvas.Handle;
    LOldColor := SetBkColor(LDC, ColorToRGB(AColor));
    Winapi.Windows.ExtTextOut(LDC, 0, 0, ETO_OPAQUE, ARect, '', 0, nil);
    SetBkColor(LDC, LOldColor);
  end;
end;

procedure TDatabaseGridPainter.GetCharacterEdges(const AText: string; out ALefts, ARights: TArray<Integer>);
var
  LAnalysis: Pointer;
  LLeading, LTrailing: Integer;
  LSize: TSize;
begin
  SetLength(ALefts, Length(AText));
  SetLength(ARights, Length(AText));

  if AText.IsEmpty then
    Exit;

  if Succeeded(ScriptStringAnalyse(FCanvas.Handle, PChar(AText), Length(AText), Length(AText) * 3 div 2 + 16, -1, SSA_GLYPHS or SSA_FALLBACK,
    0, nil, nil, nil, nil, nil, LAnalysis)) then
  try
    for var LIndex := 0 to High(ALefts) do
    begin
      ScriptStringCPtoX(LAnalysis, LIndex, False, LLeading);
      ScriptStringCPtoX(LAnalysis, LIndex, True, LTrailing);

      ALefts[LIndex] := Min(LLeading, LTrailing);
      ARights[LIndex] := Max(LLeading, LTrailing);
    end;

    Exit;
  finally
    ScriptStringFree(LAnalysis);
  end;

  GetTextExtentExPoint(FCanvas.Handle, PChar(AText), Length(AText), 0, nil, @ARights[0], LSize);

  for var LIndex := 1 to High(ALefts) do
    ALefts[LIndex] := ARights[LIndex - 1];
end;

procedure TDatabaseGridPainter.Paint(const ACanvas: TCanvas; const AState: TDatabaseGridPaintState);
var
  LClipRect: TRect;
begin
  FCanvas := ACanvas;
  FState := AState;
  FBaseFont.Assign(FCanvas.Font);
  try
    LClipRect := FCanvas.ClipRect;

    for var LIndex := FCutCells.Count - 1 downto 0 do
    if FCutCells[LIndex].Rect.IntersectsWith(LClipRect) then
      FCutCells.Delete(LIndex);

    if LClipRect.Top < FLayout.DataTop then
    begin
      PaintSearchPanel;

      if FLayout.TitleHeight > 0 then
      begin
        PaintIndicatorTitle;
        PaintTitle;
      end;
    end;

    PaintRows(LClipRect);
    PaintDropLine;

    if FLayout.FooterVisible and (LClipRect.Bottom > FLayout.FooterTop) then
      PaintFooter;
  finally
    FCanvas := nil;
  end;
end;

procedure TDatabaseGridPainter.PaintArrow(const ACenter: TPoint; const ADirection: TDatabaseGridArrowDirection; const AColor: TColor);
var
  LHalfSize, LSize: Integer;
begin
  LSize := FLayout.ScaleMetric(TDatabaseGridSize.Arrow);
  LHalfSize := LSize div 2;

  FCanvas.Pen.Color := AColor;
  FCanvas.Brush.Color := AColor;

  case ADirection of
    adUp:
      FCanvas.Polygon([Point(ACenter.X - LSize, ACenter.Y + LHalfSize), Point(ACenter.X + LSize, ACenter.Y + LHalfSize),
        Point(ACenter.X, ACenter.Y - LHalfSize)]);
    adDown:
      FCanvas.Polygon([Point(ACenter.X - LSize, ACenter.Y - LHalfSize), Point(ACenter.X + LSize, ACenter.Y - LHalfSize),
        Point(ACenter.X, ACenter.Y + LHalfSize)]);
    adRight:
      FCanvas.Polygon([Point(ACenter.X - LHalfSize, ACenter.Y - LSize), Point(ACenter.X - LHalfSize, ACenter.Y + LSize),
        Point(ACenter.X + LHalfSize, ACenter.Y)]);
  end;
end;

procedure TDatabaseGridPainter.PaintCell(const ARect: TRect; const AText: string; const AAlignment: TAlignment; const ABackground,
  AForeground, AHorizontalLine, AVerticalLine: TColor; const ARightIndent: Integer = 0; const ALeftIndent: Integer = 0; const ALastColumn: Boolean = False);
var
  LClipRect, LTextRect: TRect;
  LLeft: Integer;
  LVerticalLine: TColor;
begin
  LLeft := Max(ARect.Left, FLayout.DataLeft);

  if ARect.Right <= LLeft then
    Exit;

  FillRectangle(Rect(LLeft, ARect.Bottom - 1, ARect.Right, ARect.Bottom), GetLineColor(AHorizontalLine, ABackground));

  LVerticalLine := AVerticalLine;

  if ALastColumn and (dgoAutoFitColumns in FState.Options) then
    LVerticalLine := ABackground;

  FillRectangle(Rect(ARect.Right - 1, ARect.Top, ARect.Right, ARect.Bottom - 1), GetLineColor(LVerticalLine, ABackground));

  GetCellTextRects(ARect, ARightIndent, ALeftIndent, LClipRect, LTextRect);

  if ARightIndent > 0 then
    FillRectangle(Rect(Max(LTextRect.Right, LLeft), ARect.Top, ARect.Right - 1, ARect.Bottom - 1), ABackground);

  PaintTextLine(LClipRect, LTextRect, AText, AAlignment, LTextRect.Top + (LTextRect.Height - FLayout.TextHeight) div 2, ABackground,
    AForeground);
end;

procedure TDatabaseGridPainter.PaintCellBackground(const ACell: TDatabaseGridPaintCell; const AHorizontalLine,
  AVerticalLine: TColor);
var
  LLeft: Integer;
begin
  LLeft := Max(ACell.Rect.Left, FLayout.DataLeft);

  if ACell.Rect.Right <= LLeft then
    Exit;

  FillRectangle(Rect(LLeft, ACell.Rect.Bottom - 1, ACell.Rect.Right, ACell.Rect.Bottom), GetLineColor(AHorizontalLine, ACell.Params.Background));
  FillRectangle(Rect(ACell.Rect.Right - 1, ACell.Rect.Top, ACell.Rect.Right, ACell.Rect.Bottom - 1), GetLineColor(AVerticalLine, ACell.Params.Background));

  if ACell.Params.DefaultDrawing then
    FillRectangle(Rect(LLeft, ACell.Rect.Top, ACell.Rect.Right - 1, ACell.Rect.Bottom - 1), ACell.Params.Background);
end;

procedure TDatabaseGridPainter.PaintCellCheckBox(const AIndex: Integer);
var
  LCell: TDatabaseGridPaintCell;
  LRect: TRect;
  LSize: Integer;
begin
  LCell := FCells[AIndex];
  LSize := Min(FLayout.ScaleMetric(TDatabaseGridSize.CheckBox), LCell.Rect.Height - 5);
  LRect := Bounds(LCell.Rect.Left + (LCell.Rect.Width - 1 - LSize) div 2, LCell.Rect.Top + (LCell.Rect.Height - 1 - LSize) div 2, LSize, LSize);

  if (LSize > 0) and (LRect.Left >= FLayout.DataLeft) then
    PaintCheckBox(LRect, not LCell.Column.Field.IsNull and LCell.Column.Field.AsBoolean);
end;

procedure TDatabaseGridPainter.PaintCellImage(const AIndex: Integer);
var
  LCell: TDatabaseGridPaintCell;
  LClipRect: TRect;
  LImages: TCustomImageList;
  LLeft, LPadding: Integer;
begin
  LCell := FCells[AIndex];
  LImages := LCell.Column.Images;
  LPadding := FLayout.ScaleMetric(TDatabaseGridSize.CellPadding);
  LClipRect := Rect(Max(LCell.Rect.Left, FLayout.DataLeft), LCell.Rect.Top, LCell.Rect.Right - 1, LCell.Rect.Bottom - 1);

  if LClipRect.Right <= LClipRect.Left then
    Exit;

  if not (coShowImageAndText in LCell.Column.Options) then
  begin
    PaintImage(LImages, LCell.Params.ImageIndex, LCell.Rect.Left + (LCell.Rect.Width - 1 - LImages.Width) div 2,
      LCell.Rect.Top + (LCell.Rect.Height - 1 - LImages.Height) div 2, LClipRect);

    Exit;
  end;

  LLeft := LCell.Rect.Left + LPadding;

  PaintImage(LImages, LCell.Params.ImageIndex, LLeft, LCell.Rect.Top + (LCell.Rect.Height - 1 - LImages.Height) div 2, LClipRect);

  FCanvas.Font.Color := LCell.Params.FontColor;
  FCanvas.Font.Style := LCell.Params.FontStyle;
  FCanvas.Brush.Style := bsClear;
  FCanvas.TextRect(LClipRect, LLeft + LImages.Width + FLayout.ScaleMetric(TDatabaseGridSize.ImageTextSpacing),
    LCell.Rect.Top + (LCell.Rect.Height - 1 - FLayout.TextHeight) div 2, LCell.Params.Text);
  FCanvas.Brush.Style := bsSolid;
end;

procedure TDatabaseGridPainter.PaintCells(const AHorizontalLine, AVerticalLine: TColor; const ADataRow: Boolean;
  const AHideLastVerticalLine: Boolean = False);
begin
  for var LIndex := 0 to High(FCells) do
  if FCells[LIndex].Prepared then
    PaintCellBackground(FCells[LIndex], AHorizontalLine,
      if AHideLastVerticalLine and (LIndex = High(FCells)) then TColors.SysNone else AVerticalLine);

  for var LIndex := 0 to High(FCells) do
  if FCells[LIndex].Prepared and FCells[LIndex].Params.DefaultDrawing then
  begin
    if ADataRow and (FCells[LIndex].Params.ImageIndex >= 0) and Assigned(FCells[LIndex].Column.Images) then
      PaintCellImage(LIndex)
    else
    if ADataRow and IsCheckBoxCell(LIndex) then
      PaintCellCheckBox(LIndex)
    else
    if not FCells[LIndex].Params.Text.IsEmpty then
      PaintCellText(LIndex, ADataRow);
  end;

  FCanvas.Font.Style := FBaseFont.Style;
end;

procedure TDatabaseGridPainter.PaintCellText(const AIndex: Integer; const ADataRow: Boolean);
var
  LCell: TDatabaseGridPaintCell;
  LClipLeft, LClipRight, LLeft, LNext, LPadding, LTextWidth, LTop: Integer;
  LClipRect, LShownRect: TRect;
  LCutCell: TDatabaseGridCutCell;
  LMatches: TArray<Boolean>;

  procedure HideLine(const AX: Integer; const AColor: TColor);
  begin
    if AX >= FLayout.DataLeft then
      FillRectangle(Rect(AX, LCell.Rect.Top, AX + 1, LCell.Rect.Bottom - 1), AColor);
  end;

begin
  LCell := FCells[AIndex];

  FCanvas.Font.Color := LCell.Params.FontColor;
  FCanvas.Font.Style := LCell.Params.FontStyle;

  LPadding := FLayout.ScaleMetric(TDatabaseGridSize.CellPadding);
  LTextWidth := FCanvas.TextWidth(LCell.Params.Text);
  LClipLeft := LCell.Rect.Left;
  LClipRight := LCell.Rect.Right - 1;

  case LCell.Params.Alignment of
    taRightJustify:
      LLeft := LClipRight - LPadding - LTextWidth;
    taCenter:
      LLeft := LClipLeft + (LClipRight - LClipLeft - LTextWidth) div 2;
  else
    LLeft := LClipLeft + LPadding;
  end;

  if dgoTextOverflow in FState.Options then
  begin
    LNext := AIndex + 1;

    while (LLeft + LTextWidth + LPadding > LClipRight) and CanOverflowInto(AIndex, LNext) do
    begin
      HideLine(LClipRight, FCells[LNext].Params.Background);

      LClipRight := FCells[LNext].Rect.Right - 1;
      Inc(LNext);
    end;

    LNext := AIndex - 1;

    while (LLeft - LPadding < LClipLeft) and CanOverflowInto(AIndex, LNext) do
    begin
      HideLine(FCells[LNext].Rect.Right - 1, FCells[LNext].Params.Background);

      LClipLeft := FCells[LNext].Rect.Left;
      Dec(LNext);
    end;
  end;

  LLeft := Max(LLeft, LClipLeft + LPadding);
  LTop := LCell.Rect.Top + (LCell.Rect.Height - 1 - FLayout.TextHeight) div 2;
  LClipRect := Rect(Max(LClipLeft, FLayout.DataLeft), LCell.Rect.Top, LClipRight, LCell.Rect.Bottom - 1);

  if ADataRow and (Length(FState.SearchWords) > 0) and FindSearchMatches(LCell.Params.Text, LMatches) then
    PaintHighlightedText(LClipRect, LLeft, LTop, LCell.Params.Text, LMatches, LCell.Params.FontColor)
  else
  begin
    FCanvas.Brush.Style := bsClear;
    FCanvas.TextRect(LClipRect, LLeft, LTop, LCell.Params.Text);
  end;

  FCanvas.Brush.Style := bsSolid;

  LShownRect := LClipRect;
  LShownRect.Right := Min(LShownRect.Right, FState.ClientRect.Right);

  if ADataRow and not LShownRect.IsEmpty and ((LLeft < LShownRect.Left) or (LLeft + LTextWidth > LShownRect.Right)) then
  begin
    LCutCell.Rect := LShownRect;
    LCutCell.Text := LCell.Params.Text;

    FCutCells.Add(LCutCell);
  end;
end;

procedure TDatabaseGridPainter.PaintCheckBox(const ARect: TRect; const AChecked: Boolean);
var
  LPoints: array [0..2] of TPoint;
  LSize: Integer;
begin
  FCanvas.Brush.Color := FColors.IndicatorCheckBoxBorder;
  FCanvas.FrameRect(ARect);

  FillRectangle(Rect(ARect.Left + 1, ARect.Top + 1, ARect.Right - 1, ARect.Bottom - 1), FColors.IndicatorCheckBoxBackground);

  if not AChecked then
    Exit;

  LSize := ARect.Width;
  LPoints[0] := Point(ARect.Left + MulDiv(LSize, 3, 13), ARect.Top + MulDiv(LSize, 6, 13));
  LPoints[1] := Point(ARect.Left + MulDiv(LSize, 5, 13), ARect.Top + MulDiv(LSize, 8, 13));
  LPoints[2] := Point(ARect.Left + MulDiv(LSize, 10, 13), ARect.Top + MulDiv(LSize, 3, 13));

  FCanvas.Pen.Color := FColors.IndicatorCheckBoxMark;

  for var LOffset := 0 to Max(FLayout.ScaleMetric(2), 2) - 1 do
  begin
    FCanvas.Polyline(LPoints);

    for var LIndex := Low(LPoints) to High(LPoints) do
      Inc(LPoints[LIndex].Y);
  end;
end;

procedure TDatabaseGridPainter.PaintDropLine;
var
  LTop: Integer;
begin
  if FState.DropRow < 0 then
    Exit;

  LTop := FLayout.DataTop + (FState.DropRow - FState.TopRow) * FLayout.RowHeight - 1;

  if (LTop < FLayout.DataTop - 1) or (LTop > FLayout.DataRect.Bottom) then
    Exit;

  FillRectangle(Rect(0, LTop - 1, Max(FLayout.ColumnsRight, FLayout.DataLeft), LTop + 1), FColors.ActiveRowBackground);
end;

procedure TDatabaseGridPainter.PaintEditButton(const AIndex: Integer);
var
  LGlyphRect, LRect: TRect;
  LPadding: Integer;
begin
  LRect := FCells[AIndex].Rect;
  LRect := Rect(LRect.Right - 1 - FLayout.GetEditButtonWidth, LRect.Top, LRect.Right - 1, LRect.Bottom - 1);

  if LRect.Left < FLayout.DataLeft then
    Exit;

  FillRectangle(LRect, FColors.EditButtonBackground);

  LPadding := FLayout.ScaleMetric(TDatabaseGridSize.FilterButtonPadding) + 1;
  LGlyphRect := LRect;
  LGlyphRect.Inflate(-LPadding, -LPadding);

  PaintDatabaseGridGlyph(FCanvas, LGlyphRect, FState.EditButtonGlyph, FColors.EditButtonGlyph);
end;

procedure TDatabaseGridPainter.PaintEmptyCell(const ALeft, ARight, ATop: Integer);
begin
  if (ARight > FLayout.DataLeft) and (ALeft < FState.ClientRect.Right) then
    PaintCell(Rect(ALeft, ATop, ARight, ATop + FLayout.RowHeight), '', taLeftJustify, FColors.DataBackground,
      FColors.DataForeground, FColors.HorizontalLine, FColors.VerticalLine);
end;

procedure TDatabaseGridPainter.PaintEmptyRow(const ATop: Integer);
var
  LRight: Integer;
begin
  for var LIndex := 0 to FLayout.VisibleColumnCount - 1 do
    PaintEmptyCell(FLayout.GetVisibleColumnLeft(LIndex), FLayout.GetVisibleColumnRight(LIndex), ATop);

  LRight := FLayout.ColumnsRight;

  if FLayout.VisibleColumnCount = 0 then
  begin
    PaintEmptyCell(LRight, LRight + FLayout.ScaleMetric(TDatabaseGridDefault.ColumnWidth), ATop);

    Inc(LRight, FLayout.ScaleMetric(TDatabaseGridDefault.ColumnWidth));
  end;

  FillRectangle(Rect(Max(LRight, FLayout.DataLeft), ATop, FState.ClientRect.Right, ATop + FLayout.RowHeight),
    FColors.GridBackground);

  PaintIndicatorBackground(Rect(0, ATop, FLayout.IndicatorWidth, ATop + FLayout.RowHeight), FColors.IndicatorBackground,
    FColors.IndicatorLine, FColors.IndicatorLine);
  PaintLeftLine(ATop, ATop + FLayout.RowHeight, FColors.VerticalLine, FColors.DataBackground);
end;

procedure TDatabaseGridPainter.PaintEmptyRows(const ATop: Integer);
var
  LBottom, LRight, LWidth: Integer;

  procedure PaintLine(const AX: Integer);
  begin
    if dgoFadeExtendedLines in FState.Options then
      FillGradient(Rect(AX, ATop, AX + 1, LBottom), FColors.VerticalLine, FColors.GridBackground)
    else
      FillRectangle(Rect(AX, ATop, AX + 1, LBottom), FColors.VerticalLine);
  end;

begin
  LBottom := if FLayout.FooterVisible then FLayout.FooterTop else FState.ClientRect.Bottom;
  LWidth := FState.ClientRect.Right;

  if ATop >= LBottom then
    Exit;

  if FLayout.IndicatorWidth > 0 then
  begin
    FillRectangle(Rect(0, ATop, FLayout.IndicatorWidth - 1, LBottom), FColors.IndicatorBackground);

    if dgoFadeExtendedLines in FState.Options then
      FillGradient(Rect(FLayout.IndicatorWidth - 1, ATop, FLayout.IndicatorWidth, LBottom), FColors.IndicatorLine,
        FColors.IndicatorBackground)
    else
      FillRectangle(Rect(FLayout.IndicatorWidth - 1, ATop, FLayout.IndicatorWidth, LBottom), FColors.IndicatorLine);
  end;

  FillRectangle(Rect(FLayout.IndicatorWidth, ATop, LWidth, LBottom), FColors.GridBackground);

  if not (dgoExtendVerticalLines in FState.Options) or (FColors.VerticalLine = TColors.SysNone) then
    Exit;

  if FLayout.LeftLineWidth > 0 then
    PaintLine(FLayout.IndicatorWidth);

  for var LIndex := 0 to FLayout.VisibleColumnCount - 1 do
  begin
    if (dgoAutoFitColumns in FState.Options) and (LIndex = FLayout.VisibleColumnCount - 1) then
      Break;

    LRight := FLayout.GetVisibleColumnRight(LIndex);

    if (LRight > FLayout.DataLeft) and (LRight <= LWidth) then
      PaintLine(LRight - 1);
  end;

  if FLayout.VisibleColumnCount = 0 then
    PaintLine(FLayout.ColumnsRight + FLayout.ScaleMetric(TDatabaseGridDefault.ColumnWidth) - 1);
end;

procedure TDatabaseGridPainter.PaintFooter;
var
  LBottom, LRight, LTop: Integer;
begin
  LTop := FLayout.FooterTop;
  LBottom := FState.ClientRect.Bottom;
  LRight := Max(FLayout.ColumnsRight, FLayout.DataLeft);

  if FLayout.IndicatorWidth > 0 then
  begin
    FillRectangle(Rect(0, LTop, FLayout.IndicatorWidth, LTop + 1), FColors.FooterLine);

    PaintIndicatorBackground(Rect(0, LTop + 1, FLayout.IndicatorWidth, LBottom + 1), FColors.FooterBackground, FColors.IndicatorLine,
      FColors.IndicatorLine);
  end;

  FillRectangle(Rect(FLayout.IndicatorWidth, LTop, LRight, LTop + 1), FColors.FooterLine);
  FillRectangle(Rect(FLayout.IndicatorWidth, LTop + 1, FLayout.DataLeft, LBottom), FColors.FooterBackground);
  PaintLeftLine(LTop + 1, LBottom, if FState.FooterVerticalLines then FColors.FooterLine else TColors.SysNone, FColors.FooterBackground);

  PrepareCellPlaces(LTop + 1, LBottom - LTop);
  PrepareFooterCells;
  PaintCells(FColors.FooterLine, if FState.FooterVerticalLines then FColors.FooterLine else TColors.SysNone, False, dgoAutoFitColumns in FState.Options);

  FillRectangle(Rect(LRight, LTop, FState.ClientRect.Right, LBottom), FColors.GridBackground);
end;

procedure TDatabaseGridPainter.PaintGroupedRow(const ARow, ATop: Integer; const AActive: Boolean);
var
  LGroupRow: TDatabaseGridGroupRow;
begin
  LGroupRow := FGroups.Rows[ARow];

  if LGroupRow.RecordIndex >= FDataLink.RecordCount then
  begin
    PaintEmptyRow(ATop);

    Exit;
  end;

  FDataLink.ActiveRecord := LGroupRow.RecordIndex;

  if Assigned(LGroupRow.Node) then
    PaintGroupRow(LGroupRow.Node, ATop, AActive)
  else
    PaintRow(ARow, ATop, AActive);
end;

procedure TDatabaseGridPainter.PaintGroupRow(const ANode: TDatabaseGridGroupNode; const ATop: Integer; const AActive: Boolean);
var
  LBottom, LExpanderLeft, LGlyphTop, LHeight, LLeft: Integer;
  LCellState: TDatabaseGridDrawCellStates;
  LExpanderColor: TColor;
  LParams: TDatabaseGridDrawGroupRowParams;
  LRect: TRect;
begin
  LHeight := FLayout.GroupRowHeight;
  LBottom := ATop + LHeight - 1;
  LExpanderLeft := FLayout.RowsLeft + ANode.Level * FLayout.GroupLevelWidth;
  LRect := Rect(LExpanderLeft, ATop, FState.ClientRect.Right, LBottom);

  LParams.Background := FColors.GroupRowBackground;
  LParams.DefaultDrawing := True;
  LParams.FontColor := FColors.GroupRowForeground;
  LParams.FontStyle := FBaseFont.Style + [TFontStyle.fsBold];
  LParams.ImageIndex := -1;
  LParams.Text := Format('%s (%d)', [ANode.Text, ANode.RecordCount]);
  LExpanderColor := FColors.GroupRowExpander;

  if AActive and (FState.Focused or (dgoAlwaysShowSelection in FState.Options)) then
  begin
    LParams.Background := if FState.Focused then FColors.ActiveRowBackground else FColors.ActiveRowBackgroundUnfocused;
    LParams.FontColor := if FState.Focused then FColors.ActiveRowForeground else FColors.ActiveRowForegroundUnfocused;
    LExpanderColor := LParams.FontColor;
  end;

  LCellState := [];

  if AActive then
    Include(LCellState, dcActiveRow);

  if FState.Focused then
    Include(LCellState, dcFocused);

  if Assigned(FState.DrawGroupRow) then
    CallDrawGroupRow(ANode, LRect, LCellState, LParams);

  FillRectangle(Rect(FLayout.IndicatorWidth, ATop, LExpanderLeft, ATop + LHeight), FColors.GroupRowBackground);
  PaintLeftLine(ATop, ATop + LHeight, FColors.VerticalLine, FColors.GroupRowBackground);
  FillRectangle(Rect(LExpanderLeft, LBottom, FState.ClientRect.Right, LBottom + 1),
    GetLineColor(FColors.GroupRowLine, FColors.GroupRowBackground));

  if LParams.DefaultDrawing then
  begin
    FillRectangle(LRect, LParams.Background);

    LGlyphTop := ATop + (LHeight - 1 - FLayout.GroupLevelWidth) div 2;

    PaintDatabaseGridGlyph(FCanvas, Rect(LExpanderLeft, LGlyphTop, LExpanderLeft + FLayout.GroupLevelWidth,
      LGlyphTop + FLayout.GroupLevelWidth), if ANode.Expanded then glGroupExpanded else glGroupCollapsed, LExpanderColor);

    LLeft := LExpanderLeft + FLayout.GroupLevelWidth + FLayout.ScaleMetric(TDatabaseGridSize.CellPadding);

    if Assigned(FState.GroupImages) and (LParams.ImageIndex >= 0) then
    begin
      FState.GroupImages.Draw(FCanvas, LLeft, ATop + (LHeight - 1 - FState.GroupImages.Height) div 2, LParams.ImageIndex,
        dsTransparent, itImage);

      Inc(LLeft, FState.GroupImages.Width + FLayout.ScaleMetric(TDatabaseGridSize.ImageTextSpacing));
    end;

    FCanvas.Font.Color := LParams.FontColor;
    FCanvas.Font.Style := LParams.FontStyle;
    FCanvas.Brush.Style := bsClear;
    FCanvas.TextRect(Rect(LLeft, ATop, LRect.Right, LBottom), LLeft, ATop + (LHeight - 1 - FLayout.TextHeight) div 2,
      LParams.Text);
    FCanvas.Brush.Style := bsSolid;
    FCanvas.Font.Style := FBaseFont.Style;
  end;

  PaintIndicatorCell(ATop, LHeight, AActive, False, False);
end;

procedure TDatabaseGridPainter.PaintHighlightedText(const AClipRect: TRect; const ALeft, ATop: Integer; const AText: string;
  const AMatches: TArray<Boolean>; const AForeground: TColor);
var
  LCount, LRunLeft: Integer;
  LLefts, LRights: TArray<Integer>;
  LMatchRects: TArray<TRect>;

  procedure PaintRun(const ARunLeft, ARunRight: Integer; const AColor: TColor);
  begin
    if Min(ARunRight, AClipRect.Right) <= Max(ARunLeft, AClipRect.Left) then
      Exit;

    FCanvas.Brush.Style := bsClear;
    FCanvas.Font.Color := AColor;
    FCanvas.TextRect(Rect(Max(ARunLeft, AClipRect.Left), AClipRect.Top, Min(ARunRight, AClipRect.Right), AClipRect.Bottom), ALeft,
      ATop, AText);
  end;

begin
  GetCharacterEdges(AText, LLefts, LRights);

  LMatchRects := nil;

  for var LIndex := 0 to High(AMatches) do
  if AMatches[LIndex] then
    LMatchRects := LMatchRects + [Rect(ALeft + LLefts[LIndex], ATop, ALeft + LRights[LIndex], ATop + FLayout.TextHeight)];

  TArray.Sort<TRect>(LMatchRects, TComparer<TRect>.Construct(
    function(const ALeftRect, ARightRect: TRect): Integer
    begin
      Result := ALeftRect.Left - ARightRect.Left;
    end));

  LCount := 0;

  for var LIndex := 0 to High(LMatchRects) do
  if (LCount > 0) and (LMatchRects[LIndex].Left <= LMatchRects[LCount - 1].Right) then
    LMatchRects[LCount - 1].Right := Max(LMatchRects[LCount - 1].Right, LMatchRects[LIndex].Right)
  else
  begin
    LMatchRects[LCount] := LMatchRects[LIndex];
    Inc(LCount);
  end;

  LRunLeft := AClipRect.Left;

  for var LIndex := 0 to LCount - 1 do
  begin
    PaintRun(LRunLeft, LMatchRects[LIndex].Left, AForeground);

    FillRectangle(Rect(Max(LMatchRects[LIndex].Left, AClipRect.Left), Max(ATop, AClipRect.Top),
      Min(LMatchRects[LIndex].Right, AClipRect.Right), Min(LMatchRects[LIndex].Bottom, AClipRect.Bottom)),
      FColors.SearchMatchBackground);

    PaintRun(LMatchRects[LIndex].Left, LMatchRects[LIndex].Right, FColors.SearchMatchForeground);

    LRunLeft := LMatchRects[LIndex].Right;
  end;

  PaintRun(LRunLeft, AClipRect.Right, AForeground);
end;

procedure TDatabaseGridPainter.PaintImage(const AImages: TCustomImageList; const AImageIndex, AX, AY: Integer; const AClipRect: TRect);
var
  LSavedDC: Integer;
begin
  if (AImageIndex < 0) or (AImageIndex >= AImages.Count) then
    Exit;

  LSavedDC := SaveDC(FCanvas.Handle);
  try
    IntersectClipRect(FCanvas.Handle, AClipRect.Left, AClipRect.Top, AClipRect.Right, AClipRect.Bottom);

    AImages.Draw(FCanvas, AX, AY, AImageIndex, dsTransparent, itImage);
  finally
    RestoreDC(FCanvas.Handle, LSavedDC);
  end;
end;

procedure TDatabaseGridPainter.PaintIndicatorBackground(const ARect: TRect; const ABackground, ABottomLine, ARightLine: TColor);
begin
  if ARect.IsEmpty then
    Exit;

  FillRectangle(Rect(ARect.Left, ARect.Top, ARect.Right, ARect.Bottom - 1), ABackground);
  FillRectangle(Rect(ARect.Left, ARect.Bottom - 1, ARect.Right, ARect.Bottom), GetLineColor(ABottomLine, ABackground));

  if ARightLine <> TColors.SysNone then
    FillRectangle(Rect(ARect.Right - 1, ARect.Top, ARect.Right, ARect.Bottom - 1), ARightLine);
end;

procedure TDatabaseGridPainter.PaintIndicatorCell(const ATop, AHeight: Integer; const AActive, ACheckBox, ASelected: Boolean);
var
  LGlyphRect: TRect;
  LRowIndicatorLeft, LRowIndicatorWidth: Integer;
begin
  if FLayout.IndicatorWidth = 0 then
    Exit;

  PaintIndicatorBackground(Rect(0, ATop, FLayout.IndicatorWidth, ATop + AHeight), FColors.IndicatorBackground,
    FColors.IndicatorLine, FColors.IndicatorLine);

  if AActive and (ioShowRowIndicator in FIndicator.Options) then
  begin
    LRowIndicatorWidth := FLayout.ScaleMetric(TDatabaseGridSize.RowIndicatorWidth);
    LRowIndicatorLeft := 0;

    if ioShowCheckBox in FIndicator.Options then
      LRowIndicatorLeft := FLayout.RowHeight;

    LGlyphRect := Bounds(LRowIndicatorLeft, ATop + (AHeight - LRowIndicatorWidth) div 2, LRowIndicatorWidth - 1,
      LRowIndicatorWidth - 1);

    case FDataLink.DataSet.State of
      dsEdit:
        PaintDatabaseGridGlyph(FCanvas, LGlyphRect, glEditRow, FColors.IndicatorArrow);
      dsInsert:
        PaintDatabaseGridGlyph(FCanvas, LGlyphRect, glInsertRow, FColors.IndicatorArrow);
    else
      PaintArrow(Point(LRowIndicatorLeft + LRowIndicatorWidth div 2, ATop + (AHeight - 1) div 2), adRight,
        FColors.IndicatorArrow);
    end;
  end;

  if ACheckBox and (ioShowCheckBox in FIndicator.Options) then
    PaintCheckBox(FLayout.GetCheckBoxRect(ATop), ASelected);
end;

procedure TDatabaseGridPainter.PaintIndicatorTitle;
var
  LRect: TRect;
begin
  if FLayout.IndicatorWidth = 0 then
    Exit;

  LRect := Rect(0, FLayout.TitleTop, FLayout.IndicatorWidth, FLayout.DataTop);

  PaintIndicatorBackground(LRect, FColors.TitleBackground, FColors.TitleBottomLine,
    if FState.TitleVerticalLines then FColors.TitleVerticalLine else TColors.SysNone);

  if tmoShowDropDownSign in FIndicator.TitleMenu.Options then
    PaintArrow(Point((LRect.Right - 1) div 2, (LRect.Top + LRect.Bottom - 1) div 2), adDown, FColors.IndicatorDropDownSign);
end;

procedure TDatabaseGridPainter.PaintLeftLine(const ATop, ABottom: Integer; const ALine, ABackground: TColor);
begin
  if FLayout.LeftLineWidth > 0 then
    FillRectangle(Rect(FLayout.IndicatorWidth, ATop, FLayout.RowsLeft, ABottom), GetLineColor(ALine, ABackground));
end;

procedure TDatabaseGridPainter.PaintRow(const ARowNumber, ATop: Integer; const AActive: Boolean);
var
  LBackground, LForeground, LPlainBackground: TColor;
  LCellMode, LPlainRow, LSelected, LShowSelection: Boolean;
  LCellState: TDatabaseGridDrawCellStates;
begin
  LCellMode := dgoEditing in FState.Options;
  LShowSelection := FState.Focused or (dgoAlwaysShowSelection in FState.Options);
  LSelected := (FSelectedRows.Count > 0) and FSelectedRows.IsSelected(FDataLink.DataSet.Bookmark);
  LPlainRow := False;
  LPlainBackground := if (FColors.DataBackgroundAlternate <> TColors.SysNone) and Odd(ARowNumber) then FColors.DataBackgroundAlternate
    else FColors.DataBackground;

  if AActive and LShowSelection and LCellMode then
  begin
    LBackground := FColors.CurrentRowBackground;
    LForeground := FColors.DataForeground;
  end
  else
  if AActive and LShowSelection then
  begin
    LBackground := if FState.Focused then FColors.ActiveRowBackground else FColors.ActiveRowBackgroundUnfocused;
    LForeground := if FState.Focused then FColors.ActiveRowForeground else FColors.ActiveRowForegroundUnfocused;
  end
  else
  if LSelected and LShowSelection then
  begin
    LBackground := if FState.Focused then FColors.SelectionBackground else FColors.SelectionBackgroundUnfocused;
    LForeground := if FState.Focused then FColors.SelectionForeground else FColors.SelectionForegroundUnfocused;
  end
  else
  begin
    LBackground := LPlainBackground;
    LForeground := FColors.DataForeground;
    LPlainRow := True;
  end;

  LCellState := [];

  if AActive then
    Include(LCellState, dcActiveRow);

  if FState.Focused then
    Include(LCellState, dcFocused);

  if LSelected then
    Include(LCellState, dcSelected);

  if not LPlainRow and not (AActive and LCellMode) then
    Include(LCellState, dcHighlighted);

  PrepareCellPlaces(ATop, FLayout.RowHeight);
  PrepareRowCells(LBackground, LForeground, LCellState, LPlainRow, LCellMode and AActive and LShowSelection, LCellMode and LShowSelection and IsRowInRange);
  PaintCells(FColors.HorizontalLine, FColors.VerticalLine, True);

  if AActive and FState.Focused and (dgoEditing in FState.Options) and (FColors.CurrentCellBorder <> TColors.SysNone) then
    for var LIndex := 0 to High(FCells) do
    if FCells[LIndex].Prepared and (FCells[LIndex].Column = FState.CurrentColumn) and
      (FCells[LIndex].Rect.Left >= FLayout.DataLeft) then
    begin
      FCanvas.Brush.Color := FColors.CurrentCellBorder;
      FCanvas.FrameRect(Rect(FCells[LIndex].Rect.Left, ATop, FCells[LIndex].Rect.Right - 1, ATop + FLayout.RowHeight - 1));
    end;

  if AActive and FState.ShowEditButton then
    for var LIndex := 0 to High(FCells) do
    if FCells[LIndex].Prepared and (FCells[LIndex].Column = FState.CurrentColumn) then
      PaintEditButton(LIndex);

  FillRectangle(Rect(Max(FLayout.ColumnsRight, FLayout.DataLeft), ATop, FState.ClientRect.Right, ATop + FLayout.RowHeight),
    FColors.GridBackground);

  FillRectangle(Rect(FLayout.IndicatorWidth, ATop, FLayout.DataLeft, ATop + FLayout.RowHeight), LPlainBackground);
  PaintLeftLine(ATop, ATop + FLayout.RowHeight, FColors.VerticalLine, LPlainBackground);

  PaintIndicatorCell(ATop, FLayout.RowHeight, AActive, True, LSelected);
end;

procedure TDatabaseGridPainter.PaintRows(const AClipRect: TRect);
var
  LActiveRecord, LActiveRow, LBottom, LHeight, LRow, LRowCount, LTop: Integer;
begin
  LBottom := if FLayout.FooterVisible then FLayout.FooterTop else FState.ClientRect.Bottom;
  LTop := FLayout.DataTop;

  if not FDataLink.Active then
  begin
    PaintEmptyRow(LTop);

    Inc(LTop, FLayout.RowHeight);
  end
  else
  begin
    LActiveRecord := FDataLink.ActiveRecord;
    try
      if FGroups.Active then
      begin
        LActiveRow := FGroups.FocusedRow;
        LRowCount := FGroups.RowCount;
      end
      else
      begin
        LActiveRow := LActiveRecord;
        LRowCount := FDataLink.RecordCount;
      end;

      LRow := FState.TopRow;

      while (LRow < LRowCount) and (LTop < LBottom) do
      begin
        LHeight := if FGroups.Active and Assigned(FGroups.Rows[LRow].Node) then FLayout.GroupRowHeight else FLayout.RowHeight;

        if (LTop < AClipRect.Bottom) and (LTop + LHeight > AClipRect.Top) then
        begin
          if FGroups.Active then
            PaintGroupedRow(LRow, LTop, LRow = LActiveRow)
          else
          begin
            FDataLink.ActiveRecord := LRow;

            PaintRow(FDataLink.FirstBufferedRow + LRow, LTop, LRow = LActiveRow);
          end;
        end;

        Inc(LRow);
        Inc(LTop, LHeight);
      end;
    finally
      FDataLink.ActiveRecord := LActiveRecord;
    end;
  end;

  PaintEmptyRows(LTop);
end;

procedure TDatabaseGridPainter.PaintSearchPanel;
var
  LRight: Integer;
begin
  if FLayout.TitleTop = 0 then
    Exit;

  FillRectangle(Rect(0, 0, FState.ClientRect.Right, FLayout.TitleTop - 1),
    if FState.SearchPanelHighlighted then FColors.SearchPanelBackgroundFocused else FColors.SearchPanelBackground);
  if FLayout.TitleHeight = 0 then
    FillRectangle(Rect(0, FLayout.TitleTop - 1, FState.ClientRect.Right, FLayout.TitleTop), FColors.TitleTopLine)
  else
  begin
    LRight := Max(FLayout.ColumnsRight, FLayout.DataLeft);

    FillRectangle(Rect(0, FLayout.TitleTop - 1, LRight, FLayout.TitleTop), FColors.TitleTopLine);
    FillRectangle(Rect(LRight, FLayout.TitleTop - 1, FState.ClientRect.Right, FLayout.TitleTop), FColors.GridBackground);
  end;
end;

procedure TDatabaseGridPainter.PaintTextLine(const AClipRect, ATextRect: TRect; const AText: string; const AAlignment: TAlignment;
  const ATop: Integer; const ABackground, AForeground: TColor);
var
  LLeft, LPadding: Integer;
begin
  if (AClipRect.Right <= AClipRect.Left) or (AClipRect.Bottom <= AClipRect.Top) then
    Exit;

  LPadding := FLayout.ScaleMetric(TDatabaseGridSize.CellPadding);
  LLeft := ATextRect.Left + LPadding;

  case AAlignment of
    taRightJustify:
      LLeft := Max(ATextRect.Right - LPadding - FCanvas.TextWidth(AText), LLeft);
    taCenter:
      LLeft := Max(ATextRect.Left + (ATextRect.Width - FCanvas.TextWidth(AText)) div 2, LLeft);
  end;

  FCanvas.Brush.Color := ABackground;
  FCanvas.Font.Color := AForeground;
  FCanvas.TextRect(AClipRect, LLeft, ATop, AText);
end;

procedure TDatabaseGridPainter.PaintTitle;
var
  LBackground, LVerticalLine: TColor;
  LRightIndent: Integer;
  LColumn: TDatabaseGridColumn;
  LRect: TRect;
  LLines: TArray<string>;

  procedure PaintTitleCell(const ALeftIndent: Integer; const ALastColumn: Boolean);
  var
    LLineClipRect, LTextClipRect, LTextRect: TRect;
    LTop: Integer;
  begin
    if FLayout.TitleLineCount = 1 then
    begin
      PaintCell(LRect, LLines[0], LColumn.Title.Alignment, LBackground, FColors.TitleForeground, FColors.TitleBottomLine, LVerticalLine, LRightIndent, ALeftIndent, ALastColumn);

      Exit;
    end;

    PaintCell(LRect, '', LColumn.Title.Alignment, LBackground, FColors.TitleForeground, FColors.TitleBottomLine, LVerticalLine, LRightIndent, ALeftIndent, ALastColumn);

    if not GetCellTextRects(LRect, LRightIndent, ALeftIndent, LTextClipRect, LTextRect) then
      Exit;

    if not LColumn.Title.SubCaption.IsEmpty then
      LLines := LLines + [LColumn.Title.SubCaption];

    LTop := LTextRect.Top + (LTextRect.Height - FLayout.TitleLineCount * FLayout.TextHeight) div 2;
    LLineClipRect := LTextClipRect;

    for var LLine := 0 to High(LLines) do
    begin
      if LLine > 0 then
        LLineClipRect.Top := LLineClipRect.Bottom;

      LLineClipRect.Bottom := if LLine = High(LLines) then LTextClipRect.Bottom else LTop + (LLine + 1) * FLayout.TextHeight;

      PaintTextLine(LLineClipRect, LTextRect, LLines[LLine], LColumn.Title.Alignment, LTop + LLine * FLayout.TextHeight, LBackground,
        if not LColumn.Title.SubCaption.IsEmpty and (LLine = High(LLines)) then FColors.TitleSubCaptionForeground
        else FColors.TitleForeground);
    end;
  end;

var
  LLastColumn: Boolean;
  LButtonPadding, LButtonWidth, LFontHeight, LIconPadding, LImageIndex, LImageTop, LRight, LSortMarkerWidth, LSortNumberWidth: Integer;
  LClipRect, LGlyphRect: TRect;
  LSortNumber: string;
begin
  LVerticalLine := if FState.TitleVerticalLines then FColors.TitleVerticalLine else TColors.SysNone;
  LFontHeight := FCanvas.Font.Height;
  LButtonPadding := FLayout.ScaleMetric(TDatabaseGridSize.FilterButtonPadding);
  LIconPadding := FLayout.ScaleMetric(TDatabaseGridSize.FilterIconPadding);

  PaintTitleGroups(LVerticalLine);

  for var LIndex := 0 to FLayout.VisibleColumnCount - 1 do
  begin
    LRect := Rect(FLayout.GetVisibleColumnLeft(LIndex), FLayout.GetTitleTop(LIndex), FLayout.GetVisibleColumnRight(LIndex), FLayout.DataTop);
    LLines := FLayout.GetTitleLines(LIndex);

    if (LRect.Right <= FLayout.DataLeft) or (LRect.Left >= FState.ClientRect.Right) then
      Continue;

    LColumn := FLayout.VisibleColumns[LIndex];
    LButtonWidth := FLayout.GetTitleButtonsWidth(LColumn);
    LSortMarkerWidth := if LColumn.Title.SortMarker = smNone then 0 else FLayout.ScaleMetric(TDatabaseGridSize.SortMarkerWidth);

    LSortNumber := '';
    LSortNumberWidth := 0;

    if (LSortMarkerWidth > 0) and (FSortMarkedColumns.Count > 1) then
    begin
      LSortNumber := IntToStr(FSortMarkedColumns.IndexOf(LColumn) + 1);

      FCanvas.Font.Height := FLayout.SortNumberFontHeight;
      LSortNumberWidth := FCanvas.TextWidth(LSortNumber) + FLayout.ScaleMetric(TDatabaseGridSize.CellPadding);
      FCanvas.Font.Height := LFontHeight;
    end;

    LRightIndent := LButtonWidth + LSortNumberWidth + LSortMarkerWidth;

    if LColumn = FState.PressedTitleColumn then
      LBackground := FColors.TitleBackgroundPressed
    else
    if LSortMarkerWidth > 0 then
      LBackground := FColors.TitleBackgroundSorted
    else
      LBackground := FColors.TitleBackground;

    LImageIndex := LColumn.Title.ImageIndex;
    LLastColumn := LIndex = FLayout.VisibleColumnCount - 1;

    if not Assigned(FState.TitleImages) or (LImageIndex < 0) or (LImageIndex >= FState.TitleImages.Count) then
      PaintTitleCell(0, LLastColumn)
    else
    begin
      LImageTop := LRect.Top + (LRect.Height - 1 - FState.TitleImages.Height) div 2;
      LClipRect := Rect(Max(LRect.Left, FLayout.DataLeft), LRect.Top, LRect.Right - 1 - LRightIndent, LRect.Bottom - 1);

      if toShowImageAndText in LColumn.Title.Options then
      begin
        PaintTitleCell(FState.TitleImages.Width + FLayout.ScaleMetric(TDatabaseGridSize.ImageTextSpacing), LLastColumn);
        PaintImage(FState.TitleImages, LImageIndex, LRect.Left + FLayout.ScaleMetric(TDatabaseGridSize.CellPadding), LImageTop, LClipRect);
      end
      else
      begin
        PaintCell(LRect, '', LColumn.Title.Alignment, LBackground, FColors.TitleForeground, FColors.TitleBottomLine, LVerticalLine, LRightIndent, 0, LLastColumn);
        PaintImage(FState.TitleImages, LImageIndex, LRect.Left + (LRect.Width - 1 - LRightIndent - FState.TitleImages.Width) div 2, LImageTop, LClipRect);
      end;
    end;

    if (LSortMarkerWidth > 0) and (LRect.Right - LRightIndent > FLayout.DataLeft) then
    begin
      PaintArrow(Point(LRect.Right - 1 - LButtonWidth - LSortNumberWidth - LSortMarkerWidth div 2, (LRect.Top + LRect.Bottom - 1) div 2),
        if LColumn.Title.SortMarker = smAscending then adUp else adDown, FColors.TitleSortMarker);

      if LSortNumberWidth > 0 then
      begin
        FCanvas.Font.Height := FLayout.SortNumberFontHeight;
        FCanvas.Font.Color := FColors.TitleForeground;
        FCanvas.Brush.Color := LBackground;
        FCanvas.TextOut(LRect.Right - 1 - LButtonWidth - LSortNumberWidth, LRect.Top + (LRect.Height - 1 - FCanvas.TextHeight(LSortNumber)) div 2, LSortNumber);
        FCanvas.Font.Height := LFontHeight;
      end;
    end;

    if (LButtonWidth > 0) and (LRect.Right - LButtonWidth > FLayout.DataLeft) then
    begin
      LGlyphRect := FLayout.GetTitleButtonsRect(LColumn, LRect);
      LGlyphRect.Left := LGlyphRect.Right - FLayout.ScaleMetric(TDatabaseGridSize.FilterButtonWidth);

      if FLayout.ShowsFilterDropDown(LColumn) then
      begin
        LGlyphRect.Inflate(-LButtonPadding, -LButtonPadding);

        PaintDatabaseGridGlyph(FCanvas, LGlyphRect, glDropDown, FColors.TitleForeground);

        LGlyphRect.Inflate(LButtonPadding, LButtonPadding);
        LGlyphRect.Offset(-FLayout.ScaleMetric(TDatabaseGridSize.FilterButtonWidth), 0);
      end;

      if FLayout.ShowsFilterIcon(LColumn) then
      begin
        LGlyphRect.Inflate(-LIconPadding, -LIconPadding);

        PaintDatabaseGridGlyph(FCanvas, LGlyphRect, glFilter, FColors.SearchPanelClearGlyph);
      end;
    end;
  end;

  LRight := FLayout.ColumnsRight;

  if FLayout.VisibleColumnCount = 0 then
  begin
    PaintCell(Rect(LRight, FLayout.TitleTop, LRight + FLayout.ScaleMetric(TDatabaseGridDefault.ColumnWidth), FLayout.DataTop), '',
      taLeftJustify, FColors.TitleBackground, FColors.TitleForeground, FColors.TitleBottomLine, LVerticalLine);

    Inc(LRight, FLayout.ScaleMetric(TDatabaseGridDefault.ColumnWidth));
  end;

  FillRectangle(Rect(Max(LRight, FLayout.DataLeft), FLayout.TitleTop, FState.ClientRect.Right, FLayout.DataTop),
    FColors.GridBackground);

  FillRectangle(Rect(FLayout.IndicatorWidth, FLayout.TitleTop, FLayout.DataLeft, FLayout.DataTop - 1), FColors.TitleBackground);
  FillRectangle(Rect(FLayout.IndicatorWidth, FLayout.DataTop - 1, FLayout.DataLeft, FLayout.DataTop), FColors.TitleBottomLine);
  PaintLeftLine(FLayout.TitleTop, FLayout.DataTop - 1, LVerticalLine, FColors.TitleBackground);
end;

procedure TDatabaseGridPainter.PaintTitleGroups(const AVerticalLine: TColor);
var
  LIndex, LLastIndex, LTop: Integer;
  LParts: TArray<string>;
  LRect: TRect;

  function IsInGroup(const AColumnIndex, ALevel: Integer): Boolean;
  var
    LColumnParts: TArray<string>;
  begin
    LColumnParts := FLayout.GetTitleParts(AColumnIndex);

    if High(LColumnParts) <= ALevel then
      Exit(False);

    for var LPart := 0 to ALevel do
    if LColumnParts[LPart] <> LParts[LPart] then
      Exit(False);

    Result := True;
  end;

begin
  for var LLevel := 0 to FLayout.TitleLevelCount - 2 do
  begin
    LTop := FLayout.TitleTop + LLevel * FLayout.TitleLevelHeight;
    LIndex := 0;

    while LIndex < FLayout.VisibleColumnCount do
    begin
      LParts := FLayout.GetTitleParts(LIndex);
      LLastIndex := LIndex;

      if High(LParts) > LLevel then
      begin
        while (LLastIndex < FLayout.VisibleColumnCount - 1) and IsInGroup(LLastIndex + 1, LLevel) do
          Inc(LLastIndex);

        LRect := Rect(FLayout.GetVisibleColumnLeft(LIndex), LTop, FLayout.GetVisibleColumnRight(LLastIndex),
          LTop + FLayout.TitleLevelHeight);

        if (LRect.Right > FLayout.DataLeft) and (LRect.Left < FState.ClientRect.Right) then
          PaintCell(LRect, LParts[LLevel], taCenter, FColors.TitleBackground, FColors.TitleForeground, FColors.TitleBottomLine, AVerticalLine);
      end;

      LIndex := LLastIndex + 1;
    end;
  end;
end;

procedure TDatabaseGridPainter.PrepareCellPlaces(const ATop, AHeight: Integer);
var
  LOverflow: Boolean;
begin
  LOverflow := dgoTextOverflow in FState.Options;

  SetLength(FCells, FLayout.VisibleColumnCount);

  for var LIndex := 0 to High(FCells) do
  begin
    FCells[LIndex].Column := FLayout.VisibleColumns[LIndex];
    FCells[LIndex].Rect := Rect(FLayout.GetVisibleColumnLeft(LIndex), ATop, FLayout.GetVisibleColumnRight(LIndex), ATop + AHeight);
    FCells[LIndex].Prepared := LOverflow or (FCells[LIndex].Rect.Right > FLayout.DataLeft) and
      (FCells[LIndex].Rect.Left < FState.ClientRect.Right);
  end;
end;

procedure TDatabaseGridPainter.PrepareFooterCells;
var
  LColumn: TDatabaseGridColumn;
begin
  for var LIndex := 0 to High(FCells) do
  if FCells[LIndex].Prepared then
  begin
    LColumn := FCells[LIndex].Column;

    FCells[LIndex].Params.Alignment := LColumn.Footer.Alignment;
    FCells[LIndex].Params.Background := FColors.FooterBackground;
    FCells[LIndex].Params.DefaultDrawing := True;
    FCells[LIndex].Params.FontColor := FColors.FooterForeground;
    FCells[LIndex].Params.FontStyle := FBaseFont.Style;
    FCells[LIndex].Params.ImageIndex := -1;
    FCells[LIndex].Params.Text := LColumn.Footer.GetDisplayText;
    FCells[LIndex].State := [];

    if Assigned(FState.DrawFooterCell) then
      CallDrawCell(FState.DrawFooterCell, FCells[LIndex], []);
  end;
end;

procedure TDatabaseGridPainter.PrepareRowCells(const ABackground, AForeground: TColor; const AState: TDatabaseGridDrawCellStates;
  const APlainRow, AShowCurrentCell, AInRange: Boolean);
var
  LCellState: TDatabaseGridDrawCellStates;
  LColumn: TDatabaseGridColumn;
  LCurrentCell: Boolean;
begin
  for var LIndex := 0 to High(FCells) do
  begin
    if not FCells[LIndex].Prepared then
      Continue;

    LColumn := FCells[LIndex].Column;
    LCurrentCell := (dcActiveRow in AState) and (LColumn = FState.CurrentColumn);
    LCellState := AState;

    FCells[LIndex].Params.Alignment := LColumn.Alignment;
    FCells[LIndex].Params.Background := ABackground;
    FCells[LIndex].Params.DefaultDrawing := True;
    FCells[LIndex].Params.FontColor := AForeground;
    FCells[LIndex].Params.FontStyle := FBaseFont.Style;
    FCells[LIndex].Params.ImageIndex := LColumn.GetImageIndex;
    FCells[LIndex].Params.Text := GetCellText(LColumn);

    if LCurrentCell then
      Include(LCellState, dcCurrentCell);

    if LCurrentCell and AShowCurrentCell then
    begin
      FCells[LIndex].Params.Background := if FState.Focused then FColors.ActiveRowBackground else FColors.SelectionBackground;
      FCells[LIndex].Params.FontColor := if FState.Focused then FColors.ActiveRowForeground else FColors.SelectionForeground;

      Include(LCellState, dcHighlighted);
    end
    else
    if AInRange and (LIndex >= FState.RangeFirstColumn) and (LIndex <= FState.RangeLastColumn) then
    begin
      FCells[LIndex].Params.Background := if FState.Focused then FColors.SelectionBackground else FColors.SelectionBackgroundUnfocused;
      FCells[LIndex].Params.FontColor := if FState.Focused then FColors.SelectionForeground else FColors.SelectionForegroundUnfocused;

      Include(LCellState, dcHighlighted);
      Include(LCellState, dcSelected);
    end
    else
    if (APlainRow or AShowCurrentCell) and Assigned(FState.IsReadOnlyColumn) and FState.IsReadOnlyColumn(LColumn) then
    begin
      if APlainRow then
        FCells[LIndex].Params.Background := FColors.ReadOnlyBackground;

      FCells[LIndex].Params.FontColor := FColors.ReadOnlyForeground;
    end;

    FCells[LIndex].State := LCellState;

    if LCurrentCell and (LColumn = FState.EditingColumn) then
    begin
      FCells[LIndex].Params.Background := FColors.DataBackground;
      FCells[LIndex].Params.ImageIndex := -1;
      FCells[LIndex].Params.Text := '';

      Continue;
    end;

    if Assigned(FState.DrawColumnCell) then
      CallDrawCell(FState.DrawColumnCell, FCells[LIndex], LCellState);
  end;
end;

end.
