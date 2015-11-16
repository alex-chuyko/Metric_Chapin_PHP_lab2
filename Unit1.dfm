object Form1: TForm1
  Left = 466
  Top = 58
  Width = 810
  Height = 912
  Caption = #1052#1077#1090#1088#1080#1082#1072' '#1063#1077#1087#1080#1085#1072' PHP ('#1063#1091#1081#1082#1086' '#1040'.'#1057'. 451002)'
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  PixelsPerInch = 96
  TextHeight = 13
  object mmoInput: TMemo
    Left = 8
    Top = 8
    Width = 673
    Height = 561
    ScrollBars = ssVertical
    TabOrder = 0
  end
  object btnRun: TButton
    Left = 696
    Top = 8
    Width = 75
    Height = 25
    Caption = 'Run'
    TabOrder = 1
    OnClick = btnRunClick
  end
  object mmoOutput: TMemo
    Left = 8
    Top = 579
    Width = 673
    Height = 265
    ScrollBars = ssVertical
    TabOrder = 2
  end
end
