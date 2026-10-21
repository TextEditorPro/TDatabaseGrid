# TDatabaseGrid

A data-aware grid control for Delphi VCL.

The development environment is RAD Studio 13+, older Delphi versions are not supported.

![TDatabaseGrid showing a screenshot](https://github.com/TextEditorPro/TXMLGridView/blob/main/Assetts/screenshot.png)

## Features

- Border
  - Colored edges
- Cell editing
  - Cell mode with block selection, cut, copy, paste and delete
  - Editors: check box, date, date and time, time, ellipsis button, lookup, memo, pick list and text
  - Enter as Tab
  - Read-only columns
- Check box row selection
  - Multi-select with Ctrl and Shift
  - Dragging scrolls and selects
- Clipboard copy (TSV, HTML and XML Spreadsheet)
- Colors
  - VCL style support
  - AlphaSkins support
- Column auto-fit
- Column filters
  - Value list
  - Equals, contains, begins with, ends with, greater, less, between, empty and their opposites
- Column images and image values
- Column resize
- Data grouping
  - Multiple levels
  - Group row images and custom drawing
- Design-time column selection
- Draw events for cells, footer cells and group rows
- Export (TXT, CSV, HTML, JSON and XLSX)
- Footer
  - Count, sum and average values
- Hints for cut cell text
- Indicator
  - Row indicator and check boxes
  - Title menu: export, jump to column, selection and zoom
- Jump to column
- Memo text
- Middle-click autoscroll
- Record moving by dragging the indicator
- Scrolling without moving the current record
- Search panel
  - Combo box items with default item
  - Filter on typing
  - Highlight matches
  - Highlight on focus
  - Filter indication
- Sort marking
  - Multiple columns
- Text overflow
- Titles
  - Multi-level titles (`|` in the caption)
  - Sub captions
  - Title buttons and images
  - Word wrap
- Vertical lines
  - Extended and faded
- Zoom

## Supports

- AlphaSkins (native) - https://www.alphaskins.com/
- Devart Data Access Components (IBDAC, UniDAC, ...) - https://www.devart.com/dac.html

## Defines

- [DatabaseGrid.Defines.inc](Source/DatabaseGrid.Defines.inc)
  - `ALPHASKINS` - native AlphaSkins support
  - `DATABASE_GRID_VCL_STYLES` - the colors follow the active VCL style and the scroll bars are styled

## Dataset features

The grid sorts a dataset through a dataset features class. Filters, column filter value lists and footer values work without
one, but a features class can do them on the server instead. Add the unit of your dataset to a uses clause of the project:

- `DatabaseGrid.DataSetFeatures.ClientDataSet` - TClientDataSet
- `DatabaseGrid.DataSetFeatures.DAC` - Devart DAC datasets: sorting, column filter value lists and footer values on the server
- `DatabaseGrid.DataSetFeatures.IBDAC` - IBDAC datasets (Firebird, InterBase): as DAC, plus search and column filters on the
  server

A DAC dataset that has not fetched all of its rows is sorted and filtered on the server: the grid adds an ORDER BY and a WHERE
to the SQL and reopens the query, which fetches only the first rows. A dataset that has fetched all of its rows is sorted
and filtered in memory. Some queries are always sorted or filtered in memory:

- Sorting: queries with a row limit (FIRST, SKIP, ROWS, OFFSET, FETCH), datasets with pending cached updates, and sorting by
  calculated, lookup or BLOB fields
- Filtering: the above, plus unions, common table expressions and derived tables. Columns that are not plain table columns
  (expressions, lookup and calculated fields) are filtered in memory.

While a dataset is sorted or filtered on the server, its SQL contains the ORDER BY and the WHERE of the grid. When the
application assigns new SQL, the grid applies its sorting and filters to it again after the dataset opens.

Other datasets: descend from `TDatabaseGridDataSetFeatures` and call `RegisterDatabaseGridDataSetFeatures`. For another SQL
server with Devart DAC, descend from `TDatabaseGridDACDataSetFeatures` and override `TryGetSearchCondition` and
`TryGetColumnFilterCondition`.

## Job offers

https://www.linkedin.com/in/lassemarkusrautiainen/

## Donations

https://ko-fi.com/texteditorpro
