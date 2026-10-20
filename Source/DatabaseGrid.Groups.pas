unit DatabaseGrid.Groups;

interface

uses
  System.Classes, System.Generics.Collections, Data.DB, DatabaseGrid.DataLink;

type
  TDatabaseGridGroups = class;

  TDatabaseGridGroupNode = class(TObject)
  strict private
    FExpanded: Boolean;
    FField: TField;
    FFirstPosition: Integer;
    FGroups: TDatabaseGridGroups;
    FItems: TList<TDatabaseGridGroupNode>;
    FKeyPath: string;
    FLevel: Integer;
    FParent: TDatabaseGridGroupNode;
    FRecordCount: Integer;
    FRow: Integer;
    FText: string;
    FValue: Variant;
    function GetCount: Integer;
    function GetFirstRecord: Integer;
    function GetItem(const AIndex: Integer): TDatabaseGridGroupNode;
    procedure SetExpanded(const AValue: Boolean);
  private
    function ChangeExpanded(const AValue: Boolean): Boolean;
    function ContainsRecord(const ARecordIndex: Integer): Boolean;
    procedure AddItem(const ANode: TDatabaseGridGroupNode);
    procedure AddRecord;
    procedure SetRow(const AValue: Integer);
    property FirstPosition: Integer read FFirstPosition;
    property FirstRecord: Integer read GetFirstRecord;
    property KeyPath: string read FKeyPath;
  public
    constructor Create(const AGroups: TDatabaseGridGroups; const AParent: TDatabaseGridGroupNode; const AField: TField;
      const ALevel, AFirstPosition: Integer; const AValue: Variant; const AText, AKeyPath: string; const AExpanded: Boolean);
    destructor Destroy; override;
    property Count: Integer read GetCount;
    property Expanded: Boolean read FExpanded write SetExpanded;
    property Field: TField read FField;
    property Items[const AIndex: Integer]: TDatabaseGridGroupNode read GetItem; default;
    property Level: Integer read FLevel;
    property Parent: TDatabaseGridGroupNode read FParent;
    property RecordCount: Integer read FRecordCount;
    property Row: Integer read FRow;
    property Text: string read FText;
    property Value: Variant read FValue;
  end;

  TDatabaseGridGroupRow = record
    Node: TDatabaseGridGroupNode;
    RecordIndex: Integer;
  end;

  TDatabaseGridGroupNodeEvent = procedure(ASender: TObject; const ANode: TDatabaseGridGroupNode) of object;

  TDatabaseGridGroups = class(TObject)
  strict private
    FActive: Boolean;
    FBuildCount: Integer;
    FDataLink: TDatabaseGridDataLink;
    FFocusedNode: TDatabaseGridGroupNode;
    FItems: TList<TDatabaseGridGroupNode>;
    FLevelCount: Integer;
    FNodes: TObjectList<TDatabaseGridGroupNode>;
    FOnChange: TNotifyEvent;
    FOnExpandedChange: TDatabaseGridGroupNodeEvent;
    FRecordNodes: TArray<TDatabaseGridGroupNode>;
    FRecordPositions: TArray<Integer>;
    FRecordRows: TArray<Integer>;
    FRowCount: Integer;
    FRows: TArray<TDatabaseGridGroupRow>;
    FSortedRecords: TArray<Integer>;
    function FindNode(const AKeyPath: string): TDatabaseGridGroupNode;
    function GetCount: Integer;
    function GetCurrentNode: TDatabaseGridGroupNode;
    function GetFocusedNode: TDatabaseGridGroupNode;
    function GetFocusedRow: Integer;
    function GetItem(const AIndex: Integer): TDatabaseGridGroupNode;
    function GetNode(const AIndex: Integer): TDatabaseGridGroupNode;
    function GetNodeCount: Integer;
    function GetRecordCount: Integer;
    function GetRow(const AIndex: Integer): TDatabaseGridGroupRow;
    function ReadValues(const AFields: TArray<TField>): TArray<TArray<Variant>>;
    procedure CreateNodes(const AFields: TArray<TField>; const AValues: TArray<TArray<Variant>>;
      const AExpandedStates: TDictionary<string, Boolean>; const ADefaultExpanded: Boolean);
    procedure DoChange;
    procedure SetAllExpanded(const AValue: Boolean);
    procedure SetFocusedNode(const AValue: TDatabaseGridGroupNode);
    procedure SortRecords(const AValues: TArray<TArray<Variant>>; const ADescending: TArray<Boolean>);
    procedure UpdateRows;
  private
    function GetRecordPosition(const ARecordIndex: Integer): Integer;
    function GetSortedRecord(const APosition: Integer): Integer;
    procedure ExpandedChanged(const ANodes: TArray<TDatabaseGridGroupNode>);
  public
    constructor Create(const ADataLink: TDatabaseGridDataLink);
    destructor Destroy; override;
    function GetRecordRow(const ARecordIndex: Integer): Integer;
    function GetRowNode(const ARow: Integer): TDatabaseGridGroupNode;
    procedure Build(const AFields: TArray<TField>; const ADescending: TArray<Boolean>; const ADefaultExpanded: Boolean);
    procedure Clear;
    procedure CollapseAll;
    procedure ExpandAll;
    procedure SynchronizeFocus;
    property Active: Boolean read FActive;
    property Count: Integer read GetCount;
    property CurrentNode: TDatabaseGridGroupNode read GetCurrentNode;
    property FocusedNode: TDatabaseGridGroupNode read GetFocusedNode write SetFocusedNode;
    property FocusedRow: Integer read GetFocusedRow;
    property Items[const AIndex: Integer]: TDatabaseGridGroupNode read GetItem; default;
    property LevelCount: Integer read FLevelCount;
    property NodeCount: Integer read GetNodeCount;
    property Nodes[const AIndex: Integer]: TDatabaseGridGroupNode read GetNode;
    property OnChange: TNotifyEvent read FOnChange write FOnChange;
    property OnExpandedChange: TDatabaseGridGroupNodeEvent read FOnExpandedChange write FOnExpandedChange;
    property RecordCount: Integer read GetRecordCount;
    property RowCount: Integer read FRowCount;
    property Rows[const AIndex: Integer]: TDatabaseGridGroupRow read GetRow;
  end;

