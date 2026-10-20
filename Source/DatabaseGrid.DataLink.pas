unit DatabaseGrid.DataLink;

interface

uses
  System.Classes, Data.DB;

type
  TDatabaseGridDataChangedEvent = procedure(const ARowShift: Integer; const ACurrentRowChanged, ADataSetChanged: Boolean) of object;
  TDatabaseGridFocusControlEvent = procedure(var AField: TField) of object;
  TDatabaseGridRecordChangedEvent = procedure(const AField: TField) of object;

  TDatabaseGridDataLink = class(TDataLink)
  strict private
    FBufferAtStart: Boolean;
    FFirstBufferedRow: Integer;
    FLastActiveRecord: Integer;
    FOnActiveChanged: TNotifyEvent;
    FOnDataChanged: TDatabaseGridDataChangedEvent;
    FOnDisabledStateChanged: TNotifyEvent;
    FOnEditingChanged: TNotifyEvent;
    FOnFocusControl: TDatabaseGridFocusControlEvent;
    FOnLayoutChanged: TNotifyEvent;
    FOnRecordChanged: TDatabaseGridRecordChangedEvent;
    FOnUpdateData: TNotifyEvent;
    FSequenced: Boolean;
    function GetBufferedRowCount: Integer;
    function GetBufferFull: Boolean;
    function GetCurrentRow: Integer;
    function GetRowCountAfterBuffer: Integer;
    function GetTotalRowCount: Integer;
    function HasRowsBeforeBuffer: Boolean;
    function HasUnusedBuffers: Boolean;
    function TryGetRecordNumber(out ARecordNumber: Integer): Boolean;
    function TryGetTrimRange(const AFirstRow, ALastRow: Integer; out AFirstKeptRow, ALastKeptRow: Integer): Boolean;
    procedure BufferChanged(const AActiveRecord: Integer);
  protected
    procedure ActiveChanged; override;
    procedure DataEvent(AEvent: TDataEvent; AInfo: NativeInt); override;
    procedure DataSetChanged; override;
    procedure DataSetScrolled(ADistance: Integer); override;
    procedure EditingChanged; override;
    procedure FocusControl(AField: TFieldRef); override;
    procedure LayoutChanged; override;
    procedure RecordChanged(AField: TField); override;
    procedure UpdateData; override;
  public
    constructor Create;
    function CanExtendBuffer: Boolean;
    function CanTrimBuffer(const AFirstRow, ALastRow: Integer): Boolean;
    function ExtendBuffer(const ARowCount: Integer): Integer;
    function ExtendBufferBackward(const ARowCount: Integer): Integer;
    function HasAllRows: Boolean;
    function TrimBuffer(const AFirstRow, ALastRow: Integer): Integer;
    procedure BufferAllRows;
    property BufferedRowCount: Integer read GetBufferedRowCount;
    property BufferFull: Boolean read GetBufferFull;
    property CurrentRow: Integer read GetCurrentRow;
    property FirstBufferedRow: Integer read FFirstBufferedRow;
    property OnActiveChanged: TNotifyEvent read FOnActiveChanged write FOnActiveChanged;
    property OnDataChanged: TDatabaseGridDataChangedEvent read FOnDataChanged write FOnDataChanged;
    property OnDisabledStateChanged: TNotifyEvent read FOnDisabledStateChanged write FOnDisabledStateChanged;
    property OnEditingChanged: TNotifyEvent read FOnEditingChanged write FOnEditingChanged;
    property OnFocusControl: TDatabaseGridFocusControlEvent read FOnFocusControl write FOnFocusControl;
    property OnLayoutChanged: TNotifyEvent read FOnLayoutChanged write FOnLayoutChanged;
    property OnRecordChanged: TDatabaseGridRecordChangedEvent read FOnRecordChanged write FOnRecordChanged;
    property OnUpdateData: TNotifyEvent read FOnUpdateData write FOnUpdateData;
    property Sequenced: Boolean read FSequenced;
    property TotalRowCount: Integer read GetTotalRowCount;
  end;

implementation

uses
  System.Math, DatabaseGrid.Consts;

constructor TDatabaseGridDataLink.Create;
begin
  inherited Create;

  VisualControl := True;
end;

function TDatabaseGridDataLink.CanExtendBuffer: Boolean;
begin
  Result := Active and (DataSet.State = dsBrowse) and not DataSet.IsUniDirectional;
end;

function TDatabaseGridDataLink.CanTrimBuffer(const AFirstRow, ALastRow: Integer): Boolean;
var
  LFirstKeptRow, LLastKeptRow: Integer;
begin
  Result := CanExtendBuffer and (HasUnusedBuffers or TryGetTrimRange(AFirstRow, ALastRow, LFirstKeptRow, LLastKeptRow));
end;

function TDatabaseGridDataLink.ExtendBuffer(const ARowCount: Integer): Integer;
var
  LActiveRecord: Integer;
