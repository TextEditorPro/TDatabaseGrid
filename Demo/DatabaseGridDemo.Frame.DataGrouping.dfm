object FrameDataGrouping: TFrameDataGrouping
  Left = 0
  Top = 0
  Width = 900
  Height = 600
  Align = alClient
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  ParentFont = False
  TabOrder = 0
  object ToolPanel: TPanel
    Left = 0
    Top = 0
    Width = 900
    Height = 33
    Align = alTop
    BevelOuter = bvNone
    ParentColor = True
    ShowCaption = False
    TabOrder = 0
    object CheckBoxGroupByCountry: TCheckBox
      AlignWithMargins = True
      Left = 6
      Top = 3
      Width = 125
      Height = 27
      Margins.Left = 6
      Align = alLeft
      Caption = 'Group by country'
      Checked = True
      State = cbChecked
      TabOrder = 0
      OnClick = CheckBoxGroupByClick
    end
    object CheckBoxGroupByCity: TCheckBox
      AlignWithMargins = True
      Left = 137
      Top = 3
      Width = 110
      Height = 27
      Align = alLeft
      Caption = 'Group by city'
      Checked = True
      State = cbChecked
      TabOrder = 1
      OnClick = CheckBoxGroupByClick
    end
    object ButtonExpandAll: TButton
      AlignWithMargins = True
      Left = 253
      Top = 3
      Width = 90
      Height = 27
      Align = alLeft
      Caption = 'Expand all'
      TabOrder = 2
      OnClick = ButtonExpandAllClick
    end
    object ButtonCollapseAll: TButton
      AlignWithMargins = True
      Left = 349
      Top = 3
      Width = 90
      Height = 27
      Align = alLeft
      Caption = 'Collapse all'
      TabOrder = 3
      OnClick = ButtonCollapseAllClick
    end
  end
  object DatabaseGrid: TDatabaseGrid
    Left = 0
    Top = 33
    Width = 900
    Height = 543
    Margins.Right = 5
    Align = alClient
    Columns = <
      item
        Alignment = taRightJustify
        FieldName = 'ID'
        Options = [coFilterValueList]
        Title.Alignment = taRightJustify
        Title.Caption = 'Order'
        Width = 70
      end
      item
        FieldName = 'CUSTOMER'
        Title.Caption = 'Customer'
        Width = 200
      end
      item
        FieldName = 'COUNTRY'
        Title.Caption = 'Country'
        Width = 120
      end
      item
        FieldName = 'CITY'
        Title.Caption = 'City'
        Width = 120
      end
      item
        Alignment = taRightJustify
        FieldName = 'AMOUNT'
        Title.Alignment = taRightJustify
        Title.Caption = 'Amount'
        Width = 110
      end
      item
        Alignment = taCenter
        FieldName = 'ORDERED'
        Title.Alignment = taCenter
        Title.Caption = 'Ordered'
        Width = 110
      end>
    DataGrouping.Active = True
    DataGrouping.Images = GroupImageList
    DataGrouping.Levels = <
      item
        FieldName = 'COUNTRY'
      end
      item
        FieldName = 'CITY'
      end>
    DataSource = OrderDataSource
    OnDrawGroupRow = DatabaseGridDrawGroupRow
    OnGroupExpandedChange = DatabaseGridGroupExpandedChange
    OnScroll = DatabaseGridScroll
    OnZoomChange = DatabaseGridZoomChange
    Options = [dgoAlwaysShowSelection, dgoAutoFitColumns, dgoColumnResize, dgoExtendVerticalLines, dgoShowHints, dgoSortMarking]
    SearchPanel.Options = [spoFilterOnTyping, spoHighlightMatches]
    SearchPanel.Visible = True
    TabOrder = 1
    Title.VerticalLines = False
  end
  object StatusPanel: TPanel
    Left = 0
    Top = 576
    Width = 900
    Height = 24
    Align = alBottom
    Alignment = taLeftJustify
    BevelOuter = bvNone
    ParentColor = True
    TabOrder = 2
    object SpeedButtonZoomOut: TSpeedButton
      Left = 808
      Top = 0
      Width = 24
      Height = 24
      Hint = 'Zoom out (Ctrl+Minus or Ctrl+mouse wheel)'
      Align = alRight
      Caption = #8722
      Flat = True
      ParentShowHint = False
      ShowHint = True
      OnClick = SpeedButtonZoomOutClick
    end
    object SpeedButtonZoomReset: TSpeedButton
      Left = 832
      Top = 0
      Width = 44
      Height = 24
      Hint = 'Reset the zoom (Ctrl+0)'
      Align = alRight
      Caption = '100 %'
      Flat = True
      ParentShowHint = False
      ShowHint = True
      OnClick = SpeedButtonZoomResetClick
    end
    object SpeedButtonZoomIn: TSpeedButton
      Left = 876
      Top = 0
      Width = 24
      Height = 24
      Hint = 'Zoom in (Ctrl+Plus or Ctrl+mouse wheel)'
      Align = alRight
      Caption = '+'
      Flat = True
      ParentShowHint = False
      ShowHint = True
      OnClick = SpeedButtonZoomInClick
    end
  end
  object OrderDataSet: TClientDataSet
    Aggregates = <>
    Params = <>
    AfterScroll = OrderDataSetAfterScroll
    Left = 336
    Top = 216
    object OrderDataSetID: TIntegerField
      FieldName = 'ID'
    end
    object OrderDataSetCOUNTRY: TStringField
      FieldName = 'COUNTRY'
    end
    object OrderDataSetCITY: TStringField
      FieldName = 'CITY'
    end
    object OrderDataSetCUSTOMER: TStringField
      FieldName = 'CUSTOMER'
      Size = 40
    end
    object OrderDataSetAMOUNT: TCurrencyField
      FieldName = 'AMOUNT'
    end
    object OrderDataSetORDERED: TDateField
      FieldName = 'ORDERED'
    end
  end
  object OrderDataSource: TDataSource
    DataSet = OrderDataSet
    Left = 336
    Top = 280
  end
  object GroupImageCollection: TImageCollection
    Images = <>
    Left = 336
    Top = 136
  end
  object GroupImageList: TVirtualImageList
    Images = <>
    ImageCollection = GroupImageCollection
    Left = 440
    Top = 136
  end
end
