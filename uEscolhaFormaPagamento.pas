unit uEscolhaFormaPagamento;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.Layouts,
  FMX.Controls.Presentation, FMX.StdCtrls, FMX.Objects, FMX.ListView.Types,
  FMX.ListView.Appearances, FMX.ListView.Adapters.Base, FMX.ListView,
  FMX.TabControl, FMX.Edit, System.Actions, FMX.ActnList,FMX.Platform,FMX.VirtualKeyboard,
  ACBrPosPrinterGEDI,
  FMX.DialogService,
  FMX.Platform.Android,
  Androidapi.Helpers,
  Androidapi.JNI.JavaTypes,
  Androidapi.Jni.OS,
  InterfaceAutomacao_v1_6_0_0,
  //InterfaceAutomacao_v2_0_0_8,
  StrUtils, ACBrBase, ACBrPosPrinter, FMX.ListBox, FMX.Colors;


type
  TfEscolhaFormaPagamento = class(TForm)
    rec_principal: TRectangle;
    lb_msg: TLabel;
    LayoutBotoesTab0: TLayout;
    bt_avancar0: TButton;
    lv_formasDePagamento: TListView;
    bt_cancelar0: TButton;
    LayoutListViewFormasDePagamento: TLayout;
    TabControl: TTabControl;
    TabForma: TTabItem;
    TabValor: TTabItem;
    TabQrCodePix: TTabItem;
    TabCartao: TTabItem;
    Label1: TLabel;
    rec_valor: TRectangle;
    ed_valor: TEdit;
    StyleBook: TStyleBook;
    ActionList: TActionList;
    ChangeTabForma: TChangeTabAction;
    ChangeTabValor: TChangeTabAction;
    ChangeTabCartao: TChangeTabAction;
    ChangeTabQRCode: TChangeTabAction;
    LayoutBotoesTab1: TLayout;
    bt_avancar1: TButton;
    bt_cancelar1: TButton;
    LayoutBotoesTab2: TLayout;
    bt_avancar2: TButton;
    bt_cancelar2: TButton;
    Layout3: TLayout;
    bt_avancar3: TButton;
    bt_cancelar3: TButton;
    Label2: TLabel;
    TabConcluido: TTabItem;
    Layout1: TLayout;
    Button1: TButton;
    Button2: TButton;
    ChangeTabConcluido: TChangeTabAction;
    ed_formapagamento: TEdit;
    Image1: TImage;
    ret_senha: TRectangle;
    lb_msg_reposta: TLabel;
    lb_contagem: TLabel;
    Label3: TLabel;
    lb_valor_que_falta: TLabel;
    ComboColorBox1: TComboColorBox;
    ComboBox1: TComboBox;
    ColorComboBox1: TColorComboBox;
    procedure FormShow(Sender: TObject);
    procedure bt_cancelar0Click(Sender: TObject);
    procedure bt_avancar0Click(Sender: TObject);
    procedure bt_avancar1Click(Sender: TObject);
    procedure bt_avancar3Click(Sender: TObject);
    procedure bt_avancar2Click(Sender: TObject);
    procedure TabControlChange(Sender: TObject);
    procedure TrataFimThreadAdicionarPagamentos(Sender: TObject);
    procedure FormKeyUp(Sender: TObject; var Key: Word; var KeyChar: Char;
      Shift: TShiftState);
    procedure lb_valor_que_faltaClick(Sender: TObject);
    procedure EfetuarVendaPaygo(NumeroOperacao:integer;ModadalidadeCartao,ValorVenda:String);
    Procedure CarregaConfiguraPayGo;
    Procedure IniciaPayGo;
    procedure ResultadoOperacao;
    Procedure iniPayGoInterface(mudacor : Boolean; ViaDeferenciada : Boolean; ViaReduzida: Boolean);
    procedure trataComprovanteSemImprimir(var comprovante1:string;var comprovante2:string);
    Procedure ConfiguraImpressora;
    procedure ImpressaoComprovantes(titulo, cupom : string);
    function  setPersonalizacao(mudacor : Boolean): JPersonalizacao;
    function  resultadoOperacacao(var res:integer) : JRunnable;

  private
    { Private declarations }
  public
    resultadoVenda         : integer;
    { Public declarations }
  end;

