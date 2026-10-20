unit DatabaseGrid.Indicator;

interface

uses
  System.Classes, System.UITypes, Vcl.ImgList, Vcl.Menus, DatabaseGrid.Consts, DatabaseGrid.Types;

type
  TDatabaseGridTitleMenuCommandItem = class(TPersistent)
  strict private
    FDefaultVisible: Boolean;
    FImageIndex: System.UITypes.TImageIndex;
    FOnChange: TNotifyEvent;
    FOwner: TPersistent;
    FVisible: Boolean;
    function IsVisibleStored: Boolean;
    procedure DoChange;
    procedure SetImageIndex(const AValue: System.UITypes.TImageIndex);
    procedure SetVisible(const AValue: Boolean);
  protected
    function GetOwner: TPersistent; override;
  public
    constructor Create(const AOwner: TPersistent; const ADefaultVisible: Boolean);
    procedure Assign(ASource: TPersistent); override;
    property OnChange: TNotifyEvent read FOnChange write FOnChange;
  published
    property ImageIndex: System.UITypes.TImageIndex read FImageIndex write SetImageIndex default -1;
    property Visible: Boolean read FVisible write SetVisible stored IsVisibleStored;
  end;

  TDatabaseGridTitleMenuCommandItems = class(TPersistent)
  strict private
    FItems: array [TDatabaseGridTitleMenuCommand] of TDatabaseGridTitleMenuCommandItem;
    FOnChange: TNotifyEvent;
    FOwner: TPersistent;
    function GetCommand(const AIndex: Integer): TDatabaseGridTitleMenuCommandItem;
    function GetItem(const ACommand: TDatabaseGridTitleMenuCommand): TDatabaseGridTitleMenuCommandItem;
    procedure ItemChanged(ASender: TObject);
    procedure SetCommand(const AIndex: Integer; const AValue: TDatabaseGridTitleMenuCommandItem);
  protected
    function GetOwner: TPersistent; override;
  public
    constructor Create(const AOwner: TPersistent);
    destructor Destroy; override;
    procedure Assign(ASource: TPersistent); override;
    procedure SetVisible(const ACommands: TDatabaseGridTitleMenuCommands; const AVisible: Boolean);
    property Items[const ACommand: TDatabaseGridTitleMenuCommand]: TDatabaseGridTitleMenuCommandItem read GetItem; default;
    property OnChange: TNotifyEvent read FOnChange write FOnChange;
  published
    property Export: TDatabaseGridTitleMenuCommandItem index Ord(tmcExport) read GetCommand write SetCommand;
    property InvertSelection: TDatabaseGridTitleMenuCommandItem index Ord(tmcInvertSelection) read GetCommand write SetCommand;
    property JumpToColumn: TDatabaseGridTitleMenuCommandItem index Ord(tmcJumpToColumn) read GetCommand write SetCommand;
    property JumpToFirstColumn: TDatabaseGridTitleMenuCommandItem index Ord(tmcJumpToFirstColumn) read GetCommand write SetCommand;
    property JumpToLastColumn: TDatabaseGridTitleMenuCommandItem index Ord(tmcJumpToLastColumn) read GetCommand write SetCommand;
    property ResetZoom: TDatabaseGridTitleMenuCommandItem index Ord(tmcResetZoom) read GetCommand write SetCommand;
    property SelectAll: TDatabaseGridTitleMenuCommandItem index Ord(tmcSelectAll) read GetCommand write SetCommand;
    property UnselectAll: TDatabaseGridTitleMenuCommandItem index Ord(tmcUnselectAll) read GetCommand write SetCommand;
    property ZoomIn: TDatabaseGridTitleMenuCommandItem index Ord(tmcZoomIn) read GetCommand write SetCommand;
    property ZoomOut: TDatabaseGridTitleMenuCommandItem index Ord(tmcZoomOut) read GetCommand write SetCommand;
  end;

  TDatabaseGridIndicatorTitleMenu = class(TPersistent)
  strict private
    FCommands: TDatabaseGridTitleMenuCommandItems;
    FDropdownMenu: TPopupMenu;
    FImages: TCustomImageList;
    FOnChange: TNotifyEvent;
    FOptions: TDatabaseGridTitleMenuOptions;
    FOwner: TPersistent;
    procedure CommandsChanged(ASender: TObject);
    procedure DoChange;
    procedure SetCommands(const AValue: TDatabaseGridTitleMenuCommandItems);
    procedure SetDropdownMenu(const AValue: TPopupMenu);
    procedure SetImages(const AValue: TCustomImageList);
    procedure SetOptions(const AValue: TDatabaseGridTitleMenuOptions);
  protected
    function GetOwner: TPersistent; override;
  public
    constructor Create(const AOwner: TPersistent);
    destructor Destroy; override;
    procedure Assign(ASource: TPersistent); override;
    procedure SetOption(const AOption: TDatabaseGridTitleMenuOption; const AEnabled: Boolean);
    property OnChange: TNotifyEvent read FOnChange write FOnChange;
  published
    property Commands: TDatabaseGridTitleMenuCommandItems read FCommands write SetCommands;
    property DropdownMenu: TPopupMenu read FDropdownMenu write SetDropdownMenu;
    property Images: TCustomImageList read FImages write SetImages;
    property Options: TDatabaseGridTitleMenuOptions read FOptions write SetOptions default TDatabaseGridDefault.TitleMenuOptions;
  end;

  TDatabaseGridIndicator = class(TPersistent)
  strict private
    FOnChange: TNotifyEvent;
    FOptions: TDatabaseGridIndicatorOptions;
    FOwner: TPersistent;
    FTitleMenu: TDatabaseGridIndicatorTitleMenu;
    FVisible: Boolean;
    procedure DoChange;
    procedure SetOptions(const AValue: TDatabaseGridIndicatorOptions);
    procedure SetTitleMenu(const AValue: TDatabaseGridIndicatorTitleMenu);
    procedure SetVisible(const AValue: Boolean);
    procedure TitleMenuChanged(ASender: TObject);
  protected
    function GetOwner: TPersistent; override;
  public
    constructor Create(const AOwner: TPersistent);
    destructor Destroy; override;
    procedure Assign(ASource: TPersistent); override;
    procedure SetOption(const AOption: TDatabaseGridIndicatorOption; const AEnabled: Boolean);
    property OnChange: TNotifyEvent read FOnChange write FOnChange;
  published
    property Options: TDatabaseGridIndicatorOptions read FOptions write SetOptions default TDatabaseGridDefault.IndicatorOptions;
    property TitleMenu: TDatabaseGridIndicatorTitleMenu read FTitleMenu write SetTitleMenu;
    property Visible: Boolean read FVisible write SetVisible default True;
  end;

