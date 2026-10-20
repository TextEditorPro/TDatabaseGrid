unit DatabaseGrid;

{$I DatabaseGrid.Defines.inc}

interface

uses
  Winapi.Messages, Winapi.Windows, System.Classes, System.Generics.Collections, System.Types, System.UITypes, Vcl.Controls, Vcl.ExtCtrls,
  Vcl.Forms, Vcl.Graphics, Vcl.Menus, Data.DB, DatabaseGrid.Border, DatabaseGrid.Colors, DatabaseGrid.ColumnFilter,
  DatabaseGrid.ColumnFilter.Popup, DatabaseGrid.Columns, DatabaseGrid.Consts, DatabaseGrid.DataGrouping, DatabaseGrid.DataLink,
  DatabaseGrid.Editor, DatabaseGrid.Editor.Popups, DatabaseGrid.FilterController, DatabaseGrid.Footer, DatabaseGrid.FooterCalculator,
  DatabaseGrid.Groups, DatabaseGrid.Indicator, DatabaseGrid.Layout, DatabaseGrid.Painter, DatabaseGrid.SearchPanel,
  DatabaseGrid.SearchPanel.Controls, DatabaseGrid.SelectedRows, DatabaseGrid.Title, DatabaseGrid.Types
{$IFDEF DATABASE_GRID_VCL_STYLES}
  , Vcl.Themes, DatabaseGrid.StyleHooks
{$ENDIF}
{$IFDEF ALPHASKINS}
  , acSBUtils, sCommonData
{$ENDIF};

type
  TDatabaseGridCellHintEvent = procedure(ASender: TObject; const AColumn: TDatabaseGridColumn; var AHint: string) of object;
  TDatabaseGridColumnEvent = procedure(ASender: TObject; const AColumn: TDatabaseGridColumn) of object;
  TDatabaseGridDrawColumnCellEvent = procedure(ASender: TObject; const AColumn: TDatabaseGridColumn; const ACanvas: TCanvas;
    const ARect: TRect; const AState: TDatabaseGridDrawCellStates; var AParams: TDatabaseGridDrawCellParams) of object;
  TDatabaseGridDrawFooterCellEvent = procedure(ASender: TObject; const AColumn: TDatabaseGridColumn; const ACanvas: TCanvas;
    const ARect: TRect; var AParams: TDatabaseGridDrawCellParams) of object;
  TDatabaseGridDrawGroupRowEvent = procedure(ASender: TObject; const ANode: TDatabaseGridGroupNode; const ACanvas: TCanvas;
    const ARect: TRect; const AState: TDatabaseGridDrawCellStates; var AParams: TDatabaseGridDrawGroupRowParams) of object;
  TDatabaseGridJumpToColumnEvent = procedure(ASender: TObject; var AColumn: TDatabaseGridColumn) of object;
  TDatabaseGridMoveRecordEvent = procedure(ASender: TObject; const AFromIndex, AToIndex: Integer) of object;
  TDatabaseGridTitleMenuPopupEvent = procedure(ASender: TObject; const AMenu: TPopupMenu) of object;

  TCustomDatabaseGrid = class;

  TDatabaseGridDesignHook = class abstract(TObject)
  public
    function GetComponentImage(const AComponent: TComponent; const ASize: Integer): TGraphic; virtual; abstract;
    function IsComponentSelected(const AInstance: TPersistent): Boolean; virtual; abstract;
    procedure RegisterGrid(const AGrid: TCustomDatabaseGrid); virtual; abstract;
    procedure SelectComponent(const AInstance: TPersistent); virtual; abstract;
    procedure ShowComponentMenu(const AComponent: TComponent; const AScreenPoint: TPoint); virtual; abstract;
    procedure UnregisterGrid(const AGrid: TCustomDatabaseGrid); virtual; abstract;
  end;

  TCustomDatabaseGrid = class abstract(TCustomControl)
  strict private type
    TDatabaseGridMouse = record
      CellSelecting: Boolean;
      ClickColumn: TDatabaseGridColumn;
      DropIndex: Integer;
      MoveFromIndex: Integer;
      RecordMoving: Boolean;
      CheckBoxRowOffset: Integer;
      CheckBoxSelected: Boolean;
      CheckBoxSelecting: Boolean;
      Column: TDatabaseGridColumn;
      DownArea: TDatabaseGridArea;
      DragPoint: TPoint;
      ResizeOrigin: Integer;
      ResizeWidth: Integer;
      Resizing: Boolean;
      ScrollDelta: TPoint;
      Scrolling: Boolean;
      ScrollingPoint: TPoint;
      TitlePressed: Boolean;
      ZoomWheelDelta: Integer;
    end;

    TDatabaseGridScrollHelper = record
      NotifiedHorizontalPosition: Integer;
      NotifiedTopRow: Integer;
      TopRow: Integer;
      TrimPending: Boolean;
{$IFDEF ALPHASKINS}
      Wnd: TacScrollWnd;
{$ENDIF}
    end;

  strict private
    FBorder: TDatabaseGridBorder;
    FColors: TDatabaseGridColors;
    FColumnFilter: TDatabaseGridColumnFilter;
    FColumnFilterClosedByClick: TDatabaseGridColumn;
    FColumnFilterClosedTicks: UInt64;
    FColumnFilterPopup: TDatabaseGridColumnFilterPopup;
    FColumnFilterPopupWidth: Integer;
    FColumns: TDatabaseGridColumns;
    FCurrentColumnIndex: Integer;
    FDataGrouping: TDatabaseGridDataGrouping;
    FDataLink: TDatabaseGridDataLink;
    FDragScrollTimer: TTimer;
    FDropDownList: TDatabaseGridDropDownList;
    FEditColumn: TDatabaseGridColumn;
    FEditor: TDatabaseGridEditor;
    FEditorModifying: Boolean;
    FEditorPopupClosedByClick: TDatabaseGridColumn;
    FEditorPopupClosedTicks: UInt64;
    FEditorTextUpdating: Boolean;
    FFilterController: TDatabaseGridFilterController;
    FFooter: TDatabaseGridFooter;
    FFooterCalculator: TDatabaseGridFooterCalculator;
    FGroups: TDatabaseGridGroups;
    FIndicator: TDatabaseGridIndicator;
    FLayout: TDatabaseGridLayout;
    FLayoutUpdating: Boolean;
    FLookupKeys: TArray<Variant>;
    FMouse: TDatabaseGridMouse;
    FMouseScrollTimer: TTimer;
    FOnAfterApplyFilter: TNotifyEvent;
    FOnCellClick: TDatabaseGridColumnEvent;
    FOnCellHint: TDatabaseGridCellHintEvent;
    FOnColumnResize: TDatabaseGridColumnEvent;
    FOnDrawColumnCell: TDatabaseGridDrawColumnCellEvent;
    FOnDrawFooterCell: TDatabaseGridDrawFooterCellEvent;
    FOnDrawGroupRow: TDatabaseGridDrawGroupRowEvent;
    FOnEditButtonClick: TDatabaseGridColumnEvent;
    FOnExport: TNotifyEvent;
    FOnGroupExpandedChange: TDatabaseGridGroupNodeEvent;
    FOnIndicatorTitleMenuPopup: TDatabaseGridTitleMenuPopupEvent;
    FOnJumpToColumn: TDatabaseGridJumpToColumnEvent;
    FOnMoveRecord: TDatabaseGridMoveRecordEvent;
    FOnRefresh: TNotifyEvent;
    FOnScroll: TNotifyEvent;
    FOnSearchFilter: TNotifyEvent;
    FOnSelectionChanged: TNotifyEvent;
    FOnSortMarkingChanged: TNotifyEvent;
    FOnTitleClick: TDatabaseGridColumnEvent;
    FOnZoomChange: TNotifyEvent;
    FOptions: TDatabaseGridOptions;
    FPainter: TDatabaseGridPainter;
    FPaintLock: Integer;
    FPopupColumn: TDatabaseGridColumn;
    FRangeAnchor: TBookmark;
    FRangeAnchorColumn: TDatabaseGridColumn;
    FReadOnly: Boolean;
    FScrollHelper: TDatabaseGridScrollHelper;
    FSearchPanel: TDatabaseGridSearchPanel;
    FSearchPanelControls: TDatabaseGridSearchPanelControls;
    FSelectedRows: TDatabaseGridSelectedRows;
{$IFDEF ALPHASKINS}
    FSkinData: TsScrollWndData;
{$ENDIF}
    FSortingApplied: Boolean;
    FSortMarkedColumns: TList<TDatabaseGridColumn>;
    FStyledColors: TDatabaseGridColors;
    FTitle: TDatabaseGridTitle;
    FTitleMenu: TPopupMenu;
    FZoomPercentage: Integer;
    function ApplyFilters: Boolean;
    function ApplyDataSetSorting(const ACanReopen: Boolean): Boolean;
    function CanEditColumn(const AColumn: TDatabaseGridColumn): Boolean;
    function CanEditCurrentCell: Boolean;
    function CanMoveRecords: Boolean;
    function CanRunSelectionCommand(const ACommand: TDatabaseGridTitleMenuCommand): Boolean;
    function CanSelectRows: Boolean;
    function CreateMeasureBitmap: TBitmap;
    function EditorBeginModify: Boolean;
    function GetCurrentCellScreenRect: TRect;
    function GetCurrentColumn: TDatabaseGridColumn;
    function GetCurrentRow: Integer;
    function GetDataSource: TDataSource;
    function GetDesignColumnAt(const AX, AY: Integer): TDatabaseGridColumn;
    function GetDesignLinkAt(const AX, AY: Integer): TComponent;
    function GetDesignLinkRect(const AIndex, ACount: Integer): TRect;
    function GetDesignLinks: TArray<TComponent>;
    function GetDropDownList: TDatabaseGridDropDownList;
    function GetEditorMode: Boolean;
    function GetHorizontalPosition: Integer;
    function GetMaxTopRow: Integer;
    function GetMouseScrollCursor: HCURSOR;
    function GetMouseScrollIndicatorRect: TRect;
    function GetNextAutoFitColumn(const AColumn: TDatabaseGridColumn): TDatabaseGridColumn;
    function GetRangeBookmarks(out AStart, AEnd: TBookmark): Boolean;
    function GetResizeColumnAt(const AX, AY: Integer): TDatabaseGridColumn;
    function GetSelectedCells(out ABookmarks: TArray<TBookmark>; out AColumns: TArray<TDatabaseGridColumn>): Boolean;
    function GetRowAt(const AY: Integer): Integer;
    function GetRowCount: Integer;
    function GetRowHeight(const ARow: Integer): Integer;
    function GetRowOffset: Integer;
    function GetRowRecord(const ARow: Integer): Integer;
    function GetRowTop(const ARow: Integer): Integer;
    function GetThumbPosition(const ARange, APosition: Integer): Integer;
    function GetTitleButtonColumnAt(const AX, AY: Integer): TDatabaseGridColumn;
    function GetTopRow: Integer;
    function GetTopRowShowing(const ARow: Integer): Integer;
    function GetTotalRowCount: Integer;
    function GetVisibleRowCount: Integer;
    function HandleDesignMouseMessage(var AMessage: TMessage): Boolean;
    function HandleEditingKey(const AKey: Word; const AShift: TShiftState): Boolean;
    function HasEditButton(const AColumn: TDatabaseGridColumn; out AGlyph: TDatabaseGridGlyph): Boolean;
    function IsAutoFitColumn(const AColumn: TDatabaseGridColumn): Boolean;
    function IsCellMode: Boolean;
    function IsCheckBoxAt(const AColumn: TDatabaseGridColumn; const ALeft, AX, AY: Integer): Boolean;
    function IsColumnsStored: Boolean;
    function IsDropDownVisible: Boolean;
    function IsEditButtonAt(const AX, AY: Integer): Boolean;
    function IsInlineEditor(const AColumn: TDatabaseGridColumn): Boolean;
    function IsReadOnlyColumn(const AColumn: TDatabaseGridColumn): Boolean;
    function IsRecordRow: Boolean;
    function IsRowSelected(const ARow: Integer): Boolean;
    function MeasureTitleWidth(const ACanvas: TCanvas; const AColumn: TDatabaseGridColumn): Integer;
    function MoveRowBy(const ADistance: Integer): Boolean;
    function ScaleMetric(const AValue: Integer): Integer;
    procedure BindColumns;
    procedure BorderChanged(ASender: TObject);
    procedure BorderStyleChanged(ASender: TObject);
    procedure AcceptDropDownItem(const AIndex: Integer);
    procedure BufferVisibleRows;
    procedure CalculateLayout;
    procedure BuildTitleMenu;
    procedure CalendarPopupAccept(ASender: TObject; const AValue: TDateTime);
    procedure ChangeSortMarker(const AColumn: TDatabaseGridColumn; const AAppend: Boolean);
    procedure CMDesignHitTest(var AMessage: TCMDesignHitTest); message CM_DESIGNHITTEST;
    procedure CMFontChanged(var AMessage: TMessage); message CM_FONTCHANGED;
    procedure CMHintShow(var AMessage: TCMHintShow); message CM_HINTSHOW;
    procedure CMMouseLeave(var AMessage: TMessage); message CM_MOUSELEAVE;
    procedure CMStyleChanged(var AMessage: TMessage); message CM_STYLECHANGED;
    procedure CMWantSpecialKey(var AMessage: TCMWantSpecialKey); message CM_WANTSPECIALKEY;
    procedure ClearColumnValue(const AColumn: TDatabaseGridColumn);
    procedure ClearCurrentCell;
    procedure CloseDropDown;
    procedure CollapseCellRange;
    procedure ColumnFilterPopupClearAllColumnFilters(ASender: TObject);
    procedure ColumnFilterPopupClose(ASender: TObject; var AAction: TCloseAction);
    procedure ColumnFilterPopupSort(ASender: TObject; const AColumn: TDatabaseGridColumn; const ASortMarker: TDatabaseGridSortMarker);
    procedure ColumnsChanged(ASender: TObject);
    procedure ColumnsFilterChanged(ASender: TObject);
    procedure DataGroupingChanged(ASender: TObject);
    procedure DataLinkActiveChanged(ASender: TObject);
    procedure DataLinkDataChanged(const ARowShift: Integer; const ACurrentRowChanged, ADataSetChanged: Boolean);
    procedure DataLinkDisabledStateChanged(ASender: TObject);
    procedure DataLinkEditingChanged(ASender: TObject);
    procedure DataLinkFocusControl(var AField: TField);
    procedure DataLinkLayoutChanged(ASender: TObject);
    procedure DataLinkRecordChanged(const AField: TField);
    procedure DataLinkUpdateData(ASender: TObject);
    procedure DataMouseDown(const AShift: TShiftState; const AX, AY: Integer; const AWasFocused: Boolean);
    procedure DeleteRecord;
    procedure DoEditButtonClick;
    procedure DragScrollTimerTimer(ASender: TObject);
    procedure DropDown;
    procedure DropDownListAccept(ASender: TObject);
    procedure DrawColumnCell(const AColumn: TDatabaseGridColumn; const ACanvas: TCanvas; const ARect: TRect;
      const AState: TDatabaseGridDrawCellStates; var AParams: TDatabaseGridDrawCellParams);
    procedure DrawFooterCell(const AColumn: TDatabaseGridColumn; const ACanvas: TCanvas; const ARect: TRect;
      const AState: TDatabaseGridDrawCellStates; var AParams: TDatabaseGridDrawCellParams);
    procedure DrawGroupRow(const ANode: TDatabaseGridGroupNode; const ACanvas: TCanvas; const ARect: TRect;
      const AState: TDatabaseGridDrawCellStates; var AParams: TDatabaseGridDrawGroupRowParams);
    procedure EditCurrentCell(const ASelectAll: Boolean);
    procedure EditorChange(ASender: TObject);
    procedure EditorExit(ASender: TObject);
    procedure EditorKeyCommand(var AKey: Word; const AShift: TShiftState);
    procedure EditorPopupClose(ASender: TObject; var AAction: TCloseAction);
    procedure EndEdit;
    procedure ExtendCellRange;
    procedure FitColumnsToTitles;
    procedure GroupKeyDown(const AKey: Word; const AShift: TShiftState);
    procedure GroupsChanged(ASender: TObject);
    procedure GroupsExpandedChange(ASender: TObject; const ANode: TDatabaseGridGroupNode);
    procedure HideEditor;
    procedure IndicatorChanged(ASender: TObject);
    procedure InsertRecord;
    procedure InvalidateFooterValues;
    procedure InvalidateTitle(const AColumn: TDatabaseGridColumn);
    procedure LoadDropDownItems(const AColumn: TDatabaseGridColumn);
    procedure MemoPopupAccept(ASender: TObject; const AText: string);
    procedure MouseScrollTimerTimer(ASender: TObject);
    procedure MoveCurrentColumn(const ADistance: Integer);
    procedure MoveToNextCell(const AForward: Boolean);
    procedure MoveToRow(const ARow: Integer);
    procedure PaintDesignColumns;
    procedure PaintDesignHandles(const ARect: TRect);
    procedure PaintDesignLinks;
    procedure PaintDesignSelection;
    procedure PostFooterCalculation;
    procedure PressEditButton;
    procedure PropertiesChanged(ASender: TObject);
    procedure ResizeColumn(const AColumn: TDatabaseGridColumn; const AWidth: Integer);
    procedure ScrollColumnIntoView(const AColumn: TDatabaseGridColumn);
    procedure ScrollCurrentRowIntoView;
    procedure ScrollToRow(const ARow: Integer);
    procedure SearchPanelApplyFilter(ASender: TObject);
    procedure SearchPanelChanged(ASender: TObject);
    procedure SearchPanelRefresh(ASender: TObject);
    procedure SearchPanelSetFocus(ASender: TObject);
    procedure SelectCellsAt(const AX, AY: Integer);
    procedure SelectCheckBoxRows(const AY: Integer);
    procedure SelectedRowsChanged(ASender: TObject);
    procedure SelectRowRange(const AFirstRow, ALastRow: Integer; const ASelected: Boolean);
    procedure SetBorder(const AValue: TDatabaseGridBorder);
    procedure SetColumnText(const AColumn: TDatabaseGridColumn; const AText: string);
    procedure SetColors(const AValue: TDatabaseGridColors);
    procedure SetColumnFilter(const AValue: TDatabaseGridColumnFilter);
    procedure SetColumns(const AValue: TDatabaseGridColumns);
    procedure SetCurrentColumn(const AValue: TDatabaseGridColumn);
    procedure SetDataGrouping(const AValue: TDatabaseGridDataGrouping);
    procedure SetDataSource(const AValue: TDataSource);
    procedure SetEditorMode(const AValue: Boolean);
    procedure SetEditorText(const AText: string; const AModified: Boolean);
    procedure SetFooter(const AValue: TDatabaseGridFooter);
    procedure SetHorizontalPosition(const AValue: Integer);
    procedure SetHotTitleColumn(const AValue: TDatabaseGridColumn);
    procedure SetIndicator(const AValue: TDatabaseGridIndicator);
    procedure SetOptions(const AValue: TDatabaseGridOptions);
    procedure SetReadOnly(const AValue: Boolean);
    procedure SetScrollBar(const ABar, ARange, APage, APosition: Integer);
    procedure SetSearchPanel(const AValue: TDatabaseGridSearchPanel);
    procedure SetTitle(const AValue: TDatabaseGridTitle);
    procedure SetTopRow(const AValue: Integer);
    procedure SetZoomPercentage(const AValue: Integer);
    procedure ShowCalendarPopup;
    procedure ShowEditor(const ASelectAll: Boolean);
    procedure ShowIndicatorTitleMenu;
    procedure ShowMemoPopup;
    procedure StartMouseScrolling(const AX, AY: Integer);
    procedure StopMouseScrolling;
    procedure TitleClick(const AColumn: TDatabaseGridColumn; const AShift: TShiftState);
    procedure TitleMenuItemClick(ASender: TObject);
    procedure ToggleCheckBox;
    procedure UpdateDataSetFeatures;
    procedure UpdateDragScrolling(const AX, AY: Integer);
    procedure UpdateDropIndex(const AY: Integer);
    procedure UpdateEditorBounds;
    procedure UpdateGroups;
    procedure UpdateLayout;
    procedure UpdateMetrics;
    procedure UpdateMouseScrolling(const AX, AY: Integer);
    procedure UpdateSortMarkedColumns;
    procedure UpdateStyledColors;
    procedure WMApplyDataSetFeatures(var AMessage: TMessage); message TDatabaseGridMessage.WM_APPLY_DATASET_FEATURES;
    procedure WMCalculateFooter(var AMessage: TMessage); message TDatabaseGridMessage.WM_CALCULATE_FOOTER;
    procedure WMCommand(var AMessage: TWMCommand); message WM_COMMAND;
    procedure WMEraseBkgnd(var AMessage: TWMEraseBkgnd); message WM_ERASEBKGND;
    procedure WMFocus(var AMessage: TMessage); message TDatabaseGridMessage.WM_FOCUS;
    procedure WMGetDlgCode(var AMessage: TWMGetDlgCode); message WM_GETDLGCODE;
    procedure WMHScroll(var AMessage: TWMScroll); message WM_HSCROLL;
    procedure WMKillFocus(var AMessage: TWMKillFocus); message WM_KILLFOCUS;
    procedure WMLButtonDblClk(var AMessage: TWMLButtonDblClk); message WM_LBUTTONDBLCLK;
    procedure WMNCCalcSize(var AMessage: TWMNCCalcSize); message WM_NCCALCSIZE;
    procedure WMNCPaint(var AMessage: TWMNCPaint); message WM_NCPAINT;
    procedure WMRedrawSearchPanel(var AMessage: TMessage); message TDatabaseGridMessage.WM_REDRAW_SEARCH_PANEL;
    procedure WMSetCursor(var AMessage: TWMSetCursor); message WM_SETCURSOR;
    procedure WMSetFocus(var AMessage: TWMSetFocus); message WM_SETFOCUS;
    procedure WMTrimBuffer(var AMessage: TMessage); message TDatabaseGridMessage.WM_TRIM_BUFFER;
    procedure WMVScroll(var AMessage: TWMScroll); message WM_VSCROLL;
    procedure WriteEditorText;
    procedure WriteLookupKey(const AKey: Variant);
    procedure WriteLookupText(const AText: string);
  protected
    function DoMouseWheel(AShift: TShiftState; AWheelDelta: Integer; AMousePos: TPoint): Boolean; override;
    procedure ChangeScale(AMultiplier, ADivider: Integer; AIsDpiChange: Boolean); override;
    procedure CreateParams(var AParams: TCreateParams); override;
    procedure CreateWnd; override;
    procedure KeyDown(var AKey: Word; AShift: TShiftState); override;
    procedure KeyPress(var AKey: Char); override;
    procedure MouseDown(AButton: TMouseButton; AShift: TShiftState; AX, AY: Integer); override;
    procedure MouseMove(AShift: TShiftState; AX, AY: Integer); override;
    procedure MouseUp(AButton: TMouseButton; AShift: TShiftState; AX, AY: Integer); override;
    procedure Notification(AComponent: TComponent; AOperation: TOperation); override;
    procedure Paint; override;
    procedure PaintBorder;
{$IFDEF DATABASE_GRID_VCL_STYLES}
    procedure PaintStyledFrame;
{$ENDIF}
    procedure Resize; override;
    procedure WndProc(var AMessage: TMessage); override;
  public
{$IFDEF DATABASE_GRID_VCL_STYLES}
    class constructor Create;
    class destructor Destroy;
{$ENDIF}
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    function CanEdit: Boolean;
    function GetAreaAt(const AX, AY: Integer): TDatabaseGridArea;
    procedure AddFieldColumns;
    procedure AfterConstruction; override;
    procedure ApplySearchFilter;
    procedure AutoSizeColumns(const AMaxRowCount: Integer = TDatabaseGridDefault.AutoSizeRowCount);
    procedure ApplySorting;
    procedure BeginUpdate;
    procedure ClearColumnFilters;
    procedure ClearSelectedCells;
    procedure CopyToClipboard(const ACopyTitles: Boolean = True);
    procedure CutToClipboard;
    procedure EndUpdate;
    procedure GetTabOrderList(AList: TList); override;
    procedure InvalidateDesignSelection;
    procedure InvertRowSelection;
    procedure JumpToColumn;
    procedure Loaded; override;
    procedure PasteFromClipboard;
    procedure RefreshData;
    procedure SelectAllCells;
    procedure SelectAllRows;
    procedure SetOption(const AOption: TDatabaseGridOption; const AEnabled: Boolean);
    procedure SetSortMarker(const AColumn: TDatabaseGridColumn; const ASortMarker: TDatabaseGridSortMarker; const AAppend: Boolean = False);
    procedure ShowColumnFilterPopup(const AColumn: TDatabaseGridColumn);
    procedure ShowExportDialog;
    procedure ZoomIn;
    procedure ZoomOut;
    procedure ZoomReset;
    property Border: TDatabaseGridBorder read FBorder write SetBorder;
    property Colors: TDatabaseGridColors read FColors write SetColors;
    property ColumnFilter: TDatabaseGridColumnFilter read FColumnFilter write SetColumnFilter;
    property Columns: TDatabaseGridColumns read FColumns write SetColumns stored IsColumnsStored;
    property CurrentColumn: TDatabaseGridColumn read GetCurrentColumn write SetCurrentColumn;
    property DataGrouping: TDatabaseGridDataGrouping read FDataGrouping write SetDataGrouping;
    property DataSource: TDataSource read GetDataSource write SetDataSource;
    property EditorMode: Boolean read GetEditorMode write SetEditorMode;
    property Footer: TDatabaseGridFooter read FFooter write SetFooter;
    property Groups: TDatabaseGridGroups read FGroups;
    property HorizontalPosition: Integer read GetHorizontalPosition write SetHorizontalPosition;
    property InplaceEditor: TDatabaseGridEditor read FEditor;
    property Indicator: TDatabaseGridIndicator read FIndicator write SetIndicator;
    property OnAfterApplyFilter: TNotifyEvent read FOnAfterApplyFilter write FOnAfterApplyFilter;
    property OnCellClick: TDatabaseGridColumnEvent read FOnCellClick write FOnCellClick;
    property OnCellHint: TDatabaseGridCellHintEvent read FOnCellHint write FOnCellHint;
    property OnColumnResize: TDatabaseGridColumnEvent read FOnColumnResize write FOnColumnResize;
    property OnDrawColumnCell: TDatabaseGridDrawColumnCellEvent read FOnDrawColumnCell write FOnDrawColumnCell;
    property OnDrawFooterCell: TDatabaseGridDrawFooterCellEvent read FOnDrawFooterCell write FOnDrawFooterCell;
    property OnDrawGroupRow: TDatabaseGridDrawGroupRowEvent read FOnDrawGroupRow write FOnDrawGroupRow;
    property OnEditButtonClick: TDatabaseGridColumnEvent read FOnEditButtonClick write FOnEditButtonClick;
    property OnExport: TNotifyEvent read FOnExport write FOnExport;
    property OnGroupExpandedChange: TDatabaseGridGroupNodeEvent read FOnGroupExpandedChange write FOnGroupExpandedChange;
    property OnIndicatorTitleMenuPopup: TDatabaseGridTitleMenuPopupEvent read FOnIndicatorTitleMenuPopup write FOnIndicatorTitleMenuPopup;
    property OnJumpToColumn: TDatabaseGridJumpToColumnEvent read FOnJumpToColumn write FOnJumpToColumn;
    property OnMoveRecord: TDatabaseGridMoveRecordEvent read FOnMoveRecord write FOnMoveRecord;
    property OnRefresh: TNotifyEvent read FOnRefresh write FOnRefresh;
    property OnScroll: TNotifyEvent read FOnScroll write FOnScroll;
    property OnSearchFilter: TNotifyEvent read FOnSearchFilter write FOnSearchFilter;
    property OnSelectionChanged: TNotifyEvent read FOnSelectionChanged write FOnSelectionChanged;
    property OnSortMarkingChanged: TNotifyEvent read FOnSortMarkingChanged write FOnSortMarkingChanged;
    property OnTitleClick: TDatabaseGridColumnEvent read FOnTitleClick write FOnTitleClick;
    property OnZoomChange: TNotifyEvent read FOnZoomChange write FOnZoomChange;
    property Options: TDatabaseGridOptions read FOptions write SetOptions default TDatabaseGridDefault.Options;
    property ReadOnly: Boolean read FReadOnly write SetReadOnly default False;
    property SearchPanel: TDatabaseGridSearchPanel read FSearchPanel write SetSearchPanel;
    property SelectedRows: TDatabaseGridSelectedRows read FSelectedRows;
{$IFDEF ALPHASKINS}
    property SkinData: TsScrollWndData read FSkinData write FSkinData;
{$ENDIF}
    property SortMarkedColumns: TList<TDatabaseGridColumn> read FSortMarkedColumns;
    property Title: TDatabaseGridTitle read FTitle write SetTitle;
    property TopRow: Integer read GetTopRow write SetTopRow;
    property VisibleRowCount: Integer read GetVisibleRowCount;
    property ZoomPercentage: Integer read FZoomPercentage write SetZoomPercentage default TDatabaseGridDefault.ZoomPercentage;
  end;

  [ComponentPlatformsAttribute(pidWin32 or pidWin64)]
  TDatabaseGrid = class(TCustomDatabaseGrid)
  published
    property Align;
    property AlignWithMargins;
    property Anchors;
    property Border;
    property Colors;
    property ColumnFilter;
    property Columns;
    property Constraints;
    property Ctl3D;
    property DataGrouping;
    property DataSource;
    property Footer;
    property Enabled;
    property Font;
    property Indicator;
    property Margins;
    property OnAfterApplyFilter;
    property OnCellClick;
    property OnCellHint;
    property OnClick;
    property OnColumnResize;
    property OnDblClick;
    property OnDrawColumnCell;
    property OnDrawFooterCell;
    property OnDrawGroupRow;
    property OnEditButtonClick;
    property OnEnter;
    property OnExit;
    property OnExport;
    property OnGroupExpandedChange;
    property OnIndicatorTitleMenuPopup;
    property OnJumpToColumn;
    property OnMoveRecord;
    property OnKeyDown;
    property OnKeyPress;
    property OnKeyUp;
    property OnMouseDown;
    property OnMouseMove;
    property OnMouseUp;
    property OnMouseWheel;
    property OnRefresh;
    property OnScroll;
    property OnSearchFilter;
    property OnSelectionChanged;
    property OnSortMarkingChanged;
    property OnTitleClick;
    property OnZoomChange;
    property Options;
    property ParentCtl3D;
    property ParentFont;
    property ParentShowHint;
    property PopupMenu;
    property ReadOnly;
    property SearchPanel;
    property ShowHint;
{$IFDEF ALPHASKINS}
    property SkinData;
{$ENDIF}
    property TabOrder;
    property TabStop default True;
    property Title;
    property Visible;
    property ZoomPercentage;
  end;