Type
  TConfigPayGo = record
  Adiquirente          : String;
  TipoParcelamento     : integer;
  NumParcelas          : integer;
  ConfirmacaoManual    : boolean;
  InterfaceAlternativa : boolean;
  ViasLojaCliente      : boolean;
  ViaCompleta          : boolean;
  end;

var
  fEscolhaFormaPagamento: TfEscolhaFormaPagamento;
  fGEDIPrinter: TACBrPosPrinterGEDI;
  formaPagmento,NumeroOperacao :integer;
  comprovante1   :string;
  comprovante2   :string;
  ConfigPayGo : TConfigPayGo;

  mHandler          : JHandler;
  mConfimacoes      : JConfirmacoes;
  mDadosAutomacao   : JDadosAutomacao;
  mPersonalizacao   : JPersonalizacao;
  mTransacoes       : JTransacoes;
  mSaidaTransacao   : JSaidaTransacao;
  mEntradaTransacao : JEntradaTransacao;
  mViasImpressao    : JViasImpressao;

  mensagemErro      : string;
  nsu, codigoAutorizacao, valorOperacao : string;
  transacao         : boolean;
  resultado         : Integer;
implementation

{$R *.fmx}

uses uVenda, Loading, GEDIPrinter, uMain;


var

  y : TLoading;