implementation

uses
  System.Generics.Defaults, System.SysUtils, System.Variants, DatabaseGrid.Consts;

const
  GROUP_KEY_NULL = TControlCharacters.StartOfHeading;
  GROUP_KEY_SEPARATOR = TControlCharacters.Null;

function CompareGroupValues(const ALeft, ARight: Variant): Integer;
var
  LLeftNull, LRightNull: Boolean;
begin
  LLeftNull := VarIsNull(ALeft) or VarIsEmpty(ALeft);
  LRightNull := VarIsNull(ARight) or VarIsEmpty(ARight);

  if LLeftNull or LRightNull then
    Exit(Ord(LRightNull) - Ord(LLeftNull));

  if VarIsStr(ALeft) and VarIsStr(ARight) then
  begin
    Result := CompareText(VarToStr(ALeft), VarToStr(ARight), loUserLocale);

    if Result = 0 then
      Result := CompareStr(VarToStr(ALeft), VarToStr(ARight));

    Exit;
  end;

  case VarCompareValue(ALeft, ARight) of
    vrLessThan:
      Result := -1;
    vrGreaterThan:
      Result := 1;
    vrEqual:
      Result := 0;
  else
    Result := CompareStr(VarToStr(ALeft), VarToStr(ARight));
  end;
end;

function GetGroupKeyText(const AValue: Variant): string;
begin
  if VarIsNull(AValue) or VarIsEmpty(AValue) then
    Result := GROUP_KEY_NULL
  else
    Result := VarToStr(AValue);
end;

{ TDatabaseGridGroupNode }

constructor TDatabaseGridGroupNode.Create(const AGroups: TDatabaseGridGroups; const AParent: TDatabaseGridGroupNode; const AField: TField;
  const ALevel, AFirstPosition: Integer; const AValue: Variant; const AText, AKeyPath: string; const AExpanded: Boolean);
