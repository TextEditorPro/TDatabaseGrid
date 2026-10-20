unit DatabaseGrid.DataSetFeatures.DAC;

interface

uses
  System.Classes, System.Generics.Collections, Data.DB, DBAccess, DatabaseGrid.DataSetFeatures;

type
  TDatabaseGridServerCondition = record
    Condition: string;
    FieldName: string;
  end;

  TDatabaseGridDACDataSetFeatures = class(TDatabaseGridDataSetFeatures)
  strict private type
    TDatabaseGridServerQuery = record
      ColumnConditions: TArray<TDatabaseGridServerCondition>;
      ModifiedSQL: string;
      OrderBy: string;
      OriginalSQL: string;
      SearchCondition: string;
    end;
  strict private
    FDataSetNotifier: TComponent;
    FServerQueries: TDictionary<TDataSet, TDatabaseGridServerQuery>;
    function CanFilterOnServer(const ADataSet: TCustomDADataSet; const AQuery: TDatabaseGridServerQuery; const AStored: Boolean): Boolean;
    function CanUseServer(const ADataSet: TCustomDADataSet; const AStored: Boolean): Boolean;
    function GetCondition(const AQuery: TDatabaseGridServerQuery; const AExceptFieldName: string): string;
    function GetQuerySQL(const ADataSet: TCustomDADataSet; const AExceptFieldName: string): string;
    function ReopenWithQuery(const ADataSet: TCustomDADataSet; const AQuery, AFallbackQuery: TDatabaseGridServerQuery;
      const AClearIndexFieldNames: Boolean): Boolean;
    function TryBuildSQL(const ADataSet: TCustomDADataSet; const AQuery: TDatabaseGridServerQuery; out ASQL: string): Boolean;
    function TryGetColumnConditions(const ADataSet: TCustomDADataSet; const AFilters: TArray<TDatabaseGridFieldFilter>;
      out AConditions: TArray<TDatabaseGridServerCondition>): Boolean;
    function TryGetOrderBy(const ADataSet: TDataSet; const ASortFields: TArray<TDatabaseGridSortField>; out AOrderBy: string): Boolean;
    function TryGetServerQuery(const ADataSet: TCustomDADataSet; out AQuery: TDatabaseGridServerQuery): Boolean;
    procedure DataSetRemoved(const ADataSet: TComponent);
    procedure OpenQuery(const ADataSet: TCustomDADataSet; const AQuery: TDatabaseGridServerQuery; const AClearIndexFieldNames: Boolean);
    procedure SortLocally(const ADataSet: TDataSet; const ASortFields: TArray<TDatabaseGridSortField>);
  protected
    function TryGetColumnFilterCondition(const ADataSet: TCustomDADataSet; const AFilter: TDatabaseGridFieldFilter;
      out ACondition: string): Boolean; virtual;
    function TryGetFieldColumn(const ADataSet: TCustomDADataSet; const AField: TField; out ATableName, AColumnName: string): Boolean;
    function TryGetSearchCondition(const ADataSet: TCustomDADataSet; const AWords: TArray<string>; const AFields: TArray<TField>;
      out ACondition: string): Boolean; virtual;
  public
    constructor Create; override;
    destructor Destroy; override;
    function ApplyFilters(const ADataSet: TDataSet; const ASearchText: string; const ASearchFields: TArray<TField>;
      const AColumnFilters: TArray<TDatabaseGridFieldFilter>; const ACanReopen: Boolean;
      out AAppliedParts: TDatabaseGridFilterParts): Boolean; override;
    function ApplySorting(const ADataSet: TDataSet; const ASortFields: TArray<TDatabaseGridSortField>;
      const ACanReopen: Boolean): Boolean; override;
    function GetColumnValues(const ADataSet: TDataSet; const AField: TField; const AValues: TStrings;
      const ALimit: Integer): Boolean; override;
    function GetFooterValues(const ADataSet: TDataSet; var AValues: TArray<TDatabaseGridFooterValue>): Boolean; override;
    function IsFiltered(const ADataSet: TDataSet): Boolean; override;
  end;

implementation

uses
  System.StrUtils, System.SysUtils, System.Variants, CRAccess, CRParser, MemData, MemDS, DatabaseGrid.Types;

