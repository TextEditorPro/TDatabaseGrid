unit DatabaseGrid.DataGrouping;

interface

uses
  System.Classes, Vcl.ImgList, DatabaseGrid.Types;

type
  TDatabaseGridDataGroupLevel = class(TCollectionItem)
  strict private
    FFieldName: string;
    FSortOrder: TDatabaseGridSortOrder;
    procedure SetFieldName(const AValue: string);
    procedure SetSortOrder(const AValue: TDatabaseGridSortOrder);
  protected
    function GetDisplayName: string; override;
  public
    procedure Assign(ASource: TPersistent); override;
  published
    property FieldName: string read FFieldName write SetFieldName;
    property SortOrder: TDatabaseGridSortOrder read FSortOrder write SetSortOrder default soAscending;
  end;

  TDatabaseGridDataGroupLevels = class(TOwnedCollection)
  strict private
    FOnChange: TNotifyEvent;
    function GetItem(const AIndex: Integer): TDatabaseGridDataGroupLevel;
    procedure SetItem(const AIndex: Integer; const AValue: TDatabaseGridDataGroupLevel);
  protected
    procedure Update(AItem: TCollectionItem); override;
  public
    constructor Create(const AOwner: TPersistent);
    function Add: TDatabaseGridDataGroupLevel;
    property Items[const AIndex: Integer]: TDatabaseGridDataGroupLevel read GetItem write SetItem; default;
    property OnChange: TNotifyEvent read FOnChange write FOnChange;
  end;

  TDatabaseGridDataGrouping = class(TPersistent)
  strict private
    FActive: Boolean;
    FDefaultExpanded: Boolean;
    FImages: TCustomImageList;
    FLevels: TDatabaseGridDataGroupLevels;
    FOnChange: TNotifyEvent;
    FOwner: TPersistent;
    function IsLevelsStored: Boolean;
    procedure DoChange;
    procedure LevelsChanged(ASender: TObject);
    procedure SetActive(const AValue: Boolean);
    procedure SetDefaultExpanded(const AValue: Boolean);
    procedure SetImages(const AValue: TCustomImageList);
    procedure SetLevels(const AValue: TDatabaseGridDataGroupLevels);
  protected
    function GetOwner: TPersistent; override;
  public
    constructor Create(const AOwner: TPersistent);
    destructor Destroy; override;
    procedure Assign(ASource: TPersistent); override;
    property OnChange: TNotifyEvent read FOnChange write FOnChange;
  published
    property Active: Boolean read FActive write SetActive default False;
    property DefaultExpanded: Boolean read FDefaultExpanded write SetDefaultExpanded default False;
    property Images: TCustomImageList read FImages write SetImages;
    property Levels: TDatabaseGridDataGroupLevels read FLevels write SetLevels stored IsLevelsStored;
  end;

implementation

uses
  System.SysUtils;

{ TDatabaseGridDataGroupLevel }

procedure TDatabaseGridDataGroupLevel.Assign(ASource: TPersistent);
begin
  if Assigned(ASource) and (ASource is TDatabaseGridDataGroupLevel) then
  with ASource as TDatabaseGridDataGroupLevel do
  begin
    Self.FFieldName := FFieldName;
    Self.FSortOrder := FSortOrder;

    Self.Changed(False);
  end
  else
    inherited Assign(ASource);
end;

function TDatabaseGridDataGroupLevel.GetDisplayName: string;
begin
  Result := FFieldName;

  if Result.IsEmpty then
    Result := inherited GetDisplayName;
end;

procedure TDatabaseGridDataGroupLevel.SetFieldName(const AValue: string);
begin
  if FFieldName <> AValue then
  begin
    FFieldName := AValue;

    Changed(False);
  end;
end;

procedure TDatabaseGridDataGroupLevel.SetSortOrder(const AValue: TDatabaseGridSortOrder);
begin
  if FSortOrder <> AValue then
  begin
    FSortOrder := AValue;

    Changed(False);
  end;
end;

{ TDatabaseGridDataGroupLevels }

constructor TDatabaseGridDataGroupLevels.Create(const AOwner: TPersistent);
begin
  inherited Create(AOwner, TDatabaseGridDataGroupLevel);
end;

function TDatabaseGridDataGroupLevels.Add: TDatabaseGridDataGroupLevel;
begin
  Result := inherited Add as TDatabaseGridDataGroupLevel;
end;

function TDatabaseGridDataGroupLevels.GetItem(const AIndex: Integer): TDatabaseGridDataGroupLevel;
begin
  Result := inherited GetItem(AIndex) as TDatabaseGridDataGroupLevel;
end;

procedure TDatabaseGridDataGroupLevels.SetItem(const AIndex: Integer; const AValue: TDatabaseGridDataGroupLevel);
begin
  inherited SetItem(AIndex, AValue);
end;

procedure TDatabaseGridDataGroupLevels.Update(AItem: TCollectionItem);
begin
  inherited Update(AItem);

  if Assigned(FOnChange) then
    FOnChange(Self);
end;

{ TDatabaseGridDataGrouping }

constructor TDatabaseGridDataGrouping.Create(const AOwner: TPersistent);
begin
  inherited Create;

  FOwner := AOwner;
  FLevels := TDatabaseGridDataGroupLevels.Create(Self);
  FLevels.OnChange := LevelsChanged;
end;

destructor TDatabaseGridDataGrouping.Destroy;
begin
  FLevels.OnChange := nil;
  FLevels.Free;

  inherited Destroy;
end;

procedure TDatabaseGridDataGrouping.Assign(ASource: TPersistent);
begin
  if Assigned(ASource) and (ASource is TDatabaseGridDataGrouping) then
  with ASource as TDatabaseGridDataGrouping do
  begin
    Self.FActive := FActive;
    Self.FDefaultExpanded := FDefaultExpanded;
    Self.FImages := FImages;
    Self.FLevels.Assign(FLevels);

    Self.DoChange;
  end
  else
    inherited Assign(ASource);
end;

function TDatabaseGridDataGrouping.IsLevelsStored: Boolean;
begin
  Result := FLevels.Count > 0;
end;

function TDatabaseGridDataGrouping.GetOwner: TPersistent;
begin
  Result := FOwner;
end;

procedure TDatabaseGridDataGrouping.DoChange;
begin
  if Assigned(FOnChange) then
    FOnChange(Self);
end;

procedure TDatabaseGridDataGrouping.LevelsChanged(ASender: TObject);
begin
  DoChange;
end;

procedure TDatabaseGridDataGrouping.SetActive(const AValue: Boolean);
begin
  if FActive <> AValue then
  begin
    FActive := AValue;

    DoChange;
  end;
end;

procedure TDatabaseGridDataGrouping.SetDefaultExpanded(const AValue: Boolean);
begin
  if FDefaultExpanded <> AValue then
  begin
    FDefaultExpanded := AValue;

    DoChange;
  end;
end;

procedure TDatabaseGridDataGrouping.SetImages(const AValue: TCustomImageList);
begin
  if FImages <> AValue then
  begin
    FImages := AValue;

    DoChange;
  end;
end;

procedure TDatabaseGridDataGrouping.SetLevels(const AValue: TDatabaseGridDataGroupLevels);
begin
  FLevels.Assign(AValue);
end;

end.