var
  GDatabaseGridDesignHook: TDatabaseGridDesignHook;

implementation

uses
  System.Math, System.SysUtils, System.Variants, Vcl.Clipbrd, Vcl.Dialogs, Vcl.ToolWin, DatabaseGrid.Clipboard,
  DatabaseGrid.ColumnListDialog, DatabaseGrid.DataSetFeatures, DatabaseGrid.Export, DatabaseGrid.Glyphs, DatabaseGrid.Language
{$IFDEF ALPHASKINS}
  , sConst, sGraphUtils, sMessages, sSkinManager, sStyleSimply, sVCLUtils
{$ENDIF};

{ TCustomDatabaseGrid }

{$IFDEF DATABASE_GRID_VCL_STYLES}
type
  TDatabaseGridStyleHook = class(TVclStyleScrollBarsHook)
  protected
    procedure DrawBorder; override;
    procedure PaintNC(ACanvas: TCanvas); override;
  end;

procedure TDatabaseGridStyleHook.DrawBorder;
begin
  TCustomDatabaseGrid(Control).PaintStyledFrame;
end;

procedure TDatabaseGridStyleHook.PaintNC(ACanvas: TCanvas);
begin
  inherited PaintNC(ACanvas);

  TCustomDatabaseGrid(Control).PaintBorder;
end;

class constructor TCustomDatabaseGrid.Create;
begin
  TCustomStyleEngine.RegisterStyleHook(TCustomDatabaseGrid, TDatabaseGridStyleHook);
end;

class destructor TCustomDatabaseGrid.Destroy;
begin
  TCustomStyleEngine.UnRegisterStyleHook(TCustomDatabaseGrid, TDatabaseGridStyleHook);
end;
{$ENDIF}

constructor TCustomDatabaseGrid.Create(AOwner: TComponent);
begin
{$IFDEF ALPHASKINS}
  FSkinData := TsScrollWndData.Create(Self, True);
  FSkinData.COC := COC_TsMemo;
  FSkinData.CustomColor := True;
  FSkinData.CustomFont := True;
  StyleElements := [seBorder];
{$ENDIF}

  inherited Create(AOwner);

  ControlStyle := ControlStyle + [csOpaque, csNeedsBorderPaint];
  DoubleBuffered := True;
  Height := TDatabaseGridDefault.Height;
  Width := TDatabaseGridDefault.Width;
  TabStop := True;

  FOptions := TDatabaseGridDefault.Options;
  FZoomPercentage := TDatabaseGridDefault.ZoomPercentage;

  FBorder :=TDatabaseGridBorder.Create;
  FBorder.OnChange := BorderChanged;
  FBorder.OnStyleChange := BorderStyleChanged;
  FColors := TDatabaseGridColors.Create;
  FColors.OnChange := PropertiesChanged;
  FStyledColors := TDatabaseGridColors.Create;
  FColumnFilter := TDatabaseGridColumnFilter.Create;
  FColumnFilter.OnChange := PropertiesChanged;
  FColumns := TDatabaseGridColumns.Create(Self);
  FColumns.OnChange := ColumnsChanged;
  FColumns.OnFilterChange := ColumnsFilterChanged;
  FFooter := TDatabaseGridFooter.Create;
  FFooter.OnChange := PropertiesChanged;
  FTitle := TDatabaseGridTitle.Create;
  FTitle.OnChange := PropertiesChanged;
  FDataGrouping := TDatabaseGridDataGrouping.Create(Self);
  FDataGrouping.OnChange := DataGroupingChanged;
  FDataLink := TDatabaseGridDataLink.Create;
  FDataLink.ReadOnly := True;
  FDataLink.OnActiveChanged := DataLinkActiveChanged;
  FDataLink.OnDataChanged := DataLinkDataChanged;
  FDataLink.OnDisabledStateChanged := DataLinkDisabledStateChanged;
  FDataLink.OnEditingChanged := DataLinkEditingChanged;
  FDataLink.OnFocusControl := DataLinkFocusControl;
  FDataLink.OnLayoutChanged := DataLinkLayoutChanged;
  FDataLink.OnRecordChanged := DataLinkRecordChanged;
  FDataLink.OnUpdateData := DataLinkUpdateData;
  FFilterController := TDatabaseGridFilterController.Create(FColumns);
  FFooterCalculator := TDatabaseGridFooterCalculator.Create(FColumns, FDataLink, FFilterController);
  FGroups := TDatabaseGridGroups.Create(FDataLink);
  FGroups.OnChange := GroupsChanged;
  FGroups.OnExpandedChange := GroupsExpandedChange;
  FIndicator := TDatabaseGridIndicator.Create(Self);
  FIndicator.OnChange := IndicatorChanged;
  FLayout := TDatabaseGridLayout.Create(FColumnFilter, FIndicator, FTitle);
  FSearchPanel := TDatabaseGridSearchPanel.Create(Self);
  FSearchPanel.OnChange := SearchPanelChanged;
  FSearchPanelControls := TDatabaseGridSearchPanelControls.Create(Self, FSearchPanel, FStyledColors);
  FSearchPanelControls.OnApplyFilter := SearchPanelApplyFilter;
  FSearchPanelControls.OnRefresh := SearchPanelRefresh;
  FSearchPanel.OnGetFocusedControl := FSearchPanelControls.GetFocusedControl;
  FSearchPanel.OnSetFocus := SearchPanelSetFocus;
  FSelectedRows := TDatabaseGridSelectedRows.Create(FDataLink);
  FSelectedRows.OnChange := SelectedRowsChanged;
  FSortMarkedColumns := TList<TDatabaseGridColumn>.Create;
  FPainter := TDatabaseGridPainter.Create(FStyledColors, FDataLink, FGroups, FIndicator, FLayout, FSelectedRows,
    FSortMarkedColumns);

  UpdateStyledColors;
  UpdateMetrics;
end;

destructor TCustomDatabaseGrid.Destroy;
begin
  if Assigned(GDatabaseGridDesignHook) then
    GDatabaseGridDesignHook.UnregisterGrid(Self);

{$IFDEF ALPHASKINS}
  FreeAndNil(FScrollHelper.Wnd);
  FreeAndNil(FSkinData);
{$ENDIF}

  FDataLink.OnActiveChanged := nil;
  FDataLink.OnDataChanged := nil;
  FDataLink.OnEditingChanged := nil;
  FDataLink.OnFocusControl := nil;
  FDataLink.OnLayoutChanged := nil;
  FDataLink.OnRecordChanged := nil;
  FDataLink.OnUpdateData := nil;
  FColumns.OnChange := nil;
  FColumns.OnFilterChange := nil;
  FDataGrouping.OnChange := nil;
  FGroups.OnChange := nil;
  FGroups.OnExpandedChange := nil;
  FSearchPanel.OnChange := nil;
  FSearchPanel.OnGetFocusedControl := nil;
  FSearchPanel.OnSetFocus := nil;

  FMouseScrollTimer.Free;
  FDragScrollTimer.Free;
  FFooterCalculator.Free;
  FFilterController.Free;
  FPainter.Free;
  FGroups.Free;
  FLayout.Free;
  FSearchPanelControls.Free;
  FSelectedRows.Free;
  FDataLink.Free;
  FBorder.Free;
  FColors.Free;
  FStyledColors.Free;
  FColumnFilter.Free;
  FColumns.Free;
  FDataGrouping.Free;
  FFooter.Free;
  FTitle.Free;
  FIndicator.Free;
  FSearchPanel.Free;
  FSortMarkedColumns.Free;

  inherited Destroy;
end;

procedure TCustomDatabaseGrid.AfterConstruction;
begin
  inherited AfterConstruction;

{$IFDEF ALPHASKINS}
  FSkinData.Loaded(False);

  if HandleAllocated then
    RefreshEditScrolls(SkinData, FScrollHelper.Wnd);
{$ENDIF}
end;

procedure TCustomDatabaseGrid.Loaded;
begin
  inherited Loaded;

  BindColumns;
  UpdateSortMarkedColumns;

  FSearchPanelControls.Synchronize;

  UpdateGroups;
  UpdateMetrics;
  UpdateLayout;
  InvalidateFooterValues;
{$IFDEF ALPHASKINS}
  FSkinData.Loaded(False);
{$ENDIF}
end;

function TCustomDatabaseGrid.CanEdit: Boolean;
begin
  Result := (dgoEditing in FOptions) and not FReadOnly and FDataLink.Active and FDataLink.DataSet.CanModify;
end;

function TCustomDatabaseGrid.CanEditColumn(const AColumn: TDatabaseGridColumn): Boolean;
var
  LField: TField;
begin
  Result := CanEdit and Assigned(AColumn) and AColumn.Visible and not (coReadOnly in AColumn.Options) and Assigned(AColumn.Field) and
    not AColumn.Field.ReadOnly;

  if not Result then
    Exit;

  LField := AColumn.Field;

  case AColumn.GetEditorKind of
    ekEllipsis:
      Result := True;
    ekLookup:
      Result := (LField.FieldKind = fkLookup) and not LField.KeyFields.IsEmpty and Assigned(LField.LookupDataSet) and
        LField.LookupDataSet.Active;
    ekMemo:
      Result := LField.FieldKind = fkData;
  else
    Result := (LField.FieldKind = fkData) and not LField.IsBlob;
  end;
end;

function TCustomDatabaseGrid.CanEditCurrentCell: Boolean;
begin
  Result := CanEditColumn(GetCurrentColumn) and IsRecordRow and
    (not FDataLink.DataSet.IsEmpty or (FDataLink.DataSet.State = dsInsert));
end;

function TCustomDatabaseGrid.CanMoveRecords: Boolean;
begin
  Result := Assigned(FOnMoveRecord) and FDataLink.Active and not FGroups.Active and (FDataLink.DataSet.State = dsBrowse) and
    (FDataLink.DataSet.RecNo > 0);
end;

function TCustomDatabaseGrid.CanRunSelectionCommand(const ACommand: TDatabaseGridTitleMenuCommand): Boolean;
begin
  Result := CanSelectRows and FIndicator.TitleMenu.Commands[ACommand].Visible;
end;

function TCustomDatabaseGrid.CanSelectRows: Boolean;
begin
  Result := (dgoMultiSelect in FOptions) and (ioShowCheckBox in FIndicator.Options) and FDataLink.Active;
end;

function TCustomDatabaseGrid.CreateMeasureBitmap: TBitmap;
begin
  Result := TBitmap.Create;
  Result.Canvas.Font.Assign(Font);
  Result.Canvas.Font.Height := FLayout.FontHeight;
end;

procedure TCustomDatabaseGrid.AddFieldColumns;
begin
  if Assigned(FDataLink.DataSet) then
    FColumns.AddFields(FDataLink.DataSet, FLayout.CharWidth, ScaleMetric(TDatabaseGridSize.MaxAutoColumnWidth));
end;

function TCustomDatabaseGrid.ApplyFilters: Boolean;
begin
  Result := FDataLink.Active;

  if Result then
  begin
    FFilterController.Apply(FDataLink.DataSet, Trim(FSearchPanel.Text));
    FSearchPanelControls.AppliedText := FFilterController.Text;
  end;
end;

procedure TCustomDatabaseGrid.ApplySearchFilter;
begin
  if ApplyFilters and Assigned(FOnSearchFilter) then
    FOnSearchFilter(Self);
end;

procedure TCustomDatabaseGrid.AutoSizeColumns(const AMaxRowCount: Integer);
var
  LBitmap: TBitmap;
  LBookmark: TBookmark;
  LCanvas: TCanvas;
  LColumn: TDatabaseGridColumn;
  LColumns: TArray<TDatabaseGridColumn>;
  LDataSet: TDataSet;
  LMaxWidth, LPadding, LRowCount: Integer;
  LWidths: TArray<Integer>;

  function GetCellWidth(const AColumn: TDatabaseGridColumn): Integer;
  var
    LField: TField;
    LGlyph: TDatabaseGridGlyph;
    LLineBreak: Integer;
    LParams: TDatabaseGridDrawCellParams;
  begin
    LField := AColumn.Field;

    if (AColumn.GetEditorKind = ekCheckBox) and (LField is TBooleanField) then
      Exit(FLayout.ScaleMetric(TDatabaseGridSize.CheckBox) + LPadding);

    LParams.Alignment := AColumn.Alignment;
    LParams.Background := FStyledColors.DataBackground;
    LParams.DefaultDrawing := True;
    LParams.FontColor := FStyledColors.DataForeground;
    LParams.FontStyle := Font.Style;
    LParams.ImageIndex := AColumn.GetImageIndex;

    if (LField.DataType in [ftMemo, ftWideMemo, ftFmtMemo]) and ((dgoShowMemoText in FOptions) or
      (AColumn.GetEditorKind = ekMemo)) then
    begin
      LParams.Text := LField.AsString;
      LLineBreak := LParams.Text.IndexOfAny([TControlCharacters.CarriageReturn, TControlCharacters.LineFeed]);

      if LLineBreak >= 0 then
        LParams.Text := LParams.Text.Substring(0, LLineBreak);
    end
    else
      LParams.Text := LField.DisplayText;

    DrawColumnCell(AColumn, LCanvas, Rect(0, 0, FLayout.ScaleMetric(TDatabaseGridSize.MaxAutoColumnWidth), FLayout.RowHeight), [],
      LParams);

    Result := LPadding;

    if IsCellMode and CanEditColumn(AColumn) and HasEditButton(AColumn, LGlyph) then
      Inc(Result, FLayout.GetEditButtonWidth);

    if Assigned(AColumn.Images) and (LParams.ImageIndex >= 0) then
    begin
      Inc(Result, AColumn.Images.Width);

      if not (coShowImageAndText in AColumn.Options) then
        Exit;

      Inc(Result, FLayout.ScaleMetric(TDatabaseGridSize.ImageTextSpacing));
    end;

    LCanvas.Font.Style := LParams.FontStyle;
    Inc(Result, LCanvas.TextWidth(LParams.Text));
    LCanvas.Font.Style := Font.Style;
  end;

begin
  LColumns := nil;

  for var LIndex := 0 to FColumns.Count - 1 do
  if FColumns[LIndex].Visible then
    LColumns := LColumns + [FColumns[LIndex]];

  SetLength(LWidths, Length(LColumns));
  LPadding := 2 * FLayout.ScaleMetric(TDatabaseGridSize.CellPadding) + 1;

  LBitmap := CreateMeasureBitmap;
  try
    LCanvas := LBitmap.Canvas;

    for var LIndex := 0 to High(LColumns) do
      LWidths[LIndex] := MeasureTitleWidth(LCanvas, LColumns[LIndex]);

    LDataSet := FDataLink.DataSet;

    if FDataLink.Active and (LDataSet.State = dsBrowse) and not LDataSet.IsUniDirectional then
    begin
      LDataSet.DisableControls;
      try
        LBookmark := LDataSet.Bookmark;
        try
          LDataSet.First;
          LRowCount := 0;

          while not LDataSet.Eof and (LRowCount < AMaxRowCount) do
          begin
            for var LIndex := 0 to High(LColumns) do
            begin
              LColumn := LColumns[LIndex];

              if Assigned(LColumn.Field) then
                LWidths[LIndex] := Max(LWidths[LIndex], GetCellWidth(LColumn));
            end;

            Inc(LRowCount);
            LDataSet.Next;
          end;
        finally
          if LDataSet.BookmarkValid(LBookmark) then
            LDataSet.Bookmark := LBookmark;
        end;
      finally
        LDataSet.EnableControls;
      end;
    end;
  finally
    LBitmap.Free;
  end;

  LMaxWidth := Max(FLayout.DataRect.Width div 2, FLayout.ScaleMetric(TDatabaseGridDefault.ColumnWidth));

  FColumns.BeginUpdate;
  try
    for var LIndex := 0 to High(LColumns) do
      LColumns[LIndex].Width := FLayout.UnzoomWidth(Max(Min(LWidths[LIndex], LMaxWidth),
        FLayout.ScaleMetric(TDatabaseGridSize.MinColumnWidth)));
  finally
    FColumns.EndUpdate;
  end;
end;

function TCustomDatabaseGrid.ApplyDataSetSorting(const ACanReopen: Boolean): Boolean;
var
  LColumn: TDatabaseGridColumn;
  LCursor: TCursor;
  LFeatures: TDatabaseGridDataSetFeatures;
  LSortField: TDatabaseGridSortField;
  LSortFields: TArray<TDatabaseGridSortField>;
begin
  FSortingApplied := True;

  if not FDataLink.Active then
    Exit(True);

  LFeatures := FindDatabaseGridDataSetFeatures(FDataLink.DataSet);

  if not Assigned(LFeatures) then
    Exit(True);

  LSortFields := nil;

  for var LIndex := 0 to FSortMarkedColumns.Count - 1 do
  begin
    LColumn := FSortMarkedColumns[LIndex];

    if LColumn.FieldName.IsEmpty then
      Continue;

    LSortField.Descending := LColumn.Title.SortMarker = smDescending;
    LSortField.FieldName := LColumn.FieldName;

    LSortFields := LSortFields + [LSortField];
  end;

  LCursor := Screen.Cursor;
  Screen.Cursor := crHourGlass;
  try
    Result := LFeatures.ApplySorting(FDataLink.DataSet, LSortFields, ACanReopen);
  finally
    Screen.Cursor := LCursor;
  end;

  if Result and LFeatures.SortingChangesBookmarks then
    FSelectedRows.Refresh;
end;

procedure TCustomDatabaseGrid.ApplySorting;
begin
  ApplyDataSetSorting(True);
end;

procedure TCustomDatabaseGrid.BeginUpdate;
begin
  Inc(FPaintLock);
end;

procedure TCustomDatabaseGrid.ClearColumnFilters;
begin
  FColumns.OnFilterChange := nil;
  try
    for var LIndex := 0 to FColumns.Count - 1 do
      FColumns[LIndex].Filter.Clear;
  finally
    FColumns.OnFilterChange := ColumnsFilterChanged;
  end;

  ColumnsFilterChanged(FColumns);
end;

procedure TCustomDatabaseGrid.CopyToClipboard(const ACopyTitles: Boolean = True);
var
  LBookmarks: TArray<TBookmark>;
  LClipboard: TDatabaseGridClipboard;
  LColumns: TArray<TDatabaseGridColumn>;
  LCopyTitles: Boolean;
  LDataSet: TDataSet;
