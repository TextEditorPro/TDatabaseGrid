unit DatabaseGrid.Export;

interface

uses
  System.Classes, System.SysUtils, Data.DB, DatabaseGrid, DatabaseGrid.Columns;

type
  TDatabaseGridExportFormat = (efText, efCsv, efHtml, efJson, efXlsx);

  TDatabaseGridExportOption = (eoBlobs, eoFooter, eoIsoDates, eoSelectedRows, eoTitles);
  TDatabaseGridExportOptions = set of TDatabaseGridExportOption;

  TDatabaseGridExport = class(TObject)
  strict private
    FBuilder: TStringBuilder;
    FColumns: TArray<TDatabaseGridColumn>;
    FCsvQuote: Char;
    FCsvSeparator: Char;
    FFormatSettings: TFormatSettings;
    FGrid: TCustomDatabaseGrid;
    FOptions: TDatabaseGridExportOptions;
    FSheetName: string;
    FStream: TStream;
    function GetBase64(const AField: TField): string;
    function GetCellText(const AField: TField): string;
    function GetCellTexts: TArray<string>;
    function GetCsvText(const AText: string): string;
    function GetDataSet: TDataSet;
    function GetFooterTexts: TArray<string>;
    function GetHtmlText(const AText: string): string;
    function GetJsonString(const AText: string): string;
    function GetJsonValue(const AField: TField): string;
    function GetTabText(const AText: string): string;
    function GetTitleTexts: TArray<string>;
    function GetXlsxCellReference(const ARow, AColumnIndex: Integer): string;
    function GetXlsxColumnWidth(const AColumn: TDatabaseGridColumn): string;
    function GetXlsxCurrencyFormat: string;
    function GetXlsxSheetName: string;
    function GetXlsxStyles: string;
    function HasFooter: Boolean;
    procedure Flush;
    procedure Write(const AText: string);
    procedure WriteDelimited(const ACsv: Boolean);
    procedure WriteDelimitedLine(const ATexts: TArray<string>; const ACsv: Boolean);
    procedure WriteHtml;
    procedure WriteHtmlRow(const ATag: string; const ATexts: TArray<string>; const AAlignments: TArray<TAlignment>);
    procedure WriteJson;
    procedure WriteXlsx;
    procedure WriteXlsxCell(const ARow, AColumnIndex: Integer; const AField: TField);
    procedure WriteXlsxFooterCell(const ARow, AColumnIndex: Integer; const AColumn: TDatabaseGridColumn);
    procedure WriteXlsxNumber(const ARow, AColumnIndex: Integer; const AValue: string; const AStyle: Integer);
    procedure WriteXlsxSheet;
    procedure WriteXlsxText(const ARow, AColumnIndex: Integer; const AText: string; const AStyle: Integer);
  public
    constructor Create(const AGrid: TCustomDatabaseGrid);
    destructor Destroy; override;
    class function TryGetFormat(const AFileName: string; out AFormat: TDatabaseGridExportFormat): Boolean;
    function GetColumns: TArray<TDatabaseGridColumn>;
    procedure EnumerateRows(const ARowProc: TProc);
    procedure SaveToFile(const AFileName: string); overload;
    procedure SaveToFile(const AFileName: string; const AFormat: TDatabaseGridExportFormat); overload;
    procedure SaveToStream(const AStream: TStream; const AFormat: TDatabaseGridExportFormat);
    property CsvQuote: Char read FCsvQuote write FCsvQuote;
    property CsvSeparator: Char read FCsvSeparator write FCsvSeparator;
    property Options: TDatabaseGridExportOptions read FOptions write FOptions;
    property SheetName: string read FSheetName write FSheetName;
  end;

const
  DATABASE_GRID_DEFAULT_EXPORT_OPTIONS = [eoFooter, eoSelectedRows, eoTitles];

implementation

uses
  System.Generics.Collections, System.Math, System.NetEncoding, System.Variants, System.Zip, Data.FmtBcd, DatabaseGrid.Consts,
  DatabaseGrid.FieldValues, DatabaseGrid.Language, DatabaseGrid.Types;