procedure TfEscolhaFormaPagamento.bt_avancar1Click(Sender: TObject);
var
ItemAdd   : TListViewItem;
valor1,valor2,valor3:Extended;
valor4,valor5,valor6:Currency;
t: tthread;
ModadalidadeCartao : string;
begin


  if ContainsText(ed_valor.Text, '.') then
  begin
    ShowMessage('Utilize a virgula como separador de casas decimais.');
    Exit;
  end;

  if ed_valor.Text = '' then
  begin
    ShowMessage('Digite algum valor para avan�ar.');
    Exit;
  end;

  valor4 := StrToFloat(StringReplace(ed_valor.text,'.','',[rfReplaceAll, rfIgnoreCase]));
  valor5 := StrToFloat(StringReplace(fVenda.lb_soma_valor_pago.Text,'.','',[rfReplaceAll, rfIgnoreCase]));
  valor6 := StrToFloat(StringReplace(fVenda.edit1.Text,'.','',[rfReplaceAll, rfIgnoreCase]));

  if (valor4 + valor5 ) >  valor6 then
  begin
    ShowMessage('Valor ultrapassa a divida, digite um novo valor!');
    exit;
  end;

  if ed_formapagamento.text = '0' then  //dinheiro
  begin

    fVenda.lv_pagamentos.BeginUpdate;

    ItemAdd        :=  fVenda.lv_pagamentos.Items.Add;

    TListItemText(ItemAdd.Objects.FindDrawable('Id')).Text        := inttostr(strtoint(ed_formapagamento.Text)+1);
    TListItemText(ItemAdd.Objects.FindDrawable('FormaPag')).Text  := 'DINHEIRO';
    TListItemText(ItemAdd.Objects.FindDrawable('Valor')).Text     := FormatFloat('###,##0.00',StrToFloat(StringReplace(ed_valor.text,'.','',[rfReplaceAll, rfIgnoreCase])));


    fVenda.lv_pagamentos.EndUpdate;

    fVenda.popup_background.visible := false;

    fEscolhaFormaPagamento.Close;

  end else if ed_formapagamento.text = '1' then   //debito
  begin

    transacao := FALSE;
    NumeroOperacao := Round(random(99999));
    resultadoVenda := -999999;
    comprovante1 := '';
    comprovante2 := '';

    ModadalidadeCartao := 'DEBITO';

    T := TThread.CreateAnonymousThread(procedure
    begin

      IniciaPayGo;

      mEntradaTransacao := TJEntradaTransacao.JavaClass.init(TJOperacoes.JavaClass.VENDA, Stringtojstring(IntToStr(NumeroOperacao)));

      //n�mero do documento     StringToJString(IntToStr(NumeroOperacao))
      mEntradaTransacao.informaDocumentoFiscal(StringToJString(IntToStr(NumeroOperacao)));

      //valor
      mEntradaTransacao.informaValorTotal(StringToJString(ed_valor.text.Replace(',','').Replace('.','')));

      //tipo de financiamento - default
      mEntradaTransacao.informaTipoFinanciamento(TJFinanciamentos.JavaClass.A_VISTA);

      if ModadalidadeCartao ='DEBITO' then
      begin

        mEntradaTransacao.informaTipoCartao(TJCartoes.JavaClass.CARTAO_DEBITO);

      end  else if ModadalidadeCartao = 'CREDITO' then
      begin

        mEntradaTransacao.informaTipoCartao(TJCartoes.JavaClass.CARTAO_CREDITO);

        if ConfigPayGo.NumParcelas > 1 then
        begin

          case ConfigPayGo.TipoParcelamento of

           //n�o definido
           //0:mEntradaTransacao.informaTipoFinanciamento(TJFinanciamentos.JavaClass.FINANCIAMENTO_NAO_DEFINIDO);

           //a vista
           //1: mEntradaTransacao.informaTipoFinanciamento(TJFinanciamentos.JavaClass.A_VISTA);

           //parcelada emissor
           2:begin
              mEntradaTransacao.informaTipoFinanciamento(TJFinanciamentos.JavaClass.PARCELADO_EMISSOR);
             end;

           3:begin
              mEntradaTransacao.informaTipoFinanciamento(TJFinanciamentos.JavaClass.PARCELADO_ESTABELECIMENTO);
             end;

          end;

        end;

      end   else if ModadalidadeCartao = 'VOUCHER' then
      begin

        mEntradaTransacao.informaTipoCartao(TJCartoes.JavaClass.CARTAO_VOUCHER);

      end else
      begin

         mEntradaTransacao.informaTipoCartao(TJCartoes.JavaClass.CARTAO_DESCONHECIDO);
      end;

      mEntradaTransacao.informaNomeProvedor(StringToJString('DEMO'));

      {//defini��o do provedor
      if ConfigPayGo.Adiquirente = 'PROVEDOR DESCONHECIDO' then  //default
      begin
        mEntradaTransacao.informaNomeProvedor(StringToJString('PROVEDOR DESCONHECIDO'));
      end else
      begin
        mEntradaTransacao.informaNomeProvedor(StringToJString(ConfigPayGo.Adiquirente));
      end;}

      try
        begin
          try
            begin

              // Moeda que esta sendo usada na opera��o
              mEntradaTransacao.informaCodigoMoeda(StringToJString('986')); // Real
              mConfimacoes := TJConfirmacoes.Create;

              mSaidaTransacao := mTransacoes.realizaTransacao(mEntradaTransacao);

              if mSaidaTransacao = nil then
                  //LogAplicacao('mSaidaTransacao esta NIL');

              mConfimacoes.informaIdentificadorConfirmacaoTransacao(
                    mSaidaTransacao.obtemIdentificadorConfirmacaoTransacao
                  );

            end
          except
            on e : EJNIException do
            begin
              mensagemErro := e.Message;
            end;

            on e : Exception do
            begin
              mensagemErro := e.Message;
            end;

          end;


        end

      finally
        ResultadoOperacao;
      end;

    end);
    T.OnTerminate := TrataFimThreadAdicionarPagamentos;
    T.Start;




  end else if ed_formapagamento.text = '2' then   //credito
  begin
    //ChangeTabCartao.Execute;
    transacao := FALSE;
    NumeroOperacao := Round(random(99999));
    resultadoVenda := -999999;
    comprovante1 := '';
    comprovante2 := '';

    ModadalidadeCartao := 'DEBITO';

    T := TThread.CreateAnonymousThread(procedure
    begin

    end);

    T.OnTerminate := TrataFimThreadAdicionarPagamentos;
    T.Start;
  end else if ed_formapagamento.text = '3' then    //pix
  begin

    ChangeTabQRCode.Execute;  //pix

  end;




end;

