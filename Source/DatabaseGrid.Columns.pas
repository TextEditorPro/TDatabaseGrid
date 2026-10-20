unit DatabaseGrid.Columns;

interface

uses
  System.Classes, System.UITypes, Vcl.ImgList, Data.DB, DatabaseGrid.Consts, DatabaseGrid.Types;

type
  TDatabaseGridColumn = class;

  TDatabaseGridColumnFilterCondition = class(TPersistent)
  strict private
    FColumn: TDatabaseGridColumn;
    FOperator: TDatabaseGridColumnFilterOperator;
    FValue: string;
    FValue2: string;
    FValues: TStringList;
    function CompareFieldValue(const AField: TField; const AValue: string): Integer;
    function GetActive: Boolean;
  public
    constructor Create(const AColumn: TDatabaseGridColumn);
    destructor Destroy; override;
    function Matches(const AField: TField): Boolean;
    procedure Assign(ASource: TPersistent); override;
    procedure Clear;
    procedure SetCondition(const AOperator: TDatabaseGridColumnFilterOperator; const AValue: string = ''; const AValue2: string = '');
    procedure SetValues(const AValues: TStrings);
    property Active: Boolean read GetActive;
    property &Operator: TDatabaseGridColumnFilterOperator read FOperator;
    property Value: string read FValue;
    property Value2: string read FValue2;
    property Values: TStringList read FValues;
  end;

  TDatabaseGridColumnFooter = class(TPersistent)
  strict private
    FAlignment: TAlignment;
    FColumn: TDatabaseGridColumn;
    FDisplayFormat: string;
    FField: TField;
    FFieldName: string;
    FText: string;
    FValue: Variant;
    FValueType: TDatabaseGridFooterValueType;
    procedure SetAlignment(const AValue: TAlignment);
    procedure SetDisplayFormat(const AValue: string);
    procedure SetFieldName(const AValue: string);
    procedure SetText(const AValue: string);
    procedure SetValueType(const AValue: TDatabaseGridFooterValueType);
  protected
    function GetOwner: TPersistent; override;
  public
    constructor Create(const AColumn: TDatabaseGridColumn);
    function GetDisplayText: string;
    procedure Assign(ASource: TPersistent); override;
    property Field: TField read FField write FField;
    property Value: Variant read FValue write FValue;
  published
    property Alignment: TAlignment read FAlignment write SetAlignment default taLeftJustify;
    property DisplayFormat: string read FDisplayFormat write SetDisplayFormat;
    property FieldName: string read FFieldName write SetFieldName;
    property Text: string read FText write SetText;
    property ValueType: TDatabaseGridFooterValueType read FValueType write SetValueType default fvNone;
  end;

  TDatabaseGridColumnTitle = class(TPersistent)
  strict private
    FAlignment: TAlignment;
    FCaption: string;
    FColumn: TDatabaseGridColumn;
    FHint: string;
    FImageIndex: System.UITypes.TImageIndex;
    FOptions: TDatabaseGridTitleOptions;
    FSortMarker: TDatabaseGridSortMarker;
    FSubCaption: string;
    function GetCaptionText: string;
    function GetDisplayCaption: string;
    procedure SetAlignment(const AValue: TAlignment);
    procedure SetCaption(const AValue: string);
    procedure SetImageIndex(const AValue: System.UITypes.TImageIndex);
    procedure SetOptions(const AValue: TDatabaseGridTitleOptions);
    procedure SetSortMarker(const AValue: TDatabaseGridSortMarker);
    procedure SetSubCaption(const AValue: string);
  protected
    function GetOwner: TPersistent; override;
  public
    constructor Create(const AColumn: TDatabaseGridColumn);
    function GetCaptionParts: TArray<string>;
    procedure Assign(ASource: TPersistent); override;
    property DisplayCaption: string read GetDisplayCaption;
  published
    property Alignment: TAlignment read FAlignment write SetAlignment default taLeftJustify;
    property Caption: string read FCaption write SetCaption;
    property Hint: string read FHint write FHint;
    property ImageIndex: System.UITypes.TImageIndex read FImageIndex write SetImageIndex default -1;
    property Options: TDatabaseGridTitleOptions read FOptions write SetOptions default TDatabaseGridDefault.TitleOptions;
    property SortMarker: TDatabaseGridSortMarker read FSortMarker write SetSortMarker default smNone;
    property SubCaption: string read FSubCaption write SetSubCaption;
  end;

  TDatabaseGridColumn = class(TCollectionItem)
  strict private
    FAlignment: TAlignment;
    FDropDownRowCount: Integer;
    FEditor: TDatabaseGridEditorKind;
    FField: TField;
    FFieldName: string;
    FFilter: TDatabaseGridColumnFilterCondition;
    FFooter: TDatabaseGridColumnFooter;
    FImages: TCustomImageList;
    FImageValues: TStrings;
    FOptions: TDatabaseGridColumnOptions;
    FPickList: TStrings;
    FTitle: TDatabaseGridColumnTitle;
    FUnlistedImageIndex: System.UITypes.TImageIndex;
    FVisible: Boolean;
    FWidth: Integer;
    function IsImageValuesStored: Boolean;
    function IsPickListStored: Boolean;
    procedure ImageValuesChange(ASender: TObject);
    procedure SetAlignment(const AValue: TAlignment);
    procedure SetDropDownRowCount(const AValue: Integer);
    procedure SetEditor(const AValue: TDatabaseGridEditorKind);
    procedure SetFieldName(const AValue: string);
    procedure SetFooter(const AValue: TDatabaseGridColumnFooter);
    procedure SetImages(const AValue: TCustomImageList);
    procedure SetImageValues(const AValue: TStrings);
    procedure SetOptions(const AValue: TDatabaseGridColumnOptions);
    procedure SetPickList(const AValue: TStrings);
    procedure SetTitle(const AValue: TDatabaseGridColumnTitle);
    procedure SetUnlistedImageIndex(const AValue: System.UITypes.TImageIndex);
    procedure SetVisible(const AValue: Boolean);
    procedure SetWidth(const AValue: Integer);
  protected
    function GetDisplayName: string; override;
  public
    constructor Create(ACollection: TCollection); override;
    destructor Destroy; override;
    function GetEditorKind: TDatabaseGridEditorKind;
    function GetImageIndex: Integer;
    procedure Assign(ASource: TPersistent); override;
    procedure FilterChanged;
    property Field: TField read FField write FField;
    property Filter: TDatabaseGridColumnFilterCondition read FFilter;
  published
    property Alignment: TAlignment read FAlignment write SetAlignment default taLeftJustify;
    property DropDownRowCount: Integer read FDropDownRowCount write SetDropDownRowCount default TDatabaseGridDefault.DropDownRowCount;
    property Editor: TDatabaseGridEditorKind read FEditor write SetEditor default ekAuto;
    property FieldName: string read FFieldName write SetFieldName;
    property Footer: TDatabaseGridColumnFooter read FFooter write SetFooter;
    property Images: TCustomImageList read FImages write SetImages;
    property ImageValues: TStrings read FImageValues write SetImageValues stored IsImageValuesStored;
    property Options: TDatabaseGridColumnOptions read FOptions write SetOptions default TDatabaseGridDefault.ColumnOptions;
    property PickList: TStrings read FPickList write SetPickList stored IsPickListStored;
    property Title: TDatabaseGridColumnTitle read FTitle write SetTitle;
    property UnlistedImageIndex: System.UITypes.TImageIndex read FUnlistedImageIndex write SetUnlistedImageIndex default -1;
    property Visible: Boolean read FVisible write SetVisible default True;
    property Width: Integer read FWidth write SetWidth default TDatabaseGridDefault.ColumnWidth;
  end;

  TDatabaseGridColumns = class(TOwnedCollection)
  strict private
    FAutoCreated: Boolean;
    FAutoCreating: Boolean;
    FOnChange: TNotifyEvent;
    FOnFilterChange: TNotifyEvent;
    function GetItem(const AIndex: Integer): TDatabaseGridColumn;
    procedure SetItem(const AIndex: Integer; const AValue: TDatabaseGridColumn);
  protected
    procedure Notify(AItem: TCollectionItem; AAction: TCollectionNotification); override;
    procedure Update(AItem: TCollectionItem); override;
  public
    constructor Create(const AOwner: TPersistent);
    function Add: TDatabaseGridColumn;
    function Contains(const AColumn: TDatabaseGridColumn): Boolean;
    function FindColumn(const AFieldName: string): TDatabaseGridColumn;
    function MatchesFields(const ADataSet: TDataSet): Boolean;
    procedure AddFields(const ADataSet: TDataSet; const ACharWidth, AMaxWidth: Integer);
    procedure BindFields(const ADataSet: TDataSet);
    procedure ChangeScale(const AMultiplier, ADivider: Integer);
    procedure ClearAutoCreated;
    procedure CreateFromFields(const ADataSet: TDataSet; const ACharWidth, AMaxWidth: Integer);
    property AutoCreated: Boolean read FAutoCreated;
    property AutoCreating: Boolean read FAutoCreating;
    property Items[const AIndex: Integer]: TDatabaseGridColumn read GetItem write SetItem; default;
    property OnChange: TNotifyEvent read FOnChange write FOnChange;
    property OnFilterChange: TNotifyEvent read FOnFilterChange write FOnFilterChange;
  end;

