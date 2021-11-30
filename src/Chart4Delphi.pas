unit Chart4Delphi;

interface

uses
   FMX.Layouts,
   FMX.Objects,
   FMX.Types,
   FMX.Controls,
   FMX.Styles.Objects,
   FMX.Graphics,
   FMX.Forms,
   FMX.Ani,
   System.UITypes,
   System.JSON,
   System.SysUtils,
   System.Types,
   System.Generics.Collections,
   System.Classes,
   Winapi.Windows,
   RegularExpressions;

type
   {$SCOPEDENUMS ON}
   TChartLayoutType = (ctlPie, ctlDonuts, ctlLines, ctlBars);
   {$SCOPEDENUMS OFF}

type
   TChart4Delphi = class
      procedure AnimationFinish(Sender: TObject);
   private
      Animation: TFloatAnimation;
      StyleObj : TStyleObject;

      FLayout            : TLayout;
      FChartType         : TChartLayoutType;
      FArrValues         : TJSONArray;
      FColorsGraph       : TArray<TAlphaColor>;
      FColorsText        : TArray<TAlphaColor>;
      FTextFontSize      : Integer;
      FTextStyle         : TFontStyles;
      FDonutsCenterRadius: Integer;
      FLinePointDiameter : Integer;
      FLineTickness      : Integer;
      FTextOffset        : Real;
      FAnimationDuration : Single;
      FFormatValues      : string;
      FBarTitle          : string;
      FAnimate           : Boolean;
      FShowHint          : Boolean;
      FFullHint          : Boolean;
      FHintFieldName     : Boolean;
      FShowValues        : Boolean;
      FShowPercent       : Boolean;
      FShowBarTitle      : Boolean;
      FShowBarLegend     : Boolean;
      FColorLinePoint    : TAlphaColor;

      procedure SetTextOffset(Value: Real);
      procedure SetDonutsTickness(Value: Integer);
      procedure SetLinePointDiameter(Value: Integer);
      procedure SetLineTickness(Value: Integer);
      function DrawCircularGraph: String;
      function DrawLineGraph: String;
      function DrawBarGraph: String;
   public
      constructor Create(Layout: TLayout; ChartType: TChartLayoutType);

      procedure Clear;
      procedure SetColors(ColorsGraph, ColorsText: Array of TAlphaColor);
      procedure DrawGraph(JsonString: string; var ErrorMsg: string);

      property ShowPercent       : Boolean     read FShowPercent        write FShowPercent;
      property ShowValues        : Boolean     read FShowValues         write FShowValues;
      property ShowHint          : Boolean     read FShowHint           write FShowHint;
      property HintFieldName     : Boolean     read FHintFieldName      write FHintFieldName;
      property ShowBarTitle      : Boolean     read FShowBarTitle       write FShowBarTitle;
      property ShowBarLegend     : Boolean     read FShowBarLegend      write FShowBarLegend;
      property FullHint          : Boolean     read FFullHint           write FFullHint;
      property Animate           : Boolean     read FAnimate            write FAnimate;
      property TextOffset        : Real        read FTextOffset         write SetTextOffset;
      property AnimationDuration : Single      read FAnimationDuration  write FAnimationDuration;
      property DonutsCenterRadius: Integer     read FDonutsCenterRadius write SetDonutsTickness;
      property TextFontSize      : Integer     read FTextFontSize       write FTextFontSize;
      property LinePointDiameter : Integer     read FLinePointDiameter  write SetLinePointDiameter;
      property LineTickness      : Integer     read FLineTickness       write SetLineTickness;
      property FormatValues      : string      read FFormatValues       write FFormatValues;
      property BarTitle          : string      read FBarTitle           write FBarTitle;
      property TextStyle         : TFontStyles read FTextStyle          write FTextStyle;
      property ColorLinePoint    : TAlphaColor read FColorLinePoint     write FColorLinePoint;
   end;

implementation

uses
  FMX.Dialogs;

{ TChart4Delphi }

