unit uPrincipal;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.StdCtrls,
  FMX.Controls.Presentation, FMX.Edit, FMX.Layouts,
  System.Generics.Collections, FMX.Objects, FMX.Ani, FMX.Memo.Types, FMX.ScrollBox, FMX.Memo, FMX.ListBox;

type
  TFrmGraph = class(TForm)
    btnShowGraph: TButton;
    lyChart: TLayout;
    Label1: TLabel;
    Memo1: TMemo;
    cbStyle: TComboBox;
    Label2: TLabel;
    edtDNR: TEdit;
    Label3: TLabel;
    edtTO: TEdit;
    Label4: TLabel;
    swPercent: TSwitch;
    Label5: TLabel;
    swValues: TSwitch;
    Label6: TLabel;
    swHint: TSwitch;
    Label7: TLabel;
    Label8: TLabel;
    swFullHint: TSwitch;
    Label9: TLabel;
    swAnimate: TSwitch;
    Label10: TLabel;
    edtFontSize: TEdit;
    Label11: TLabel;
    Label12: TLabel;
    swBold: TSwitch;
    Label13: TLabel;
    swBarTitle: TSwitch;
    Label14: TLabel;
    swBarLegend: TSwitch;
    edtBarTitle: TEdit;
    Label15: TLabel;
    Label16: TLabel;
    edtDuration: TEdit;
    procedure btnShowGraphClick(Sender: TObject);
    procedure cbStyleChange(Sender: TObject);
  private
    procedure ShowGraph;
    { Private declarations }
  public
    { Public declarations }
  end;

var
  FrmGraph: TFrmGraph;

implementation

{$R *.fmx}

uses Chart4Delphi;

procedure TFrmGraph.btnShowGraphClick(Sender: TObject);
begin
   TThread.CreateAnonymousThread(procedure
   begin
      TThread.Synchronize(nil, ShowGraph);
   end).Start;
end;

procedure TFrmGraph.ShowGraph;
var
   errorMsg: string;
   pieChart: TChart4Delphi;
begin
   pieChart := nil;

   case cbStyle.ItemIndex of
      0: pieChart := TChart4Delphi.Create(lyChart, TChartLayoutType.ctlPie);
      1: pieChart := TChart4Delphi.Create(lyChart, TChartLayoutType.ctlDonuts);
      2: pieChart := TChart4Delphi.Create(lyChart, TChartLayoutType.ctlBars);
      3: pieChart := TChart4Delphi.Create(lyChart, TChartLayoutType.ctlLines);
   end;

   if (swBold.IsChecked) then
      pieChart.TextStyle := [TFontStyle.fsBold]
   else
      pieChart.TextStyle := [];

   edtFontSize.Text := IntToStr(StrToIntDef(edtFontSize.Text,12));
   edtTO.Text       := FloatToStr(StrToFloatDef(edtTO.Text,0.1));
   edtDuration.Text := FloatToStr(StrToFloatDef(edtDuration.Text,0.8));

   pieChart.TextFontSize      := StrToInt(edtFontSize.Text);
   pieChart.TextOffset        := StrToFloat(edtTO.Text);
   pieChart.FormatValues      := '##,#0';
   pieChart.ShowPercent       := swPercent.IsChecked;
   pieChart.ShowValues        := swValues.IsChecked;
   pieChart.ShowHint          := swHint.IsChecked;
   pieChart.FullHint          := swFullHint.IsChecked;
   pieChart.Animate           := swAnimate.IsChecked;
   pieChart.AnimationDuration := StrToFloat(edtDuration.Text);

   if (cbStyle.ItemIndex in [0,1]) then
   begin
      if (cbStyle.ItemIndex = 1) then
      begin
         pieChart.DonutsCenterRadius := StrToIntDef(edtDNR.Text,180);
      end;

      pieChart.SetColors(
         [
            TAlphaColors.Green,
            TAlphaColors.Yellow,
            TAlphaColors.Orange,
            TAlphaColors.Lightgreen,
            TAlphaColors.Red,
            TAlphaColors.Black
         ],
         [
            TAlphaColors.White,
            TAlphaColors.Black,
            TAlphaColors.White,
            TAlphaColors.Black,
            TAlphaColors.White,
            TAlphaColors.White
         ]
      );
   end
   else if (cbStyle.ItemIndex = 2) then
   begin
      pieChart.SetColors([TAlphaColors.Green],[TAlphaColors.Black]);
      pieChart.BarTitle      := edtBarTitle.Text;
      pieChart.ShowBarTitle  := swBarTitle.IsChecked;
      pieChart.ShowBarLegend := swBarLegend.IsChecked;
   end
   else if (cbStyle.ItemIndex = 3) then
   begin
      pieChart.SetColors([TAlphaColors.Green],[TAlphaColors.Black]);
      pieChart.ColorLinePoint    := TAlphaColors.Black;
      pieChart.LineTickness      := 3;
      pieChart.LinePointDiameter := 8;
   end;

   pieChart.DrawGraph(Memo1.Text, errorMsg);

   if (errorMsg <> EmptyStr) then
      ShowMessage(errorMsg);
end;

procedure TFrmGraph.cbStyleChange(Sender: TObject);
begin
   edtBarTitle.Enabled := False;
   edtBarTitle.Text    := EmptyStr;
   if (cbStyle.ItemIndex = 1) then
   begin
      edtDNR.Enabled := True;
      edtDNR.Text    := '180';
      edtTO.Text     := '0,17';
   end
   else
   begin
      edtDNR.Enabled := False;
      edtDNR.Text    := EmptyStr;
      if (cbStyle.ItemIndex = 3) then
         edtTO.Text := '0,15'
      else
      begin
         edtBarTitle.Enabled := True;
         edtBarTitle.Text    := 'Bar Graphic';
         edtTO.Text          := '0,1';
      end;
   end;
end;

end.
