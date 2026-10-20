unit DatabaseGridDemo.Frame.Customers;

interface

uses
  System.Classes, System.ImageList, System.SysUtils, System.Types, Vcl.BaseImageCollection, Vcl.Buttons, Vcl.Controls, Vcl.ExtCtrls,
  Vcl.Forms, Vcl.Graphics, Vcl.ImageCollection, Vcl.ImgList, Vcl.Menus, Vcl.VirtualImageList, Data.DB, DatabaseGrid, DatabaseGrid.Columns,
  DatabaseGrid.SearchPanel, DatabaseGrid.Types, Datasnap.DBClient;

type
  TFrameCustomers = class(TFrame)
    ClientDataSet: TClientDataSet;
    ClientDataSetACTIVE: TBooleanField;
    ClientDataSetAMOUNT: TCurrencyField;
    ClientDataSetCITY: TStringField;
    ClientDataSetCOUNTRY: TStringField;
    ClientDataSetCOUNTRYID: TIntegerField;
    ClientDataSetCREATED: TDateField;
    ClientDataSetID: TIntegerField;
    ClientDataSetNAME: TStringField;
    ClientDataSetNOTES: TMemoField;
    ClientDataSetPRIORITY: TIntegerField;
    CountryDataSet: TClientDataSet;
    CountryDataSetID: TIntegerField;
    CountryDataSetNAME: TStringField;
    DatabaseGrid: TDatabaseGrid;
    DataSource: TDataSource;
    SpeedButtonZoomIn: TSpeedButton;
    SpeedButtonZoomOut: TSpeedButton;
    SpeedButtonZoomReset: TSpeedButton;
    StatusImageCollection: TImageCollection;
    StatusImageList: TVirtualImageList;
    StatusPanel: TPanel;
    procedure DatabaseGridDrawColumnCell(ASender: TObject; const AColumn: TDatabaseGridColumn; const ACanvas: TCanvas;
      const ARect: TRect; const AState: TDatabaseGridDrawCellStates; var AParams: TDatabaseGridDrawCellParams);
    procedure DatabaseGridIndicatorTitleMenuPopup(ASender: TObject; const AMenu: TPopupMenu);
    procedure DatabaseGridRefresh(ASender: TObject);
    procedure DatabaseGridScroll(ASender: TObject);
    procedure DatabaseGridSearchPanelItemChange(ASender: TObject; const AItem: TDatabaseGridSearchPanelItem);
    procedure DatabaseGridSelectionChanged(ASender: TObject);
    procedure DatabaseGridZoomChange(ASender: TObject);
    procedure MenuItemShowCheckBoxesClick(ASender: TObject);
    procedure SpeedButtonZoomInClick(ASender: TObject);
    procedure SpeedButtonZoomOutClick(ASender: TObject);
    procedure SpeedButtonZoomResetClick(ASender: TObject);
  strict private
    procedure AddCountries;
    procedure AddData(const ADataSet: TClientDataSet);
    procedure AddStatusImages;
    procedure LoadData;
    procedure UpdateStatus;
    procedure UpdateZoomButton;
  public
    procedure LoadDemoData;
  end;

implementation

{$R *.dfm}

uses
  Winapi.Windows, System.UITypes, System.Variants, DatabaseGrid.Colors, DatabaseGrid.DataSetFeatures.ClientDataSet, DatabaseGridDemo.Images;

const
  DEMO_CITIES: array [0..4] of string = ('Helsinki', 'Tampere', 'Turku', 'Oulu', 'Kuopio');
  DEMO_COUNTRIES: array [0..4] of string = ('Finland', 'Sweden', 'Norway', 'Denmark', 'Estonia');
  DEMO_ROW_COUNT = 100000;

procedure TFrameCustomers.AddCountries;
begin
  for var LIndex := 0 to High(DEMO_COUNTRIES) do
    CountryDataSet.AppendRecord([LIndex + 1, DEMO_COUNTRIES[LIndex]]);

  CountryDataSet.First;
