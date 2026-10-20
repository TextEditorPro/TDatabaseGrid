unit DatabaseGrid.FilterController;

interface

uses
  System.Classes, Data.DB, DatabaseGrid.Columns, DatabaseGrid.DataSetFeatures;

type
  TDatabaseGridFilterController = class(TComponent)
  strict private type
    TDatabaseGridFilterState = record
      DataSet: TDataSet;
      LocalColumnFilters: Boolean;
      PreviousFilter: string;
      PreviousFiltered: Boolean;
      PreviousOnFilterRecord: TFilterRecordEvent;
      Text: string;
      Words: TArray<string>;
    end;
  strict private
    FColumns: TDatabaseGridColumns;
    FServerDataSet: TDataSet;
    FServerParts: TDatabaseGridFilterParts;
    FState: TDatabaseGridFilterState;
    FValuesColumn: TDatabaseGridColumn;
    function GetColumnField(const ADataSet: TDataSet; const AColumn: TDatabaseGridColumn): TField;
    function GetDataSet: TDataSet;
    function GetFieldFilters: TArray<TDatabaseGridFieldFilter>;
    function GetSearchFields: TArray<TField>;
    function HasColumnFilters: Boolean;
    function HasOtherFilters(const ADataSet: TDataSet; const AColumn: TDatabaseGridColumn): Boolean;
    function IsColumnFilterMatch(const ADataSet: TDataSet): Boolean;
    function IsSearchFilterMatch(const ADataSet: TDataSet): Boolean;
    procedure FilterRecord(ADataSet: TDataSet; var AAccept: Boolean);
    procedure ReadColumnValues(const ADataSet: TDataSet; const AColumn: TDatabaseGridColumn; const AValues: TStrings; const ALimit: Integer);
    procedure RemoveLocalFilter;
    procedure RemoveServerFilter;
    procedure SetServerDataSet(const AValue: TDataSet);
  protected
    procedure Notification(AComponent: TComponent; AOperation: TOperation); override;
  public
    constructor Create(const AColumns: TDatabaseGridColumns); reintroduce;
    destructor Destroy; override;
    function Apply(const ADataSet: TDataSet; const AText: string; const ACanReopen: Boolean = True): Boolean;
    function HasLocalFilters(const ADataSet: TDataSet): Boolean;
    function NeedsReapply(const ADataSet: TDataSet): Boolean;
    procedure GetColumnValues(const ADataSet: TDataSet; const AColumn: TDatabaseGridColumn; const AValues: TStrings; const ALimit: Integer);
    procedure Remove;
    property DataSet: TDataSet read GetDataSet;
    property Text: string read FState.Text;
  end;

implementation

uses
  System.Generics.Collections, System.SysUtils, DatabaseGrid.FieldValues;

constructor TDatabaseGridFilterController.Create(const AColumns: TDatabaseGridColumns);
begin
  inherited Create(nil);

  FColumns := AColumns;
end;

destructor TDatabaseGridFilterController.Destroy;
begin
  Remove;

  inherited Destroy;
end;

function TDatabaseGridFilterController.GetColumnField(const ADataSet: TDataSet; const AColumn: TDatabaseGridColumn): TField;
begin
  Result := AColumn.Field;

  if not Assigned(Result) or (Result.DataSet <> ADataSet) then
    Result := ADataSet.FindField(AColumn.FieldName);
end;

function TDatabaseGridFilterController.GetDataSet: TDataSet;
begin
  Result := FState.DataSet;

  if not Assigned(Result) then
    Result := FServerDataSet;
end;

function TDatabaseGridFilterController.GetFieldFilters: TArray<TDatabaseGridFieldFilter>;
var
  LColumn: TDatabaseGridColumn;
  LFieldFilter: TDatabaseGridFieldFilter;
