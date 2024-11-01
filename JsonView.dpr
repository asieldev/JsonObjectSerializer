program JsonView;

uses
  System.StartUpCopy,
  FMX.Forms,
  uJsonView in 'uJsonView.pas' {Form1},
  uJsonObjectSerializer in 'uJsonObjectSerializer.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TForm1, Form1);
  Application.Run;
end.
