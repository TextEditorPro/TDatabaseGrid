unit DatabaseGridDemo.Frame.DataGrouping;

interface

uses
  System.Classes, System.ImageList, System.SysUtils, System.Types, Vcl.BaseImageCollection, Vcl.Buttons, Vcl.Controls, Vcl.ExtCtrls,
  Vcl.Forms, Vcl.Graphics, Vcl.ImageCollection, Vcl.ImgList, Vcl.StdCtrls, Vcl.VirtualImageList, Data.DB, DatabaseGrid,
  DatabaseGrid.Groups, DatabaseGrid.Types, Datasnap.DBClient;

type
  TFrameDataGrouping = class(TFrame)
    ButtonCollapseAll: TButton;
    ButtonExpandAll: TButton;
    CheckBoxGroupByCity: TCheckBox;
    CheckBoxGroupByCountry: TCheckBox;
    DatabaseGrid: TDatabaseGrid;
    GroupImageCollection: TImageCollection;
    GroupImageList: TVirtualImageList;
    OrderDataSet: TClientDataSet;
    OrderDataSetAMOUNT: TCurrencyField;
    OrderDataSetCITY: TStringField;
    OrderDataSetCOUNTRY: TStringField;
    OrderDataSetCUSTOMER: TStringField;
    OrderDataSetID: TIntegerField;
    OrderDataSetORDERED: TDateField;
    OrderDataSource: TDataSource;
    SpeedButtonZoomIn: TSpeedButton;
    SpeedButtonZoomOut: TSpeedButton;
    SpeedButtonZoomReset: TSpeedButton;
    StatusPanel: TPanel;
    ToolPanel: TPanel;
    procedure ButtonCollapseAllClick(ASender: TObject);
    procedure ButtonExpandAllClick(ASender: TObject);
    procedure CheckBoxGroupByClick(ASender: TObject);
    procedure DatabaseGridDrawGroupRow(ASender: TObject; const ANode: TDatabaseGridGroupNode; const ACanvas: TCanvas;
      const ARect: TRect; const AState: TDatabaseGridDrawCellStates; var AParams: TDatabaseGridDrawGroupRowParams);
    procedure DatabaseGridGroupExpandedChange(ASender: TObject; const ANode: TDatabaseGridGroupNode);
    procedure DatabaseGridScroll(ASender: TObject);
    procedure DatabaseGridZoomChange(ASender: TObject);
    procedure OrderDataSetAfterScroll(ADataSet: TDataSet);
    procedure SpeedButtonZoomInClick(ASender: TObject);
    procedure SpeedButtonZoomOutClick(ASender: TObject);
    procedure SpeedButtonZoomResetClick(ASender: TObject);
  strict private
    procedure AddGroupImages;
    procedure AddOrders;
    procedure UpdateStatus;
    procedure UpdateZoomButton;
  public
    procedure LoadDemoData;
  end;

implementation

{$R *.dfm}

uses
  Winapi.Windows, System.UITypes, DatabaseGridDemo.Images;

const
  DEMO_GROUP_IMAGE_CITY = 1;
  DEMO_GROUP_IMAGE_COUNTRY = 0;
  DEMO_ORDER_COUNT = 2000;

procedure TFrameDataGrouping.AddGroupImages;
begin
  AddDemoImage(GroupImageCollection, GroupImageList, 'Country',
    procedure(ACanvas: TCanvas)
    begin
      ACanvas.Pen.Color := TColor($00905020);
      ACanvas.Brush.Color := TColor($00E0B070);
      ACanvas.Ellipse(1, 1, 15, 15);
      ACanvas.MoveTo(1, 8);
      ACanvas.LineTo(15, 8);
      ACanvas.Arc(4, 1, 12, 15, 8, 1, 8, 15);
      ACanvas.Arc(4, 1, 12, 15, 8, 15, 8, 1);
    end);

  AddDemoImage(GroupImageCollection, GroupImageList, 'City',
    procedure(ACanvas: TCanvas)
    begin
      ACanvas.Pen.Color := TColor($00206030);
      ACanvas.Brush.Color := TColor($0070C080);
      ACanvas.Polygon([Point(1, 7), Point(8, 1), Point(15, 7)]);
      ACanvas.Rectangle(3, 7, 13, 15);
    end);
end;

procedure TFrameDataGrouping.AddOrders;
const
  CITIES: array [0..4, 0..2] of string = (('Helsinki', 'Tampere', 'Turku'), ('Stockholm', 'Gothenburg', 'Malmo'),
    ('Oslo', 'Bergen', 'Trondheim'), ('Copenhagen', 'Aarhus', 'Odense'), ('Tallinn', 'Tartu', 'Parnu'));
  COUNTRIES: array [0..4] of string = ('Finland', 'Sweden', 'Norway', 'Denmark', 'Estonia');
var
  LCountryIndex: Integer;
begin
  OrderDataSet.DisableControls;
  try
    for var LIndex := 1 to DEMO_ORDER_COUNT do
    begin
      LCountryIndex := LIndex * 7 mod Length(COUNTRIES);

      OrderDataSet.AppendRecord([LIndex, COUNTRIES[LCountryIndex], CITIES[LCountryIndex, LIndex * 11 mod 3],
        Format('Customer %d', [LIndex * 13 mod 400 + 1]), (LIndex * 53 mod 50000) / 100, EncodeDate(2026, 1, 1) + LIndex mod 280]);
    end;

    OrderDataSet.First;
  finally
    OrderDataSet.EnableControls;
  end;