implementation

{ TDatabaseGridTitleMenuCommandItem }

constructor TDatabaseGridTitleMenuCommandItem.Create(const AOwner: TPersistent; const ADefaultVisible: Boolean);
begin
  inherited Create;

  FOwner := AOwner;
  FDefaultVisible := ADefaultVisible;
  FImageIndex := -1;
  FVisible := ADefaultVisible;
end;

procedure TDatabaseGridTitleMenuCommandItem.Assign(ASource: TPersistent);
begin
  if Assigned(ASource) and (ASource is TDatabaseGridTitleMenuCommandItem) then
  with ASource as TDatabaseGridTitleMenuCommandItem do
  begin
    Self.FImageIndex := FImageIndex;
    Self.FVisible := FVisible;

    Self.DoChange;
  end
  else
    inherited Assign(ASource);
end;

function TDatabaseGridTitleMenuCommandItem.GetOwner: TPersistent;
begin
  Result := FOwner;
end;

function TDatabaseGridTitleMenuCommandItem.IsVisibleStored: Boolean;
begin
  Result := FVisible <> FDefaultVisible;
end;

procedure TDatabaseGridTitleMenuCommandItem.DoChange;
begin
  if Assigned(FOnChange) then
    FOnChange(Self);
end;

procedure TDatabaseGridTitleMenuCommandItem.SetImageIndex(const AValue: System.UITypes.TImageIndex);
begin
  if FImageIndex <> AValue then
  begin
    FImageIndex := AValue;

    DoChange;
  end;
