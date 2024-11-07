{
********************************************************************************
	Copyright (c) 2024 Asiel Aldana Ortiz

	A classe TJsonSerializer<T> na unidade uJsonGeneric permite serializar e
  desserializar objetos e arrays genéricos em Delphi usando JSON.
	Utiliza RTTI para mapear as propriedades dos objetos para JSON e vice-versa,
  tornando-a flexível para qualquer classe. É útil para persistir e transferir
  dados em formato JSON em APIs e bancos de dados, facilitando a manipulação
  em diferentes camadas da aplicação.

********************************************************************************
}
unit uJsonObjectSerializer;

interface

uses
  System.SysUtils,
  System.Rtti,
  System.JSON,
  System.Classes,
  Winapi.Windows;
type

  TJsonObjectSerializer<T: class, constructor> = class
  private
    class function DeserializeValue(const Ctx: TRttiContext;
      RttiProp: TRttiProperty; JsonValue: TJSONValue): TValue;
  public
    class function JsonObjectToObject(const Json: string): T;overload;
    class function JsonObjectToObject(JsonObj: TJSONObject): T;overload;
    class function JsonArrayToObjectArray(JsonArray: TJSONArray): TArray<T>;overload;
    class function JsonStringToObjectArray(const JsonArrayString: string): TArray<T>;overload;
  end;

implementation

class function TJsonObjectSerializer<T>.DeserializeValue(const Ctx: TRttiContext;
  RttiProp: TRttiProperty; JsonValue: TJSONValue): TValue;
var
  ChildObj: TObject;
  ElementType: TRttiType;
  ChildJsonObj: TJSONObject;
  ChildProp: TRttiProperty;
  ChildJsonValue: TJSONValue;
  ChildValue: TValue;
  JsonArray: TJSONArray;
  ArrayValues: TArray<TValue>;
  i: Integer;
begin
  if JsonValue = nil then
    Exit(TValue.Empty);

  case RttiProp.PropertyType.TypeKind of
    tkInteger:
      Result := (JsonValue as TJSONNumber).AsInt;

    tkFloat:
      if RttiProp.PropertyType.Handle = TypeInfo(TDateTime) then
        Result := StrToDateTime((JsonValue as TJSONString).Value)
      else
        Result := (JsonValue as TJSONNumber).AsDouble;

    tkString, tkUString, tkWString:
      Result := (JsonValue as TJSONString).Value;

    tkEnumeration:
      if RttiProp.PropertyType.Handle = TypeInfo(Boolean) then
      begin
        if JsonValue is TJSONTrue then
          Result := True
        else if JsonValue is TJSONFalse then
          Result := False
        else
          Result := False;
      end;

    tkClass:
    begin
      if JsonValue is TJSONObject then
      begin
        ChildJsonObj := JsonValue as TJSONObject;
        ElementType := Ctx.GetType(RttiProp.PropertyType.Handle);
        ChildObj := RttiProp.PropertyType.AsInstance.MetaclassType.Create;

        for ChildProp in ElementType.GetProperties do
        begin
          if ChildProp.IsWritable then
          begin
            ChildJsonValue := ChildJsonObj.GetValue(ChildProp.Name);
            if Assigned(ChildJsonValue) then
            begin
              ChildValue := DeserializeValue(Ctx, ChildProp, ChildJsonValue);
              ChildProp.SetValue(ChildObj, ChildValue);
            end;
          end;
        end;

        Result := TValue.From<TObject>(ChildObj);
      end
      else
        Result := TValue.Empty;
    end;

    tkDynArray:
    begin
      if JsonValue is TJSONArray then
      begin
        JsonArray := TJSONArray(JsonValue);
        ElementType := (RttiProp.PropertyType as TRttiDynamicArrayType).ElementType;  // Corrección en la obtención del tipo de elemento en el array
        SetLength(ArrayValues, JsonArray.Count);

        for i := 0 to JsonArray.Count - 1 do
        begin
          ChildJsonObj := JsonArray.Items[i] as TJSONObject;
          ChildObj := ElementType.AsInstance.MetaclassType.Create;

          for ChildProp in ElementType.GetProperties do
          begin
            if ChildProp.IsWritable then
            begin
              ChildJsonValue := ChildJsonObj.GetValue(ChildProp.Name);
              if Assigned(ChildJsonValue) then
              begin
                ChildValue := DeserializeValue(Ctx, ChildProp, ChildJsonValue);
                ChildProp.SetValue(ChildObj, ChildValue);
              end;
            end;
          end;

          ArrayValues[i] := TValue.From<TObject>(ChildObj);
        end;

        Result := TValue.FromArray(RttiProp.PropertyType.Handle, ArrayValues);
      end
      else
        Result := TValue.Empty;
    end;

    else
      Result := TValue.Empty;
  end;
