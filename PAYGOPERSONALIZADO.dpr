program PAYGOPERSONALIZADO;

uses
  System.StartUpCopy,
  FMX.Forms,
  uMain in 'uMain.pas' {fMain},
  G700Interface in 'G700Interface.pas',
  GEDIPrinter in 'GEDIPrinter.pas',
  InterfaceAutomacao_v1_6_0_0 in 'InterfaceAutomacao_v1_6_0_0.pas',
  uEscolhaFormaPagamento in 'uEscolhaFormaPagamento.pas' {fEscolhaFormaPagamento},
  PayGoSDK in 'PayGoSDK.pas',
  uVenda in 'uVenda.pas' {fVenda},
  Loading in 'Loading.pas',
  InterfaceAutomacao_v2_0_0_8 in 'InterfaceAutomacao_v2_0_0_8.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TfMain, fMain);
  Application.CreateForm(TfEscolhaFormaPagamento, fEscolhaFormaPagamento);
  Application.CreateForm(TfVenda, fVenda);
  Application.Run;
end.
