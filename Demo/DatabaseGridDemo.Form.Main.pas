unit DatabaseGridDemo.Form.Main;

interface

uses
  Winapi.Messages, Winapi.Windows, System.Actions, System.Classes, System.ImageList, System.SysUtils, Vcl.ActnList, Vcl.BaseImageCollection,
  Vcl.Buttons, Vcl.Controls, Vcl.ExtCtrls, Vcl.Forms, Vcl.ImageCollection, Vcl.ImgList, Vcl.VirtualImageList,
  DatabaseGridDemo.Frame.Customers, DatabaseGridDemo.Frame.DataGrouping, MyControl.ObjectInspector;

type
  TMainForm = class(TForm)
    ActionList: TActionList;
    ActionViewCustomers: TAction;
    ActionViewDarkTheme: TAction;
    ActionViewDataGrouping: TAction;
    PanelMain: TPanel;
    PanelSidebar: TPanel;
    SidebarImageCollection: TImageCollection;
    SidebarImageList: TVirtualImageList;
    SpeedButtonCustomers: TSpeedButton;
    SpeedButtonDarkTheme: TSpeedButton;
    SpeedButtonDataGrouping: TSpeedButton;
    procedure ActionViewDarkThemeExecute(ASender: TObject);
    procedure ActionViewExecute(ASender: TObject);
    procedure FormCreate(ASender: TObject);
  strict private
    FFrameCustomers: TFrameCustomers;
    FFrameDataGrouping: TFrameDataGrouping;
    FIsCustomStyleActive: Boolean;
    FObjectInspector: TMyObjectInspector;
    FSplitterRight: TSplitter;
    FWndProcGuardActive: Boolean;
    procedure AddSidebarImages;
    procedure CreateFrames;
    procedure CreateInspector;
    procedure CreateRightSplitter;
    procedure InspectObject(const AObject: TComponent);
  public
    procedure WndProc(var AMessage: TMessage); override;
  end;

var
  MainForm: TMainForm;

procedure ToggleDarkStyle(const AValue: Boolean);

implementation

{$R *.dfm}

uses
  Vcl.Graphics, Vcl.Themes, DatabaseGridDemo.Images;

const
  DEMO_VIEW_CUSTOMERS = 0;
  DEMO_VIEW_DATA_GROUPING = 1;

var
  GDarkStyleEnabled: Boolean;
  GStyleLoaded: Boolean;

procedure ToggleDarkStyle(const AValue: Boolean);
begin
  if not GStyleLoaded then
  begin
    TStyleManager.AutoDiscoverStyleResources := False;
    try
      TStyleManager.LoadFromResource(HInstance, 'DARKSTYLE');
      GStyleLoaded := True;
    except
      Exit;
    end;
  end;

  GDarkStyleEnabled := AValue;

  TStyleManager.TrySetStyle(if AValue then 'Windows11 Modern Dark' else 'Windows');
end;

procedure TMainForm.FormCreate(ASender: TObject);
begin
  FIsCustomStyleActive := IsCustomStyleActive;

  AddSidebarImages;
  CreateFrames;
  CreateInspector;
  CreateRightSplitter;

  InspectObject(FFrameCustomers.DatabaseGrid);
end;

procedure TMainForm.ActionViewDarkThemeExecute(ASender: TObject);
begin
  PanelSidebar.SetFocus;

  ToggleDarkStyle(not GDarkStyleEnabled);

  Application.ProcessMessages;

  FObjectInspector.InspectedObject := FObjectInspector.InspectedObject;
end;

procedure TMainForm.ActionViewExecute(ASender: TObject);
var
  LView: Integer;
begin
  LView := (ASender as TAction).Tag;

  FFrameCustomers.Visible := LView = DEMO_VIEW_CUSTOMERS;
  FFrameDataGrouping.Visible := LView = DEMO_VIEW_DATA_GROUPING;

  if LView = DEMO_VIEW_CUSTOMERS then
  begin
    SpeedButtonCustomers.Down := True;

    InspectObject(FFrameCustomers.DatabaseGrid);
  end
  else
  begin
    SpeedButtonDataGrouping.Down := True;

    InspectObject(FFrameDataGrouping.DatabaseGrid);
  end;