end;

procedure TFrameCustomers.AddData(const ADataSet: TClientDataSet);
var
  LAmount: Currency;
  LCity, LName: string;
  LNotes: Variant;
begin
  for var LIndex := 1 to DEMO_ROW_COUNT do
  begin
    if LIndex mod 10 = 0 then
    begin
      LName := Format('Customer %d - a company with a long name that runs over', [LIndex]);
      LCity := '';
    end
    else
    begin
      LName := Format('Customer %d', [LIndex]);
      LCity := DEMO_CITIES[LIndex mod Length(DEMO_CITIES)];
    end;

    LAmount := (LIndex * 37 mod 100000) / 100;
    LNotes := Null;

    if LIndex mod 50 = 1 then
      LNotes := Format('Called on %d.1.' + sLineBreak + 'Wants an offer.', [LIndex mod 28 + 1]);

    ADataSet.AppendRecord([LIndex, LName, LCity, LAmount, EncodeDate(2026, 1, 1) + LIndex mod 365, LIndex mod 3 <> 0,
      LIndex mod Length(DEMO_COUNTRIES) + 1, LNotes, LIndex * 7 mod 11 mod 3]);
  end;
end;

procedure TFrameCustomers.AddStatusImages;
const
  DOT_COLORS: array [0..2, 0..1] of TColor = ((TColor($0040A040), TColor($00207020)), (TColor($0030C0F0), TColor($00108CB0)),
    (TColor($004040E0), TColor($002020A0)));
  DOT_NAMES: array [0..2] of string = ('Low', 'Normal', 'High');
begin
  for var LIndex := 0 to High(DOT_NAMES) do
    AddDemoImage(StatusImageCollection, StatusImageList, DOT_NAMES[LIndex],
      procedure(ACanvas: TCanvas)
      begin
        ACanvas.Brush.Color := DOT_COLORS[LIndex, 0];
        ACanvas.Pen.Color := DOT_COLORS[LIndex, 1];
        ACanvas.Ellipse(3, 3, 13, 13);
      end);

  AddDemoImage(StatusImageCollection, StatusImageList, 'Priority',
    procedure(ACanvas: TCanvas)
    begin
      ACanvas.Pen.Color := TColor($00404040);
      ACanvas.Brush.Color := TColor($00404040);
      ACanvas.Rectangle(3, 1, 4, 15);
      ACanvas.Pen.Color := TColor($002020A0);
      ACanvas.Brush.Color := TColor($004040E0);
      ACanvas.Polygon([Point(5, 2), Point(14, 5), Point(5, 9)]);
    end);
end;

procedure TFrameCustomers.DatabaseGridDrawColumnCell(ASender: TObject; const AColumn: TDatabaseGridColumn;
  const ACanvas: TCanvas; const ARect: TRect; const AState: TDatabaseGridDrawCellStates;
  var AParams: TDatabaseGridDrawCellParams);
begin
  if (AColumn.Field <> ClientDataSetAMOUNT) or (dcHighlighted in AState) then
    Exit;

  if ClientDataSetAMOUNT.AsCurrency >= 900 then
  begin
    AParams.Background := BlendDatabaseGridColor(AParams.Background, TColors.Green, 30);
    AParams.FontStyle := AParams.FontStyle + [TFontStyle.fsBold];
  end
  else
  if ClientDataSetAMOUNT.AsCurrency < 50 then
    AParams.FontColor := BlendDatabaseGridColor(AParams.FontColor, TColors.Red, 70);
end;

procedure TFrameCustomers.DatabaseGridIndicatorTitleMenuPopup(ASender: TObject; const AMenu: TPopupMenu);
var
  LMenuItem: TMenuItem;