implementation

uses
  Winapi.Windows, System.DateUtils, System.Math, System.SysUtils, System.Variants, Data.FmtBcd, DatabaseGrid.FieldValues;

{ TDatabaseGridColumnFilterCondition }

constructor TDatabaseGridColumnFilterCondition.Create(const AColumn: TDatabaseGridColumn);
begin
  inherited Create;

  FColumn := AColumn;
  FValues := TStringList.Create;
  FValues.CaseSensitive := False;
  FValues.Duplicates := dupIgnore;
  FValues.Sorted := True;
end;

destructor TDatabaseGridColumnFilterCondition.Destroy;
begin
  FValues.Free;

  inherited Destroy;
end;

procedure TDatabaseGridColumnFilterCondition.Assign(ASource: TPersistent);
begin
  if Assigned(ASource) and (ASource is TDatabaseGridColumnFilterCondition) then
  with ASource as TDatabaseGridColumnFilterCondition do
  begin
    Self.FOperator := FOperator;
    Self.FValue := FValue;
    Self.FValue2 := FValue2;
    Self.FValues.Assign(FValues);

    Self.FColumn.FilterChanged;
  end
  else
    inherited Assign(ASource);
end;

function TDatabaseGridColumnFilterCondition.CompareFieldValue(const AField: TField; const AValue: string): Integer;
var
  LDateTime: TDateTime;
  LNumber: Extended;