type
  TCustomDADataSetAccess = class(TCustomDADataSet);

  TDatabaseGridDataSetRemovedEvent = procedure(const ADataSet: TComponent) of object;

  TDatabaseGridDataSetNotifier = class(TComponent)
  strict private
    FOnRemoved: TDatabaseGridDataSetRemovedEvent;
  protected
    procedure Notification(AComponent: TComponent; AOperation: TOperation); override;
  public
    constructor Create(const AOnRemoved: TDatabaseGridDataSetRemovedEvent); reintroduce;
  end;

  TDatabaseGridSQLInfo = record
    HasCommonTableExpressions: Boolean;
    HasDerivedTables: Boolean;
    HasRowLimit: Boolean;
    HasUnion: Boolean;
    OrderStart: Integer;
    SelectFound: Boolean;
    TailStart: Integer;
  end;

constructor TDatabaseGridDataSetNotifier.Create(const AOnRemoved: TDatabaseGridDataSetRemovedEvent);
begin
  inherited Create(nil);

  FOnRemoved := AOnRemoved;
end;

procedure TDatabaseGridDataSetNotifier.Notification(AComponent: TComponent; AOperation: TOperation);
begin
  inherited Notification(AComponent, AOperation);

  if AOperation = opRemove then
    FOnRemoved(AComponent);
end;

procedure AddSQLCondition(var ACondition: string; const APart: string);
begin
  if APart.IsEmpty then
    Exit;

  if not ACondition.IsEmpty then
    ACondition := ACondition + ' AND ';

  ACondition := ACondition + '(' + APart + ')';
end;

function AnalyzeSQL(const ASQL: string; const AParserClass: TSQLParserClass): TDatabaseGridSQLInfo;
var
  LBracketLevel: Integer;
  LCode: Integer;
  LFromClause: Boolean;
  LLexem: string;
  LLexemStart: Integer;
  LParser: TSQLParser;
  LPreviousCode: Integer;
  LTextEnd: Integer;
begin
  Result := Default(TDatabaseGridSQLInfo);
  LBracketLevel := 0;
  LFromClause := False;
  LPreviousCode := lcEnd;
  LTextEnd := 0;

  LParser := AParserClass.Create(ASQL);
  try
    LParser.OmitBlank := True;
    LParser.OmitComment := True;

    LCode := LParser.GetNext(LLexem);

    while LCode <> lcEnd do
    begin
      LLexemStart := LParser.CurrPos - Length(LLexem) + 1;

      if LFromClause and (LBracketLevel = 1) and (LPreviousCode = lxLeftBracket) and (LCode = lxSELECT) then
        Result.HasDerivedTables := True;

      if LCode = lxLeftBracket then
        Inc(LBracketLevel)
      else
      if LCode = lxRightBracket then
        Dec(LBracketLevel)
      else
      if LBracketLevel = 0 then
      begin
        if (LCode = lxWITH) and not Result.SelectFound then
          Result.HasCommonTableExpressions := True
        else
        if LCode = lxSELECT then
        begin
          Result.SelectFound := True;
          LFromClause := False;
        end
        else
        if Result.SelectFound and (LCode <> lcString) then
        begin
          if (LCode = lxFIRST) or (LCode = lxFETCH) or (LCode = lxOFFSET) or MatchText(LLexem, ['ROWS', 'SKIP']) then
            Result.HasRowLimit := True;

          if LCode = lxUNION then
            Result.HasUnion := True;

          if LCode = lxFROM then
            LFromClause := True
          else
          if (LCode = lxWHERE) or (LCode = lxGROUP) or (LCode = lxHAVING) or (LCode = lxORDER) or (LCode = lxUNION) or
            MatchText(LLexem, ['PLAN', 'WINDOW']) then
            LFromClause := False;

          if (LCode = lxORDER) and (Result.TailStart = 0) then
            Result.OrderStart := LLexemStart
          else
          if ((LCode = lxFOR) or (LCode = lxWITH) or (LCode = lxSemicolon)) and (Result.TailStart = 0) then
          begin
            Result.TailStart := LLexemStart;
            LFromClause := False;
          end;
        end;
      end;

      LTextEnd := LParser.CurrPos;
      LPreviousCode := LCode;
      LCode := LParser.GetNext(LLexem);
    end;
  finally
    LParser.Free;
  end;

  if Result.TailStart = 0 then
    Result.TailStart := LTextEnd + 1;