begin
  LDataSet := FDataLink.DataSet;

  if not FDataLink.Active or LDataSet.IsEmpty and (LDataSet.State <> dsInsert) then
    Exit;

  LCopyTitles := ACopyTitles;
  LBookmarks := nil;

  if IsCellMode and (FSelectedRows.Count = 0) then
  begin
    LCopyTitles := False;

    if not GetSelectedCells(LBookmarks, LColumns) then
      Exit;
  end
  else
  begin
    SetLength(LColumns, FLayout.VisibleColumnCount);

    for var LIndex := 0 to High(LColumns) do
      LColumns[LIndex] := FLayout.VisibleColumns[LIndex];

    if LDataSet.State = dsBrowse then
    begin
      for var LIndex := 0 to FSelectedRows.Count - 1 do
        LBookmarks := LBookmarks + [FSelectedRows[LIndex]];

      if Length(LBookmarks) = 0 then
        LBookmarks := [LDataSet.Bookmark];
    end;
  end;

  LClipboard := TDatabaseGridClipboard.Create(LColumns);
  try
    LClipboard.Copy(LDataSet, LBookmarks, LCopyTitles);
  finally
    LClipboard.Free;
  end;
end;

procedure TCustomDatabaseGrid.CutToClipboard;
begin
  if not CanEdit then
    Exit;

  CopyToClipboard(False);
  ClearSelectedCells;
end;

procedure TCustomDatabaseGrid.EndUpdate;
begin
  Assert(FPaintLock > 0);
  Dec(FPaintLock);

  if FPaintLock = 0 then
    UpdateLayout;
end;

procedure TCustomDatabaseGrid.GetTabOrderList(AList: TList);
var
  LForm: TCustomForm;
begin
  LForm := GetParentForm(Self);

  if (AList.Count = 0) or (AList.Last <> Self) or Assigned(LForm) and not Assigned(LForm.ActiveControl) then
  begin
    inherited GetTabOrderList(AList);

    Exit;
  end;

  AList.Delete(AList.Count - 1);

  inherited GetTabOrderList(AList);

  AList.Add(Self);
end;

function TCustomDatabaseGrid.DoMouseWheel(AShift: TShiftState; AWheelDelta: Integer; AMousePos: TPoint): Boolean;
var
  LRowCount: Integer;
begin
  Result := inherited DoMouseWheel(AShift, AWheelDelta, AMousePos);

  if Result then
    Exit;

  if IsDropDownVisible then
  begin
    FDropDownList.ScrollBy(if AWheelDelta > 0 then -3 else 3);

    Exit(True);
  end;

  if Assigned(FEditColumn) then
    EndEdit;

  if ssCtrl in AShift then
  begin
    Inc(FMouse.ZoomWheelDelta, AWheelDelta);

    while FMouse.ZoomWheelDelta >= WHEEL_DELTA do
    begin
      Dec(FMouse.ZoomWheelDelta, WHEEL_DELTA);

      ZoomIn;
    end;

    while FMouse.ZoomWheelDelta <= -WHEEL_DELTA do
    begin
      Inc(FMouse.ZoomWheelDelta, WHEEL_DELTA);

      ZoomOut;
    end;

    Exit(True);
  end;

  LRowCount := Mouse.WheelScrollLines;

  if (LRowCount <= 0) or (LRowCount > FLayout.VisibleRowCount) then
    LRowCount := FLayout.VisibleRowCount;

  if AWheelDelta > 0 then
    LRowCount := -LRowCount;

  if ssShift in AShift then
    SetHorizontalPosition(FLayout.HorizontalPosition + LRowCount * FLayout.ScaleMetric(TDatabaseGridSize.HorizontalScrollStep))
  else
    ScrollToRow(FScrollHelper.TopRow + LRowCount);

  Result := True;
end;

function TCustomDatabaseGrid.EditorBeginModify: Boolean;
begin
  if not Assigned(FEditColumn) then
    Exit(False);

  FEditorModifying := True;
  try
    Result := FDataLink.Edit;
  finally
    FEditorModifying := False;
  end;
end;

function TCustomDatabaseGrid.GetAreaAt(const AX, AY: Integer): TDatabaseGridArea;
begin
  if (AX < 0) or (AY < 0) or (AX >= ClientWidth) or (AY >= ClientHeight) then
    Exit(gaNone);

  Result := FLayout.GetAreaAt(AX, AY);
end;

function TCustomDatabaseGrid.GetCurrentCellScreenRect: TRect;
var
  LLeft, LTop: Integer;
begin
  FLayout.TryGetColumnLeft(GetCurrentColumn, LLeft);

  LTop := GetRowTop(GetCurrentRow);

  Result.TopLeft := ClientToScreen(Point(Max(LLeft, FLayout.DataLeft), LTop));
  Result.BottomRight := ClientToScreen(Point(LLeft + FLayout.GetColumnWidth(GetCurrentColumn), LTop + GetRowHeight(GetCurrentRow)));
end;

function TCustomDatabaseGrid.GetCurrentColumn: TDatabaseGridColumn;
begin
  if (FCurrentColumnIndex >= 0) and (FCurrentColumnIndex < FColumns.Count) then
    Result := FColumns[FCurrentColumnIndex]
  else
    Result := nil;
end;

function TCustomDatabaseGrid.GetCurrentRow: Integer;
begin
  if FGroups.Active then
    Result := FGroups.FocusedRow
  else
    Result := FDataLink.ActiveRecord;
end;

function TCustomDatabaseGrid.GetDataSource: TDataSource;
begin
  Result := FDataLink.DataSource;
end;

function TCustomDatabaseGrid.GetDesignColumnAt(const AX, AY: Integer): TDatabaseGridColumn;
var
  LLeft: Integer;
begin
  if not (csDesigning in ComponentState) or FColumns.AutoCreated then
    Exit(nil);

  Result := FLayout.GetTitleColumnAt(AX, AY, LLeft);
end;

function TCustomDatabaseGrid.GetDesignLinkAt(const AX, AY: Integer): TComponent;
var
  LComponents: TArray<TComponent>;
begin
  LComponents := GetDesignLinks;

  for var LIndex := 0 to High(LComponents) do
  if GetDesignLinkRect(LIndex, Length(LComponents)).Contains(Point(AX, AY)) then
    Exit(LComponents[LIndex]);

  Result := nil;
end;

function TCustomDatabaseGrid.GetDesignLinkRect(const AIndex, ACount: Integer): TRect;
var
  LMargin, LSize: Integer;
begin
  LMargin := ScaleMetric(TDatabaseGridSize.DesignLinkMargin);
  LSize := ScaleMetric(TDatabaseGridSize.DesignLink);

  Result.Right := ClientWidth - LMargin - (ACount - 1 - AIndex) * (LSize + LMargin);
  Result.Left := Result.Right - LSize;
  Result.Bottom := ClientHeight - LMargin;
  Result.Top := Result.Bottom - LSize;
end;

function TCustomDatabaseGrid.GetDesignLinks: TArray<TComponent>;
begin
  Result := nil;

  if not (csDesigning in ComponentState) or not Assigned(FDataLink.DataSource) then
    Exit;

  Result := [FDataLink.DataSource];

  if Assigned(FDataLink.DataSource.DataSet) then
    Result := Result + [FDataLink.DataSource.DataSet];
end;

function TCustomDatabaseGrid.GetDropDownList: TDatabaseGridDropDownList;
begin
  if not Assigned(FDropDownList) then
  begin
    FDropDownList := TDatabaseGridDropDownList.Create(Self);
    FDropDownList.Parent := Self;
    FDropDownList.OnAccept := DropDownListAccept;
  end;

  Result := FDropDownList;
end;

function TCustomDatabaseGrid.GetEditorMode: Boolean;
begin
  Result := Assigned(FEditColumn);
end;

function TCustomDatabaseGrid.GetHorizontalPosition: Integer;
begin
  Result := FLayout.HorizontalPosition;
end;

function TCustomDatabaseGrid.GetMouseScrollCursor: HCURSOR;
var
  LCursor: PChar;
begin
  case Sign(FMouse.ScrollDelta.X) * 3 + Sign(FMouse.ScrollDelta.Y) of
    -4, 4:
      LCursor := IDC_SIZENWSE;
    -2, 2:
      LCursor := IDC_SIZENESW;
    -3, 3:
      LCursor := IDC_SIZEWE;
    -1, 1:
      LCursor := IDC_SIZENS;
  else
    LCursor := IDC_SIZEALL;
  end;

  Result := LoadCursor(0, LCursor);
end;

function TCustomDatabaseGrid.GetMaxTopRow: Integer;
begin
  if not FGroups.Active then
    Exit(Max(GetRowCount - FLayout.VisibleRowCount, 0));

  Result := if GetRowCount = 0 then 0 else Max(GetTopRowShowing(GetRowCount - 1), 0);
end;

function TCustomDatabaseGrid.GetMouseScrollIndicatorRect: TRect;
var
  LSize: Integer;
begin
  LSize := FLayout.ScaleMetric(TDatabaseGridSize.MouseScrollIndicator);
  Result := Bounds(FMouse.ScrollingPoint.X - LSize div 2, FMouse.ScrollingPoint.Y - LSize div 2, LSize, LSize);
end;

function TCustomDatabaseGrid.GetNextAutoFitColumn(const AColumn: TDatabaseGridColumn): TDatabaseGridColumn;
begin
  for var LIndex := AColumn.Index + 1 to FColumns.Count - 1 do
  if FColumns[LIndex].Visible and (coAutoFit in FColumns[LIndex].Options) then
    Exit(FColumns[LIndex]);

  Result := nil;
end;

function TCustomDatabaseGrid.GetRangeBookmarks(out AStart, AEnd: TBookmark): Boolean;
var
  LCurrent: TBookmark;
  LDataSet: TDataSet;
begin
  AStart := nil;
  AEnd := nil;

  if not IsCellMode or not Assigned(FRangeAnchor) or not FDataLink.Active or FGroups.Active or
    not FColumns.Contains(FRangeAnchorColumn) or not FRangeAnchorColumn.Visible then
    Exit(False);

  LDataSet := FDataLink.DataSet;

  if (LDataSet.State = dsInsert) or not LDataSet.BookmarkValid(FRangeAnchor) then
    Exit(False);

  LCurrent := LDataSet.Bookmark;

  if LDataSet.CompareBookmarks(FRangeAnchor, LCurrent) <= 0 then
  begin
    AStart := FRangeAnchor;
    AEnd := LCurrent;
  end
  else
  begin
    AStart := LCurrent;
    AEnd := FRangeAnchor;
  end;

  Result := True;
end;

function TCustomDatabaseGrid.GetResizeColumnAt(const AX, AY: Integer): TDatabaseGridColumn;
begin
  if GetAreaAt(AX, AY) <> gaTitle then
    Exit(nil);

  Result := FLayout.GetResizeColumnAt(AX);

  if Assigned(Result) and (AY < FLayout.GetTitleTop(FLayout.IndexOfVisibleColumn(Result))) then
    Exit(nil);

  if Assigned(Result) and IsAutoFitColumn(Result) and not Assigned(GetNextAutoFitColumn(Result)) then
    Result := nil;
end;

function TCustomDatabaseGrid.GetSelectedCells(out ABookmarks: TArray<TBookmark>; out AColumns: TArray<TDatabaseGridColumn>): Boolean;
var
  LBookmark, LRangeEnd, LRangeStart: TBookmark;
  LBookmarks: TList<TBookmark>;
  LDataSet: TDataSet;
  LFirstColumn, LLastColumn: Integer;
begin
  ABookmarks := nil;
  AColumns := nil;
  LDataSet := FDataLink.DataSet;
  LFirstColumn := FLayout.IndexOfVisibleColumn(GetCurrentColumn);
  LLastColumn := LFirstColumn;

  if not FDataLink.Active or (LFirstColumn < 0) then
    Exit(False);

  if LDataSet.State = dsBrowse then
  begin
    if GetRangeBookmarks(LRangeStart, LRangeEnd) then
    begin
      LFirstColumn := Min(FLayout.IndexOfVisibleColumn(FRangeAnchorColumn), LFirstColumn);
      LLastColumn := Max(FLayout.IndexOfVisibleColumn(FRangeAnchorColumn), LLastColumn);

      LBookmarks := TList<TBookmark>.Create;
      try
        LDataSet.DisableControls;
        try
          LBookmark := LDataSet.Bookmark;
          try
            LDataSet.Bookmark := LRangeStart;

            while not LDataSet.Eof do
            begin
              LBookmarks.Add(LDataSet.Bookmark);

              if LDataSet.CompareBookmarks(LDataSet.Bookmark, LRangeEnd) >= 0 then
                Break;

              LDataSet.Next;
            end;
          finally
            LDataSet.Bookmark := LBookmark;
          end;
        finally
          LDataSet.EnableControls;
        end;

        ABookmarks := LBookmarks.ToArray;
      finally
        LBookmarks.Free;
      end;
    end
    else
      ABookmarks := [LDataSet.Bookmark];
  end;

  SetLength(AColumns, LLastColumn - LFirstColumn + 1);

  for var LIndex := 0 to High(AColumns) do
    AColumns[LIndex] := FLayout.VisibleColumns[LFirstColumn + LIndex];

  Result := True;
end;

function TCustomDatabaseGrid.GetRowAt(const AY: Integer): Integer;
var
  LTop: Integer;
begin
  if AY < FLayout.DataTop then
    Exit(-1);

  if not FGroups.Active then
  begin
    Result := FScrollHelper.TopRow + (AY - FLayout.DataTop) div FLayout.RowHeight;

    Exit(if Result >= GetRowCount then -1 else Result);
  end;

  LTop := FLayout.DataTop;
  Result := FScrollHelper.TopRow;

  while Result < GetRowCount do
  begin
    Inc(LTop, GetRowHeight(Result));

    if AY < LTop then
      Exit;

    Inc(Result);
  end;

  Result := -1;
end;


function TCustomDatabaseGrid.GetRowCount: Integer;
begin
  if FGroups.Active then
    Result := FGroups.RowCount
  else
    Result := FDataLink.BufferedRowCount;
end;

function TCustomDatabaseGrid.GetRowHeight(const ARow: Integer): Integer;
begin
  Result := if FGroups.Active and Assigned(FGroups.GetRowNode(ARow)) then FLayout.GroupRowHeight else FLayout.RowHeight;
end;

function TCustomDatabaseGrid.GetRowOffset: Integer;
begin
  if FGroups.Active then
    Result := 0
  else
    Result := FDataLink.FirstBufferedRow;
end;

function TCustomDatabaseGrid.GetRowRecord(const ARow: Integer): Integer;
begin
  if (ARow < 0) or (ARow >= GetRowCount) then
    Exit(-1);

  if not FGroups.Active then
    Exit(ARow);

  if Assigned(FGroups.Rows[ARow].Node) then
    Result := -1
  else
    Result := FGroups.Rows[ARow].RecordIndex;
end;

function TCustomDatabaseGrid.GetRowTop(const ARow: Integer): Integer;
begin
  if not FGroups.Active then
    Exit(FLayout.DataTop + (ARow - FScrollHelper.TopRow) * FLayout.RowHeight);

  Result := FLayout.DataTop;

  for var LRow := FScrollHelper.TopRow to ARow - 1 do
    Inc(Result, GetRowHeight(LRow));

  for var LRow := ARow to FScrollHelper.TopRow - 1 do
    Dec(Result, GetRowHeight(LRow));
end;

function TCustomDatabaseGrid.GetThumbPosition(const ARange, APosition: Integer): Integer;
begin
  if ARange <= DATABASE_GRID_MAX_SCROLL_RANGE then
    Result := APosition
  else
    Result := MulDiv(ARange, Min(Abs(APosition), DATABASE_GRID_MAX_SCROLL_RANGE), DATABASE_GRID_MAX_SCROLL_RANGE);
end;

function TCustomDatabaseGrid.GetTitleButtonColumnAt(const AX, AY: Integer): TDatabaseGridColumn;
var
  LLeft: Integer;
begin
  if GetAreaAt(AX, AY) <> gaTitle then
    Exit(nil);

  Result := FLayout.GetTitleColumnAt(AX, AY, LLeft);

  if Assigned(Result) and ((FLayout.GetTitleButtonsWidth(Result) = 0) or not FLayout.GetTitleButtonsRect(Result,
    Rect(LLeft, FLayout.GetTitleTop(FLayout.IndexOfVisibleColumn(Result)), LLeft + FLayout.GetColumnWidth(Result),
    FLayout.DataTop)).Contains(Point(AX, AY))) then
    Result := nil;
end;

function TCustomDatabaseGrid.GetTopRowShowing(const ARow: Integer): Integer;
var
  LHeight: Integer;
begin
  if not FGroups.Active then
    Exit(ARow - FLayout.VisibleRowCount + 1);

  Result := ARow;
  LHeight := GetRowHeight(ARow);

  while (Result > 0) and (LHeight + GetRowHeight(Result - 1) <= FLayout.DataRect.Height) do
  begin
    Dec(Result);
    Inc(LHeight, GetRowHeight(Result));
  end;
end;

function TCustomDatabaseGrid.GetTopRow: Integer;
begin
  Result := GetRowOffset + FScrollHelper.TopRow;
end;

function TCustomDatabaseGrid.GetVisibleRowCount: Integer;
begin
  Result := FLayout.VisibleRowCount;
end;

function TCustomDatabaseGrid.GetTotalRowCount: Integer;
begin
  if FGroups.Active then
    Result := FGroups.RowCount
  else
    Result := FDataLink.TotalRowCount;
end;

function TCustomDatabaseGrid.HandleDesignMouseMessage(var AMessage: TMessage): Boolean;
var
  LInstance: TPersistent;
  LLeftButton: Boolean;
  LPoint: TPoint;
begin
  LLeftButton := False;

  case AMessage.Msg of
    WM_LBUTTONDOWN, WM_LBUTTONDBLCLK, WM_LBUTTONUP:
      begin
        LPoint := Point(TWMMouse(AMessage).XPos, TWMMouse(AMessage).YPos);
        LLeftButton := True;
      end;
    WM_RBUTTONDOWN, WM_RBUTTONUP:
      LPoint := Point(TWMMouse(AMessage).XPos, TWMMouse(AMessage).YPos);
    WM_CONTEXTMENU:
      LPoint := ScreenToClient(Point(TWMContextMenu(AMessage).XPos, TWMContextMenu(AMessage).YPos));
  else
    Exit(False);
  end;

  LInstance := GetDesignLinkAt(LPoint.X, LPoint.Y);

  if not Assigned(LInstance) and LLeftButton then
    LInstance := GetDesignColumnAt(LPoint.X, LPoint.Y);

  if not Assigned(LInstance) then
    Exit(False);

  if Assigned(GDatabaseGridDesignHook) then
  case AMessage.Msg of
    WM_LBUTTONDOWN:
      GDatabaseGridDesignHook.SelectComponent(LInstance);
    WM_RBUTTONDOWN:
      GDatabaseGridDesignHook.ShowComponentMenu(TComponent(LInstance), ClientToScreen(LPoint));
  end;

  AMessage.Result := 0;

  Result := True;
end;

function TCustomDatabaseGrid.HandleEditingKey(const AKey: Word; const AShift: TShiftState): Boolean;
var
  LColumn: TDatabaseGridColumn;
  LGlyph: TDatabaseGridGlyph;
  LKind: TDatabaseGridEditorKind;
begin
  Result := True;
  LColumn := GetCurrentColumn;
  LKind := if Assigned(LColumn) then LColumn.GetEditorKind else ekText;

  if (AKey = vkF2) and (AShift = []) then
    EditCurrentCell(False)
  else
  if (AKey = vkReturn) and (AShift = []) then
  begin
    if dgoEnterAsTab in FOptions then
      MoveToNextCell(True)
    else
      EditCurrentCell(False);
  end
  else
  if (AKey = vkReturn) and (AShift = [ssCtrl]) and (LKind = ekEllipsis) and CanEditCurrentCell then
    DoEditButtonClick
  else
  if ((AKey = vkDown) and (AShift = [ssAlt]) or (AKey = vkF4) and (AShift = [])) and CanEditCurrentCell and
    HasEditButton(LColumn, LGlyph) then
    PressEditButton
  else
  if (AKey = vkSpace) and (AShift = []) and (LKind = ekCheckBox) and CanEditCurrentCell then
    ToggleCheckBox
  else
  if (AKey = vkBack) and (AShift = [ssCtrl]) then
    ClearCurrentCell
  else
  if (AKey = vkTab) and (AShift - [ssShift] = []) then
    MoveToNextCell(not (ssShift in AShift))
  else
  if (AKey = vkEscape) and FDataLink.Editing then
    FDataLink.DataSet.Cancel
  else
  if (AKey = vkInsert) and (AShift = []) then
    InsertRecord
  else
  if (AKey = vkDelete) and (AShift = [ssCtrl]) then
    DeleteRecord
  else
  if (AKey = Ord('V')) and (AShift = [ssCtrl]) or (AKey = vkInsert) and (AShift = [ssShift]) then
    PasteFromClipboard
  else
  if (AKey = Ord('X')) and (AShift = [ssCtrl]) or (AKey = vkDelete) and (AShift = [ssShift]) then
    CutToClipboard
  else
  if (AKey = vkDelete) and (AShift = []) then
    ClearSelectedCells
  else
    Result := False;
end;

function TCustomDatabaseGrid.HasEditButton(const AColumn: TDatabaseGridColumn; out AGlyph: TDatabaseGridGlyph): Boolean;
begin
  Result := Assigned(AColumn);
  AGlyph := glDropDown;

  if not Result then
    Exit;

  case AColumn.GetEditorKind of
    ekDate, ekDateTime, ekLookup, ekPickList, ekTime:
      AGlyph := glDropDown;
    ekEllipsis, ekMemo:
      AGlyph := glEllipsis;
  else
    Result := False;
  end;
end;

function TCustomDatabaseGrid.IsAutoFitColumn(const AColumn: TDatabaseGridColumn): Boolean;
begin
  Result := (dgoAutoFitColumns in FOptions) and (coAutoFit in AColumn.Options);
end;

function TCustomDatabaseGrid.IsCellMode: Boolean;
begin
  Result := dgoEditing in FOptions;
end;

function TCustomDatabaseGrid.IsCheckBoxAt(const AColumn: TDatabaseGridColumn; const ALeft, AX, AY: Integer): Boolean;
var
  LRow, LRowTop, LSize: Integer;
begin
  if (AColumn.GetEditorKind <> ekCheckBox) or not (AColumn.Field is TBooleanField) then
    Exit(False);

  LRow := GetRowAt(AY);

  if LRow < 0 then
    Exit(False);

  LSize := Min(FLayout.ScaleMetric(TDatabaseGridSize.CheckBox), FLayout.RowHeight - 5);
  LRowTop := GetRowTop(LRow);

  Result := Bounds(ALeft + (FLayout.GetColumnWidth(AColumn) - 1 - LSize) div 2, LRowTop + (FLayout.RowHeight - 1 - LSize) div 2,
    LSize, LSize).Contains(Point(AX, AY));
end;

function TCustomDatabaseGrid.IsDropDownVisible: Boolean;
begin
  Result := Assigned(FDropDownList) and FDropDownList.Dropped;
end;

function TCustomDatabaseGrid.IsEditButtonAt(const AX, AY: Integer): Boolean;
var
  LColumn: TDatabaseGridColumn;
  LGlyph: TDatabaseGridGlyph;
  LLeft, LRight: Integer;
begin
  LColumn := GetCurrentColumn;

  if not IsCellMode or not FDataLink.Active or (GetAreaAt(AX, AY) <> gaData) or (GetRowAt(AY) <> GetCurrentRow) or
    not HasEditButton(LColumn, LGlyph) or not CanEditCurrentCell or not FLayout.TryGetColumnLeft(LColumn, LLeft) then
    Exit(False);

  LRight := LLeft + FLayout.GetColumnWidth(LColumn) - 1;

  Result := (AX >= LRight - FLayout.GetEditButtonWidth) and (AX < LRight);
end;

function TCustomDatabaseGrid.IsColumnsStored: Boolean;
begin
  Result := not FColumns.AutoCreated and (FColumns.Count > 0);
end;

function TCustomDatabaseGrid.IsInlineEditor(const AColumn: TDatabaseGridColumn): Boolean;
begin
  if not Assigned(AColumn) or not Assigned(AColumn.Field) then
    Exit(False);

  case AColumn.GetEditorKind of
    ekCheckBox, ekMemo:
      Result := False;
    ekEllipsis:
      Result := (AColumn.Field.FieldKind = fkData) and not AColumn.Field.IsBlob;
  else
    Result := True;
  end;
end;

function TCustomDatabaseGrid.IsReadOnlyColumn(const AColumn: TDatabaseGridColumn): Boolean;
begin
  Result := not CanEditColumn(AColumn);
end;

function TCustomDatabaseGrid.IsRecordRow: Boolean;
begin
  Result := not FGroups.Active or not Assigned(FGroups.GetRowNode(FGroups.FocusedRow));
end;

function TCustomDatabaseGrid.IsRowSelected(const ARow: Integer): Boolean;
var
  LActiveRecord, LRecordIndex: Integer;