begin
  inherited Create;

  FGroups := AGroups;
  FParent := AParent;
  FField := AField;
  FLevel := ALevel;
  FFirstPosition := AFirstPosition;
  FValue := AValue;
  FText := AText;
  FKeyPath := AKeyPath;
  FExpanded := AExpanded;
  FRow := -1;
  FItems := TList<TDatabaseGridGroupNode>.Create;
end;

destructor TDatabaseGridGroupNode.Destroy;
begin
  FItems.Free;

  inherited Destroy;
end;

function TDatabaseGridGroupNode.ChangeExpanded(const AValue: Boolean): Boolean;
begin
  Result := FExpanded <> AValue;

  FExpanded := AValue;
end;

function TDatabaseGridGroupNode.ContainsRecord(const ARecordIndex: Integer): Boolean;
var
  LPosition: Integer;
begin
  LPosition := FGroups.GetRecordPosition(ARecordIndex);

  Result := (LPosition >= FFirstPosition) and (LPosition < FFirstPosition + FRecordCount);
end;

function TDatabaseGridGroupNode.GetCount: Integer;
begin
  Result := FItems.Count;
end;

function TDatabaseGridGroupNode.GetFirstRecord: Integer;
begin
  Result := FGroups.GetSortedRecord(FFirstPosition);
end;

function TDatabaseGridGroupNode.GetItem(const AIndex: Integer): TDatabaseGridGroupNode;
begin
  Result := FItems[AIndex];
end;

procedure TDatabaseGridGroupNode.AddItem(const ANode: TDatabaseGridGroupNode);
begin
  FItems.Add(ANode);
end;

procedure TDatabaseGridGroupNode.AddRecord;
var
  LNode: TDatabaseGridGroupNode;
begin
  LNode := Self;

  while Assigned(LNode) do
  begin
    Inc(LNode.FRecordCount);

    LNode := LNode.FParent;
  end;
end;

procedure TDatabaseGridGroupNode.SetRow(const AValue: Integer);
begin
  FRow := AValue;
end;

procedure TDatabaseGridGroupNode.SetExpanded(const AValue: Boolean);
var
  LChangedNodes: TArray<TDatabaseGridGroupNode>;
  LNode: TDatabaseGridGroupNode;
begin
  LChangedNodes := nil;

  if AValue then
  begin
    LNode := Self;

    while Assigned(LNode) do
    begin
      if LNode.ChangeExpanded(True) then
        LChangedNodes := LChangedNodes + [LNode];

      LNode := LNode.FParent;
    end;
  end
  else
  if ChangeExpanded(False) then
    LChangedNodes := [Self];

  if Length(LChangedNodes) > 0 then
    FGroups.ExpandedChanged(LChangedNodes);
end;

{ TDatabaseGridGroups }

constructor TDatabaseGridGroups.Create(const ADataLink: TDatabaseGridDataLink);
begin
  inherited Create;

  FDataLink := ADataLink;
  FItems := TList<TDatabaseGridGroupNode>.Create;
  FNodes := TObjectList<TDatabaseGridGroupNode>.Create(True);
end;

destructor TDatabaseGridGroups.Destroy;
begin
  FItems.Free;
  FNodes.Free;

  inherited Destroy;
end;

function TDatabaseGridGroups.FindNode(const AKeyPath: string): TDatabaseGridGroupNode;
begin
  for var LIndex := 0 to FNodes.Count - 1 do
  if FNodes[LIndex].KeyPath = AKeyPath then
    Exit(FNodes[LIndex]);

  Result := nil;
end;

function TDatabaseGridGroups.GetCount: Integer;
begin
  Result := FItems.Count;
end;

function TDatabaseGridGroups.GetCurrentNode: TDatabaseGridGroupNode;
var
  LRecordIndex: Integer;
begin
  Result := nil;

  if FActive and FDataLink.Active then
  begin
    LRecordIndex := FDataLink.ActiveRecord;

    if (LRecordIndex >= 0) and (LRecordIndex < Length(FRecordNodes)) then
      Result := FRecordNodes[LRecordIndex];
  end;
end;

function TDatabaseGridGroups.GetFocusedNode: TDatabaseGridGroupNode;
begin
  Result := GetRowNode(GetFocusedRow);
