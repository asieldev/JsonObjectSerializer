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

    class function ObjectToJsonString(Obj: T): string;
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

class function TJsonObjectSerializer<T>.ObjectToJsonString(Obj: T): string;
var
  Ctx: TRttiContext;
  RttiType: TRttiType;
  RttiProp: TRttiProperty;
  JsonObj: TJSONObject;
  PropValue: TValue;
  i, ArrayLength: Integer;
  ChildObj: TObject;
  JsonArray: TJSONArray;
  ElementValue: TValue;
  ChildJsonStr: string;
  ChildJsonObj: TJSONObject;
begin
  if not Assigned(Obj) then
    raise Exception.Create('El objeto no puede ser nulo');

  Ctx := TRttiContext.Create;
  JsonObj := TJSONObject.Create;

  try
    RttiType := Ctx.GetType(T);
    for RttiProp in RttiType.GetProperties do
    begin
      if RttiProp.IsReadable and Assigned(RttiProp.PropertyType) then
      begin
        PropValue := RttiProp.GetValue(TObject(Obj));
        case RttiProp.PropertyType.TypeKind of
          tkInteger:
            JsonObj.AddPair(RttiProp.Name, TJSONNumber.Create(PropValue.AsInteger));
          tkFloat:
            if RttiProp.PropertyType.Handle = TypeInfo(TDateTime) then
              JsonObj.AddPair(RttiProp.Name, TJSONString.Create(DateTimeToStr(PropValue.AsExtended)))
            else
              JsonObj.AddPair(RttiProp.Name, TJSONNumber.Create(PropValue.AsExtended));
          tkString, tkUString, tkWString:
            JsonObj.AddPair(RttiProp.Name, TJSONString.Create(PropValue.AsString));
          tkEnumeration:
            if RttiProp.PropertyType.Handle = TypeInfo(Boolean) then
            begin
              if PropValue.AsBoolean then
                JsonObj.AddPair(RttiProp.Name, TJSONTrue.Create)
              else
                JsonObj.AddPair(RttiProp.Name, TJSONFalse.Create);
            end
            else
              JsonObj.AddPair(RttiProp.Name, TJSONString.Create(PropValue.ToString));
          tkClass:
            begin
              ChildObj := PropValue.AsObject;
              if Assigned(ChildObj) then
              begin
                ChildJsonStr := TJsonObjectSerializer<TObject>.ObjectToJsonString(ChildObj);
                ChildJsonObj := TJSONObject.ParseJSONValue(ChildJsonStr) as TJSONObject;
                try
                  if Assigned(ChildJsonObj) then
                    JsonObj.AddPair(RttiProp.Name, ChildJsonObj.Clone as TJSONObject);
                finally
                  ChildJsonObj.Free;
                end;
              end
              else
                JsonObj.AddPair(RttiProp.Name, TJSONObject.Create); // JSON vacío si es nil
            end;
          tkDynArray:
            begin
              JsonArray := TJSONArray.Create;
              ArrayLength := PropValue.GetArrayLength;

              for i := 0 to ArrayLength - 1 do
              begin
                ElementValue := PropValue.GetArrayElement(i);

                if ElementValue.IsObject then
                begin
                  ChildObj := ElementValue.AsObject;
                  if Assigned(ChildObj) then
                  begin
                    ChildJsonStr := TJsonObjectSerializer<TObject>.ObjectToJsonString(ChildObj);
                    ChildJsonObj := TJSONObject.ParseJSONValue(ChildJsonStr) as TJSONObject;
                    try
                      if Assigned(ChildJsonObj) then
                        JsonArray.AddElement(ChildJsonObj.Clone as TJSONObject);
                    finally
                      ChildJsonObj.Free;
                    end;
                  end;
                end;
              end;

              JsonObj.AddPair(RttiProp.Name, JsonArray);
            end;
        end;
      end;
    end;

    Result := JsonObj.ToString;
  finally
    JsonObj.Free;
    Ctx.Free;
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

