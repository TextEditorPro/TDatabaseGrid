unit DatabaseGrid.DataSetFeatures.IBDAC;

interface

uses
  Data.DB, DBAccess, DatabaseGrid.DataSetFeatures, DatabaseGrid.DataSetFeatures.DAC;

type
  TDatabaseGridIBDACDataSetFeatures = class(TDatabaseGridDACDataSetFeatures)
  strict private
    function TryGetColumnReference(const ADataSet: TCustomDADataSet; const AField: TField; out AReference: string): Boolean;
    function TryGetValuesCondition(const AField: TField; const AReference: string; const AValues: TArray<string>;
      out ACondition: string): Boolean;
  protected
    function TryGetColumnFilterCondition(const ADataSet: TCustomDADataSet; const AFilter: TDatabaseGridFieldFilter;
      out ACondition: string): Boolean; override;
    function TryGetSearchCondition(const ADataSet: TCustomDADataSet; const AWords: TArray<string>; const AFields: TArray<TField>;
      out ACondition: string): Boolean; override;
  end;

implementation

uses
  System.DateUtils, System.Math, System.SysUtils, Data.SqlTimSt, IBC, DatabaseGrid.Types;

type
  TDatabaseGridSQLValueKind = (vkNone, vkString, vkInteger, vkNumber, vkDate, vkTime, vkDateTime);

const
  IN_LIST_MAX_COUNT = 1000;

function GetDateTimeDisplayFormat(const AField: TField): string;
begin
  if AField is TDateTimeField then
    Result := TDateTimeField(AField).DisplayFormat
  else
  if AField is TSQLTimeStampField then
    Result := TSQLTimeStampField(AField).DisplayFormat
  else
    Result := '';
end;

function GetNumberDisplayFormat(const AField: TField): string;
begin
  if AField is TNumericField then
    Result := TNumericField(AField).DisplayFormat
  else
    Result := '';
end;

function GetSQLValueKind(const AField: TField): TDatabaseGridSQLValueKind;
begin
  case AField.DataType of
    ftString, ftWideString, ftFixedChar, ftFixedWideChar, ftGuid:
      Result := vkString;
    ftSmallint, ftInteger, ftWord, ftAutoInc, ftLargeint, ftLongWord, ftShortint, ftByte:
      Result := vkInteger;
    ftFloat, ftCurrency, ftBCD, ftFMTBcd, ftExtended, ftSingle:
      Result := vkNumber;
    ftDate:
      Result := vkDate;
    ftTime:
      Result := vkTime;
    ftDateTime, ftTimeStamp:
      Result := vkDateTime;
  else
    Result := vkNone;
  end;
end;