end;

function TDatabaseGridGroups.GetFocusedRow: Integer;
var
  LRecordIndex: Integer;
begin
  if not FActive or not FDataLink.Active then
    Exit(-1);

  LRecordIndex := FDataLink.ActiveRecord;

  if Assigned(FFocusedNode) and (FFocusedNode.Row >= 0) and FFocusedNode.ContainsRecord(LRecordIndex) then
    Result := FFocusedNode.Row
  else
    Result := GetRecordRow(LRecordIndex);
end;

function TDatabaseGridGroups.GetItem(const AIndex: Integer): TDatabaseGridGroupNode;
begin
  Result := FItems[AIndex];
end;

function TDatabaseGridGroups.GetNode(const AIndex: Integer): TDatabaseGridGroupNode;
begin
  Result := FNodes[AIndex];
end;

function TDatabaseGridGroups.GetNodeCount: Integer;
begin
  Result := FNodes.Count;
end;

function TDatabaseGridGroups.GetRecordCount: Integer;
begin
  Result := Length(FSortedRecords);
end;

function TDatabaseGridGroups.GetRecordPosition(const ARecordIndex: Integer): Integer;
begin
  if (ARecordIndex >= 0) and (ARecordIndex < Length(FRecordPositions)) then
    Result := FRecordPositions[ARecordIndex]
  else
    Result := -1;
end;

function TDatabaseGridGroups.GetRecordRow(const ARecordIndex: Integer): Integer;
var
  LNode: TDatabaseGridGroupNode;
begin
  if (ARecordIndex < 0) or (ARecordIndex >= Length(FRecordNodes)) then
    Exit(-1);

  Result := FRecordRows[ARecordIndex];
  LNode := FRecordNodes[ARecordIndex];

  while Assigned(LNode) do
  begin
    if not LNode.Expanded then
      Result := LNode.Row;

    LNode := LNode.Parent;
  end;
end;

function TDatabaseGridGroups.GetRow(const AIndex: Integer): TDatabaseGridGroupRow;
begin
  Result := FRows[AIndex];
end;

function TDatabaseGridGroups.GetRowNode(const ARow: Integer): TDatabaseGridGroupNode;
begin
  if (ARow >= 0) and (ARow < FRowCount) then
    Result := FRows[ARow].Node
  else
    Result := nil;
end;

function TDatabaseGridGroups.GetSortedRecord(const APosition: Integer): Integer;
begin
  Result := FSortedRecords[APosition];
end;

function TDatabaseGridGroups.ReadValues(const AFields: TArray<TField>): TArray<TArray<Variant>>;
var
  LRecordCount: Integer;
begin
  LRecordCount := Length(FSortedRecords);

  SetLength(Result, Length(AFields), LRecordCount);

  for var LRecordIndex := 0 to LRecordCount - 1 do
  begin
    FDataLink.ActiveRecord := LRecordIndex;

    for var LLevel := 0 to High(AFields) do
      Result[LLevel][LRecordIndex] := AFields[LLevel].Value;
  end;
end;

procedure TDatabaseGridGroups.Build(const AFields: TArray<TField>; const ADescending: TArray<Boolean>;
  const ADefaultExpanded: Boolean);
var
  LActiveRecord: Integer;
  LExpandedStates: TDictionary<string, Boolean>;
  LFocusedKeyPath: string;
  LValues: TArray<TArray<Variant>>;
begin
  LFocusedKeyPath := '';

  if Assigned(FFocusedNode) then
    LFocusedKeyPath := FFocusedNode.KeyPath;

  LExpandedStates := TDictionary<string, Boolean>.Create;
  try
    for var LIndex := 0 to FNodes.Count - 1 do
      LExpandedStates.AddOrSetValue(FNodes[LIndex].KeyPath, FNodes[LIndex].Expanded);

    Clear;

    if not FDataLink.Active or (Length(AFields) = 0) then
      Exit;

    FActive := True;
    FLevelCount := Length(AFields);

    SetLength(FSortedRecords, FDataLink.BufferedRowCount);

    LActiveRecord := FDataLink.ActiveRecord;
    try
      LValues := ReadValues(AFields);

      SortRecords(LValues, ADescending);
      CreateNodes(AFields, LValues, LExpandedStates, ADefaultExpanded);
    finally
      FDataLink.ActiveRecord := LActiveRecord;
    end;
  finally
    LExpandedStates.Free;
  end;

  UpdateRows;

  if not LFocusedKeyPath.IsEmpty then
    FFocusedNode := FindNode(LFocusedKeyPath);

  SynchronizeFocus;
