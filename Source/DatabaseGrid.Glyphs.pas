unit DatabaseGrid.Glyphs;

interface

uses
  System.Types, System.UITypes, Vcl.Graphics, DatabaseGrid.Types;

procedure PaintDatabaseGridGlyph(const ACanvas: TCanvas; const ARect: TRect; const AGlyph: TDatabaseGridGlyph; const AColor: TColor);

implementation

uses
  Winapi.GDIPAPI, Winapi.GDIPOBJ, Winapi.Windows, System.Math;

procedure PaintDatabaseGridGlyph(const ACanvas: TCanvas; const ARect: TRect; const AGlyph: TDatabaseGridGlyph; const AColor: TColor);
var
  LBrush: TGPSolidBrush;
  LColor: Cardinal;
  LGraphics: TGPGraphics;
  LLeft, LSize, LTop: Integer;
  LPen: TGPPen;
  LRGBColor: COLORREF;
  LScale: Single;

  function PointF(const AX, AY: Single): TGPPointF;
  begin
    Result := MakePoint(LLeft + AX * LScale, LTop + AY * LScale);
  end;

  procedure PaintClear;
  begin
    LGraphics.DrawLine(LPen, PointF(3.5, 3.5), PointF(12.5, 12.5));
    LGraphics.DrawLine(LPen, PointF(12.5, 3.5), PointF(3.5, 12.5));
  end;

  procedure PaintChevron(const AX1, AY1, AX2, AY2, AX3, AY3: Single);
  var
    LPoints: array [0..2] of TGPPointF;
  begin
    LPoints[0] := PointF(AX1, AY1);
    LPoints[1] := PointF(AX2, AY2);
    LPoints[2] := PointF(AX3, AY3);

    LPen.SetWidth(1.8 * LScale);

    LGraphics.DrawLines(LPen, PGPPointF(@LPoints[0]), Length(LPoints));
  end;

  procedure PaintDropDown;
  begin
    PaintChevron(3, 5.5, 8, 10.5, 13, 5.5);
  end;

  procedure PaintGroupCollapsed;
  begin
    PaintChevron(5.5, 3, 10.5, 8, 5.5, 13);
  end;

  procedure PaintEditRow;
  var
    LBody, LEnd: array [0..3] of TGPPointF;
    LTip: array [0..2] of TGPPointF;
  begin
    LTip[0] := PointF(1, 15);
    LTip[1] := PointF(2, 10.6);
    LTip[2] := PointF(5.4, 14);

    LBody[0] := PointF(3, 9.6);
    LBody[1] := PointF(10.6, 2);
    LBody[2] := PointF(14, 5.4);
    LBody[3] := PointF(6.4, 13);

    LEnd[0] := PointF(11.6, 1);
    LEnd[1] := PointF(12.6, 0);
    LEnd[2] := PointF(16, 3.4);
    LEnd[3] := PointF(15, 4.4);

    LGraphics.FillPolygon(LBrush, PGPPointF(@LTip[0]), Length(LTip));
    LGraphics.FillPolygon(LBrush, PGPPointF(@LBody[0]), Length(LBody));
    LGraphics.FillPolygon(LBrush, PGPPointF(@LEnd[0]), Length(LEnd));
  end;

  procedure PaintEllipsis;
  begin
    for var LDot := 0 to 2 do
      LGraphics.FillEllipse(LBrush, PointF(2 + 5 * LDot, 0).X, PointF(0, 6.8).Y, 2.4 * LScale, 2.4 * LScale);
  end;

  procedure PaintFilter;
  var
    LPoints: array [0..5] of TGPPointF;
  begin
    LPoints[0] := PointF(1, 2);
    LPoints[1] := PointF(15, 2);
    LPoints[2] := PointF(10, 8.5);
    LPoints[3] := PointF(10, 14);
    LPoints[4] := PointF(6, 12);
    LPoints[5] := PointF(6, 8.5);

    LGraphics.FillPolygon(LBrush, PGPPointF(@LPoints[0]), Length(LPoints));
  end;

  procedure PaintInsertRow;
  begin
    LGraphics.DrawLine(LPen, PointF(8, 2.5), PointF(8, 13.5));
    LGraphics.DrawLine(LPen, PointF(3.2, 5.2), PointF(12.8, 10.8));
    LGraphics.DrawLine(LPen, PointF(12.8, 5.2), PointF(3.2, 10.8));
  end;

  procedure PaintMouseScroll;
  var
    LArrow: array [0..2] of TGPPointF;

    procedure PaintArrow(const ATipX, ATipY, ABaseX, ABaseY: Single);
    begin
      LArrow[0] := PointF(ATipX, ATipY);
      LArrow[1] := PointF(ABaseX + (ATipY - ABaseY), ABaseY + (ABaseX - ATipX));
      LArrow[2] := PointF(ABaseX - (ATipY - ABaseY), ABaseY - (ABaseX - ATipX));

      LGraphics.FillPolygon(LBrush, PGPPointF(@LArrow[0]), Length(LArrow));
    end;

  begin
    LPen.SetWidth(LScale);

    LGraphics.DrawEllipse(LPen, PointF(0.5, 0.5).X, PointF(0.5, 0.5).Y, 15 * LScale, 15 * LScale);
    LGraphics.FillEllipse(LBrush, PointF(6.75, 6.75).X, PointF(6.75, 6.75).Y, 2.5 * LScale, 2.5 * LScale);

    PaintArrow(8, 2.5, 8, 5);
    PaintArrow(8, 13.5, 8, 11);
    PaintArrow(2.5, 8, 5, 8);
    PaintArrow(13.5, 8, 11, 8);
  end;

  procedure PaintSort(const AAscending: Boolean);
  var
    LArrow: array [0..2] of TGPPointF;
    LBarGap, LBarLength, LBarStep, LBarThickness, LBlockHeight, LBlockTop, LHeadHeight, LHeadLeft, LHeadWing, LMaxBarLength,
      LStemLeft: Integer;
  begin
    LBarThickness := Max(1, Round(LSize / 8));
    LBarGap := Max(1, LSize div 4 - LBarThickness);
    LBlockHeight := 4 * LBarThickness + 3 * LBarGap;
    LBlockTop := LTop + (LSize - LBlockHeight) div 2;
    LHeadWing := Max(1, Round(LSize / 8));
    LHeadLeft := LLeft + LSize - 2 * LHeadWing - LBarThickness;
    LHeadHeight := Round(0.75 * (2 * LHeadWing + LBarThickness));
    LStemLeft := LHeadLeft + LHeadWing;
    LMaxBarLength := LHeadLeft - LLeft - Max(1, LSize div 16);
    LBarStep := Max(1, LMaxBarLength div 4);

    for var LBar := 0 to 3 do
    begin
      LBarLength := LMaxBarLength - LBarStep * (if AAscending then 3 - LBar else LBar);

      LGraphics.FillRectangle(LBrush, LLeft, LBlockTop + LBar * (LBarThickness + LBarGap), LBarLength, LBarThickness);
    end;

    LGraphics.FillRectangle(LBrush, LStemLeft, LBlockTop, LBarThickness, LBlockHeight - LHeadHeight);

    LArrow[0] := MakePoint(Single(LHeadLeft), LBlockTop + LBlockHeight - LHeadHeight);
    LArrow[1] := MakePoint(Single(LLeft + LSize), LBlockTop + LBlockHeight - LHeadHeight);
    LArrow[2] := MakePoint(LStemLeft + LBarThickness / 2, LBlockTop + LBlockHeight);

    LGraphics.FillPolygon(LBrush, PGPPointF(@LArrow[0]), Length(LArrow));
  end;

  procedure PaintRefresh;
  const
    ARC_START_ANGLE = 40;
    ARROW_ANGLE = -42;
    CENTER_X = 7.75;
    CENTER_Y = 8;
    HEAD_HALF_WIDTH = 4;
    HEAD_LENGTH = 4;
    RADIUS = 5.75;
  var
    LArrow: array [0..2] of TGPPointF;
    LBaseX, LBaseY, LDirectionX, LDirectionY: Single;
    LPath: TGPGraphicsPath;
  begin
    LPen.SetLineCap(LineCapFlat, LineCapFlat, DashCapFlat);

    LPath := TGPGraphicsPath.Create;
    try
      LPath.AddArc(PointF(CENTER_X - RADIUS, CENTER_Y - RADIUS).X, PointF(CENTER_X - RADIUS, CENTER_Y - RADIUS).Y, 2 * RADIUS * LScale,
        2 * RADIUS * LScale, ARC_START_ANGLE, 360 + ARROW_ANGLE + 2 - ARC_START_ANGLE);

      LGraphics.DrawPath(LPen, LPath);
    finally
      LPath.Free;
    end;

    LDirectionX := -Sin(DegToRad(ARROW_ANGLE));
    LDirectionY := Cos(DegToRad(ARROW_ANGLE));
    LBaseX := CENTER_X + RADIUS * LDirectionY;
    LBaseY := CENTER_Y - RADIUS * LDirectionX;

    LArrow[0] := PointF(LBaseX + HEAD_HALF_WIDTH * LDirectionY, LBaseY - HEAD_HALF_WIDTH * LDirectionX);
    LArrow[1] := PointF(LBaseX - HEAD_HALF_WIDTH * LDirectionY, LBaseY + HEAD_HALF_WIDTH * LDirectionX);
    LArrow[2] := PointF(LBaseX + HEAD_LENGTH * LDirectionX, LBaseY + HEAD_LENGTH * LDirectionY);

    LGraphics.FillPolygon(LBrush, PGPPointF(@LArrow[0]), Length(LArrow));
  end;