constructor TChart4Delphi.Create(Layout: TLayout; ChartType: TChartLayoutType);
begin
   FLayout              := Layout;
   FChartType           := ChartType;
   ShowPercent          := True;
   ShowValues           := True;
   ShowHint             := True;
   FHintFieldName       := True;
   FShowBarTitle        := True;
   FShowBarLegend       := True;
   FFullHint            := True;
   FAnimate             := True;
   FDonutsCenterRadius  := 200;
   FTextStyle           := [TFontStyle.fsBold];
   FTextFontSize        := 12;
   FFormatValues        := '';
   FColorLinePoint      := TAlphaColors.Black;
   FLinePointDiameter   := 8;
   FLineTickness        := 2;
   FAnimationDuration   := 0.8;
   FBarTitle            := 'Bar Graphic';

   if (ChartType in [TChartLayoutType.ctlPie, TChartLayoutType.ctlDonuts]) then
      FTextOffset := 0.2
   else
      FTextOffset := 0.15;

   FColorsGraph := TArray<TAlphaColor>.Create(
      TAlphaColors.Green,
      TAlphaColors.Orange,
      TAlphaColors.Beige,
      TAlphaColors.Red,
      TAlphaColors.Blue,
      TAlphaColors.Magenta,
      TAlphaColors.Brown,
      TAlphaColors.Gold,
      TAlphaColors.Grey,
      TAlphaColors.Lightgreen,
      TAlphaColors.Black,
      TAlphaColors.Pink);

   FColorsText := TArray<TAlphaColor>.Create(
      TAlphaColors.White,
      TAlphaColors.White,
      TAlphaColors.White,
      TAlphaColors.White,
      TAlphaColors.White,
      TAlphaColors.White,
      TAlphaColors.White,
      TAlphaColors.White,
      TAlphaColors.White,
      TAlphaColors.White,
      TAlphaColors.White,
      TAlphaColors.White);
end;

procedure TChart4Delphi.AnimationFinish(Sender: TObject);
begin
   TAnimator.AnimateFloat(StyleObj, 'Opacity', 1, 0.2, TAnimationType.In, TInterpolationType.Linear);
end;

procedure TChart4Delphi.Clear;
var
   fmxObj: TFmxObject;
begin
   while FLayout.ChildrenCount > 0 do
      for fmxObj in FLayout.Children do
      begin
         FLayout.RemoveObject(fmxObj);
         fmxObj.Free;
      end;

   FLayout.Padding.Rect := TRect.Create(0,0,0,0);
end;

procedure TChart4Delphi.DrawGraph(JsonString: string; var ErrorMsg: string);
begin
   ErrorMsg := EmptyStr;
   Clear;

   try
      FArrValues := TJSONObject.ParseJSONValue(TEncoding.UTF8.GetBytes(jsonString), 0) as TJSONArray;
   except
      ErrorMsg := 'Invalid JSON array';
      Exit;
   end;

   if FArrValues = nil then
   begin
      ErrorMsg := 'Invalid JSON array';
      Exit;
   end;

   case FChartType of
      TChartLayoutType.ctlPie   : ErrorMsg := DrawCircularGraph;
      TChartLayoutType.ctlDonuts: ErrorMsg := DrawCircularGraph;
      TChartLayoutType.ctlLines : ErrorMsg := DrawLineGraph;
      TChartLayoutType.ctlBars  : ErrorMsg := DrawBarGraph;
   end;
end;

function TChart4Delphi.DrawCircularGraph: String;
var
   PieColor, PieMask: TPie;
   Circle: TCircle;
   LayoutText: TLayout;
   textoGraph: TText;
   I, idColorG, idColorT: Integer;
   serieValue, jsonV, totValue: Real;
   startAng, endAng, midPoint: Single;
   Leg, txtHint: string;
   ArrAngs: Array of Single;