const
  EXPORT_BUFFER_SIZE = 65536;
  HTML_STYLE = 'table{border-collapse:collapse;font:10pt "Segoe UI",sans-serif}' +
    'th,td{border:1px solid #d0d0d0;padding:2px 6px;vertical-align:top}th{background:#f0f0f0}' +
    'tfoot td{font-weight:bold;background:#f8f8f8}';
  XLSX_CONTENT_TYPES = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>' +
    '<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">' +
    '<Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>' +
    '<Default Extension="xml" ContentType="application/xml"/>' +
    '<Override PartName="/xl/workbook.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/>' +
    '<Override PartName="/xl/worksheets/sheet1.xml" ' +
    'ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/>' +
    '<Override PartName="/xl/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.styles+xml"/>' +
    '</Types>';
  XLSX_FIRST_DATE = 61;
  XLSX_MAX_TEXT_LENGTH = 32767;
  XLSX_PACKAGE_RELATIONSHIPS = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>' +
    '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">' +
    '<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" ' +
    'Target="xl/workbook.xml"/></Relationships>';
  XLSX_STYLE_BOLD = 1;
  XLSX_STYLE_BOLD_CURRENCY = 7;
  XLSX_STYLE_CURRENCY = 5;
  XLSX_STYLE_DATE = 2;
  XLSX_STYLE_DATE_TIME = 3;
  XLSX_STYLE_TIME = 4;
  XLSX_STYLE_WRAP = 6;
  XLSX_WORKBOOK_RELATIONSHIPS = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>' +
    '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">' +
    '<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" ' +
    'Target="worksheets/sheet1.xml"/>' +
    '<Relationship Id="rId2" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" ' +
    'Target="styles.xml"/></Relationships>';

constructor TDatabaseGridExport.Create(const AGrid: TCustomDatabaseGrid);
begin
  inherited Create;

  FGrid := AGrid;
  FBuilder := TStringBuilder.Create;
  FCsvQuote := '"';
  FCsvSeparator := FormatSettings.ListSeparator;
  FFormatSettings := TFormatSettings.Invariant;
  FOptions := DATABASE_GRID_DEFAULT_EXPORT_OPTIONS;
  FSheetName := 'Sheet1';
end;

destructor TDatabaseGridExport.Destroy;
begin
  FBuilder.Free;

  inherited Destroy;
end;

class function TDatabaseGridExport.TryGetFormat(const AFileName: string; out AFormat: TDatabaseGridExportFormat): Boolean;
var
  LExtension: string;
begin
  LExtension := LowerCase(ExtractFileExt(AFileName));
  Result := True;

  if LExtension = '.txt' then
    AFormat := efText
  else
  if LExtension = '.csv' then
    AFormat := efCsv
  else
  if (LExtension = '.htm') or (LExtension = '.html') then
    AFormat := efHtml
  else
  if LExtension = '.json' then
    AFormat := efJson
  else
  if LExtension = '.xlsx' then
    AFormat := efXlsx
  else
    Result := False;
end;

function TDatabaseGridExport.GetBase64(const AField: TField): string;
begin
  Result := TNetEncoding.Base64String.EncodeBytesToString(AField.AsBytes);
end;

function TDatabaseGridExport.GetCellText(const AField: TField): string;
var
  LKind: TDatabaseGridValueKind;
begin
  if not Assigned(AField) or AField.IsNull then
    Exit('');

  LKind := GetValueKind(AField);

  case LKind of
    vkBinary:
      if eoBlobs in FOptions then
        Result := GetBase64(AField)
      else
        Result := '';
    vkDate, vkDateTime, vkTime:
      if eoIsoDates in FOptions then
        Result := GetIsoDateTime(AField, LKind)
      else
        Result := GetFieldText(AField);
  else
    Result := GetFieldText(AField);
  end;
end;

function TDatabaseGridExport.GetCellTexts: TArray<string>;
begin
  SetLength(Result, Length(FColumns));

  for var LIndex := 0 to High(FColumns) do
    Result[LIndex] := GetCellText(FColumns[LIndex].Field);