begin
  LRecordIndex := GetRowRecord(ARow);

  if (FSelectedRows.Count = 0) or (LRecordIndex < 0) then
    Exit(False);

  LActiveRecord := FDataLink.ActiveRecord;
  try
    FDataLink.ActiveRecord := LRecordIndex;

    Result := FSelectedRows.IsSelected(FDataLink.DataSet.Bookmark);
  finally
    FDataLink.ActiveRecord := LActiveRecord;
  end;
end;

function TCustomDatabaseGrid.MeasureTitleWidth(const ACanvas: TCanvas; const AColumn: TDatabaseGridColumn): Integer;
var
  LParts: TArray<string>;
begin
  LParts := AColumn.Title.GetCaptionParts;
  Result := Max(ACanvas.TextWidth(LParts[High(LParts)]), ACanvas.TextWidth(AColumn.Title.SubCaption)) +
    2 * FLayout.ScaleMetric(TDatabaseGridSize.CellPadding) + 1 + FLayout.GetTitleButtonsWidth(AColumn);

  if (dgoSortMarking in FOptions) and (toButton in AColumn.Title.Options) then
    Inc(Result, FLayout.ScaleMetric(TDatabaseGridSize.SortMarkerWidth));

  if Assigned(FTitle.Images) and (AColumn.Title.ImageIndex >= 0) then
    Inc(Result, FTitle.Images.Width + FLayout.ScaleMetric(TDatabaseGridSize.ImageTextSpacing));
end;

function TCustomDatabaseGrid.MoveRowBy(const ADistance: Integer): Boolean;
var
  LRow: Integer;
begin
  if not FGroups.Active then
    Exit(FDataLink.DataSet.MoveBy(ADistance) <> 0);

  LRow := FGroups.FocusedRow;

  MoveToRow(LRow + ADistance);

  Result := FGroups.FocusedRow <> LRow;
end;

function TCustomDatabaseGrid.ScaleMetric(const AValue: Integer): Integer;
begin
  Result := MulDiv(AValue, CurrentPPI, USER_DEFAULT_SCREEN_DPI);
end;

procedure TCustomDatabaseGrid.BindColumns;
begin
  if csLoading in ComponentState then
    Exit;

  if FDataLink.Active then
  begin
    if (FColumns.Count = 0) or FColumns.AutoCreated and not FColumns.MatchesFields(FDataLink.DataSet) then
    begin
      FColumns.CreateFromFields(FDataLink.DataSet, FLayout.CharWidth, ScaleMetric(TDatabaseGridSize.MaxAutoColumnWidth));
      FColumns.BindFields(FDataLink.DataSet);
      FitColumnsToTitles;
    end
    else
      FColumns.BindFields(FDataLink.DataSet);
  end
  else
  begin
    FColumns.ClearAutoCreated;
    FColumns.BindFields(nil);
  end;
end;

procedure TCustomDatabaseGrid.BorderChanged(ASender: TObject);
begin
  BorderWidth := FBorder.Width;

  if HandleAllocated then
    RedrawWindow(Handle, nil, 0, RDW_FRAME or RDW_INVALIDATE);
end;

procedure TCustomDatabaseGrid.BorderStyleChanged(ASender: TObject);
begin
  RecreateWnd;
end;

procedure TCustomDatabaseGrid.AcceptDropDownItem(const AIndex: Integer);
begin
  if (AIndex < 0) or not Assigned(FEditColumn) or not FDataLink.Edit then
    Exit;

  if FEditColumn.GetEditorKind = ekLookup then
  begin
    WriteLookupKey(FLookupKeys[AIndex]);
    SetEditorText(FEditColumn.Field.Text, False);
  end
  else
    SetEditorText(FDropDownList.Items[AIndex], True);

  CloseDropDown;
end;

procedure TCustomDatabaseGrid.BuildTitleMenu;
var
  LGroupStarted: Boolean;

  procedure AddItem(const ACaption: string; const ACommand: TDatabaseGridTitleMenuCommand; const AShortCut: TShortCut;
    const AEnabled: Boolean = True);
  var
    LItem: TMenuItem;
  begin
    if not FIndicator.TitleMenu.Commands[ACommand].Visible then
      Exit;

    if LGroupStarted and (FTitleMenu.Items.Count > 0) then
      FTitleMenu.Items.NewBottomLine;

    LGroupStarted := False;

    LItem := TMenuItem.Create(FTitleMenu);
    LItem.Caption := ACaption;
    LItem.Enabled := AEnabled;
    LItem.ImageIndex := FIndicator.TitleMenu.Commands[ACommand].ImageIndex;
    LItem.ShortCut := AShortCut;
    LItem.Tag := Ord(ACommand);
    LItem.OnClick := TitleMenuItemClick;

    FTitleMenu.Items.Add(LItem);
  end;

  procedure StartGroup;
  begin
    LGroupStarted := True;
  end;

var
  LHasRows: Boolean;
begin
  FTitleMenu.Items.Clear;
  FTitleMenu.Images := FIndicator.TitleMenu.Images;

  LGroupStarted := False;

  if CanSelectRows then
  begin
    LHasRows := not FDataLink.DataSet.IsEmpty;

    AddItem(SDatabaseGridSelectAllRows, tmcSelectAll, Vcl.Menus.ShortCut(Ord('A'), [ssCtrl]), LHasRows);
    AddItem(SDatabaseGridInvertSelection, tmcInvertSelection, Vcl.Menus.ShortCut(Ord('A'), [ssCtrl, ssShift]), LHasRows);
    AddItem(SDatabaseGridUnselectAll, tmcUnselectAll, Vcl.Menus.ShortCut(Ord('D'), [ssCtrl]), FSelectedRows.Count > 0);
  end;

  StartGroup;
  AddItem(SDatabaseGridJumpToColumn, tmcJumpToColumn, Vcl.Menus.ShortCut(Ord('J'), [ssCtrl]));
  AddItem(SDatabaseGridJumpToFirstColumn, tmcJumpToFirstColumn, Vcl.Menus.ShortCut(vkHome, []));
  AddItem(SDatabaseGridJumpToLastColumn, tmcJumpToLastColumn, Vcl.Menus.ShortCut(vkEnd, []));

  StartGroup;
  AddItem(SDatabaseGridExport, tmcExport, 0, FDataLink.Active);

  StartGroup;
  AddItem(SDatabaseGridZoomIn, tmcZoomIn, Vcl.Menus.ShortCut(vkEqual, [ssCtrl]), FZoomPercentage < DATABASE_GRID_ZOOM_PERCENTAGES[High(DATABASE_GRID_ZOOM_PERCENTAGES)]);
  AddItem(SDatabaseGridZoomOut, tmcZoomOut, Vcl.Menus.ShortCut(vkMinus, [ssCtrl]), FZoomPercentage > DATABASE_GRID_ZOOM_PERCENTAGES[0]);
  AddItem(Format(SDatabaseGridResetZoom, [FZoomPercentage]), tmcResetZoom, Vcl.Menus.ShortCut(vk0, [ssCtrl]), FZoomPercentage <> TDatabaseGridDefault.ZoomPercentage);
end;

procedure TCustomDatabaseGrid.BufferVisibleRows;
var
  LRowCount: Integer;
begin
  if FGroups.Active then
    Exit;

  LRowCount := FScrollHelper.TopRow + FLayout.VisibleRowCount + 2;

  if (LRowCount <= FDataLink.BufferedRowCount) or not FDataLink.BufferFull then
    Exit;

  LRowCount := LRowCount - FDataLink.BufferCount;

  if not FDataLink.Sequenced then
    LRowCount := Max(LRowCount, DATABASE_GRID_BUFFER_GROW_ROW_COUNT);

  Inc(FScrollHelper.TopRow, FDataLink.ExtendBuffer(LRowCount));
end;

procedure TCustomDatabaseGrid.CalculateLayout;
begin
  FLayout.Calculate(ClientRect, FSearchPanel.Visible, FFooter.Visible, FGroups.LevelCount,
    FStyledColors.VerticalLine <> TColors.SysNone);

  if dgoAutoFitColumns in FOptions then
    FLayout.FitColumns(FLayout.ScaleMetric(TDatabaseGridSize.MinColumnWidth));

  FSearchPanelControls.Realign(Rect(0, 0, ClientWidth, Max(FLayout.TitleTop - 1, 0)), FLayout.SearchPanelControlHeight, CurrentPPI);
end;

procedure TCustomDatabaseGrid.CalendarPopupAccept(ASender: TObject; const AValue: TDateTime);
var
  LField: TField;
begin
  if not FColumns.Contains(FPopupColumn) or (GetCurrentColumn <> FPopupColumn) or not FDataLink.Edit then
    Exit;

  LField := FPopupColumn.Field;

  case FPopupColumn.GetEditorKind of
    ekDate:
      LField.AsDateTime := Trunc(AValue);
    ekTime:
      LField.AsDateTime := Frac(AValue);
  else
    LField.AsDateTime := AValue;
  end;

  if Assigned(FEditColumn) then
    SetEditorText(LField.Text, False);
end;

procedure TCustomDatabaseGrid.ChangeScale(AMultiplier, ADivider: Integer; AIsDpiChange: Boolean);
begin
  inherited ChangeScale(AMultiplier, ADivider, AIsDpiChange);

  if AMultiplier <> ADivider then
  begin
    FColumns.ChangeScale(AMultiplier, ADivider);

    UpdateMetrics;
    UpdateLayout;
  end;
end;

procedure TCustomDatabaseGrid.ChangeSortMarker(const AColumn: TDatabaseGridColumn; const AAppend: Boolean);
var
  LSortMarker: TDatabaseGridSortMarker;
begin
  case AColumn.Title.SortMarker of
    smNone:
      LSortMarker := smAscending;
    smAscending:
      LSortMarker := smDescending;
  else
    LSortMarker := smNone;
  end;

  SetSortMarker(AColumn, LSortMarker, AAppend);
end;

procedure TCustomDatabaseGrid.CMDesignHitTest(var AMessage: TCMDesignHitTest);
begin
  if Assigned(GetDesignLinkAt(AMessage.XPos, AMessage.YPos)) or Assigned(GetDesignColumnAt(AMessage.XPos, AMessage.YPos)) then
    AMessage.Result := 1
  else
    inherited;
end;

procedure TCustomDatabaseGrid.CMFontChanged(var AMessage: TMessage);
begin
  inherited;

  UpdateMetrics;
  UpdateLayout;
end;

procedure TCustomDatabaseGrid.CMHintShow(var AMessage: TCMHintShow);
var
  LActiveRecord, LLeft, LRecord, LRow, LTop: Integer;
  LColumn: TDatabaseGridColumn;
  LCursorRect, LCutRect: TRect;
  LHint: string;
  LPoint: TPoint;
begin
  inherited;

  LPoint := AMessage.HintInfo.CursorPos;

  if FMouse.Scrolling then
  begin
    AMessage.Result := 1;

    Exit;
  end;

  if not (dgoShowHints in FOptions) then
    Exit;

  case GetAreaAt(LPoint.X, LPoint.Y) of
    gaTitle:
      begin
        LColumn := FLayout.GetTitleColumnAt(LPoint.X, LPoint.Y, LLeft);

        if Assigned(LColumn) and not LColumn.Title.Hint.IsEmpty then
        begin
          AMessage.HintInfo.HintStr := LColumn.Title.Hint;
          AMessage.HintInfo.CursorRect := Rect(Max(LLeft, FLayout.DataLeft), FLayout.GetTitleTop(FLayout.IndexOfVisibleColumn(LColumn)),
            LLeft + FLayout.GetColumnWidth(LColumn), FLayout.DataTop);
          AMessage.Result := 0;
        end;
      end;
    gaData:
      begin
        if not FDataLink.Active then
          Exit;

        LRow := GetRowAt(LPoint.Y);
        LRecord := GetRowRecord(LRow);
        LColumn := FLayout.GetColumnAt(LPoint.X, LLeft);

        if (LRecord < 0) or (LRecord >= FDataLink.RecordCount) or not Assigned(LColumn) then
          Exit;

        LTop := GetRowTop(LRow);
        LCursorRect := Rect(Max(LLeft, FLayout.DataLeft), LTop, LLeft + FLayout.GetColumnWidth(LColumn), LTop + GetRowHeight(LRow));

        if FPainter.TryGetCutCellText(LPoint, LHint, LCutRect) then
          LCursorRect := LCutRect;

        if Assigned(FOnCellHint) then
        begin
          LActiveRecord := FDataLink.ActiveRecord;
          FDataLink.ActiveRecord := LRecord;
          try
            FOnCellHint(Self, LColumn, LHint);
          finally
            FDataLink.ActiveRecord := LActiveRecord;
          end;
        end;

        AMessage.HintInfo.HintStr := LHint;
        AMessage.HintInfo.CursorRect := LCursorRect;
        AMessage.Result := if LHint.IsEmpty then 1 else 0;
      end;
  end;
end;

procedure TCustomDatabaseGrid.CMMouseLeave(var AMessage: TMessage);
begin
  inherited;

  SetHotTitleColumn(nil);
end;

procedure TCustomDatabaseGrid.CMStyleChanged(var AMessage: TMessage);
begin
  inherited;

  UpdateStyledColors;
  UpdateLayout;
  Invalidate;
end;

procedure TCustomDatabaseGrid.CMWantSpecialKey(var AMessage: TCMWantSpecialKey);
begin
  if IsCellMode and ((AMessage.CharCode = VK_RETURN) and CanEdit or (AMessage.CharCode = VK_ESCAPE) and FDataLink.Editing) then
    AMessage.Result := 1
  else
    inherited;
end;

procedure TCustomDatabaseGrid.ClearColumnValue(const AColumn: TDatabaseGridColumn);
begin
  if AColumn.Field.FieldKind = fkLookup then
    FDataLink.DataSet.FieldValues[AColumn.Field.KeyFields] := Null
  else
    AColumn.Field.Clear;
end;

procedure TCustomDatabaseGrid.ClearCurrentCell;
begin
  if not CanEditCurrentCell then
    Exit;

  HideEditor;

  if not FDataLink.Edit then
    Exit;

  ClearColumnValue(GetCurrentColumn);

  Invalidate;
end;

procedure TCustomDatabaseGrid.ClearSelectedCells;
var
  LBookmark: TBookmark;
  LBookmarks: TArray<TBookmark>;
  LColumns: TArray<TDatabaseGridColumn>;
  LDataSet: TDataSet;
begin
  if not CanEdit then
    Exit;

  LDataSet := FDataLink.DataSet;

  HideEditor;

  if not Assigned(FRangeAnchor) then
  begin
    ClearCurrentCell;

    Exit;
  end;

  LDataSet.CheckBrowseMode;

  if not GetSelectedCells(LBookmarks, LColumns) then
    Exit;

  LDataSet.DisableControls;
  try
    LBookmark := LDataSet.Bookmark;
    try
      for var LRowBookmark in LBookmarks do
      begin
        if not LDataSet.BookmarkValid(LRowBookmark) then
          Continue;

        LDataSet.Bookmark := LRowBookmark;
        LDataSet.Edit;
        try
          for var LColumn in LColumns do
          if CanEditColumn(LColumn) then
            ClearColumnValue(LColumn);

          LDataSet.Post;
        except
          LDataSet.Cancel;

          raise;
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

procedure TCustomDatabaseGrid.CloseDropDown;
begin
  if Assigned(FDropDownList) then
    FDropDownList.CloseUp;
end;

procedure TCustomDatabaseGrid.CollapseCellRange;
begin
  if Assigned(FRangeAnchor) then
  begin
    FRangeAnchor := nil;
    FRangeAnchorColumn := nil;

    Invalidate;
  end;
end;

procedure TCustomDatabaseGrid.ColumnFilterPopupClearAllColumnFilters(ASender: TObject);
begin
  ClearColumnFilters;
end;

procedure TCustomDatabaseGrid.ColumnFilterPopupClose(ASender: TObject; var AAction: TCloseAction);
var
  LLeft: Integer;
  LPoint: TPoint;
begin
  AAction := caFree;

  if ASender = FColumnFilterPopup then
  begin
    if FColumnFilterPopup.HasValueList then
      FColumnFilterPopupWidth := FColumnFilterPopup.Width;

    LPoint := ScreenToClient(Mouse.CursorPos);

    if FColumnFilterPopup.ClosedByDeactivation and (GetAreaAt(LPoint.X, LPoint.Y) = gaTitle) and
      (FLayout.GetTitleColumnAt(LPoint.X, LPoint.Y, LLeft) = FColumnFilterPopup.Column) then
    begin
      FColumnFilterClosedByClick := FColumnFilterPopup.Column;
      FColumnFilterClosedTicks := GetTickCount64;
    end;

    FColumnFilterPopup := nil;
  end;
end;

procedure TCustomDatabaseGrid.ColumnFilterPopupSort(ASender: TObject; const AColumn: TDatabaseGridColumn;
  const ASortMarker: TDatabaseGridSortMarker);
begin
  if FColumns.Contains(AColumn) then
    SetSortMarker(AColumn, ASortMarker);
end;

procedure TCustomDatabaseGrid.ColumnsChanged(ASender: TObject);
begin
  for var LIndex := 0 to FColumns.Count - 1 do
  if Assigned(FColumns[LIndex].Images) then
    FColumns[LIndex].Images.FreeNotification(Self);

  if [csDestroying, csLoading] * ComponentState <> [] then
    Exit;

  if not FColumns.Contains(FLayout.HotTitleColumn) then
    FLayout.HotTitleColumn := nil;

  if not FColumns.Contains(FColumnFilterClosedByClick) then
    FColumnFilterClosedByClick := nil;

  if Assigned(FEditColumn) and (not FColumns.Contains(FEditColumn) or not CanEditColumn(FEditColumn)) then
    HideEditor;

  if FDataLink.Active then
  begin
    if (FColumns.Count = 0) and not FColumns.AutoCreating then
      BindColumns
    else
      FColumns.BindFields(FDataLink.DataSet);
  end;

  if FFooterCalculator.ColumnsChanged then
    PostFooterCalculation;

  UpdateSortMarkedColumns;
  UpdateLayout;
end;

procedure TCustomDatabaseGrid.ColumnsFilterChanged(ASender: TObject);
begin
  if [csDestroying, csLoading] * ComponentState <> [] then
    Exit;

  CollapseCellRange;

  if ApplyFilters and Assigned(FOnAfterApplyFilter) then
    FOnAfterApplyFilter(Self);

  Invalidate;
end;

procedure TCustomDatabaseGrid.CreateParams(var AParams: TCreateParams);
const
  BORDER_STYLES: array [TBorderStyle] of DWORD = (0, WS_BORDER);
begin
  inherited CreateParams(AParams);

  AParams.Style := AParams.Style or BORDER_STYLES[FBorder.Style] or WS_CLIPCHILDREN;

  if NewStyleControls and Ctl3D and (FBorder.Style = bsSingle) then
  begin
    AParams.Style := AParams.Style and not WS_BORDER;
    AParams.ExStyle := AParams.ExStyle or WS_EX_CLIENTEDGE;
  end;
end;

procedure TCustomDatabaseGrid.CreateWnd;
begin
  inherited CreateWnd;

  FScrollHelper.TrimPending := False;

  FSearchPanelControls.Synchronize;

  UpdateMetrics;
  UpdateLayout;
  ScrollCurrentRowIntoView;

  if FFooterCalculator.Pending then
    PostFooterCalculation;
end;

procedure TCustomDatabaseGrid.DataGroupingChanged(ASender: TObject);
begin
  if Assigned(FDataGrouping.Images) then
    FDataGrouping.Images.FreeNotification(Self);

  if [csDestroying, csLoading] * ComponentState <> [] then
    Exit;

  UpdateGroups;
  UpdateLayout;
  ScrollCurrentRowIntoView;
end;

procedure TCustomDatabaseGrid.DataLinkActiveChanged(ASender: TObject);
begin
  if csDestroying in ComponentState then
    Exit;

  FScrollHelper.TopRow := 0;
  FLayout.HorizontalPosition := 0;

  HideEditor;
  CollapseCellRange;
  FSelectedRows.Clear;

  if Assigned(FFilterController.DataSet) and (FDataLink.DataSet <> FFilterController.DataSet) then
  begin
    FFilterController.Remove;

    FSearchPanel.Text := '';
  end;

  BindColumns;
  UpdateDataSetFeatures;
  UpdateGroups;
  UpdateLayout;
  InvalidateFooterValues;
end;

procedure TCustomDatabaseGrid.DataLinkDataChanged(const ARowShift: Integer; const ACurrentRowChanged, ADataSetChanged: Boolean);
var
  LCurrentRowChanged: Boolean;
  LFocusedRow: Integer;
begin
  if csDestroying in ComponentState then
    Exit;

  LCurrentRowChanged := ACurrentRowChanged;

  if FGroups.Active then
  begin
    LFocusedRow := FGroups.FocusedRow;

    if ADataSetChanged or (ARowShift <> 0) or (FDataLink.BufferedRowCount <> FGroups.RecordCount) then
      UpdateGroups
    else
      FGroups.SynchronizeFocus;

    LCurrentRowChanged := LCurrentRowChanged or (FGroups.FocusedRow <> LFocusedRow);
  end
  else
    Inc(FScrollHelper.TopRow, ARowShift);

  if ADataSetChanged then
    InvalidateFooterValues;

  if Assigned(FEditColumn) and (LCurrentRowChanged or ADataSetChanged and not FFooterCalculator.Calculating) and
    not FDataLink.Editing then
    HideEditor;

  if LCurrentRowChanged then
    ScrollCurrentRowIntoView
  else
    ScrollToRow(FScrollHelper.TopRow);
end;

procedure TCustomDatabaseGrid.DataLinkDisabledStateChanged(ASender: TObject);
begin
  if csDestroying in ComponentState then
    Exit;

  FColumns.BindFields(if FDataLink.DataSet.Active then FDataLink.DataSet else nil);

  UpdateDataSetFeatures;
  InvalidateFooterValues;
end;

procedure TCustomDatabaseGrid.DataLinkEditingChanged(ASender: TObject);
begin
  if csDestroying in ComponentState then
    Exit;

  if not FDataLink.Editing then
    HideEditor;

  Invalidate;
end;

procedure TCustomDatabaseGrid.DataLinkFocusControl(var AField: TField);
begin
  for var LIndex := 0 to FLayout.VisibleColumnCount - 1 do
  if FLayout.VisibleColumns[LIndex].Field = AField then
  begin
    SetCurrentColumn(FLayout.VisibleColumns[LIndex]);

    if CanFocus then
      SetFocus;

    ShowEditor(False);

    AField := nil;

    Exit;
  end;
end;

procedure TCustomDatabaseGrid.DataLinkLayoutChanged(ASender: TObject);
begin
  if csDestroying in ComponentState then
    Exit;

  BindColumns;
  UpdateGroups;
  UpdateLayout;
  InvalidateFooterValues;
end;

procedure TCustomDatabaseGrid.DataLinkRecordChanged(const AField: TField);
begin
  if csDestroying in ComponentState then
    Exit;

  if Assigned(FEditColumn) and not FEditorModifying and not FEditor.Modified and
    (not Assigned(AField) or (AField = FEditColumn.Field)) then
    SetEditorText(FEditColumn.Field.Text, False);

  Invalidate;
end;

procedure TCustomDatabaseGrid.DataLinkUpdateData(ASender: TObject);
begin
  if Assigned(FEditColumn) and FEditor.Modified then
    WriteEditorText;
end;

procedure TCustomDatabaseGrid.DataMouseDown(const AShift: TShiftState; const AX, AY: Integer; const AWasFocused: Boolean);
var
  LActiveRow, LLeft, LRow: Integer;
  LColumn: TDatabaseGridColumn;
  LCurrentCellClicked: Boolean;
  LNode: TDatabaseGridGroupNode;
  LPoint: TPoint;
  LPreviousBookmark: TBookmark;
