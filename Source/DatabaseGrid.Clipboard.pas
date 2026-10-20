unit DatabaseGrid.Clipboard;

interface

uses
  System.SysUtils, Data.DB, DatabaseGrid.Columns, DatabaseGrid.FieldValues;

type
  TDatabaseGridClipboard = class(TObject)
  strict private
    FColumns: TArray<TDatabaseGridColumn>;
    FFormatSettings: TFormatSettings;
    FHtml: TStringBuilder;
    FText: TStringBuilder;
    FXml: TStringBuilder;
    function GetDateTimeValue(const AField: TField; const AKind: TDatabaseGridValueKind): string;
    function GetHtmlDocument: string;
    function GetNumberValue(const AField: TField): string;
    function GetXmlStyle(const AKind: TDatabaseGridValueKind): string;
    function QuoteText(const AText: string): string;
    procedure AddCell(const AField: TField; const AIndex: Integer);
    procedure AddRow;
    procedure AddTitles;
    procedure BeginRow;
    procedure EndRow;
    procedure SetClipboard;
  public
    constructor Create(const AColumns: TArray<TDatabaseGridColumn>);
    destructor Destroy; override;
    class function ParseText(const AText: string): TArray<TArray<string>>;
    procedure Copy(const ADataSet: TDataSet; const ABookmarks: TArray<TBookmark>; const ACopyTitles: Boolean);
  end;

implementation

uses
  Winapi.Windows, System.Math, Vcl.Clipbrd, DatabaseGrid.Consts;

const
  CLIPBOARD_FORMAT_HTML = 'HTML Format';
  CLIPBOARD_FORMAT_XML_SPREADSHEET = 'XML Spreadsheet';

constructor TDatabaseGridClipboard.Create(const AColumns: TArray<TDatabaseGridColumn>);
begin
  inherited Create;

  FColumns := AColumns;
  FFormatSettings := TFormatSettings.Invariant;
  FHtml := TStringBuilder.Create;
  FText := TStringBuilder.Create;
  FXml := TStringBuilder.Create;
end;

destructor TDatabaseGridClipboard.Destroy;
begin
  FHtml.Free;
  FText.Free;
  FXml.Free;

  inherited Destroy;
end;

class function TDatabaseGridClipboard.ParseText(const AText: string): TArray<TArray<string>>;
var
  LCell: TStringBuilder;
  LIndex, LLength: Integer;
  LRow: TArray<string>;

  procedure EndCell;
  begin
    LRow := LRow + [LCell.ToString];
    LCell.Clear;
  end;

  procedure EndRow;
  begin
    EndCell;

    Result := Result + [LRow];
    LRow := nil;
  end;

begin
  Result := nil;
  LRow := nil;
  LLength := Length(AText);

  while (LLength > 0) and CharInSet(AText[LLength], [TControlCharacters.LineFeed, TControlCharacters.CarriageReturn]) do
    Dec(LLength);

  if LLength = 0 then
    Exit;

  LCell := TStringBuilder.Create;
  try
    LIndex := 1;

    while LIndex <= LLength do
    begin
      if (AText[LIndex] = '"') and (LCell.Length = 0) then
      begin
        Inc(LIndex);

        while LIndex <= LLength do
        begin
          if AText[LIndex] = '"' then
          begin
            if (LIndex < LLength) and (AText[LIndex + 1] = '"') then
              Inc(LIndex)
            else
              Break;
          end;

          LCell.Append(AText[LIndex]);
          Inc(LIndex);
        end;
      end
      else
      if AText[LIndex] = TControlCharacters.Tab then
        EndCell
      else
      if CharInSet(AText[LIndex], [TControlCharacters.LineFeed, TControlCharacters.CarriageReturn]) then
      begin
        if (AText[LIndex] = TControlCharacters.CarriageReturn) and (LIndex < LLength) and (AText[LIndex + 1] = TControlCharacters.LineFeed) then
          Inc(LIndex);

        EndRow;
      end
      else
        LCell.Append(AText[LIndex]);

      Inc(LIndex);
    end;

    EndRow;
  finally
    LCell.Free;
  end;
end;

function TDatabaseGridClipboard.GetDateTimeValue(const AField: TField; const AKind: TDatabaseGridValueKind): string;
const
  ISO_FORMAT = 'yyyy"-"mm"-"dd"T"hh":"nn":"ss"."zzz';
begin
  if AKind = vkTime then
    Result := '1899-12-31T' + FormatDateTime('hh":"nn":"ss"."zzz', AField.AsDateTime, FFormatSettings)
  else
    Result := FormatDateTime(ISO_FORMAT, AField.AsDateTime, FFormatSettings);
