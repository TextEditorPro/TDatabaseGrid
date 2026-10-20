unit DatabaseGrid.SelectedRows;

interface

uses
  System.Classes, System.Generics.Collections, Data.DB;

type
  TDatabaseGridSelectedRows = class(TObject)
  strict private
    FChanged: Boolean;
    FDataLink: TDataLink;
    FItems: TList<TBookmark>;
    FOnChange: TNotifyEvent;
    FUpdateCount: Integer;
    function GetCount: Integer;
    function GetCurrentRowSelected: Boolean;
    function GetItem(const AIndex: Integer): TBookmark;
    function GetDataSetBookmarks: TArray<TBookmark>;
    function TryFind(const ABookmark: TBookmark; out AIndex: Integer): Boolean;
    procedure DoChange;
    procedure SetCurrentRowSelected(const AValue: Boolean);
  public
    constructor Create(const ADataLink: TDataLink);
    destructor Destroy; override;
    function IsSelected(const ABookmark: TBookmark): Boolean;
    procedure BeginUpdate;
    procedure Clear;
    procedure EndUpdate;
    procedure Invert;
    procedure Refresh;
    procedure Select(const ABookmark: TBookmark; const ASelected: Boolean);
    procedure SelectAll;
    property Count: Integer read GetCount;
    property CurrentRowSelected: Boolean read GetCurrentRowSelected write SetCurrentRowSelected;
    property Items[const AIndex: Integer]: TBookmark read GetItem; default;
    property OnChange: TNotifyEvent read FOnChange write FOnChange;
  end;

implementation

constructor TDatabaseGridSelectedRows.Create(const ADataLink: TDataLink);
begin
  inherited Create;

  FDataLink := ADataLink;
  FItems := TList<TBookmark>.Create;
end;

destructor TDatabaseGridSelectedRows.Destroy;
begin
  FItems.Free;

  inherited Destroy;
end;

function TDatabaseGridSelectedRows.GetCount: Integer;
begin
  Result := FItems.Count;
end;

function TDatabaseGridSelectedRows.GetCurrentRowSelected: Boolean;
begin
  Result := FDataLink.Active and IsSelected(FDataLink.DataSet.Bookmark);
end;

function TDatabaseGridSelectedRows.GetItem(const AIndex: Integer): TBookmark;
begin
  Result := FItems[AIndex];
end;

function TDatabaseGridSelectedRows.GetDataSetBookmarks: TArray<TBookmark>;
var
  LBookmark: TBookmark;
  LBookmarks: TList<TBookmark>;
  LDataSet: TDataSet;
begin
  LDataSet := FDataLink.DataSet;
  LDataSet.CheckBrowseMode;

  LBookmarks := TList<TBookmark>.Create;
  try
    LDataSet.DisableControls;
    try
      LBookmark := LDataSet.Bookmark;
      try
        LDataSet.First;

        while not LDataSet.Eof do
        begin
          LBookmarks.Add(LDataSet.Bookmark);

          LDataSet.Next;
        end;
      finally
        if LDataSet.BookmarkValid(LBookmark) then
          LDataSet.Bookmark := LBookmark;
      end;
    finally
      LDataSet.EnableControls;
    end;

    Result := LBookmarks.ToArray;
  finally
    LBookmarks.Free;
  end;
end;

function TDatabaseGridSelectedRows.IsSelected(const ABookmark: TBookmark): Boolean;
var
  LIndex: Integer;
begin
  Result := (FItems.Count > 0) and TryFind(ABookmark, LIndex);
end;

function TDatabaseGridSelectedRows.TryFind(const ABookmark: TBookmark; out AIndex: Integer): Boolean;
var
  LCompare, LHigh, LLow, LMiddle: Integer;