begin
  if not CanExtendBuffer or (ARowCount <= 0) then
    Exit(0);

  LActiveRecord := ActiveRecord;

  BufferCount := BufferCount + ARowCount;

  Result := ActiveRecord - LActiveRecord;

  BufferChanged(LActiveRecord);
end;

function TDatabaseGridDataLink.ExtendBufferBackward(const ARowCount: Integer): Integer;
var
  LGrowRowCount, LRowCount: Integer;
begin
  Result := 0;

  LRowCount := ARowCount;

  if LRowCount < MaxInt - DATABASE_GRID_MAX_BUFFERED_ROW_COUNT then
    Inc(LRowCount, DATABASE_GRID_MAX_BUFFERED_ROW_COUNT div 4);

  if FSequenced then
    LGrowRowCount := Min(LRowCount, FFirstBufferedRow) + GetRowCountAfterBuffer
  else
    LGrowRowCount := DATABASE_GRID_BUFFER_GROW_ROW_COUNT;

  while (Result < ARowCount) and (LGrowRowCount > 0) and CanExtendBuffer and BufferFull and HasRowsBeforeBuffer do
  begin
    Inc(Result, ExtendBuffer(LGrowRowCount));

    LGrowRowCount := Min(LGrowRowCount * 2, DATABASE_GRID_MAX_BUFFER_GROW_ROW_COUNT);
  end;
end;

function TDatabaseGridDataLink.GetBufferedRowCount: Integer;
begin
  if Active then
    Result := RecordCount
  else
    Result := 0;
end;

function TDatabaseGridDataLink.GetBufferFull: Boolean;
begin
  Result := Active and (RecordCount >= BufferCount);
end;

function TDatabaseGridDataLink.GetCurrentRow: Integer;
begin
  if Active then
    Result := FFirstBufferedRow + ActiveRecord
  else
    Result := -1;
end;

function TDatabaseGridDataLink.GetRowCountAfterBuffer: Integer;
begin
  if Active and FSequenced then
    Result := Max(DataSet.RecordCount - FFirstBufferedRow - RecordCount, 0)
  else
    Result := 0;
end;

function TDatabaseGridDataLink.GetTotalRowCount: Integer;
begin
  if not Active then
    Exit(0);

  Result := FFirstBufferedRow + RecordCount;

  if FSequenced then
    Result := Max(Result, DataSet.RecordCount);
end;

function TDatabaseGridDataLink.HasAllRows: Boolean;
begin
  Result := Active and not BufferFull and not HasRowsBeforeBuffer;
end;

function TDatabaseGridDataLink.HasRowsBeforeBuffer: Boolean;
begin
  if FSequenced then
    Result := FFirstBufferedRow > 0
  else
    Result := not FBufferAtStart;
end;

function TDatabaseGridDataLink.HasUnusedBuffers: Boolean;
begin
  Result := BufferCount - RecordCount > DATABASE_GRID_BUFFER_GROW_ROW_COUNT;
end;

function TDatabaseGridDataLink.TrimBuffer(const AFirstRow, ALastRow: Integer): Integer;
var
  LActiveRecord, LFirstKeptRow, LLastKeptRow: Integer;
begin
  Result := 0;

  if not CanExtendBuffer then
    Exit;

  if HasUnusedBuffers then
    BufferCount := RecordCount + 1;

  if not TryGetTrimRange(AFirstRow, ALastRow, LFirstKeptRow, LLastKeptRow) then
    Exit;

  LActiveRecord := ActiveRecord;

  if LFirstKeptRow > 0 then
    BufferCount := LActiveRecord - LFirstKeptRow + 1;

  BufferCount := LLastKeptRow - LFirstKeptRow + 1;

  Result := ActiveRecord - LActiveRecord;

  BufferChanged(LActiveRecord);
end;

function TDatabaseGridDataLink.TryGetRecordNumber(out ARecordNumber: Integer): Boolean;
begin
  ARecordNumber := 0;

  if DataSet.IsSequenced and (DataSet.State = dsBrowse) then
    ARecordNumber := DataSet.RecNo;

  Result := ARecordNumber > 0;
end;

function TDatabaseGridDataLink.TryGetTrimRange(const AFirstRow, ALastRow: Integer; out AFirstKeptRow, ALastKeptRow: Integer): Boolean;
var
  LActiveRecord, LFirstRow: Integer;
begin
  LActiveRecord := ActiveRecord;
  LFirstRow := EnsureRange(AFirstRow, 0, LActiveRecord);

  ALastKeptRow := EnsureRange(ALastRow, LActiveRecord, RecordCount - 1);
  AFirstKeptRow := Max(LFirstRow - DATABASE_GRID_MAX_BUFFERED_ROW_COUNT div 4, 0);

  if Int64(LActiveRecord - AFirstKeptRow + 1) * AFirstKeptRow > DATABASE_GRID_MAX_BUFFER_MOVE_COUNT then
    AFirstKeptRow := LFirstRow;

  if Int64(LActiveRecord - AFirstKeptRow + 1) * AFirstKeptRow > DATABASE_GRID_MAX_BUFFER_MOVE_COUNT then
    AFirstKeptRow := 0;

  Result := BufferCount > Max(DATABASE_GRID_MAX_BUFFERED_ROW_COUNT, 2 * (ALastKeptRow - AFirstKeptRow + 1));