end;

function TDatabaseGridClipboard.GetHtmlDocument: string;
const
  FRAGMENT_END = '<!--EndFragment-->';
  FRAGMENT_START = '<!--StartFragment-->';
  HEADER = 'Version:0.9' + sLineBreak + 'StartHTML:%.10d' + sLineBreak + 'EndHTML:%.10d' + sLineBreak + 'StartFragment:%.10d' + sLineBreak +
    'EndFragment:%.10d' + sLineBreak;
var
  LBefore, LDocument: string;
  LHeaderLength: Integer;
begin
  LBefore := '<html xmlns:x="urn:schemas-microsoft-com:office:excel"><head><meta charset="utf-8"></head><body>' + FRAGMENT_START;
  LDocument := LBefore + '<table>' + FHtml.ToString + '</table>' + FRAGMENT_END + '</body></html>';
  LHeaderLength := Length(Format(HEADER, [0, 0, 0, 0]));

  Result := Format(HEADER, [LHeaderLength, LHeaderLength + TEncoding.UTF8.GetByteCount(LDocument),
    LHeaderLength + TEncoding.UTF8.GetByteCount(LBefore),
    LHeaderLength + TEncoding.UTF8.GetByteCount(LDocument) - TEncoding.UTF8.GetByteCount(FRAGMENT_END + '</body></html>')]) +
    LDocument;
end;

function TDatabaseGridClipboard.GetNumberValue(const AField: TField): string;
begin
  case AField.DataType of
    ftSmallint, ftInteger, ftWord, ftAutoInc, ftShortint, ftByte, ftLongWord, ftLargeint:
      Result := IntToStr(AField.AsLargeInt);
  else
    Result := FloatToStr(AField.AsFloat, FFormatSettings);
  end;
end;

function TDatabaseGridClipboard.GetXmlStyle(const AKind: TDatabaseGridValueKind): string;
begin
  case AKind of
    vkCurrency:
      Result := 'Currency';
    vkDate:
      Result := 'Date';
    vkDateTime:
      Result := 'DateTime';
    vkTime:
      Result := 'Time';
  else
    Result := '';
  end;
end;

function TDatabaseGridClipboard.QuoteText(const AText: string): string;
begin
  if AText.IndexOfAny([TControlCharacters.Tab, TControlCharacters.LineFeed, TControlCharacters.CarriageReturn, '"']) < 0 then
    Result := AText
  else
    Result := '"' + AText.Replace('"', '""') + '"';
end;

procedure TDatabaseGridClipboard.AddCell(const AField: TField; const AIndex: Integer);
var
  LHtmlText, LText, LValue: string;
  LKind: TDatabaseGridValueKind;
begin
  if AIndex > 0 then
    FText.Append(TControlCharacters.Tab);

  if not Assigned(AField) or AField.IsNull then
  begin
    FHtml.Append('<td></td>');
    FXml.Append('<Cell/>');

    Exit;
  end;

  LKind := GetValueKind(AField);

  if (LKind = vkBinary) or (LKind = vkInteger) and (Abs(AField.AsLargeInt) > DATABASE_GRID_MAX_EXCEL_INTEGER) then
    LKind := vkText;

  LText := GetFieldText(AField);

  FText.Append(QuoteText(LText));

  LHtmlText := EscapeXml(AdjustLineBreaks(LText, tlbsLF)).Replace('&#10;', '<br style="mso-data-placement:same-cell">');

  case LKind of
    vkInteger, vkNumber, vkCurrency:
      begin
        LValue := GetNumberValue(AField);

        FHtml.Append('<td x:num="' + LValue + '">' + LHtmlText + '</td>');
        FXml.Append(if LKind = vkCurrency then '<Cell ss:StyleID="Currency">' else '<Cell>');
        FXml.Append('<Data ss:Type="Number">' + LValue + '</Data></Cell>');
      end;
    vkDate, vkTime, vkDateTime:
      begin
        FHtml.Append('<td x:num="' + FloatToStr(AField.AsDateTime, FFormatSettings) + '">' + LHtmlText + '</td>');
        FXml.Append('<Cell ss:StyleID="' + GetXmlStyle(LKind) + '"><Data ss:Type="DateTime">' + GetDateTimeValue(AField, LKind) +
          '</Data></Cell>');
      end;
    vkBoolean:
      begin
        FHtml.Append('<td>' + LHtmlText + '</td>');
        FXml.Append('<Cell><Data ss:Type="Boolean">' + IntToStr(Ord(AField.AsBoolean)) + '</Data></Cell>');
      end;
  else
    FHtml.Append('<td>' + LHtmlText + '</td>');
    FXml.Append(if LText.IndexOfAny([TControlCharacters.LineFeed, TControlCharacters.CarriageReturn]) >= 0 then '<Cell ss:StyleID="Wrap">' else '<Cell>');
    FXml.Append('<Data ss:Type="String">' + EscapeXml(AdjustLineBreaks(LText, tlbsLF)) + '</Data></Cell>');
  end;
