unit uJsonView;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs,
  FMX.Controls.Presentation, FMX.StdCtrls, uJsonObjectSerializer, FMX.Layouts, FMX.Memo,
  FMX.TabControl;

type
  TGrupo = class
  private
    FCodigo: Integer;
    FPessoa: String;
  published
    property codigo: Integer read FCodigo write FCodigo;
    property pessoa: String read FPessoa write FPessoa;
  end;

  TMotorista = class
  private
    FCodigo: Integer;
    FTransportador: Integer;
    FSindicato: Integer;
    FGrupos: TArray<TGrupo>;
  public
    property codigo: Integer read FCodigo write FCodigo;
    property transportador: Integer read FTransportador write FTransportador;
    property sindicato: Integer read FSindicato write FSindicato;
    property grupos: TArray<TGrupo> read FGrupos write FGrupos;

  end;

  TDados = class
  private
    FNome_Mot: string;
    FEscala: string;
  published
    property nome_mot: string read FNome_Mot write  FNome_Mot;
    property escala: string read FEscala write  FEscala;
  end;

  TJornada = class
  private
    FMotorista: TMotorista;
    FDados: TDados;
  published
    property motorista: TMotorista read FMotorista write FMotorista;
    property dados: TDados read FDados write FDados;
  end;


  TForm1 = class(TForm)
    tbControl: TTabControl;
    mmoJsonToArray: TMemo;
    btnJsonToArray: TButton;
    btnJsonToObject: TButton;
    mmoJsonToObject: TMemo;
    tbtm1: TTabItem;
    tbtm2: TTabItem;
    mmoObjectToJson: TMemo;
    btnObjectToJson: TButton;
    mmoObjectToArray: TMemo;
    btnObjectToArray: TButton;
    procedure btnJsonToObjectClick(Sender: TObject);
    procedure btnJsonToArrayClick(Sender: TObject);
    procedure btnObjectToJsonClick(Sender: TObject);
  end;

var
  Form1: TForm1;
  Jornada: TJornada;
  Jornadas: TArray<TJornada>;

implementation

{$R *.fmx}


procedure TForm1.btnJsonToObjectClick(Sender: TObject);
begin

  if mmoJsonToObject.Text <> EmptyStr then
  begin
    Jornada:= TJsonObjectSerializer<TJornada>.JsonObjectToObject(mmoJsonToObject.Text);

    if Assigned(Jornada) then
      ShowMessage(Format('Jornadas: %d, %d, %d', [Jornada.motorista.codigo, Jornada.motorista.sindicato, Jornada.motorista.transportador]))
  end
  else
    ShowMessage('Json nulo');

end;

procedure TForm1.btnObjectToJsonClick(Sender: TObject);
begin
  if not Assigned(Jornada) then
    Jornada:= TJornada.Create;

  mmoObjectToJson.Text:= TJsonObjectSerializer<TJornada>.ObjectToJsonString(Jornada);
  ShowMessage('Esta función puede presentar problemas al intentar manipular TClass');
end;

procedure TForm1.btnJsonToArrayClick(Sender: TObject);
var
  JornadaValue: TJornada;
begin

  if mmoJsonToArray.Text <> EmptyStr then
  begin
    Jornadas:= TJsonObjectSerializer<TJornada>.JsonStringToObjectArray(mmoJsonToArray.Text);

    if Length(Jornadas) > 0 then
      for JornadaValue in Jornadas do
      begin
        ShowMessage(Format('Jornadas: %d, %d, %d', [JornadaValue.motorista.codigo, JornadaValue.motorista.sindicato, JornadaValue.motorista.transportador]))
      end;
  end
  else
    ShowMessage('Json nulo');
end;
end.