end;

function SameServerConditions(const AConditions, AOtherConditions: TArray<TDatabaseGridServerCondition>): Boolean;
begin
  if Length(AConditions) <> Length(AOtherConditions) then
    Exit(False);

  for var LIndex := 0 to High(AConditions) do
  if (AConditions[LIndex].Condition <> AOtherConditions[LIndex].Condition) or
    (AConditions[LIndex].FieldName <> AOtherConditions[LIndex].FieldName) then
    Exit(False);

  Result := True;
end;

function TryReplaceOrderBy(const ASQL, AOrderBy: string; const AParserClass: TSQLParserClass; out ASortedSQL: string): Boolean;
var
  LInfo: TDatabaseGridSQLInfo;
  LOrderStart: Integer;
  LTail: string;
begin
  ASortedSQL := '';

  LInfo := AnalyzeSQL(ASQL, AParserClass);

  if not LInfo.SelectFound or LInfo.HasRowLimit then
    Exit(False);

  LOrderStart := LInfo.OrderStart;

  if LOrderStart = 0 then
    LOrderStart := LInfo.TailStart;

  LTail := Trim(Copy(ASQL, LInfo.TailStart, MaxInt));

  ASortedSQL := TrimRight(Copy(ASQL, 1, LOrderStart - 1)) + sLineBreak + 'ORDER BY ' + AOrderBy;

  if not LTail.IsEmpty then
    ASortedSQL := ASortedSQL + ' ' + LTail;

  Result := True;
end;

{ TDatabaseGridDACDataSetFeatures }

constructor TDatabaseGridDACDataSetFeatures.Create;
begin
  inherited Create;

  FDataSetNotifier := TDatabaseGridDataSetNotifier.Create(DataSetRemoved);
  FServerQueries := TDictionary<TDataSet, TDatabaseGridServerQuery>.Create;
end;

destructor TDatabaseGridDACDataSetFeatures.Destroy;
begin
  FDataSetNotifier.Free;
  FServerQueries.Free;

  inherited Destroy;
end;

function TDatabaseGridDACDataSetFeatures.CanFilterOnServer(const ADataSet: TCustomDADataSet; const AQuery: TDatabaseGridServerQuery;
  const AStored: Boolean): Boolean;
var
  LInfo: TDatabaseGridSQLInfo;
begin
  if not CanUseServer(ADataSet, AStored) then
    Exit(False);

  LInfo := AnalyzeSQL(AQuery.OriginalSQL, TCustomDADataSetAccess(ADataSet).GetParserClass);

  Result := LInfo.SelectFound and not LInfo.HasCommonTableExpressions and not LInfo.HasDerivedTables and not LInfo.HasRowLimit and
    not LInfo.HasUnion;
end;

function TDatabaseGridDACDataSetFeatures.CanUseServer(const ADataSet: TCustomDADataSet; const AStored: Boolean): Boolean;
begin
  if not Assigned(ADataSet.Connection) or not ADataSet.Connection.Connected or (ADataSet.State <> dsBrowse) or
    (Trim(ADataSet.SQL.Text) = '') or ADataSet.CachedUpdates and ADataSet.UpdatesPending then
    Exit(False);

  Result := AStored or not ADataSet.Fetched;
end;

function TDatabaseGridDACDataSetFeatures.GetCondition(const AQuery: TDatabaseGridServerQuery; const AExceptFieldName: string): string;
begin
  Result := '';

  AddSQLCondition(Result, AQuery.SearchCondition);

  for var LIndex := 0 to High(AQuery.ColumnConditions) do
  if not SameText(AQuery.ColumnConditions[LIndex].FieldName, AExceptFieldName) then
    AddSQLCondition(Result, AQuery.ColumnConditions[LIndex].Condition);
end;

function TDatabaseGridDACDataSetFeatures.GetQuerySQL(const ADataSet: TCustomDADataSet; const AExceptFieldName: string): string;
var
  LCondition: string;
  LQuery: TDatabaseGridServerQuery;