begin
  Result := nil;

  for var LIndex := 0 to FColumns.Count - 1 do
  begin
    LColumn := FColumns[LIndex];

    if not LColumn.Filter.Active or not Assigned(LColumn.Field) then
      Continue;

    LFieldFilter.Field := LColumn.Field;
    LFieldFilter.Operator := LColumn.Filter.Operator;
    LFieldFilter.Value := LColumn.Filter.Value;
    LFieldFilter.Value2 := LColumn.Filter.Value2;
    LFieldFilter.Values := LColumn.Filter.Values.ToStringArray;

    Result := Result + [LFieldFilter];
  end;
end;

function TDatabaseGridFilterController.GetSearchFields: TArray<TField>;
begin
  Result := nil;

  for var LIndex := 0 to FColumns.Count - 1 do
  if FColumns[LIndex].Visible and Assigned(FColumns[LIndex].Field) then
    Result := Result + [FColumns[LIndex].Field];
end;

function TDatabaseGridFilterController.HasColumnFilters: Boolean;
begin
  for var LIndex := 0 to FColumns.Count - 1 do
  if FColumns[LIndex].Filter.Active then
    Exit(True);

  Result := False;
end;

function TDatabaseGridFilterController.HasOtherFilters(const ADataSet: TDataSet; const AColumn: TDatabaseGridColumn): Boolean;
begin
  if not ADataSet.Filtered then
    Exit(False);

  if (FState.DataSet <> ADataSet) or (Length(FState.Words) > 0) or FState.PreviousFiltered or
    Assigned(FState.PreviousOnFilterRecord) then
    Exit(True);

  if FState.LocalColumnFilters then
  for var LIndex := 0 to FColumns.Count - 1 do
  if (FColumns[LIndex] <> AColumn) and FColumns[LIndex].Filter.Active and Assigned(FColumns[LIndex].Field) then
    Exit(True);

  Result := False;
end;

function TDatabaseGridFilterController.HasLocalFilters(const ADataSet: TDataSet): Boolean;
begin
  Result := HasOtherFilters(ADataSet, nil);
end;

function TDatabaseGridFilterController.NeedsReapply(const ADataSet: TDataSet): Boolean;
var
  LFeatures: TDatabaseGridDataSetFeatures;
begin
  if (FServerParts = []) or (FServerDataSet <> ADataSet) then
    Exit(False);

  LFeatures := FindDatabaseGridDataSetFeatures(ADataSet);

  Result := Assigned(LFeatures) and not LFeatures.IsFiltered(ADataSet);
end;

function TDatabaseGridFilterController.IsColumnFilterMatch(const ADataSet: TDataSet): Boolean;
var
  LColumn: TDatabaseGridColumn;
  LField: TField;
begin
  for var LIndex := 0 to FColumns.Count - 1 do
  begin
    LColumn := FColumns[LIndex];

    if not LColumn.Filter.Active or (LColumn = FValuesColumn) then
      Continue;

    LField := GetColumnField(ADataSet, LColumn);

    if Assigned(LField) and not LColumn.Filter.Matches(LField) then
      Exit(False);
  end;

  Result := True;
end;

function TDatabaseGridFilterController.IsSearchFilterMatch(const ADataSet: TDataSet): Boolean;
var
  LColumn: TDatabaseGridColumn;
  LField: TField;
  LText: string;
  LWordCount: Integer;
  LWordFound: TArray<Boolean>;
begin
  LWordCount := Length(FState.Words);

  if LWordCount = 0 then
    Exit(True);

  SetLength(LWordFound, LWordCount);

  for var LIndex := 0 to FColumns.Count - 1 do
  begin
    LColumn := FColumns[LIndex];

    if not LColumn.Visible then
      Continue;

    LField := GetColumnField(ADataSet, LColumn);

    if not Assigned(LField) then
      Continue;

    LText := AnsiUpperCase(GetFieldDisplayText(LField));

    if LText.IsEmpty then
      Continue;

    for var LWordIndex := 0 to High(LWordFound) do
    if not LWordFound[LWordIndex] and LText.Contains(FState.Words[LWordIndex]) then
    begin
      LWordFound[LWordIndex] := True;

      Dec(LWordCount);
    end;

    if LWordCount = 0 then
      Exit(True);
  end;

  Result := False;
