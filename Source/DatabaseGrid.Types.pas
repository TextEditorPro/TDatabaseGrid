unit DatabaseGrid.Types;

interface

uses
  System.Classes, System.UITypes;

type
  TDatabaseGridArea = (gaNone, gaSearchPanel, gaIndicatorTitle, gaTitle, gaIndicator, gaData, gaFooter);

  TDatabaseGridArrowDirection = (adUp, adDown, adRight);

  TDatabaseGridDrawCellParams = record
    Alignment: TAlignment;
    Background: TColor;
    DefaultDrawing: Boolean;
    FontColor: TColor;
    FontStyle: TFontStyles;
    ImageIndex: Integer;
    Text: string;
  end;

  TDatabaseGridDrawGroupRowParams = record
    Background: TColor;
    DefaultDrawing: Boolean;
    FontColor: TColor;
    FontStyle: TFontStyles;
    ImageIndex: Integer;
    Text: string;
  end;

  TDatabaseGridDrawCellState = (dcActiveRow, dcCurrentCell, dcFocused, dcHighlighted, dcSelected);
  TDatabaseGridDrawCellStates = set of TDatabaseGridDrawCellState;

  TDatabaseGridColumnFilterOperator = (foNone, foValues, foEquals, foNotEquals, foContains, foNotContains, foBeginsWith,
    foEndsWith, foGreater, foGreaterOrEqual, foLess, foLessOrEqual, foBetween, foEmpty, foNotEmpty);

  TDatabaseGridColumnOption = (coAutoFit, coFilterValueList, coReadOnly, coShowImageAndText);
  TDatabaseGridColumnOptions = set of TDatabaseGridColumnOption;

  TDatabaseGridColumnFilterOption = (cfoShowFilterIcon, cfoDropDownShadow, cfoDropDownSizeable, cfoShowValueList);
  TDatabaseGridColumnFilterOptions = set of TDatabaseGridColumnFilterOption;

  TDatabaseGridEditorKind = (ekAuto, ekCheckBox, ekDate, ekDateTime, ekEllipsis, ekLookup, ekMemo, ekPickList, ekText, ekTime);

  TDatabaseGridFooterValueType = (fvNone, fvCount, fvSum, fvAverage);

  TDatabaseGridGlyph =(glClear, glDropDown, glEditRow, glEllipsis, glFilter, glGroupCollapsed, glGroupExpanded, glInsertRow, glMouseScroll,
    glRefresh, glSortAscending, glSortDescending);

  TDatabaseGridIndicatorOption = (ioShowRowIndicator, ioShowCheckBox);
  TDatabaseGridIndicatorOptions = set of TDatabaseGridIndicatorOption;

  TDatabaseGridOption = (dgoAlwaysShowSelection, dgoAutoFitColumns, dgoColumnResize, dgoEditing, dgoEnterAsTab, dgoExtendVerticalLines,
    dgoFadeExtendedLines, dgoMiddleClickAutoscroll, dgoMultiSelect, dgoShowHints, dgoShowMemoText, dgoSortMarking, dgoTextOverflow);
  TDatabaseGridOptions = set of TDatabaseGridOption;

  TDatabaseGridSearchPanelOption = (spoClearResetsItems, spoFilterOnTyping, spoHighlightFiltering, spoHighlightMatches, spoHighlightOnFocus,
    spoShowRefreshButton);
  TDatabaseGridSearchPanelOptions = set of TDatabaseGridSearchPanelOption;

  TDatabaseGridSortMarker = (smNone, smAscending, smDescending);

  TDatabaseGridSortOrder = (soAscending, soDescending);

  TDatabaseGridTitleMenuCommand = (tmcSelectAll, tmcInvertSelection, tmcUnselectAll, tmcJumpToColumn, tmcJumpToFirstColumn,
    tmcJumpToLastColumn, tmcExport, tmcZoomIn, tmcZoomOut, tmcResetZoom);
  TDatabaseGridTitleMenuCommands = set of TDatabaseGridTitleMenuCommand;

  TDatabaseGridTitleMenuOption = (tmoShowDropDownSign, tmoTitleButton);
  TDatabaseGridTitleMenuOptions = set of TDatabaseGridTitleMenuOption;

  TDatabaseGridTitleOption = (toButton, toShowImageAndText, toWordWrap);
  TDatabaseGridTitleOptions = set of TDatabaseGridTitleOption;

implementation

end.