begin
  TryGetServerQuery(ADataSet, LQuery);

  LCondition := GetCondition(LQuery, AExceptFieldName);

  AddSQLCondition(LCondition, ADataSet.FilterSQL);

  Result := LQuery.OriginalSQL;

  if not LCondition.IsEmpty then
    Result := TCustomDADataSetAccess(ADataSet).SQLAddWhere(Result, LCondition);
end;

function TDatabaseGridDACDataSetFeatures.ReopenWithQuery(const ADataSet: TCustomDADataSet; const AQuery,
  AFallbackQuery: TDatabaseGridServerQuery; const AClearIndexFieldNames: Boolean): Boolean;
begin
  Result := True;

  ADataSet.DisableControls;
  try
    try
      OpenQuery(ADataSet, AQuery, AClearIndexFieldNames);
    except
      on EDatabaseError do
      begin
        OpenQuery(ADataSet, AFallbackQuery, AClearIndexFieldNames);

        Result := False;
      end;
    end;
  finally
    ADataSet.EnableControls;
  end;
end;

function TDatabaseGridDACDataSetFeatures.TryBuildSQL(const ADataSet: TCustomDADataSet; const AQuery: TDatabaseGridServerQuery;
  out ASQL: string): Boolean;
var
  LCondition: string;
  LFilteredSQL: string;
begin
  LFilteredSQL := AQuery.OriginalSQL;
  LCondition := GetCondition(AQuery, '');

  if not LCondition.IsEmpty then
    LFilteredSQL := TCustomDADataSetAccess(ADataSet).SQLAddWhere(LFilteredSQL, LCondition);

  if AQuery.OrderBy.IsEmpty then
  begin
    ASQL := LFilteredSQL;

    Exit(True);
  end;

  Result := TryReplaceOrderBy(LFilteredSQL, AQuery.OrderBy, TCustomDADataSetAccess(ADataSet).GetParserClass, ASQL);
end;

function TDatabaseGridDACDataSetFeatures.TryGetColumnConditions(const ADataSet: TCustomDADataSet;
  const AFilters: TArray<TDatabaseGridFieldFilter>; out AConditions: TArray<TDatabaseGridServerCondition>): Boolean;
var
  LCondition: TDatabaseGridServerCondition;
begin
  AConditions := nil;

  for var LIndex := 0 to High(AFilters) do
  begin
    if not Assigned(AFilters[LIndex].Field) then
      Continue;

    if not TryGetColumnFilterCondition(ADataSet, AFilters[LIndex], LCondition.Condition) then
    begin
      AConditions := nil;

      Exit(False);
    end;

    LCondition.FieldName := AFilters[LIndex].Field.FieldName;

    AConditions := AConditions + [LCondition];
  end;

  Result := True;
end;

function TDatabaseGridDACDataSetFeatures.TryGetOrderBy(const ADataSet: TDataSet; const ASortFields: TArray<TDatabaseGridSortField>;
  out AOrderBy: string): Boolean;
var
  LField: TField;
begin
  AOrderBy := '';

  for var LIndex := 0 to High(ASortFields) do
  begin
    LField := ADataSet.FindField(ASortFields[LIndex].FieldName);

    if not Assigned(LField) then
      Continue;

    if (LField.FieldKind <> fkData) or LField.IsBlob or (LField.FieldNo <= 0) or Assigned(LField.ParentField) then
      Exit(False);

    if not AOrderBy.IsEmpty then
      AOrderBy := AOrderBy + ', ';

    AOrderBy := AOrderBy + LField.FieldNo.ToString;

    if ASortFields[LIndex].Descending then
      AOrderBy := AOrderBy + ' DESC';
  end;

  Result := True;
end;

function TDatabaseGridDACDataSetFeatures.TryGetServerQuery(const ADataSet: TCustomDADataSet; out AQuery: TDatabaseGridServerQuery): Boolean;
begin
  if FServerQueries.TryGetValue(ADataSet, AQuery) then
  begin
    if ADataSet.SQL.Text = AQuery.ModifiedSQL then
      Exit(True);

    FServerQueries.Remove(ADataSet);
  end;

  AQuery := Default(TDatabaseGridServerQuery);
  AQuery.OriginalSQL := ADataSet.SQL.Text;

  Result := False;
end;

