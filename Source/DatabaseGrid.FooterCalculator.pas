unit DatabaseGrid.FooterCalculator;

interface

uses
  Data.DB, Data.FmtBcd, DatabaseGrid.Columns, DatabaseGrid.DataLink, DatabaseGrid.DataSetFeatures, DatabaseGrid.FilterController,
  DatabaseGrid.Types;

type
  TDatabaseGridFooterCalculator = class(TObject)
  strict private type
    TDatabaseGridFooterSumKind = (skNone, skInteger, skCurrency, skBcd, skFloat);

    TDatabaseGridFooterSum = record
      BcdSum: TBcd;
      CurrencySum: Currency;
      FloatSum: Double;
      IntegerSum: Int64;
      Kind: TDatabaseGridFooterSumKind;
      ValueCount: Integer;
    end;
  strict private
    FCalculating: Boolean;
    FColumns: TDatabaseGridColumns;
    FDataLink: TDatabaseGridDataLink;
    FFilterController: TDatabaseGridFilterController;
    FPending: Boolean;
    FValues: TArray<TDatabaseGridFooterValue>;
    function GetRequestedValues: TArray<TDatabaseGridFooterValue>;
    function IsRequestChanged(const AValues: TArray<TDatabaseGridFooterValue>): Boolean;
    procedure ReadRows(var AValues: TArray<TDatabaseGridFooterValue>; const AReadAllRows: Boolean);
    procedure UpdateColumns;
  public
    constructor Create(const AColumns: TDatabaseGridColumns; const ADataLink: TDatabaseGridDataLink; const AFilterController: TDatabaseGridFilterController);
    function ColumnsChanged: Boolean;
    function Invalidate: Boolean;
    procedure Calculate;
    property Calculating: Boolean read FCalculating;
    property Pending: Boolean read FPending;
  end;

implementation

uses
  System.Classes, System.Variants;

constructor TDatabaseGridFooterCalculator.Create(const AColumns: TDatabaseGridColumns; const ADataLink: TDatabaseGridDataLink;
  const AFilterController: TDatabaseGridFilterController);
begin
  inherited Create;

  FColumns := AColumns;
  FDataLink := ADataLink;
  FFilterController := AFilterController;
end;

procedure TDatabaseGridFooterCalculator.Calculate;
var
  LDataSet: TDataSet;
  LFeatures: TDatabaseGridDataSetFeatures;
  LValues: TArray<TDatabaseGridFooterValue>;
begin
  FPending := False;
  LValues := GetRequestedValues;

  if Length(LValues) > 0 then
  begin
    if not FDataLink.Active then
    begin
      FValues := LValues;

      UpdateColumns;

      Exit;
    end;

    LDataSet := FDataLink.DataSet;

    if (LDataSet.State <> dsBrowse) or LDataSet.ControlsDisabled then
      Exit;

    FCalculating := True;
    try
      if FDataLink.HasAllRows then
        ReadRows(LValues, False)
      else
      begin
        LFeatures := nil;

        if not FFilterController.HasLocalFilters(LDataSet) then
          LFeatures := FindDatabaseGridDataSetFeatures(LDataSet);

        if not Assigned(LFeatures) or not LFeatures.GetFooterValues(LDataSet, LValues) then
        begin
          if LDataSet.IsUniDirectional then
            Exit;

          ReadRows(LValues, True);
        end;
      end;
    finally
      FCalculating := False;
    end;
  end;

  FValues := LValues;

  UpdateColumns;
end;

function TDatabaseGridFooterCalculator.ColumnsChanged: Boolean;
begin
  if IsRequestChanged(GetRequestedValues) then
    Result := Invalidate
  else
    Result := False;
end;

function TDatabaseGridFooterCalculator.GetRequestedValues: TArray<TDatabaseGridFooterValue>;
var
  LColumn: TDatabaseGridColumn;
  LValue: TDatabaseGridFooterValue;
begin
  Result := nil;

  for var LIndex := 0 to FColumns.Count - 1 do
  begin
    LColumn := FColumns[LIndex];

    if LColumn.Footer.ValueType = fvNone then
      Continue;

    LValue.ValueType := LColumn.Footer.ValueType;
    LValue.Value := Null;

    if LValue.ValueType = fvCount then
      LValue.Field := nil
    else
      LValue.Field := LColumn.Footer.Field;

    Result := Result + [LValue];
  end;
end;

function TDatabaseGridFooterCalculator.Invalidate: Boolean;
begin
  if FCalculating then
    Exit(False);

  Result := not FPending;

  FPending := True;
end;

function TDatabaseGridFooterCalculator.IsRequestChanged(const AValues: TArray<TDatabaseGridFooterValue>): Boolean;
begin
  if Length(AValues) <> Length(FValues) then
    Exit(True);

  for var LIndex := 0 to High(AValues) do
  if (AValues[LIndex].Field <> FValues[LIndex].Field) or (AValues[LIndex].ValueType <> FValues[LIndex].ValueType) then
    Exit(True);

  Result := False;
