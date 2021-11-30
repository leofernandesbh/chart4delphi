program ChartForDelphiDemo;

uses
  System.StartUpCopy,
  FMX.Forms,
  uPrincipal in 'uPrincipal.pas' {FrmGraph},
  Chart4Delphi in 'Chart4Delphi.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TFrmGraph, FrmGraph);
  Application.Run;
end.
