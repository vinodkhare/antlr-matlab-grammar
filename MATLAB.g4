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

NL : ('\r' '\n' | '\r' | '\n') -> channel(HIDDEN);

file: scriptMFile | function_definition*
	;

function_definition: functionDefinitionLine statement* 'return'? 'END'?
				  ;

functionDefinitionLine: 'function' functionOutputArguments '=' reference '(' functionInputArguments ')'
					  ;

functionOutputArguments: LeftSquareBracket (ID (Comma ID)*)* RightSquareBracket
				  	   | ID
					   ;

functionInputArguments: (ID (Comma ID)*)*
					  ;

scriptMFile: (statement | NL)* EOF
		   ;

statement: (ID 
         | assignment
         | expression
         | command_form
         | for_command
         | if_command
		 | if_statement
         | global_command
         | while_command
		 | for_statement
		 | whileStatement
         | RETURN)*
		 (',' | SemiColon | NL)
         ;

for_statement:
	FOR for_index Equals expression
		statement*
	END
;

for_index:
	ID
;

if_statement:
	IF expression
		statement*
	(ELSEIF expression
		statement*)*
	(ELSE
		statement*)?
	END
;

whileStatement: 'while' expression statement* END
			  ;

assignment: reference '=' expression
		  | functionCallOutput Equals expression
          ;

functionCall: ID LeftParenthesis functionCallInput* RightParenthesis
			| ID Dot functionCall
			;

functionCallInput: expression (Comma expression)*
				 ;

functionCallOutput: LeftSquareBracket functionCallOutputArgument (Comma functionCallOutputArgument)* RightSquareBracket
				  | reference
				  ;

functionCallOutputArgument: (reference | '~')
						  ;

reference: ID;

argument_list: ':'
			| expression
			| ':' ',' argument_list
			| expression ',' argument_list
			;

command_form : ID command_args
             ;

command_args : ID+ // FIXME!!
             ;

for_command : FOR ID '=' expression END
            ;

if_command : IF expression END
           ;

global_command	: GLOBAL ID+
		;

while_command : WHILE expression END
              ;

expression: functionCall
	| '(' expression ')'
	| expression SingleQuote
	| expression '.^' expression
	| expression '^' expression
	| '~' expression
	| '+' expression
	| '-' expression
	| expression '*' expression
	| expression RIGHTDIV expression
	| expression '/' expression
	| expression '.*' expression
	| expression EL_RIGHTDIV expression
	| expression './' expression
	| expression '+' expression
	| expression '-' expression
	| expression ':' expression 
	| expression '<' expression
	| expression '<=' expression
	| expression '>' expression
	| expression '>=' expression
	| expression '=' expression
	| expression '~=' expression
	| expression '&&' expression
	| expression '||' expression
	| expression '&' expression
	| expression '|' expression
	| expression '==' expression
	| array
	| arrayAccess
	| fieldAccess
	| reference
    | (INT | FLOAT | STRING);

array: LeftSquareBracket arrayLine (';' arrayLine)* RightSquareBracket
	 ;

arrayLine: expression (Comma* expression)*
		 ;

arrayAccess: reference LeftParenthesis arrayAccessInput RightParenthesis
		   ;

arrayAccessInput: arrayAccessExpression (Comma arrayAccessExpression)*
				;

arrayAccessExpression: expression
					 | Colon
					 | END
					 ;

fieldAccess: ID '.(' ID ')'
		   | ID '.' ID
		   ; 

//// LEXER RULES

// Multiline statement
Elipsis: '...' NL -> skip;

// language keywords
BREAK	   : 'break';
CASE	   : 'case';
CATCH	   : 'catch';
CONTINUE   : 'continue';
ELSE	   : 'else';
ELSEIF	   : 'elseif';
END	   		: 'end';
FOR	   		: 'for';
FUNCTION   : 'function';
GLOBAL	   : 'global';
IF	   : 'if';
OTHERWISE  : 'otherwise';
PERSISTENT : 'persistent';
RETURN	   : 'return';
SWITCH	   : 'switch';
TRY	   : 'try';
VARARGIN   : 'varargin';
WHILE	   : 'while';
CLEAR	   : 'clear';

ENDS	  : END SemiColon?;

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