end;

procedure TDatabaseGridTitleMenuCommandItem.SetVisible(const AValue: Boolean);
begin
  if FVisible <> AValue then
  begin
    FVisible := AValue;

    DoChange;
  end;
end;

{ TDatabaseGridTitleMenuCommandItems }

constructor TDatabaseGridTitleMenuCommandItems.Create(const AOwner: TPersistent);
begin
  inherited Create;

  FOwner := AOwner;

  for var LCommand := Low(TDatabaseGridTitleMenuCommand) to High(TDatabaseGridTitleMenuCommand) do
  begin
    FItems[LCommand] := TDatabaseGridTitleMenuCommandItem.Create(Self, not (LCommand in TDatabaseGridDefault.TitleMenuHiddenCommands));
    FItems[LCommand].OnChange := ItemChanged;
  end;
end;

destructor TDatabaseGridTitleMenuCommandItems.Destroy;
begin
  for var LCommand := Low(TDatabaseGridTitleMenuCommand) to High(TDatabaseGridTitleMenuCommand) do
    FItems[LCommand].Free;

  inherited Destroy;
end;

procedure TDatabaseGridTitleMenuCommandItems.Assign(ASource: TPersistent);
begin
  if Assigned(ASource) and (ASource is TDatabaseGridTitleMenuCommandItems) then
  for var LCommand := Low(TDatabaseGridTitleMenuCommand) to High(TDatabaseGridTitleMenuCommand) do
    FItems[LCommand].Assign(TDatabaseGridTitleMenuCommandItems(ASource)[LCommand])
  else
    inherited Assign(ASource);
end;

function TDatabaseGridTitleMenuCommandItems.GetCommand(const AIndex: Integer): TDatabaseGridTitleMenuCommandItem;
begin
  Result := FItems[TDatabaseGridTitleMenuCommand(AIndex)];
end;

function TDatabaseGridTitleMenuCommandItems.GetItem(const ACommand: TDatabaseGridTitleMenuCommand): TDatabaseGridTitleMenuCommandItem;
begin
  Result := FItems[ACommand];
end;

function TDatabaseGridTitleMenuCommandItems.GetOwner: TPersistent;
begin
  Result := FOwner;
end;

procedure TDatabaseGridTitleMenuCommandItems.ItemChanged(ASender: TObject);
begin
  if Assigned(FOnChange) then
    FOnChange(Self);
end;

procedure TDatabaseGridTitleMenuCommandItems.SetCommand(const AIndex: Integer; const AValue: TDatabaseGridTitleMenuCommandItem);
begin
  FItems[TDatabaseGridTitleMenuCommand(AIndex)].Assign(AValue);
end;

procedure TDatabaseGridTitleMenuCommandItems.SetVisible(const ACommands: TDatabaseGridTitleMenuCommands; const AVisible: Boolean);
begin
  for var LCommand in ACommands do
    FItems[LCommand].Visible := AVisible;
end;

{ TDatabaseGridIndicatorTitleMenu }

constructor TDatabaseGridIndicatorTitleMenu.Create(const AOwner: TPersistent);
begin
  inherited Create;

  FOwner := AOwner;
  FCommands := TDatabaseGridTitleMenuCommandItems.Create(Self);
  FCommands.OnChange := CommandsChanged;
  FOptions := TDatabaseGridDefault.TitleMenuOptions;
end;

destructor TDatabaseGridIndicatorTitleMenu.Destroy;
begin
  FCommands.Free;

  inherited Destroy;
end;

procedure TDatabaseGridIndicatorTitleMenu.Assign(ASource: TPersistent);
begin
  if Assigned(ASource) and (ASource is TDatabaseGridIndicatorTitleMenu) then
  with ASource as TDatabaseGridIndicatorTitleMenu do
  begin
    Self.FCommands.Assign(FCommands);
    Self.FDropdownMenu := FDropdownMenu;
    Self.FImages := FImages;
    Self.FOptions := FOptions;

    Self.DoChange;
  end
  else
    inherited Assign(ASource);