function GetDateTimeLiteral(const AKind: TDatabaseGridSQLValueKind; const AValue: TDateTime): string;
begin
  case AKind of
    vkDate:
      Result := 'DATE ''' + FormatDateTime('yyyy-mm-dd', AValue, TFormatSettings.Invariant) + '''';
    vkTime:
      Result := 'TIME ''' + FormatDateTime('hh:nn:ss.zzz', AValue, TFormatSettings.Invariant) + '''';
  else
    Result := 'TIMESTAMP ''' + FormatDateTime('yyyy-mm-dd hh:nn:ss.zzz', AValue, TFormatSettings.Invariant) + '''';
  end;
end;

function GetScaledNumber(const AMantissa: Int64; const AScale: Integer): string;
begin
  Result := Abs(AMantissa).ToString;

  if AScale > 0 then
  begin
    Result := StringOfChar('0', Max(AScale + 1 - Result.Length, 0)) + Result;
    Result := Result.Insert(Result.Length - AScale, '.');
  end;

  if AMantissa < 0 then
    Result := '-' + Result;
end;

function HasPlainDisplayText(const AField: TField; const AKind: TDatabaseGridSQLValueKind): Boolean;
begin
  Result := (AKind = vkString) or (AKind = vkInteger) and GetNumberDisplayFormat(AField).IsEmpty;
end;

function QuoteName(const AName: string): string;
begin
  Result := '"' + AName.Replace('"', '""') + '"';
end;

function GetTextExpression(const AField: TField; const AKind: TDatabaseGridSQLValueKind; const AReference: string): string;
begin
  if AKind = vkInteger then
    Result := 'CAST(' + AReference + ' AS VARCHAR(20))'
  else
  if AField.DataType in [ftFixedChar, ftFixedWideChar] then
    Result := 'TRIM(TRAILING FROM ' + AReference + ')'
  else
    Result := AReference;
end;

function RemoveThousandSeparators(const AText: string): string;
begin
  if (FormatSettings.ThousandSeparator <> #0) and (FormatSettings.ThousandSeparator <> FormatSettings.DecimalSeparator) then
    Result := AText.Replace(FormatSettings.ThousandSeparator, '')
  else
    Result := AText;
end;

function TryGetNumberLiteral(const AText: string; out ALiteral: string): Boolean;
var
  LNumber: Extended;
begin
  ALiteral := Trim(RemoveThousandSeparators(AText));
  Result := TryStrToFloat(ALiteral, LNumber);

  if Result then
    ALiteral := ALiteral.Replace(FormatSettings.DecimalSeparator, '.')
  else
    ALiteral := '';
end;

function TryGetLiteral(const AKind: TDatabaseGridSQLValueKind; const AText: string; out ALiteral: string): Boolean;
var
  LDateTime: TDateTime;
begin
  ALiteral := '';

  case AKind of
    vkString:
      ALiteral := QuotedStr(AText);
    vkInteger, vkNumber:
      TryGetNumberLiteral(AText, ALiteral);
    vkDate, vkTime, vkDateTime:
      if TryStrToDateTime(AText, LDateTime) then
        ALiteral := GetDateTimeLiteral(AKind, LDateTime);
  end;

  Result := not ALiteral.IsEmpty;
end;

function TryGetNumberRange(const AField: TField; const AText: string; out ALow, AHigh: string): Boolean;
var
  LDecimalPosition: Integer;
  LDigits: string;
  LMantissa: Int64;
  LScale: Integer;
  LSignificantDigits: Integer;
  LText: string;
begin
  ALow := '';
  AHigh := '';

  LText := Trim(RemoveThousandSeparators(AText));

  if LText.ToUpper.Contains('E') or not TryGetNumberLiteral(LText, ALow) then
    Exit(False);

  LSignificantDigits := 0;

  for var LChar in LText do
  if CharInSet(LChar, ['0'..'9']) and ((LSignificantDigits > 0) or (LChar <> '0')) then
    Inc(LSignificantDigits);

  if GetNumberDisplayFormat(AField).IsEmpty and (LSignificantDigits < 15) then
    Exit(True);

  LDecimalPosition := Pos(FormatSettings.DecimalSeparator, LText);

  if LDecimalPosition > 0 then
    LScale := Length(LText) - LDecimalPosition
  else
    LScale := 0;

  LDigits := LText.Replace(FormatSettings.DecimalSeparator, '').Replace('-', '').Replace('+', '');

  if (LDigits.Length > 17) or not TryStrToInt64(LDigits, LMantissa) then
    Exit(False);

  if LText.StartsWith('-') then
  begin
    ALow := GetScaledNumber(-(10 * LMantissa + 5), LScale + 1);
    AHigh := GetScaledNumber(-(10 * LMantissa - 5), LScale + 1);
  end
  else
  begin
    ALow := GetScaledNumber(10 * LMantissa - 5, LScale + 1);
    AHigh := GetScaledNumber(10 * LMantissa + 5, LScale + 1);
  end;

  Result := True;
end;

function TryGetDateTimeRange(const AField: TField; const AKind: TDatabaseGridSQLValueKind; const AText: string; out ALow,
  AHigh: TDateTime): Boolean;
var
  LDateFormat: string;
  LFormat: string;
  LParsed: Boolean;
  LSettings: TFormatSettings;
  LTimeFormat: string;
  LTimePosition: Integer;

  function GetSeparator(const AFormat, AFormatChars: string): Char;
  begin
    for var LChar in AFormat do
    if not AFormatChars.Contains(LowerCase(LChar)) then
      Exit(LChar);

    Result := #0;
  end;

begin
  LSettings := FormatSettings;
  LFormat := GetDateTimeDisplayFormat(AField);
  LTimeFormat := '';

  if LFormat.IsEmpty then
  begin
    case AKind of
      vkDate:
        LTimeFormat := '';
      vkTime:
        LTimeFormat := LSettings.LongTimeFormat;
    else
      if AText.Contains(LSettings.TimeSeparator) then
        LTimeFormat := LSettings.LongTimeFormat;
    end;
  end
  else
  begin
    if LFormat.ToLower.Contains('mmm') or LFormat.ToLower.Contains('ddd') or LFormat.ToLower.Contains('am/pm') or
      LFormat.ToLower.Contains('a/p') or LFormat.Contains('"') or LFormat.Contains('''') then
      Exit(False);

    LTimePosition := Pos('h', LFormat.ToLower);

    if LTimePosition > 0 then
    begin
      LDateFormat := Trim(Copy(LFormat, 1, LTimePosition - 1));
      LTimeFormat := Trim(Copy(LFormat, LTimePosition, MaxInt));
    end
    else
      LDateFormat := Trim(LFormat);

    if not LDateFormat.IsEmpty then
    begin
      LSettings.ShortDateFormat := LDateFormat;
      LSettings.DateSeparator := GetSeparator(LDateFormat, 'dmy');
    end;

    if not LTimeFormat.IsEmpty then
    begin
      LSettings.LongTimeFormat := LTimeFormat;
      LSettings.ShortTimeFormat := LTimeFormat;
      LSettings.TimeSeparator := GetSeparator(LTimeFormat, 'hnsz');
    end;
  end;

  case AKind of
    vkDate:
      LParsed := TryStrToDate(AText, ALow, LSettings);
    vkTime:
      LParsed := TryStrToTime(AText, ALow, LSettings);
  else
    LParsed := TryStrToDateTime(AText, ALow, LSettings);
  end;

  if not LParsed then
    Exit(False);

  LTimeFormat := LTimeFormat.ToLower;

  if LTimeFormat.Contains('z') then
    AHigh := IncMilliSecond(ALow)
  else
  if LTimeFormat.Contains('s') or LFormat.IsEmpty and (AKind = vkDateTime) then
    AHigh := IncSecond(ALow)
  else
  if LTimeFormat.Contains('n') then
    AHigh := IncMinute(ALow)
  else
  if LTimeFormat.Contains('h') then
    AHigh := IncHour(ALow)
  else
    AHigh := IncDay(ALow);

  Result := True;
