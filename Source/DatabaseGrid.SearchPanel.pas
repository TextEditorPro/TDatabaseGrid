unit DatabaseGrid.SearchPanel;

interface

uses
  System.Classes, Vcl.Controls, DatabaseGrid.Consts, DatabaseGrid.Types;

type
  TDatabaseGridSearchPanelItem = class;

  TDatabaseGridFocusedControlEvent = function: TWinControl of object;
  TDatabaseGridSearchPanelItemEvent = procedure(ASender: TObject; const AItem: TDatabaseGridSearchPanelItem) of object;

  TDatabaseGridSearchPanelItem = class(TCollectionItem)
  strict private
    FAcceptedText: string;
    FDefaultItemIndex: Integer;
    FItemIndex: Integer;
    FItems: TStrings;
    FName: string;
    FOnAccept: TDatabaseGridSearchPanelItemEvent;
    FOnChange: TDatabaseGridSearchPanelItemEvent;
    FOnCompletion: TDatabaseGridSearchPanelItemEvent;
    FText: string;
    FTextHint: string;
    FValues: TStrings;
    FVisible: Boolean;
    FWidth: Integer;
    function GetValue: string;
    procedure SetDefaultItemIndex(const AValue: Integer);
    procedure SetItemIndex(const AValue: Integer);
    procedure SetItems(const AValue: TStrings);
    procedure SetName(const AValue: string);
    procedure SetText(const AValue: string);
    procedure SetTextHint(const AValue: string);
    procedure SetValues(const AValue: TStrings);
    procedure SetVisible(const AValue: Boolean);
    procedure SetWidth(const AValue: Integer);
    procedure StringsChanged(ASender: TObject);
  protected
    function GetDisplayName: string; override;
  public
    constructor Create(ACollection: TCollection); override;
    destructor Destroy; override;
    function IsDefaultItemSelected: Boolean;
    function IsFiltering: Boolean;
    procedure Assign(ASource: TPersistent); override;
    procedure Reset;
    property AcceptedText: string read FAcceptedText write FAcceptedText;
    property Text: string read FText write SetText;
    property Value: string read GetValue;
  published
    property DefaultItemIndex: Integer read FDefaultItemIndex write SetDefaultItemIndex default 0;
    property ItemIndex: Integer read FItemIndex write SetItemIndex default -1;
    property Items: TStrings read FItems write SetItems;
    property Name: string read FName write SetName;
    property TextHint: string read FTextHint write SetTextHint;
    property Values: TStrings read FValues write SetValues;
    property Visible: Boolean read FVisible write SetVisible default True;
    property Width: Integer read FWidth write SetWidth default TDatabaseGridDefault.SearchPanelItemWidth;
    property OnAccept: TDatabaseGridSearchPanelItemEvent read FOnAccept write FOnAccept;
    property OnChange: TDatabaseGridSearchPanelItemEvent read FOnChange write FOnChange;
    property OnCompletion: TDatabaseGridSearchPanelItemEvent read FOnCompletion write FOnCompletion;
  end;

  TDatabaseGridSearchPanelItems = class(TOwnedCollection)
  strict private
    FOnChange: TNotifyEvent;
    function GetItem(const AIndex: Integer): TDatabaseGridSearchPanelItem;
    procedure SetItem(const AIndex: Integer; const AValue: TDatabaseGridSearchPanelItem);
  protected
    procedure Update(AItem: TCollectionItem); override;
  public
    constructor Create(const AOwner: TPersistent);
    function Add: TDatabaseGridSearchPanelItem;
    function FindItem(const AName: string): TDatabaseGridSearchPanelItem;
    property Items[const AIndex: Integer]: TDatabaseGridSearchPanelItem read GetItem write SetItem; default;
    property OnChange: TNotifyEvent read FOnChange write FOnChange;
  end;

  TDatabaseGridSearchPanel = class(TPersistent)
  strict private
    FFilterDelay: Integer;
    FItems: TDatabaseGridSearchPanelItems;
    FOnChange: TNotifyEvent;
    FOnGetFocusedControl: TDatabaseGridFocusedControlEvent;
    FOnSetFocus: TNotifyEvent;
    FOptions: TDatabaseGridSearchPanelOptions;
    FOwner: TPersistent;
    FText: string;
    FTextHint: string;
    FVisible: Boolean;
    function IsItemsStored: Boolean;
    procedure DoChange;
    procedure ItemsChanged(ASender: TObject);
    procedure SetFilterDelay(const AValue: Integer);
    procedure SetItems(const AValue: TDatabaseGridSearchPanelItems);
    procedure SetOptions(const AValue: TDatabaseGridSearchPanelOptions);
    procedure SetText(const AValue: string);
    procedure SetTextHint(const AValue: string);
    procedure SetVisible(const AValue: Boolean);
  protected
    function GetOwner: TPersistent; override;
  public
    constructor Create(const AOwner: TPersistent);
    destructor Destroy; override;
    function Focused: Boolean;
    function FocusedControl: TWinControl;
    function IsAnyItemFiltering: Boolean;
    procedure Assign(ASource: TPersistent); override;
    procedure Clear;
    procedure SetFocus;
    procedure SetOption(const AOption: TDatabaseGridSearchPanelOption; const AEnabled: Boolean);
    property OnChange: TNotifyEvent read FOnChange write FOnChange;
    property OnGetFocusedControl: TDatabaseGridFocusedControlEvent read FOnGetFocusedControl write FOnGetFocusedControl;
    property OnSetFocus: TNotifyEvent read FOnSetFocus write FOnSetFocus;
    property Text: string read FText write SetText;
  published
    property FilterDelay: Integer read FFilterDelay write SetFilterDelay default TDatabaseGridDefault.SearchPanelFilterDelay;
    property Items: TDatabaseGridSearchPanelItems read FItems write SetItems stored IsItemsStored;
    property Options: TDatabaseGridSearchPanelOptions read FOptions write SetOptions default TDatabaseGridDefault.SearchPanelOptions;
    property TextHint: string read FTextHint write SetTextHint;
    property Visible: Boolean read FVisible write SetVisible default False;
  end;

