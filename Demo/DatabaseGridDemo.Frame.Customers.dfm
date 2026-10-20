object FrameCustomers: TFrameCustomers
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
  object DatabaseGrid: TDatabaseGrid
    Left = 0
    Top = 0
    Width = 900
    Height = 576
    Margins.Right = 5
    Align = alClient
    ColumnFilter.Visible = True
    Columns = <
      item
        Alignment = taRightJustify
        FieldName = 'ID'
        Footer.DisplayFormat = '#,##0 "rows"'
        Footer.ValueType = fvCount
        Options = [coReadOnly]
        Title.Alignment = taRightJustify
        Title.Caption = 'Id'
        Width = 70
      end
      item
        FieldName = 'NAME'
        Options = [coAutoFit]
        Title.Caption = 'Name'
        Title.Hint = 'Customer name'
        Width = 220
      end
      item
        FieldName = 'CITY'
        Title.Caption = 'City'
        Width = 140
      end
      item
        Alignment = taRightJustify
        FieldName = 'AMOUNT'
        Footer.Alignment = taRightJustify
        Footer.ValueType = fvSum
        Options = [coAutoFit]
        Title.Alignment = taRightJustify
        Title.Caption = 'Amount'
        Width = 110
      end
      item
        Alignment = taCenter
        FieldName = 'CREATED'
        Options = [coAutoFit]
        Title.Alignment = taCenter
        Title.Caption = 'Created'
        Width = 110
      end
      item
        Alignment = taCenter
        FieldName = 'ACTIVE'
        Options = [coFilterValueList]
        Title.Alignment = taCenter
        Title.Caption = 'Active'
        Width = 60
      end
      item
        FieldName = 'COUNTRY'
        Title.Caption = 'Country'
        Width = 110
      end
      item
        Editor = ekMemo
        FieldName = 'NOTES'
        Options = [coAutoFit]
        Title.Caption = 'Notes'
        Width = 160
      end
      item
        Alignment = taCenter
        FieldName = 'PRIORITY'
        Images = StatusImageList
        Options = [coFilterValueList]
        Title.Alignment = taCenter
        Title.Hint = 'Priority'
        Title.ImageIndex = 3
        Width = 44
      end>
    DataSource = DataSource
    Footer.VerticalLines = False
    Footer.Visible = True
    Indicator.Options = [ioShowRowIndicator, ioShowCheckBox]
    Indicator.TitleMenu.Commands.Export.Visible = True
    OnDrawColumnCell = DatabaseGridDrawColumnCell
    OnIndicatorTitleMenuPopup = DatabaseGridIndicatorTitleMenuPopup
    OnRefresh = DatabaseGridRefresh
    OnScroll = DatabaseGridScroll
    OnSelectionChanged = DatabaseGridSelectionChanged
    OnZoomChange = DatabaseGridZoomChange
    Options = [dgoAlwaysShowSelection, dgoAutoFitColumns, dgoColumnResize, dgoEditing, dgoExtendVerticalLines, dgoFadeExtendedLines, dgoMiddleClickAutoscroll, dgoMultiSelect, dgoShowHints, dgoSortMarking, dgoTextOverflow]
    ParentShowHint = False
    SearchPanel.Items = <
      item
        ItemIndex = 0
        Items.Strings = (
          'All cities'
          'Helsinki'
          'Tampere'
          'Turku'
          'Oulu'
          'Kuopio')
        Name = 'City'
        Width = 120
        OnChange = DatabaseGridSearchPanelItemChange
      end>
    SearchPanel.Options = [spoClearResetsItems, spoFilterOnTyping, spoHighlightFiltering, spoHighlightMatches, spoShowRefreshButton]
    SearchPanel.Visible = True
    ShowHint = True
    TabOrder = 0
    Title.Images = StatusImageList
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
    TabOrder = 1
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
  object DataSource: TDataSource
    DataSet = ClientDataSet
    Left = 440
    Top = 280
  end
  object ClientDataSet: TClientDataSet
    Aggregates = <>
    Params = <>
    Left = 440
    Top = 216
    object ClientDataSetID: TIntegerField
      FieldName = 'ID'
    end
    object ClientDataSetNAME: TStringField
      FieldName = 'NAME'
      Size = 60
    end
    object ClientDataSetCITY: TStringField
      FieldName = 'CITY'
    end
    object ClientDataSetAMOUNT: TCurrencyField
      FieldName = 'AMOUNT'
    end
    object ClientDataSetCREATED: TDateField
      FieldName = 'CREATED'
    end
    object ClientDataSetACTIVE: TBooleanField
      FieldName = 'ACTIVE'
    end
    object ClientDataSetCOUNTRYID: TIntegerField
      FieldName = 'COUNTRYID'
    end
    object ClientDataSetNOTES: TMemoField
      FieldName = 'NOTES'
      BlobType = ftMemo
    end
    object ClientDataSetPRIORITY: TIntegerField
      FieldName = 'PRIORITY'
    end
    object ClientDataSetCOUNTRY: TStringField
      FieldKind = fkLookup
      FieldName = 'COUNTRY'
      LookupDataSet = CountryDataSet
      LookupKeyFields = 'ID'
      LookupResultField = 'NAME'
      KeyFields = 'COUNTRYID'
      LookupCache = True
      Lookup = True
    end
  end
  object CountryDataSet: TClientDataSet
    Aggregates = <>
    Params = <>
    Left = 336
    Top = 216
    object CountryDataSetID: TIntegerField
      FieldName = 'ID'
    end
    object CountryDataSetNAME: TStringField
      FieldName = 'NAME'
    end
  end
  object StatusImageCollection: TImageCollection
    Images = <>
    Left = 336
    Top = 136
  end
  object StatusImageList: TVirtualImageList
    Images = <>
    ImageCollection = StatusImageCollection
    Left = 440
    Top = 136
  end
end