end;

procedure TDatabaseGridFooterCalculator.ReadRows(var AValues: TArray<TDatabaseGridFooterValue>; const AReadAllRows: Boolean);
var
  LActiveRecord: Integer;
  LBookmark: TBookmark;
  LDataSet: TDataSet;
  LField: TField;
  LRowCount: Integer;
  LSums: TArray<TDatabaseGridFooterSum>;

  procedure AddRow;
  var
    LBcd: TBcd;
  begin
    Inc(LRowCount);

    for var LIndex := 0 to High(AValues) do
    begin
      LField := AValues[LIndex].Field;

      if (LSums[LIndex].Kind = skNone) or LField.IsNull then
        Continue;

      Inc(LSums[LIndex].ValueCount);

      case LSums[LIndex].Kind of
        skInteger:
          Inc(LSums[LIndex].IntegerSum, LField.AsLargeInt);
        skCurrency:
          LSums[LIndex].CurrencySum := LSums[LIndex].CurrencySum + LField.AsCurrency;
        skBcd:
          begin
            BcdAdd(LSums[LIndex].BcdSum, LField.AsBCD, LBcd);
            LSums[LIndex].BcdSum := LBcd;
          end;
        skFloat:
          LSums[LIndex].FloatSum := LSums[LIndex].FloatSum + LField.AsFloat;
      end;
    end;
  end;

begin
  LDataSet := FDataLink.DataSet;
  LRowCount := 0;
  SetLength(LSums, Length(AValues));

  for var LIndex := 0 to High(AValues) do
  begin
    LSums[LIndex] := Default(TDatabaseGridFooterSum);
    LField := AValues[LIndex].Field;

    if (AValues[LIndex].ValueType = fvCount) or not (LField is TNumericField) then
      Continue;

    case LField.DataType of
      ftSmallint, ftInteger, ftWord, ftAutoInc, ftLargeint, ftLongWord, ftShortint, ftByte:
        LSums[LIndex].Kind := skInteger;
      ftBCD, ftCurrency:
        LSums[LIndex].Kind := skCurrency;
      ftFMTBcd:
        begin
          LSums[LIndex].Kind := skBcd;
          LSums[LIndex].BcdSum := IntegerToBcd(0);
        end;
    else
      LSums[LIndex].Kind := skFloat;
    end;
  end;

  if AReadAllRows then
  begin
    LDataSet.DisableControls;
    try
      LBookmark := LDataSet.Bookmark;
      try
        LDataSet.First;

        while not LDataSet.Eof do
        begin
          AddRow;

          LDataSet.Next;
        end;
      finally
        if LDataSet.BookmarkValid(LBookmark) then
          LDataSet.Bookmark := LBookmark;
      end;
    finally
      LDataSet.EnableControls;
    end;
  end
  else
  begin
    LActiveRecord := FDataLink.ActiveRecord;
    try
      for var LRecordIndex := 0 to FDataLink.RecordCount - 1 do
      begin
        FDataLink.ActiveRecord := LRecordIndex;

        AddRow;
      end;
    finally
      FDataLink.ActiveRecord := LActiveRecord;
    end;
  end;

  for var LIndex := 0 to High(AValues) do
  begin
    if AValues[LIndex].ValueType = fvCount then
    begin
      AValues[LIndex].Value := LRowCount;

      Continue;
    end;

    case LSums[LIndex].Kind of
      skInteger:
        AValues[LIndex].Value := LSums[LIndex].IntegerSum;
      skCurrency:
        AValues[LIndex].Value := LSums[LIndex].CurrencySum;
      skBcd:
        AValues[LIndex].Value := VarFMTBcdCreate(LSums[LIndex].BcdSum);
      skFloat:
        AValues[LIndex].Value := LSums[LIndex].FloatSum;
    else
      Continue;
    end;

    if AValues[LIndex].ValueType = fvAverage then
    begin
      if LSums[LIndex].ValueCount = 0 then
        AValues[LIndex].Value := Null
      else
        AValues[LIndex].Value := AValues[LIndex].Value / LSums[LIndex].ValueCount;
    end;
  end;
end;

procedure TDatabaseGridFooterCalculator.UpdateColumns;
var
  LColumn: TDatabaseGridColumn;
  LValueIndex: Integer;
begin
  LValueIndex := 0;

  for var LIndex := 0 to FColumns.Count - 1 do
  begin
    LColumn := FColumns[LIndex];

    if LColumn.Footer.ValueType = fvNone then
      Continue;

    if LValueIndex <= High(FValues) then
      LColumn.Footer.Value := FValues[LValueIndex].Value
    else
      LColumn.Footer.Value := Null;

    Inc(LValueIndex);
  end;
end;

end.