implementation

uses
  System.Math, System.SysUtils;

{ TDatabaseGridSearchPanelItem }

constructor TDatabaseGridSearchPanelItem.Create(ACollection: TCollection);
begin
  FItems := TStringList.Create;
  FValues := TStringList.Create;
  FDefaultItemIndex := 0;
  FItemIndex := -1;
  FVisible := True;
  FWidth := TDatabaseGridDefault.SearchPanelItemWidth;

  inherited Create(ACollection);

  TStringList(FItems).OnChange := StringsChanged;
  TStringList(FValues).OnChange := StringsChanged;
end;

destructor TDatabaseGridSearchPanelItem.Destroy;
begin
  inherited Destroy;

  FItems.Free;
  FValues.Free;
end;

procedure TDatabaseGridSearchPanelItem.Assign(ASource: TPersistent);
begin
  if Assigned(ASource) and (ASource is TDatabaseGridSearchPanelItem) then
  with ASource as TDatabaseGridSearchPanelItem do
  begin
    Self.Collection.BeginUpdate;
    try
      Self.FDefaultItemIndex := FDefaultItemIndex;
      Self.FItemIndex := FItemIndex;
      Self.FName := FName;
      Self.FOnAccept := FOnAccept;
      Self.FOnChange := FOnChange;
      Self.FOnCompletion := FOnCompletion;
      Self.FTextHint := FTextHint;
      Self.FVisible := FVisible;
      Self.FWidth := FWidth;
      Self.FItems.Assign(FItems);
      Self.FValues.Assign(FValues);
    finally
      Self.Collection.EndUpdate;
    end;
  end
  else
    inherited Assign(ASource);
end;

function TDatabaseGridSearchPanelItem.GetDisplayName: string;
begin
  Result := FName;

  if Result.IsEmpty then
    Result := inherited GetDisplayName;
end;