end;

procedure TMainForm.AddSidebarImages;
begin
  AddDemoImage(SidebarImageCollection, SidebarImageList, 'Customers',
    procedure(ACanvas: TCanvas)
    begin
      ACanvas.Pen.Color := TColor($00905020);
      ACanvas.Brush.Color := TColor($00E0B070);
      ACanvas.Rectangle(1, 2, 15, 14);
      ACanvas.Brush.Color := TColor($00905020);
      ACanvas.Rectangle(1, 2, 15, 5);
      ACanvas.MoveTo(1, 8);
      ACanvas.LineTo(15, 8);
      ACanvas.MoveTo(1, 11);
      ACanvas.LineTo(15, 11);
      ACanvas.MoveTo(6, 5);
      ACanvas.LineTo(6, 14);
    end);

  AddDemoImage(SidebarImageCollection, SidebarImageList, 'DataGrouping',
    procedure(ACanvas: TCanvas)
    begin
      ACanvas.Pen.Color := TColor($00206030);
      ACanvas.Brush.Color := TColor($0070C080);
      ACanvas.Rectangle(1, 1, 15, 5);
      ACanvas.Rectangle(6, 7, 15, 10);
      ACanvas.Rectangle(6, 12, 15, 15);

      ACanvas.Brush.Color := TColor($0050A860);
      ACanvas.FillRect(Rect(3, 5, 4, 14));
      ACanvas.FillRect(Rect(4, 8, 6, 9));
      ACanvas.FillRect(Rect(4, 13, 6, 14));
    end);

  AddDemoImage(SidebarImageCollection, SidebarImageList, 'DarkTheme',
    procedure(ACanvas: TCanvas)
    begin
      ACanvas.Pen.Color := TColor($00808080);
      ACanvas.Brush.Color := TColor($00F0F0F0);
      ACanvas.Ellipse(2, 2, 14, 14);
      ACanvas.Brush.Color := TColor($00303030);
      ACanvas.Pie(2, 2, 14, 14, 8, 14, 8, 2);
      ACanvas.Brush.Style := bsClear;
      ACanvas.Ellipse(2, 2, 14, 14);
    end);
end;

procedure TMainForm.CreateFrames;
begin
  FFrameCustomers := TFrameCustomers.Create(Self);
  FFrameCustomers.Parent := PanelMain;
  FFrameCustomers.LoadDemoData;

  FFrameDataGrouping := TFrameDataGrouping.Create(Self);
  FFrameDataGrouping.Visible := False;
  FFrameDataGrouping.Parent := PanelMain;
  FFrameDataGrouping.LoadDemoData;
end;

procedure TMainForm.CreateInspector;
begin
  FObjectInspector := TMyObjectInspector.Create(Self);
  FObjectInspector.Parent := PanelMain;
  FObjectInspector.Align := alRight;
  FObjectInspector.Width := ScaleValue(350);
end;

procedure TMainForm.CreateRightSplitter;
begin
  FSplitterRight := TSplitter.Create(Self);
  FSplitterRight.Parent := PanelMain;
  FSplitterRight.Align := alRight;
  FSplitterRight.Left := FObjectInspector.Left - FSplitterRight.Width;
end;

procedure TMainForm.InspectObject(const AObject: TComponent);
begin
  FObjectInspector.InspectedObject := AObject;
end;

procedure TMainForm.WndProc(var AMessage: TMessage);
begin
  if FIsCustomStyleActive and (AMessage.Msg = CM_SHOWINGCHANGED) and Showing and not FWndProcGuardActive and
    not (csDesigning in ComponentState) then
  begin
    FWndProcGuardActive := True;
    try
      AlphaBlend := True;
      AlphaBlendValue := 0;

      inherited WndProc(AMessage);

      if HandleAllocated then
        RedrawWindow(Handle, nil, 0, RDW_ALLCHILDREN or RDW_INVALIDATE or RDW_UPDATENOW);

      AlphaBlend := False;
    finally
      FWndProcGuardActive := False;
    end;
  end
  else
    inherited WndProc(AMessage);
end;

end.
