grammar MATLAB;

NewLine: ('\r' '\n' | '\n' | '\r') -> skip;
Space: ' ' -> skip;

fragment
Integer: [0-9]+;

String : '\'' ( ~('\'' | '\n' | '\r'))* '\'';

fragment
NumericSign: ('+' | '-')?;

fragment
    Decimal: Integer '.'?
           | Integer* '.' Integer;

fragment
    Exponent: ('e' | 'E') NumericSign Integer;

Number: Decimal Exponent?;

And: '&&';
Ampersand: '&';
BraceLeft: '{';
BraceRight: '}';
Caret: '^';
Colon: ':';
SemiColon: ';';
Comma: ',';
Dot: '.';
DoubleQuote: '"';
SingleQuote: '\'';
End: 'end';
Equals: '=';
Function: 'function';
LessThan: '<';
GreaterThan: '>';
Minus: '-';
Or: '||';
ParenthesisLeft: '(';
ParenthesisRight: ')';
Percent: '%';
Pipe: '|';
Plus: '+';
Return: 'return';

SlashBackward: '\\';
SlashForward: '/';
SquareBracketLeft: '[';
SquareBracketRight: ']';
Star: '*';
Tilde: '~';
UnderScore: '_';

Comment: '%' .*? NewLine -> skip;
Identifier: [_0-9a-zA-Z]+;

transpose: rValue SingleQuote
         ;

arrayElements: rValue (Comma? rValue)*
             ;

matrix: SquareBracketLeft arrayElements (SemiColon arrayElements)* SquareBracketRight
      ;

assignment: lValue Equals expression
          | lValue Equals matrix
          ;

empty: SquareBracketLeft SquareBracketRight;

end: End;

expression: end
          | field
          | functionCall 
          | identifier 
          | number
          | string
          | transpose
          | Minus expression
          | Tilde expression
          | expression Caret expression
          | expression Minus expression
          | expression Plus expression
          | expression SlashForward expression
          | expression Star expression
          | expression SingleQuote
          | expression (Colon expression)? Colon expression
          | Colon
          ;

field: Identifier Dot Identifier;

functionCall: Identifier ParenthesisLeft functionArguments ParenthesisRight
        | field ParenthesisLeft functionArguments ParenthesisRight
        ;

functionDeclaration: Function (outputArguments Equals)* Identifier ParenthesisLeft? (Identifier (Comma Identifier)*)* ParenthesisRight? statement* (Return | End)*;

identifier: Identifier;

functionArguments: ; 

lValue: field
      | functionCall
      | identifier
      | outputArguments
      ;

simpleRValues: Identifier
             | Number
             | matrix;

rValue: simpleRValues
      | rValue (Comma rValue)*
      | rValue Caret rValue
      ;

newLine: NewLine;

number: Number;

outputArgument: (Identifier | Tilde);

outputArguments: SquareBracketLeft outputArgument (Comma outputArgument)* SquareBracketRight
               | empty;

statement: assignment SemiColon;

string: String;

matlabFile: (field | newLine | statement | functionDeclaration)* EOF;