begin
  if (AField is TNumericField) and TryStrToFloat(AValue, LNumber) then
    Result := CompareValue(AField.AsExtended, LNumber)
  else
  if (AField is TDateTimeField) and TryStrToDateTime(AValue, LDateTime) then
    Result := CompareDateTime(AField.AsDateTime, LDateTime)
  else
    Result := AnsiCompareText(GetFieldDisplayText(AField), AValue);
end;

function TDatabaseGridColumnFilterCondition.GetActive: Boolean;
begin
  Result := FOperator <> foNone;
end;

function TDatabaseGridColumnFilterCondition.Matches(const AField: TField): Boolean;
var
  LIndex: Integer;
  LText: string;
begin
  LText := GetFieldDisplayText(AField);

  case FOperator of
    foValues:
      Result := FValues.Find(LText, LIndex);
    foEquals:
      Result := CompareFieldValue(AField, FValue) = 0;
    foNotEquals:
      Result := CompareFieldValue(AField, FValue) <> 0;
    foContains:
      Result := AnsiUpperCase(LText).Contains(AnsiUpperCase(FValue));
    foNotContains:
      Result := not AnsiUpperCase(LText).Contains(AnsiUpperCase(FValue));
    foBeginsWith:
      Result := AnsiUpperCase(LText).StartsWith(AnsiUpperCase(FValue));
    foEndsWith:
      Result := AnsiUpperCase(LText).EndsWith(AnsiUpperCase(FValue));
    foGreater:
      Result := CompareFieldValue(AField, FValue) > 0;
    foGreaterOrEqual:
      Result := CompareFieldValue(AField, FValue) >= 0;
    foLess:
      Result := CompareFieldValue(AField, FValue) < 0;
    foLessOrEqual:
      Result := CompareFieldValue(AField, FValue) <= 0;
    foBetween:
      Result := (CompareFieldValue(AField, FValue) >= 0) and (CompareFieldValue(AField, FValue2) <= 0);
    foEmpty:
      Result := AField.IsNull or LText.IsEmpty;
    foNotEmpty:
      Result := not AField.IsNull and not LText.IsEmpty;
  else
    Result := True;
  end;