begin
   Result := EmptyStr;
   try
      FLayout.Padding.Rect := TRect.Create(5,5,5,5);

      PieMask              := TPie.Create(FLayout.Owner);
      PieMask.Parent       := FLayout;
      PieMask.StartAngle   := -90;
      PieMask.EndAngle     := 270;
      PieMask.Stroke.Kind  := TBrushKind.None;
      PieMask.Align        := TAlignLayout.Contents;
      PieMask.Fill.Assign((FLayout.Owner as TForm).Fill);
      PieMask.Stroke.Color := PieMask.Fill.Color;

      if (FChartType = TChartLayoutType.ctlDonuts) then
      begin
         Circle             := TCircle.Create(FLayout.Owner);
         Circle.Parent      := PieMask;
         Circle.Size.Width  := FDonutsCenterRadius;
         Circle.Size.Height := FDonutsCenterRadius;
         Circle.Align       := TAlignLayout.Center;
         Circle.Fill.Assign((FLayout.Owner as TForm).Fill);
         Circle.Stroke.Kind := TBrushKind.None;
      end;

      Animation               := TFloatAnimation.Create(FLayout.Owner);
      Animation.Parent        := PieMask;
      Animation.Duration      := FAnimationDuration;
      Animation.Interpolation := TInterpolationType.Quartic;
      Animation.PropertyName  := 'StartAngle';
      Animation.StartValue    := -90;
      Animation.StopValue     := PieMask.EndAngle;
      Animation.OnFinish      := AnimationFinish;

      StyleObj             := TStyleObject.Create(FLayout.Owner);
      StyleObj.Parent      := FLayout;
      StyleObj.Size.Width  := 180;
      StyleObj.Size.Height := 180;
      StyleObj.Opacity     := 0;

      FLayout.RemoveObject(PieMask);
      FLayout.RemoveObject(StyleObj);

      SetLength(ArrAngs,FArrValues.Count);

      totValue := 0;
      for I := 0 to Pred(FArrValues.Count) do
         totValue := totValue + FArrValues.Items[I].GetValue<double>('value');

      startAng := -90;
      idColorG := 0;
      idColorT := 0;
      for I := 0 to Pred(FArrValues.Count) do
      begin
         jsonV      := FArrValues.Items[I].GetValue<double>('value');
         serieValue := (jsonV / totValue) * 360;

         PieColor            := TPie.Create(nil);
         PieColor.StartAngle := startAng;
         PieColor.EndAngle   := startAng + serieValue;

         midPoint := startAng + serieValue * 0.5;
         startAng := PieColor.EndAngle;

         PieColor.Fill.Color  := FColorsGraph[idColorG];
         PieColor.Stroke.Kind := TBrushKind.None;
         FLayout.AddObject(PieColor);
         PieColor.Align       := TAlignLayout.Client;

         Leg := EmptyStr;
         if (ShowPercent) then
            Leg := IntToStr(Round((jsonV / totValue) * 100)) + '%';

         if (ShowValues) then
         begin
            if (FFormatValues <> '') then
               if (Leg <> EmptyStr) then
                  Leg := Leg + LineFeed + FormatFloat(FFormatValues,FArrValues.Items[I].GetValue<double>('value'))
               else
                  Leg := FormatFloat(FFormatValues,FArrValues.Items[I].GetValue<double>('value'))
            else
               if (Leg <> EmptyStr) then
                  Leg := Leg + LineFeed + FArrValues.Items[I].GetValue<string>('value')
               else
                  Leg := FArrValues.Items[I].GetValue<string>('value');
         end;

         if (FShowHint) and (TOSVersion.Platform = TOSVersion.TPlatform.pfWindows) then
         begin
            if (FHintFieldName) then
               txtHint := FArrValues.Items[I].GetValue<string>('field')
            else if not(FFullHint) then
               txtHint := Leg
            else
            begin
               if (FFormatValues <> '') then
                  txtHint := IntToStr(Round((jsonV / totValue) * 100)) + '%' + LineFeed + FormatFloat(FFormatValues,FArrValues.Items[I].GetValue<double>('value'))
               else
                  txtHint := IntToStr(Round((jsonV / totValue) * 100)) + '%' + LineFeed + FArrValues.Items[I].GetValue<string>('value');
            end;
            PieColor.Hint     := txtHint;
            PieColor.ShowHint := True;
         end;

         if (idColorG < Pred(Length(FColorsGraph))) then
            Inc(idColorG)
         else
            idColorG := 0;

         if (Leg <> EmptyStr) then
         begin
            textoGraph         := TText.Create(nil);
            textoGraph.HitTest := False;
            textoGraph.Locked  := True;

            textoGraph.TextSettings.Font.Size  := FTextFontSize;
            textoGraph.TextSettings.Font.Style := TextStyle;
            textoGraph.TextSettings.FontColor  := FColorsText[idColorT];

            LayoutText := TLayout.Create(nil);
            LayoutText.RotationCenter.Point := TPointF.Zero;
            StyleObj.AddObject(LayoutText);

            with FLayout.LocalRect.CenterPoint do
               LayoutText.SetBounds(X,Y,0,0);

            LayoutText.RotationAngle  := midPoint;
            textoGraph.Align          := TAlignLayout.None;
            textoGraph.Width          := 80;
            textoGraph.Text           := Leg;
            LayoutText.Width          := ((FLayout.LocalRect.BottomRight.Length * FTextOffset) + (textoGraph.LocalRect.BottomRight.Length * 0.5));
            StyleObj.AddObject(textoGraph);
            textoGraph.Position.Point := StyleObj.AbsoluteToLocal(LayoutText.AbsoluteRect.BottomRight) - textoGraph.LocalRect.CenterPoint;

            if (idColorT < Pred(Length(FColorsText))) then
               Inc(idColorT)
            else
               idColorT := 0;
         end;
      end;

      PieMask.StartAngle := -90;
      PieMask.EndAngle   := 270;
      FLayout.AddObject(PieMask);
      FLayout.AddObject(StyleObj);

      if (FAnimate) then
         Animation.Start
      else
         PieMask.StartAngle := PieMask.EndAngle;
   except on Ex: Exception do
      Result := Ex.Message;
   end;