begin
  AMenu.Items.NewBottomLine;

  LMenuItem := TMenuItem.Create(AMenu);
  LMenuItem.Caption := 'Show check boxes';
  LMenuItem.Checked := ioShowCheckBox in DatabaseGrid.Indicator.Options;
  LMenuItem.OnClick := MenuItemShowCheckBoxesClick;

  AMenu.Items.Add(LMenuItem);
end;

procedure TFrameCustomers.DatabaseGridRefresh(ASender: TObject);
begin
  Screen.Cursor := crHourGlass;
  try
    LoadData;
  finally
    Screen.Cursor := crDefault;
  end;
end;

procedure TFrameCustomers.DatabaseGridScroll(ASender: TObject);
begin
  UpdateStatus;
end;

procedure TFrameCustomers.DatabaseGridSearchPanelItemChange(ASender: TObject; const AItem: TDatabaseGridSearchPanelItem);
begin
  ClientDataSet.Filter := if AItem.ItemIndex > 0 then 'CITY = ' + QuotedStr(AItem.Value) else '';
  ClientDataSet.Filtered := True;
end;

procedure TFrameCustomers.DatabaseGridSelectionChanged(ASender: TObject);
begin
  UpdateStatus;
end;

procedure TFrameCustomers.DatabaseGridZoomChange(ASender: TObject);
var
  LSize: Integer;
begin
  LSize := MulDiv(DEMO_IMAGE_DESIGN_SIZE, DatabaseGrid.CurrentPPI * DatabaseGrid.ZoomPercentage, USER_DEFAULT_SCREEN_DPI * 100);

  StatusImageList.SetSize(LSize, LSize);

  UpdateZoomButton;
end;

procedure TFrameCustomers.LoadData;
var
  LDataSet: TClientDataSet;
begin
  LDataSet := TClientDataSet.Create(nil);
  try
    for var LField in ClientDataSet.Fields do
    if LField.FieldKind = fkData then
      LDataSet.FieldDefs.Add(LField.FieldName, LField.DataType, LField.Size);

    LDataSet.CreateDataSet;
    LDataSet.LogChanges := False;

    AddData(LDataSet);

    ClientDataSet.Data := LDataSet.Data;
    ClientDataSet.LogChanges := False;
  finally
    LDataSet.Free;
  end;
end;

procedure TFrameCustomers.LoadDemoData;
begin
  CountryDataSet.CreateDataSet;
  CountryDataSet.LogChanges := False;

  AddCountries;
  AddStatusImages;

  for var LCity in DEMO_CITIES do
    DatabaseGrid.Columns.FindColumn('CITY').PickList.Add(LCity);

  LoadData;
  UpdateStatus;
  UpdateZoomButton;
end;

procedure TFrameCustomers.MenuItemShowCheckBoxesClick(ASender: TObject);
begin
  DatabaseGrid.Indicator.SetOption(ioShowCheckBox, not (ioShowCheckBox in DatabaseGrid.Indicator.Options));
end;

procedure TFrameCustomers.SpeedButtonZoomInClick(ASender: TObject);
begin
  DatabaseGrid.ZoomIn;
end;

procedure TFrameCustomers.SpeedButtonZoomOutClick(ASender: TObject);
begin
  DatabaseGrid.ZoomOut;
end;

procedure TFrameCustomers.SpeedButtonZoomResetClick(ASender: TObject);
begin
  DatabaseGrid.ZoomReset;
end;

procedure TFrameCustomers.UpdateStatus;
begin
  if not ClientDataSet.Active then
    Exit;

  StatusPanel.Caption := Format('  Dataset record %d of %d - top row %d - selected rows %d', [ClientDataSet.RecNo,
    ClientDataSet.RecordCount, DatabaseGrid.TopRow, DatabaseGrid.SelectedRows.Count]);
end;

procedure TFrameCustomers.UpdateZoomButton;
begin
  SpeedButtonZoomReset.Caption := Format('%d %%', [DatabaseGrid.ZoomPercentage]);
end;

end.
