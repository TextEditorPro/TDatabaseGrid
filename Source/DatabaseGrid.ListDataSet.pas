unit DatabaseGrid.ListDataSet;

interface

uses
  System.Classes, System.Generics.Collections, Data.DB;

type
  TDatabaseGridListDataSet = class(TDataSet)
  strict private type
    PDatabaseGridListRecord = ^TDatabaseGridListRecord;
    TDatabaseGridListRecord = record
      BookmarkFlag: TBookmarkFlag;
      RowIndex: Integer;
    end;
  strict private
    FCurrent: Integer;
    FFilterRowIndex: Integer;
    FOpen: Boolean;
    FRows: TList<TArray<string>>;
    FView: TList<Integer>;
    function GetActiveRowIndex: Integer;
    function IsRowAccepted(const ARowIndex: Integer): Boolean;
    procedure UpdateView;
  protected
    function AllocRecordBuffer: TRecordBuffer; override;
    function GetBookmarkFlag(ABuffer: TRecBuf): TBookmarkFlag; override;
    function GetCanModify: Boolean; override;
    function GetRecNo: Integer; override;
    function GetRecord(ABuffer: TRecBuf; AGetMode: TGetMode; ADoCheck: Boolean): TGetResult; override;
    function GetRecordCount: Integer; override;
    function IsCursorOpen: Boolean; override;
    procedure FreeRecordBuffer(var ABuffer: TRecordBuffer); override;
    procedure GetBookmarkData(ABuffer: TRecBuf; AData: TBookmark); override;
    procedure InternalClose; override;
    procedure InternalFirst; override;
    procedure InternalGotoBookmark(ABookmark: TBookmark); override;
    procedure InternalHandleException; override;
    procedure InternalInitFieldDefs; override;
    procedure InternalInitRecord(ABuffer: TRecBuf); override;
    procedure InternalLast; override;
    procedure InternalOpen; override;
    procedure InternalSetToRecord(ABuffer: TRecBuf); override;
    procedure SetBookmarkData(ABuffer: TRecBuf; AData: TBookmark); override;
    procedure SetBookmarkFlag(ABuffer: TRecBuf; AValue: TBookmarkFlag); override;
    procedure SetFiltered(AValue: Boolean); override;
    procedure SetOnFilterRecord(const AValue: TFilterRecordEvent); override;
    procedure SetRecNo(AValue: Integer); override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    function BookmarkValid(ABookmark: TBookmark): Boolean; override;
    function CompareBookmarks(ABookmark1, ABookmark2: TBookmark): Integer; override;
    function GetFieldData(AField: TField; var ABuffer: TValueBuffer): Boolean; override;
    procedure AddRow(const AValues: array of string);
    property RowIndex: Integer read GetActiveRowIndex;
  end;

implementation

uses
  System.Math, System.SysUtils, DatabaseGrid.Consts;

constructor TDatabaseGridListDataSet.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);

  FRows := TList<TArray<string>>.Create;
  FView := TList<Integer>.Create;
  FCurrent := -1;
end;

destructor TDatabaseGridListDataSet.Destroy;
begin
  Close;

  FRows.Free;
  FView.Free;

  inherited Destroy;
end;

function TDatabaseGridListDataSet.AllocRecordBuffer: TRecordBuffer;
begin
  Result := AllocMem(SizeOf(TDatabaseGridListRecord));
end;

function TDatabaseGridListDataSet.BookmarkValid(ABookmark: TBookmark): Boolean;
begin
  Result := (Length(ABookmark) = SizeOf(Integer)) and FView.Contains(PInteger(@ABookmark[0])^);
end;

function TDatabaseGridListDataSet.CompareBookmarks(ABookmark1, ABookmark2: TBookmark): Integer;
begin
  if Length(ABookmark1) < SizeOf(Integer) then
    Result := if Length(ABookmark2) < SizeOf(Integer) then 0 else -1
  else
  if Length(ABookmark2) < SizeOf(Integer) then
    Result := 1
  else
    Result := CompareValue(PInteger(@ABookmark1[0])^, PInteger(@ABookmark2[0])^);
end;

function TDatabaseGridListDataSet.GetActiveRowIndex: Integer;
begin
  if not Active or IsEmpty then
    Exit(-1);

  Result := PDatabaseGridListRecord(ActiveBuffer).RowIndex;
end;

function TDatabaseGridListDataSet.GetBookmarkFlag(ABuffer: TRecBuf): TBookmarkFlag;
begin
  Result := PDatabaseGridListRecord(ABuffer).BookmarkFlag;
end;

function TDatabaseGridListDataSet.GetCanModify: Boolean;
begin
  Result := False;
end;

function TDatabaseGridListDataSet.GetFieldData(AField: TField; var ABuffer: TValueBuffer): Boolean;
var
  LLength, LRowIndex: Integer;
  LText: string;
begin
  if State = dsFilter then
    LRowIndex := FFilterRowIndex
  else
    LRowIndex := GetActiveRowIndex;

  if (LRowIndex < 0) or (AField.FieldNo < 1) or (AField.FieldNo > Length(FRows[LRowIndex])) then
    Exit(False);

  LText := FRows[LRowIndex][AField.FieldNo - 1];

  if Length(ABuffer) > 0 then
  begin
    LLength := Min(Min(Length(LText), AField.Size), Length(ABuffer) div SizeOf(Char) - 1);

    if LLength > 0 then
      Move(PChar(LText)^, ABuffer[0], LLength * SizeOf(Char));

    PChar(@ABuffer[LLength * SizeOf(Char)])^ := TControlCharacters.Null;
  end;

  Result := True;
end;

function TDatabaseGridListDataSet.GetRecNo: Integer;
var
  LRowIndex: Integer;