procedure TDatabaseGridDACDataSetFeatures.DataSetRemoved(const ADataSet: TComponent);
begin
  FServerQueries.Remove(TDataSet(ADataSet));
end;

procedure TDatabaseGridDACDataSetFeatures.OpenQuery(const ADataSet: TCustomDADataSet; const AQuery: TDatabaseGridServerQuery;
  const AClearIndexFieldNames: Boolean);
var
  LQuery: TDatabaseGridServerQuery;
  LSQL: string;
begin
  if not TryBuildSQL(ADataSet, AQuery, LSQL) then
    LSQL := AQuery.OriginalSQL;

  ADataSet.SQL.Text := LSQL;

  if AClearIndexFieldNames then
    ADataSet.IndexFieldNames := '';

  if AQuery.OrderBy.IsEmpty and AQuery.SearchCondition.IsEmpty and (Length(AQuery.ColumnConditions) = 0) then
    FServerQueries.Remove(ADataSet)
  else
  begin
    LQuery := AQuery;
    LQuery.ModifiedSQL := ADataSet.SQL.Text;

    FServerQueries.AddOrSetValue(ADataSet, LQuery);
    ADataSet.FreeNotification(FDataSetNotifier);
  end;

  ADataSet.Open;
end;

procedure TDatabaseGridDACDataSetFeatures.SortLocally(const ADataSet: TDataSet; const ASortFields: TArray<TDatabaseGridSortField>);
var
  LField: TField;
  LIndexFieldNames: string;
begin
  LIndexFieldNames := '';

  for var LIndex := 0 to High(ASortFields) do
  begin
    LField := ADataSet.FindField(ASortFields[LIndex].FieldName);

    if not Assigned(LField) then
      Continue;

    if not LIndexFieldNames.IsEmpty then
      LIndexFieldNames := LIndexFieldNames + ';';

    LIndexFieldNames := LIndexFieldNames + LField.FieldName;

    if ASortFields[LIndex].Descending then
      LIndexFieldNames := LIndexFieldNames + ' DESC';

    if LField.DataType in [ftString, ftFixedChar, ftWideString, ftFixedWideChar, ftMemo, ftWideMemo] then
      LIndexFieldNames := LIndexFieldNames + ' CIS';
  end;

  TMemDataSet(ADataSet).IndexFieldNames := LIndexFieldNames;
end;

function TDatabaseGridDACDataSetFeatures.TryGetColumnFilterCondition(const ADataSet: TCustomDADataSet;
  const AFilter: TDatabaseGridFieldFilter; out ACondition: string): Boolean;
begin
  ACondition := '';

  Result := False;
end;

function TDatabaseGridDACDataSetFeatures.TryGetFieldColumn(const ADataSet: TCustomDADataSet; const AField: TField; out ATableName,
  AColumnName: string): Boolean;
var
  LFieldDesc: TFieldDesc;
  LTableInfo: TCRTableInfo;
begin
  ATableName := '';
  AColumnName := '';

  if (AField.FieldKind <> fkData) or Assigned(AField.ParentField) then
    Exit(False);

  LFieldDesc := ADataSet.GetFieldDesc(AField);

  if not (LFieldDesc is TCRFieldDesc) then
    Exit(False);

  LTableInfo := TCRFieldDesc(LFieldDesc).TableInfo;

  if not Assigned(LTableInfo) or LTableInfo.TableName.IsEmpty or LFieldDesc.ActualName.IsEmpty then
    Exit(False);

  ATableName := LTableInfo.TableAlias;

  if ATableName.IsEmpty then
    ATableName := LTableInfo.TableName;

  AColumnName := LFieldDesc.ActualName;

  Result := True;
end;

function TDatabaseGridDACDataSetFeatures.TryGetSearchCondition(const ADataSet: TCustomDADataSet; const AWords: TArray<string>;
  const AFields: TArray<TField>; out ACondition: string): Boolean;
begin
  ACondition := '';

  Result := False;
end;

function TDatabaseGridDACDataSetFeatures.ApplyFilters(const ADataSet: TDataSet; const ASearchText: string;
  const ASearchFields: TArray<TField>; const AColumnFilters: TArray<TDatabaseGridFieldFilter>; const ACanReopen: Boolean;
  out AAppliedParts: TDatabaseGridFilterParts): Boolean;