end;

function TDatabaseGridExport.GetColumns: TArray<TDatabaseGridColumn>;
begin
  Result := nil;

  for var LIndex := 0 to FGrid.Columns.Count - 1 do
  if FGrid.Columns[LIndex].Visible then
    Result := Result + [FGrid.Columns[LIndex]];
end;

function TDatabaseGridExport.GetCsvText(const AText: string): string;
begin
  if (AText.IndexOfAny([FCsvSeparator, FCsvQuote, TControlCharacters.LineFeed, TControlCharacters.CarriageReturn]) < 0) and (AText = AText.Trim) then
    Result := AText
  else
    Result := FCsvQuote + AText.Replace(FCsvQuote, FCsvQuote + FCsvQuote) + FCsvQuote;
end;

function TDatabaseGridExport.GetDataSet: TDataSet;
begin
  if not Assigned(FGrid.DataSource) or not Assigned(FGrid.DataSource.DataSet) or not FGrid.DataSource.DataSet.Active then
    raise EDatabaseError.Create(SDatabaseGridExportNoDataSet);

  Result := FGrid.DataSource.DataSet;
end;

function TDatabaseGridExport.GetFooterTexts: TArray<string>;
begin
  SetLength(Result, Length(FColumns));

  for var LIndex := 0 to High(FColumns) do
    Result[LIndex] := FColumns[LIndex].Footer.GetDisplayText;
end;

function TDatabaseGridExport.GetHtmlText(const AText: string): string;
begin
  Result := EscapeXml(AdjustLineBreaks(AText, tlbsLF)).Replace('&#10;', '<br>');
end;

function TDatabaseGridExport.GetJsonString(const AText: string): string;
var
  LBuilder: TStringBuilder;
begin
  LBuilder := TStringBuilder.Create(Length(AText) + 2);
  try
    LBuilder.Append('"');

    for var LChar in AText do
      case LChar of
        '"':
          LBuilder.Append('\"');
        '\':
          LBuilder.Append('\\');
        TControlCharacters.Backspace:
          LBuilder.Append('\b');
        TControlCharacters.Tab:
          LBuilder.Append('\t');
        TControlCharacters.LineFeed:
          LBuilder.Append('\n');
        TControlCharacters.FormFeed:
          LBuilder.Append('\f');
        TControlCharacters.CarriageReturn:
          LBuilder.Append('\r');
        TControlCharacters.Null..TControlCharacters.Bell, TControlCharacters.VerticalTab, TControlCharacters.ShiftOut..TControlCharacters.UnitSeparator:
          LBuilder.Append('\u' + IntToHex(Ord(LChar), 4));
      else
        LBuilder.Append(LChar);
      end;

    LBuilder.Append('"');

    Result := LBuilder.ToString;
  finally
    LBuilder.Free;
  end;
end;

function TDatabaseGridExport.GetJsonValue(const AField: TField): string;
var
  LKind: TDatabaseGridValueKind;
begin
  if AField.IsNull then
    Exit('null');

  LKind := GetValueKind(AField);

  case LKind of
    vkInteger:
      Result := IntToStr(AField.AsLargeInt);
    vkNumber, vkCurrency:
      if AField is TFMTBCDField then
        Result := BcdToStr(AField.AsBCD, FFormatSettings)
      else
      if AField is TBCDField then
        Result := CurrToStr(AField.AsCurrency, FFormatSettings)
      else
      if IsNan(AField.AsFloat) or IsInfinite(AField.AsFloat) then
        Result := 'null'
      else
        Result := FloatToStr(AField.AsFloat, FFormatSettings);
    vkBoolean:
      Result := if AField.AsBoolean then 'true' else 'false';
    vkDate, vkDateTime, vkTime:
      Result := '"' + GetIsoDateTime(AField, LKind) + '"';
    vkBinary:
      if eoBlobs in FOptions then
        Result := '"' + GetBase64(AField) + '"'
      else
        Result := 'null';
  else
    Result := GetJsonString(AField.AsString);
  end;
end;