begin
  LRowIndex := GetActiveRowIndex;

  if LRowIndex < 0 then
    Result := -1
  else
    Result := FView.IndexOf(LRowIndex) + 1;
end;

function TDatabaseGridListDataSet.GetRecord(ABuffer: TRecBuf; AGetMode: TGetMode; ADoCheck: Boolean): TGetResult;
begin
  Result := grOK;

  case AGetMode of
    gmNext:
      if FCurrent >= FView.Count - 1 then
        Result := grEOF
      else
        Inc(FCurrent);
    gmPrior:
      if FCurrent <= 0 then
        Result := grBOF
      else
        Dec(FCurrent);
    gmCurrent:
      if (FCurrent < 0) or (FCurrent >= FView.Count) then
        Result := grError;
  end;

  if Result = grOK then
  begin
    PDatabaseGridListRecord(ABuffer).RowIndex := FView[FCurrent];
    PDatabaseGridListRecord(ABuffer).BookmarkFlag := bfCurrent;
  end;
end;

function TDatabaseGridListDataSet.GetRecordCount: Integer;
begin
  Result := FView.Count;
end;

function TDatabaseGridListDataSet.IsCursorOpen: Boolean;
begin
  Result := FOpen;
end;

function TDatabaseGridListDataSet.IsRowAccepted(const ARowIndex: Integer): Boolean;
var
  LState: TDataSetState;
begin
  Result := True;

  if not Filtered or not Assigned(OnFilterRecord) then
    Exit;

  FFilterRowIndex := ARowIndex;
  LState := SetTempState(dsFilter);
  try
    OnFilterRecord(Self, Result);
  finally
    RestoreState(LState);
  end;
end;

procedure TDatabaseGridListDataSet.AddRow(const AValues: array of string);
var
  LRow: TArray<string>;
begin
  SetLength(LRow, Length(AValues));

  for var LIndex := 0 to High(AValues) do
    LRow[LIndex] := AValues[LIndex];

  FRows.Add(LRow);

  if Active then
  begin
    UpdateView;
    Resync([]);
  end;
end;

procedure TDatabaseGridListDataSet.FreeRecordBuffer(var ABuffer: TRecordBuffer);
begin
  FreeMem(ABuffer);
  ABuffer := nil;
end;

procedure TDatabaseGridListDataSet.GetBookmarkData(ABuffer: TRecBuf; AData: TBookmark);
begin
  PInteger(@AData[0])^ := PDatabaseGridListRecord(ABuffer).RowIndex;
end;

procedure TDatabaseGridListDataSet.InternalClose;
begin
  FOpen := False;
  FCurrent := -1;

  BindFields(False);
  DestroyFields;
end;

procedure TDatabaseGridListDataSet.InternalFirst;
begin
  FCurrent := -1;
end;

procedure TDatabaseGridListDataSet.InternalGotoBookmark(ABookmark: TBookmark);
begin
  FCurrent := FView.IndexOf(PInteger(@ABookmark[0])^);
end;

procedure TDatabaseGridListDataSet.InternalHandleException;
begin
  if Assigned(System.Classes.ApplicationHandleException) then
    System.Classes.ApplicationHandleException(Self);
end;

procedure TDatabaseGridListDataSet.InternalInitFieldDefs;
begin
end;

procedure TDatabaseGridListDataSet.InternalInitRecord(ABuffer: TRecBuf);
begin
  PDatabaseGridListRecord(ABuffer).RowIndex := -1;
  PDatabaseGridListRecord(ABuffer).BookmarkFlag := bfCurrent;
end;

procedure TDatabaseGridListDataSet.InternalLast;
begin
  FCurrent := FView.Count;
end;

procedure TDatabaseGridListDataSet.InternalOpen;
begin
  FCurrent := -1;
  BookmarkSize := SizeOf(Integer);

  InternalInitFieldDefs;
  CreateFields;
  BindFields(True);
  UpdateView;

  FOpen := True;
end;

procedure TDatabaseGridListDataSet.InternalSetToRecord(ABuffer: TRecBuf);
begin
  FCurrent := FView.IndexOf(PDatabaseGridListRecord(ABuffer).RowIndex);
end;

procedure TDatabaseGridListDataSet.SetBookmarkData(ABuffer: TRecBuf; AData: TBookmark);
begin
  PDatabaseGridListRecord(ABuffer).RowIndex := PInteger(@AData[0])^;
end;

procedure TDatabaseGridListDataSet.SetBookmarkFlag(ABuffer: TRecBuf; AValue: TBookmarkFlag);
begin
  PDatabaseGridListRecord(ABuffer).BookmarkFlag := AValue;
end;

procedure TDatabaseGridListDataSet.SetFiltered(AValue: Boolean);
begin
  inherited SetFiltered(AValue);

  if Active then
  begin
    UpdateView;
    First;
  end;
end;

procedure TDatabaseGridListDataSet.SetOnFilterRecord(const AValue: TFilterRecordEvent);
begin
  inherited SetOnFilterRecord(AValue);

  if Active and Filtered then
  begin
    UpdateView;
    First;
  end;
end;

procedure TDatabaseGridListDataSet.SetRecNo(AValue: Integer);
begin
  CheckBrowseMode;

  if (AValue < 1) or (AValue > FView.Count) or (AValue = RecNo) then
    Exit;

  DoBeforeScroll;

  FCurrent := AValue - 1;

  Resync([rmCenter]);
  DoAfterScroll;
end;

procedure TDatabaseGridListDataSet.UpdateView;
begin
  FView.Clear;

  for var LRowIndex := 0 to FRows.Count - 1 do
  if IsRowAccepted(LRowIndex) then
    FView.Add(LRowIndex);
end;

end.
