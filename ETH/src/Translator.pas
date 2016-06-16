﻿unit Translator;

interface

uses
  System.Generics.Collections;

type
  TLangsDictionary = TDictionary<string, string>;

  TTranslator = class
  protected
    FSrcLang, FDestLang: string;
    FLangs: TLangsDictionary;
  protected
    function GetLangs: TLangsDictionary;
  public
    function Translate(text: string): string; virtual; abstract;
    procedure SetTranslationDirection(SourceLang, DestinationLang: string);
    property LangPairs: TLangsDictionary read GetLangs;
    constructor Create;
    destructor Destroy; override;
  end;

implementation

{ TTramslator }

constructor TTranslator.Create;
begin
  FLangs := TLangsDictionary.Create;
end;

destructor TTranslator.Destroy;
begin
  FLangs.Free;
  inherited;
end;

function TTranslator.GetLangs: TLangsDictionary;
begin
  Result := FLangs;
end;

procedure TTranslator.SetTranslationDirection(SourceLang,
  DestinationLang: string);
begin
  FSrcLang := FLangs[SourceLang];
  FDestLang := FLangs[DestinationLang];
end;

end.