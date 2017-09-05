/*
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */

grammar MATLAB;

//
// ==================================================================
//
// PARSER RULES
//

NL : '\n' -> channel(HIDDEN);

file: scriptMFile | functionMFile ;

functionMFile: f_def_line f_body RETURNS? ENDS?
             ;

f_def_line	:	FUNCTION ID '=' ID f_input
		|	FUNCTION ID f_input
		;

f_input		:
		| '(' ')'
		| '(' f_argument_list ')'
		;

f_argument_list	: ID ',' f_argument_list
		| ID
		;

f_body		:	(   statement (';'|NL)
        |   NL
        )*
            ;


scriptMFile:   (statement | NL)* EOF;


statement: (ID 
         | assignment
         | expr
         | command_form
         | for_command
         | if_command
         | global_command
         | while_command
         | return_command)
		 (SemiColon | NL)
         ;	

assignment: reference '=' expr
		  | functionCallOutput Equals expr
          ;

functionCall: ID LeftParenthesis functionCallInput* RightParenthesis
			| ID Dot functionCall
			;

functionCallInput: expr (Comma expr)*;

functionCallOutput: LeftSquareBracket ID (Comma ID)* RightSquareBracket
				  | ID
				  ;

reference: ID;

argument_list	: ':'
		| expr
		| ':' ',' argument_list
		| expr ',' argument_list
		;

command_form : ID command_args
             ;

command_args : ID+ // FIXME!!
             ;

for_command : FOR ID '=' expr End
            ;

if_command : IF expr End
           ;

global_command	: GLOBAL ID+
		;

while_command : WHILE expr End
              ;

return_command : RETURNS
               ;

expr: functionCall
	| '(' expr ')'
	| expr SingleQuote
	| expr '.^' expr
	| expr '^' expr
	| '~' expr
	| '+' expr
	| '-' expr
	| expr '*' expr
	| expr RIGHTDIV expr
	| expr '/' expr
	| expr '.*' expr
	| expr EL_RIGHTDIV expr
	| expr './' expr
	| expr '+' expr
	| expr '-' expr
	| expr ':' expr 
	| expr '<' expr
	| expr '<=' expr
	| expr '>' expr
	| expr '>=' expr
	| expr '=' expr
	| expr '~=' expr
	| expr '&&' expr
	| expr '||' expr
	| expr '&' expr
	| expr '|' expr
	| expr '==' expr
	| array
	| arrayAccess
	| fieldAccess
	| reference
    | (INT | FLOAT | STRING);

array: LeftSquareBracket expr (Comma* expr)* RightSquareBracket
	 ;

arrayAccess: reference LeftParenthesis arrayAccessInput RightParenthesis
		   ;

arrayAccessInput: arrayAccessExpression (Comma arrayAccessExpression)*
				;

arrayAccessExpression: expr
					 | Colon
					 | End
					 ;

fieldAccess: ID '.(' ID ')'
		   | ID '.' ID
		   ; 

//// LEXER RULES

// language keywords
BREAK	   : 'break';
CASE	   : 'case';
CATCH	   : 'catch';
CONTINUE   : 'continue';
ELSE	   : 'else';
ELSEIF	   : 'elseif';
End	   : 'end';
FOR	   : 'for';
FUNCTION   : 'function';
GLOBAL	   : 'global';
IF	   : 'if';
OTHERWISE  : 'otherwise';
PERSISTENT : 'persistent';
RETURNS	   : 'return';
SWITCH	   : 'switch';
TRY	   : 'try';
VARARGIN   : 'varargin';
WHILE	   : 'while';
CLEAR	   : 'clear';

ENDS	  : End SemiColon?;

//
// operators and assignments
//

DOUBLE_EQ : '==';
LOG_OR	  : '||';
LOG_AND	  : '&&';
LSTE	  : '<=';
GRTE	  : '>=';
NEQ	  : '~=';

EL_TIMES	: '.*';
EL_LEFTDIV	: './';
EL_RIGHTDIV	: '.\\';
EL_EXP	: '.^';
EL_CCT	: '.\'';

Equals: '=';

BIN_OR	: '|';
BIN_AND	: '&';

LST	: '<';
GRT	: '>';

Colon: ':';

PLUS	: '+';
MINUS	: '-';
NEG	: '~';
TIMES	: '*';

LEFTDIV	: '/';
RIGHTDIV: '\\';

EXP	: '^';

SingleQuote: '\'';

// Other useful language snippets
SemiColon: ';';
LeftParenthesis: '(';
RightParenthesis: ')';
LBRACE	: '{';
RBRACE	: '}';
LeftSquareBracket: '[';
RightSquareBracket: ']';
AT	: '@';
Dot	: '.';
Comma: ',';

// comments
BLOCKCOMMENT: '%{' .*?  '%}' -> channel(HIDDEN);

COMMENT: '%' .*? NL  -> channel(HIDDEN);

THREEDOTS: ('...' NL) -> skip;

// identifiers, strings, numbers, whitespace
ID: [a-zA-Z] [a-zA-Z0-9_]*;

INT: DIGIT+;

FLOAT: DIGIT+ '.' DIGIT* EXPONENT?
     | DIGIT+ EXPONENT
     | '.' DIGIT+ EXPONENT?;

fragment
EXPONENT: ('e'|'E') ('+'|'-')? DIGIT+;

fragment
DIGIT: [0-9];

STRING : '\'' ( ~('\'' | '\r' | '\n') )* '\'';

WS : [ \t] -> skip;