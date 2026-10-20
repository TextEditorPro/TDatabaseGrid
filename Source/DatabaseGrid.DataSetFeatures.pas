unit DatabaseGrid.DataSetFeatures;

interface

uses
  System.Classes, Data.DB, DatabaseGrid.Types;

type
  TDatabaseGridFieldFilter = record
    Field: TField;
    &Operator: TDatabaseGridColumnFilterOperator;
    Value: string;
    Value2: string;
    Values: TArray<string>;
  end;

  TDatabaseGridFilterPart = (fpColumnFilters, fpSearch);
  TDatabaseGridFilterParts = set of TDatabaseGridFilterPart;

  TDatabaseGridFooterValue = record
    Field: TField;
    Value: Variant;
    ValueType: TDatabaseGridFooterValueType;
  end;

  TDatabaseGridSortField = record
    Descending: Boolean;
    FieldName: string;
  end;

  TDatabaseGridDataSetFeatures = class(TObject)
  public
    constructor Create; virtual;
    function ApplyFilters(const ADataSet: TDataSet; const ASearchText: string; const ASearchFields: TArray<TField>;
      const AColumnFilters: TArray<TDatabaseGridFieldFilter>; const ACanReopen: Boolean; out AAppliedParts: TDatabaseGridFilterParts): Boolean; virtual;
    function ApplySorting(const ADataSet: TDataSet; const ASortFields: TArray<TDatabaseGridSortField>; const ACanReopen: Boolean): Boolean; virtual;
    function GetColumnValues(const ADataSet: TDataSet; const AField: TField; const AValues: TStrings; const ALimit: Integer): Boolean; virtual;
    function GetFooterValues(const ADataSet: TDataSet; var AValues: TArray<TDatabaseGridFooterValue>): Boolean; virtual;
    function IsFiltered(const ADataSet: TDataSet): Boolean; virtual;
    function SortingChangesBookmarks: Boolean; virtual;
    procedure ResetSorting(const ADataSet: TDataSet); virtual;
  end;

  TDatabaseGridDataSetFeaturesClass = class of TDatabaseGridDataSetFeatures;

function FindDatabaseGridDataSetFeatures(const ADataSet: TDataSet): TDatabaseGridDataSetFeatures;
procedure RegisterDatabaseGridDataSetFeatures(const ADataSetClass: TDataSetClass; const AFeaturesClass: TDatabaseGridDataSetFeaturesClass);
procedure UnregisterDatabaseGridDataSetFeatures(const ADataSetClass: TDataSetClass);

implementation

uses
  System.Generics.Collections;

var
  GDataSetFeatures: TObjectDictionary<TClass, TDatabaseGridDataSetFeatures>;

function FindDatabaseGridDataSetFeatures(const ADataSet: TDataSet): TDatabaseGridDataSetFeatures;
var
  LClass: TClass;
begin
  Result := nil;

  if not Assigned(GDataSetFeatures) or not Assigned(ADataSet) then
    Exit;

  LClass := ADataSet.ClassType;

  while Assigned(LClass) and not GDataSetFeatures.TryGetValue(LClass, Result) do
    LClass := LClass.ClassParent;
end;

procedure RegisterDatabaseGridDataSetFeatures(const ADataSetClass: TDataSetClass; const AFeaturesClass: TDatabaseGridDataSetFeaturesClass);
begin
  if not Assigned(GDataSetFeatures) then
    GDataSetFeatures := TObjectDictionary<TClass, TDatabaseGridDataSetFeatures>.Create([doOwnsValues]);

  GDataSetFeatures.AddOrSetValue(ADataSetClass, AFeaturesClass.Create);
end;

procedure UnregisterDatabaseGridDataSetFeatures(const ADataSetClass: TDataSetClass);
begin
  if Assigned(GDataSetFeatures) then
    GDataSetFeatures.Remove(ADataSetClass);
end;

{ TDatabaseGridDataSetFeatures }

constructor TDatabaseGridDataSetFeatures.Create;
begin
  inherited Create;
end;

function TDatabaseGridDataSetFeatures.ApplyFilters(const ADataSet: TDataSet; const ASearchText: string; const ASearchFields: TArray<TField>;
  const AColumnFilters: TArray<TDatabaseGridFieldFilter>; const ACanReopen: Boolean; out AAppliedParts: TDatabaseGridFilterParts): Boolean;
begin
  AAppliedParts := [];

  Result := True;
end;

function TDatabaseGridDataSetFeatures.ApplySorting(const ADataSet: TDataSet; const ASortFields: TArray<TDatabaseGridSortField>; const ACanReopen: Boolean): Boolean;
begin
  Result := True;
end;

function TDatabaseGridDataSetFeatures.GetColumnValues(const ADataSet: TDataSet; const AField: TField; const AValues: TStrings; const ALimit: Integer): Boolean;
begin
  Result := False;
end;

function TDatabaseGridDataSetFeatures.GetFooterValues(const ADataSet: TDataSet; var AValues: TArray<TDatabaseGridFooterValue>): Boolean;
begin
  Result := False;
end;

function TDatabaseGridDataSetFeatures.IsFiltered(const ADataSet: TDataSet): Boolean;
begin
  Result := False;
end;

function TDatabaseGridDataSetFeatures.SortingChangesBookmarks: Boolean;
begin
  Result := False;
end;

procedure TDatabaseGridDataSetFeatures.ResetSorting(const ADataSet: TDataSet);
begin
end;

initialization

finalization

  GDataSetFeatures.Free;

end.