end;

function TDatabaseGridIndicatorTitleMenu.GetOwner: TPersistent;
begin
  Result := FOwner;
end;

procedure TDatabaseGridIndicatorTitleMenu.CommandsChanged(ASender: TObject);
begin
  DoChange;
end;

procedure TDatabaseGridIndicatorTitleMenu.DoChange;
begin
  if Assigned(FOnChange) then
    FOnChange(Self);
end;

procedure TDatabaseGridIndicatorTitleMenu.SetCommands(const AValue: TDatabaseGridTitleMenuCommandItems);
begin
  FCommands.Assign(AValue);
end;

procedure TDatabaseGridIndicatorTitleMenu.SetDropdownMenu(const AValue: TPopupMenu);
begin
  if FDropdownMenu <> AValue then
  begin
    FDropdownMenu := AValue;

    DoChange;
  end;
end;

procedure TDatabaseGridIndicatorTitleMenu.SetImages(const AValue: TCustomImageList);
begin
  if FImages <> AValue then
  begin
    FImages := AValue;

    DoChange;
  end;
end;

procedure TDatabaseGridIndicatorTitleMenu.SetOption(const AOption: TDatabaseGridTitleMenuOption; const AEnabled: Boolean);
begin
  if AEnabled then
    SetOptions(FOptions + [AOption])
  else
    SetOptions(FOptions - [AOption]);
end;

procedure TDatabaseGridIndicatorTitleMenu.SetOptions(const AValue: TDatabaseGridTitleMenuOptions);
begin
  if FOptions <> AValue then
  begin
    FOptions := AValue;

    DoChange;
  end;
end;

{ TDatabaseGridIndicator }

constructor TDatabaseGridIndicator.Create(const AOwner: TPersistent);
begin
  inherited Create;

  FOwner := AOwner;
  FOptions := TDatabaseGridDefault.IndicatorOptions;
  FVisible := True;
  FTitleMenu := TDatabaseGridIndicatorTitleMenu.Create(Self);
  FTitleMenu.OnChange := TitleMenuChanged;
end;

destructor TDatabaseGridIndicator.Destroy;
begin
  FTitleMenu.Free;

  inherited Destroy;
end;

procedure TDatabaseGridIndicator.Assign(ASource: TPersistent);
begin
  if Assigned(ASource) and (ASource is TDatabaseGridIndicator) then
  with ASource as TDatabaseGridIndicator do
  begin
    Self.FOptions := FOptions;
    Self.FVisible := FVisible;
    Self.FTitleMenu.Assign(FTitleMenu);
  end
  else
    inherited Assign(ASource);
end;

function TDatabaseGridIndicator.GetOwner: TPersistent;
begin
  Result := FOwner;
end;

procedure TDatabaseGridIndicator.DoChange;
begin
  if Assigned(FOnChange) then
    FOnChange(Self);
end;

procedure TDatabaseGridIndicator.SetOption(const AOption: TDatabaseGridIndicatorOption; const AEnabled: Boolean);
begin
  if AEnabled then
    SetOptions(FOptions + [AOption])
  else
    SetOptions(FOptions - [AOption]);
end;

procedure TDatabaseGridIndicator.SetOptions(const AValue: TDatabaseGridIndicatorOptions);
begin
  if FOptions <> AValue then
  begin
    FOptions := AValue;

    DoChange;
  end;
end;

procedure TDatabaseGridIndicator.SetTitleMenu(const AValue: TDatabaseGridIndicatorTitleMenu);
begin
  FTitleMenu.Assign(AValue);
end;

procedure TDatabaseGridIndicator.SetVisible(const AValue: Boolean);
begin
  if FVisible <> AValue then
  begin
    FVisible := AValue;

    DoChange;
  end;
end;

procedure TDatabaseGridIndicator.TitleMenuChanged(ASender: TObject);
begin
  DoChange;
end;

end.
