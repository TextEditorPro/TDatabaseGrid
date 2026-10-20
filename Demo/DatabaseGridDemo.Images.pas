unit DatabaseGridDemo.Images;

interface

uses
  Winapi.Windows, System.SysUtils, Vcl.Graphics, Vcl.ImageCollection, Vcl.VirtualImageList;

const
  DEMO_IMAGE_DESIGN_SIZE = 16;

procedure AddDemoImage(const ACollection: TImageCollection; const AList: TVirtualImageList; const AName: string; const APaint: TProc<TCanvas>);

implementation

uses
  System.Classes, System.UITypes, Vcl.Imaging.pngimage;

const
  DEMO_IMAGE_SOURCE_SIZE = 64;
  DEMO_IMAGE_SUPERSAMPLING = 4;

procedure AddDemoImage(const ACollection: TImageCollection; const AList: TVirtualImageList; const AName: string;
  const APaint: TProc<TCanvas>);
const
  DRAWING_SIZE = DEMO_IMAGE_SOURCE_SIZE * DEMO_IMAGE_SUPERSAMPLING;
  KEY_COLOR = TColors.Fuchsia;
  SAMPLE_COUNT = DEMO_IMAGE_SUPERSAMPLING * DEMO_IMAGE_SUPERSAMPLING;
var
  LAlpha: PByteArray;
  LBlue, LCount, LGreen, LRed: Integer;
  LDrawing: TBitmap;
  LImage: TPngImage;
  LPixel, LTarget: PRGBTriple;
  LStream: TMemoryStream;
  LTransform: TXForm;
begin
  LDrawing := TBitmap.Create;
  try
    LDrawing.PixelFormat := pf24bit;
    LDrawing.SetSize(DRAWING_SIZE, DRAWING_SIZE);
    LDrawing.Canvas.Brush.Color := KEY_COLOR;
    LDrawing.Canvas.FillRect(Rect(0, 0, DRAWING_SIZE, DRAWING_SIZE));

    LTransform := Default(TXForm);
    LTransform.eM11 := DRAWING_SIZE / DEMO_IMAGE_DESIGN_SIZE;
    LTransform.eM22 := LTransform.eM11;

    SetGraphicsMode(LDrawing.Canvas.Handle, GM_ADVANCED);
    SetWorldTransform(LDrawing.Canvas.Handle, LTransform);

    APaint(LDrawing.Canvas);

    LImage := TPngImage.CreateBlank(COLOR_RGBALPHA, 8, DEMO_IMAGE_SOURCE_SIZE, DEMO_IMAGE_SOURCE_SIZE);
    try
      for var LY := 0 to DEMO_IMAGE_SOURCE_SIZE - 1 do
      begin
        LTarget := LImage.Scanline[LY];
        LAlpha := LImage.AlphaScanline[LY];

        for var LX := 0 to DEMO_IMAGE_SOURCE_SIZE - 1 do
        begin
          LCount := 0;
          LRed := 0;
          LGreen := 0;
          LBlue := 0;

          for var LSampleY := 0 to DEMO_IMAGE_SUPERSAMPLING - 1 do
          begin
            LPixel := LDrawing.ScanLine[LY * DEMO_IMAGE_SUPERSAMPLING + LSampleY];
            Inc(LPixel, LX * DEMO_IMAGE_SUPERSAMPLING);

            for var LSampleX := 0 to DEMO_IMAGE_SUPERSAMPLING - 1 do
            begin
              if TColor(RGB(LPixel.rgbtRed, LPixel.rgbtGreen, LPixel.rgbtBlue)) <> KEY_COLOR then
              begin
                Inc(LCount);
                Inc(LRed, LPixel.rgbtRed);
                Inc(LGreen, LPixel.rgbtGreen);
                Inc(LBlue, LPixel.rgbtBlue);
              end;

              Inc(LPixel);
            end;
          end;

          LTarget.rgbtRed := if LCount > 0 then LRed div LCount else 0;
          LTarget.rgbtGreen := if LCount > 0 then LGreen div LCount else 0;
          LTarget.rgbtBlue := if LCount > 0 then LBlue div LCount else 0;
          LAlpha[LX] := LCount * 255 div SAMPLE_COUNT;

          Inc(LTarget);
        end;
      end;

      LStream := TMemoryStream.Create;
      try
        LImage.SaveToStream(LStream);
        LStream.Position := 0;

        ACollection.Add(AName, LStream);
      finally
        LStream.Free;
      end;
    finally
      LImage.Free;
    end;
  finally
    LDrawing.Free;
  end;

  AList.Add(AName, AName);
end;

end.
