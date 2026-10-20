object MainForm: TMainForm
  Left = 0
  Top = 0
  Caption = 'TDatabaseGrid demo'
  ClientHeight = 729
  ClientWidth = 1384
  Color = clWindow
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poScreenCenter
  OnCreate = FormCreate
  TextHeight = 15
  object PanelSidebar: TPanel
    Left = 0
    Top = 0
    Width = 68
    Height = 729
    Align = alLeft
    BevelOuter = bvNone
    ParentColor = True
    ShowCaption = False
    TabOrder = 0
    object SpeedButtonCustomers: TSpeedButton
      Left = 0
      Top = 0
      Width = 68
      Height = 61
      Action = ActionViewCustomers
      Align = alTop
      GroupIndex = 1
      Down = True
      ImageIndex = 0
      Images = SidebarImageList
      Flat = True
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'Segoe UI'
      Font.Style = []
      Layout = blGlyphTop
      ParentFont = False
    end
    object SpeedButtonDataGrouping: TSpeedButton
      Left = 0
      Top = 61
      Width = 68
      Height = 61
      Action = ActionViewDataGrouping
      Align = alTop
      GroupIndex = 1
      ImageIndex = 1
      Images = SidebarImageList
      Flat = True
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'Segoe UI'
      Font.Style = []
      Layout = blGlyphTop
      ParentFont = False
    end
    object SpeedButtonDarkTheme: TSpeedButton
      Left = 0
      Top = 668
      Width = 68
      Height = 61
      Action = ActionViewDarkTheme
      Align = alBottom
      ImageIndex = 2
      Images = SidebarImageList
      Flat = True
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'Segoe UI'
      Font.Style = []
      Layout = blGlyphTop
      ParentFont = False
    end
  end
  object PanelMain: TPanel
    Left = 68
    Top = 0
    Width = 1316
    Height = 729
    Align = alClient
    BevelOuter = bvNone
    Padding.Left = 3
    ParentColor = True
    ShowCaption = False
    TabOrder = 1
  end
  object ActionList: TActionList
    Images = SidebarImageList
    Left = 240
    Top = 120
    object ActionViewCustomers: TAction
      AutoCheck = True
      Caption = 'Customers'
      GroupIndex = 1
      OnExecute = ActionViewExecute
    end
    object ActionViewDataGrouping: TAction
      Tag = 1
      AutoCheck = True
      Caption = 'Grouping'
      GroupIndex = 1
      OnExecute = ActionViewExecute
    end
    object ActionViewDarkTheme: TAction
      Caption = 'Dark theme'
      OnExecute = ActionViewDarkThemeExecute
    end
  end
  object SidebarImageCollection: TImageCollection
    Images = <>
    Left = 240
    Top = 184
  end
  object SidebarImageList: TVirtualImageList
    Images = <>
    ImageCollection = SidebarImageCollection
    Width = 32
    Height = 32
    Left = 352
    Top = 184
  end
end
