unit DatabaseGrid.Design.ComponentImages;

interface

uses
  Winapi.Windows, System.Classes, Vcl.Graphics;

function LoadComponentImage(const AClass: TClass; const ASize: Integer): TGraphic;
function TryLoadComponentImage(const AModule: HMODULE; const AClass: TClass; const ASize: Integer; out AImage: TGraphic): Boolean;

implementation

uses
  System.SysUtils;

function TryLoadComponentImage(const AModule: HMODULE; const AClass: TClass; const ASize: Integer; out AImage: TGraphic): Boolean;
var
  LBitmap: TBitmap;
  LName, LSizedName: string;
begin
  AImage := nil;

  LName := UpperCase(AClass.ClassName);

  if ASize >= 32 then
    LSizedName := LName + '32'
  else
  if ASize <= 16 then
    LSizedName := LName + '16'
  else
    LSizedName := LName;

  if FindResource(AModule, PChar(LSizedName), RT_BITMAP) <> 0 then
    LName := LSizedName
  else
  if (LSizedName = LName) or (FindResource(AModule, PChar(LName), RT_BITMAP) = 0) then
    Exit(False);

  LBitmap := TBitmap.Create;
  try
    LBitmap.LoadFromResourceName(AModule, LName);

    if LBitmap.PixelFormat = pf32bit then
      LBitmap.AlphaFormat := afDefined
    else
      LBitmap.Transparent := True;
  except
    LBitmap.Free;

    Exit(False);
  end;

  AImage := LBitmap;

  Result := True;
end;

function LoadComponentImage(const AClass: TClass; const ASize: Integer): TGraphic;
var
  LClass: TClass;
  LModule: PLibModule;
begin
  LClass := AClass;

  while Assigned(LClass) and LClass.InheritsFrom(TComponent) do
  begin
    LModule := LibModuleList;

    while Assigned(LModule) do
    begin
      if TryLoadComponentImage(LModule.Instance, LClass, ASize, Result) then
        Exit;

      LModule := LModule.Next;
    end;

    LClass := LClass.ClassParent;
  end;

  Result := nil;
end;

end.