end;

function TDatabaseGridFilterController.Apply(const ADataSet: TDataSet; const AText: string; const ACanReopen: Boolean = True): Boolean;
var
  LAppliedParts: TDatabaseGridFilterParts;
  LFeatures: TDatabaseGridDataSetFeatures;
  LLocalColumnFilters: Boolean;
  LLocalText: string;
begin
  if Assigned(FServerDataSet) and (FServerDataSet <> ADataSet) then
    RemoveServerFilter;

  LFeatures := FindDatabaseGridDataSetFeatures(ADataSet);
  LLocalText := AText;
  LLocalColumnFilters := HasColumnFilters;
  LAppliedParts := [];

  if Assigned(LFeatures) then
  begin
    if not LFeatures.ApplyFilters(ADataSet, AText, GetSearchFields, GetFieldFilters, ACanReopen, LAppliedParts) then
      Exit(False);

    if fpSearch in LAppliedParts then
      LLocalText := '';

    if fpColumnFilters in LAppliedParts then
      LLocalColumnFilters := False;
  end;

  if LAppliedParts = [] then
    SetServerDataSet(nil)
  else
    SetServerDataSet(ADataSet);

  FServerParts := LAppliedParts;

  Result := True;

  if LLocalText.IsEmpty and not LLocalColumnFilters then
  begin
    RemoveLocalFilter;

    FState.Text := AText;

    Exit;
  end;

  ADataSet.DisableControls;
  try
    if FState.DataSet <> ADataSet then
    begin
      RemoveLocalFilter;

      FState.DataSet := ADataSet;
      FState.PreviousFilter := ADataSet.Filter;
      FState.PreviousFiltered := ADataSet.Filtered;
      FState.PreviousOnFilterRecord := ADataSet.OnFilterRecord;

      ADataSet.FreeNotification(Self);
      ADataSet.OnFilterRecord := FilterRecord;
    end;

    FState.LocalColumnFilters := LLocalColumnFilters;
    FState.Text := AText;
    FState.Words := AnsiUpperCase(LLocalText).Split([' '], TStringSplitOptions.ExcludeEmpty);

    ADataSet.Filtered := False;
    ADataSet.Filtered := True;
  finally
    ADataSet.EnableControls;
  end;
end;

procedure TDatabaseGridFilterController.FilterRecord(ADataSet: TDataSet; var AAccept: Boolean);
begin
  if Assigned(FState.PreviousOnFilterRecord) then
  begin
    FState.PreviousOnFilterRecord(ADataSet, AAccept);

    if not AAccept then
      Exit;
  end;

  AAccept := IsSearchFilterMatch(ADataSet) and (not FState.LocalColumnFilters or IsColumnFilterMatch(ADataSet));
end;

procedure TDatabaseGridFilterController.GetColumnValues(const ADataSet: TDataSet; const AColumn: TDatabaseGridColumn;
  const AValues: TStrings; const ALimit: Integer);
var
  LFeatures: TDatabaseGridDataSetFeatures;
begin
  if not Assigned(ADataSet) or not Assigned(AColumn.Field) then
    Exit;

  LFeatures := nil;

  if not HasOtherFilters(ADataSet, AColumn) then
    LFeatures := FindDatabaseGridDataSetFeatures(ADataSet);

  if not Assigned(LFeatures) or not LFeatures.GetColumnValues(ADataSet, AColumn.Field, AValues, ALimit) then
    ReadColumnValues(ADataSet, AColumn, AValues, ALimit);
end;

procedure TDatabaseGridFilterController.Notification(AComponent: TComponent; AOperation: TOperation);
begin
  inherited Notification(AComponent, AOperation);

  if AOperation <> opRemove then
    Exit;

  if AComponent = FState.DataSet then
    FState.DataSet := nil;

  if AComponent = FServerDataSet then
  begin
    FServerDataSet := nil;
    FServerParts := [];
  end;
end;