begin
  LRow := GetRowAt(AY);

  if LRow < 0 then
    Exit;

  if Assigned(FGroups.GetRowNode(LRow)) then
  begin
    MoveToRow(LRow);

    LNode := FGroups.GetRowNode(LRow);

    if Assigned(LNode) then
      LNode.Expanded := not LNode.Expanded;

    Exit;
  end;

  if (FMouse.DownArea = gaIndicator) and (ioShowCheckBox in FIndicator.Options) and (AX < FLayout.RowHeight) then
  begin
    if dgoMultiSelect in FOptions then
    begin
      FMouse.CheckBoxSelecting := True;
      FMouse.CheckBoxSelected := not IsRowSelected(LRow);
      FMouse.CheckBoxRowOffset := LRow - GetCurrentRow;

      SelectRowRange(LRow, LRow, FMouse.CheckBoxSelected);
    end;

    Exit;
  end;

  LActiveRow := GetCurrentRow;
  LColumn := nil;
  LPreviousBookmark := nil;

  if (dgoMultiSelect in FOptions) and (ssCtrl in AShift) and (LRow <> LActiveRow) and (FSelectedRows.Count = 0) and
    FDataLink.Active and (FDataLink.DataSet.State = dsBrowse) and not FDataLink.DataSet.IsEmpty and
    not Assigned(FGroups.GetRowNode(LActiveRow)) then
    LPreviousBookmark := FDataLink.DataSet.Bookmark;

  if FMouse.DownArea = gaData then
    LColumn := FLayout.GetColumnAt(AX, LLeft);

  LCurrentCellClicked := IsCellMode and AWasFocused and Assigned(LColumn) and (LRow = LActiveRow) and
    (LColumn = GetCurrentColumn) and (AShift * [ssShift, ssCtrl] = []);

  if IsCellMode and (FMouse.DownArea = gaData) then
  begin
    if ssShift in AShift then
      ExtendCellRange
    else
      CollapseCellRange;
  end;

  MoveToRow(LRow);

  if Assigned(LColumn) then
  begin
    SetCurrentColumn(LColumn);

    FMouse.ClickColumn := LColumn;
  end;

  if (FMouse.DownArea = gaIndicator) and (GetCurrentRow = LRow) and CanMoveRecords then
  begin
    FMouse.RecordMoving := True;
    FMouse.MoveFromIndex := FDataLink.DataSet.RecNo - 1;
  end;

  if IsCellMode and Assigned(LColumn) and (GetCurrentRow = LRow) and (GetCurrentColumn = LColumn) and
    (AShift * [ssShift, ssCtrl] = []) and IsCheckBoxAt(LColumn, LLeft, AX, AY) then
  begin
    ToggleCheckBox;

    Exit;
  end;

  if LCurrentCellClicked and CanEditCurrentCell and not IsInlineEditor(LColumn) then
  begin
    EditCurrentCell(False);

    Exit;
  end;

  if LCurrentCellClicked and CanEditCurrentCell then
  begin
    ShowEditor(False);

    if Assigned(FEditColumn) and FEditor.Visible then
    begin
      LPoint := FEditor.ScreenToClient(ClientToScreen(Point(AX, AY)));

      FEditor.Perform(WM_LBUTTONDOWN, MK_LBUTTON, PointToLParam(LPoint));
      FEditor.Perform(WM_LBUTTONUP, 0, PointToLParam(LPoint));
    end;

    Exit;
  end;

  FMouse.CellSelecting := IsCellMode and (FMouse.DownArea = gaData) and not FGroups.Active;

  if not (dgoMultiSelect in FOptions) or (GetCurrentRow <> LRow) then
    Exit;

  if ssCtrl in AShift then
  begin
    FSelectedRows.BeginUpdate;
    try
      if Assigned(LPreviousBookmark) then
        FSelectedRows.Select(LPreviousBookmark, True);

      FSelectedRows.CurrentRowSelected := not FSelectedRows.CurrentRowSelected;
    finally
      FSelectedRows.EndUpdate;
    end;
  end
  else
  if (ssShift in AShift) and not IsCellMode then
    SelectRowRange(LActiveRow, LRow, True);
end;

procedure TCustomDatabaseGrid.DeleteRecord;
begin
  if not CanEdit or FDataLink.DataSet.IsEmpty then
    Exit;

  HideEditor;

  if MessageDlg(SDatabaseGridDeleteRecordQuestion, TMsgDlgType.mtConfirmation, [TMsgDlgBtn.mbYes, TMsgDlgBtn.mbNo], 0) = mrYes then
    FDataLink.DataSet.Delete;
end;

procedure TCustomDatabaseGrid.DoEditButtonClick;
begin
  if Assigned(FOnEditButtonClick) then
    FOnEditButtonClick(Self, GetCurrentColumn);

  Invalidate;
end;

procedure TCustomDatabaseGrid.DragScrollTimerTimer(ASender: TObject);
var
  LDistance: Integer;
begin
  if not MouseCapture then
  begin
    FMouse.CellSelecting := False;
    FMouse.CheckBoxSelecting := False;
  end;

  if not FMouse.CellSelecting and not FMouse.CheckBoxSelecting then
  begin
    FDragScrollTimer.Enabled := False;

    Exit;
  end;

  if FMouse.DragPoint.Y < FLayout.DataTop then
    LDistance := FMouse.DragPoint.Y - FLayout.DataTop
  else
    LDistance := FMouse.DragPoint.Y - FLayout.DataRect.Bottom + 1;

  ScrollToRow(FScrollHelper.TopRow + Sign(LDistance) * (1 + Abs(LDistance) div FLayout.RowHeight));

  if FMouse.CheckBoxSelecting then
    SelectCheckBoxRows(FMouse.DragPoint.Y)
  else
    SelectCellsAt(FMouse.DragPoint.X, FMouse.DragPoint.Y);
end;

procedure TCustomDatabaseGrid.DropDown;
var
  LList: TDatabaseGridDropDownList;
begin
  if not Assigned(FEditColumn) then
    Exit;

  case FEditColumn.GetEditorKind of
    ekLookup, ekPickList:
      begin
        LList := GetDropDownList;
        LList.Font.Assign(FEditor.Font);
        LList.MatchBackground := FStyledColors.SearchMatchBackground;

        LoadDropDownItems(FEditColumn);

        LList.SetFilter('', False);
        LList.SelectText(FEditor.Text);
        LList.DropDown(GetCurrentCellScreenRect, FEditColumn.DropDownRowCount);
      end;
    ekDate, ekDateTime, ekTime:
      ShowCalendarPopup;
  end;
end;

procedure TCustomDatabaseGrid.DropDownListAccept(ASender: TObject);
begin
  AcceptDropDownItem(FDropDownList.SelectedItem);
end;

procedure TCustomDatabaseGrid.DrawColumnCell(const AColumn: TDatabaseGridColumn; const ACanvas: TCanvas; const ARect: TRect;
  const AState: TDatabaseGridDrawCellStates; var AParams: TDatabaseGridDrawCellParams);
begin
  if Assigned(FOnDrawColumnCell) then
    FOnDrawColumnCell(Self, AColumn, ACanvas, ARect, AState, AParams);
end;

procedure TCustomDatabaseGrid.DrawFooterCell(const AColumn: TDatabaseGridColumn; const ACanvas: TCanvas; const ARect: TRect;
  const AState: TDatabaseGridDrawCellStates; var AParams: TDatabaseGridDrawCellParams);
begin
  if Assigned(FOnDrawFooterCell) then
    FOnDrawFooterCell(Self, AColumn, ACanvas, ARect, AParams);
end;

procedure TCustomDatabaseGrid.DrawGroupRow(const ANode: TDatabaseGridGroupNode; const ACanvas: TCanvas; const ARect: TRect;
  const AState: TDatabaseGridDrawCellStates; var AParams: TDatabaseGridDrawGroupRowParams);
begin
  if Assigned(FOnDrawGroupRow) then
    FOnDrawGroupRow(Self, ANode, ACanvas, ARect, AState, AParams);
end;

procedure TCustomDatabaseGrid.EditCurrentCell(const ASelectAll: Boolean);
var
  LColumn: TDatabaseGridColumn;
begin
  if not CanEditCurrentCell then
    Exit;

  LColumn := GetCurrentColumn;

  case LColumn.GetEditorKind of
    ekCheckBox:
      ;
    ekMemo:
      ShowMemoPopup;
    ekEllipsis:
      if IsInlineEditor(LColumn) then
        ShowEditor(ASelectAll)
      else
        DoEditButtonClick;
  else
    ShowEditor(ASelectAll);
  end;
end;

procedure TCustomDatabaseGrid.EditorChange(ASender: TObject);
var
  LKind: TDatabaseGridEditorKind;
begin
  if FEditorTextUpdating or not Assigned(FEditColumn) then
    Exit;

  LKind := FEditColumn.GetEditorKind;

  if not (LKind in [ekLookup, ekPickList]) then
    Exit;

  if not IsDropDownVisible then
    DropDown;

  FDropDownList.SetFilter(FEditor.Text, (LKind = ekLookup) and not Trim(FEditor.Text).IsEmpty);
end;

procedure TCustomDatabaseGrid.EditorExit(ASender: TObject);
begin
  CloseDropDown;
  Invalidate;
end;

procedure TCustomDatabaseGrid.EditorKeyCommand(var AKey: Word; const AShift: TShiftState);
var
  LGlyph: TDatabaseGridGlyph;
  LKey: Word;
begin
  if not Assigned(FEditColumn) then
    Exit;

  if ((AKey = vkDown) and (AShift = [ssAlt]) or (AKey = vkF4) and (AShift = [])) and HasEditButton(FEditColumn, LGlyph) then
  begin
    AKey := 0;

    if IsDropDownVisible then
      CloseDropDown
    else
      DropDown;

    Exit;
  end;

  if (AKey = vkReturn) and (AShift = [ssCtrl]) and (FEditColumn.GetEditorKind = ekEllipsis) then
  begin
    AKey := 0;

    EndEdit;
    DoEditButtonClick;

    Exit;
  end;

  if (AKey = vkBack) and (AShift = [ssCtrl]) then
  begin
    AKey := 0;

    ClearCurrentCell;

    Exit;
  end;

  if IsDropDownVisible then
  case AKey of
    vkUp, vkDown:
      begin
        FDropDownList.MoveSelection(if AKey = vkUp then -1 else 1);

        AKey := 0;

        Exit;
      end;
    vkPrior, vkNext:
      begin
        FDropDownList.MoveSelection((if AKey = vkPrior then -1 else 1) * Max(FEditColumn.DropDownRowCount - 1, 1));

        AKey := 0;

        Exit;
      end;
    vkEscape:
      begin
        CloseDropDown;

        AKey := 0;

        Exit;
      end;
    vkReturn:
      if FDropDownList.SelectedItem >= 0 then
      begin
        AcceptDropDownItem(FDropDownList.SelectedItem);

        AKey := 0;

        Exit;
      end
      else
        CloseDropDown;
    vkTab:
      CloseDropDown;
  end;

  case AKey of
    vkEscape:
      begin
        AKey := 0;

        HideEditor;
      end;
    vkReturn:
      begin
        EndEdit;

        AKey := 0;

        if dgoEnterAsTab in FOptions then
          MoveToNextCell(True);
      end;
    vkTab:
      begin
        EndEdit;

        AKey := 0;

        MoveToNextCell(not (ssShift in AShift));
      end;
    vkUp, vkDown, vkPrior, vkNext:
      begin
        EndEdit;

        LKey := AKey;
        AKey := 0;

        KeyDown(LKey, AShift);
      end;
  end;
end;

procedure TCustomDatabaseGrid.EditorPopupClose(ASender: TObject; var AAction: TCloseAction);
var
  LPoint: TPoint;
begin
  LPoint := ScreenToClient(Mouse.CursorPos);

  if (ASender as TDatabaseGridEditorPopup).ClosedByDeactivation and IsEditButtonAt(LPoint.X, LPoint.Y) then
  begin
    FEditorPopupClosedByClick := FPopupColumn;
    FEditorPopupClosedTicks := GetTickCount64;
  end;
end;

procedure TCustomDatabaseGrid.EndEdit;
begin
  if not Assigned(FEditColumn) then
    Exit;

  if FEditor.Modified and (FDataLink.Editing or FDataLink.Edit) then
    WriteEditorText;

  HideEditor;
end;

procedure TCustomDatabaseGrid.ExtendCellRange;
begin
  if not IsCellMode or FGroups.Active or not FDataLink.Active or (FDataLink.DataSet.State = dsInsert) or
    FDataLink.DataSet.IsEmpty or Assigned(FRangeAnchor) then
    Exit;

  FRangeAnchor := FDataLink.DataSet.Bookmark;
  FRangeAnchorColumn := GetCurrentColumn;
end;

procedure TCustomDatabaseGrid.FitColumnsToTitles;
var
  LBitmap: TBitmap;
begin
  LBitmap := CreateMeasureBitmap;
  FColumns.BeginUpdate;
  try
    for var LIndex := 0 to FColumns.Count - 1 do
      FColumns[LIndex].Width := Max(FColumns[LIndex].Width, FLayout.UnzoomWidth(MeasureTitleWidth(LBitmap.Canvas, FColumns[LIndex])));
  finally
    FColumns.EndUpdate;
    LBitmap.Free;
  end;
end;

procedure TCustomDatabaseGrid.GroupKeyDown(const AKey: Word; const AShift: TShiftState);
var
  LNode: TDatabaseGridGroupNode;
  LRow: Integer;
begin
  LRow := FGroups.FocusedRow;
  LNode := FGroups.GetRowNode(LRow);

  case AKey of
    vkUp:
      MoveToRow(LRow - 1);
    vkDown:
      MoveToRow(LRow + 1);
    vkPrior:
      MoveToRow(LRow - FLayout.VisibleRowCount);
    vkNext:
      MoveToRow(LRow + FLayout.VisibleRowCount);
    vkHome:
      if ssCtrl in AShift then
        MoveToRow(0)
      else
        MoveCurrentColumn(-FColumns.Count);
    vkEnd:
      if ssCtrl in AShift then
        MoveToRow(FGroups.RowCount - 1)
      else
        MoveCurrentColumn(FColumns.Count);
    vkLeft:
      if not Assigned(LNode) then
        MoveCurrentColumn(-1)
      else
      if LNode.Expanded then
        LNode.Expanded := False
      else
      if Assigned(LNode.Parent) then
        MoveToRow(LNode.Parent.Row);
    vkRight:
      if not Assigned(LNode) then
        MoveCurrentColumn(1)
      else
      if not LNode.Expanded then
        LNode.Expanded := True;
    vkSpace:
      if (dgoMultiSelect in FOptions) and not Assigned(LNode) then
        FSelectedRows.CurrentRowSelected := not FSelectedRows.CurrentRowSelected;
  end;
end;

procedure TCustomDatabaseGrid.GroupsChanged(ASender: TObject);
begin
  if not (csDestroying in ComponentState) then
    ScrollCurrentRowIntoView;
end;

procedure TCustomDatabaseGrid.GroupsExpandedChange(ASender: TObject; const ANode: TDatabaseGridGroupNode);
begin
  if Assigned(FOnGroupExpandedChange) then
    FOnGroupExpandedChange(Self, ANode);
end;

procedure TCustomDatabaseGrid.HideEditor;
begin
  if not Assigned(FEditColumn) then
    Exit;

  FEditColumn := nil;

  CloseDropDown;

  if FEditor.Focused and CanFocus then
    SetFocus;

  FEditor.Visible := False;

  Invalidate;
end;

procedure TCustomDatabaseGrid.InvalidateDesignSelection;
var
  LComponents: TArray<TComponent>;
begin
  if not HandleAllocated then
    Exit;

  InvalidateRect(Handle, Rect(0, FLayout.TitleTop, ClientWidth, FLayout.DataTop), False);

  LComponents := GetDesignLinks;

  for var LIndex := 0 to High(LComponents) do
    InvalidateRect(Handle, GetDesignLinkRect(LIndex, Length(LComponents)), False);
end;

procedure TCustomDatabaseGrid.InvalidateFooterValues;
begin
  if FFooterCalculator.Invalidate then
    PostFooterCalculation;
end;

procedure TCustomDatabaseGrid.InvalidateTitle(const AColumn: TDatabaseGridColumn);
var
  LLeft: Integer;
begin
  if HandleAllocated and FLayout.TryGetColumnLeft(AColumn, LLeft) then
    InvalidateRect(Handle, Rect(LLeft, FLayout.TitleTop, LLeft + FLayout.GetColumnWidth(AColumn), FLayout.DataTop), False);
end;

procedure TCustomDatabaseGrid.LoadDropDownItems(const AColumn: TDatabaseGridColumn);
var
  LBookmark: TBookmark;
  LField: TField;
  LItems: TStrings;
  LLookupDataSet: TDataSet;
begin
  LItems := GetDropDownList.Items;
  LItems.Clear;
  FLookupKeys := nil;

  if AColumn.GetEditorKind <> ekLookup then
  begin
    LItems.Assign(AColumn.PickList);

    Exit;
  end;

  LField := AColumn.Field;
  LLookupDataSet := LField.LookupDataSet;

  LLookupDataSet.DisableControls;
  try
    LBookmark := LLookupDataSet.Bookmark;
    try
      LLookupDataSet.First;

      while not LLookupDataSet.Eof do
      begin
        LItems.Add(LLookupDataSet.FieldByName(LField.LookupResultField).DisplayText);
        FLookupKeys := FLookupKeys + [LLookupDataSet.FieldValues[LField.LookupKeyFields]];

        LLookupDataSet.Next;
      end;
    finally
      if LLookupDataSet.BookmarkValid(LBookmark) then
        LLookupDataSet.Bookmark := LBookmark;
    end;
  finally
    LLookupDataSet.EnableControls;
  end;
end;

procedure TCustomDatabaseGrid.MemoPopupAccept(ASender: TObject; const AText: string);
begin
  if FColumns.Contains(FPopupColumn) and (GetCurrentColumn = FPopupColumn) and FDataLink.Edit then
    FPopupColumn.Field.AsString := AText;
end;

procedure TCustomDatabaseGrid.MouseScrollTimerTimer(ASender: TObject);
var
  LPoint: TPoint;
begin
  if not FDataLink.Active then
  begin
    StopMouseScrolling;

    Exit;
  end;

  BeginUpdate;
  try
    if FMouse.ScrollDelta.Y <> 0 then
      SetTopRow(GetTopRow + FMouse.ScrollDelta.Y);

    if FMouse.ScrollDelta.X <> 0 then
      FLayout.HorizontalPosition := FLayout.HorizontalPosition +
        FMouse.ScrollDelta.X * FLayout.ScaleMetric(TDatabaseGridSize.HorizontalScrollStep);
  finally
    EndUpdate;
  end;

  LPoint := ScreenToClient(Mouse.CursorPos);

  UpdateMouseScrolling(LPoint.X, LPoint.Y);
end;

procedure TCustomDatabaseGrid.IndicatorChanged(ASender: TObject);
begin
  if Assigned(FIndicator.TitleMenu.DropdownMenu) then
    FIndicator.TitleMenu.DropdownMenu.FreeNotification(Self);

  if Assigned(FIndicator.TitleMenu.Images) then
    FIndicator.TitleMenu.Images.FreeNotification(Self);

  UpdateLayout;
end;

procedure TCustomDatabaseGrid.InvertRowSelection;
begin
  if dgoMultiSelect in FOptions then
    FSelectedRows.Invert;
end;

procedure TCustomDatabaseGrid.JumpToColumn;
var
  LColumn: TDatabaseGridColumn;
begin
  if Assigned(FEditColumn) then
    EndEdit;

  LColumn := GetCurrentColumn;

  if Assigned(FOnJumpToColumn) then
    FOnJumpToColumn(Self, LColumn)
  else
  if not TDatabaseGridColumnListDialog.Execute(Self, Font, LColumn) then
    LColumn := nil;

  SetCurrentColumn(LColumn);
end;

procedure TCustomDatabaseGrid.InsertRecord;
begin
  if not CanEdit or FGroups.Active then
    Exit;

  HideEditor;
  CollapseCellRange;

  FDataLink.DataSet.Insert;

  if not CanEditColumn(GetCurrentColumn) then
  for var LIndex := 0 to FLayout.VisibleColumnCount - 1 do
  if CanEditColumn(FLayout.VisibleColumns[LIndex]) then
  begin
    SetCurrentColumn(FLayout.VisibleColumns[LIndex]);

    Break;
  end;
end;

procedure TCustomDatabaseGrid.KeyDown(var AKey: Word; AShift: TShiftState);
begin
  if FMouse.Scrolling then
  begin
    StopMouseScrolling;

    if AKey = vkEscape then
      AKey := 0;
  end;

  inherited KeyDown(AKey, AShift);

  if (AKey = Ord('F')) and (AShift = [ssCtrl]) and FSearchPanel.Visible then
  begin
    AKey := 0;

    FSearchPanelControls.BeginSearch('');
  end;

  if (AKey = Ord('A')) and (AShift = [ssCtrl, ssShift]) and CanRunSelectionCommand(tmcInvertSelection) then
  begin
    AKey := 0;

    FSelectedRows.Invert;
  end;

  if AShift = [ssCtrl] then
  case AKey of
    Ord('A'):
      if CanRunSelectionCommand(tmcSelectAll) then
      begin
        AKey := 0;

        FSelectedRows.SelectAll;
      end
      else
      if IsCellMode and FDataLink.Active then
      begin
        AKey := 0;

        SelectAllCells;
      end;
    Ord('D'):
      if CanRunSelectionCommand(tmcUnselectAll) then
      begin
        AKey := 0;

        FSelectedRows.Clear;
      end;
    Ord('J'):
      if FIndicator.TitleMenu.Commands[tmcJumpToColumn].Visible then
      begin
        AKey := 0;

        JumpToColumn;
      end;
    Ord('C'), vkInsert:
      begin
        AKey := 0;

        CopyToClipboard;
      end;
    vkAdd, vkEqual:
      begin
        AKey := 0;

        ZoomIn;
      end;
    vkSubtract, vkMinus:
      begin
        AKey := 0;

        ZoomOut;
      end;
    vk0, vkNumpad0:
      begin
        AKey := 0;

        ZoomReset;
      end;
  end;

  if not FDataLink.Active then
    Exit;

  if IsCellMode and (AKey <> 0) and HandleEditingKey(AKey, AShift) then
  begin
    AKey := 0;

    Exit;
  end;

  if IsCellMode then
  case AKey of
    vkUp, vkDown, vkPrior, vkNext, vkHome, vkEnd, vkLeft, vkRight:
      if ssShift in AShift then
        ExtendCellRange
      else
        CollapseCellRange;
  end;

  if FGroups.Active then
  begin
    GroupKeyDown(AKey, AShift);

    Exit;
  end;

  case AKey of
    vkUp:
      FDataLink.DataSet.MoveBy(-1);
    vkDown:
      FDataLink.DataSet.MoveBy(1);
    vkPrior:
      FDataLink.DataSet.MoveBy(-FLayout.VisibleRowCount);
    vkNext:
      FDataLink.DataSet.MoveBy(FLayout.VisibleRowCount);
    vkHome:
      if ssCtrl in AShift then
        FDataLink.DataSet.First
      else
        MoveCurrentColumn(-FColumns.Count);
    vkEnd:
      if ssCtrl in AShift then
        FDataLink.DataSet.Last
      else
        MoveCurrentColumn(FColumns.Count);
    vkLeft:
      MoveCurrentColumn(-1);
    vkRight:
      MoveCurrentColumn(1);
    vkSpace:
      if dgoMultiSelect in FOptions then
        FSelectedRows.CurrentRowSelected := not FSelectedRows.CurrentRowSelected;
  end;
end;

procedure TCustomDatabaseGrid.KeyPress(var AKey: Char);
begin
  inherited KeyPress(AKey);

  if IsCellMode then
  begin
    if (AKey >= TCharacters.Space) and (AKey <> TCharacters.CtrlBackspace) and not ((AKey = ' ') and (dgoMultiSelect in FOptions)) and CanEditCurrentCell and
      IsInlineEditor(GetCurrentColumn) then
    begin
      if not Assigned(FEditColumn) then
        ShowEditor(True);

      if Assigned(FEditColumn) then
        FEditor.Perform(WM_CHAR, Ord(AKey), 0);
    end;

    AKey := TControlCharacters.Null;

    Exit;
  end;

  if (AKey > TCharacters.Space) and FSearchPanel.Visible then
  begin
    FSearchPanelControls.BeginSearch(AKey);

    AKey := TControlCharacters.Null;
  end;
end;

procedure TCustomDatabaseGrid.MouseDown(AButton: TMouseButton; AShift: TShiftState; AX, AY: Integer);
var
  LColumn: TDatabaseGridColumn;
  LLeft: Integer;
  LWasFocused: Boolean;
