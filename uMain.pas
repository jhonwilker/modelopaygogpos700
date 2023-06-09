unit uMain;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs,
  FMX.Controls.Presentation, FMX.StdCtrls,
  InterfaceAutomacao_v1_6_0_0,
  //InterfaceAutomacao_v2_0_0_8,
  GEDIPrinter,    //Esta unit inicializa o Modulo de impressao G700.
  G700Interface,
  FMX.Platform.Android,
  Androidapi.Helpers,
  Androidapi.Jni.OS,
  Androidapi.JNI.JavaTypes,
  Androidapi.Log,
  FMX.DialogService,
  ACBrTEFComum,
  FMX.Layouts, ACBrBase, ACBrTEFAPIComum, ACBrTEFAndroid, ACBrPosPrinter;

type
  TfMain = class(TForm)
    Button1: TButton;
    Button2: TButton;
    Layout1: TLayout;
    ACBrTEFAndroid: TACBrTEFAndroid;
    ACBrPosPrinter: TACBrPosPrinter;
    procedure Button1Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure InicializarPosPrinter;
    procedure ImprimirComprovantes(ATEFResp: TACBrTEFResp);
    procedure ImprimirRelatorio(ATexto: String);
    procedure ACBrTEFAndroidQuandoDetectarTransacaoPendente(
      RespostaTEF: TACBrTEFResp; const MsgErro: string);
  private
    { Private declarations }
  public
    { Public declarations }
    procedure efetuaOperacao(operacoes : JOperacoes);
    procedure iniPayGoInterface(mudacor : Boolean; ViaDeferenciada : Boolean; ViaReduzida: Boolean);
    function setPersonalizacao(mudacor: Boolean): JPersonalizacao;
  end;

var
  mHandler          : JHandler;
  mConfimacoes      : JConfirmacoes;
  mDadosAutomacao   : JDadosAutomacao;
  mPersonalizacao   : JPersonalizacao;
  mTransacoes       : JTransacoes;
  mSaidaTransacao   : JSaidaTransacao;
  mEntradaTransacao : JEntradaTransacao;
  mViasImpressao    : JViasImpressao;
  fMain: TfMain;

implementation

{$R *.fmx}

uses uEscolhaFormaPagamento, uVenda;

{ TForm1 }

procedure TfMain.ACBrTEFAndroidQuandoDetectarTransacaoPendente(
  RespostaTEF: TACBrTEFResp; const MsgErro: string);
var
  AStatus: TACBrTEFStatusTransacao;
  i: Integer;
  ATEFResp: TACBrTEFResp;
  aMsgErro: String;
begin
  // Aqui voc� pode Confirmar ou Desfazer as transa��es pendentes de acordo com
  // a sua regra de neg�cios

  // Exemplo 0 - Deixe o ACBrTEFAndroid CONFIRMAR todas transa��es pendentes automaticamente
  // ACBrTEFAndroid1.AutoConfirmarTransacoesPendente := True;
  // Nesse caso... esse evento n�o ser� disparado.

  // Exemplo 1 -  Envio de confirma��o autom�tica:
  // AStatus := stsSucessoManual;
  // ACBrTEFAndroid1.ResolverOperacaoPendente(AStatus);

  // Exemplo 2 -  Fazer uma pergunta ao usu�rio:
  if (MsgErro = '') then
    AMsgErro := RespostaTEF.TextoEspecialOperador
  else
    AMsgErro := MsgErro;

  TDialogService.MessageDialog( AMsgErro + sLineBreak+sLineBreak +
                                'Confirmar ?',
                                TMsgDlgType.mtConfirmation,
                                [TMsgDlgBtn.mbYes, TMsgDlgBtn.mbNo],
                                TMsgDlgBtn.mbYes, 0,

    procedure(const AResult: TModalResult)
    begin
        if (AResult = mrYes) then
          AStatus := TACBrTEFStatusTransacao.tefstsSucessoManual
        else
          AStatus := TACBrTEFStatusTransacao.tefstsErroDiverso;

        ACBrTEFAndroid.ResolverTransacaoPendente(AStatus);
      end
  );

  // Se confirmou, vamos re-imprimir a transa��o que ficou pendente
  if (AStatus in [tefstsSucessoAutomatico, tefstsSucessoManual]) then
  begin
    ATEFResp := RespostaTEF;
    // Achando a transa��o original...
    for i := 0 to ACBrTEFAndroid.RespostasTEF.Count-1 do
    begin
      if (ACBrTEFAndroid.RespostasTEF[i].NSU = RespostaTEF.NSU) and
         (ACBrTEFAndroid.RespostasTEF[i].Rede = RespostaTEF.Rede) then
      begin
        ATEFResp := ACBrTEFAndroid.RespostasTEF[i];
        Break;
      end;
    end;

    ImprimirComprovantes(ATEFResp);
  end;

end;

procedure TfMain.Button1Click(Sender: TObject);
begin

  efetuaOperacao(TJOperacoes.JavaClass.ADMINISTRATIVA);

end;

procedure TfMain.Button2Click(Sender: TObject);
begin

  if not Assigned(fVenda) then  Application.CreateForm(TfVenda,fVenda);

  fVenda.Button1.Text := 'Pagar';
  fVenda.lb_soma_valor_pago.Text := '0,00';
  fVenda.Edit1.text := '0,00';
  fVenda.lv_pagamentos.items.clear;
  fVenda.Edit1.ReadOnly := false;

  fVenda.Show;