procedure TfEscolhaFormaPagamento.bt_avancar3Click(Sender: TObject);  //senha foi digitada e avan�ou
var
TS : TThread;
begin

    y := TLoading.Create;
    y.Show(fEscolhaFormaPagamento, 'Verificando pagamento...');

    TS := TThread.CreateAnonymousThread(procedure
    begin

      Sleep(3000);

      if ed_valor.Text = '1,11' then
      begin
         lb_contagem.text :='Pagamento n�o encontrado!';
      end else
      begin
         transacao := True;
      end


    end);
    TS.OnTerminate := TrataFimThreadAdicionarPagamentos;
    TS.Start;
end;

procedure TfEscolhaFormaPagamento.bt_avancar2Click(Sender: TObject);   //qrcode lido avan�ou
var
T : TThread;
begin

//    T := TThread.CreateAnonymousThread(procedure
//    begin
//
//      y := TLoading.Create;
//      y.Show(fEscolhaFormaPagamento, 'Verificando pagamento...');
//
//      Sleep(3000);
//
//      if ed_valor.Text = '1,11' then
//      begin
//         lb_contagem.text :='Pagamento n�o encontrado!';
//      end else
//      begin
//         transacao := True;
//      end
//
//
//    end);
//    T.OnTerminate := TrataFimThreadAdicionarPagamentos;
//    T.Start;
end;

procedure TfEscolhaFormaPagamento.bt_cancelar0Click(Sender: TObject);   //cancelou
begin
  fVenda.popup_background.visible := false;
  self.close;
end;

Procedure TfEscolhaFormaPagamento.CarregaConfiguraPayGo;
begin
  ConfigPayGo.Adiquirente := '';
  ConfigPayGo.TipoParcelamento     := 0;
  ConfigPayGo.ConfirmacaoManual    := FALSE ;
  ConfigPayGo.InterfaceAlternativa := FALSE ;
  ConfigPayGo.ViasLojaCliente      := True ;
  ConfigPayGo.ViaCompleta          := FALSE ;
  ConfigPayGo.NumParcelas          := 1;
end;

Procedure TfEscolhaFormaPagamento.IniciaPayGo;
begin
  CarregaConfiguraPayGo;
  iniPayGoInterface(ConfigPayGo.InterfaceAlternativa,
                    ConfigPayGo.ViasLojaCliente,
                    ConfigPayGo.ViaCompleta);
end;

procedure TfEscolhaFormaPagamento.iniPayGoInterface(mudacor, ViaDeferenciada,
  ViaReduzida: Boolean);
var
  versao : JString;
begin

  versao := MainActivity.getPackageManager.getPackageInfo(MainActivity.getPackageName, 0).versionName;

  mPersonalizacao := setPersonalizacao(mudacor);

  mDadosAutomacao := TJDadosAutomacao.JavaClass.init(
                                         StringToJString('Gertec'),             // Empresa Automa��o
                                         StringToJString('Automa��o Demo'),     // Nome Automa��o
                                         versao,                                // Vers�o
                                         true,                                  // Suporta Troco
                                         true,                                  // Suporta Desconto
                                         ViaDeferenciada,                       // Via Diferenciada
                                         ViaReduzida,                           // Via Reduzida
                                         mPersonalizacao);                      // Personaliza Tela

  mTransacoes := TJTransacoes.JavaClass.obtemInstancia(mDadosAutomacao, MainActivity);
end;

function TfEscolhaFormaPagamento.setPersonalizacao(mudacor : Boolean): JPersonalizacao;
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

procedure TfEscolhaFormaPagamento.EfetuarVendaPaygo(NumeroOperacao: integer; ModadalidadeCartao, ValorVenda: String);
var
  res:integer;
  T : TThread;