function TDatabaseGridExport.GetTabText(const AText: string): string;
begin
  if AText.IndexOfAny([TControlCharacters.Tab, TControlCharacters.LineFeed, TControlCharacters.CarriageReturn, '"']) < 0 then
    Result := AText
  else
    Result := '"' + AText.Replace('"', '""') + '"';
end;

function TDatabaseGridExport.GetTitleTexts: TArray<string>;
begin
  SetLength(Result, Length(FColumns));

  for var LIndex := 0 to High(FColumns) do
    Result[LIndex] := FColumns[LIndex].Title.DisplayCaption;
end;

function TDatabaseGridExport.GetXlsxCellReference(const ARow, AColumnIndex: Integer): string;
var
  LNumber: Integer;
begin
  Result := '';
  LNumber := AColumnIndex + 1;

  while LNumber > 0 do
  begin
    Result := Chr(Ord('A') + (LNumber - 1) mod 26) + Result;
    LNumber := (LNumber - 1) div 26;
  end;

  Result := Result + IntToStr(ARow);
end;

function TDatabaseGridExport.GetXlsxColumnWidth(const AColumn: TDatabaseGridColumn): string;
begin
  Result := FloatToStrF(EnsureRange(AColumn.Width * 96 / FGrid.CurrentPPI / 7, 4, 100), ffFixed, 15, 1, FFormatSettings);
end;

function TDatabaseGridExport.GetXlsxCurrencyFormat: string;
var
  LNumber, LSymbol: string;
begin
  LNumber := '#,##0';

  if FormatSettings.CurrencyDecimals > 0 then
    LNumber := LNumber + '.' + StringOfChar('0', FormatSettings.CurrencyDecimals);

  LSymbol := '"' + FormatSettings.CurrencyString + '"';

  case FormatSettings.CurrencyFormat of
    0:
      Result := LSymbol + LNumber;
    1:
      Result := LNumber + LSymbol;
    2:
      Result := LSymbol + ' ' + LNumber;
  else
    Result := LNumber + ' ' + LSymbol;
  end;
end;

function TDatabaseGridExport.GetXlsxSheetName: string;
begin
  Result := FSheetName;

  for var LChar in '[]:*?/\' do
    Result := Result.Replace(LChar, '_');

  Result := Copy(Result.Trim, 1, 31);

  if Result.IsEmpty then
    Result := 'Sheet1';
end;

function TDatabaseGridExport.GetXlsxStyles: string;
begin
  Result := '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>' +
    '<styleSheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">' +
    '<numFmts count="1"><numFmt numFmtId="164" formatCode="' + EscapeXml(GetXlsxCurrencyFormat) + '"/></numFmts>' +
    '<fonts count="2"><font><sz val="11"/><name val="Calibri"/><family val="2"/></font>' +
    '<font><b/><sz val="11"/><name val="Calibri"/><family val="2"/></font></fonts>' +
    '<fills count="2"><fill><patternFill patternType="none"/></fill><fill><patternFill patternType="gray125"/></fill></fills>' +
    '<borders count="1"><border><left/><right/><top/><bottom/><diagonal/></border></borders>' +
    '<cellStyleXfs count="1"><xf numFmtId="0" fontId="0" fillId="0" borderId="0"/></cellStyleXfs>' +
    '<cellXfs count="8">' +
    '<xf numFmtId="0" fontId="0" fillId="0" borderId="0" xfId="0"/>' +
    '<xf numFmtId="0" fontId="1" fillId="0" borderId="0" xfId="0" applyFont="1"/>' +
    '<xf numFmtId="14" fontId="0" fillId="0" borderId="0" xfId="0" applyNumberFormat="1"/>' +
    '<xf numFmtId="22" fontId="0" fillId="0" borderId="0" xfId="0" applyNumberFormat="1"/>' +
    '<xf numFmtId="21" fontId="0" fillId="0" borderId="0" xfId="0" applyNumberFormat="1"/>' +
    '<xf numFmtId="164" fontId="0" fillId="0" borderId="0" xfId="0" applyNumberFormat="1"/>' +
    '<xf numFmtId="0" fontId="0" fillId="0" borderId="0" xfId="0" applyAlignment="1">' +
    '<alignment vertical="top" wrapText="1"/></xf>' +
    '<xf numFmtId="164" fontId="1" fillId="0" borderId="0" xfId="0" applyFont="1" applyNumberFormat="1"/>' +
    '</cellXfs><cellStyles count="1"><cellStyle name="Normal" xfId="0" builtinId="0"/></cellStyles></styleSheet>';