end;

function TChart4Delphi.DrawLineGraph: String;
var
   I: Integer;
   SpacePoints: Integer;
   BarCount: Integer;
   CountComp: Integer;
   MaxValue: Double;
   Line: TLine;
   procedure DrawLineBetweenPoints(L: TLine; p1, p2: TPointF);
   begin
       L.LineType         := TLineType.Diagonal;
       L.RotationCenter.X := 0.0;
       L.RotationCenter.Y := 0.0;

       if (p2.X >= p1.X) then
       begin
           if (p2.Y > p1.Y) then begin
               L.RotationAngle := 0;
               L.Position.X    := p1.X;
               L.Width         := p2.X - p1.X;
               L.Position.Y    := p1.Y;
               L.Height        := p2.Y - p1.Y;
           end
           else
           begin
               L.RotationAngle := -90;
               L.Position.X    := p1.X;
               L.Width         := p1.Y - p2.Y;
               L.Position.Y    := p1.Y;
               L.Height        := p2.X - p1.X;
           end;
       end
       else
       begin
           if (p1.Y > p2.Y) then
           begin
               L.RotationAngle := 0;
               L.Position.X    := p2.X;
               L.Width         := p1.X - p2.X;
               L.Position.Y    := p2.Y;
               L.Height        := p1.Y - p2.Y;
           end
           else
           begin
               L.RotationAngle := -90;
               L.Position.X    := p2.X;
               L.Width         := p2.Y - p1.Y;
               L.Position.Y    := p2.Y;
               L.Height        := p1.X - p2.X;
           end;
       end;

       if (L.Height < 0.01) then
           L.Height := 0.1;
       if (L.Width < 0.01) then
           L.Width := 0.1;
   end;
   procedure AddLine(vlFrom, vlTo: Double);
   var
       ptFrom, ptTo: TPointF;
   begin
      ptFrom.Y := (1 - (vlFrom / MaxValue)) * FLayout.Height;
      ptFrom.X := CountComp * SpacePoints;

      ptTo.Y := (1 - (vlTo / MaxValue)) * FLayout.Height;
      ptTo.X := (CountComp + 1) * SpacePoints;

      Line                  := TLine.Create(FLayout);
      Line.Parent           := FLayout;
      Line.Stroke.Kind      := TBrushKind.Solid;
      Line.Stroke.Color     := FColorsGraph[0];
      Line.Stroke.Thickness := FLineTickness;

      if (FAnimate) then
      begin
         Line.Opacity := 0;
         TAnimator.AnimateFloatDelay(Line, 'Opacity', 1, 0.2, (CountComp * 0.1) + FAnimationDuration,
            TAnimationType.InOut, TInterpolationType.Circular);
      end;

      DrawLineBetweenPoints(Line, ptFrom, ptTo);
      Inc(CountComp);
   end;
   procedure AddLinePoint(vl: double; field: string);
   var
      porc      : Double;
      Leg       : string;
      LineCircle: TCircle;
      textoGraph: TText;
   begin
      porc := (1 - (vl / MaxValue)) * FLayout.Height;

      LineCircle             := TCircle.Create(FLayout);
      LineCircle.Parent      := FLayout;
      LineCircle.Stroke.Kind := TBrushKind.None;
      LineCircle.Fill.Kind   := TBrushKind.Solid;
      LineCircle.Fill.Color  := FColorLinePoint;
      LineCircle.Width       := FLinePointDiameter;
      LineCircle.Height      := FLinePointDiameter;

      LineCircle.Position.X := CountComp * SpacePoints - Trunc(LineCircle.Width / 2);
      LineCircle.Position.Y := FLayout.Height - 35;

      if (FAnimate) then
      begin
         TAnimator.AnimateFloat(LineCircle, 'Position.Y', porc - Trunc(LineCircle.Width / 2), FAnimationDuration,
            TAnimationType.InOut, TInterpolationType.Circular);
      end
      else
         LineCircle.Position.Y := porc - Trunc(LineCircle.Width / 2);

      Leg := EmptyStr;
      if (FShowValues) then
      begin
         if (FFormatValues <> '') then
            if (Leg <> EmptyStr) then
               Leg := Leg + LineFeed + FormatFloat(FFormatValues,vl)
            else
               Leg := FormatFloat(FFormatValues,vl)
         else
            if (Leg <> EmptyStr) then
               Leg := Leg + LineFeed + vl.ToString
            else
               Leg := vl.ToString;
      end;

      if (FShowHint) and (TOSVersion.Platform = TOSVersion.TPlatform.pfWindows) then
      begin
         if (FHintFieldName) then
            LineCircle.Hint := field
         else
            LineCircle.Hint := Leg;
         LineCircle.ShowHint := True;
      end;

      if (Leg <> EmptyStr) then
      begin
         textoGraph := TText.Create(LineCircle);
         textoGraph.Parent := LineCircle;

         if (FFormatValues <> '') then
            textoGraph.Text := FormatFloat(FFormatValues, vl)
         else
            textoGraph.Text := vl.ToString;

         textoGraph.Opacity                := 0;
         textoGraph.Align                  := TAlignLayout.Center;
         textoGraph.Margins.Bottom         := 200 * FTextOffset;
         textoGraph.TextSettings.HorzAlign := TTextAlign.Center;

         textoGraph.TextSettings.Font.Style := FTextStyle;
         textoGraph.TextSettings.Font.Size  := FTextFontSize;
         textoGraph.TextSettings.FontColor  := FColorsText[0];

         TAnimator.AnimateFloatDelay(textoGraph, 'Opacity', 1, 0.2, FAnimationDuration,
            TAnimationType.In, TInterpolationType.Linear)
      end;

      Inc(CountComp);
   end;
