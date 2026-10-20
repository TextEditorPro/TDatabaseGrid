unit DatabaseGrid.Design.Editors;

interface

uses
  System.Classes, System.Generics.Collections, System.Types, Vcl.Graphics, DatabaseGrid, ColnEdit, DesignEditors, DesignIntf;

type
  TDatabaseGridColumnsEditor = class(TCollectionEditor)
  protected
    function CanAdd(AIndex: Integer): Boolean; override;
  end;

  TDatabaseGridColumnsProperty = class(TCollectionProperty)
  public
    function GetEditorClass: TCollectionEditorClass; override;
  end;

  TDatabaseGridComponentEditor = class(TComponentEditor)
  public
    function GetVerb(AIndex: Integer): string; override;
    function GetVerbCount: Integer; override;
    procedure ExecuteVerb(AIndex: Integer); override;
  end;

  TDatabaseGridIDEDesignHook = class(TDatabaseGridDesignHook)
  strict private
    FDesignNotification: IDesignNotification;
    FGrids: TList<TCustomDatabaseGrid>;
    FImages: TObjectDictionary<string, TGraphic>;
  public
    constructor Create;
    destructor Destroy; override;
    function GetComponentImage(const AComponent: TComponent; const ASize: Integer): TGraphic; override;
    function IsComponentSelected(const AInstance: TPersistent): Boolean; override;
    procedure InvalidateGrids;
    procedure RegisterGrid(const AGrid: TCustomDatabaseGrid); override;
    procedure SelectComponent(const AInstance: TPersistent); override;
    procedure ShowComponentMenu(const AComponent: TComponent; const AScreenPoint: TPoint); override;
    procedure UnregisterGrid(const AGrid: TCustomDatabaseGrid); override;
  end;

  TDatabaseGridDesignNotification = class(TInterfacedObject, IDesignNotification)
  strict private
    FDesignHook: TDatabaseGridIDEDesignHook;
  public
    constructor Create(const ADesignHook: TDatabaseGridIDEDesignHook);
    procedure DesignerClosed(const ADesigner: IDesigner; AGoingDormant: Boolean);
    procedure DesignerOpened(const ADesigner: IDesigner; AResurrecting: Boolean);
    procedure ItemDeleted(const ADesigner: IDesigner; AItem: TPersistent);
    procedure ItemInserted(const ADesigner: IDesigner; AItem: TPersistent);
    procedure ItemsModified(const ADesigner: IDesigner);
    procedure SelectionChanged(const ADesigner: IDesigner; const ASelection: IDesignerSelections);
  end;

implementation

uses
  System.SysUtils, DatabaseGrid.Columns, DatabaseGrid.Design.ComponentImages, DatabaseGrid.Language, DesignMenus;

const
  VERB_COLUMNS_EDITOR = 0;
  VERB_ADD_ALL_FIELDS = 1;
  VERB_DELETE_ALL_COLUMNS = 2;
  VERB_COUNT = 3;

{ TDatabaseGridColumnsEditor }

function TDatabaseGridColumnsEditor.CanAdd(AIndex: Integer): Boolean;
begin
  Result := Assigned(Collection) and not (Collection as TDatabaseGridColumns).AutoCreated;
end;

{ TDatabaseGridColumnsProperty }

function TDatabaseGridColumnsProperty.GetEditorClass: TCollectionEditorClass;
begin
  Result := TDatabaseGridColumnsEditor;
end;

{ TDatabaseGridComponentEditor }

function TDatabaseGridComponentEditor.GetVerb(AIndex: Integer): string;
begin
  case AIndex of
    VERB_COLUMNS_EDITOR:
      Result := SDatabaseGridColumnsEditor;
    VERB_ADD_ALL_FIELDS:
      Result := SDatabaseGridAddAllFields;
    VERB_DELETE_ALL_COLUMNS:
      Result := SDatabaseGridDeleteAllColumns;
  else
    Result := '';
  end;
end;

function TDatabaseGridComponentEditor.GetVerbCount: Integer;
begin
  Result := VERB_COUNT;
end;

procedure TDatabaseGridComponentEditor.ExecuteVerb(AIndex: Integer);
var
  LGrid: TCustomDatabaseGrid;
begin
  LGrid := Component as TCustomDatabaseGrid;

  case AIndex of
    VERB_COLUMNS_EDITOR:
      ShowCollectionEditorClass(Designer, TDatabaseGridColumnsEditor, LGrid, LGrid.Columns, 'Columns');
    VERB_ADD_ALL_FIELDS:
      begin
        LGrid.AddFieldColumns;

        Designer.Modified;
      end;
    VERB_DELETE_ALL_COLUMNS:
      begin
        LGrid.Columns.Clear;

        Designer.Modified;
      end;
  end;
