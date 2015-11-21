unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, PerlRegEx, pcre, StdCtrls;

type
  TForm1 = class(TForm)
    mmoInput: TMemo;
    mmoOutput: TMemo;
    btnRun: TButton;
    procedure btnRunClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

type
  arrString = array[1..500] of string;
  arrInteger = array[1..500] of integer;

const
  coeffForP = 1;
  coeffForM = 2;
  coeffForC = 3;
  coeffForT = 0.5;

var
  Form1: TForm1;


implementation

{$R *.dfm}

/////////////////////// Additional Routines \\\\\\\\\\\\\\\\\\\\\\\\\\\\\
procedure deleteCommentsOneString(var CodeString: string);
var
  LengthDeleteRow : integer;
  RegExp : TPerlRegEx;
begin
  RegExp := TPerlRegEx.Create;
  RegExp.Options := [preMultiLine];
  RegExp.RegEx := '\/\*.*?\*\/|\/\/.*?$|\#.*?$';//'\/\*.*?\*\/|\/\/.*?$|\#.*?$';
  RegExp.Subject := CodeString;
  RegExp.Compile;
  LengthDeleteRow := 0;
  if RegExp.Match then
  begin
    repeat
      delete(CodeString, RegExp.MatchedOffset - LengthDeleteRow, RegExp.MatchedLength);
      LengthDeleteRow := LengthDeleteRow + RegExp.MatchedLength;
    until not RegExp.MatchAgain;
  end;
end;

procedure deleteCommentsMultiString(var CodeString: string);
var
  LengthDeleteRow: integer;
  RegExp : TPerlRegEx;
begin
  RegExp := TPerlRegEx.Create;
  RegExp.Options := [preSingleLine];
  RegExp.RegEx := '\/\*.*?\*\/';
  RegExp.Subject := CodeString;
  RegExp.Compile;
  LengthDeleteRow := 0;
  if RegExp.Match then
  begin
    repeat
      delete(CodeString, RegExp.MatchedOffset - LengthDeleteRow, RegExp.MatchedLength);
      LengthDeleteRow := LengthDeleteRow + RegExp.MatchedLength;
    until not RegExp.MatchAgain;
  end;
end;

procedure deleteStringWithOneHatch(var CodeString: string);
var
  LengthDeleteRow: integer;
  RegExp : TPerlRegEx;