procedure TDatabaseGridFilterController.ReadColumnValues(const ADataSet: TDataSet; const AColumn: TDatabaseGridColumn;
  const AValues: TStrings; const ALimit: Integer);
var
  LBookmark: TBookmark;
  LSeen: TDictionary<string, Boolean>;
  LText: string;
begin
  LSeen := TDictionary<string, Boolean>.Create;
  ADataSet.DisableControls;
  try
    LBookmark := ADataSet.Bookmark;
    FValuesColumn := AColumn;
    try
      if AColumn.Filter.Active and ADataSet.Filtered then
      begin
        ADataSet.Filtered := False;
        ADataSet.Filtered := True;
      end;

      ADataSet.First;

      while not ADataSet.Eof and ((ALimit = 0) or (AValues.Count < ALimit)) do
      begin
        LText := AColumn.Field.DisplayText;

        if LSeen.TryAdd(AnsiUpperCase(LText), True) then
          AValues.Add(LText);

        ADataSet.Next;
      end;
    finally
      FValuesColumn := nil;

      if ADataSet.Filtered then
      begin
        ADataSet.Filtered := False;
        ADataSet.Filtered := True;
      end;

      if ADataSet.BookmarkValid(LBookmark) then
        ADataSet.Bookmark := LBookmark;
    end;
  finally
    ADataSet.EnableControls;
    LSeen.Free;
  end;

  if AValues is TStringList then
    TStringList(AValues).Sort;
end;

procedure TDatabaseGridFilterController.Remove;
begin
  RemoveLocalFilter;
  RemoveServerFilter;
end;

procedure TDatabaseGridFilterController.RemoveLocalFilter;
var
  LDataSet: TDataSet;
  LFilterRecord, LOwnFilterRecord: TFilterRecordEvent;
  LState: TDatabaseGridFilterState;
begin
  LState := FState;
  FState := Default(TDatabaseGridFilterState);

  LDataSet := LState.DataSet;

  if not Assigned(LDataSet) then
    Exit;

  if LDataSet <> FServerDataSet then
    LDataSet.RemoveFreeNotification(Self);

  LFilterRecord := LDataSet.OnFilterRecord;
  LOwnFilterRecord := FilterRecord;

  if (csDestroying in LDataSet.ComponentState) or (TMethod(LFilterRecord) <> TMethod(LOwnFilterRecord)) then
    Exit;

  LDataSet.DisableControls;
  try
    LDataSet.OnFilterRecord := LState.PreviousOnFilterRecord;
    LDataSet.Filtered := False;

    if LDataSet.Filter = LState.PreviousFilter then
      LDataSet.Filtered := LState.PreviousFiltered
    else
      LDataSet.Filtered := not LDataSet.Filter.IsEmpty or LState.PreviousFiltered and Assigned(LState.PreviousOnFilterRecord);
  finally
    LDataSet.EnableControls;
  end;
end;

procedure TDatabaseGridFilterController.RemoveServerFilter;
var
  LAppliedParts: TDatabaseGridFilterParts;
  LDataSet: TDataSet;
  LFeatures: TDatabaseGridDataSetFeatures;
begin
  LDataSet := FServerDataSet;

  SetServerDataSet(nil);
  FServerParts := [];

  if not Assigned(LDataSet) or (csDestroying in LDataSet.ComponentState) or not LDataSet.Active then
    Exit;

  LFeatures := FindDatabaseGridDataSetFeatures(LDataSet);

  if Assigned(LFeatures) then
    LFeatures.ApplyFilters(LDataSet, '', nil, nil, True, LAppliedParts);
end;

procedure TDatabaseGridFilterController.SetServerDataSet(const AValue: TDataSet);
begin
  if FServerDataSet = AValue then
    Exit;

  if Assigned(FServerDataSet) and (FServerDataSet <> FState.DataSet) then
    FServerDataSet.RemoveFreeNotification(Self);

  FServerDataSet := AValue;

  if Assigned(FServerDataSet) then
    FServerDataSet.FreeNotification(Self);
end;

end.
