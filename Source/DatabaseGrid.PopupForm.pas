unit DatabaseGrid.PopupForm;

{$I DatabaseGrid.Defines.inc}

interface

uses
  Winapi.Messages, Winapi.Windows, System.Classes, System.UITypes, Vcl.Controls, Vcl.Forms;

type
  TDatabaseGridPopupForm = class(TCustomForm)
  strict private
    FShowingGuard: Boolean;
    procedure PaintStyledBorder;
  protected
    function SystemColor(const AColor: TColor): TColor;
    procedure WndProc(var AMessage: TMessage); override;
  public
    constructor CreateNew(AOwner: TComponent; ADummy: Integer = 0); override;
  end;

function GetDatabaseGridSystemColor(const AColor: TColor): TColor;
procedure PaintDatabaseGridStyledBorder(const AHandle: HWND);

implementation

uses
  Vcl.Graphics
{$IFDEF ALPHASKINS}
  , sConst, sSkinManager, sVCLUtils
{$ENDIF}
{$IFDEF DATABASE_GRID_VCL_STYLES}
  , Vcl.Themes
{$ENDIF};

function IsSkinActive: Boolean;
begin
{$IFDEF ALPHASKINS}
  Result := Assigned(DefaultManager) and DefaultManager.IsActive;
{$ELSE}
  Result := False;
{$ENDIF}
end;

function GetDatabaseGridSystemColor(const AColor: TColor): TColor;
begin
{$IFDEF ALPHASKINS}
  if IsSkinActive then
    Exit(acColorToRGB(AColor));
{$ENDIF}
{$IFDEF DATABASE_GRID_VCL_STYLES}
  Result := StyleServices.GetSystemColor(AColor);
{$ELSE}
  Result := AColor;
{$ENDIF}
end;

constructor TDatabaseGridPopupForm.CreateNew(AOwner: TComponent; ADummy: Integer);
begin
  inherited CreateNew(AOwner, ADummy);

  BorderStyle := bsNone;
{$IFDEF ALPHASKINS}
  Tag := Tag or ExceptTag;
{$ENDIF}

  if IsSkinActive then
    Color := SystemColor(TColors.SysBtnFace)
  else
    Color := SystemColor(TColors.SysWindow);

  KeyPreview := True;
  Position := poDesigned;
  StyleElements := [seFont, seBorder];

  if AOwner is TControl then
  begin
    PopupMode := pmExplicit;
    PopupParent := GetParentForm(TControl(AOwner));
  end;
end;

procedure PaintDatabaseGridStyledBorder(const AHandle: HWND);
var
  LBrush: HBRUSH;
  LDC: HDC;
  LRect: TRect;
begin
  if (AHandle = 0) or not IsSkinActive {$IFDEF DATABASE_GRID_VCL_STYLES}and not TStyleManager.IsCustomStyleActive{$ENDIF} then
    Exit;

  LDC := GetWindowDC(AHandle);
  try
    GetWindowRect(AHandle, LRect);
    LRect.Offset(-LRect.Left, -LRect.Top);

    if IsSkinActive then
    begin
      LBrush := CreateSolidBrush(ColorToRGB(GetDatabaseGridSystemColor(TColors.SysWindowFrame)));
      try
        FrameRect(LDC, LRect, LBrush);
      finally
        DeleteObject(LBrush);
      end;
    end
{$IFDEF DATABASE_GRID_VCL_STYLES}
    else
    begin
      ExcludeClipRect(LDC, LRect.Left + 1, LRect.Top + 1, LRect.Right - 1, LRect.Bottom - 1);
      StyleServices.DrawElement(LDC, StyleServices.GetElementDetails(teEditBorderNoScrollNormal), LRect);
    end
{$ENDIF};
  finally
    ReleaseDC(AHandle, LDC);
  end;
end;

procedure TDatabaseGridPopupForm.PaintStyledBorder;
begin
  if HandleAllocated then
    PaintDatabaseGridStyledBorder(Handle);
end;

function TDatabaseGridPopupForm.SystemColor(const AColor: TColor): TColor;
begin
  Result := GetDatabaseGridSystemColor(AColor);
end;

procedure TDatabaseGridPopupForm.WndProc(var AMessage: TMessage);
begin
  if (AMessage.Msg = CM_SHOWINGCHANGED) and Showing and not FShowingGuard then
  begin
    FShowingGuard := True;
    try
      AlphaBlend := True;
      AlphaBlendValue := 0;

      inherited WndProc(AMessage);

      if HandleAllocated then
        RedrawWindow(Handle, nil, 0, RDW_ALLCHILDREN or RDW_INVALIDATE or RDW_UPDATENOW);

      AlphaBlendValue := 255;
    finally
      FShowingGuard := False;
    end;

    Exit;
  end;

  inherited WndProc(AMessage);

  if (AMessage.Msg = WM_NCPAINT) or (AMessage.Msg = WM_NCACTIVATE) then
    PaintStyledBorder;
end;

end.