end;



procedure TfMain.efetuaOperacao(operacoes: JOperacoes);
var
  NumeroOperacao : integer;
begin

    TThread.CreateAnonymousThread(
    procedure
    begin
      NumeroOperacao := Round(random(99999)); // 99999 � o limite do numero randomico

      mEntradaTransacao := TJEntradaTransacao.JavaClass.init(operacoes, StringToJString(IntToStr(NumeroOperacao)));

      try
        begin
          mConfimacoes := TJConfirmacoes.Create;
          mSaidaTransacao := mTransacoes.realizaTransacao(mEntradaTransacao);

          if mSaidaTransacao = nil then
                //LogAplicacao('mSaidaTransacao esta NIL');

            mConfimacoes.informaIdentificadorConfirmacaoTransacao(
                  mSaidaTransacao.obtemIdentificadorConfirmacaoTransacao
                );
        end

      finally

      end;
    end
  ).Start;

end;

procedure TfMain.FormCreate(Sender: TObject);
begin
  iniPayGoInterface(false,false,false);
end;

procedure TfMain.ImprimirComprovantes(ATEFResp: TACBrTEFResp);
begin
  if not Assigned(ATEFResp) then
    Exit;

  if (ATEFResp.ImagemComprovante2aVia.Count > 0) then
    ImprimirRelatorio( ATEFResp.ImagemComprovante2aVia.Text );

  if (ATEFResp.ImagemComprovante1aVia.Count > 0) then
  begin

    if true {(cbxImpressaoViaCliente.ItemIndex = 0} or    // Configurado para sempre Imprimir
       (ATEFResp.ImagemComprovante2aVia.Count = 0) then  // S� recebeu a via do Cliente
    begin
      ImprimirRelatorio( ATEFResp.ImagemComprovante1aVia.Text )
    end

    else if true{(cbxImpressaoViaCliente.ItemIndex = 1)} then   // Perguntar
    begin
      TDialogService.MessageDialog( 'Imprimir Via do Cliente ?',
                                    TMsgDlgType.mtConfirmation,
                                    [TMsgDlgBtn.mbYes, TMsgDlgBtn.mbNo],
                                    TMsgDlgBtn.mbYes, 0,
        procedure(const AResult: TModalResult)
        var
          AStatus: LongWord;
        begin
          if (AResult = mrYes) then
            ImprimirRelatorio( ATEFResp.ImagemComprovante1aVia.Text );
        end);
    end;
  end;
end;

procedure TfMain.ImprimirRelatorio(ATexto: String);
var
  ComandoInicial, ComandoFinal: string;
begin
  InicializarPosPrinter;

  ComandoInicial := '</zera>';
  if false {swFonteCondensada.IsChecked} then
    ComandoInicial := ComandoInicial + '<c>';
  if false {swFonteNegrito.IsChecked} then
    ComandoInicial := ComandoInicial + '<n>';

  ComandoFinal := '</lf></corte_total>';
  ACBrPosPrinter.Ativar;
  ACBrPosPrinter.Imprimir(ComandoInicial + ATexto + ComandoFinal);
  ACBrPosPrinter.desAtivar;

end;

procedure TfMain.InicializarPosPrinter;
begin
  if ACBrPosPrinter.Ativo then
    Exit;

  ACBrPosPrinter.Ativar;
end;

procedure TfMain.iniPayGoInterface(mudacor, ViaDeferenciada,
  ViaReduzida: Boolean);
var
  versao : JString;
begin

  versao := MainActivity.getPackageManager.getPackageInfo(MainActivity.getPackageName, 0).versionName;

  mPersonalizacao := setPersonalizacao(mudacor);

  mDadosAutomacao := TJDadosAutomacao.JavaClass.init(
                                         StringToJString('Gertec'),             // Empresa Automa��o
                                         StringToJString('Automa��o Demo'),     // Nome Automa��o
                                         StringToJString('1.0'),                                // Vers�o
                                         true,                                  // Suporta Troco
                                         true,                                  // Suporta Desconto
                                         ViaDeferenciada,                       // Via Diferenciada
                                         ViaReduzida,                           // Via Reduzida
                                         mPersonalizacao);                      // Personaliza Tela

  mTransacoes := TJTransacoes.JavaClass.obtemInstancia(mDadosAutomacao, MainActivity);

end;

function TfMain.setPersonalizacao(mudacor: Boolean): JPersonalizacao;
var
  pb : JPersonalizacao_Builder;
begin

  pb := TJPersonalizacao_Builder.Create;

  if mudacor then
  begin
    pb.informaCorFonte(StringToJString('#000000'));
    pb.informaCorFonteTeclado(StringToJString('#000000'));
    pb.informaCorFundoCaixaEdicao(StringToJString('#FFFFFF'));
    pb.informaCorFundoTela(StringToJString('#F4F4F4'));
    pb.informaCorFundoTeclado(StringToJString('#F4F4F4'));
    pb.informaCorFundoToolbar(StringToJString('#2F67F4'));
    pb.informaCorTextoCaixaEdicao(StringToJString('#000000'));
    pb.informaCorTeclaPressionadaTeclado(StringToJString('#e1e1e1'));
    pb.informaCorTeclaLiberadaTeclado(StringToJString('#dedede'));
    pb.informaCorSeparadorMenu(StringToJString('#2F67F4'));

  end;

  result := pb.build;

end;

end.