end;

procedure TDatabaseGridClipboard.AddRow;
begin
  BeginRow;

  for var LIndex := 0 to High(FColumns) do
    AddCell(FColumns[LIndex].Field, LIndex);

  EndRow;
end;

procedure TDatabaseGridClipboard.AddTitles;
var
  LCaption: string;
begin
  BeginRow;

  for var LIndex := 0 to High(FColumns) do
  begin
    LCaption := FColumns[LIndex].Title.DisplayCaption;

    if LIndex > 0 then
      FText.Append(TControlCharacters.Tab);

    FText.Append(QuoteText(LCaption));
    FHtml.Append('<th>' + EscapeXml(LCaption) + '</th>');
    FXml.Append('<Cell ss:StyleID="Title"><Data ss:Type="String">' + EscapeXml(LCaption) + '</Data></Cell>');
  end;

  EndRow;
end;

procedure TDatabaseGridClipboard.BeginRow;
begin
  FHtml.Append('<tr>');
  FXml.Append('<Row>');
end;

procedure TDatabaseGridClipboard.Copy(const ADataSet: TDataSet; const ABookmarks: TArray<TBookmark>; const ACopyTitles: Boolean);
var
  LBookmark: TBookmark;
begin
  FXml.Append('<?xml version="1.0"?><Workbook xmlns="urn:schemas-microsoft-com:office:spreadsheet" ' +
    'xmlns:ss="urn:schemas-microsoft-com:office:spreadsheet"><Styles>' +
    '<Style ss:ID="Title"><Font ss:Bold="1"/></Style>' +
    '<Style ss:ID="Wrap"><Alignment ss:Vertical="Top" ss:WrapText="1"/></Style>' +
    '<Style ss:ID="Currency"><NumberFormat ss:Format="Currency"/></Style>' +
    '<Style ss:ID="Date"><NumberFormat ss:Format="Short Date"/></Style>' +
    '<Style ss:ID="Time"><NumberFormat ss:Format="Long Time"/></Style>' +
    '<Style ss:ID="DateTime"><NumberFormat ss:Format="General Date"/></Style>' +
    '</Styles><Worksheet ss:Name="Sheet1"><Table>');

  if ACopyTitles then
    AddTitles;

  if Length(ABookmarks) = 0 then
    AddRow
  else
  begin
    ADataSet.DisableControls;
    try
      LBookmark := ADataSet.Bookmark;
      try
        for var LRowBookmark in ABookmarks do
        begin
          if not ADataSet.BookmarkValid(LRowBookmark) then
            Continue;

          ADataSet.Bookmark := LRowBookmark;

          AddRow;
        end;
      finally
        if ADataSet.BookmarkValid(LBookmark) then
          ADataSet.Bookmark := LBookmark;
      end;
    finally
      ADataSet.EnableControls;
    end;
  end;

  FXml.Append('</Table></Worksheet></Workbook>');

  SetClipboard;
end;

procedure TDatabaseGridClipboard.EndRow;
begin
  FText.Append(sLineBreak);
  FHtml.Append('</tr>');
  FXml.Append('</Row>');
end;

procedure TDatabaseGridClipboard.SetClipboard;

  procedure SetBytes(const AFormat: string; const AText: string);
  var
    LBytes: TBytes;
    LMemory: HGLOBAL;
  begin
    LBytes := TEncoding.UTF8.GetBytes(AText + TControlCharacters.Null);
    LMemory := GlobalAlloc(GMEM_MOVEABLE, Length(LBytes));

    if LMemory = 0 then
      RaiseLastOSError;

    Move(LBytes[0], GlobalLock(LMemory)^, Length(LBytes));
    GlobalUnlock(LMemory);

    Clipboard.SetAsHandle(RegisterClipboardFormat(PChar(AFormat)), LMemory);
  end;

begin
  Clipboard.Open;
  try
    SetBytes(CLIPBOARD_FORMAT_XML_SPREADSHEET, FXml.ToString);
    SetBytes(CLIPBOARD_FORMAT_HTML, GetHtmlDocument);

    Clipboard.AsText := FText.ToString;
  finally
    Clipboard.Close;
  end;
end;

end.
