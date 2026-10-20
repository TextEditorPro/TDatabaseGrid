unit DatabaseGrid.Border;

interface

uses
  System.Classes, System.UITypes, Vcl.Forms, Vcl.ToolWin;

const
  COLORED_EDGES_DEFAULT = [ebLeft, ebTop, ebRight, ebBottom];

type
  TDatabaseGridBorder = class(TPersistent)
  strict private
    FColor: TColor;
    FColoredEdges: TEdgeBorders;
    FOnChange: TNotifyEvent;
    FOnStyleChange: TNotifyEvent;
    FStyle: TBorderStyle;
    FWidth: Integer;
    procedure DoChange;
    procedure DoStyleChange;
    procedure SetColor(const AValue: TColor);
    procedure SetColoredEdges(const AValue: TEdgeBorders);
    procedure SetStyle(const AValue: TBorderStyle);
    procedure SetWidth(const AValue: Integer);
  public
    constructor Create;
    procedure Assign(ASource: TPersistent); override;
    property OnChange: TNotifyEvent read FOnChange write FOnChange;
    property OnStyleChange: TNotifyEvent read FOnStyleChange write FOnStyleChange;
  published
    property Color: TColor read FColor write SetColor default TColors.SysActiveBorder;
    property ColoredEdges: TEdgeBorders read FColoredEdges write SetColoredEdges default COLORED_EDGES_DEFAULT;
    property Style: TBorderStyle read FStyle write SetStyle default bsSingle;
    property Width: Integer read FWidth write SetWidth default 0;
  end;

implementation

uses
  System.Math;

constructor TDatabaseGridBorder.Create;
begin
  inherited Create;

  FColor := TColors.SysActiveBorder;
  FColoredEdges := COLORED_EDGES_DEFAULT;
  FStyle := bsSingle;
  FWidth := 0;
end;

procedure TDatabaseGridBorder.Assign(ASource: TPersistent);
begin
  if Assigned(ASource) and (ASource is TDatabaseGridBorder) then
  with ASource as TDatabaseGridBorder do
  begin
    Self.FColor := FColor;
    Self.FColoredEdges := FColoredEdges;
    Self.FStyle := FStyle;
    Self.FWidth := FWidth;

    Self.DoStyleChange;
    Self.DoChange;
  end
  else
    inherited Assign(ASource);
end;

procedure TDatabaseGridBorder.DoChange;
begin
  if Assigned(FOnChange) then
    FOnChange(Self);
end;

procedure TDatabaseGridBorder.DoStyleChange;
begin
  if Assigned(FOnStyleChange) then
    FOnStyleChange(Self);
end;

procedure TDatabaseGridBorder.SetColor(const AValue: TColor);
begin
  if FColor <> AValue then
  begin
    FColor := AValue;

    DoChange;
  end;
end;

procedure TDatabaseGridBorder.SetColoredEdges(const AValue: TEdgeBorders);
begin
  if FColoredEdges <> AValue then
  begin
    FColoredEdges := AValue;

    DoStyleChange;
  end;
end;

procedure TDatabaseGridBorder.SetStyle(const AValue: TBorderStyle);
begin
  if FStyle <> AValue then
  begin
    FStyle := AValue;

    DoStyleChange;
  end;
end;

procedure TDatabaseGridBorder.SetWidth(const AValue: Integer);
var
  LWidth: Integer;
begin
  LWidth := Max(AValue, 0);

  if FWidth <> LWidth then
  begin
    FWidth := LWidth;

    DoChange;
  end;
end;

end.