end;

function TDatabaseGridExport.HasFooter: Boolean;
begin
  Result := (eoFooter in FOptions) and FGrid.Footer.Visible;
end;

procedure TDatabaseGridExport.EnumerateRows(const ARowProc: TProc);
var
  LBookmark: TBookmark;
  LDataSet: TDataSet;
begin
  LDataSet := GetDataSet;
  LDataSet.CheckBrowseMode;

  LDataSet.DisableControls;
  try
    LBookmark := LDataSet.Bookmark;
    try
      if (eoSelectedRows in FOptions) and (FGrid.SelectedRows.Count > 0) then
      begin
        for var LIndex := 0 to FGrid.SelectedRows.Count - 1 do
        if LDataSet.BookmarkValid(FGrid.SelectedRows[LIndex]) then
        begin
          LDataSet.Bookmark := FGrid.SelectedRows[LIndex];

          ARowProc;
        end;
      end
      else
      begin
        LDataSet.First;

        while not LDataSet.Eof do
        begin
          ARowProc;

          LDataSet.Next;
        end;
      end;
    finally
      if LDataSet.BookmarkValid(LBookmark) then
        LDataSet.Bookmark := LBookmark;
    end;
  finally
    LDataSet.EnableControls;
  end;
end;

procedure TDatabaseGridExport.Flush;
var
  LBytes: TBytes;
begin
  if FBuilder.Length = 0 then
    Exit;

  LBytes := TEncoding.UTF8.GetBytes(FBuilder.ToString);
  FStream.WriteBuffer(LBytes, Length(LBytes));
  FBuilder.Clear;
end;

procedure TDatabaseGridExport.SaveToFile(const AFileName: string);
var
  LFormat: TDatabaseGridExportFormat;
begin
  if not TryGetFormat(AFileName, LFormat) then
    raise EArgumentException.CreateFmt(SDatabaseGridExportUnknownFileType, [ExtractFileExt(AFileName)]);

  SaveToFile(AFileName, LFormat);
end;

procedure TDatabaseGridExport.SaveToFile(const AFileName: string; const AFormat: TDatabaseGridExportFormat);
var
  LStream: TFileStream;
begin
  GetDataSet;

  LStream := TFileStream.Create(AFileName, fmCreate);
  try
    try
      SaveToStream(LStream, AFormat);
    finally
      LStream.Free;
    end;
  except
    System.SysUtils.DeleteFile(AFileName);

    raise;
  end;
end;

procedure TDatabaseGridExport.SaveToStream(const AStream: TStream; const AFormat: TDatabaseGridExportFormat);
begin
  GetDataSet;

  FColumns := GetColumns;
  FStream := AStream;
  try
    case AFormat of
      efText:
        WriteDelimited(False);
      efCsv:
        WriteDelimited(True);
      efHtml:
        WriteHtml;
      efJson:
        WriteJson;
      efXlsx:
        WriteXlsx;
    end;

    Flush;
  finally
    FBuilder.Clear;
    FStream := nil;
    FColumns := nil;
  end;
end;

procedure TDatabaseGridExport.Write(const AText: string);
begin
  FBuilder.Append(AText);

  if FBuilder.Length >= EXPORT_BUFFER_SIZE then
    Flush;
end;