end;

procedure TDatabaseGridColumnFilterCondition.Clear;
begin
  SetCondition(foNone);
end;

procedure TDatabaseGridColumnFilterCondition.SetCondition(const AOperator: TDatabaseGridColumnFilterOperator; const AValue: string = '';
  const AValue2: string = '');
begin
  if (FOperator = AOperator) and (FValue = AValue) and (FValue2 = AValue2) and (AOperator <> foValues) then
    Exit;

  FOperator := AOperator;
  FValue := AValue;
  FValue2 := AValue2;

  if AOperator <> foValues then
    FValues.Clear;

  FColumn.FilterChanged;
end;

procedure TDatabaseGridColumnFilterCondition.SetValues(const AValues: TStrings);
begin
  FValues.Sorted := False;
  FValues.Assign(AValues);
  FValues.Sorted := True;
  FOperator := foValues;
  FValue := '';
  FValue2 := '';

  FColumn.FilterChanged;
end;

{ TDatabaseGridColumnFooter }

constructor TDatabaseGridColumnFooter.Create(const AColumn: TDatabaseGridColumn);
begin
  inherited Create;

  FColumn := AColumn;
  FAlignment := taLeftJustify;
  FValue := Null;
end;

procedure TDatabaseGridColumnFooter.Assign(ASource: TPersistent);
begin
  if Assigned(ASource) and (ASource is TDatabaseGridColumnFooter) then
  with ASource as TDatabaseGridColumnFooter do
  begin
    Self.FAlignment := FAlignment;
    Self.FDisplayFormat := FDisplayFormat;
    Self.FFieldName := FFieldName;
    Self.FText := FText;
    Self.FValueType := FValueType;

    Self.FColumn.Changed(False);
  end
  else
    inherited Assign(ASource);
end;

function TDatabaseGridColumnFooter.GetDisplayText: string;
var
  LFormat: string;
begin
  if FValueType = fvNone then
    Exit(FText);

  if VarIsNull(FValue) or VarIsEmpty(FValue) then
    Exit('');

  LFormat := FDisplayFormat;

  if LFormat.IsEmpty and (FValueType <> fvCount) and (FField is TNumericField) then
    LFormat := TNumericField(FField).DisplayFormat;

  if not LFormat.IsEmpty then
  begin
    if VarIsFMTBcd(FValue) then
      Exit(FormatBcd(LFormat, VarToBcd(FValue)));

    Exit(FormatFloat(LFormat, FValue));
  end;

  if (FValueType <> fvCount) and IsCurrencyField(FField) then
    Result := CurrToStrF(FValue, ffCurrency, FormatSettings.CurrencyDecimals)
  else
    Result := VarToStr(FValue);
end;

function TDatabaseGridColumnFooter.GetOwner: TPersistent;
begin
  Result := FColumn;
end;