begin
  if csDesigning in ComponentState then
    Exit;

  if FMouse.Scrolling then
  begin
    StopMouseScrolling;

    Exit;
  end;

  if (AButton = mbMiddle) and (dgoMiddleClickAutoscroll in FOptions) and FDataLink.Active then
  begin
    StartMouseScrolling(AX, AY);

    Exit;
  end;

  LWasFocused := Focused or Assigned(FEditColumn) and FEditor.Focused;

  if (AButton = mbLeft) and IsEditButtonAt(AX, AY) then
  begin
    if CanFocus and not LWasFocused then
      SetFocus;

    if (GetCurrentColumn <> FEditorPopupClosedByClick) or (GetTickCount64 - FEditorPopupClosedTicks > GetDoubleClickTime) then
      PressEditButton;

    FEditorPopupClosedByClick := nil;

    Exit;
  end;

  if Assigned(FEditColumn) then
    EndEdit;

  if CanFocus and not Focused then
    SetFocus;

  inherited MouseDown(AButton, AShift, AX, AY);

  if AButton <> mbLeft then
    Exit;

  FMouse.DownArea := GetAreaAt(AX, AY);
  FMouse.Column := nil;
  FMouse.CellSelecting := False;
  FMouse.CheckBoxSelecting := False;
  FMouse.ClickColumn := nil;
  FMouse.RecordMoving := False;
  FMouse.DropIndex := -1;

  case FMouse.DownArea of
    gaIndicatorTitle:
      ShowIndicatorTitleMenu;
    gaTitle:
      begin
        LColumn := FLayout.GetTitleColumnAt(AX, AY, LLeft);

        if Assigned(LColumn) and (GetTitleButtonColumnAt(AX, AY) = LColumn) then
        begin
          if (LColumn <> FColumnFilterClosedByClick) or (GetTickCount64 - FColumnFilterClosedTicks > GetDoubleClickTime) then
            ShowColumnFilterPopup(LColumn);

          FColumnFilterClosedByClick := nil;

          Exit;
        end;

        if dgoColumnResize in FOptions then
          FMouse.Column := GetResizeColumnAt(AX, AY);

        if Assigned(FMouse.Column) then
        begin
          FMouse.Resizing := True;
          FMouse.ResizeOrigin := AX;
          FMouse.ResizeWidth := FLayout.GetColumnWidth(FMouse.Column);
        end
        else
        begin
          FMouse.Column := FLayout.GetTitleColumnAt(AX, AY, LLeft);
          FMouse.TitlePressed := Assigned(FMouse.Column) and (toButton in FMouse.Column.Title.Options);

          if FMouse.TitlePressed then
            InvalidateTitle(FMouse.Column);
        end;
      end;
    gaIndicator, gaData:
      if FDataLink.Active then
        DataMouseDown(AShift, AX, AY, LWasFocused);
  end;
end;

procedure TCustomDatabaseGrid.MouseMove(AShift: TShiftState; AX, AY: Integer);
var
  LLeft: Integer;
begin
  inherited MouseMove(AShift, AX, AY);

  if FMouse.Scrolling then
  begin
    UpdateMouseScrolling(AX, AY);

    Winapi.Windows.SetCursor(GetMouseScrollCursor);

    Exit;
  end;

  if GetAreaAt(AX, AY) = gaTitle then
    SetHotTitleColumn(FLayout.GetTitleColumnAt(AX, AY, LLeft))
  else
    SetHotTitleColumn(nil);

  if FMouse.Resizing and FColumns.Contains(FMouse.Column) then
    ResizeColumn(FMouse.Column, Max(FMouse.ResizeWidth + AX - FMouse.ResizeOrigin, FLayout.ScaleMetric(TDatabaseGridSize.MinColumnWidth)))
  else
  if FMouse.RecordMoving and (ssLeft in AShift) then
    UpdateDropIndex(AY)
  else
  if FMouse.CheckBoxSelecting then
  begin
    SelectCheckBoxRows(AY);
    UpdateDragScrolling(AX, AY);
  end
  else
  if FMouse.CellSelecting and (ssLeft in AShift) then
  begin
    SelectCellsAt(AX, AY);
    UpdateDragScrolling(AX, AY);
  end;
end;

procedure TCustomDatabaseGrid.MouseUp(AButton: TMouseButton; AShift: TShiftState; AX, AY: Integer);
var
  LColumn: TDatabaseGridColumn;
  LFromIndex, LLeft, LToIndex: Integer;
begin
  inherited MouseUp(AButton, AShift, AX, AY);

  if AButton <> mbLeft then
    Exit;

  LColumn := FMouse.Column;

  if FMouse.Resizing then
  begin
    FMouse.Resizing := False;

    if FColumns.Contains(LColumn) and Assigned(FOnColumnResize) then
      FOnColumnResize(Self, LColumn);
  end
  else
  if (FMouse.DownArea = gaTitle) and Assigned(LColumn) and (GetAreaAt(AX, AY) = gaTitle) and
    (FLayout.GetTitleColumnAt(AX, AY, LLeft) = LColumn) then
    TitleClick(LColumn, AShift);

  if FMouse.TitlePressed then
  begin
    FMouse.TitlePressed := False;

    InvalidateTitle(LColumn);
  end;

  if FMouse.RecordMoving then
  begin
    FMouse.RecordMoving := False;
    LFromIndex := FMouse.MoveFromIndex;
    LToIndex := FMouse.DropIndex;
    FMouse.DropIndex := -1;

    Invalidate;

    if (LToIndex >= 0) and CanMoveRecords then
    begin
      if LToIndex > LFromIndex then
        Dec(LToIndex);

      FOnMoveRecord(Self, LFromIndex, LToIndex);

      if FDataLink.Active and (LToIndex < FDataLink.DataSet.RecordCount) then
        FDataLink.DataSet.RecNo := LToIndex + 1;
    end;
  end;

  if Assigned(FMouse.ClickColumn) and Assigned(FOnCellClick) and FColumns.Contains(FMouse.ClickColumn) and
    (GetAreaAt(AX, AY) = gaData) and (FLayout.GetColumnAt(AX, LLeft) = FMouse.ClickColumn) and (GetRowAt(AY) = GetCurrentRow) then
    FOnCellClick(Self, FMouse.ClickColumn);

  FMouse.CellSelecting := False;
  FMouse.CheckBoxSelecting := False;
  FMouse.ClickColumn := nil;
  FMouse.Column := nil;
  FMouse.DownArea := gaNone;

  if Assigned(FDragScrollTimer) then
    FDragScrollTimer.Enabled := False;
end;

procedure TCustomDatabaseGrid.MoveCurrentColumn(const ADistance: Integer);
var
  LIndex, LStep, LVisibleIndex: Integer;
begin
  if (ADistance = 0) or (FColumns.Count = 0) then
    Exit;

  LStep := Sign(ADistance);
  LIndex := EnsureRange(FCurrentColumnIndex, 0, FColumns.Count - 1);
  LVisibleIndex := LIndex;

  for var LCount := 1 to Abs(ADistance) do
  begin
    repeat
      Inc(LIndex, LStep);
    until (LIndex < 0) or (LIndex >= FColumns.Count) or FColumns[LIndex].Visible;

    if (LIndex < 0) or (LIndex >= FColumns.Count) then
      Break;

    LVisibleIndex := LIndex;
  end;

  SetCurrentColumn(FColumns[LVisibleIndex]);
end;

procedure TCustomDatabaseGrid.MoveToNextCell(const AForward: Boolean);
var
  LAnyEditable: Boolean;
  LCount, LPosition: Integer;
begin
  LCount := FLayout.VisibleColumnCount;

  if not FDataLink.Active or (LCount = 0) then
    Exit;

  LAnyEditable := False;

  for var LIndex := 0 to LCount - 1 do
  if CanEditColumn(FLayout.VisibleColumns[LIndex]) then
  begin
    LAnyEditable := True;

    Break;
  end;

  CollapseCellRange;

  LPosition := FLayout.IndexOfVisibleColumn(GetCurrentColumn);

  repeat
    if AForward then
      Inc(LPosition)
    else
      Dec(LPosition);

    if LPosition >= LCount then
    begin
      if not MoveRowBy(1) then
        Exit;

      LPosition := 0;
    end
    else
    if LPosition < 0 then
    begin
      if not MoveRowBy(-1) then
        Exit;

      LPosition := LCount - 1;
    end;
  until not LAnyEditable or CanEditColumn(FLayout.VisibleColumns[LPosition]) and IsRecordRow;

  SetCurrentColumn(FLayout.VisibleColumns[LPosition]);
end;

procedure TCustomDatabaseGrid.MoveToRow(const ARow: Integer);
var
  LRecordIndex, LRow: Integer;
begin
  if not FDataLink.Active then
    Exit;

  if not FGroups.Active then
  begin
    if ARow <> FDataLink.ActiveRecord then
      FDataLink.DataSet.MoveBy(ARow - FDataLink.ActiveRecord);

    Exit;
  end;

  if FGroups.RowCount = 0 then
    Exit;

  LRow := EnsureRange(ARow, 0, FGroups.RowCount - 1);
  LRecordIndex := FGroups.Rows[LRow].RecordIndex;

  if LRecordIndex <> FDataLink.ActiveRecord then
    FDataLink.DataSet.MoveBy(LRecordIndex - FDataLink.ActiveRecord);

  FGroups.FocusedNode := FGroups.GetRowNode(LRow);

  ScrollCurrentRowIntoView;
end;

procedure TCustomDatabaseGrid.Notification(AComponent: TComponent; AOperation: TOperation);
begin
  inherited Notification(AComponent, AOperation);

  if AOperation <> opRemove then
    Exit;

  if AComponent = FColumnFilterPopup then
    FColumnFilterPopup := nil;

  if csDestroying in ComponentState then
    Exit;

  if Assigned(FDataLink) and (AComponent = FDataLink.DataSource) then
    FDataLink.DataSource := nil
  else
  if Assigned(FIndicator) and (AComponent = FIndicator.TitleMenu.DropdownMenu) then
    FIndicator.TitleMenu.DropdownMenu := nil
  else
  if Assigned(FIndicator) and (AComponent = FIndicator.TitleMenu.Images) then
    FIndicator.TitleMenu.Images := nil
  else
  if Assigned(FDataGrouping) and (AComponent = FDataGrouping.Images) then
    FDataGrouping.Images := nil;

  if Assigned(FTitle) and (AComponent = FTitle.Images) then
    FTitle.Images := nil;

  if Assigned(FColumns) then
  for var LIndex := 0 to FColumns.Count - 1 do
  if FColumns[LIndex].Images = AComponent then
    FColumns[LIndex].Images := nil;
end;

procedure TCustomDatabaseGrid.Paint;
var
  LRangeEnd, LRangeStart: TBookmark;
  LState: TDatabaseGridPaintState;
begin
  if FPaintLock > 0 then
    Exit;

  Canvas.Font := Font;
  Canvas.Font.Height := FLayout.FontHeight;

  LState.ClientRect := ClientRect;
  LState.CurrentColumn := GetCurrentColumn;
  LState.DrawColumnCell := nil;
  LState.DrawFooterCell := nil;
  LState.DrawGroupRow := nil;
  LState.DropRow := if FMouse.RecordMoving and (FMouse.DropIndex >= 0) then FMouse.DropIndex - GetRowOffset else -1;
  LState.EditButtonGlyph := glDropDown;
  LState.EditingColumn := FEditColumn;
  LState.Focused := Focused or Assigned(FEditColumn) and FEditor.Focused;
  LState.FooterVerticalLines := FFooter.VerticalLines;
  LState.GroupImages := FDataGrouping.Images;
  LState.IsReadOnlyColumn := nil;
  LState.Options := FOptions;
  LState.PressedTitleColumn := if FMouse.TitlePressed then FMouse.Column else nil;
  LState.RangeEnd := nil;
  LState.RangeFirstColumn := -1;
  LState.RangeLastColumn := -1;
  LState.RangeStart := nil;
  LState.SearchPanelHighlighted := FSearchPanelControls.IsHighlighted;
  LState.SearchWords := nil;
  LState.ShowEditButton := IsCellMode and FDataLink.Active and CanEditCurrentCell and HasEditButton(GetCurrentColumn, LState.EditButtonGlyph);

  if CanEdit then
    LState.IsReadOnlyColumn := IsReadOnlyColumn;

  if GetRangeBookmarks(LRangeStart, LRangeEnd) then
  begin
    LState.RangeEnd := LRangeEnd;
    LState.RangeFirstColumn := Min(FLayout.IndexOfVisibleColumn(FRangeAnchorColumn), FLayout.IndexOfVisibleColumn(GetCurrentColumn));
    LState.RangeLastColumn := Max(FLayout.IndexOfVisibleColumn(FRangeAnchorColumn), FLayout.IndexOfVisibleColumn(GetCurrentColumn));
    LState.RangeStart := LRangeStart;
  end;

  LState.TitleImages := FTitle.Images;
  LState.TitleVerticalLines := FTitle.VerticalLines;
  LState.TopRow := FScrollHelper.TopRow;

  if Assigned(FOnDrawColumnCell) then
    LState.DrawColumnCell := DrawColumnCell;

  if Assigned(FOnDrawFooterCell) then
    LState.DrawFooterCell := DrawFooterCell;

  if Assigned(FOnDrawGroupRow) then
    LState.DrawGroupRow := DrawGroupRow;

  if FSearchPanel.Visible and (spoHighlightMatches in FSearchPanel.Options) then
    LState.SearchWords := AnsiUpperCase(FFilterController.Text).Split([' '], TStringSplitOptions.ExcludeEmpty);

  FPainter.Paint(Canvas, LState);

  if FMouse.Scrolling then
    PaintDatabaseGridGlyph(Canvas, GetMouseScrollIndicatorRect, glMouseScroll, FStyledColors.DataForeground);

  if csDesigning in ComponentState then
    PaintDesignSelection;
end;

procedure TCustomDatabaseGrid.PaintBorder;
var
  LBrush: HBRUSH;
  LDC: HDC;
  LRect: TRect;
begin
  if (FBorder.Style <> bsSingle) or (FBorder.ColoredEdges = []) then
    Exit;

  LDC := GetWindowDC(Handle);
  try
    GetWindowRect(Handle, LRect);
    LRect.Offset(-LRect.Left, -LRect.Top);

{$IFDEF DATABASE_GRID_VCL_STYLES}
    if TStyleManager.IsCustomStyleActive and (FBorder.Color = TColors.SysActiveBorder) then
      Exit;

    LBrush := CreateSolidBrush(ColorToRGB(StyleServices.GetSystemColor(FBorder.Color)));
{$ELSE}
    LBrush := CreateSolidBrush(ColorToRGB(FBorder.Color));
{$ENDIF}
    try
      if ebLeft in FBorder.ColoredEdges then
        Winapi.Windows.FillRect(LDC, Rect(LRect.Left, LRect.Top, LRect.Left + 1, LRect.Bottom), LBrush);

      if ebTop in FBorder.ColoredEdges then
        Winapi.Windows.FillRect(LDC, Rect(LRect.Left, LRect.Top, LRect.Right, LRect.Top + 1), LBrush);

      if ebRight in FBorder.ColoredEdges then
        Winapi.Windows.FillRect(LDC, Rect(LRect.Right - 1, LRect.Top, LRect.Right, LRect.Bottom), LBrush);

      if ebBottom in FBorder.ColoredEdges then
        Winapi.Windows.FillRect(LDC, Rect(LRect.Left, LRect.Bottom - 1, LRect.Right, LRect.Bottom), LBrush);
    finally
      DeleteObject(LBrush);
    end;
  finally
    ReleaseDC(Handle, LDC);
  end;
end;

procedure TCustomDatabaseGrid.PaintDesignColumns;
var
  LRect: TRect;
begin
  if not Assigned(GDatabaseGridDesignHook) then
    Exit;

  for var LIndex := 0 to FLayout.VisibleColumnCount - 1 do
  begin
    LRect := Rect(FLayout.GetVisibleColumnLeft(LIndex), FLayout.GetTitleTop(LIndex), FLayout.GetVisibleColumnRight(LIndex),
      FLayout.DataTop);

    if (LRect.Right <= FLayout.DataLeft) or (LRect.Left >= ClientWidth) then
      Continue;

    if GDatabaseGridDesignHook.IsComponentSelected(FLayout.VisibleColumns[LIndex]) then
      PaintDesignHandles(LRect);
  end;
end;

procedure TCustomDatabaseGrid.PaintDesignHandles(const ARect: TRect);
var
  LHandleSize: Integer;

  procedure PaintHandle(const ACenterX, ACenterY: Integer);
  var
    LHandleRect: TRect;
  begin
    LHandleRect := Bounds(ACenterX - LHandleSize div 2, ACenterY - LHandleSize div 2, LHandleSize, LHandleSize);

    Canvas.Brush.Color := TDatabaseGridColor.DesignHandleBorder;
    Canvas.FrameRect(LHandleRect);

    LHandleRect.Inflate(-1, -1);

    Canvas.Brush.Color := TDatabaseGridColor.DesignHandle;
    Canvas.FillRect(LHandleRect);
  end;

begin
  LHandleSize := ScaleMetric(TDatabaseGridSize.DesignHandle);

  PaintHandle(ARect.Left, ARect.Top);
  PaintHandle(ARect.Right - 1, ARect.Top);
  PaintHandle(ARect.Left, ARect.Bottom - 1);
  PaintHandle(ARect.Right - 1, ARect.Bottom - 1);
end;

procedure TCustomDatabaseGrid.PaintDesignLinks;
var
  LComponents: TArray<TComponent>;
  LImage: TGraphic;
  LImageSize: Integer;
  LLinkRect, LRect: TRect;
  LText: string;
begin
  LComponents := GetDesignLinks;

  if Length(LComponents) = 0 then
    Exit;

  LImageSize := ScaleMetric(TDatabaseGridSize.DesignLinkImage);

  for var LIndex := 0 to High(LComponents) do
  begin
    LLinkRect := GetDesignLinkRect(LIndex, Length(LComponents));
    LRect := LLinkRect;

    Canvas.Brush.Color := TColors.SysBtnShadow;
    Canvas.FrameRect(LRect);

    LRect.Inflate(-1, -1);

    Canvas.Brush.Color := TColors.SysBtnFace;
    Canvas.FillRect(LRect);

    LImage := nil;

    if Assigned(GDatabaseGridDesignHook) then
      LImage := GDatabaseGridDesignHook.GetComponentImage(LComponents[LIndex], LImageSize);

    if Assigned(LImage) then
      Canvas.StretchDraw(Bounds(LRect.Left + (LRect.Width - LImageSize) div 2, LRect.Top + (LRect.Height - LImageSize) div 2,
        LImageSize, LImageSize), LImage)
    else
    begin
      LText := Copy(LComponents[LIndex].ClassName, 2, 1);

      Canvas.Font.Color := TColors.SysBtnText;
      Canvas.TextRect(LRect, LRect.Left + (LRect.Width - Canvas.TextWidth(LText)) div 2,
        LRect.Top + (LRect.Height - FLayout.TextHeight) div 2, LText);
    end;

    if Assigned(GDatabaseGridDesignHook) and GDatabaseGridDesignHook.IsComponentSelected(LComponents[LIndex]) then
      PaintDesignHandles(LLinkRect);
  end;
end;

procedure TCustomDatabaseGrid.PaintDesignSelection;
begin
  if Assigned(GDatabaseGridDesignHook) then
    GDatabaseGridDesignHook.RegisterGrid(Self);

  PaintDesignLinks;
  PaintDesignColumns;
end;

{$IFDEF DATABASE_GRID_VCL_STYLES}
procedure TCustomDatabaseGrid.PaintStyledFrame;
var
  LBrush: HBRUSH;
  LClientRect, LRect: TRect;
  LDC: HDC;
  LOrigin: TPoint;
begin
  if FBorder.Style <> bsSingle then
    Exit;

  LDC := GetWindowDC(Handle);
  try
    GetWindowRect(Handle, LRect);
    LOrigin := LRect.TopLeft;
    LRect.Offset(-LRect.Left, -LRect.Top);

    Winapi.Windows.GetClientRect(Handle, LClientRect);
    MapWindowPoints(Handle, 0, LClientRect, 2);
    LClientRect.Offset(-LOrigin.X, -LOrigin.Y);
    ExcludeClipRect(LDC, LClientRect.Left, LClientRect.Top, LClientRect.Right, LClientRect.Bottom);

    LBrush := CreateSolidBrush(ColorToRGB(FStyledColors.GridBackground));
    try
      Winapi.Windows.FillRect(LDC, LRect, LBrush);
    finally
      DeleteObject(LBrush);
    end;

    ExcludeClipRect(LDC, LRect.Left + 1, LRect.Top + 1, LRect.Right - 1, LRect.Bottom - 1);
    StyleServices.DrawElement(LDC, StyleServices.GetElementDetails(teEditBorderNoScrollNormal), LRect);
  finally
    ReleaseDC(Handle, LDC);
  end;
end;
{$ENDIF}

procedure TCustomDatabaseGrid.PasteFromClipboard;
var
  LBookmark: TBookmark;
  LBookmarks: TArray<TBookmark>;
  LColumns: TArray<TDatabaseGridColumn>;
  LDataSet: TDataSet;
  LFirstColumn: Integer;
  LRows: TArray<TArray<string>>;
  LValues: TArray<string>;

  procedure WriteRow(const AColumns: TArray<TDatabaseGridColumn>; const AValues: TArray<string>);
  begin
    LDataSet.Edit;
    try
      for var LIndex := 0 to High(AColumns) do
      if CanEditColumn(AColumns[LIndex]) then
        SetColumnText(AColumns[LIndex], AValues[LIndex]);

      LDataSet.Post;
    except
      LDataSet.Cancel;

      raise;
    end;
  end;

  function GetRowColumns(const ACount: Integer): TArray<TDatabaseGridColumn>;
  begin
    Result := nil;

    for var LIndex := LFirstColumn to Min(LFirstColumn + ACount, FLayout.VisibleColumnCount) - 1 do
      Result := Result + [FLayout.VisibleColumns[LIndex]];
  end;

begin
  if not CanEdit or not Clipboard.HasFormat(CF_TEXT) then
    Exit;

  LRows := TDatabaseGridClipboard.ParseText(Clipboard.AsText);

  if Length(LRows) = 0 then
    Exit;

  if (Length(LRows) = 1) and (Length(LRows[0]) = 1) and not Assigned(FRangeAnchor) then
  begin
    if CanEditCurrentCell then
    begin
      ShowEditor(True);

      if Assigned(FEditColumn) then
        FEditor.PasteFromClipboard;
    end;

    Exit;
  end;

  if FGroups.Active then
    Exit;

  LDataSet := FDataLink.DataSet;

  HideEditor;
  LDataSet.CheckBrowseMode;

  if not GetSelectedCells(LBookmarks, LColumns) or (Length(LBookmarks) = 0) then
    Exit;

  LFirstColumn := FLayout.IndexOfVisibleColumn(LColumns[0]);

  LDataSet.DisableControls;
  try
    LBookmark := LDataSet.Bookmark;
    try
      if (Length(LRows) = 1) and (Length(LRows[0]) = 1) then
      begin
        SetLength(LValues, Length(LColumns));

        for var LIndex := 0 to High(LValues) do
          LValues[LIndex] := LRows[0][0];

        for var LRowBookmark in LBookmarks do
        if LDataSet.BookmarkValid(LRowBookmark) then
        begin
          LDataSet.Bookmark := LRowBookmark;

          WriteRow(LColumns, LValues);
        end;
      end
      else
      begin
        LDataSet.Bookmark := LBookmarks[0];

        for var LRow in LRows do
        begin
          if LDataSet.Eof then
            Break;

          WriteRow(GetRowColumns(Length(LRow)), LRow);

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

procedure TCustomDatabaseGrid.PostFooterCalculation;
begin
  if HandleAllocated then
    PostMessage(Handle, TDatabaseGridMessage.WM_CALCULATE_FOOTER, 0, 0);
end;

procedure TCustomDatabaseGrid.PressEditButton;
begin
  case GetCurrentColumn.GetEditorKind of
    ekEllipsis:
      begin
        EndEdit;
        DoEditButtonClick;
      end;
    ekMemo:
      ShowMemoPopup;
    ekDate, ekDateTime, ekTime:
      if Assigned(FEditColumn) then
        DropDown
      else
        ShowCalendarPopup;
  else
    if IsDropDownVisible then
      CloseDropDown
    else
    begin
      if not Assigned(FEditColumn) then
        ShowEditor(True);

      DropDown;
    end;
  end;
end;

procedure TCustomDatabaseGrid.PropertiesChanged(ASender: TObject);
begin
  if ASender = FColors then
    UpdateStyledColors;

  if Assigned(FTitle) and Assigned(FTitle.Images) then
    FTitle.Images.FreeNotification(Self);

  if Assigned(FFooterCalculator) and FFooterCalculator.Pending then
    PostFooterCalculation;

  UpdateLayout;
end;

procedure TCustomDatabaseGrid.RefreshData;
begin
  BeginUpdate;
  try
    if Assigned(FOnRefresh) then
      FOnRefresh(Self)
    else
    if FDataLink.Active then
      FDataLink.DataSet.Refresh;
  finally
    EndUpdate;
  end;
end;

procedure TCustomDatabaseGrid.ResizeColumn(const AColumn: TDatabaseGridColumn; const AWidth: Integer);
var
  LColumn, LNextColumn: TDatabaseGridColumn;
  LDelta: Integer;
