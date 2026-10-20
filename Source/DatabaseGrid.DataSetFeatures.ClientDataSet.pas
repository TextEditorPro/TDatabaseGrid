unit DatabaseGrid.DataSetFeatures.ClientDataSet;

interface

uses
  Data.DB, DatabaseGrid.DataSetFeatures;

type
  TDatabaseGridClientDataSetFeatures = class(TDatabaseGridDataSetFeatures)
  public
    function ApplySorting(const ADataSet: TDataSet; const ASortFields: TArray<TDatabaseGridSortField>;
      const ACanReopen: Boolean): Boolean; override;
    function SortingChangesBookmarks: Boolean; override;
    procedure ResetSorting(const ADataSet: TDataSet); override;
  end;

implementation

uses
  System.SysUtils, Datasnap.DBClient;

const
  SORT_INDEX_NAME = 'DatabaseGridSortIndex';

type
  TClientDataSetAccess = class(TCustomClientDataSet);

function TDatabaseGridClientDataSetFeatures.SortingChangesBookmarks: Boolean;
begin
  Result := True;
end;

function TDatabaseGridClientDataSetFeatures.ApplySorting(const ADataSet: TDataSet;
  const ASortFields: TArray<TDatabaseGridSortField>; const ACanReopen: Boolean): Boolean;
var
  LClientDataSet: TClientDataSetAccess;
  LDescendingFieldNames, LFieldNames, LSortFieldNames: string;
  LField: TField;
begin
  Result := True;

  LClientDataSet := TClientDataSetAccess(ADataSet);

  if Assigned(LClientDataSet.MasterSource) then
    Exit;

  LFieldNames := '';
  LDescendingFieldNames := '';

  for var LIndex := 0 to High(ASortFields) do
  begin
    LField := LClientDataSet.FindField(ASortFields[LIndex].FieldName);

    if not Assigned(LField) then
      Continue;

    if LField.FieldKind = fkLookup then
      LSortFieldNames := LField.KeyFields
    else
    if LField.FieldKind in [fkData, fkInternalCalc] then
      LSortFieldNames := LField.FieldName
    else
      Continue;

    if not LFieldNames.IsEmpty then
      LFieldNames := LFieldNames + ';';

    LFieldNames := LFieldNames + LSortFieldNames;

    if ASortFields[LIndex].Descending then
    begin
      if not LDescendingFieldNames.IsEmpty then
        LDescendingFieldNames := LDescendingFieldNames + ';';

      LDescendingFieldNames := LDescendingFieldNames + LSortFieldNames;
    end;
  end;

  LClientDataSet.DisableControls;
  try
    if SameText(LClientDataSet.IndexName, SORT_INDEX_NAME) then
      LClientDataSet.IndexName := '';

    LClientDataSet.IndexDefs.Update;

    if LClientDataSet.IndexDefs.IndexOf(SORT_INDEX_NAME) >= 0 then
      LClientDataSet.DeleteIndex(SORT_INDEX_NAME);

    if not LFieldNames.IsEmpty then
    begin
      LClientDataSet.AddIndex(SORT_INDEX_NAME, LFieldNames, [], LDescendingFieldNames);
      LClientDataSet.IndexName := SORT_INDEX_NAME;
    end;
  finally
    LClientDataSet.EnableControls;
  end;
end;

procedure TDatabaseGridClientDataSetFeatures.ResetSorting(const ADataSet: TDataSet);
var
  LClientDataSet: TClientDataSetAccess;
begin
  LClientDataSet := TClientDataSetAccess(ADataSet);

  if SameText(LClientDataSet.IndexName, SORT_INDEX_NAME) then
    LClientDataSet.IndexName := '';
end;

initialization

  RegisterDatabaseGridDataSetFeatures(TCustomClientDataSet, TDatabaseGridClientDataSetFeatures);

finalization

  UnregisterDatabaseGridDataSetFeatures(TCustomClientDataSet);

end.