procedure TDatabaseGridColumnFooter.SetAlignment(const AValue: TAlignment);
begin
  if FAlignment <> AValue then
  begin
    FAlignment := AValue;

    FColumn.Changed(False);
  end;
end;

procedure TDatabaseGridColumnFooter.SetDisplayFormat(const AValue: string);
begin
  if FDisplayFormat <> AValue then
  begin
    FDisplayFormat := AValue;

    FColumn.Changed(False);
  end;
end;

procedure TDatabaseGridColumnFooter.SetFieldName(const AValue: string);
begin
  if FFieldName <> AValue then
  begin
    FFieldName := AValue;

    FColumn.Changed(False);
  end;
end;

procedure TDatabaseGridColumnFooter.SetText(const AValue: string);
begin
  if FText <> AValue then
  begin
    FText := AValue;

    FColumn.Changed(False);
  end;
end;

procedure TDatabaseGridColumnFooter.SetValueType(const AValue: TDatabaseGridFooterValueType);
begin
  if FValueType <> AValue then
  begin
    FValueType := AValue;
    FValue := Null;

    FColumn.Changed(False);
  end;
end;

{ TDatabaseGridColumnTitle }

constructor TDatabaseGridColumnTitle.Create(const AColumn: TDatabaseGridColumn);
begin
  inherited Create;

  FColumn := AColumn;
  FAlignment := taLeftJustify;
  FImageIndex := -1;
  FOptions := TDatabaseGridDefault.TitleOptions;
  FSortMarker := smNone;
end;

procedure TDatabaseGridColumnTitle.Assign(ASource: TPersistent);
begin
  if Assigned(ASource) and (ASource is TDatabaseGridColumnTitle) then
  with ASource as TDatabaseGridColumnTitle do
  begin
    Self.FAlignment := FAlignment;
    Self.FCaption := FCaption;
    Self.FHint := FHint;
    Self.FImageIndex := FImageIndex;
    Self.FOptions := FOptions;
    Self.FSortMarker := FSortMarker;
    Self.FSubCaption := FSubCaption;

    Self.FColumn.Changed(False);
  end
  else
    inherited Assign(ASource);
end;

function TDatabaseGridColumnTitle.GetCaptionParts: TArray<string>;
begin
  Result := GetCaptionText.Split([TDatabaseGridCaption.PartSeparator]);

  if Length(Result) = 0 then
    Result := [''];
end;

function TDatabaseGridColumnTitle.GetCaptionText: string;
begin
  if not FCaption.IsEmpty then
    Exit(FCaption);

  if Assigned(FColumn.Field) then
    Exit(FColumn.Field.DisplayLabel);

  Result := FColumn.FieldName;
end;

function TDatabaseGridColumnTitle.GetDisplayCaption: string;
begin
  Result := string.Join(TDatabaseGridCaption.PartTextSeparator, GetCaptionParts);
end;

function TDatabaseGridColumnTitle.GetOwner: TPersistent;
begin
  Result := FColumn;
end;

procedure TDatabaseGridColumnTitle.SetAlignment(const AValue: TAlignment);
begin
  if FAlignment <> AValue then
  begin
    FAlignment := AValue;

    FColumn.Changed(False);
  end;
end;

procedure TDatabaseGridColumnTitle.SetCaption(const AValue: string);
begin
  if FCaption <> AValue then
  begin
    FCaption := AValue;

    FColumn.Changed(False);
  end;
end;

procedure TDatabaseGridColumnTitle.SetImageIndex(const AValue: System.UITypes.TImageIndex);
begin
  if FImageIndex <> AValue then
  begin
    FImageIndex := AValue;

    FColumn.Changed(False);
  end;
end;

procedure TDatabaseGridColumnTitle.SetOptions(const AValue: TDatabaseGridTitleOptions);
begin
  if FOptions <> AValue then
  begin
    FOptions := AValue;

    FColumn.Changed(False);
  end;
end;

procedure TDatabaseGridColumnTitle.SetSortMarker(const AValue: TDatabaseGridSortMarker);
begin
  if FSortMarker <> AValue then
  begin
    FSortMarker := AValue;

    FColumn.Changed(False);
  end;