end;

{ TDatabaseGridIBDACDataSetFeatures }

function TDatabaseGridIBDACDataSetFeatures.TryGetColumnReference(const ADataSet: TCustomDADataSet; const AField: TField;
  out AReference: string): Boolean;
var
  LColumnName, LTableName: string;
begin
  Result := TryGetFieldColumn(ADataSet, AField, LTableName, LColumnName);

  if Result then
    AReference := QuoteName(LTableName) + '.' + QuoteName(LColumnName)
  else
    AReference := '';
end;

function TDatabaseGridIBDACDataSetFeatures.TryGetValuesCondition(const AField: TField; const AReference: string;
  const AValues: TArray<string>; out ACondition: string): Boolean;
var
  LHigh, LLow: string;
  LHighDateTime, LLowDateTime: TDateTime;
  LKind: TDatabaseGridSQLValueKind;
  LLiterals: TArray<string>;
  LNullOrEmpty: Boolean;
  LParts: TArray<string>;
begin
  ACondition := '';
  LKind := GetSQLValueKind(AField);
  LLiterals := nil;
  LNullOrEmpty := False;
  LParts := nil;

  for var LIndex := 0 to High(AValues) do
  begin
    if AValues[LIndex].IsEmpty then
    begin
      LNullOrEmpty := True;

      Continue;
    end;

    case LKind of
      vkString:
        LLiterals := LLiterals + [QuotedStr(AValues[LIndex])];
      vkInteger, vkNumber:
        if not TryGetNumberRange(AField, AValues[LIndex], LLow, LHigh) then
          Exit(False)
        else
        if LHigh.IsEmpty then
          LLiterals := LLiterals + [LLow]
        else
          LParts := LParts + ['(' + AReference + ' >= ' + LLow + ' AND ' + AReference + ' < ' + LHigh + ')'];
      vkDate, vkTime, vkDateTime:
        if TryGetDateTimeRange(AField, LKind, AValues[LIndex], LLowDateTime, LHighDateTime) then
          LParts := LParts + ['(' + AReference + ' >= ' + GetDateTimeLiteral(LKind, LLowDateTime) + ' AND ' + AReference + ' < ' +
            GetDateTimeLiteral(LKind, LHighDateTime) + ')']
        else
          Exit(False);
    else
      Exit(False);
    end;
  end;

  if Length(LLiterals) > 0 then
    for var LIndex := 0 to (Length(LLiterals) - 1) div IN_LIST_MAX_COUNT do
      LParts := LParts + [AReference + ' IN (' + string.Join(', ', LLiterals, LIndex * IN_LIST_MAX_COUNT,
        Min(IN_LIST_MAX_COUNT, Length(LLiterals) - LIndex * IN_LIST_MAX_COUNT)) + ')'];

  if LNullOrEmpty then
  begin
    if LKind = vkString then
      LParts := LParts + ['(' + AReference + ' IS NULL OR ' + GetTextExpression(AField, LKind, AReference) + ' = '''')']
    else
      LParts := LParts + [AReference + ' IS NULL'];
  end;

  if Length(LParts) = 0 then
    ACondition := '1 = 0'
  else
    ACondition := string.Join(' OR ', LParts);

  Result := True;
end;

function TDatabaseGridIBDACDataSetFeatures.TryGetColumnFilterCondition(const ADataSet: TCustomDADataSet;
  const AFilter: TDatabaseGridFieldFilter; out ACondition: string): Boolean;
const
  COMPARISON_OPERATORS: array [foEquals .. foLessOrEqual] of string = ('=', '<>', '', '', '', '', '>', '>=', '<', '<=');
var
  LField: TField;
  LKind: TDatabaseGridSQLValueKind;
  LLiteral, LLiteral2: string;
  LReference: string;
  LText: string;
begin
  ACondition := '';
  LField := AFilter.Field;
  LKind := GetSQLValueKind(LField);

  if (LKind = vkNone) or not TryGetColumnReference(ADataSet, LField, LReference) then
    Exit(False);

  LText := GetTextExpression(LField, LKind, LReference);

  case AFilter.Operator of
    foEquals, foNotEquals, foGreater, foGreaterOrEqual, foLess, foLessOrEqual:
      begin
        if LKind = vkString then
          ACondition := 'UPPER(' + LText + ') ' + COMPARISON_OPERATORS[AFilter.Operator] + ' UPPER(' + QuotedStr(AFilter.Value) + ')'
        else
        if TryGetLiteral(LKind, AFilter.Value, LLiteral) then
          ACondition := LReference + ' ' + COMPARISON_OPERATORS[AFilter.Operator] + ' ' + LLiteral
        else
          Exit(False);

        if AFilter.Operator = foNotEquals then
          ACondition := LReference + ' IS NULL OR ' + ACondition;
      end;
    foBetween:
      if LKind = vkString then
        ACondition := 'UPPER(' + LText + ') BETWEEN UPPER(' + QuotedStr(AFilter.Value) + ') AND UPPER(' + QuotedStr(AFilter.Value2) + ')'
      else
      if TryGetLiteral(LKind, AFilter.Value, LLiteral) and TryGetLiteral(LKind, AFilter.Value2, LLiteral2) then
        ACondition := LReference + ' BETWEEN ' + LLiteral + ' AND ' + LLiteral2
      else
        Exit(False);
    foContains, foNotContains, foBeginsWith, foEndsWith:
      begin
        if not HasPlainDisplayText(LField, LKind) then
          Exit(False);

        case AFilter.Operator of
          foContains:
            ACondition := LText + ' CONTAINING ' + QuotedStr(AFilter.Value);
          foNotContains:
            ACondition := LReference + ' IS NULL OR ' + LText + ' NOT CONTAINING ' + QuotedStr(AFilter.Value);
          foBeginsWith:
            ACondition := 'UPPER(' + LText + ') STARTING WITH UPPER(' + QuotedStr(AFilter.Value) + ')';
        else
          ACondition := 'UPPER(' + LText + ') LIKE UPPER(' + QuotedStr('%' + AFilter.Value.Replace('\', '\\').Replace('%', '\%').
            Replace('_', '\_')) + ') ESCAPE ''\''';
        end;
      end;
    foEmpty:
      if LKind = vkString then
        ACondition := LReference + ' IS NULL OR ' + LText + ' = '''''
      else
        ACondition := LReference + ' IS NULL';
    foNotEmpty:
      if LKind = vkString then
        ACondition := LReference + ' IS NOT NULL AND ' + LText + ' <> '''''
      else
        ACondition := LReference + ' IS NOT NULL';
    foValues:
      Exit(TryGetValuesCondition(LField, LReference, AFilter.Values, ACondition));
  else
    Exit(False);
  end;

  Result := True;
end;

function TDatabaseGridIBDACDataSetFeatures.TryGetSearchCondition(const ADataSet: TCustomDADataSet; const AWords: TArray<string>;
  const AFields: TArray<TField>; out ACondition: string): Boolean;
var
  LDate: TDateTime;
  LFields: TArray<TField>;
  LKind: TDatabaseGridSQLValueKind;
  LKinds: TArray<TDatabaseGridSQLValueKind>;
  LNumber: Extended;
  LNumberWord: string;
  LReference: string;
  LReferences: TArray<string>;
  LWordConditions: TArray<string>;
  LYear: Integer;
begin
  ACondition := '';
  LFields := nil;
  LKinds := nil;
  LReferences := nil;

  for var LIndex := 0 to High(AFields) do
  begin
    if AFields[LIndex].IsBlob or (AFields[LIndex].DataType = ftBoolean) then
      Continue;

    LKind := GetSQLValueKind(AFields[LIndex]);

    if (LKind = vkNone) or not TryGetColumnReference(ADataSet, AFields[LIndex], LReference) then
      Exit(False);

    LFields := LFields + [AFields[LIndex]];
    LKinds := LKinds + [LKind];
    LReferences := LReferences + [LReference];
  end;

  for var LWord in AWords do
  begin
    LWordConditions := nil;
    LNumberWord := RemoveThousandSeparators(LWord);

    if TryStrToFloat(LNumberWord, LNumber) then
      LNumberWord := LNumberWord.Replace(FormatSettings.DecimalSeparator, '.')
    else
      LNumberWord := '';

    for var LIndex := 0 to High(LFields) do
    begin
      LReference := LReferences[LIndex];

      case LKinds[LIndex] of
        vkString:
          LWordConditions := LWordConditions + [GetTextExpression(LFields[LIndex], vkString, LReference) + ' CONTAINING ' +
            QuotedStr(LWord)];
        vkInteger, vkNumber:
          if not LNumberWord.IsEmpty then
            LWordConditions := LWordConditions + ['CAST(' + LReference + ' AS VARCHAR(40)) CONTAINING ' + QuotedStr(LNumberWord)];
        vkDate, vkDateTime:
          if TryStrToDate(LWord, LDate) then
            LWordConditions := LWordConditions + ['CAST(' + LReference + ' AS DATE) = ' + GetDateTimeLiteral(vkDate, LDate)]
          else
          if (LWord.Length = 4) and TryStrToInt(LWord, LYear) and (LYear >= 1000) then
            LWordConditions := LWordConditions + ['EXTRACT(YEAR FROM ' + LReference + ') = ' + LWord];
      end;
    end;

    if Length(LWordConditions) = 0 then
      LWordConditions := ['1 = 0'];

    if not ACondition.IsEmpty then
      ACondition := ACondition + ' AND ';

    ACondition := ACondition + '(' + string.Join(' OR ', LWordConditions) + ')';
  end;

  Result := True;
end;

initialization

  RegisterDatabaseGridDataSetFeatures(TCustomIBCDataSet, TDatabaseGridIBDACDataSetFeatures);

finalization

  UnregisterDatabaseGridDataSetFeatures(TCustomIBCDataSet);

end.