begin

  T := TThread.CreateAnonymousThread(procedure
  begin

    IniciaPayGo;

    mEntradaTransacao := TJEntradaTransacao.JavaClass.init(TJOperacoes.JavaClass.VENDA, StringToJString(IntToStr(NumeroOperacao)));

    //n�mero do documento
    mEntradaTransacao.informaDocumentoFiscal(StringToJString(IntToStr(NumeroOperacao)));

    //valor
    mEntradaTransacao.informaValorTotal(StringToJString(ValorVenda.Replace(',','').Replace('.','')));

    mEntradaTransacao.informaTipoFinanciamento(TJFinanciamentos.JavaClass.A_VISTA);

    if ModadalidadeCartao ='DEBITO' then
    begin

      mEntradaTransacao.informaTipoCartao(TJCartoes.JavaClass.CARTAO_DEBITO);

    end  else if ModadalidadeCartao = 'CREDITO' then
    begin

      mEntradaTransacao.informaTipoCartao(TJCartoes.JavaClass.CARTAO_CREDITO);

      if ConfigPayGo.NumParcelas > 1 then
      begin

        case ConfigPayGo.TipoParcelamento of

         //n�o definido
         //0:mEntradaTransacao.informaTipoFinanciamento(TJFinanciamentos.JavaClass.FINANCIAMENTO_NAO_DEFINIDO);

         //a vista
         //1: mEntradaTransacao.informaTipoFinanciamento(TJFinanciamentos.JavaClass.A_VISTA);

         //parcelada emissor
         2:begin
            mEntradaTransacao.informaTipoFinanciamento(TJFinanciamentos.JavaClass.PARCELADO_EMISSOR);
           end;

         3:begin
            mEntradaTransacao.informaTipoFinanciamento(TJFinanciamentos.JavaClass.PARCELADO_ESTABELECIMENTO);
           end;
        end;

      end;

    end   else if ModadalidadeCartao = 'VOUCHER' then
    begin

      mEntradaTransacao.informaTipoCartao(TJCartoes.JavaClass.CARTAO_VOUCHER);
    end else
    begin

       mEntradaTransacao.informaTipoCartao(TJCartoes.JavaClass.CARTAO_DESCONHECIDO);
    end;

    //mEntradaTransacao.informaNomeProvedor(StringToJString('DEMO'));

    {//defini��o do provedor
    if ConfigPayGo.Adiquirente = 'PROVEDOR DESCONHECIDO' then  //default
    begin
      mEntradaTransacao.informaNomeProvedor(StringToJString('PROVEDOR DESCONHECIDO'));
    end else
    begin
      mEntradaTransacao.informaNomeProvedor(StringToJString(ConfigPayGo.Adiquirente));
    end;}

    try
      begin
        try
          begin

            // Moeda que esta sendo usada na opera��o
            mEntradaTransacao.informaCodigoMoeda(StringToJString('986')); // Real
            mConfimacoes := TJConfirmacoes.Create;

            mSaidaTransacao := mTransacoes.realizaTransacao(mEntradaTransacao);

            if mSaidaTransacao = nil then
                //LogAplicacao('mSaidaTransacao esta NIL');

            mConfimacoes.informaIdentificadorConfirmacaoTransacao(
                  mSaidaTransacao.obtemIdentificadorConfirmacaoTransacao
                );

          end
        except
          on e : EJNIException do
          begin
            mensagemErro := e.Message;
          end;

          on e : Exception do
          begin
            mensagemErro := e.Message;
          end;

        end;

      //resultado da operacao
      end
    finally

      //trataComprovanteSemImprimir(comprovante1,comprovante2);
      //mHandler.post(resultadoOperacacao(res));
      //resultadoOperacacao(res);
      ResultadoOperacao;


    end;

  end);
  T.OnTerminate := TrataFimThreadAdicionarPagamentos;
  T.Start;

end;

function TfEscolhaFormaPagamento.resultadoOperacacao(var res:integer) : JRunnable;
begin
  ResultadoOperacao;
  trataComprovanteSemImprimir(comprovante1,comprovante2);
end;

procedure TfEscolhaFormaPagamento.ResultadoOperacao;
var

  mensagemAlert : string;
  mensagemRetorno : string;
  confirmaOperacaoManual : Boolean;
  TransacaoPendente : Boolean;

