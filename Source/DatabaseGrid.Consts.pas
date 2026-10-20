unit DatabaseGrid.Consts;

interface

uses
  Winapi.Messages, System.UITypes, DatabaseGrid.Types;

const
  DATABASE_GRID_BUFFER_GROW_ROW_COUNT = 256;
  DATABASE_GRID_DRAG_SCROLL_INTERVAL = 50;
  DATABASE_GRID_FILTER_POPUP_MAX_ROW_COUNT = 20;
  DATABASE_GRID_MAX_BUFFERED_ROW_COUNT = 512;
  DATABASE_GRID_MAX_BUFFER_GROW_ROW_COUNT = 1 shl 20;
  DATABASE_GRID_MAX_BUFFER_MOVE_COUNT = 1 shl 26;
  DATABASE_GRID_MAX_SCROLL_RANGE = High(Smallint);
  DATABASE_GRID_MOUSE_SCROLL_INTERVAL = 100;
  DATABASE_GRID_SORT_NUMBER_FONT_SIZE = 7;
  DATABASE_GRID_ZOOM_PERCENTAGES: array [0..13] of Integer = (50, 67, 75, 80, 90, 100, 110, 125, 150, 175, 200, 250, 300, 400);

type
  TCharacters = record
  const
    Space = #32;
    CtrlBackspace = #127;
  end;

  TControlCharacters = record
  const
    Backspace = #8;
    Bell = #7;
    CarriageReturn = #13;
    EndOfText = #3;
    Escape = #27;
    FormFeed = #12;
    Linefeed = #10;
    Null = #0;
    ShiftOut = #14;
    StartOfHeading = #1;
    Tab = #9;
    UnitSeparator = #31;
    VerticalTab = #11;
  end;

  TDatabaseGridButton = record
  const
    GlyphPercent = 75;
    HotAlpha = 24;
    PressedAlpha = 48;
  end;

  TDatabaseGridCaption = record
  const
    PartSeparator = '|';
    PartTextSeparator = ' - ';
  end;

  TDatabaseGridColor = record
  const
    CurrentRowBackground = TColor($00FAF0E6);
    DesignHandle = TColor($00E8AE78);
    DesignHandleBorder = TColor($00B56B2D);
    GroupRowBackground = TColor($00FCF7F2);
    GroupRowLine = TColor($00DDD4CB);
    ReadOnlyBackground = TColor($00F4F4F4);
    SearchMatchBackground = TColor($0080F0FF);
    SearchPanelBackgroundFocused = TColor($00FFE8CA);
    SearchPanelBorder = TColor($00D5D5D5);
    SearchPanelClearGlyph = TColor($002049DE);
    SearchPanelFilterBackground = TColor($00C8F8FF);
    SelectionBackground = TColor($00FFE8CC);
    SelectionBackgroundUnfocused = TColor($00E5E5E5);
    TitleBackgroundPressed = TColor($00DADADA);
    TitleBackgroundSorted = TColor($00F4ECE3);
  end;

  TDatabaseGridDefault = record
  const
    AutoSizeRowCount = 100;
    ColumnFilterOptions = [cfoShowFilterIcon, cfoDropDownShadow, cfoDropDownSizeable, cfoShowValueList];
    ColumnOptions = [coAutoFit, coFilterValueList];
    ColumnWidth = 100;
    DropDownRowCount = 12;
    Height = 120;
    IndicatorOptions = [ioShowRowIndicator];
    Options = [dgoAlwaysShowSelection, dgoSortMarking, dgoShowHints, dgoColumnResize];
    SearchPanelFilterDelay = 300;
    SearchPanelItemWidth = 100;
    SearchPanelOptions = [spoShowRefreshButton];
    TitleMaxLineCount = 3;
    TitleMenuHiddenCommands = [tmcExport];
    TitleMenuOptions = [tmoShowDropDownSign, tmoTitleButton];
    TitleOptions = [toButton];
    ValueListLimit = 500;
    Width = 320;
    ZoomPercentage = 100;
  end;

  TDatabaseGridMessage = record
  const
    WM_ACCEPT = WM_USER + 103;
    WM_APPLY_DATASET_FEATURES = WM_USER + 105;
    WM_CALCULATE_FOOTER = WM_USER + 102;
    WM_FOCUS = WM_USER + 101;
    WM_REDRAW_SEARCH_PANEL = WM_USER + 104;
    WM_TRIM_BUFFER = WM_USER + 100;
  end;

  TDatabaseGridSize = record
  const
    Arrow = 4;
    CellPadding = 3;
    CheckBox = 13;
    ColumnResizeMargin = 3;
    DesignHandle = 7;
    DesignLink = 28;
    DesignLinkImage = 24;
    DesignLinkMargin = 4;
    EditButtonWidth = 17;
    FilterButtonPadding = 2;
    FilterButtonWidth = 18;
    FilterIconPadding = 0;
    FilterPopupHeight = 360;
    FilterPopupSizingMargin = 5;
    FilterPopupWidth = 240;
    GroupLevelWidth = 16;
    GroupRowExtraHeight = 2;
    HorizontalScrollStep = 20;
    ImageTextSpacing = 6;
    MaxAutoColumnWidth = 300;
    MenuSeparatorHeight = 5;
    MinColumnWidth = 8;
    MouseScrollIndicator = 28;
    RowIndicatorWidth = 12;
    RowPadding = 2;
    SearchPanelControlPadding = 4;
    SearchPanelPadding = 3;
    SearchPanelSpacing = 4;
    SortMarkerWidth = 14;
    TitlePadding = 3;
  end;

implementation

end.