begin
  LSize := Min(ARect.Width, ARect.Height);

  if LSize <= 0 then
    Exit;

  LLeft := ARect.Left + (ARect.Width - LSize) div 2;
  LTop := ARect.Top + (ARect.Height - LSize) div 2;
  LScale := LSize / 16;

  LRGBColor := ColorToRGB(AColor);
  LColor := MakeColor(255, GetRValue(LRGBColor), GetGValue(LRGBColor), GetBValue(LRGBColor));

  LGraphics := TGPGraphics.Create(ACanvas.Handle);
  LBrush := TGPSolidBrush.Create(LColor);
  LPen := TGPPen.Create(LColor, 2.2 * LScale);
  try
    LGraphics.SetSmoothingMode(SmoothingModeAntiAlias);
    LGraphics.SetPixelOffsetMode(PixelOffsetModeHalf);

    LPen.SetLineCap(LineCapRound, LineCapRound, DashCapRound);
    LPen.SetLineJoin(LineJoinRound);

    case AGlyph of
      glClear:
        PaintClear;
      glDropDown, glGroupExpanded:
        PaintDropDown;
      glEditRow:
        PaintEditRow;
      glEllipsis:
        PaintEllipsis;
      glFilter:
        PaintFilter;
      glGroupCollapsed:
        PaintGroupCollapsed;
      glInsertRow:
        PaintInsertRow;
      glMouseScroll:
        PaintMouseScroll;
      glRefresh:
        PaintRefresh;
      glSortAscending:
        PaintSort(True);
      glSortDescending:
        PaintSort(False);
    end;
  finally
    LPen.Free;
    LBrush.Free;
    LGraphics.Free;
  end;
end;

end.