begin
  LNextColumn := nil;

  if IsAutoFitColumn(AColumn) then
    LNextColumn := GetNextAutoFitColumn(AColumn);

  if not Assigned(LNextColumn) then
  begin
    AColumn.Width := FLayout.UnzoomWidth(AWidth);

    Exit;
  end;

  FColumns.BeginUpdate;
  try
    for var LIndex := 0 to FColumns.Count - 1 do
    begin
      LColumn := FColumns[LIndex];

      if LColumn.Visible and (coAutoFit in LColumn.Options) then
        LColumn.Width := FLayout.UnzoomWidth(FLayout.GetColumnWidth(LColumn));
    end;

    LDelta := Min(FLayout.UnzoomWidth(AWidth) - AColumn.Width, LNextColumn.Width - ScaleMetric(TDatabaseGridSize.MinColumnWidth));

    AColumn.Width := AColumn.Width + LDelta;
    LNextColumn.Width := LNextColumn.Width - LDelta;
  finally
    FColumns.EndUpdate;
  end;
end;

procedure TCustomDatabaseGrid.Resize;
begin
  inherited Resize;

  UpdateLayout;
end;

procedure TCustomDatabaseGrid.ScrollColumnIntoView(const AColumn: TDatabaseGridColumn);
var
  LLeft, LOffset: Integer;
begin
  if not FLayout.TryGetColumnLeft(AColumn, LLeft) then
    Exit;

  LOffset := LLeft - FLayout.ColumnsLeft;

  if LOffset < FLayout.HorizontalPosition then
    SetHorizontalPosition(LOffset)
  else
  if LOffset + FLayout.GetColumnWidth(AColumn) > FLayout.HorizontalPosition + FLayout.DataRect.Width then
    SetHorizontalPosition(Min(LOffset, LOffset + FLayout.GetColumnWidth(AColumn) - FLayout.DataRect.Width));
end;

procedure TCustomDatabaseGrid.ScrollCurrentRowIntoView;
var
  LRow: Integer;
begin
  if not FDataLink.Active or not HandleAllocated then
    Exit;

  LRow := GetCurrentRow;

  if LRow < FScrollHelper.TopRow then
    ScrollToRow(LRow)
  else
  if GetRowTop(LRow) + GetRowHeight(LRow) > FLayout.DataRect.Bottom then
    ScrollToRow(GetTopRowShowing(LRow))
  else
    ScrollToRow(FScrollHelper.TopRow);
end;

procedure TCustomDatabaseGrid.ScrollToRow(const ARow: Integer);
var
  LTopRow: Integer;
begin
  LTopRow := ARow;

  if (LTopRow < 0) and not FGroups.Active then
    Inc(LTopRow, FDataLink.ExtendBufferBackward(-LTopRow));

  FScrollHelper.TopRow := Max(LTopRow, 0);

  UpdateLayout;
end;

procedure TCustomDatabaseGrid.SearchPanelApplyFilter(ASender: TObject);
begin
  ApplySearchFilter;
end;

procedure TCustomDatabaseGrid.SearchPanelChanged(ASender: TObject);
begin
  if [csDestroying, csLoading] * ComponentState <> [] then
    Exit;

  FSearchPanelControls.Synchronize;

  UpdateLayout;

  if not FSearchPanelControls.Updating and (Trim(FSearchPanel.Text) <> FFilterController.Text) then
    ApplySearchFilter;
end;

procedure TCustomDatabaseGrid.SearchPanelRefresh(ASender: TObject);
begin
  RefreshData;
end;

procedure TCustomDatabaseGrid.SearchPanelSetFocus(ASender: TObject);
begin
  FSearchPanelControls.BeginSearch('');
end;

procedure TCustomDatabaseGrid.SelectCellsAt(const AX, AY: Integer);
var
  LColumn: TDatabaseGridColumn;
  LLeft, LRow: Integer;
begin
  LRow := GetRowAt(EnsureRange(AY, FLayout.DataTop, Max(FLayout.DataRect.Bottom - 1, FLayout.DataTop)));
  LColumn := FLayout.GetColumnAt(EnsureRange(AX, FLayout.DataLeft, Max(FLayout.ColumnsRight - 1, FLayout.DataLeft)), LLeft);

  if (LRow < 0) or not Assigned(LColumn) or (LRow = GetCurrentRow) and (LColumn = GetCurrentColumn) then
    Exit;

  ExtendCellRange;
  MoveToRow(LRow);
  SetCurrentColumn(LColumn);
end;

procedure TCustomDatabaseGrid.SelectCheckBoxRows(const AY: Integer);
var
  LLastRow, LRow: Integer;
begin
  if not FDataLink.Active then
    Exit;

  LRow := GetRowAt(EnsureRange(AY, FLayout.DataTop, Max(FLayout.DataRect.Bottom - 1, FLayout.DataTop)));

  if LRow < 0 then
    LRow := GetRowCount - 1;
  LLastRow := GetCurrentRow + FMouse.CheckBoxRowOffset;

  if (LRow < 0) or (LRow = LLastRow) then
    Exit;

  SelectRowRange(LLastRow, LRow, FMouse.CheckBoxSelected);

  FMouse.CheckBoxRowOffset := LRow - GetCurrentRow;
end;

procedure TCustomDatabaseGrid.SelectedRowsChanged(ASender: TObject);
begin
  if csDestroying in ComponentState then
    Exit;

  Invalidate;

  if Assigned(FOnSelectionChanged) then
    FOnSelectionChanged(Self);
end;

procedure TCustomDatabaseGrid.SelectAllCells;
var
  LDataSet: TDataSet;
begin
  LDataSet := FDataLink.DataSet;

  if not IsCellMode or FGroups.Active or not FDataLink.Active or (LDataSet.State <> dsBrowse) or LDataSet.IsEmpty or
    (FLayout.VisibleColumnCount = 0) then
    Exit;

  HideEditor;
  CollapseCellRange;

  LDataSet.Last;
  SetCurrentColumn(FLayout.VisibleColumns[FLayout.VisibleColumnCount - 1]);
  ExtendCellRange;

  LDataSet.First;
  SetCurrentColumn(FLayout.VisibleColumns[0]);
end;

procedure TCustomDatabaseGrid.SelectAllRows;
begin
  if dgoMultiSelect in FOptions then
    FSelectedRows.SelectAll;
end;

procedure TCustomDatabaseGrid.SelectRowRange(const AFirstRow, ALastRow: Integer; const ASelected: Boolean);
var
  LActiveRecord, LRecordIndex: Integer;
begin
  LActiveRecord := FDataLink.ActiveRecord;

  FSelectedRows.BeginUpdate;
  try
    for var LRow := Max(Min(AFirstRow, ALastRow), 0) to Min(Max(AFirstRow, ALastRow), GetRowCount - 1) do
    begin
      LRecordIndex := GetRowRecord(LRow);

      if LRecordIndex < 0 then
        Continue;

      FDataLink.ActiveRecord := LRecordIndex;

      FSelectedRows.Select(FDataLink.DataSet.Bookmark, ASelected);
    end;
  finally
    FDataLink.ActiveRecord := LActiveRecord;

    FSelectedRows.EndUpdate;
  end;
end;

procedure TCustomDatabaseGrid.SetColumnText(const AColumn: TDatabaseGridColumn; const AText: string);
var
  LField: TField;
  LKey: Variant;
  LText: string;
