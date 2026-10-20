unit DatabaseGrid.DataSetFeatures.JvMemoryData;

interface

uses
  Data.DB, DatabaseGrid.DataSetFeatures;

type
  TDatabaseGridJvMemoryDataFeatures = class(TDatabaseGridDataSetFeatures)
  public
    function ApplySorting(const ADataSet: TDataSet; const ASortFields: TArray<TDatabaseGridSortField>;
      const ACanReopen: Boolean): Boolean; override;
  end;

implementation

uses
  System.SysUtils, JvMemoryDataset;

function TDatabaseGridJvMemoryDataFeatures.ApplySorting(const ADataSet: TDataSet;
  const ASortFields: TArray<TDatabaseGridSortField>; const ACanReopen: Boolean): Boolean;
var
  LDescending: Boolean;
  LField: TField;
  LFieldNames: string;
begin
  Result := True;

  LFieldNames := '';
  LDescending := False;

  for var LIndex := 0 to High(ASortFields) do
  begin
    LField := ADataSet.FindField(ASortFields[LIndex].FieldName);

    if not Assigned(LField) or (LField.FieldKind <> fkData) or LField.IsBlob then
      Continue;

    if LFieldNames.IsEmpty then
      LDescending := ASortFields[LIndex].Descending
    else
      LFieldNames := LFieldNames + ';';

    LFieldNames := LFieldNames + LField.FieldName;
  end;

  TJvMemoryData(ADataSet).SortOnFields(LFieldNames, True, LDescending);
end;

initialization

  RegisterDatabaseGridDataSetFeatures(TJvMemoryData, TDatabaseGridJvMemoryDataFeatures);

finalization

  UnregisterDatabaseGridDataSetFeatures(TJvMemoryData);

end.
