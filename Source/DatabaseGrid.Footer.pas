unit DatabaseGrid.Footer;

interface

uses
  System.Classes;

type
  TDatabaseGridFooter = class(TPersistent)
  strict private
    FOnChange: TNotifyEvent;
    FVerticalLines: Boolean;
    FVisible: Boolean;
    procedure DoChange;
    procedure SetVerticalLines(const AValue: Boolean);
    procedure SetVisible(const AValue: Boolean);
  public
    constructor Create;
    procedure Assign(ASource: TPersistent); override;
    property OnChange: TNotifyEvent read FOnChange write FOnChange;
  published
    property VerticalLines: Boolean read FVerticalLines write SetVerticalLines default True;
    property Visible: Boolean read FVisible write SetVisible default False;
  end;

implementation

constructor TDatabaseGridFooter.Create;
begin
  inherited Create;

  FVerticalLines := True;
end;

procedure TDatabaseGridFooter.Assign(ASource: TPersistent);
begin
  if Assigned(ASource) and (ASource is TDatabaseGridFooter) then
  with ASource as TDatabaseGridFooter do
  begin
    Self.FVerticalLines := FVerticalLines;
    Self.FVisible := FVisible;

    Self.DoChange;
  end
  else
    inherited Assign(ASource);
end;

procedure TDatabaseGridFooter.DoChange;
begin
  if Assigned(FOnChange) then
    FOnChange(Self);
end;

procedure TDatabaseGridFooter.SetVerticalLines(const AValue: Boolean);
begin
  if FVerticalLines <> AValue then
  begin
    FVerticalLines := AValue;

    DoChange;
  end;
end;

procedure TDatabaseGridFooter.SetVisible(const AValue: Boolean);
begin
  if FVisible <> AValue then
  begin
    FVisible := AValue;

    DoChange;
  end;
end;

end.
