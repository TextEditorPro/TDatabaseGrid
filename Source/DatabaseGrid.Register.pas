unit DatabaseGrid.Register;

interface

uses
  System.Classes, DesignIntf, DatabaseGrid, DatabaseGrid.Columns, DatabaseGrid.Design.Editors;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('DatabaseGrid', [TDatabaseGrid]);
  RegisterComponentEditor(TDatabaseGrid, TDatabaseGridComponentEditor);
  RegisterPropertyEditor(TypeInfo(TDatabaseGridColumns), TCustomDatabaseGrid, 'Columns', TDatabaseGridColumnsProperty);
end;

end.