begin
  Result := False;

  LLow := 0;
  LHigh := FItems.Count - 1;

  while LLow <= LHigh do
  begin
    LMiddle := (LLow + LHigh) shr 1;
    LCompare := FDataLink.DataSet.CompareBookmarks(FItems[LMiddle], ABookmark);

    if LCompare < 0 then
      LLow := LMiddle + 1
    else
    begin
      LHigh := LMiddle - 1;

      if LCompare = 0 then
      begin
        Result := True;
        LLow := LMiddle;
      end;
    end;
  end;

  AIndex := LLow;
end;

procedure TDatabaseGridSelectedRows.BeginUpdate;
begin
  Inc(FUpdateCount);
end;

procedure TDatabaseGridSelectedRows.Clear;
begin
  if FItems.Count > 0 then
  begin
    FItems.Clear;

    DoChange;
  end;
end;

procedure TDatabaseGridSelectedRows.DoChange;
begin
  if FUpdateCount > 0 then
    FChanged := True
  else
  if Assigned(FOnChange) then
    FOnChange(Self);
end;

procedure TDatabaseGridSelectedRows.EndUpdate;
begin
  Dec(FUpdateCount);

  if (FUpdateCount = 0) and FChanged then
  begin
    FChanged := False;

    DoChange;
  end;
end;

procedure TDatabaseGridSelectedRows.Invert;
var
  LBookmarks: TArray<TBookmark>;
  LInverted: TList<TBookmark>;
begin
  if not FDataLink.Active then
    Exit;

  LBookmarks := GetDataSetBookmarks;

  LInverted := TList<TBookmark>.Create;
  try
    for var LBookmark in LBookmarks do
    if not IsSelected(LBookmark) then
      LInverted.Add(LBookmark);

    FItems.Clear;
    FItems.AddRange(LInverted);
  finally
    LInverted.Free;
  end;

  DoChange;
end;

procedure TDatabaseGridSelectedRows.Refresh;
var
  LBookmark: TBookmark;
  LBookmarks: TArray<TBookmark>;
  LDataSet: TDataSet;
  LIndex: Integer;
begin
  if not FDataLink.Active or (FItems.Count = 0) then
    Exit;

  LDataSet := FDataLink.DataSet;
  LBookmarks := FItems.ToArray;

  LDataSet.DisableControls;
  try
    LBookmark := LDataSet.Bookmark;
    try
      FItems.Clear;

      for var LBookmarkIndex := 0 to High(LBookmarks) do
      if LDataSet.BookmarkValid(LBookmarks[LBookmarkIndex]) then
      begin
        LDataSet.GotoBookmark(LBookmarks[LBookmarkIndex]);

        if not TryFind(LDataSet.Bookmark, LIndex) then
          FItems.Insert(LIndex, LDataSet.Bookmark);
      end;
    finally
      if LDataSet.BookmarkValid(LBookmark) then
        LDataSet.GotoBookmark(LBookmark);
    end;
  finally
    LDataSet.EnableControls;
  end;

  if FItems.Count <> Length(LBookmarks) then
    DoChange;
end;

procedure TDatabaseGridSelectedRows.Select(const ABookmark: TBookmark; const ASelected: Boolean);
var
  LIndex: Integer;
begin
  if not FDataLink.Active or (Length(ABookmark) = 0) or (TryFind(ABookmark, LIndex) = ASelected) then
    Exit;

  if ASelected then
    FItems.Insert(LIndex, ABookmark)
  else
    FItems.Delete(LIndex);

  DoChange;
end;

procedure TDatabaseGridSelectedRows.SelectAll;
var
  LBookmarks: TArray<TBookmark>;
begin
  if not FDataLink.Active then
    Exit;

  LBookmarks := GetDataSetBookmarks;

  if Length(LBookmarks) = FItems.Count then
    Exit;

  FItems.Clear;
  FItems.AddRange(LBookmarks);

  DoChange;
end;

procedure TDatabaseGridSelectedRows.SetCurrentRowSelected(const AValue: Boolean);
begin
  if FDataLink.Active then
    Select(FDataLink.DataSet.Bookmark, AValue);
end;

end.
