unit DatabaseGrid.ColumnFilter;

interface

uses
  System.Classes, DatabaseGrid.Consts, DatabaseGrid.Types;

type
  TDatabaseGridColumnFilter = class(TPersistent)
  strict private
    FOnChange: TNotifyEvent;
    FOptions: TDatabaseGridColumnFilterOptions;
    FValueListLimit: Integer;
    FVisible: Boolean;
    procedure DoChange;
    procedure SetOptions(const AValue: TDatabaseGridColumnFilterOptions);
    procedure SetValueListLimit(const AValue: Integer);
    procedure SetVisible(const AValue: Boolean);
  public
    constructor Create;
    procedure Assign(ASource: TPersistent); override;
    procedure SetOption(const AOption: TDatabaseGridColumnFilterOption; const AEnabled: Boolean);
    property OnChange: TNotifyEvent read FOnChange write FOnChange;
  published
    property Options: TDatabaseGridColumnFilterOptions read FOptions write SetOptions default TDatabaseGridDefault.ColumnFilterOptions;
    property ValueListLimit: Integer read FValueListLimit write SetValueListLimit default TDatabaseGridDefault.ValueListLimit;
    property Visible: Boolean read FVisible write SetVisible default False;
  end;

implementation

uses
  System.Math;

constructor TDatabaseGridColumnFilter.Create;
begin
  inherited Create;

  FOptions := TDatabaseGridDefault.ColumnFilterOptions;
  FValueListLimit := TDatabaseGridDefault.ValueListLimit;
end;

procedure TDatabaseGridColumnFilter.Assign(ASource: TPersistent);
begin
  if Assigned(ASource) and (ASource is TDatabaseGridColumnFilter) then
  with ASource as TDatabaseGridColumnFilter do
  begin
    Self.FOptions := FOptions;
    Self.FValueListLimit := FValueListLimit;
    Self.FVisible := FVisible;

    Self.DoChange;
  end
  else
    inherited Assign(ASource);
end;

procedure TDatabaseGridColumnFilter.DoChange;
begin
  if Assigned(FOnChange) then
    FOnChange(Self);
end;

procedure TDatabaseGridColumnFilter.SetOption(const AOption: TDatabaseGridColumnFilterOption; const AEnabled: Boolean);
begin
  if AEnabled then
    SetOptions(FOptions + [AOption])
  else
    SetOptions(FOptions - [AOption]);
end;

procedure TDatabaseGridColumnFilter.SetOptions(const AValue: TDatabaseGridColumnFilterOptions);
begin
  if FOptions <> AValue then
  begin
    FOptions := AValue;

    DoChange;
  end;
end;

procedure TDatabaseGridColumnFilter.SetValueListLimit(const AValue: Integer);
begin
  FValueListLimit := Max(AValue, 0);
end;

procedure TDatabaseGridColumnFilter.SetVisible(const AValue: Boolean);
begin
  if FVisible <> AValue then
  begin
    FVisible := AValue;

    DoChange;
  end;
end;

end.