begin
  LField := AColumn.Field;

  if LField.IsBlob and not (LField.DataType in [ftMemo, ftWideMemo, ftFmtMemo]) then
    Exit;

  if AText.IsEmpty then
  begin
    ClearColumnValue(AColumn);

    Exit;
  end;

  if LField.FieldKind = fkLookup then
  begin
    LKey := LField.LookupDataSet.Lookup(LField.LookupResultField, AText, LField.LookupKeyFields);

    if not VarIsNull(LKey) then
      FDataLink.DataSet.FieldValues[LField.KeyFields] := LKey;

    Exit;
  end;

  LText := AText;

  if LField is TNumericField then
  begin
    if not FormatSettings.CurrencyString.IsEmpty then
      LText := LText.Replace(FormatSettings.CurrencyString, '');

    LText := LText.Replace(FormatSettings.ThousandSeparator, '').Replace(' ', '').Replace(#$00A0, '').Replace(#$202F, '');
  end;

  LField.Text := LText;
end;

procedure TCustomDatabaseGrid.SetBorder(const AValue: TDatabaseGridBorder);
begin
  FBorder.Assign(AValue);
end;

procedure TCustomDatabaseGrid.SetColors(const AValue: TDatabaseGridColors);
begin
  FColors.Assign(AValue);
end;

procedure TCustomDatabaseGrid.SetColumnFilter(const AValue: TDatabaseGridColumnFilter);
begin
  FColumnFilter.Assign(AValue);
end;

procedure TCustomDatabaseGrid.SetColumns(const AValue: TDatabaseGridColumns);
begin
  FColumns.Assign(AValue);
end;

procedure TCustomDatabaseGrid.SetCurrentColumn(const AValue: TDatabaseGridColumn);
begin
  if not Assigned(AValue) or not AValue.Visible or (AValue.Collection <> FColumns) then
    Exit;

  if FCurrentColumnIndex <> AValue.Index then
  begin
    FCurrentColumnIndex := AValue.Index;

    Invalidate;
  end;

  ScrollColumnIntoView(AValue);
end;

procedure TCustomDatabaseGrid.SetDataGrouping(const AValue: TDatabaseGridDataGrouping);
begin
  FDataGrouping.Assign(AValue);
end;

procedure TCustomDatabaseGrid.SetFooter(const AValue: TDatabaseGridFooter);
begin
  FFooter.Assign(AValue);
end;

procedure TCustomDatabaseGrid.SetDataSource(const AValue: TDataSource);
begin
  if FDataLink.DataSource <> AValue then
  begin
    FDataLink.DataSource := AValue;

    if Assigned(AValue) then
      AValue.FreeNotification(Self);

    Invalidate;
  end;
end;

procedure TCustomDatabaseGrid.SetEditorMode(const AValue: Boolean);
begin
  if AValue then
    ShowEditor(False)
  else
    EndEdit;
end;

procedure TCustomDatabaseGrid.SetEditorText(const AText: string; const AModified: Boolean);
begin
  FEditorTextUpdating := True;
  try
    FEditor.Text := AText;
    FEditor.Modified := AModified;
    FEditor.SelStart := Length(AText);
  finally
    FEditorTextUpdating := False;
  end;
end;

procedure TCustomDatabaseGrid.SetHorizontalPosition(const AValue: Integer);
begin
  FLayout.HorizontalPosition := AValue;

  UpdateLayout;
end;

procedure TCustomDatabaseGrid.SetHotTitleColumn(const AValue: TDatabaseGridColumn);
begin
  if FLayout.HotTitleColumn <> AValue then
  begin
    InvalidateTitle(FLayout.HotTitleColumn);

    FLayout.HotTitleColumn := AValue;

    InvalidateTitle(FLayout.HotTitleColumn);
  end;
end;

procedure TCustomDatabaseGrid.SetIndicator(const AValue: TDatabaseGridIndicator);
begin
  FIndicator.Assign(AValue);
end;

procedure TCustomDatabaseGrid.SetOption(const AOption: TDatabaseGridOption; const AEnabled: Boolean);
begin
  if AEnabled then
    SetOptions(FOptions + [AOption])
  else
    SetOptions(FOptions - [AOption]);
end;

procedure TCustomDatabaseGrid.SetOptions(const AValue: TDatabaseGridOptions);
begin
  if FOptions <> AValue then
  begin
    FOptions := AValue;
    FDataLink.ReadOnly := FReadOnly or not (dgoEditing in FOptions);

    if not (dgoMultiSelect in FOptions) then
      FSelectedRows.Clear;

    if not (dgoMiddleClickAutoscroll in FOptions) then
      StopMouseScrolling;

    if not (dgoEditing in FOptions) then
    begin
      HideEditor;
      CollapseCellRange;
    end;

    UpdateLayout;
  end;
end;

procedure TCustomDatabaseGrid.SetReadOnly(const AValue: Boolean);
begin
  if FReadOnly <> AValue then
  begin
    FReadOnly := AValue;
    FDataLink.ReadOnly := FReadOnly or not (dgoEditing in FOptions);

    if FReadOnly then
      HideEditor;

    Invalidate;
  end;
end;

procedure TCustomDatabaseGrid.SetScrollBar(const ABar, ARange, APage, APosition: Integer);
var
  LScrollInfo: TScrollInfo;
begin
  LScrollInfo.cbSize := SizeOf(TScrollInfo);
  LScrollInfo.fMask := SIF_ALL;
  LScrollInfo.nMin := 0;
  LScrollInfo.nTrackPos := 0;

  if ARange <= DATABASE_GRID_MAX_SCROLL_RANGE then
  begin
    LScrollInfo.nMax := Max(ARange - 1, 0);
    LScrollInfo.nPage := Max(APage, 0);
    LScrollInfo.nPos := APosition;
  end
  else
  begin
    LScrollInfo.nMax := DATABASE_GRID_MAX_SCROLL_RANGE;
    LScrollInfo.nPage := MulDiv(DATABASE_GRID_MAX_SCROLL_RANGE, Max(APage, 0), ARange);
    LScrollInfo.nPos := MulDiv(DATABASE_GRID_MAX_SCROLL_RANGE, APosition, ARange);
  end;

  SetScrollInfo(Handle, ABar, LScrollInfo, True);
end;

procedure TCustomDatabaseGrid.SetSearchPanel(const AValue: TDatabaseGridSearchPanel);
begin
  FSearchPanel.Assign(AValue);
end;

procedure TCustomDatabaseGrid.SetSortMarker(const AColumn: TDatabaseGridColumn; const ASortMarker: TDatabaseGridSortMarker;
  const AAppend: Boolean = False);
begin
  FColumns.BeginUpdate;
  try
    if not AAppend then
    for var LIndex := 0 to FColumns.Count - 1 do
      FColumns[LIndex].Title.SortMarker := smNone;

    AColumn.Title.SortMarker := ASortMarker;
  finally
    FColumns.EndUpdate;
  end;

  FSortingApplied := False;

  if Assigned(FOnSortMarkingChanged) then
    FOnSortMarkingChanged(Self)
  else
    ApplySorting;
end;

procedure TCustomDatabaseGrid.SetTitle(const AValue: TDatabaseGridTitle);
begin
  FTitle.Assign(AValue);
end;

procedure TCustomDatabaseGrid.SetTopRow(const AValue: Integer);
begin
  ScrollToRow(AValue - GetRowOffset);
end;

procedure TCustomDatabaseGrid.SetZoomPercentage(const AValue: Integer);
var
  LPreviousPercentage, LValue: Integer;
begin
  LValue := EnsureRange(AValue, DATABASE_GRID_ZOOM_PERCENTAGES[0], DATABASE_GRID_ZOOM_PERCENTAGES[High(DATABASE_GRID_ZOOM_PERCENTAGES)]);

  if FZoomPercentage = LValue then
    Exit;

  LPreviousPercentage := FZoomPercentage;
  FZoomPercentage := LValue;

  if csLoading in ComponentState then
    Exit;

  FLayout.HorizontalPosition := MulDiv(FLayout.HorizontalPosition, FZoomPercentage, LPreviousPercentage);

  UpdateMetrics;
  UpdateLayout;
  ScrollCurrentRowIntoView;

  if Assigned(FOnZoomChange) then
    FOnZoomChange(Self);
end;

procedure TCustomDatabaseGrid.ShowColumnFilterPopup(const AColumn: TDatabaseGridColumn);
var
  LLeft: Integer;
  LOptions: TDatabaseGridColumnFilterOptions;
  LValues: TStringList;
begin
  if Assigned(FColumnFilterPopup) then
    FColumnFilterPopup.Close;

  LValues := TStringList.Create;
  try
    LValues.CaseSensitive := False;

    LOptions := FColumnFilter.Options;

    if not (coFilterValueList in AColumn.Options) then
      Exclude(LOptions, cfoShowValueList);

    if (cfoShowValueList in LOptions) and FDataLink.Active then
      FFilterController.GetColumnValues(FDataLink.DataSet, AColumn, LValues, FColumnFilter.ValueListLimit);

    FColumnFilterPopup := TDatabaseGridColumnFilterPopup.CreatePopup(Self, AColumn, LValues, Font, LOptions);
  finally
    LValues.Free;
  end;

  if (FColumnFilterPopupWidth > 0) and (cfoShowValueList in LOptions) then
    FColumnFilterPopup.Width := FColumnFilterPopupWidth;

  FColumnFilterPopup.OnClearAllColumnFilters := ColumnFilterPopupClearAllColumnFilters;
  FColumnFilterPopup.OnClose := ColumnFilterPopupClose;
  FColumnFilterPopup.OnSort := ColumnFilterPopupSort;

  FLayout.TryGetColumnLeft(AColumn, LLeft);

  FColumnFilterPopup.Popup(ClientToScreen(Point(LLeft + FLayout.GetColumnWidth(AColumn) - FColumnFilterPopup.Width,
    FLayout.DataTop - 1)));
end;

procedure TCustomDatabaseGrid.ShowCalendarPopup;
var
  LPopup: TDatabaseGridCalendarPopup;
  LValue: TDateTime;
begin
  FPopupColumn := GetCurrentColumn;
  LValue := 0;

  if not Assigned(FEditColumn) or not FEditor.Modified or not TryStrToDateTime(FEditor.Text, LValue) then
  begin
    LValue := 0;

    if not FPopupColumn.Field.IsNull then
      LValue := FPopupColumn.Field.AsDateTime;
  end;

  LPopup := TDatabaseGridCalendarPopup.CreateCalendar(Self, Font, CurrentPPI, FPopupColumn.GetEditorKind, LValue);
  LPopup.OnAccept := CalendarPopupAccept;
  LPopup.OnClose := EditorPopupClose;
  LPopup.Popup(GetCurrentCellScreenRect);
end;

procedure TCustomDatabaseGrid.ShowExportDialog;
const
  FILTER_FORMATS: array [1..5] of TDatabaseGridExportFormat = (efXlsx, efCsv, efText, efHtml, efJson);
var
  LDialog: TSaveDialog;
  LExport: TDatabaseGridExport;
  LFormat: TDatabaseGridExportFormat;
begin
  if Assigned(FOnExport) then
  begin
    FOnExport(Self);

    Exit;
  end;

  if not FDataLink.Active then
    Exit;

  LDialog := TSaveDialog.Create(nil);
  try
    LDialog.DefaultExt := 'xlsx';
    LDialog.Filter := SDatabaseGridExportFilter;
    LDialog.Options := LDialog.Options + [ofOverwritePrompt, ofPathMustExist];

    if not LDialog.Execute then
      Exit;

    if not TDatabaseGridExport.TryGetFormat(LDialog.FileName, LFormat) then
      LFormat := FILTER_FORMATS[EnsureRange(LDialog.FilterIndex, Low(FILTER_FORMATS), High(FILTER_FORMATS))];

    LExport := TDatabaseGridExport.Create(Self);
    try
      Screen.Cursor := crHourGlass;
      try
        LExport.SaveToFile(LDialog.FileName, LFormat);
      finally
        Screen.Cursor := crDefault;
      end;
    finally
      LExport.Free;
    end;
  finally
    LDialog.Free;
  end;
end;

procedure TCustomDatabaseGrid.ShowEditor(const ASelectAll: Boolean);
var
  LColumn: TDatabaseGridColumn;
begin
  if not HandleAllocated or not CanEditCurrentCell or not IsInlineEditor(GetCurrentColumn) then
    Exit;

  LColumn := GetCurrentColumn;

  ScrollColumnIntoView(LColumn);
  ScrollCurrentRowIntoView;

  if not Assigned(FEditor) then
  begin
    FEditor := TDatabaseGridEditor.Create(Self);
    FEditor.Parent := Self;
    FEditor.OnBeginModify := EditorBeginModify;
    FEditor.OnChange := EditorChange;
    FEditor.OnExit := EditorExit;
    FEditor.OnKeyCommand := EditorKeyCommand;
  end;

  FEditColumn := LColumn;

  FEditor.Alignment := LColumn.Alignment;
  FEditor.Color := FStyledColors.DataBackground;
  FEditor.Font.Assign(Font);
  FEditor.Font.Color := FStyledColors.DataForeground;
  FEditor.MaxLength := if LColumn.Field is TStringField then LColumn.Field.Size else 0;

  SetEditorText(LColumn.Field.Text, False);

  UpdateEditorBounds;

  if FEditor.Visible and FEditor.CanFocus then
    FEditor.SetFocus;

  if ASelectAll then
    FEditor.SelectAll
  else
    FEditor.SelStart := Length(FEditor.Text);

  Invalidate;
end;

procedure TCustomDatabaseGrid.ShowIndicatorTitleMenu;
var
  LMenu: TPopupMenu;
  LMessage: TMsg;
  LPoint: TPoint;
begin
  if not (tmoTitleButton in FIndicator.TitleMenu.Options) then
    Exit;

  LMenu := FIndicator.TitleMenu.DropdownMenu;

  if not Assigned(LMenu) then
  begin
    if not Assigned(FTitleMenu) then
      FTitleMenu := TPopupMenu.Create(Self);

    BuildTitleMenu;

    if Assigned(FOnIndicatorTitleMenuPopup) then
      FOnIndicatorTitleMenuPopup(Self, FTitleMenu);

    if FTitleMenu.Items.Count = 0 then
      Exit;

{$IFDEF ALPHASKINS}
    if Assigned(FSkinData.SkinManager) then
      FSkinData.SkinManager.SkinableMenus.HookPopupMenu(FTitleMenu, FSkinData.SkinManager.IsActive);
{$ENDIF}
    LMenu := FTitleMenu;
  end;

  LPoint := ClientToScreen(Point(0, FLayout.DataTop));

  LMenu.PopupComponent := Self;
  LMenu.Popup(LPoint.X, LPoint.Y);

  if PeekMessage(LMessage, Handle, WM_LBUTTONDOWN, WM_LBUTTONDBLCLK, PM_NOREMOVE) and
    ((LMessage.message = WM_LBUTTONDOWN) or (LMessage.message = WM_LBUTTONDBLCLK)) and
    (GetAreaAt(SmallInt(LoWord(LMessage.lParam)), SmallInt(HiWord(LMessage.lParam))) = gaIndicatorTitle) then
    PeekMessage(LMessage, Handle, LMessage.message, LMessage.message, PM_REMOVE);
end;

procedure TCustomDatabaseGrid.ShowMemoPopup;
var
  LPopup: TDatabaseGridMemoPopup;
  LRect: TRect;
begin
  EndEdit;

  FPopupColumn := GetCurrentColumn;
  LRect := GetCurrentCellScreenRect;

  LPopup := TDatabaseGridMemoPopup.CreateMemo(Self, Font, CurrentPPI, FPopupColumn.Field.AsString, LRect.Width);
  LPopup.OnAccept := MemoPopupAccept;
  LPopup.OnClose := EditorPopupClose;
  LPopup.Popup(LRect);
end;

procedure TCustomDatabaseGrid.StartMouseScrolling(const AX, AY: Integer);
begin
  if Assigned(FEditColumn) then
    EndEdit;

  if Assigned(FEditColumn) then
    Exit;

  if CanFocus and not Focused then
    SetFocus;

  if not Assigned(FMouseScrollTimer) then
  begin
    FMouseScrollTimer := TTimer.Create(nil);
    FMouseScrollTimer.Enabled := False;
    FMouseScrollTimer.Interval := DATABASE_GRID_MOUSE_SCROLL_INTERVAL;
    FMouseScrollTimer.OnTimer := MouseScrollTimerTimer;
  end;

  FMouse.Scrolling := True;
  FMouse.ScrollingPoint := Point(AX, AY);
  FMouse.ScrollDelta := Point(0, 0);

  Application.CancelHint;

  InvalidateRect(Handle, GetMouseScrollIndicatorRect, False);

  Winapi.Windows.SetCursor(GetMouseScrollCursor);
end;

procedure TCustomDatabaseGrid.StopMouseScrolling;
begin
  if not FMouse.Scrolling then
    Exit;

  FMouse.Scrolling := False;
  FMouseScrollTimer.Enabled := False;

  if HandleAllocated then
  begin
    InvalidateRect(Handle, GetMouseScrollIndicatorRect, False);

    Perform(WM_SETCURSOR, Handle, MakeLParam(HTCLIENT, WM_MOUSEMOVE));
  end;
end;

procedure TCustomDatabaseGrid.ToggleCheckBox;
var
  LField: TField;
begin
  LField := GetCurrentColumn.Field;

  if not CanEditCurrentCell or not (LField is TBooleanField) or not FDataLink.Edit then
    Exit;

  LField.AsBoolean := LField.IsNull or not LField.AsBoolean;

  Invalidate;
end;

procedure TCustomDatabaseGrid.TitleClick(const AColumn: TDatabaseGridColumn; const AShift: TShiftState);
begin
  if not (toButton in AColumn.Title.Options) then
    Exit;

  if dgoSortMarking in FOptions then
    ChangeSortMarker(AColumn, ssCtrl in AShift);

  if Assigned(FOnTitleClick) then
    FOnTitleClick(Self, AColumn);
end;

procedure TCustomDatabaseGrid.TitleMenuItemClick(ASender: TObject);
begin
  case TDatabaseGridTitleMenuCommand((ASender as TMenuItem).Tag) of
    tmcSelectAll:
      FSelectedRows.SelectAll;
    tmcInvertSelection:
      FSelectedRows.Invert;
    tmcUnselectAll:
      FSelectedRows.Clear;
    tmcJumpToColumn:
      JumpToColumn;
    tmcJumpToFirstColumn:
      MoveCurrentColumn(-FColumns.Count);
    tmcJumpToLastColumn:
      MoveCurrentColumn(FColumns.Count);
    tmcExport:
      ShowExportDialog;
    tmcZoomIn:
      ZoomIn;
    tmcZoomOut:
      ZoomOut;
    tmcResetZoom:
      ZoomReset;
  end;
end;

procedure TCustomDatabaseGrid.UpdateDragScrolling(const AX, AY: Integer);
var
  LOutside: Boolean;
begin
  FMouse.DragPoint := Point(AX, AY);

  LOutside := (AY < FLayout.DataTop) or (AY >= FLayout.DataRect.Bottom);

  if LOutside and not Assigned(FDragScrollTimer) then
  begin
    FDragScrollTimer := TTimer.Create(nil);
    FDragScrollTimer.Enabled := False;
    FDragScrollTimer.Interval := DATABASE_GRID_DRAG_SCROLL_INTERVAL;
    FDragScrollTimer.OnTimer := DragScrollTimerTimer;
  end;

  if Assigned(FDragScrollTimer) then
    FDragScrollTimer.Enabled := LOutside;
end;

procedure TCustomDatabaseGrid.UpdateDataSetFeatures;
var
  LAtFirstRecord: Boolean;
  LDataSet: TDataSet;
  LFeatures: TDatabaseGridDataSetFeatures;
  LReapply: Boolean;
begin
  LDataSet := FDataLink.DataSet;

  if not Assigned(LDataSet) then
    Exit;

  if LDataSet.Active then
  begin
    LReapply := FFilterController.NeedsReapply(LDataSet);

    if FSortingApplied then
    begin
      LAtFirstRecord := LDataSet.Bof;

      if not ApplyDataSetSorting(False) then
        LReapply := True
      else
      if LAtFirstRecord and not LDataSet.Bof then
        LDataSet.First;
    end;

    if LReapply and HandleAllocated then
      PostMessage(Handle, TDatabaseGridMessage.WM_APPLY_DATASET_FEATURES, 0, 0);
  end
  else
  begin
    LFeatures := FindDatabaseGridDataSetFeatures(LDataSet);

    if Assigned(LFeatures) then
      LFeatures.ResetSorting(LDataSet);
  end;
end;

procedure TCustomDatabaseGrid.UpdateDropIndex(const AY: Integer);
var
  LDropIndex, LRow: Integer;
begin
  if AY < FLayout.DataTop then
    ScrollToRow(FScrollHelper.TopRow - 1)
  else
  if AY >= FLayout.DataRect.Bottom then
    ScrollToRow(FScrollHelper.TopRow + 1);

  LRow := FScrollHelper.TopRow + (EnsureRange(AY, FLayout.DataTop, Max(FLayout.DataRect.Bottom - 1, FLayout.DataTop)) -
    FLayout.DataTop + FLayout.RowHeight div 2) div FLayout.RowHeight;
  LDropIndex := GetRowOffset + EnsureRange(LRow, 0, GetRowCount);

  if (LDropIndex = FMouse.MoveFromIndex) or (LDropIndex = FMouse.MoveFromIndex + 1) then
    LDropIndex := -1
  else
    Winapi.Windows.SetCursor(Screen.Cursors[crDrag]);

  if LDropIndex <> FMouse.DropIndex then
  begin
    FMouse.DropIndex := LDropIndex;

    Invalidate;
  end;
end;

procedure TCustomDatabaseGrid.UpdateEditorBounds;
var
  LGlyph: TDatabaseGridGlyph;
  LLeft, LPadding, LRow, LTop: Integer;
  LRect: TRect;
  LVisible: Boolean;
begin
  if not Assigned(FEditColumn) then
    Exit;

  LRow := GetCurrentRow - FScrollHelper.TopRow;
  LVisible := HandleAllocated and FLayout.TryGetColumnLeft(FEditColumn, LLeft) and (LRow >= 0) and
    (LRow < FLayout.VisibleRowCount);

  if LVisible then
  begin
    LRect.Left := Max(LLeft, FLayout.DataLeft);
    LRect.Top := GetRowTop(GetCurrentRow);
    LRect.Right := Min(LLeft + FLayout.GetColumnWidth(FEditColumn) - 1, ClientWidth);
    LRect.Bottom := LRect.Top + FLayout.RowHeight - 1;

    if HasEditButton(FEditColumn, LGlyph) then
      Dec(LRect.Right, FLayout.GetEditButtonWidth);

    LVisible := (LRect.Right > LRect.Left) and (LRect.Bottom <= FLayout.DataRect.Bottom);
  end;

  if not LVisible then
  begin
    if FEditor.Focused and CanFocus then
      SetFocus;

    FEditor.Visible := False;

    Exit;
  end;

  if FEditor.Font.Height <> FLayout.FontHeight then
    FEditor.Font.Height := FLayout.FontHeight;

  LTop := LRect.Top + Max((LRect.Height - FLayout.TextHeight) div 2, 0);
  LPadding := FLayout.ScaleMetric(TDatabaseGridSize.CellPadding);

  FEditor.SetBounds(LRect.Left, LTop, LRect.Width, Min(FLayout.TextHeight + 2, LRect.Bottom - LTop));
  FEditor.Visible := True;
  FEditor.SetMargins(LPadding, LPadding);
end;

procedure TCustomDatabaseGrid.UpdateGroups;
var
  LDescending: TArray<Boolean>;
  LField: TField;
  LFields: TArray<TField>;
  LWasActive: Boolean;
begin
  if [csDestroying, csLoading] * ComponentState <> [] then
    Exit;

  LWasActive := FGroups.Active;
  LDescending := nil;
  LFields := nil;

  if FDataGrouping.Active and FDataLink.Active then
    for var LIndex := 0 to FDataGrouping.Levels.Count - 1 do
    begin
      LField := FDataLink.DataSet.FindField(FDataGrouping.Levels[LIndex].FieldName);

      if Assigned(LField) then
      begin
        LFields := LFields + [LField];
        LDescending := LDescending + [FDataGrouping.Levels[LIndex].SortOrder = soDescending];
      end;
    end;

  if Length(LFields) > 0 then
  begin
    FDataLink.BufferAllRows;
    FGroups.Build(LFields, LDescending, FDataGrouping.DefaultExpanded);
  end
  else
    FGroups.Clear;

  if FGroups.Active <> LWasActive then
    FScrollHelper.TopRow := 0;
end;

procedure TCustomDatabaseGrid.UpdateLayout;
var
  LClientRect: TRect;
begin
  if csDestroying in ComponentState then
    Exit;

  FLayout.UpdateColumns(FColumns);

  if not HandleAllocated or FLayoutUpdating or (FPaintLock > 0) then
    Exit;

  FLayoutUpdating := True;
  try
    for var LPass := 1 to 3 do
    begin
      LClientRect := ClientRect;

      CalculateLayout;
      BufferVisibleRows;

      FScrollHelper.TopRow := EnsureRange(FScrollHelper.TopRow, 0, GetMaxTopRow);
      FLayout.HorizontalPosition := EnsureRange(FLayout.HorizontalPosition, 0,
        Max(FLayout.ColumnsWidth - FLayout.DataRect.Width, 0));

      SetScrollBar(SB_VERT, GetTotalRowCount, if FGroups.Active then GetRowCount - GetMaxTopRow else FLayout.VisibleRowCount,
        GetRowOffset + FScrollHelper.TopRow);
      SetScrollBar(SB_HORZ, FLayout.ColumnsWidth, FLayout.DataRect.Width, FLayout.HorizontalPosition);

      if ClientRect = LClientRect then
        Break;
    end;
  finally
    FLayoutUpdating := False;
  end;

  if not FScrollHelper.TrimPending and not FGroups.Active and
    FDataLink.CanTrimBuffer(FScrollHelper.TopRow, FScrollHelper.TopRow + FLayout.VisibleRowCount + 1) then
  begin
    FScrollHelper.TrimPending := True;

    PostMessage(Handle, TDatabaseGridMessage.WM_TRIM_BUFFER, 0, 0);
  end;

  Invalidate;
  UpdateEditorBounds;

  if (GetTopRow <> FScrollHelper.NotifiedTopRow) or (FLayout.HorizontalPosition <> FScrollHelper.NotifiedHorizontalPosition) then
  begin
    FScrollHelper.NotifiedTopRow := GetTopRow;
    FScrollHelper.NotifiedHorizontalPosition := FLayout.HorizontalPosition;

    if Assigned(FOnScroll) then
      FOnScroll(Self);
  end;
end;

procedure TCustomDatabaseGrid.UpdateMetrics;
begin
  FLayout.UpdateMetrics(Font, CurrentPPI, FZoomPercentage);
end;

procedure TCustomDatabaseGrid.UpdateMouseScrolling(const AX, AY: Integer);
var
  LHalfSize: Integer;

  function GetDelta(const ADistance: Integer): Integer;
  begin
    if Abs(ADistance) <= LHalfSize then
      Exit(0);

    Result := Sign(ADistance) * (1 + (Abs(ADistance) - LHalfSize) div FLayout.RowHeight);
  end;

begin
  LHalfSize := FLayout.ScaleMetric(TDatabaseGridSize.MouseScrollIndicator) div 2;

  FMouse.ScrollDelta := Point(GetDelta(AX - FMouse.ScrollingPoint.X), GetDelta(AY - FMouse.ScrollingPoint.Y));
  FMouseScrollTimer.Enabled := ClientRect.Contains(Point(AX, AY)) and (FMouse.ScrollDelta <> Point(0, 0));
end;

procedure TCustomDatabaseGrid.UpdateSortMarkedColumns;
var
  LColumn: TDatabaseGridColumn;
begin
  for var LIndex := FSortMarkedColumns.Count - 1 downto 0 do
  begin
    LColumn := FSortMarkedColumns[LIndex];

    if not FColumns.Contains(LColumn) or (LColumn.Title.SortMarker = smNone) then
      FSortMarkedColumns.Delete(LIndex);
  end;

  for var LIndex := 0 to FColumns.Count - 1 do
  begin
    LColumn := FColumns[LIndex];

    if (LColumn.Title.SortMarker <> smNone) and not FSortMarkedColumns.Contains(LColumn) then
      FSortMarkedColumns.Add(LColumn);
  end;
end;

procedure TCustomDatabaseGrid.UpdateStyledColors;
begin
{$IFDEF ALPHASKINS}
  FStyledColors.ResolveSkin(FColors, FSkinData.SkinManager);
{$ELSE}
  FStyledColors.ResolveStyle(FColors);
{$ENDIF}
end;

procedure TCustomDatabaseGrid.WMApplyDataSetFeatures(var AMessage: TMessage);
begin
  if (csDestroying in ComponentState) or not FDataLink.Active or (FDataLink.DataSet.State <> dsBrowse) then
    Exit;

  if FFilterController.NeedsReapply(FDataLink.DataSet) then
    ApplyFilters;

  if FSortingApplied then
    ApplyDataSetSorting(True);
end;

procedure TCustomDatabaseGrid.WMCalculateFooter(var AMessage: TMessage);
begin
  if (csDestroying in ComponentState) or not FFooter.Visible or not FFooterCalculator.Pending then
    Exit;

  FFooterCalculator.Calculate;

  Invalidate;
end;

procedure TCustomDatabaseGrid.WMCommand(var AMessage: TWMCommand);
begin
  inherited;

  if csDestroying in ComponentState then
    Exit;

  if FSearchPanelControls.HandleFocusNotification(AMessage.Ctl, AMessage.NotifyCode) and HandleAllocated then
    InvalidateRect(Handle, Rect(0, 0, ClientWidth, FLayout.TitleTop), False);
end;

procedure TCustomDatabaseGrid.WMEraseBkgnd(var AMessage: TWMEraseBkgnd);
begin
  AMessage.Result := 1;
end;

procedure TCustomDatabaseGrid.WMFocus(var AMessage: TMessage);
begin
  if CanFocus then
    SetFocus;
end;

procedure TCustomDatabaseGrid.WMGetDlgCode(var AMessage: TWMGetDlgCode);
begin
  inherited;

  AMessage.Result := AMessage.Result or DLGC_WANTARROWS;

  if IsCellMode and CanEdit then
    AMessage.Result := AMessage.Result or DLGC_WANTTAB;
end;

procedure TCustomDatabaseGrid.WMHScroll(var AMessage: TWMScroll);
var
  LStep: Integer;
begin
  AMessage.Result := 0;

  if Assigned(FEditColumn) then
    EndEdit;

  LStep := FLayout.ScaleMetric(TDatabaseGridSize.HorizontalScrollStep);

  case AMessage.ScrollCode of
    SB_LEFT:
      SetHorizontalPosition(0);
    SB_RIGHT:
      SetHorizontalPosition(FLayout.ColumnsWidth);
    SB_LINELEFT:
      SetHorizontalPosition(FLayout.HorizontalPosition - LStep);
    SB_LINERIGHT:
      SetHorizontalPosition(FLayout.HorizontalPosition + LStep);
    SB_PAGELEFT:
      SetHorizontalPosition(FLayout.HorizontalPosition - FLayout.DataRect.Width);
    SB_PAGERIGHT:
      SetHorizontalPosition(FLayout.HorizontalPosition + FLayout.DataRect.Width);
    SB_THUMBPOSITION, SB_THUMBTRACK:
      SetHorizontalPosition(GetThumbPosition(FLayout.ColumnsWidth, AMessage.Pos));
  end;
end;

procedure TCustomDatabaseGrid.WMKillFocus(var AMessage: TWMKillFocus);
begin
  inherited;

  StopMouseScrolling;
  Invalidate;
end;

procedure TCustomDatabaseGrid.WMLButtonDblClk(var AMessage: TWMLButtonDblClk);
var
  LNode: TDatabaseGridGroupNode;
begin
  LNode := nil;

  if not (csDesigning in ComponentState) and (GetAreaAt(AMessage.XPos, AMessage.YPos) in [gaIndicator, gaData]) then
    LNode := FGroups.GetRowNode(GetRowAt(AMessage.YPos));

  if Assigned(LNode) then
    Exit;

  inherited;

  if IsCellMode and not Assigned(OnDblClick) and (GetAreaAt(AMessage.XPos, AMessage.YPos) = gaData) and not Assigned(FEditColumn) then
    EditCurrentCell(True);
end;

procedure TCustomDatabaseGrid.WMNCCalcSize(var AMessage: TWMNCCalcSize);
begin
  inherited;

  if (FBorder.Style <> bsSingle) or (FBorder.ColoredEdges = []) or IsCustomStyleActive then
    Exit;

  if ebLeft in FBorder.ColoredEdges then
    Dec(AMessage.CalcSize_Params.rgrc[0].Left);

  if ebTop in FBorder.ColoredEdges then
    Dec(AMessage.CalcSize_Params.rgrc[0].Top);

  if ebRight in FBorder.ColoredEdges then
    Inc(AMessage.CalcSize_Params.rgrc[0].Right);

  if ebBottom in FBorder.ColoredEdges then
    Inc(AMessage.CalcSize_Params.rgrc[0].Bottom);
end;

procedure TCustomDatabaseGrid.WMNCPaint(var AMessage: TWMNCPaint);
begin
  inherited;

  PaintBorder;
end;

procedure TCustomDatabaseGrid.WMRedrawSearchPanel(var AMessage: TMessage);
begin
  FSearchPanelControls.Redraw;
end;

procedure TCustomDatabaseGrid.WMSetCursor(var AMessage: TWMSetCursor);
var
  LPoint: TPoint;
begin
  if FMouse.Scrolling and (AMessage.HitTest = HTCLIENT) then
  begin
    Winapi.Windows.SetCursor(GetMouseScrollCursor);

    AMessage.Result := 1;

    Exit;
  end;

  if (AMessage.HitTest = HTCLIENT) and (dgoColumnResize in FOptions) and not (csDesigning in ComponentState) then
  begin
    LPoint := ScreenToClient(Mouse.CursorPos);

    if FMouse.Resizing or Assigned(GetResizeColumnAt(LPoint.X, LPoint.Y)) then
    begin
      Winapi.Windows.SetCursor(Screen.Cursors[crHSplit]);

      AMessage.Result := 1;

      Exit;
    end;
  end;

  inherited;
end;

procedure TCustomDatabaseGrid.WMSetFocus(var AMessage: TWMSetFocus);
begin
  inherited;

  Invalidate;
end;

procedure TCustomDatabaseGrid.WMTrimBuffer(var AMessage: TMessage);
begin
  FScrollHelper.TrimPending := False;

  if FGroups.Active then
    Exit;

  Inc(FScrollHelper.TopRow, FDataLink.TrimBuffer(FScrollHelper.TopRow, FScrollHelper.TopRow + FLayout.VisibleRowCount + 1));

  UpdateLayout;
end;

procedure TCustomDatabaseGrid.WMVScroll(var AMessage: TWMScroll);
begin
  AMessage.Result := 0;

  if Assigned(FEditColumn) then
    EndEdit;

  case AMessage.ScrollCode of
    SB_TOP:
      ScrollToRow(-MaxInt);
    SB_BOTTOM:
      ScrollToRow(if FGroups.Active then GetMaxTopRow else GetTotalRowCount - GetRowOffset - FLayout.VisibleRowCount);
    SB_LINEUP:
      ScrollToRow(FScrollHelper.TopRow - 1);
    SB_LINEDOWN:
      ScrollToRow(FScrollHelper.TopRow + 1);
    SB_PAGEUP:
      ScrollToRow(FScrollHelper.TopRow - FLayout.VisibleRowCount);
    SB_PAGEDOWN:
      ScrollToRow(FScrollHelper.TopRow + FLayout.VisibleRowCount);
    SB_THUMBPOSITION, SB_THUMBTRACK:
      ScrollToRow(GetThumbPosition(GetTotalRowCount, AMessage.Pos) - GetRowOffset);
  end;
end;

procedure TCustomDatabaseGrid.WndProc(var AMessage: TMessage);
{$IFDEF ALPHASKINS}
var
  LPaintStruct: TPaintStruct;
{$ENDIF}
begin
  if (csDesigning in ComponentState) and HandleDesignMouseMessage(AMessage) then
    Exit;

{$IFDEF ALPHASKINS}
  if AMessage.Msg = SM_ALPHACMD then
  case AMessage.WParamHi of
    AC_CTRLHANDLED:
      begin
        AMessage.Result := 1;
        Exit;
      end;
    AC_SETNEWSKIN:
      begin
        if ACUInt(AMessage.LParam) = ACUInt(SkinData.SkinManager) then
          CommonMessage(AMessage, FSkinData);

        AlphaBroadCast(Self, AMessage);
        Exit;
      end;
    AC_REMOVESKIN:
      begin
        if ACUInt(AMessage.LParam) = ACUInt(SkinData.SkinManager) then
        begin
          if Assigned(FScrollHelper.Wnd) then
          begin
            FreeAndNil(FScrollHelper.Wnd);
            RecreateWnd;
          end;

          UpdateStyledColors;
          Invalidate;
        end;

        AlphaBroadCast(Self, AMessage);
        UpdateLayout;
        Exit;
      end;
    AC_REFRESH:
      begin
        if RefreshNeeded(SkinData, AMessage) then
        begin
          RefreshEditScrolls(SkinData, FScrollHelper.Wnd);
          CommonMessage(AMessage, FSkinData);
          UpdateStyledColors;

          if HandleAllocated and Visible then
            RedrawWindow(Handle, nil, 0, RDWA_REPAINT);
        end;

        AlphaBroadCast(Self, AMessage);
        UpdateLayout;
        Exit;
      end;
    AC_GETBG:
      begin
        with PacBGInfo(AMessage.LParam)^ do
        begin
          Bmp := nil;
          BgType := btFill;
          Color := if FSearchPanelControls.IsHighlighted then FStyledColors.SearchPanelBackgroundFocused
            else FStyledColors.SearchPanelBackground;
          Offset := Point(0, 0);

          if PleaseDraw then
            FillDC(DrawDC, R, Color);
        end;

        Exit;
      end;
    AC_GETDEFSECTION:
      begin
        AMessage.Result := 1;
        Exit;
      end;
    AC_GETDEFINDEX:
      begin
        if Assigned(FSkinData.SkinManager) then
          AMessage.Result := FSkinData.SkinManager.SkinCommonInfo.Sections[ssEdit] + 1;

        Exit;
      end;
    AC_SETGLASSMODE:
      begin
        CommonMessage(AMessage, FSkinData);
        Exit;
      end;
  end;

  if not ControlIsReady(Self) or not Assigned(FSkinData) or not FSkinData.Skinned then
    inherited
  else
  begin
    case AMessage.Msg of
      WM_ERASEBKGND:
        if (SkinData.SkinIndex >= 0) and InUpdating(FSkinData) then
          Exit;
      WM_PAINT:
        begin
          if InUpdating(FSkinData) then
          begin
            BeginPaint(Handle, LPaintStruct);
            EndPaint(Handle, LPaintStruct);
          end
          else
          begin
            inherited;

            SetParentUpdated(Self);
          end;

          Exit;
        end;
    end;

    if CommonWndProc(AMessage, FSkinData) then
      Exit;

    inherited;

    case AMessage.Msg of
      CM_SHOWINGCHANGED:
        begin
          RefreshEditScrolls(SkinData, FScrollHelper.Wnd);

          if Assigned(FScrollHelper.Wnd) then
            SetWindowPos(Handle, 0, 0, 0, 0, 0, SWP_FRAMECHANGED or SWP_NOMOVE or SWP_NOSIZE or SWP_NOZORDER or SWP_NOACTIVATE);
        end;
      CM_VISIBLECHANGED, CM_ENABLEDCHANGED, WM_SETFONT:
        FSkinData.Invalidate;
    end;
  end;
{$ELSE}
  inherited;
{$ENDIF}
end;

procedure TCustomDatabaseGrid.WriteEditorText;
begin
  if FEditColumn.GetEditorKind = ekLookup then
    WriteLookupText(FEditor.Text)
  else
    FEditColumn.Field.Text := FEditor.Text;

  FEditor.Modified := False;
end;

procedure TCustomDatabaseGrid.WriteLookupKey(const AKey: Variant);
begin
  FDataLink.DataSet.FieldValues[FEditColumn.Field.KeyFields] := AKey;
end;

procedure TCustomDatabaseGrid.WriteLookupText(const AText: string);
var
  LFound: Integer;
  LItems: TStrings;
  LText: string;
begin
  if AText.IsEmpty then
  begin
    WriteLookupKey(Null);

    Exit;
  end;

  LoadDropDownItems(FEditColumn);

  LItems := FDropDownList.Items;
  LFound := -1;

  for var LIndex := 0 to LItems.Count - 1 do
  if SameText(LItems[LIndex], AText) then
  begin
    WriteLookupKey(FLookupKeys[LIndex]);

    Exit;
  end;

  LText := AnsiUpperCase(AText);

  for var LIndex := 0 to LItems.Count - 1 do
  if AnsiUpperCase(LItems[LIndex]).Contains(LText) then
  begin
    if LFound >= 0 then
    begin
      LFound := -1;

      Break;
    end;

    LFound := LIndex;
  end;

  if LFound < 0 then
    raise EDatabaseError.CreateFmt(SDatabaseGridValueNotInList, [AText, FEditColumn.Title.DisplayCaption]);

  WriteLookupKey(FLookupKeys[LFound]);
end;

procedure TCustomDatabaseGrid.ZoomIn;
begin
  for var LIndex := 0 to High(DATABASE_GRID_ZOOM_PERCENTAGES) do
  if DATABASE_GRID_ZOOM_PERCENTAGES[LIndex] > FZoomPercentage then
  begin
    SetZoomPercentage(DATABASE_GRID_ZOOM_PERCENTAGES[LIndex]);

    Exit;
  end;
end;

procedure TCustomDatabaseGrid.ZoomOut;
begin
  for var LIndex := High(DATABASE_GRID_ZOOM_PERCENTAGES) downto 0 do
  if DATABASE_GRID_ZOOM_PERCENTAGES[LIndex] < FZoomPercentage then
  begin
    SetZoomPercentage(DATABASE_GRID_ZOOM_PERCENTAGES[LIndex]);

    Exit;
  end;
end;

procedure TCustomDatabaseGrid.ZoomReset;
begin
  SetZoomPercentage(TDatabaseGridDefault.ZoomPercentage);
end;

end.
