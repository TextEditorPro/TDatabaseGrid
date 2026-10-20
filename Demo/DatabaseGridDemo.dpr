program DatabaseGridDemo;

uses
  MidasLib,
  Vcl.Forms,
  Vcl.Styles,
  Vcl.Themes,
  MyControl.ObjectInspector in 'MyControl.ObjectInspector.pas',
  DatabaseGridDemo.Images in 'DatabaseGridDemo.Images.pas',
  DatabaseGridDemo.Form.Main in 'DatabaseGridDemo.Form.Main.pas' {MainForm},
  DatabaseGridDemo.Frame.Customers in 'DatabaseGridDemo.Frame.Customers.pas' {FrameCustomers: TFrame},
  DatabaseGridDemo.Frame.DataGrouping in 'DatabaseGridDemo.Frame.DataGrouping.pas' {FrameDataGrouping: TFrame};

{$R *.res}
{$R DarkStyle.res}

begin
  ToggleDarkStyle(True);

  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TMainForm, MainForm);
  Application.Run;
end.