end;

procedure TDatabaseGridColumnTitle.SetSubCaption(const AValue: string);
begin
  if FSubCaption <> AValue then
  begin
    FSubCaption := AValue;

    FColumn.Changed(False);
  end;
end;

{ TDatabaseGridColumn }

constructor TDatabaseGridColumn.Create(ACollection: TCollection);
begin
  FTitle := TDatabaseGridColumnTitle.Create(Self);
  FFilter := TDatabaseGridColumnFilterCondition.Create(Self);
  FFooter := TDatabaseGridColumnFooter.Create(Self);
  FPickList := TStringList.Create;
  FImageValues := TStringList.Create;
  TStringList(FImageValues).OnChange := ImageValuesChange;
  FUnlistedImageIndex := -1;
  FAlignment := taLeftJustify;
  FDropDownRowCount := TDatabaseGridDefault.DropDownRowCount;
  FOptions := TDatabaseGridDefault.ColumnOptions;
  FVisible := True;
  FWidth := TDatabaseGridDefault.ColumnWidth;

  inherited Create(ACollection);
end;

destructor TDatabaseGridColumn.Destroy;
begin
  inherited Destroy;

  FFilter.Free;
  FFooter.Free;
  FImageValues.Free;
  FPickList.Free;
  FTitle.Free;
end;

procedure TDatabaseGridColumn.Assign(ASource: TPersistent);
begin
  if Assigned(ASource) and (ASource is TDatabaseGridColumn) then
  with ASource as TDatabaseGridColumn do
  begin
    Self.FAlignment := FAlignment;
    Self.FDropDownRowCount := FDropDownRowCount;
    Self.FEditor := FEditor;
    Self.FFieldName := FFieldName;
    Self.FPickList.Assign(FPickList);
    Self.FImages := FImages;
    Self.FImageValues.Assign(FImageValues);
    Self.FUnlistedImageIndex := FUnlistedImageIndex;
    Self.FOptions := FOptions;
    Self.FVisible := FVisible;
    Self.FWidth := FWidth;
    Self.FTitle.Assign(FTitle);
    Self.FFilter.Assign(FFilter);
    Self.FFooter.Assign(FFooter);
  end
  else
    inherited Assign(ASource);
end;

procedure TDatabaseGridColumn.FilterChanged;
begin
  Changed(False);

  if Assigned(Collection) and Assigned((Collection as TDatabaseGridColumns).OnFilterChange) then
    (Collection as TDatabaseGridColumns).OnFilterChange(Self);
end;

function TDatabaseGridColumn.GetEditorKind: TDatabaseGridEditorKind;
begin
  if FEditor <> ekAuto then
    Exit(FEditor);

  if not Assigned(FField) then
    Exit(ekText);

  if FField.FieldKind = fkLookup then
    Result := ekLookup
  else
  if FField is TBooleanField then
    Result := ekCheckBox
  else
  if FField.DataType = ftDate then
    Result := ekDate
  else
  if FField.DataType = ftTime then
    Result := ekTime
  else
  if FField.DataType in [ftDateTime, ftTimeStamp, ftTimeStampOffset] then
    Result := ekDateTime
  else
  if FPickList.Count > 0 then
    Result := ekPickList
  else
    Result := ekText;
end;

function TDatabaseGridColumn.GetImageIndex: Integer;
var
  LIndex: Integer;
begin
  if not Assigned(FImages) or not Assigned(FField) or FField.IsNull then
    Exit(-1);

  if FImageValues.Count > 0 then
    LIndex := FImageValues.IndexOf(FField.Text)
  else
  if not TryStrToInt(FField.AsString, LIndex) then
    LIndex := -1;

  Result := if (LIndex >= 0) and (LIndex < FImages.Count) then LIndex else FUnlistedImageIndex;
end;

function TDatabaseGridColumn.IsImageValuesStored: Boolean;
begin
  Result := FImageValues.Count > 0;