end;

procedure TDatabaseGridDataLink.ActiveChanged;
var
  LRecordNumber: Integer;
begin
  FFirstBufferedRow := 0;
  FBufferAtStart := True;
  FSequenced := False;

  if Active then
  begin
    FLastActiveRecord := ActiveRecord;
    FSequenced := TryGetRecordNumber(LRecordNumber);

    if FSequenced then
      FFirstBufferedRow := Max(LRecordNumber - 1 - ActiveRecord, 0);
  end
  else
    BufferCount := 1;

  if Assigned(FOnActiveChanged) then
    FOnActiveChanged(Self);
end;

procedure TDatabaseGridDataLink.BufferAllRows;
var
  LRowCount: Integer;
begin
  while BufferFull and CanExtendBuffer do
  begin
    LRowCount := Max(BufferCount, DATABASE_GRID_BUFFER_GROW_ROW_COUNT);

    if FSequenced then
      LRowCount := Max(LRowCount, DataSet.RecordCount - RecordCount + 1);

    ExtendBuffer(LRowCount);
  end;

  if (BufferCount > RecordCount + 1) and CanExtendBuffer then
    BufferCount := RecordCount + 1;
end;

procedure TDatabaseGridDataLink.BufferChanged(const AActiveRecord: Integer);
var
  LShift: Integer;
begin
  LShift := ActiveRecord - AActiveRecord;

  FLastActiveRecord := ActiveRecord;

  if FSequenced then
    FFirstBufferedRow := Max(FFirstBufferedRow - LShift, 0)
  else
  if LShift < 0 then
    FBufferAtStart := False
  else
  if not BufferFull then
    FBufferAtStart := True;
end;

procedure TDatabaseGridDataLink.DataEvent(AEvent: TDataEvent; AInfo: NativeInt);
begin
  inherited;

  if (AEvent = deDisabledStateChange) and Assigned(FOnDisabledStateChanged) then
    FOnDisabledStateChanged(Self);
end;

procedure TDatabaseGridDataLink.DataSetChanged;
var
  LCurrentRowChanged: Boolean;
  LFirstBufferedRow, LRecordNumber: Integer;
begin
  LFirstBufferedRow := FFirstBufferedRow;

  if TryGetRecordNumber(LRecordNumber) then
  begin
    FSequenced := True;
    FFirstBufferedRow := Max(LRecordNumber - 1 - ActiveRecord, 0);
  end
  else
  if not FSequenced then
    FBufferAtStart := not BufferFull or DataSet.Bof and (ActiveRecord = 0) or FBufferAtStart and (ActiveRecord = FLastActiveRecord);

  LCurrentRowChanged := FFirstBufferedRow + ActiveRecord <> LFirstBufferedRow + FLastActiveRecord;

  FLastActiveRecord := ActiveRecord;

  if Assigned(FOnDataChanged) then
    FOnDataChanged(LFirstBufferedRow - FFirstBufferedRow, LCurrentRowChanged, True);
end;

procedure TDatabaseGridDataLink.DataSetScrolled(ADistance: Integer);
var
  LRecordNumber: Integer;
begin
  if TryGetRecordNumber(LRecordNumber) then
  begin
    FSequenced := True;
    FFirstBufferedRow := Max(LRecordNumber - 1 - ActiveRecord, 0);
  end
  else
  if ADistance > 0 then
    FBufferAtStart := False;

  FLastActiveRecord := ActiveRecord;

  if Assigned(FOnDataChanged) then
    FOnDataChanged(-ADistance, True, False);
end;

procedure TDatabaseGridDataLink.EditingChanged;
begin
  if Assigned(FOnEditingChanged) then
    FOnEditingChanged(Self);
end;

procedure TDatabaseGridDataLink.FocusControl(AField: TFieldRef);
begin
  if Assigned(AField) and Assigned(AField^) and Assigned(FOnFocusControl) then
    FOnFocusControl(AField^);
end;

procedure TDatabaseGridDataLink.LayoutChanged;
begin
  if Assigned(FOnLayoutChanged) then
    FOnLayoutChanged(Self);
end;

procedure TDatabaseGridDataLink.RecordChanged(AField: TField);
begin
  if Assigned(FOnRecordChanged) then
    FOnRecordChanged(AField);
end;

procedure TDatabaseGridDataLink.UpdateData;
begin
  if Assigned(FOnUpdateData) then
    FOnUpdateData(Self);
end;

end.