begin
  RegExp := TPerlRegEx.Create;
  RegExp.Options := [preMultiLine];
  RegExp.RegEx := '\''.*?\''';                      //(\''.*?\'')|(\".*?\")
  RegExp.Subject := CodeString;
  RegExp.Compile;
  LengthDeleteRow := 0;
  if RegExp.Match then
  begin
    repeat
      delete(CodeString, RegExp.MatchedOffset - LengthDeleteRow, RegExp.MatchedLength);
      LengthDeleteRow := LengthDeleteRow + RegExp.MatchedLength;
    until not RegExp.MatchAgain;
  end;
end;

procedure deleteStringWithTwoHatch(var CodeString: string);
var
  LengthDeleteRow: integer;
  RegExp : TPerlRegEx;
begin
  RegExp := TPerlRegEx.Create;
  RegExp.Options := [preMultiLine];
  RegExp.RegEx := '\".*?\"';
  RegExp.Subject := CodeString;
  RegExp.Compile;
  LengthDeleteRow := 0;
  if RegExp.Match then
  begin
    repeat
      delete(CodeString, RegExp.MatchedOffset - LengthDeleteRow, RegExp.MatchedLength);
      LengthDeleteRow := LengthDeleteRow + RegExp.MatchedLength;
    until not RegExp.MatchAgain;
  end;
end;

procedure readFromFile(var CodeString: string);
var
  FlagInput: boolean;
  File1Name: string;
  OpenDialog: TOpenDialog;
begin
  FlagInput:= True;
  OpenDialog := TOpenDialog.Create(OpenDialog);
  OpenDialog.Title:= 'Input File';
  OpenDialog.InitialDir := GetCurrentDir;
  OpenDialog.Options := [ofFileMustExist];
  OpenDialog.Filter := 'Text file|*.*';
  OpenDialog.FilterIndex := 1;
  if OpenDialog.Execute then
  begin
    File1Name:= OpenDialog.FileName;
  end
  else
    begin
      Application.MessageBox('Open file stop!', 'Warning!');
      FlagInput:=False;
    end;
  if FlagInput then
  begin
    AssignFile(input, File1Name);
    reset(input);
    while not Eof(input) do
    begin
      readln(CodeString);
      Form1.mmoInput.Text := Form1.mmoInput.Text + CodeString + #13#10;
    end;
    CloseFile(input);
  end;
  OpenDialog.Free;
  CodeString := Form1.mmoInput.Text;
end;                             
///////////////////////////\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\



/////////////////// search Mod. Variable \\\\\\\\\\\\\\\\\\\
function checkRepeatVariables(arrayVariable: arrString; Quantity : integer; nameVariables : string): boolean;
var
  flag : boolean;
  i: integer;
begin
  flag := true;
  for i:= 1 to Quantity do
    if nameVariables = arrayVariable[i] then
      flag := false;
  checkRepeatVariables := flag;
end;

function searchModVariable(CodeString: string; var arrayModVariable: arrString; var Quantity: integer): integer;
var
  RegExp: TPerlRegEx;
  nameVariables : string;
begin
  Quantity := 0;
  RegExp := TPerlRegEx.Create;
  RegExp.RegEx := '(?<=\$)\w*(?=\s*\=\s+)';
  RegExp.Subject := CodeString;
  RegExp.Compile;
  if RegExp.Match then
  begin
    repeat
      nameVariables := RegExp.MatchedText;
      if checkRepeatVariables(arrayModVariable, Quantity, nameVariables) then
      begin
        inc(Quantity);
        arrayModVariable[Quantity] := nameVariables;
      end;
    until not RegExp.MatchAgain;
  end;
  searchModVariable := Quantity;
end;
///////////////////////////\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\



/////////////////// search Control Variable \\\\\\\\\\\\\\\\\\\
function searchControlVariable(CodeString : string): integer;
var
  RegExp, RegExp1 : TPerlRegEx;
  arrayControlVariables: arrString;
  Quantity, i, numberOpeningBrackets, numberClosingBrackets : integer;
  tempString : string;
begin
  Quantity := 0;
  i := 0;
  numberOpeningBrackets := 0;
  numberClosingBrackets := 0;
  RegExp := TPerlRegEx.Create;

//////////////// SWITCH \\\\\\\\\\\\\\\\\\\\\\\\\\\
  RegExp.RegEx := '(?<=\bswitch\s\(\$)\w*(?=\s*\))';
  RegExp.Subject := CodeString;
  RegExp.Compile;
  if RegExp.Match then
  begin
    repeat
      tempString := RegExp.MatchedText;
      if checkRepeatVariables(arrayControlVariables, Quantity, tempString) then
      begin
        inc(Quantity);
        arrayControlVariables[Quantity] := tempString;
      end;
    until not RegExp.MatchAgain;
  end;
//////////////// SWITCH \\\\\\\\\\\\\\\\\\\\\\\\\\\

//////////////// FOR \\\\\\\\\\\\\\\\\\\\\\\\\\\
  RegExp.RegEx := '((?<=\sfor\s\(\$)|(?<=\sfor\(\b\$))\w+';
  RegExp.Compile;
  if RegExp.Match then
  begin
    repeat
      tempString := RegExp.MatchedText;
      if checkRepeatVariables(arrayControlVariables, Quantity, tempString) then
      begin
        inc(Quantity);
        arrayControlVariables[Quantity] := tempString;
      end;
    until not RegExp.MatchAgain;
  end;
//////////////// FOR \\\\\\\\\\\\\\\\\\\\\\\\\\\

//////////////// IF \\\\\\\\\\\\\\\\\\\\\\\\\\\
  RegExp.RegEx := '\bif\s*';      
  RegExp.Subject := CodeString;
  tempString := '';
  RegExp.Compile;
  if RegExp.Match then
  begin
    repeat
      i := RegExp.MatchedOffset + RegExp.MatchedLength;
      while (numberOpeningBrackets <> numberClosingBrackets) or ((numberOpeningBrackets = 0) and (numberClosingBrackets = 0)) do
      begin
        if CodeString[i] = '(' then
          inc(numberOpeningBrackets);
        if CodeString[i] = ')' then
          inc(numberClosingBrackets);
        tempString := tempString + CodeString[i];
        inc(i);
      end;
      numberOpeningBrackets := 0;
      numberClosingBrackets := 0;
    until not RegExp.MatchAgain;

    RegExp1 := TPerlRegEx.Create;
    RegExp1.RegEx := '(?<=\$).*?\w*(?=\s*)';
    RegExp1.Subject := tempString;
    if RegExp1.Match then
    begin
      repeat
        tempString := RegExp1.MatchedText;
        if checkRepeatVariables(arrayControlVariables, Quantity, tempString) then
        begin
          inc(Quantity);
          arrayControlVariables[Quantity] := tempString;
        end;
      until not RegExp1.MatchAgain;
    end;
  end;
//////////////// IF \\\\\\\\\\\\\\\\\\\\\\\\\\\

//////////////// WHILE \\\\\\\\\\\\\\\\\\\\\\\\\\\
  RegExp.RegEx := '\bwhile\s*';
  RegExp.Subject := CodeString;
  RegExp.Compile;
  tempString := '';
  numberOpeningBrackets := 0;
  numberClosingBrackets := 0;
  if RegExp.Match then
  begin
    repeat
      i := RegExp.MatchedOffset + RegExp.MatchedLength;
      while (numberOpeningBrackets <> numberClosingBrackets) or ((numberOpeningBrackets = 0) and (numberClosingBrackets = 0)) do
      begin
        if CodeString[i] = '(' then
          inc(numberOpeningBrackets);
        if CodeString[i] = ')' then
          inc(numberClosingBrackets);
        tempString := tempString + CodeString[i];
        inc(i);
      end;
      numberOpeningBrackets := 0;
      numberClosingBrackets := 0;
    until not RegExp.MatchAgain;

    RegExp1.RegEx := '(?<=\$).*?\w*(?=\s*)';
    RegExp1.Subject := tempString;
    if RegExp1.Match then
    begin
      repeat
        tempString := RegExp1.MatchedText;
        if checkRepeatVariables(arrayControlVariables, Quantity, tempString) then
        begin
          inc(Quantity);
          arrayControlVariables[Quantity] := tempString;
        end;
      until not RegExp1.MatchAgain;
    end;
  end; 
//////////////// WHILE \\\\\\\\\\\\\\\\\\\\\\\\\\\


//////////////// ? : \\\\\\\\\\\\\\\\\\\\\\\\\\\
  RegExp.RegEx := '(?<!\<)\?(?!\>)';
  RegExp.Subject := CodeString;
  RegExp.Compile;
  tempString := '';
  numberOpeningBrackets := 0;
  numberClosingBrackets := 0;
  if RegExp.Match then
  begin
    repeat
      i := RegExp.MatchedOffset - RegExp.MatchedLength;
      while (numberOpeningBrackets <> numberClosingBrackets) or ((numberOpeningBrackets = 0) and (numberClosingBrackets = 0)) do
      begin
        if CodeString[i] = '(' then
          inc(numberOpeningBrackets);
        if CodeString[i] = ')' then
          inc(numberClosingBrackets);
        tempString := CodeString[i] + tempString;
        dec(i);
      end;
      numberOpeningBrackets := 0;
      numberClosingBrackets := 0;
    until not RegExp.MatchAgain;

    RegExp1 := TPerlRegEx.Create;
    RegExp1.RegEx := '(?<=\$).*?\w*(?=\s*)';
    RegExp1.Subject := tempString;
    if RegExp1.Match then
    begin
      repeat
        tempString := RegExp1.MatchedText;
        if checkRepeatVariables(arrayControlVariables, Quantity, tempString) then
        begin
          inc(Quantity);
          arrayControlVariables[Quantity] := tempString;
        end;
      until not RegExp1.MatchAgain;
    end;
  end;
//////////////// ? : \\\\\\\\\\\\\\\\\\\\\\\\\\\

  searchControlVariable := Quantity;
end;
/////////////////////////////\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\



/////////////////// search Parazit Variables \\\\\\\\\\\\\\\\\\\\
procedure checkNumberOfMeetingsVariables(arrayParazitVariables: arrString; Quantity: integer; CodeString : string; var variableNumberMeetings : arrInteger);
var
  RegEx : TPerlRegEx;
  i : integer;
begin
  RegEx := TPerlRegEx.Create;
  RegEx.Subject := CodeString;
  for i:=1 to Quantity do
  begin
    variableNumberMeetings[i] := 0;
    RegEx.RegEx := '(?<=\$|\.)' + arrayParazitVariables[i];
    RegEx.Compile;
    if RegEx.Match then
    begin
      repeat
        inc(variableNumberMeetings[i]);
      until not RegEx.MatchAgain;
      dec(variableNumberMeetings[i]);
    end;
  end;
end;

function searchParazitVariable(CodeString : string; arrayModVariable : arrString; countArrayModVariable : integer): integer;
var
  RegExp: TPerlRegEx;
  i, Quantity, NumberParazitVariables, LengthDeleteRow: integer;
  tempString, nameVariable : string;
  arrayParazitVariables : arrString;
  variableNumberMeetings : arrInteger;
begin
  Quantity := 0;
  NumberParazitVariables := 0;
  RegExp := TPerlRegEx.Create;
  RegExp.RegEx := '(?<=\$)\w*(?=\s*)';  //'\s(?:int|float|short|unsigned|unsigned\s+int|char|bool|double)\s[\w\,\s=\+\-\/\*\[\]]+\;';
  RegExp.Subject := CodeString;
  RegExp.Compile;
  if RegExp.Match then
  begin
    repeat
      nameVariable := RegExp.MatchedText;
      //if (checkRepeatVariables(arrayModVariable, countArrayModVariable, nameVariable)) then
      //begin
        inc(Quantity);
        arrayParazitVariables[Quantity] := nameVariable;
      //end;
    until not RegExp.MatchAgain;
  end;
  checkNumberOfMeetingsVariables(arrayParazitVariables, Quantity, CodeString, variableNumberMeetings);
  for i:= 1 to Quantity do
    if variableNumberMeetings[i] = 0 then
      inc(NumberParazitVariables);
  searchParazitVariable := NumberParazitVariables;
end;
////////////////////////////\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\


/////////////////// search Variables To Output and Calc. \\\\\\\\\\\\\\\\\\\\
function searchVariableForOutput(CodeString: string; var arrayVariableForOutput : arrString; var Quantity : integer): integer;
var
  RegExp, RegExp1 : TPerlRegEx;
  nameVariable : string;
begin
  Quantity := 0;
  RegExp := TPerlRegEx.Create;
  RegExp.RegEx := '(?<=\becho\s\"|\bprint\s\"|\bprint\s|\becho\s).*?\;';
  RegExp.Subject := CodeString;
  RegExp.Compile;
  if RegExp.Match then
  begin
    RegExp1 := TPerlRegEx.Create;
    RegExp1.RegEx := '(?<=\$)\w*(?=\s*)';
    RegExp1.Compile;
    repeat
      RegExp1.Subject := RegExp.MatchedText;
      if RegExp1.Match then
      begin
        repeat
          nameVariable := RegExp1.MatchedText;
          if (checkRepeatVariables(arrayVariableForOutput, Quantity, nameVariable)) then
          begin
            inc(Quantity);
            arrayVariableForOutput[Quantity] := nameVariable;
          end;
        until not RegExp1.MatchAgain;
      end;
    until not RegExp.MatchAgain;
  end;
  searchVariableForOutput := Quantity;
end;

function searchVariableNotMod(CodeString: string; arrayModVariable : arrString; countArrayModVariable : integer; arrayVariableForOutput : arrString; QuantityVariablesForOutput : integer): integer;
var
  RegExp, RegExp1 : TPerlRegEx;
  nameVariable : string;
  Quantity : integer;
begin
  Quantity := QuantityVariablesForOutput;
  RegExp := TPerlRegEx.Create;
  RegExp.RegEx := '\s*(\=|\+\=|\*\=|\-\=|\/\=)[\$*\w\s\\\/\*\+\*\-\(\)]*\;';
  RegExp.Subject := CodeString;
  RegExp.Compile;
  if RegExp.Match then
  begin
    RegExp1 := TPerlRegEx.Create;
    RegExp1.RegEx := '(?<=\$)\w*(?=\s*)';
    RegExp1.Compile;
    repeat
      RegExp1.Subject := RegExp.MatchedText;
      if RegExp1.Match then
      begin
        repeat
          nameVariable := RegExp1.MatchedText;
          if (checkRepeatVariables(arrayModVariable, countArrayModVariable, nameVariable)) and (checkRepeatVariables(arrayVariableForOutput, QuantityVariablesForOutput, nameVariable)) then
          begin
            inc(QuantityVariablesForOutput);
            arrayVariableForOutput[QuantityVariablesForOutput] := nameVariable;
          end;
        until not RegExp1.MatchAgain;
      end;
    until not RegExp.MatchAgain;
  end;
  searchVariableNotMod := QuantityVariablesForOutput - Quantity;
end;
////////////////////////////\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\



procedure TForm1.btnRunClick(Sender: TObject);
var
  i, countSubroutines, countArrayModVariable, QuantityVariablesForOutput: integer;
  CodeString: string;
  arraySubroutines, arrayModVariable, arrayVariableForOutput: arrString;
  P, M, C, T: integer;
  Q : Extended;
begin
  mmoInput.Clear;
  mmoOutput.Clear;
  QuantityVariablesForOutput := 0;
  P := 0; M := 0; C := 0; T := 0; Q := 0;

  readFromFile(CodeString);
  deleteCommentsMultiString(CodeString);
  deleteCommentsOneString(CodeString);
  deleteStringWithOneHatch(CodeString);
  P := P + searchVariableForOutput(CodeString, arrayVariableForOutput, QuantityVariablesForOutput);
  deleteStringWithTwoHatch(CodeString);

  for i:= 1 to length(CodeString) do
    if (CodeString[i] = #13) or (CodeString[i] = #10) then
      CodeString[i] := #0;
  //deleteComments2(CodeString);

  M := M + searchModVariable(CodeString, arrayModVariable, countArrayModVariable);
  P := P + searchVariableNotMod(CodeString, arrayModVariable, countArrayModVariable, arrayVariableForOutput, QuantityVariablesForOutput);
  T := T + searchParazitVariable(CodeString, arrayModVariable, countArrayModVariable);
  C := C + searchControlVariable(CodeString);

  Q := coeffForP * P + coeffForM * M + coeffForC * C + coeffForT * T;
  mmoOutput.Text := mmoOutput.Text + 'P = ' + IntToStr(P) + '; ' + 'M = ' + IntToStr(M) + '; ' + 'C = ' + IntToStr(C) + '; ' + 'T = ' + IntToStr(T) + #13 + #10 + 'Q = ' + FloatToStr(Q);
end;

end.
 