end;

procedure TDatabaseGridColumn.ImageValuesChange(ASender: TObject);
begin
  Changed(False);
end;

function TDatabaseGridColumn.IsPickListStored: Boolean;
begin
  Result := FPickList.Count > 0;
end;

function TDatabaseGridColumn.GetDisplayName: string;
begin
  Result := FFieldName;

  if Result.IsEmpty then
    Result := inherited GetDisplayName;
end;

procedure TDatabaseGridColumn.SetAlignment(const AValue: TAlignment);
begin
  if FAlignment <> AValue then
  begin
    FAlignment := AValue;

    Changed(False);
  end;
end;

procedure TDatabaseGridColumn.SetDropDownRowCount(const AValue: Integer);
begin
  FDropDownRowCount := Max(AValue, 1);
end;

procedure TDatabaseGridColumn.SetFieldName(const AValue: string);
begin
  if FFieldName <> AValue then
  begin
    FFieldName := AValue;
    FField := nil;

    Changed(False);
  end;
end;

procedure TDatabaseGridColumn.SetFooter(const AValue: TDatabaseGridColumnFooter);
begin
  FFooter.Assign(AValue);
end;

procedure TDatabaseGridColumn.SetEditor(const AValue: TDatabaseGridEditorKind);
begin
  if FEditor <> AValue then
  begin
    FEditor := AValue;

    Changed(False);
  end;
end;

procedure TDatabaseGridColumn.SetImages(const AValue: TCustomImageList);
begin
  if FImages <> AValue then
  begin
    FImages := AValue;

    Changed(False);
  end;
end;

procedure TDatabaseGridColumn.SetImageValues(const AValue: TStrings);
begin
  FImageValues.Assign(AValue);
end;

procedure TDatabaseGridColumn.SetOptions(const AValue: TDatabaseGridColumnOptions);
begin
  if FOptions <> AValue then
  begin
    FOptions := AValue;

    Changed(False);
  end;
end;

procedure TDatabaseGridColumn.SetPickList(const AValue: TStrings);
begin
  FPickList.Assign(AValue);
end;

procedure TDatabaseGridColumn.SetTitle(const AValue: TDatabaseGridColumnTitle);
begin
  FTitle.Assign(AValue);
end;

procedure TDatabaseGridColumn.SetUnlistedImageIndex(const AValue: System.UITypes.TImageIndex);
begin
  if FUnlistedImageIndex <> AValue then
  begin
    FUnlistedImageIndex := AValue;

    Changed(False);
  end;
end;

procedure TDatabaseGridColumn.SetVisible(const AValue: Boolean);
begin
  if FVisible <> AValue then
  begin
    FVisible := AValue;

    Changed(False);
  end;
end;

procedure TDatabaseGridColumn.SetWidth(const AValue: Integer);
var
  LWidth: Integer;
begin
  LWidth := Max(AValue, 0);

  if FWidth <> LWidth then
  begin
    FWidth := LWidth;

    Changed(False);
  end;
end;

{ TDatabaseGridColumns }

constructor TDatabaseGridColumns.Create(const AOwner: TPersistent);
begin
  inherited Create(AOwner, TDatabaseGridColumn);
end;

function TDatabaseGridColumns.Add: TDatabaseGridColumn;
begin
  Result := inherited Add as TDatabaseGridColumn;
end;

function TDatabaseGridColumns.Contains(const AColumn: TDatabaseGridColumn): Boolean;
begin
  for var LIndex := 0 to Count - 1 do
  if Items[LIndex] = AColumn then
    Exit(True);

  Result := False;
end;

function TDatabaseGridColumns.FindColumn(const AFieldName: string): TDatabaseGridColumn;
begin
  for var LIndex := 0 to Count - 1 do
  if SameText(Items[LIndex].FieldName, AFieldName) then
    Exit(Items[LIndex]);

  Result := nil;
end;

function TDatabaseGridColumns.MatchesFields(const ADataSet: TDataSet): Boolean;
var
  LColumnIndex: Integer;
