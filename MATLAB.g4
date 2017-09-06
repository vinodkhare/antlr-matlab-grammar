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

function_definition:
	FUNCTION (function_output_arguments Equals)? function_name function_input_arguments?
		statement*
	(RETURN | END)?
;

function_output_arguments:
	LeftSquareBracket variable_list? RightSquareBracket
;

function_input_arguments:
	LEFT_PARENTHESIS variable_list? RIGHT_PARENTHESIS
;

variable_list:
	ID (COMMA ID)*
;

functionDefinitionLine: 'function' functionOutputArguments '=' reference '(' functionInputArguments ')'
					  ;

functionOutputArguments: LeftSquareBracket (ID (COMMA ID)*)* RightSquareBracket
				  	   | ID
					   ;

functionInputArguments: (ID (COMMA ID)*)*
					  ;

scriptMFile: (statement | NL)* EOF
		   ;

statement
	: ID SemiColon?
	| assignment SemiColon?
	| if_statement
	| for_statement
	| whileStatement
    | expression SemiColon?
    | RETURN
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
		  | cell_access Equals expression
;

variable:
	ID
;

function_call
	: function_name LEFT_PARENTHESIS expression_list? RIGHT_PARENTHESIS
	| ID Dot function_call
;

function_name:
	ID
;

expression_list:
	expression (COMMA? expression)*
;

functionCallOutput: LeftSquareBracket functionCallOutputArgument (COMMA functionCallOutputArgument)* RightSquareBracket
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

expression
	: function_call
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
	| array_access
	| cell
	| cell_access
	| fieldAccess
	| reference
    | (INT | FLOAT | STRING | END | COLON);

array
	: LeftSquareBracket expression_list (';' expression_list)* RightSquareBracket
	| empty_array
;

empty_array:
	LeftSquareBracket RightSquareBracket
;

array_access
	: variable LEFT_PARENTHESIS expression_list RIGHT_PARENTHESIS
	| cell_access LEFT_PARENTHESIS expression_list RIGHT_PARENTHESIS
;

cell_access:
	variable LEFT_BRACE expression_list RIGHT_BRACE
;

cell:
	LEFT_BRACE expression_list RIGHT_BRACE
;

fieldAccess: ID '.(' ID ')'
		   | ID '.' ID
		   ; 

//// LEXER RULES

// Multiline statement
Ellipsis: '...' -> skip;

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

COLON: ':';

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
LEFT_PARENTHESIS: '(';
RIGHT_PARENTHESIS: ')';
LEFT_BRACE	: '{';
RIGHT_BRACE	: '}';
LeftSquareBracket: '[';
RightSquareBracket: ']';
AT	: '@';
Dot	: '.';
COMMA: ',';

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