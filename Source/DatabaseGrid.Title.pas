unit DatabaseGrid.Title;

interface

uses
  System.Classes, Vcl.ImgList, DatabaseGrid.Consts;

type
  TDatabaseGridTitle = class(TPersistent)
  strict private
    FImages: TCustomImageList;
    FMaxLineCount: Integer;
    FOnChange: TNotifyEvent;
    FVerticalLines: Boolean;
    FVisible: Boolean;
    procedure DoChange;
    procedure SetImages(const AValue: TCustomImageList);
    procedure SetMaxLineCount(const AValue: Integer);
    procedure SetVerticalLines(const AValue: Boolean);
    procedure SetVisible(const AValue: Boolean);
  public
    constructor Create;
    procedure Assign(ASource: TPersistent); override;
    property OnChange: TNotifyEvent read FOnChange write FOnChange;
  published
    property Images: TCustomImageList read FImages write SetImages;
    property MaxLineCount: Integer read FMaxLineCount write SetMaxLineCount default TDatabaseGridDefault.TitleMaxLineCount;
    property VerticalLines: Boolean read FVerticalLines write SetVerticalLines default True;
    property Visible: Boolean read FVisible write SetVisible default True;
  end;

implementation

uses
  System.Math;

constructor TDatabaseGridTitle.Create;
begin
  inherited Create;

  FMaxLineCount := TDatabaseGridDefault.TitleMaxLineCount;
  FVerticalLines := True;
  FVisible := True;
end;

procedure TDatabaseGridTitle.Assign(ASource: TPersistent);
begin
  if Assigned(ASource) and (ASource is TDatabaseGridTitle) then
  with ASource as TDatabaseGridTitle do
  begin
    Self.FImages := FImages;
    Self.FMaxLineCount := FMaxLineCount;
    Self.FVerticalLines := FVerticalLines;
    Self.FVisible := FVisible;

    Self.DoChange;
  end
  else
    inherited Assign(ASource);
end;

procedure TDatabaseGridTitle.DoChange;
begin
  if Assigned(FOnChange) then
    FOnChange(Self);
end;

procedure TDatabaseGridTitle.SetImages(const AValue: TCustomImageList);
begin
  if FImages <> AValue then
  begin
    FImages := AValue;

    DoChange;
  end;
end;

procedure TDatabaseGridTitle.SetMaxLineCount(const AValue: Integer);
var
  LMaxLineCount: Integer;
begin
  LMaxLineCount := Max(AValue, 1);

  if FMaxLineCount <> LMaxLineCount then
  begin
    FMaxLineCount := LMaxLineCount;

    DoChange;
  end;
end;

procedure TDatabaseGridTitle.SetVerticalLines(const AValue: Boolean);
begin
  if FVerticalLines <> AValue then
  begin
    FVerticalLines := AValue;

    DoChange;
  end;
end;

procedure TDatabaseGridTitle.SetVisible(const AValue: Boolean);
begin
  if FVisible <> AValue then
  begin
    FVisible := AValue;

    DoChange;
  end;
end;

end.
