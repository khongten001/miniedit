unit mneClasses;

{$mode objfpc}{$H+}
{**
 * Mini Edit
 *
 * @license    GPL 2 (http://www.gnu.org/licenses/gpl.html)
 * @author    Zaher Dirkey <zaher at parmaja dot com>
 *}

interface

uses
  Messages, Forms, SysUtils, StrUtils, Variants, Classes, Controls, Graphics, Contnrs,
  LCLintf, LCLType,
  Dialogs, EditorOptions, SynEditHighlighter, SynEditSearch, SynEdit,
  Registry, EditorEngine, mnXMLRttiProfile, mnXMLUtils,
  SynEditTypes, SynCompletion, SynHighlighterHashEntries, EditorProfiles,
  SynHighlighterSQL, SynHighlighterXML, SynHighlighterApache, SynHighlighterINI,
  SynHighlighterPython;

type
  TSQLFile = class(TTextEditorFile)
  protected
  public
  end;

  TApacheFile = class(TTextEditorFile)
  public
  end;

  TINIFile = class(TTextEditorFile)
  public
  end;

  TTXTFile = class(TTextEditorFile)
  public
  end;

  TXMLFile = class(TTextEditorFile)
  public
    procedure NewSource; override;
  end;

  { TSQLFileCategory }

  TSQLFileCategory = class(TFileCategory)
  protected
    function DoCreateHighlighter: TSynCustomHighlighter; override;
    procedure InitMappers; override;
  public
  end;

  { TApacheFileCategory }

  TApacheFileCategory = class(TFileCategory)
  protected
    function DoCreateHighlighter: TSynCustomHighlighter; override;
    procedure InitMappers; override;
  public
  end;

  { TINIFileCategory }

  TINIFileCategory = class(TFileCategory)
  protected
    function DoCreateHighlighter: TSynCustomHighlighter; override;
    procedure InitMappers; override;
  public
  end;

  { TTXTFileCategory }

  TTXTFileCategory = class(TFileCategory)
  protected
    function DoCreateHighlighter: TSynCustomHighlighter; override;
    procedure InitMappers; override;
  public
  end;

  { TXMLFileCategory }

  TXMLFileCategory = class(TFileCategory)
  protected
    function DoCreateHighlighter: TSynCustomHighlighter; override;
    procedure InitMappers; override;
  public
  end;

  { TmneEngine }

function ColorToRGBHex(Color: TColor): string;
function RGBHexToColor(Value: string): TColor;

const
  sSoftwareRegKey = 'Software\miniEdit\';

function GetFileImageIndex(const FileName: string): integer;

function GetHighlighterAttriAtRowColEx2(SynEdit: TCustomSynEdit; const XY: TPoint; var Token: string; var TokenType, Start: integer; var Attri: TSynHighlighterAttributes; var Range: Pointer): boolean;

implementation

uses
  IniFiles, mnStreams, mnUtils, SynHighlighterSQLite;

function ColorToRGBHex(Color: TColor): string;
var
  aRGB: TColorRef;
begin
  aRGB := ColorToRGB(Color);
  FmtStr(Result, '%s%.2x%.2x%.2x', ['#', GetRValue(aRGB), GetGValue(aRGB), GetBValue(aRGB)]);
end;

function RGBHexToColor(Value: string): TColor;
var
  R, G, B: byte;
begin
  if LeftStr(Value, 1) = '#' then
    Delete(Value, 1, 1);
  if Value <> '' then
  begin
    if Length(Value) = 3 then
    begin
      R := StrToIntDef('$' + Copy(Value, 1, 1) + Copy(Value, 1, 1), 0);
      G := StrToIntDef('$' + Copy(Value, 2, 1) + Copy(Value, 2, 1), 0);
      B := StrToIntDef('$' + Copy(Value, 3, 1) + Copy(Value, 3, 1), 0);
      Result := RGB(R, G, B);
    end
    else
    begin
      R := StrToIntDef('$' + Copy(Value, 1, 2), 0);
      G := StrToIntDef('$' + Copy(Value, 3, 2), 0);
      B := StrToIntDef('$' + Copy(Value, 5, 2), 0);
      Result := RGB(R, G, B);
    end;
  end
  else
    Result := clBlack;
end;

type
  TSynCustomHighlighterHack = class(TSynCustomHighlighter);

function GetHighlighterAttriAtRowColEx2(SynEdit: TCustomSynEdit; const XY: TPoint; var Token: string; var TokenType, Start: integer; var Attri: TSynHighlighterAttributes; var Range: Pointer): boolean;
var
  PosX, PosY: integer;
  Line: string;
  aToken: string;
begin
  with SynEdit do
  begin
    TokenType := 0;
    Token := '';
    Attri := nil;
    Result := False;
    PosY := XY.Y - 1;
    if Assigned(Highlighter) and (PosY >= 0) and (PosY < Lines.Count) then
    begin
      Line := Lines[PosY];
      if PosY = 0 then
        Highlighter.ResetRange
      else
        Highlighter.SetRange(TSynCustomHighlighterHack(Highlighter).CurrentRanges.Range[PosY - 1]);
      Highlighter.SetLine(Line, PosY);
      PosX := XY.X;
      Range := Highlighter.GetRange;
      if PosX > 0 then
        while not Highlighter.GetEol do
        begin
          Start := Highlighter.GetTokenPos + 1;
          aToken := Highlighter.GetToken;
          Range := Highlighter.GetRange;
          if (PosX >= Start) and (PosX < Start + Length(aToken)) then
          begin
            Attri := Highlighter.GetTokenAttribute;
            TokenType := Highlighter.GetTokenKind;
            Token := aToken;
            Result := True;
            exit;
          end;
          Highlighter.Next;
        end;
    end;
  end;
end;

{ TmneEngine }

function GetFileImageIndex(const FileName: string): Integer;
var
  AExtensions: TStringList;
  s: string;
begin
  s := ExtractFileExt(FileName);
  if LeftStr(s, 1) = '.' then
    s := Copy(s, 2, MaxInt);

  AExtensions := TStringList.Create;
  try
    Engine.Perspective.Groups[0].EnumExtensions(AExtensions);//TODO bad bad
    if AExtensions.IndexOf(s) >= 0 then
      Result := 2
    else
      Result := 1;//any file
  finally
    AExtensions.Free;
  end;
end;

{ TSQLFileCategory }

function TSQLFileCategory.DoCreateHighlighter: TSynCustomHighlighter;
begin
  {Result := TSynSQLSyn.Create(nil);
  (Result as TSynSQLSyn).SQLDialect := sqlMySQL;}
  Result := TSynSqliteSyn.Create(nil);
end;

procedure TSQLFileCategory.InitMappers;
begin
  with Highlighter as TSynSqliteSyn do
  begin
{    Mapper.Add(SpaceAttri, attWhitespace);
    Mapper.Add(CommentAttri, attComment);
    Mapper.Add(KeyAttri, attKeyword);
    Mapper.Add(NumberAttri, attNumber);
    Mapper.Add(StringAttri, attString);
    Mapper.Add(SymbolAttri, attSymbol);
    Mapper.Add(DefaultPackageAttri, attIdentifier);
    Mapper.Add(ExceptionAttri, attIdentifier);
    Mapper.Add(FunctionAttri, attCommon);
    Mapper.Add(IdentifierAttri, attIdentifier);
    Mapper.Add(PLSQLAttri, attDirective);
    Mapper.Add(SQLPlusAttri, attDirective);
    Mapper.Add(TableNameAttri, attName);
    Mapper.Add(VariableAttri, attVariable);
    Mapper.Add(DataTypeAttri, attType);}

    Mapper.Add(CommentAttri, attComment);
    Mapper.Add(DataTypeAttri, attType);
    Mapper.Add(ObjectAttri, attName);
    Mapper.Add(FunctionAttri, attStandard);
    Mapper.Add(IdentifierAttri, attIdentifier);
    Mapper.Add(KeyAttri, attKeyword);
    Mapper.Add(NumberAttri, attNumber);
    Mapper.Add(SpaceAttri, attWhitespace);
    Mapper.Add(StringAttri, attString);
    Mapper.Add(SymbolAttri, attSymbol);
    Mapper.Add(VariableAttri, attVariable);
  end;
end;

{ TTApacheFileCategory }

function TApacheFileCategory.DoCreateHighlighter: TSynCustomHighlighter;
begin
  Result := TSynApacheSyn.Create(nil);
end;

procedure TApacheFileCategory.InitMappers;
begin
  with Highlighter as TSynApacheSyn do
  begin
    Mapper.Add(CommentAttri, attComment);
    Mapper.Add(TextAttri, attText);
    Mapper.Add(SectionAttri, attDirective);
    Mapper.Add(KeyAttri, attKeyword);
    Mapper.Add(NumberAttri, attNumber);
    Mapper.Add(SpaceAttri, attWhitespace);
    Mapper.Add(StringAttri, attString);
    Mapper.Add(SymbolAttri, attSymbol);
  end;
end;

{ TINIFileCategory }

function TINIFileCategory.DoCreateHighlighter: TSynCustomHighlighter;
begin
  Result := TSynINISyn.Create(nil);
end;

procedure TINIFileCategory.InitMappers;
begin
  with Highlighter as TSynINISyn do
  begin
    Mapper.Add(SpaceAttri, attWhitespace);
    Mapper.Add(TextAttri, attComment);
    Mapper.Add(CommentAttri, attComment);
    Mapper.Add(KeyAttri, attKeyword);
    Mapper.Add(NumberAttri, attNumber);
    Mapper.Add(StringAttri, attString);
    Mapper.Add(SymbolAttri, attSymbol);
    Mapper.Add(SectionAttri, attDirective);
  end;
end;

{ TTXTFileCategory }

function TTXTFileCategory.DoCreateHighlighter: TSynCustomHighlighter;
begin
  Result := nil;
end;

procedure TTXTFileCategory.InitMappers;
begin
end;

{ TXMLFileCategory }

function TXMLFileCategory.DoCreateHighlighter: TSynCustomHighlighter;
begin
  Result := TSynXMLSyn.Create(nil);
end;

procedure TXMLFileCategory.InitMappers;
begin
  with Highlighter as TSynXMLSyn do
  begin
    Mapper.Add(ElementAttri, attName);
    Mapper.Add(SpaceAttri, attWhitespace);
    Mapper.Add(TextAttri, attText);
    Mapper.Add(EntityRefAttri, attIdentifier);
    Mapper.Add(ProcessingInstructionAttri, attDirective);
    Mapper.Add(CDATAAttri, attOutter);
    Mapper.Add(CommentAttri, attComment);
    Mapper.Add(DocTypeAttri, attComment);
    Mapper.Add(AttributeAttri, attName);
    Mapper.Add(NamespaceAttributeAttri, attName);
    Mapper.Add(AttributeValueAttri, attString);
    Mapper.Add(NamespaceAttributeAttri, attString);
    Mapper.Add(SymbolAttri, attSymbol);
  end;
end;

{ TXMLFile }

procedure TXMLFile.NewSource;
begin
  SynEdit.Text := '<?xml version="1.0" encoding="iso-8859-1" ?>';
  SynEdit.Lines.Add('');
  SynEdit.Lines.Add('');
  SynEdit.CaretY := 2;
  SynEdit.CaretX := 3;
end;

initialization
  with Engine do
  begin
    //Categories.Add('', TTXTFile, TTXTFileCategory);
    Categories.Add(TTXTFileCategory.Create('txt'));
    Categories.Add(TSQLFileCategory.Create('sql'));
    Categories.Add(TApacheFileCategory.Create('apache', []));
    Categories.Add(TINIFileCategory.Create('ini'));
    Categories.Add(TXMLFileCategory.Create('xml'));

    Groups.Add(TTXTFile, 'txt', 'TXT files', 'txt', ['txt'], []);
    Groups.Add(TSQLFile, 'sql', 'SQL files', 'SQL', ['sql'], [fgkAssociated, fgkMember, fgkBrowsable]);
    Groups.Add(TApacheFile, 'htaccess', 'htaccess files', 'apache', ['htaccess', 'conf'], [fgkAssociated, fgkBrowsable]);
    Groups.Add(TINIFile, 'xml', 'XML files', 'xml', ['xml'], [fgkMember, fgkBrowsable]);
    Groups.Add(TXMLFile, 'ini', 'INI files', 'ini', ['ini'], [fgkAssociated, fgkBrowsable]);
  end;
  //Engine.AddInstant('Python', ['py'], TSynPythonSyn, []);
end.
