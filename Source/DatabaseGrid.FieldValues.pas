unit DatabaseGrid.FieldValues;

interface

uses
  Data.DB;

type
  TDatabaseGridValueKind = (vkText, vkBinary, vkBoolean, vkCurrency, vkDate, vkDateTime, vkInteger, vkNumber, vkTime);

const
  DATABASE_GRID_MAX_EXCEL_INTEGER = 999999999999999;

function EscapeXml(const AText: string): string;
function GetFieldDisplayText(const AField: TField): string;
function GetFieldText(const AField: TField): string;
function GetIsoDateTime(const AField: TField; const AKind: TDatabaseGridValueKind): string;
function GetValueKind(const AField: TField): TDatabaseGridValueKind;
function IsCurrencyField(const AField: TField): Boolean;

implementation

uses
  System.SysUtils, System.Variants, DatabaseGrid.Consts;

function EscapeXml(const AText: string): string;
var
  LBuilder: TStringBuilder;
begin
  LBuilder := TStringBuilder.Create(Length(AText));
  try
    for var LChar in AText do
      case LChar of
        '&':
          LBuilder.Append('&amp;');
        '<':
          LBuilder.Append('&lt;');
        '>':
          LBuilder.Append('&gt;');
        '"':
          LBuilder.Append('&quot;');
        TControlCharacters.Tab:
          LBuilder.Append('&#9;');
        TControlCharacters.LineFeed:
          LBuilder.Append('&#10;');
        TControlCharacters.Null..TControlCharacters.Backspace, TControlCharacters.VerticalTab..TControlCharacters.UnitSeparator:
          ;
      else
        LBuilder.Append(LChar);
      end;

    Result := LBuilder.ToString;
  finally
    LBuilder.Free;
  end;
end;

function GetFieldDisplayText(const AField: TField): string;
var
  LKey, LValue: Variant;
begin
  Result := AField.DisplayText;

  if not Result.IsEmpty or (AField.FieldKind <> fkLookup) or not Assigned(AField.DataSet) then
    Exit;

  LKey := AField.DataSet.FieldValues[AField.KeyFields];

  if VarIsNull(LKey) then
    Exit;

  LValue := Null;

  if AField.LookupCache then
    LValue := AField.LookupList.ValueOfKey(LKey);

  if VarIsNull(LValue) and Assigned(AField.LookupDataSet) and AField.LookupDataSet.Active then
    LValue := AField.LookupDataSet.Lookup(AField.LookupKeyFields, LKey, AField.LookupResultField);

  Result := VarToStr(LValue);
end;

function GetFieldText(const AField: TField): string;
begin
  if AField.DataType in [ftMemo, ftWideMemo, ftFmtMemo] then
    Result := AField.AsString
  else
    Result := AField.DisplayText;
end;

function GetIsoDateTime(const AField: TField; const AKind: TDatabaseGridValueKind): string;
begin
  case AKind of
    vkDate:
      Result := FormatDateTime('yyyy"-"mm"-"dd', AField.AsDateTime);
    vkTime:
      Result := FormatDateTime('hh":"nn":"ss"."zzz', AField.AsDateTime);
  else
    Result := FormatDateTime('yyyy"-"mm"-"dd"T"hh":"nn":"ss"."zzz', AField.AsDateTime);
  end;
end;

function GetValueKind(const AField: TField): TDatabaseGridValueKind;
begin
  case AField.DataType of
    ftSmallint, ftInteger, ftWord, ftAutoInc, ftShortint, ftByte, ftLongWord, ftLargeint:
      Result := vkInteger;
    ftFloat, ftBCD, ftFMTBcd, ftSingle, ftExtended:
      Result := if IsCurrencyField(AField) then vkCurrency else vkNumber;
    ftCurrency:
      Result := vkCurrency;
    ftBoolean:
      Result := vkBoolean;
    ftDate:
      Result := vkDate;
    ftTime:
      Result := vkTime;
    ftDateTime, ftTimeStamp, ftTimeStampOffset:
      Result := vkDateTime;
    ftMemo, ftWideMemo, ftFmtMemo:
      Result := vkText;
    ftBytes, ftVarBytes, ftBlob, ftGraphic, ftParadoxOle, ftDBaseOle, ftTypedBinary, ftOraBlob:
      Result := vkBinary;
  else
    Result := vkText;
  end;
end;

function IsCurrencyField(const AField: TField): Boolean;
begin
  if AField is TFloatField then
    Result := TFloatField(AField).Currency
  else
  if AField is TBCDField then
    Result := TBCDField(AField).Currency
  else
  if AField is TFMTBCDField then
    Result := TFMTBCDField(AField).Currency
  else
    Result := False;
end;

end.