end;

procedure TDatabaseGridGroups.Clear;
begin
  Inc(FBuildCount);

  FActive := False;
  FLevelCount := 0;
  FFocusedNode := nil;
  FRowCount := 0;
  FRows := nil;
  FRecordNodes := nil;
  FRecordPositions := nil;
  FRecordRows := nil;
  FSortedRecords := nil;

  FItems.Clear;
  FNodes.Clear;
end;

procedure TDatabaseGridGroups.CollapseAll;
begin
  SetAllExpanded(False);
end;

procedure TDatabaseGridGroups.CreateNodes(const AFields: TArray<TField>; const AValues: TArray<TArray<Variant>>;
  const AExpandedStates: TDictionary<string, Boolean>; const ADefaultExpanded: Boolean);
var
  LExpanded: Boolean;
  LFirstChangedLevel, LPreviousRecord, LRecordIndex: Integer;
  LKeyPath: string;
  LLevelNodes: TArray<TDatabaseGridGroupNode>;
  LNode, LParent: TDatabaseGridGroupNode;
begin
  SetLength(LLevelNodes, FLevelCount);
  SetLength(FRecordNodes, Length(FSortedRecords));

  LPreviousRecord := -1;

  for var LPosition := 0 to High(FSortedRecords) do
  begin
    LRecordIndex := FSortedRecords[LPosition];
    LFirstChangedLevel := 0;

    if LPreviousRecord >= 0 then
    begin
      LFirstChangedLevel := FLevelCount;

      for var LLevel := 0 to FLevelCount - 1 do
      if CompareGroupValues(AValues[LLevel][LRecordIndex], AValues[LLevel][LPreviousRecord]) <> 0 then
      begin
        LFirstChangedLevel := LLevel;

        Break;
      end;
    end;

    if LFirstChangedLevel < FLevelCount then
      FDataLink.ActiveRecord := LRecordIndex;

    for var LLevel := LFirstChangedLevel to FLevelCount - 1 do
    begin
      LParent := if LLevel > 0 then LLevelNodes[LLevel - 1] else nil;
      LKeyPath := GetGroupKeyText(AValues[LLevel][LRecordIndex]);

      if Assigned(LParent) then
        LKeyPath := LParent.KeyPath + GROUP_KEY_SEPARATOR + LKeyPath;

      if not AExpandedStates.TryGetValue(LKeyPath, LExpanded) then
        LExpanded := ADefaultExpanded;

      LNode := TDatabaseGridGroupNode.Create(Self, LParent, AFields[LLevel], LLevel, LPosition, AValues[LLevel][LRecordIndex],
        AFields[LLevel].DisplayText, LKeyPath, LExpanded);

      FNodes.Add(LNode);

      if Assigned(LParent) then
        LParent.AddItem(LNode)
      else
        FItems.Add(LNode);

      LLevelNodes[LLevel] := LNode;
    end;

    LNode := LLevelNodes[FLevelCount - 1];
    LNode.AddRecord;

    FRecordNodes[LRecordIndex] := LNode;

    LPreviousRecord := LRecordIndex;
  end;
end;

procedure TDatabaseGridGroups.DoChange;
begin
  if Assigned(FOnChange) then
    FOnChange(Self);
end;

procedure TDatabaseGridGroups.ExpandAll;
begin
  SetAllExpanded(True);
end;

procedure TDatabaseGridGroups.ExpandedChanged(const ANodes: TArray<TDatabaseGridGroupNode>);
var
  LBuildCount: Integer;