begin
   Result := EmptyStr;
   try
      BarCount := FArrValues.Count;
      MaxValue := 0;

      for I := FArrValues.Count - 1 downto 0 do
         if MaxValue < FArrValues.Items[I].GetValue<double>('value') then
            MaxValue := FArrValues.Items[I].GetValue<double>('value');

      MaxValue := MaxValue * 1.1;

      SpacePoints := Trunc(FLayout.Width / (BarCount - 1));

      CountComp := 0;
      for I := 0 to FArrValues.Count - 2 do
         AddLine(FArrValues.Items[I].GetValue<double>('value'), FArrValues.Items[I+1].GetValue<double>('value'));

      CountComp := 0;
      for I := 0 to FArrValues.Count - 1 do
         AddLinePoint(FArrValues.Items[I].GetValue<double>('value'), FArrValues.Items[I].GetValue<string>('field'));
   except on Ex: Exception do
      Result := Ex.Message;
   end;
end;

function TChart4Delphi.DrawBarGraph: String;
var
   LayoutTopo: TLayout;
   LineBase: TLine;
   TextTitulo: TText;
   HrScroll: THorzScrollBox;
   rFundo, rBar: TRectangle;
   I, J : Integer;
   maxValue, percSerie: Real;
   txtHint: string;
   procedure Serie(SerieValue: Real; Texto: String);
   var
      textoGraph, textBottom: TText;
      Leg: string;
   begin
      Leg := EmptyStr;
      if (ShowPercent) then
         Leg := IntToStr(Round((SerieValue / maxValue) * 100)) + '%';

      if (ShowValues) then
      begin
         if (FFormatValues <> '') then
            if (Leg <> EmptyStr) then
               Leg := Leg + LineFeed + FormatFloat(FFormatValues,SerieValue)
            else
               Leg := FormatFloat(FFormatValues,SerieValue)
         else
            if (Leg <> EmptyStr) then
               Leg := Leg + LineFeed + FloatToStr(SerieValue)
            else
               Leg := FloatToStr(SerieValue);
      end;

      rFundo               := TRectangle.Create(HrScroll);
      rFundo.Parent        := HrScroll;
      rFundo.Align         := TAlignLayout.Left;
      rFundo.Margins.Left  := 5;
      rFundo.Margins.Right := 5;
      rFundo.Height        := HrScroll.Height;
      rFundo.Width         := HrScroll.Width  / FArrValues.Count - 10;
      rFundo.Stroke.Kind   := TBrushKind.None;

      rBar              := TRectangle.Create(rFundo);
      rBar.Align        := TAlignLayout.Bottom;
      rBar.Fill.Color   := FColorsGraph[0];
      rBar.Size.Height  :=  0;
      rBar.ClipChildren := True;
      rBar.Parent       := rFundo;
      rBar.Stroke.Kind  := TBrushKind.None;

      percSerie := ((SerieValue * 100) / maxValue);
      percSerie := (percSerie * rFundo.Height) / 100;

      if (FShowHint) and (TOSVersion.Platform = TOSVersion.TPlatform.pfWindows) then
      begin
         if (FHintFieldName) then
            txtHint := Texto
         else if not(FFullHint) then
            txtHint := Leg
         else
         begin
            if (FFormatValues <> '') then
               txtHint := FormatFloat(FFormatValues,SerieValue)
            else
               txtHint := FloatToStr(SerieValue);
         end;
         rBar.Hint     := txtHint;
         rBar.ShowHint := True;
      end;

      if (Leg <> EmptyStr) then
      begin
         textoGraph := TText.Create(rFundo);
         textoGraph.Parent := rFundo;

         textoGraph.Opacity                := 0;
         textoGraph.Text                   := Leg;
         textoGraph.Height                 := 30;
         textoGraph.Width                  := rBar.Width;
         textoGraph.Position.X             := 0;
         textoGraph.Position.Y             := (rFundo.Height - percSerie - textoGraph.Height) - (30 * FTextOffset);
         textoGraph.TextSettings.HorzAlign := TTextAlign.Center;
         textoGraph.TextSettings.VertAlign := TTextAlign.Trailing;

         textoGraph.TextSettings.Font.Style := FTextStyle;
         textoGraph.TextSettings.Font.Size  := FTextFontSize;
         textoGraph.TextSettings.FontColor  := FColorsText[0];

         if (textoGraph.Position.Y < -textoGraph.Height) then
            textoGraph.Position.Y := (30 * FTextOffset)
         else if (textoGraph.Position.Y < 0) then
            textoGraph.Position.Y := 5;

         TAnimator.AnimateFloatDelay(textoGraph, 'Opacity', 1, 0.2, FAnimationDuration,
            TAnimationType.In, TInterpolationType.Linear);
      end;

      if (FShowBarLegend) then
      begin
         textBottom := TText.Create(FLayout);
         textBottom.Parent := FLayout;

         textBottom.Text                   := Texto;
         textBottom.Height                 := 20;
         textBottom.Width                  := rBar.Width;
         textBottom.Position.X             := (J * rBar.Width) + (10 * (J + 1));
         textBottom.Position.Y             := FLayout.Height - LineBase.Size.Height;
         textBottom.TextSettings.HorzAlign := TTextAlign.Center;
         textBottom.TextSettings.VertAlign := TTextAlign.Leading;
         textBottom.Anchors                := [TAnchorKind.akBottom];

         textBottom.TextSettings.Font.Style := FTextStyle;
         textBottom.TextSettings.Font.Size  := FTextFontSize;
         textBottom.TextSettings.FontColor  := FColorsText[0];
      end;

      TAnimator.AnimateFloat(rBar, 'Height', percSerie, FAnimationDuration,
         TAnimationType.In,TInterpolationType.Cubic);
   end;
