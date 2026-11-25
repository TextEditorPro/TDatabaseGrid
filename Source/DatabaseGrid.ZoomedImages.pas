unit DatabaseGrid.ZoomedImages;

interface

uses
  System.Classes, System.Generics.Collections, Vcl.Graphics, Vcl.ImgList, Vcl.VirtualImageList;

type
  TDatabaseGridZoomedImages = class(TComponent)
  strict private type
    TDatabaseGridZoomedImageList = class(TObject)
    strict private
      FChangeLink: TChangeLink;
      FImages: TVirtualImageList;
      FSource: TVirtualImageList;
      procedure SourceChange(ASender: TObject);
    public
      constructor Create(const ASource: TVirtualImageList);
      destructor Destroy; override;
      function GetImages(const AWidth, AHeight: Integer): TVirtualImageList;
      procedure Reset;
    end;
  strict private
    FImageLists: TObjectDictionary<TCustomImageList, TDatabaseGridZoomedImageList>;
    FZoomPercentage: Integer;
    function GetZoomedImages(const AImages: TVirtualImageList): TVirtualImageList;
    procedure SetZoomPercentage(const AValue: Integer);
  protected
    procedure Notification(AComponent: TComponent; AOperation: TOperation); override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    function GetHeight(const AImages: TCustomImageList): Integer;
    function GetWidth(const AImages: TCustomImageList): Integer;
    procedure Draw(const ACanvas: TCanvas; const AImages: TCustomImageList; const AImageIndex, ALeft, ATop: Integer);
    property ZoomPercentage: Integer read FZoomPercentage write SetZoomPercentage;
  end;

implementation

uses
  Winapi.CommCtrl, Winapi.Windows, System.ImageList, DatabaseGrid.Consts;

type
  TVirtualImageListClass = class of TVirtualImageList;

{ TDatabaseGridZoomedImages.TDatabaseGridZoomedImageList }

constructor TDatabaseGridZoomedImages.TDatabaseGridZoomedImageList.Create(const ASource: TVirtualImageList);
begin
  inherited Create;

  FSource := ASource;
  FChangeLink := TChangeLink.Create;
  FChangeLink.OnChange := SourceChange;
  FChangeLink.Sender := ASource;
end;

destructor TDatabaseGridZoomedImages.TDatabaseGridZoomedImageList.Destroy;
begin
  FChangeLink.Free;
  FImages.Free;

  inherited Destroy;
end;

function TDatabaseGridZoomedImages.TDatabaseGridZoomedImageList.GetImages(const AWidth, AHeight: Integer): TVirtualImageList;
begin
  if not Assigned(FImages) then
  begin
    FImages := TVirtualImageListClass(FSource.ClassType).Create(nil);
    FImages.BeginUpdate;
    try
      FImages.SetSize(AWidth, AHeight);
      FImages.Assign(FSource);
    finally
      FImages.EndUpdate;
    end;
  end;

  Result := FImages;
end;

procedure TDatabaseGridZoomedImages.TDatabaseGridZoomedImageList.Reset;
begin
  FImages.Free;
  FImages := nil;
end;

procedure TDatabaseGridZoomedImages.TDatabaseGridZoomedImageList.SourceChange(ASender: TObject);
begin
  Reset;
end;

{ TDatabaseGridZoomedImages }

constructor TDatabaseGridZoomedImages.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);

  FImageLists := TObjectDictionary<TCustomImageList, TDatabaseGridZoomedImageList>.Create([doOwnsValues]);
  FZoomPercentage := TDatabaseGridDefault.ZoomPercentage;
end;

destructor TDatabaseGridZoomedImages.Destroy;
begin
  FImageLists.Free;

  inherited Destroy;
end;

procedure TDatabaseGridZoomedImages.Draw(const ACanvas: TCanvas; const AImages: TCustomImageList; const AImageIndex, ALeft,
  ATop: Integer);
begin
  if FZoomPercentage = TDatabaseGridDefault.ZoomPercentage then
    AImages.Draw(ACanvas, ALeft, ATop, AImageIndex, dsTransparent, itImage)
  else
  if AImages is TVirtualImageList then
    GetZoomedImages(TVirtualImageList(AImages)).Draw(ACanvas, ALeft, ATop, AImageIndex, dsTransparent, itImage)
  else
    ImageList_DrawEx(AImages.Handle, AImageIndex, ACanvas.Handle, ALeft, ATop, GetWidth(AImages), GetHeight(AImages), CLR_NONE,
      CLR_NONE, ILD_TRANSPARENT or ILD_SCALE);
end;

function TDatabaseGridZoomedImages.GetHeight(const AImages: TCustomImageList): Integer;
begin
  Result := MulDiv(AImages.Height, FZoomPercentage, 100);
end;

function TDatabaseGridZoomedImages.GetWidth(const AImages: TCustomImageList): Integer;
begin
  Result := MulDiv(AImages.Width, FZoomPercentage, 100);
end;

function TDatabaseGridZoomedImages.GetZoomedImages(const AImages: TVirtualImageList): TVirtualImageList;
var
  LImageList: TDatabaseGridZoomedImageList;
begin
  if not FImageLists.TryGetValue(AImages, LImageList) then
  begin
    LImageList := TDatabaseGridZoomedImageList.Create(AImages);

    FImageLists.Add(AImages, LImageList);
    AImages.FreeNotification(Self);
  end;

  Result := LImageList.GetImages(GetWidth(AImages), GetHeight(AImages));
end;

procedure TDatabaseGridZoomedImages.Notification(AComponent: TComponent; AOperation: TOperation);
begin
  inherited Notification(AComponent, AOperation);

  if (AOperation = opRemove) and (AComponent is TCustomImageList) then
    FImageLists.Remove(TCustomImageList(AComponent));
end;

procedure TDatabaseGridZoomedImages.SetZoomPercentage(const AValue: Integer);
begin
  if FZoomPercentage = AValue then
    Exit;

  FZoomPercentage := AValue;

  for var LImageList in FImageLists.Values do
    LImageList.Reset;
end;

end.