begin
  LBuildCount := FBuildCount;

  UpdateRows;
  SynchronizeFocus;
  DoChange;

  for var LIndex := 0 to High(ANodes) do
  begin
    if (FBuildCount <> LBuildCount) or not Assigned(FOnExpandedChange) then
      Break;

    FOnExpandedChange(Self, ANodes[LIndex]);
  end;
end;

procedure TDatabaseGridGroups.SetAllExpanded(const AValue: Boolean);
var
  LChangedNodes: TArray<TDatabaseGridGroupNode>;
begin
  LChangedNodes := nil;

  for var LIndex := 0 to FNodes.Count - 1 do
  if FNodes[LIndex].ChangeExpanded(AValue) then
    LChangedNodes := LChangedNodes + [FNodes[LIndex]];

  if Length(LChangedNodes) > 0 then
    ExpandedChanged(LChangedNodes);
end;

procedure TDatabaseGridGroups.SetFocusedNode(const AValue: TDatabaseGridGroupNode);
begin
  if not Assigned(AValue) or FNodes.Contains(AValue) then
    FFocusedNode := AValue;
end;

procedure TDatabaseGridGroups.SortRecords(const AValues: TArray<TArray<Variant>>; const ADescending: TArray<Boolean>);
var
  LDescending: TArray<Boolean>;
  LValues: TArray<TArray<Variant>>;
begin
  LDescending := ADescending;
  LValues := AValues;

  for var LIndex := 0 to High(FSortedRecords) do
    FSortedRecords[LIndex] := LIndex;

  TArray.Sort<Integer>(FSortedRecords, TComparer<Integer>.Construct(
    function(const ALeft, ARight: Integer): Integer
    begin
      for var LLevel := 0 to High(LValues) do
      begin
        Result := CompareGroupValues(LValues[LLevel][ALeft], LValues[LLevel][ARight]);

        if Result <> 0 then
        begin
          if (LLevel < Length(LDescending)) and LDescending[LLevel] then
            Result := -Result;

          Exit;
        end;
      end;

      Result := ALeft - ARight;
    end));

  SetLength(FRecordPositions, Length(FSortedRecords));

  for var LPosition := 0 to High(FSortedRecords) do
    FRecordPositions[FSortedRecords[LPosition]] := LPosition;
end;

procedure TDatabaseGridGroups.SynchronizeFocus;
begin
  if Assigned(FFocusedNode) and ((FFocusedNode.Row < 0) or not FDataLink.Active or
    not FFocusedNode.ContainsRecord(FDataLink.ActiveRecord)) then
    FFocusedNode := nil;
end;

procedure TDatabaseGridGroups.UpdateRows;
var
  LRowCount: Integer;

  procedure AddRow(const ANode: TDatabaseGridGroupNode; const ARecordIndex: Integer);
  begin
    FRows[LRowCount].Node := ANode;
    FRows[LRowCount].RecordIndex := ARecordIndex;

    Inc(LRowCount);
  end;

  procedure AddNodeRows(const ANode: TDatabaseGridGroupNode);
  var
    LRecordIndex: Integer;
  begin
    ANode.SetRow(LRowCount);

    AddRow(ANode, ANode.FirstRecord);

    if not ANode.Expanded then
      Exit;

    for var LIndex := 0 to ANode.Count - 1 do
      AddNodeRows(ANode[LIndex]);

    if ANode.Count > 0 then
      Exit;

    for var LPosition := ANode.FirstPosition to ANode.FirstPosition + ANode.RecordCount - 1 do
    begin
      LRecordIndex := FSortedRecords[LPosition];
      FRecordRows[LRecordIndex] := LRowCount;

      AddRow(nil, LRecordIndex);
    end;
  end;

begin
  for var LIndex := 0 to FNodes.Count - 1 do
    FNodes[LIndex].SetRow(-1);

  SetLength(FRecordRows, Length(FSortedRecords));

  for var LIndex := 0 to High(FRecordRows) do
    FRecordRows[LIndex] := -1;

  SetLength(FRows, FNodes.Count + Length(FSortedRecords));

  LRowCount := 0;

  for var LIndex := 0 to FItems.Count - 1 do
    AddNodeRows(FItems[LIndex]);

  FRowCount := LRowCount;
end;

end.