begin
   if (FShowBarTitle) then
   begin
      LayoutTopo             := TLayout.Create(FLayout);
      LayoutTopo.Align       := TAlignLayout.Top;
      LayoutTopo.Size.Height := 30;
      LayoutTopo.Parent      := FLayout;

      TextTitulo        := TText.Create(LayoutTopo);
      TextTitulo.Align  := TAlignLayout.Client;
      TextTitulo.Parent := LayoutTopo;
      TextTitulo.Text   := FBarTitle;
   end;

   LineBase             := TLine.Create(FLayout);
   LineBase.LineType    := TLineType.Top;
   LineBase.Size.Height := 30;
   LineBase.Align       := TAlignLayout.Bottom;
   LineBase.Parent      := FLayout;

   HrScroll                := THorzScrollBox.Create(FLayout);
   HrScroll.Parent         := FLayout;
   HrScroll.Align          := TAlignLayout.Client;
   HrScroll.Margins.Top    := 5;
   HrScroll.Margins.Left   := 5;
   HrScroll.Margins.Right  := 5;
   HrScroll.Margins.Bottom := 0;

   maxValue := 0;
   for I := 0 to Pred(FArrValues.Count) do
      if (FArrValues.Items[I].GetValue<double>('value') > maxValue) then
         maxValue := FArrValues.Items[I].GetValue<double>('value');

   J := 0;
   for I := 0 to FArrValues.Count - 1 do
   begin
      Serie(FArrValues.Items[I].GetValue<double>('value'),FArrValues.Items[I].GetValue<string>('field'));
      Inc(J);
   end;