var
  LDataSet: TCustomDADataSet;
  LFallbackQuery, LNewQuery, LQuery: TDatabaseGridServerQuery;
  LStored: Boolean;
  LWords: TArray<string>;
begin
  AAppliedParts := [];
  Result := True;

  if not (ADataSet is TCustomDADataSet) then
    Exit;

  LDataSet := TCustomDADataSet(ADataSet);

  if ACanReopen then
    LDataSet.CheckBrowseMode;

  LStored := TryGetServerQuery(LDataSet, LQuery);

  LNewQuery := LQuery;
  LNewQuery.SearchCondition := '';
  LNewQuery.ColumnConditions := nil;

  if CanFilterOnServer(LDataSet, LQuery, LStored) then
  begin
    LWords := ASearchText.Split([' '], TStringSplitOptions.ExcludeEmpty);

    if (Length(LWords) > 0) and TryGetSearchCondition(LDataSet, LWords, ASearchFields, LNewQuery.SearchCondition) then
      Include(AAppliedParts, fpSearch)
    else
      LNewQuery.SearchCondition := '';

    if (Length(AColumnFilters) > 0) and TryGetColumnConditions(LDataSet, AColumnFilters, LNewQuery.ColumnConditions) then
      Include(AAppliedParts, fpColumnFilters);
  end;

  if (LNewQuery.SearchCondition = LQuery.SearchCondition) and SameServerConditions(LNewQuery.ColumnConditions, LQuery.ColumnConditions) then
    Exit;

  if not ACanReopen then
  begin
    AAppliedParts := [];

    Exit(False);
  end;

  LFallbackQuery := LQuery;
  LFallbackQuery.SearchCondition := '';
  LFallbackQuery.ColumnConditions := nil;

  if not ReopenWithQuery(LDataSet, LNewQuery, LFallbackQuery, False) then
    AAppliedParts := [];
end;

function TDatabaseGridDACDataSetFeatures.ApplySorting(const ADataSet: TDataSet; const ASortFields: TArray<TDatabaseGridSortField>;
  const ACanReopen: Boolean): Boolean;
var
  LDataSet: TCustomDADataSet;
  LNewQuery, LQuery: TDatabaseGridServerQuery;
  LOrderBy, LSQL: string;
  LStored: Boolean;
begin
  Result := True;

  if not (ADataSet is TCustomDADataSet) then
  begin
    SortLocally(ADataSet, ASortFields);

    Exit;
  end;

  LDataSet := TCustomDADataSet(ADataSet);

  if ACanReopen then
    LDataSet.CheckBrowseMode;

  LStored := TryGetServerQuery(LDataSet, LQuery);

  if not CanUseServer(LDataSet, LStored) or not TryGetOrderBy(LDataSet, ASortFields, LOrderBy) then
  begin
    SortLocally(LDataSet, ASortFields);

    Exit;
  end;

  if LQuery.OrderBy = LOrderBy then
  begin
    LDataSet.IndexFieldNames := '';

    Exit;
  end;

  LNewQuery := LQuery;
  LNewQuery.OrderBy := LOrderBy;

  if not TryBuildSQL(LDataSet, LNewQuery, LSQL) then
  begin
    SortLocally(LDataSet, ASortFields);

    Exit;
  end;

  if not ACanReopen then
    Exit(False);

  if not ReopenWithQuery(LDataSet, LNewQuery, LQuery, True) then
    SortLocally(LDataSet, ASortFields);
end;

function TDatabaseGridDACDataSetFeatures.GetColumnValues(const ADataSet: TDataSet; const AField: TField;
  const AValues: TStrings; const ALimit: Integer): Boolean;
var
  LDataSet: TCustomDADataSet;
  LField: TField;
  LQuery: TCustomDADataSet;