begin

  resultado := -999999;

  if mSaidaTransacao = nil then
  begin

    resultado := -999999

  end else
  begin

      confirmaOperacaoManual := false;
      TransacaoPendente := false;

      resultado := mSaidaTransacao.obtemResultadoTransacao();

      if resultado = 0 then
      begin
          transacao := true;

          if mSaidaTransacao.obtemInformacaoConfirmacao() then
          begin
              if ConfigPayGo.ConfirmacaoManual then
              begin
                  //LogAplicacao('CONFIRMADO_MANUAL');
                  confirmaOperacaoManual := true;
              end else
              begin
                  //LogAplicacao('CONFIRMADO_AUTOMATICO');
                  mConfimacoes.informaStatusTransacao(TJStatusTransacao.JavaClass.CONFIRMADO_AUTOMATICO);
                  mTransacoes.confirmaTransacao(mConfimacoes);

              end;

          end else if mSaidaTransacao.existeTransacaoPendente then
          begin
              //LogAplicacao('Tratar');
          end

      end else if mSaidaTransacao.existeTransacaoPendente then
      begin
          //LogAplicacao('Existe Transa��o Pendente');
          mConfimacoes := TJConfirmacoes.Create;
          TransacaoPendente := true
      end else
      begin
          //LogAplicacao('Aconteceu algum erro no processo');
          mensagemAlert := 'Erro';
      end;

      mensagemRetorno := JStringToString(TJString.Wrap(mSaidaTransacao.obtemMensagemResultado.intern));

      trataComprovanteSemImprimir(comprovante1,comprovante2);





      if mensagemRetorno.length > 0 then
      begin
          //LogAplicacao('At� aqui esta tudo certo');
          //LogAplicacao(mensagemRetorno);
          if resultado = 0 then
          begin
              nsu        := JStringToString(mSaidaTransacao.obtemNsuHost);
              codigoAutorizacao := JStringToString(mSaidaTransacao.obtemCodigoAutorizacao);
              valorOperacao     := JStringToString(mSaidaTransacao.obtemValorTotal) ;

              mensagemAlert := mensagemRetorno;
              //mensagemAlert := mensagemAlert + #13#10 + #13#10 + trataMensagemResultado();

          end else
            mensagemAlert := mensagemAlert + #13#10 + #13#10 +  mensagemRetorno;

      end else if (mensagemErro.length = 0) then
      begin

          if resultado = 0 then
            mensagemAlert := 'Opera��o OK'
          else
            mensagemAlert := 'Erro: ' + IntToStr(resultado);

      end else
      begin

        mensagemAlert := mensagemRetorno;

      end;


      if resultado = 0 then
      begin

          if(confirmaOperacaoManual) then
          begin

              //mensagemFim(mensagemAlert);
              //ConfirmaOperacao;

          end else
          begin

              //trataComprovante;
              //mensagemFim(mensagemAlert);
          end

      end else if(TransacaoPendente) then
      begin
        //existeTransacaoPendente
      end  else
      begin
        //mensagemFim(mensagemAlert);
      end;

  end;

end;


procedure TfEscolhaFormaPagamento.trataComprovanteSemImprimir(var comprovante1:string;var comprovante2:string);
var
  listCupom : JList;
  iter: JIterator;
  cupom : string;
begin

  if ConfigPayGo.ViasLojaCliente then
  begin

      mViasImpressao := mSaidaTransacao.obtemViasImprimir();

      if ( mViasImpressao.equals(TJViasImpressao.JavaClass.VIA_CLIENTE) )
         or
          ( mViasImpressao.equals(TJViasImpressao.JavaClass.VIA_CLIENTE_E_ESTABELECIMENTO) ) then
         begin
          listCupom := mSaidaTransacao.obtemComprovanteDiferenciadoPortador;
          if listCupom.size > 0  then
            begin
              cupom := '';
              iter := listCupom.iterator;
              while iter.hasNext do
              begin
                cupom := cupom + JStringToString(TJString.Wrap(iter.next).intern);
              end;

              ImpressaoComprovantes('Via Cliente', cupom);
              comprovante1 := cupom;
            end;

         end;

      if ( mViasImpressao.equals(TJViasImpressao.JavaClass.VIA_ESTABELECIMENTO) )
          or
         ( mViasImpressao.equals(TJViasImpressao.JavaClass.VIA_CLIENTE_E_ESTABELECIMENTO) ) then
        begin
          listCupom := mSaidaTransacao.obtemComprovanteDiferenciadoLoja;
          if listCupom.size > 0  then
          begin
            cupom := '';
            iter := listCupom.iterator;
            while iter.hasNext do
            begin
              cupom := cupom + JStringToString(TJString.Wrap(iter.next).intern);
            end;
            ImpressaoComprovantes('Via do Estabelecimento', cupom);
            comprovante2:=cupom;
          end;

        end;

    end
  else
  begin
      listCupom := mSaidaTransacao.obtemComprovanteCompleto;
      if listCupom.size > 0  then
      begin
        iter := listCupom.iterator;
        while iter.hasNext do
        begin
          cupom := cupom + JStringToString(TJString.Wrap(iter.next).intern);
        end;
        ImpressaoComprovantes('Comprovante Full', cupom);
        comprovante2:=cupom;
      end;
  end;