procedure TDatabaseGridExport.WriteDelimited(const ACsv: Boolean);
begin
  Write(#$FEFF);

  if eoTitles in FOptions then
    WriteDelimitedLine(GetTitleTexts, ACsv);

  EnumerateRows(
    procedure
    begin
      WriteDelimitedLine(GetCellTexts, ACsv);
    end);

  if HasFooter then
    WriteDelimitedLine(GetFooterTexts, ACsv);
end;

procedure TDatabaseGridExport.WriteDelimitedLine(const ATexts: TArray<string>; const ACsv: Boolean);
begin
  for var LIndex := 0 to High(ATexts) do
  begin
    if LIndex > 0 then
      Write(if ACsv then FCsvSeparator else TControlCharacters.Tab);

    Write(if ACsv then GetCsvText(ATexts[LIndex]) else GetTabText(ATexts[LIndex]));
  end;

  Write(sLineBreak);
end;

procedure TDatabaseGridExport.WriteHtml;
var
  LAlignments: TArray<TAlignment>;
begin
  SetLength(LAlignments, Length(FColumns));

  Write('<!DOCTYPE html>' + sLineBreak + '<html>' + sLineBreak + '<head>' + sLineBreak + '<meta charset="utf-8">' + sLineBreak +
    '<title>' + EscapeXml(FSheetName) + '</title>' + sLineBreak + '<style>' + HTML_STYLE + '</style>' + sLineBreak + '</head>' + sLineBreak +
    '<body>' + sLineBreak + '<table>' + sLineBreak);

  if eoTitles in FOptions then
  begin
    for var LIndex := 0 to High(FColumns) do
      LAlignments[LIndex] := FColumns[LIndex].Title.Alignment;

    Write('<thead>' + sLineBreak);
    WriteHtmlRow('th', GetTitleTexts, LAlignments);
    Write('</thead>' + sLineBreak);
  end;

  for var LIndex := 0 to High(FColumns) do
    LAlignments[LIndex] := FColumns[LIndex].Alignment;

  Write('<tbody>' + sLineBreak);

  EnumerateRows(
    procedure
    begin
      WriteHtmlRow('td', GetCellTexts, LAlignments);
    end);

  Write('</tbody>' + sLineBreak);

  if HasFooter then
  begin
    for var LIndex := 0 to High(FColumns) do
      LAlignments[LIndex] := FColumns[LIndex].Footer.Alignment;

    Write('<tfoot>' + sLineBreak);
    WriteHtmlRow('td', GetFooterTexts, LAlignments);
    Write('</tfoot>' + sLineBreak);
  end;

  Write('</table>' + sLineBreak + '</body>' + sLineBreak + '</html>' + sLineBreak);
end;

procedure TDatabaseGridExport.WriteHtmlRow(const ATag: string; const ATexts: TArray<string>; const AAlignments: TArray<TAlignment>);
const
  ALIGNMENT_STYLES: array [TAlignment] of string = ('', ' style="text-align:right"', ' style="text-align:center"');
begin
  Write('<tr>');

  for var LIndex := 0 to High(ATexts) do
    Write('<' + ATag + ALIGNMENT_STYLES[AAlignments[LIndex]] + '>' + GetHtmlText(ATexts[LIndex]) + '</' + ATag + '>');

  Write('</tr>' + sLineBreak);
end;

procedure TDatabaseGridExport.WriteJson;
var
  LFieldList: TList<TField>;
  LFields: TArray<TField>;
  LFirstRow: Boolean;
begin
  LFieldList := TList<TField>.Create;
  try
    for var LColumn in FColumns do
    if Assigned(LColumn.Field) and not LFieldList.Contains(LColumn.Field) then
      LFieldList.Add(LColumn.Field);

    LFields := LFieldList.ToArray;
  finally
    LFieldList.Free;
  end;

  LFirstRow := True;

  Write('[');

  EnumerateRows(
    procedure
    begin
      Write(if LFirstRow then sLineBreak + '  {' else ',' + sLineBreak + '  {');

      LFirstRow := False;

      for var LIndex := 0 to High(LFields) do
      begin
        if LIndex > 0 then
          Write(', ');

        Write(GetJsonString(LFields[LIndex].FieldName) + ': ' + GetJsonValue(LFields[LIndex]));
      end;

      Write('}');
    end);

  Write(if LFirstRow then ']' + sLineBreak else sLineBreak + ']' + sLineBreak);
end;

procedure TDatabaseGridExport.WriteXlsx;
var
  LSheet: TMemoryStream;
  LStream: TStream;
  LZipFile: TZipFile;
begin
  LStream := FStream;
  LSheet := TMemoryStream.Create;
  try
    FStream := LSheet;

    WriteXlsxSheet;
    Flush;

    FStream := LStream;
    LSheet.Position := 0;

    LZipFile := TZipFile.Create;
    try
      LZipFile.Open(LStream, zmWrite);
      LZipFile.Add(TEncoding.UTF8.GetBytes(XLSX_CONTENT_TYPES), '[Content_Types].xml');
      LZipFile.Add(TEncoding.UTF8.GetBytes(XLSX_PACKAGE_RELATIONSHIPS), '_rels/.rels');
      LZipFile.Add(TEncoding.UTF8.GetBytes('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>' +
        '<workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" ' +
        'xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships"><sheets>' +
        '<sheet name="' + EscapeXml(GetXlsxSheetName) + '" sheetId="1" r:id="rId1"/></sheets></workbook>'), 'xl/workbook.xml');
      LZipFile.Add(TEncoding.UTF8.GetBytes(XLSX_WORKBOOK_RELATIONSHIPS), 'xl/_rels/workbook.xml.rels');
      LZipFile.Add(TEncoding.UTF8.GetBytes(GetXlsxStyles), 'xl/styles.xml');
      LZipFile.Add(LSheet, 'xl/worksheets/sheet1.xml');
      LZipFile.Close;
    finally
      LZipFile.Free;
    end;
  finally
    FStream := LStream;
    LSheet.Free;
  end;
end;

procedure TDatabaseGridExport.WriteXlsxCell(const ARow, AColumnIndex: Integer; const AField: TField);
var
  LKind: TDatabaseGridValueKind;
  LText: string;
begin
  if not Assigned(AField) or AField.IsNull then
    Exit;

  LKind := GetValueKind(AField);

  case LKind of
    vkInteger:
      if Abs(AField.AsLargeInt) <= DATABASE_GRID_MAX_EXCEL_INTEGER then
        WriteXlsxNumber(ARow, AColumnIndex, IntToStr(AField.AsLargeInt), 0)
      else
        WriteXlsxText(ARow, AColumnIndex, AField.AsString, 0);
    vkNumber, vkCurrency:
      if IsNan(AField.AsFloat) or IsInfinite(AField.AsFloat) then
        WriteXlsxText(ARow, AColumnIndex, AField.DisplayText, 0)
      else
        WriteXlsxNumber(ARow, AColumnIndex, FloatToStr(AField.AsFloat, FFormatSettings),
          if LKind = vkCurrency then XLSX_STYLE_CURRENCY else 0);
    vkBoolean:
      Write('<c r="' + GetXlsxCellReference(ARow, AColumnIndex) + '" t="b"><v>' + IntToStr(Ord(AField.AsBoolean)) + '</v></c>');
    vkDate, vkDateTime:
      if AField.AsDateTime < XLSX_FIRST_DATE then
        WriteXlsxText(ARow, AColumnIndex, GetIsoDateTime(AField, LKind), 0)
      else
        WriteXlsxNumber(ARow, AColumnIndex, FloatToStr(AField.AsDateTime, FFormatSettings),
          if LKind = vkDate then XLSX_STYLE_DATE else XLSX_STYLE_DATE_TIME);
    vkTime:
      WriteXlsxNumber(ARow, AColumnIndex, FloatToStr(Frac(AField.AsDateTime), FFormatSettings), XLSX_STYLE_TIME);
    vkBinary:
      if eoBlobs in FOptions then
        WriteXlsxText(ARow, AColumnIndex, GetBase64(AField), 0);
  else
    LText := GetFieldText(AField);

    WriteXlsxText(ARow, AColumnIndex, LText, if LText.IndexOfAny([TControlCharacters.LineFeed, TControlCharacters.CarriageReturn]) >= 0 then XLSX_STYLE_WRAP else 0);
  end;
end;

procedure TDatabaseGridExport.WriteXlsxFooterCell(const ARow, AColumnIndex: Integer; const AColumn: TDatabaseGridColumn);
var
  LFooter: TDatabaseGridColumnFooter;
  LValue: Variant;
begin
  LFooter := AColumn.Footer;
  LValue := LFooter.Value;

  if (LFooter.ValueType = fvNone) or not LFooter.DisplayFormat.IsEmpty or VarIsNull(LValue) or VarIsEmpty(LValue) then
    WriteXlsxText(ARow, AColumnIndex, LFooter.GetDisplayText, XLSX_STYLE_BOLD)
  else
  if VarIsOrdinal(LValue) then
    WriteXlsxNumber(ARow, AColumnIndex, VarToStr(LValue), XLSX_STYLE_BOLD)
  else
    WriteXlsxNumber(ARow, AColumnIndex, FloatToStr(Double(LValue), FFormatSettings),
      if (LFooter.ValueType <> fvCount) and IsCurrencyField(LFooter.Field) then XLSX_STYLE_BOLD_CURRENCY else XLSX_STYLE_BOLD);
end;

procedure TDatabaseGridExport.WriteXlsxNumber(const ARow, AColumnIndex: Integer; const AValue: string; const AStyle: Integer);
begin
  Write('<c r="' + GetXlsxCellReference(ARow, AColumnIndex) + '"');

  if AStyle <> 0 then
    Write(' s="' + IntToStr(AStyle) + '"');

  Write('><v>' + AValue + '</v></c>');
end;

procedure TDatabaseGridExport.WriteXlsxSheet;
var
  LRow: Integer;
  LTitles: TArray<string>;
begin
  Write('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>' +
    '<worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">');

  if eoTitles in FOptions then
    Write('<sheetViews><sheetView workbookViewId="0">' +
      '<pane ySplit="1" topLeftCell="A2" activePane="bottomLeft" state="frozen"/></sheetView></sheetViews>');

  if Length(FColumns) > 0 then
  begin
    Write('<cols>');

    for var LIndex := 0 to High(FColumns) do
      Write('<col min="' + IntToStr(LIndex + 1) + '" max="' + IntToStr(LIndex + 1) + '" width="' +
        GetXlsxColumnWidth(FColumns[LIndex]) + '" customWidth="1"/>');

    Write('</cols>');
  end;

  Write('<sheetData>');

  LRow := 0;

  if eoTitles in FOptions then
  begin
    Inc(LRow);
    LTitles := GetTitleTexts;

    Write('<row r="' + IntToStr(LRow) + '">');

    for var LIndex := 0 to High(LTitles) do
      WriteXlsxText(LRow, LIndex, LTitles[LIndex], XLSX_STYLE_BOLD);

    Write('</row>');
  end;

  EnumerateRows(
    procedure
    begin
      Inc(LRow);

      Write('<row r="' + IntToStr(LRow) + '">');

      for var LIndex := 0 to High(FColumns) do
        WriteXlsxCell(LRow, LIndex, FColumns[LIndex].Field);

      Write('</row>');
    end);

  if HasFooter then
  begin
    Inc(LRow);

    Write('<row r="' + IntToStr(LRow) + '">');

    for var LIndex := 0 to High(FColumns) do
      WriteXlsxFooterCell(LRow, LIndex, FColumns[LIndex]);

    Write('</row>');
  end;

  Write('</sheetData></worksheet>');
end;

procedure TDatabaseGridExport.WriteXlsxText(const ARow, AColumnIndex: Integer; const AText: string; const AStyle: Integer);
begin
  if AText.IsEmpty then
    Exit;

  Write('<c r="' + GetXlsxCellReference(ARow, AColumnIndex) + '"');

  if AStyle <> 0 then
    Write(' s="' + IntToStr(AStyle) + '"');

  Write(' t="inlineStr"><is><t xml:space="preserve">' + EscapeXml(AdjustLineBreaks(Copy(AText, 1, XLSX_MAX_TEXT_LENGTH), tlbsLF)) +
    '</t></is></c>');
end;

end.