begin
  if not (ADataSet is TCustomDADataSet) or (AField.FieldKind <> fkData) then
    Exit(False);

  LDataSet := TCustomDADataSet(ADataSet);

  if not Assigned(LDataSet.Connection) or (Trim(LDataSet.SQL.Text) = '') then
    Exit(False);

  LQuery := TCustomDADataSetClass(LDataSet.ClassType).Create(nil);
  try
    LQuery.Connection := LDataSet.Connection;
    LQuery.SQL.Text := 'SELECT DISTINCT ' + AField.FieldName + ' FROM (' + GetQuerySQL(LDataSet, AField.FieldName) + ') ' +
      sLineBreak + 'ORDER BY 1';
    LQuery.Params.Assign(LDataSet.Params);
    LQuery.UniDirectional := True;
    LQuery.Open;

    LField := LQuery.FieldByName(AField.FieldName);

    if (AField is TNumericField) and (LField is TNumericField) then
      TNumericField(LField).DisplayFormat := TNumericField(AField).DisplayFormat
    else
    if (AField is TDateTimeField) and (LField is TDateTimeField) then
      TDateTimeField(LField).DisplayFormat := TDateTimeField(AField).DisplayFormat;

    while not LQuery.Eof and ((ALimit = 0) or (AValues.Count < ALimit)) do
    begin
      AValues.Add(LField.DisplayText);

      LQuery.Next;
    end;
  finally
    LQuery.Free;
  end;

  Result := True;
end;

function TDatabaseGridDACDataSetFeatures.GetFooterValues(const ADataSet: TDataSet;
  var AValues: TArray<TDatabaseGridFooterValue>): Boolean;
var
  LColumns: string;
  LDataSet: TCustomDADataSet;
  LField: TField;
  LFieldIndex: Integer;
  LQuery: TCustomDADataSet;
  LValueCount: Int64;
begin
  if not (ADataSet is TCustomDADataSet) then
    Exit(False);

  LDataSet := TCustomDADataSet(ADataSet);

  if not Assigned(LDataSet.Connection) or (Trim(LDataSet.SQL.Text) = '') then
    Exit(False);

  LColumns := 'COUNT(*)';

  for var LIndex := 0 to High(AValues) do
  if AValues[LIndex].ValueType in [fvSum, fvAverage] then
  begin
    LField := AValues[LIndex].Field;

    if Assigned(LField) and (LField.FieldKind <> fkData) then
      Exit(False);

    if LField is TNumericField then
      LColumns := LColumns + ', SUM(' + LField.FieldName + '), COUNT(' + LField.FieldName + ')';
  end;

  LQuery := TCustomDADataSetClass(LDataSet.ClassType).Create(nil);
  try
    LQuery.Connection := LDataSet.Connection;
    LQuery.SQL.Text := 'SELECT ' + LColumns + ' FROM (' + GetQuerySQL(LDataSet, '') + ')';
    LQuery.Params.Assign(LDataSet.Params);
    LQuery.UniDirectional := True;
    LQuery.Open;

    LFieldIndex := 1;

    for var LIndex := 0 to High(AValues) do
    begin
      if AValues[LIndex].ValueType = fvCount then
        AValues[LIndex].Value := LQuery.Fields[0].Value
      else
      if AValues[LIndex].Field is TNumericField then
      begin
        LValueCount := LQuery.Fields[LFieldIndex + 1].AsLargeInt;

        if LValueCount = 0 then
        begin
          if AValues[LIndex].ValueType = fvSum then
            AValues[LIndex].Value := 0
          else
            AValues[LIndex].Value := Null;
        end
        else
        if AValues[LIndex].ValueType = fvSum then
          AValues[LIndex].Value := LQuery.Fields[LFieldIndex].Value
        else
          AValues[LIndex].Value := LQuery.Fields[LFieldIndex].Value / LValueCount;

        Inc(LFieldIndex, 2);
      end;
    end;
  finally
    LQuery.Free;
  end;

  Result := True;
end;

function TDatabaseGridDACDataSetFeatures.IsFiltered(const ADataSet: TDataSet): Boolean;
var
  LQuery: TDatabaseGridServerQuery;
begin
  Result := (ADataSet is TCustomDADataSet) and TryGetServerQuery(TCustomDADataSet(ADataSet), LQuery) and
    (not LQuery.SearchCondition.IsEmpty or (Length(LQuery.ColumnConditions) > 0));
end;

initialization

  RegisterDatabaseGridDataSetFeatures(TMemDataSet, TDatabaseGridDACDataSetFeatures);

finalization

  UnregisterDatabaseGridDataSetFeatures(TMemDataSet);

end.