end;

procedure TfEscolhaFormaPagamento.ImpressaoComprovantes(titulo, cupom : string);
begin
  TThread.Synchronize(nil,
    procedure
    begin
      TDialogService.MessageDialog
              ('Deseja imprimir ' + titulo + '?',
              System.UITypes.TMsgDlgType.mtConfirmation,
              [System.UITypes.TMsgDlgBtn.mbYes, System.UITypes.TMsgDlgBtn.mbNo],
              System.UITypes.TMsgDlgBtn.mbYes, 0,
              procedure(const AResult: TModalResult)
              begin
                //LogAplicacao('Imprimindo ' + titulo);

                if (AResult = mrYES) then
                  begin

                    {ConfiguraImpressora;
                    ACBrPosPrinter1.Ativar;
                    ACBrPosPrinter1.Imprimir(cupom);
                    ACBrPosPrinter1.desAtivar; }

                    //grava comprovante no banco;

                    GertecPrinter.textSize := 18;
                    GertecPrinter.FlagBold := true;
                    GertecPrinter.textFamily := 0;
                    GertecPrinter.PrintString(ESQUERDA, cupom);
                    GertecPrinter.printBlankLine(150);
                    GertecPrinter.printOutput;

                  end;
              end);
            end);
end;

Procedure TfEscolhaFormaPagamento.ConfiguraImpressora;
var

  dado:String;
  dadoInt:Integer;
begin

  fGEDIPrinter := TACBrPosPrinterGEDI.Create(fmain.ACBrPosPrinter);
  fmain.ACBrPosPrinter.ConfigLogo.KeyCode1 := 1;
  fmain.ACBrPosPrinter.ConfigLogo.KeyCode2 := 0;
  fmain.ACBrPosPrinter.ModeloExterno  := fGEDIPrinter;
  fmain.ACBrPosPrinter.PaginaDeCodigo := TACBrPosPaginaCodigo(0);//TACBrPosPaginaCodigo(pcNone);//(pcNone, pc437, pc850, pc852, pc860, pcUTF8, pc1252);
  fmain.ACBrPosPrinter.ColunasFonteNormal := 32;
  fmain.ACBrPosPrinter.Inicializar;
end;

procedure TfEscolhaFormaPagamento.bt_avancar0Click(Sender: TObject);
begin

  if lv_formasDePagamento.Selected = nil then exit;    // N�o h� sele��o

  ed_formapagamento.text := IntToStr(lv_formasDePagamento.ItemIndex);

  ChangeTabValor.Execute;

  ed_valor.Text := '';

  lb_valor_que_falta.Text := FormatFloat('###,##0.00',StrToFloat(StringReplace(fVenda.edit1.text,'.','',[rfReplaceAll, rfIgnoreCase]))-StrToFloat(StringReplace(fVenda.lb_soma_valor_pago.text,'.','',[rfReplaceAll, rfIgnoreCase])));

end;

procedure TfEscolhaFormaPagamento.FormKeyUp(Sender: TObject; var Key: Word; var KeyChar: Char;
  Shift: TShiftState);
{$IFDEF ANDROID}
var
  FService : IFMXVirtualKeyboardService;
{$ENDIF}
begin
{$IFDEF ANDROID}
  if Key = vkHardwareBack then
  begin
    TPlatFormServices.Current.SupportsPlatformService(IFMXVirtualKeyboardService,
                                                      IInterface(FService));
    if (FService <> nil) and (TVirtualKeyboardState.Visible in FService.VirtualKeyboardState)  then
    begin

    end else
    begin
       key:=0;
    end

  end
{$ENDIF}
end;