end;

procedure TChart4Delphi.SetColors(ColorsGraph, ColorsText: Array of TAlphaColor);
var
   I: Integer;
begin
   if (Length(ColorsGraph) > 0) then
   begin
      SetLength(FColorsGraph,0);
      for I := 0 to Pred(Length(ColorsGraph)) do
      begin
         SetLength(FColorsGraph,Length(FColorsGraph)+1);
         FColorsGraph[I] := ColorsGraph[I];
      end;
   end;
   if (Length(ColorsText) > 0) then
   begin
      SetLength(FColorsText,0);
      for I := 0 to Pred(Length(ColorsText)) do
      begin
         SetLength(FColorsText,Length(FColorsText)+1);
         FColorsText[I] := ColorsText[I];
      end;
   end;
end;

procedure TChart4Delphi.SetTextOffset(Value: Real);
begin
   if (Value <= 0) then
      FTextOffset := 0
   else if (Value > 0.5) then
      FTextOffset := 0.5
   else
      FTextOffset := Value;
end;

procedure TChart4Delphi.SetDonutsTickness(Value: Integer);
begin
   if (Value < 10) then
      FDonutsCenterRadius := 10
   else if (Value > (FLayout.Size.Width - 15)) then
      FDonutsCenterRadius := Trunc(FLayout.Size.Width - 15)
   else
      FDonutsCenterRadius := Value;

   if (FDonutsCenterRadius <= 0) then
      FDonutsCenterRadius := 10;
end;

procedure TChart4Delphi.SetLinePointDiameter(Value: Integer);
begin
   if (Value <= 0) then
      FLinePointDiameter := 0
   else if (Value >= 50) then
      FLinePointDiameter := 50
   else
      FLinePointDiameter := Value;
end;

procedure TChart4Delphi.SetLineTickness(Value: Integer);
begin
   if (Value <= 1) then
      FLineTickness := 1
   else if (Value >= 30) then
      FLineTickness := 30
   else
      FLineTickness := Value;
end;

end.