function TDatabaseGridSearchPanelItem.GetValue: string;
begin
  if (FItemIndex >= 0) and (FItemIndex < FValues.Count) then
    Exit(FValues[FItemIndex]);

  if (FItemIndex >= 0) and (FItemIndex < FItems.Count) then
    Exit(FItems[FItemIndex]);

  Result := FText;
end;

function TDatabaseGridSearchPanelItem.IsDefaultItemSelected: Boolean;
begin
  Result := (FItemIndex >= 0) and (FItemIndex = FDefaultItemIndex);
end;

function TDatabaseGridSearchPanelItem.IsFiltering: Boolean;
begin
  if FItemIndex >= 0 then
    Exit(FItemIndex <> FDefaultItemIndex);

  Result := not FText.IsEmpty;
end;

procedure TDatabaseGridSearchPanelItem.Reset;
begin
  if (FItemIndex <> FDefaultItemIndex) or not FText.IsEmpty then
  begin
    FItemIndex := FDefaultItemIndex;
    FText := '';

    Changed(False);
  end;
end;

procedure TDatabaseGridSearchPanelItem.SetDefaultItemIndex(const AValue: Integer);
begin
  if FDefaultItemIndex <> AValue then
  begin
    FDefaultItemIndex := AValue;

    Changed(False);
  end;
end;

procedure TDatabaseGridSearchPanelItem.SetItemIndex(const AValue: Integer);
begin
  if FItemIndex <> AValue then
  begin
    FItemIndex := AValue;

    Changed(False);
  end;
end;

procedure TDatabaseGridSearchPanelItem.SetItems(const AValue: TStrings);
begin
  FItems.Assign(AValue);
end;

procedure TDatabaseGridSearchPanelItem.SetName(const AValue: string);
begin
  if FName <> AValue then
  begin
    FName := AValue;

    Changed(False);
  end;
end;

procedure TDatabaseGridSearchPanelItem.SetText(const AValue: string);
begin
  if FText <> AValue then
  begin
    FText := AValue;

    Changed(False);
  end;
end;

procedure TDatabaseGridSearchPanelItem.SetValues(const AValue: TStrings);
begin
  FValues.Assign(AValue);
end;

procedure TDatabaseGridSearchPanelItem.SetVisible(const AValue: Boolean);
begin
  if FVisible <> AValue then
  begin
    FVisible := AValue;

    Changed(False);
  end;
end;

procedure TDatabaseGridSearchPanelItem.SetTextHint(const AValue: string);
begin
  if FTextHint <> AValue then
  begin
    FTextHint := AValue;

    Changed(False);
  end;
end;

procedure TDatabaseGridSearchPanelItem.SetWidth(const AValue: Integer);
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

procedure TDatabaseGridSearchPanelItem.StringsChanged(ASender: TObject);
begin
  Changed(False);
end;

{ TDatabaseGridSearchPanelItems }

constructor TDatabaseGridSearchPanelItems.Create(const AOwner: TPersistent);
begin
  inherited Create(AOwner, TDatabaseGridSearchPanelItem);
end;

function TDatabaseGridSearchPanelItems.Add: TDatabaseGridSearchPanelItem;
begin
  Result := inherited Add as TDatabaseGridSearchPanelItem;
end;

function TDatabaseGridSearchPanelItems.FindItem(const AName: string): TDatabaseGridSearchPanelItem;
begin
  for var LIndex := 0 to Count - 1 do
  if SameText(Items[LIndex].Name, AName) then
    Exit(Items[LIndex]);

  Result := nil;
end;

function TDatabaseGridSearchPanelItems.GetItem(const AIndex: Integer): TDatabaseGridSearchPanelItem;
begin
  Result := inherited GetItem(AIndex) as TDatabaseGridSearchPanelItem;
end;

procedure TDatabaseGridSearchPanelItems.SetItem(const AIndex: Integer; const AValue: TDatabaseGridSearchPanelItem);
begin
  inherited SetItem(AIndex, AValue);
end;

procedure TDatabaseGridSearchPanelItems.Update(AItem: TCollectionItem);
begin
  inherited Update(AItem);

  if Assigned(FOnChange) then
    FOnChange(Self);
