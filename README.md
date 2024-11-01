# TJsonObjectSerializer<T>

## Descripción

`TJsonObjectSerializer<T>` es una clase genérica de Delphi que permite la conversión entre objetos y representaciones JSON. Diseñada para ser versátil y eficiente, esta clase soporta tanto tipos de datos simples como complejos (clases anidadas y arrays), proporcionando un mecanismo robusto para serialización y deserialización mediante RTTI.

## Características

- **Deserialización de JSON a objetos**: Convierte cadenas JSON en instancias de objetos de tipo `T`.
- **Serialización de objetos a JSON**: Genera una cadena JSON a partir de un objeto de tipo `T`.
- **Soporte para tipos complejos**: Deserializa y serializa propiedades de tipo clase y arrays de objetos.
- **Manejo de tipos básicos**: Admite enteros, cadenas, booleanos, y enumeraciones.

## Requisitos

- Delphi con soporte para RTTI.
- Módulos estándar como `System.SysUtils`, `System.Rtti`, `System.JSON`, `System.Classes`, y `Winapi.Windows`.

## Ejemplos de Uso

### Deserialización de JSON a Objeto

```delphi
var
  JsonString: string;
  MyObject: TMiClase;
begin
  JsonString := '{"campo1": "valor1", "campo2": 123}';
  MyObject := TJsonObjectSerializer<TMiClase>.JsonToObject(JsonString);
  // Usar MyObject después de la deserialización
end;