procedure TfEscolhaFormaPagamento.FormShow(Sender: TObject);
var
ItemAdd   : TListViewItem;
begin

  TabControl.TabIndex := 0;

  lv_formasDePagamento.Items.Clear;

  lv_formasDePagamento.BeginUpdate;

  ItemAdd        := lv_formasDePagamento.Items.Add; //0
  ItemAdd.Text   :=  'DINHEIRO';

  ItemAdd        := lv_formasDePagamento.Items.Add;  //1
  ItemAdd.Text   :=  'CART�O DE D�BITO';


  ItemAdd        := lv_formasDePagamento.Items.Add;  //2
  ItemAdd.Text   :=  'CART�O DE CR�DITO';

  ItemAdd        := lv_formasDePagamento.Items.Add;  //3
  ItemAdd.Text   :=  'PIX';

  lv_formasDePagamento.EndUpdate;
end;

procedure TfEscolhaFormaPagamento.lb_valor_que_faltaClick(Sender: TObject);
begin
 ed_valor.Text := StringReplace(lb_valor_que_falta.text,'.','',[rfReplaceAll, rfIgnoreCase]);
end;

procedure TfEscolhaFormaPagamento.TabControlChange(Sender: TObject);
var
  T : TThread;
  i : integer;
begin

  transacao := false;

  if TabControl.TabIndex = 2  then  //mudou para a tela de pix
  begin

    lb_contagem.text :='   5...';
    bt_cancelar2.Enabled := False;


    T := TThread.CreateAnonymousThread(procedure
    var
        i,k : integer;
    begin

      k := 5;
      for I := 1 to 5 do
      begin

        Sleep(1000);

        TThread.Synchronize(nil,procedure
        begin
          lb_contagem.text :='   '+IntToStr(k-i)+'...';
        end
        );
      end;

      if ed_valor.Text = '1,11' then
      begin
         lb_contagem.text :='Pagamento n�o encontrado!';
      end else
      begin
         transacao := True;
      end


    end);
    T.OnTerminate := TrataFimThreadAdicionarPagamentos;
    T.Start;
  end;

end;

procedure TfEscolhaFormaPagamento.TrataFimThreadAdicionarPagamentos(Sender: TObject);
var
ItemAdd   : TListViewItem;
begin

    if transacao then
    begin

      TThread.Synchronize(nil,procedure
      begin
        //ed_senha.Text := '';
        ItemAdd        :=  fVenda.lv_pagamentos.Items.Add;
          try
          with ItemAdd do
          begin

            fVenda.lv_pagamentos.BeginUpdate;


            TListItemText(ItemAdd.Objects.FindDrawable('Id')).Text          := ed_formapagamento.Text;

            if ed_formapagamento.text = '1' then
            begin
              TListItemText(ItemAdd.Objects.FindDrawable('FormaPag')).Text  := 'CART.D�BITO';
              //y.Hide;
              //y.Free;
            end else if ed_formapagamento.text = '2' then
            begin
              TListItemText(ItemAdd.Objects.FindDrawable('FormaPag')).Text  := 'CART.CR�DITO';

            end else if ed_formapagamento.text = '3' then
            begin
              TListItemText(ItemAdd.Objects.FindDrawable('FormaPag')).Text  := 'PIX';
            end;


            TListItemText(ItemAdd.Objects.FindDrawable('Valor')).Text       := FormatFloat('###,##0.00',StrToFloat(StringReplace(ed_valor.text,'.','',[rfReplaceAll, rfIgnoreCase])));

            fVenda.lv_pagamentos.EndUpdate;


          end;
        except
          on e : Exception do
          begin
            mensagemErro := e.Message;
            ShowMessage(mensagemErro);
          end;

        end;





      end);

      fVenda.popup_background.visible := false;
      self.Close;

    end else
    begin

      ShowMessage('Falha ao adicionar o pagamento.');
      fVenda.popup_background.visible := false;
      Self.Close;

    end;


  bt_cancelar2.Enabled := True;

end;
end.