end;

{ TDatabaseGridIDEDesignHook }

constructor TDatabaseGridIDEDesignHook.Create;
begin
  inherited Create;

  FGrids := TList<TCustomDatabaseGrid>.Create;
  FImages := TObjectDictionary<string, TGraphic>.Create([doOwnsValues]);
  FDesignNotification := TDatabaseGridDesignNotification.Create(Self);

  RegisterDesignNotification(FDesignNotification);
end;

destructor TDatabaseGridIDEDesignHook.Destroy;
begin
  UnregisterDesignNotification(FDesignNotification);
  FDesignNotification := nil;

  FGrids.Free;
  FImages.Free;

  inherited Destroy;
end;

function TDatabaseGridIDEDesignHook.GetComponentImage(const AComponent: TComponent; const ASize: Integer): TGraphic;
var
  LKey: string;
begin
  LKey := Format('%s:%d', [AComponent.ClassName, ASize]);

  if not FImages.TryGetValue(LKey, Result) then
  begin
    Result := LoadComponentImage(AComponent.ClassType, ASize);

    FImages.Add(LKey, Result);
  end;
end;

function TDatabaseGridIDEDesignHook.IsComponentSelected(const AInstance: TPersistent): Boolean;
var
  LDesigner: IDesigner;
  LSelections: IDesignerSelections;
begin
  if not Supports(FindRootDesigner(AInstance), IDesigner, LDesigner) then
    Exit(False);

  LSelections := CreateSelectionList;
  LDesigner.GetSelections(LSelections);

  for var LIndex := 0 to LSelections.Count - 1 do
  if LSelections[LIndex] = AInstance then
    Exit(True);

  Result := False;
end;

procedure TDatabaseGridIDEDesignHook.InvalidateGrids;
begin
  for var LIndex := 0 to FGrids.Count - 1 do
    FGrids[LIndex].InvalidateDesignSelection;
end;

procedure TDatabaseGridIDEDesignHook.RegisterGrid(const AGrid: TCustomDatabaseGrid);
begin
  if not FGrids.Contains(AGrid) then
    FGrids.Add(AGrid);
end;

procedure TDatabaseGridIDEDesignHook.SelectComponent(const AInstance: TPersistent);
var
  LDesigner: IDesigner;
begin
  if Supports(FindRootDesigner(AInstance), IDesigner, LDesigner) then
    LDesigner.SelectComponent(AInstance);
end;

procedure TDatabaseGridIDEDesignHook.ShowComponentMenu(const AComponent: TComponent; const AScreenPoint: TPoint);
var
  LDesigner: IDesigner;
  LLocalMenu: IDesignLocalMenu;
  LRootDesigner: IDesignerNotify;
  LSelections: IDesignerSelections;
begin
  LRootDesigner := FindRootDesigner(AComponent);

  if not Supports(LRootDesigner, IDesigner, LDesigner) or not Supports(LRootDesigner, IDesignLocalMenu, LLocalMenu) then
    Exit;

  LDesigner.SelectComponent(AComponent);

  LSelections := CreateSelectionList;
  LDesigner.GetSelections(LSelections);

  LLocalMenu.BuildLocalMenu(LSelections, [lmComponent]).Popup(AScreenPoint.X, AScreenPoint.Y);
end;

procedure TDatabaseGridIDEDesignHook.UnregisterGrid(const AGrid: TCustomDatabaseGrid);
begin
  FGrids.Remove(AGrid);
end;

{ TDatabaseGridDesignNotification }

constructor TDatabaseGridDesignNotification.Create(const ADesignHook: TDatabaseGridIDEDesignHook);
begin
  inherited Create;

  FDesignHook := ADesignHook;
end;

procedure TDatabaseGridDesignNotification.DesignerClosed(const ADesigner: IDesigner; AGoingDormant: Boolean);
begin
end;

procedure TDatabaseGridDesignNotification.DesignerOpened(const ADesigner: IDesigner; AResurrecting: Boolean);
begin
end;

procedure TDatabaseGridDesignNotification.ItemDeleted(const ADesigner: IDesigner; AItem: TPersistent);
begin
end;

procedure TDatabaseGridDesignNotification.ItemInserted(const ADesigner: IDesigner; AItem: TPersistent);
begin
end;

procedure TDatabaseGridDesignNotification.ItemsModified(const ADesigner: IDesigner);
begin
end;

procedure TDatabaseGridDesignNotification.SelectionChanged(const ADesigner: IDesigner; const ASelection: IDesignerSelections);
begin
  FDesignHook.InvalidateGrids;
end;

initialization
  GDatabaseGridDesignHook := TDatabaseGridIDEDesignHook.Create;

finalization
  FreeAndNil(GDatabaseGridDesignHook);

end.