end;

class function TJsonObjectSerializer<T>.JsonArrayToObjectArray(
  JsonArray: TJSONArray): TArray<T>;
var
  Ctx: TRttiContext;
  ElementType: TRttiType;
  JsonObj: TJSONObject;
  ObjValue: T;
  i: Integer;
begin
  SetLength(Result, JsonArray.Count);
  Ctx := TRttiContext.Create;

  try
    ElementType := Ctx.GetType(TypeInfo(T));

    for i := 0 to JsonArray.Count - 1 do
    begin
      JsonObj := JsonArray.Items[i] as TJSONObject;
      ObjValue := JsonObjectToObject(JsonObj.ToString);  // Convierte cada elemento JSON en un objeto T
      Result[i] := ObjValue;
    end;

  finally
    Ctx.Free;
  end;
end;

class function TJsonObjectSerializer<T>.JsonObjectToObject(
  JsonObj: TJSONObject): T;
var
  Ctx: TRttiContext;
  RttiType: TRttiType;
  RttiProp: TRttiProperty;
  JsonValue: TJSONValue;
  Value: TValue;
begin
  if not Assigned(JsonObj) then
    raise Exception.Create('Objeto JSON inválido');

  Result := T.Create;
  Ctx := TRttiContext.Create;

  try
    RttiType := Ctx.GetType(T);

    for RttiProp in RttiType.GetProperties do
    begin
      if RttiProp.IsWritable then
      begin
        JsonValue := JsonObj.GetValue(RttiProp.Name);
        if Assigned(JsonValue) then
        begin
          Value := DeserializeValue(Ctx, RttiProp, JsonValue);
          RttiProp.SetValue(TObject(Result), Value);
        end;
      end;
    end;
  finally
    Ctx.Free;
  end;
end;

class function TJsonObjectSerializer<T>.JsonStringToObjectArray(
  const JsonArrayString: string): TArray<T>;
var
  JsonArray: TJSONArray;
begin
  // Parsear el string JSON a un TJSONArray
  JsonArray := TJSONObject.ParseJSONValue(JsonArrayString) as TJSONArray;

  if not Assigned(JsonArray) then
    raise Exception.Create('JSON inválido: se esperaba un array JSON');

  try
    // Llama a la función JsonArrayToObjectArray con el TJSONArray
    Result := JsonArrayToObjectArray(JsonArray);
  finally
    JsonArray.Free;
  end;
end;

class function TJsonObjectSerializer<T>.JsonObjectToObject(const Json: string): T;
var
  Ctx: TRttiContext;
  RttiType: TRttiType;
  RttiProp: TRttiProperty;
  JsonObj: TJSONObject;
  JsonValue: TJSONValue;
  Value: TValue;
begin
  Result := T.Create;
  JsonObj := TJSONObject.ParseJSONValue(Json) as TJSONObject;

  if not Assigned(JsonObj) then
    raise Exception.Create('JSON inválido');

  Ctx := TRttiContext.Create;

  try
    RttiType := Ctx.GetType(T);
    for RttiProp in RttiType.GetProperties do
    begin
      if RttiProp.IsWritable then
      begin
        JsonValue := JsonObj.GetValue(RttiProp.Name);
        if Assigned(JsonValue) then
        begin
          Value := DeserializeValue(Ctx, RttiProp, JsonValue);
          RttiProp.SetValue(TObject(Result), Value);
        end;
      end;
    end;
  finally
    JsonObj.Free;
    Ctx.Free;
  end;
end;

end.