begin
  LColumnIndex := 0;

  for var LIndex := 0 to ADataSet.FieldCount - 1 do
  if ADataSet.Fields[LIndex].Visible then
  begin
    if (LColumnIndex >= Count) or not SameText(Items[LColumnIndex].FieldName, ADataSet.Fields[LIndex].FieldName) then
      Exit(False);

    Inc(LColumnIndex);
  end;

  Result := LColumnIndex = Count;
end;

function TDatabaseGridColumns.GetItem(const AIndex: Integer): TDatabaseGridColumn;
begin
  Result := inherited GetItem(AIndex) as TDatabaseGridColumn;
end;

procedure TDatabaseGridColumns.SetItem(const AIndex: Integer; const AValue: TDatabaseGridColumn);
begin
  inherited SetItem(AIndex, AValue);
end;

procedure TDatabaseGridColumns.AddFields(const ADataSet: TDataSet; const ACharWidth, AMaxWidth: Integer);
var
  LColumn: TDatabaseGridColumn;
  LField: TField;
begin
  BeginUpdate;
  try
    for var LIndex := 0 to ADataSet.FieldCount - 1 do
    begin
      LField := ADataSet.Fields[LIndex];

      if LField.Visible then
      begin
        LColumn := Add;
        LColumn.Alignment := LField.Alignment;
        LColumn.FieldName := LField.FieldName;
        LColumn.Width := Min((Max(LField.DisplayWidth, Length(LField.DisplayLabel)) + 2) * ACharWidth, AMaxWidth);
      end;
    end;
  finally
    EndUpdate;
  end;
end;

procedure TDatabaseGridColumns.BindFields(const ADataSet: TDataSet);
var
  LColumn: TDatabaseGridColumn;
begin
  for var LIndex := 0 to Count - 1 do
  begin
    LColumn := Items[LIndex];

    if Assigned(ADataSet) and not LColumn.FieldName.IsEmpty then
      LColumn.Field := ADataSet.FindField(LColumn.FieldName)
    else
      LColumn.Field := nil;

    if Assigned(ADataSet) and not LColumn.Footer.FieldName.IsEmpty then
      LColumn.Footer.Field := ADataSet.FindField(LColumn.Footer.FieldName)
    else
      LColumn.Footer.Field := LColumn.Field;
  end;
end;

procedure TDatabaseGridColumns.ChangeScale(const AMultiplier, ADivider: Integer);
begin
  BeginUpdate;
  try
    for var LIndex := 0 to Count - 1 do
      Items[LIndex].Width := MulDiv(Items[LIndex].Width, AMultiplier, ADivider);
  finally
    EndUpdate;
  end;
end;

procedure TDatabaseGridColumns.ClearAutoCreated;
begin
  if not FAutoCreated then
    Exit;

  FAutoCreated := False;

  Clear;
end;

procedure TDatabaseGridColumns.CreateFromFields(const ADataSet: TDataSet; const ACharWidth, AMaxWidth: Integer);
begin
  FAutoCreating := True;
  BeginUpdate;
  try
    Clear;
    AddFields(ADataSet, ACharWidth, AMaxWidth);
  finally
    EndUpdate;
    FAutoCreating := False;
  end;

  FAutoCreated := True;
end;

procedure TDatabaseGridColumns.Notify(AItem: TCollectionItem; AAction: TCollectionNotification);
begin
  inherited Notify(AItem, AAction);

  if (AAction = cnAdded) and FAutoCreated and not FAutoCreating then
  begin
    FAutoCreated := False;

    BeginUpdate;
    try
      for var LIndex := Count - 1 downto 0 do
      if Items[LIndex] <> AItem then
        Items[LIndex].Free;
    finally
      EndUpdate;
    end;
  end;
end;

procedure TDatabaseGridColumns.Update(AItem: TCollectionItem);
begin
  inherited Update(AItem);

  if Assigned(FOnChange) then
    FOnChange(Self);
end;

end.