end;

procedure TFrameDataGrouping.ButtonCollapseAllClick(ASender: TObject);
begin
  DatabaseGrid.Groups.CollapseAll;
end;

procedure TFrameDataGrouping.ButtonExpandAllClick(ASender: TObject);
begin
  DatabaseGrid.Groups.ExpandAll;
end;

procedure TFrameDataGrouping.CheckBoxGroupByClick(ASender: TObject);
begin
  DatabaseGrid.DataGrouping.Levels.BeginUpdate;
  try
    DatabaseGrid.DataGrouping.Levels.Clear;

    if CheckBoxGroupByCountry.Checked then
      DatabaseGrid.DataGrouping.Levels.Add.FieldName := 'COUNTRY';

    if CheckBoxGroupByCity.Checked then
      DatabaseGrid.DataGrouping.Levels.Add.FieldName := 'CITY';
  finally
    DatabaseGrid.DataGrouping.Levels.EndUpdate;
  end;

  UpdateStatus;
end;

procedure TFrameDataGrouping.DatabaseGridDrawGroupRow(ASender: TObject; const ANode: TDatabaseGridGroupNode;
  const ACanvas: TCanvas; const ARect: TRect; const AState: TDatabaseGridDrawCellStates;
  var AParams: TDatabaseGridDrawGroupRowParams);
begin
  if ANode.Field = OrderDataSetCOUNTRY then
  begin
    AParams.ImageIndex := DEMO_GROUP_IMAGE_COUNTRY;

    if ANode.Count > 0 then
      AParams.Text := Format('%s - %d cities, %d orders', [ANode.Text, ANode.Count, ANode.RecordCount])
    else
      AParams.Text := Format('%s - %d orders', [ANode.Text, ANode.RecordCount]);
  end
  else
  begin
    AParams.ImageIndex := DEMO_GROUP_IMAGE_CITY;
    AParams.Text := Format('%s - %d orders', [ANode.Text, ANode.RecordCount]);

    if ANode.Level > 0 then
      AParams.FontStyle := AParams.FontStyle - [TFontStyle.fsBold];
  end;
end;

procedure TFrameDataGrouping.DatabaseGridGroupExpandedChange(ASender: TObject; const ANode: TDatabaseGridGroupNode);
begin
  UpdateStatus;
end;

procedure TFrameDataGrouping.DatabaseGridScroll(ASender: TObject);
begin
  UpdateStatus;
end;

procedure TFrameDataGrouping.DatabaseGridZoomChange(ASender: TObject);
var
  LSize: Integer;
begin
  LSize := MulDiv(DEMO_IMAGE_DESIGN_SIZE, DatabaseGrid.CurrentPPI * DatabaseGrid.ZoomPercentage, USER_DEFAULT_SCREEN_DPI * 100);

  GroupImageList.SetSize(LSize, LSize);

  UpdateZoomButton;
end;

procedure TFrameDataGrouping.LoadDemoData;
begin
  AddGroupImages;

  OrderDataSet.CreateDataSet;
  OrderDataSet.LogChanges := False;

  AddOrders;

  if DatabaseGrid.Groups.Count > 0 then
  begin
    DatabaseGrid.Groups[0].Expanded := True;

    OrderDataSet.Locate('COUNTRY', DatabaseGrid.Groups[0].Text, []);
    DatabaseGrid.Groups.FocusedNode := DatabaseGrid.Groups[0];
  end;

  UpdateStatus;
  UpdateZoomButton;
end;

procedure TFrameDataGrouping.OrderDataSetAfterScroll(ADataSet: TDataSet);
begin
  UpdateStatus;
end;

procedure TFrameDataGrouping.SpeedButtonZoomInClick(ASender: TObject);
begin
  DatabaseGrid.ZoomIn;
end;

procedure TFrameDataGrouping.SpeedButtonZoomOutClick(ASender: TObject);
begin
  DatabaseGrid.ZoomOut;
end;

procedure TFrameDataGrouping.SpeedButtonZoomResetClick(ASender: TObject);
begin
  DatabaseGrid.ZoomReset;
end;

procedure TFrameDataGrouping.UpdateStatus;
var
  LNode: TDatabaseGridGroupNode;
  LText: string;
begin
  if not OrderDataSet.Active then
    Exit;

  LText := '';
  LNode := DatabaseGrid.Groups.CurrentNode;

  while Assigned(LNode) do
  begin
    LText := if LText.IsEmpty then LNode.Text else LNode.Text + ' / ' + LText;
    LNode := LNode.Parent;
  end;

  if LText.IsEmpty then
    LText := '-';

  StatusPanel.Caption := Format('  Order %d - group %s - %d groups - %d rows shown', [OrderDataSetID.AsInteger, LText,
    DatabaseGrid.Groups.NodeCount, DatabaseGrid.Groups.RowCount]);
end;

procedure TFrameDataGrouping.UpdateZoomButton;
begin
  SpeedButtonZoomReset.Caption := Format('%d %%', [DatabaseGrid.ZoomPercentage]);
end;

end.