end;

{ TDatabaseGridSearchPanel }

constructor TDatabaseGridSearchPanel.Create(const AOwner: TPersistent);
begin
  inherited Create;

  FOwner := AOwner;
  FFilterDelay := TDatabaseGridDefault.SearchPanelFilterDelay;
  FOptions := TDatabaseGridDefault.SearchPanelOptions;
  FItems := TDatabaseGridSearchPanelItems.Create(Self);
  FItems.OnChange := ItemsChanged;
end;

destructor TDatabaseGridSearchPanel.Destroy;
begin
  FItems.OnChange := nil;
  FItems.Free;

  inherited Destroy;
end;

procedure TDatabaseGridSearchPanel.Assign(ASource: TPersistent);
begin
  if Assigned(ASource) and (ASource is TDatabaseGridSearchPanel) then
  with ASource as TDatabaseGridSearchPanel do
  begin
    Self.FFilterDelay := FFilterDelay;
    Self.FOptions := FOptions;
    Self.FText := FText;
    Self.FTextHint := FTextHint;
    Self.FVisible := FVisible;
    Self.FItems.Assign(FItems);

    Self.DoChange;
  end
  else
    inherited Assign(ASource);
end;

function TDatabaseGridSearchPanel.IsItemsStored: Boolean;
begin
  Result := FItems.Count > 0;
end;

function TDatabaseGridSearchPanel.GetOwner: TPersistent;
begin
  Result := FOwner;
end;

procedure TDatabaseGridSearchPanel.DoChange;
begin
  if Assigned(FOnChange) then
    FOnChange(Self);
end;

procedure TDatabaseGridSearchPanel.ItemsChanged(ASender: TObject);
begin
  DoChange;
end;

procedure TDatabaseGridSearchPanel.SetFilterDelay(const AValue: Integer);
begin
  FFilterDelay := Max(AValue, 0);
end;

procedure TDatabaseGridSearchPanel.SetItems(const AValue: TDatabaseGridSearchPanelItems);
begin
  FItems.Assign(AValue);
end;

procedure TDatabaseGridSearchPanel.SetOption(const AOption: TDatabaseGridSearchPanelOption; const AEnabled: Boolean);
begin
  if AEnabled then
    SetOptions(FOptions + [AOption])
  else
    SetOptions(FOptions - [AOption]);
end;

procedure TDatabaseGridSearchPanel.SetOptions(const AValue: TDatabaseGridSearchPanelOptions);
begin
  if FOptions <> AValue then
  begin
    FOptions := AValue;

    DoChange;
  end;
end;

procedure TDatabaseGridSearchPanel.SetText(const AValue: string);
begin
  if FText <> AValue then
  begin
    FText := AValue;

    DoChange;
  end;
end;

procedure TDatabaseGridSearchPanel.SetTextHint(const AValue: string);
begin
  if FTextHint <> AValue then
  begin
    FTextHint := AValue;

    DoChange;
  end;
end;

procedure TDatabaseGridSearchPanel.Clear;
begin
  SetText('');
end;

function TDatabaseGridSearchPanel.Focused: Boolean;
begin
  Result := FocusedControl <> nil;
end;

function TDatabaseGridSearchPanel.FocusedControl: TWinControl;
begin
  if Assigned(FOnGetFocusedControl) then
    Result := FOnGetFocusedControl
  else
    Result := nil;
end;

function TDatabaseGridSearchPanel.IsAnyItemFiltering: Boolean;
begin
  for var LIndex := 0 to FItems.Count - 1 do
  if FItems[LIndex].IsFiltering then
    Exit(True);

  Result := False;
end;

procedure TDatabaseGridSearchPanel.SetFocus;
begin
  if Assigned(FOnSetFocus) then
    FOnSetFocus(Self);
end;

procedure TDatabaseGridSearchPanel.SetVisible(const AValue: Boolean);
begin
  if FVisible <> AValue then
  begin
    FVisible := AValue;

    DoChange;
  end;
end;

end.
