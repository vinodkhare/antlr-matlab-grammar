grammar MATLAB;

@lexer::members
{
	boolean maybeString = false;
}

//// Parser Rules

matlab_file:
	(statement | function_definition)*
;

function_definition:
	FUNCTION (rvalue_arguments ASSIGN)? function_name lvalue_arguments?
		statement*
	(RETURN | END)?
;

rvalue_arguments:
	LEFT_SQUARE_BRACKET (variable (COMMA? variable)*)? RIGHT_SQUARE_BRACKET
;

lvalue_arguments:
	LEFT_PARENTHESIS ((variable | NOT) (COMMA? (variable | NOT))*)? RIGHT_PARENTHESIS
;

statement:
	( assignment
	| command
	| if_statement
	| for_statement
	| switch_statement
	| try_statement
	| while_statement
	| expression_list
	| function_call
	| variable
	| BREAK
	| CONTINUE
    | RETURN
	| SEMI_COLON
	) (COMMA | SEMI_COLON)?
;

assignment
	: LEFT_SQUARE_BRACKET lvalue_list RIGHT_SQUARE_BRACKET ASSIGN expression
	| lvalue ASSIGN expression
;

lvalue_list:
	lvalue (COMMA? lvalue)*
;

command:
	function_name command_argument+
;

if_statement:
	IF expression COMMA?
		statement*
	(ELSEIF expression COMMA?
		statement*)*
	(ELSE
		statement*)?
	END
;

for_statement:
	FOR for_index ASSIGN expression
		statement*
	END
;

for_index:
	ID
;

switch_statement:
	SWITCH expression
		(CASE expression
			statement*)*
		(OTHERWISE
			statement*)?
	END
;

try_statement:
	TRY COMMA?
		statement*
	(CATCH exception?
		statement*)*
	END
;

while_statement:
	WHILE expression
		statement*
	END
;

// Things that can be assigned
expression
	: expression DOT expression
	| LEFT_PARENTHESIS expression RIGHT_PARENTHESIS		
	| expression ELMENT_WISE_TRANSPOSE					
	| expression ELMENT_WISE_POWER expression			
	| expression TRANSPOSE								
	| expression POWER expression						
	| PLUS expression								
	| MINUS expression							
	| NOT expression									
	| expression ELMENT_WISE_TIMES expression			
	| expression ELMENT_WISE_RIGHT_DIVIDE expression	
	| expression ELMENT_WISE_LEFT_DIVIDE expression		
	| expression TIMES expression						
	| expression RIGHT_DIVIDE expression				
	| expression LEFT_DIVIDE expression					
	| expression PLUS expression						
	| expression MINUS expression						
	| expression COLON expression						
	| expression LESS_THAN expression					
	| expression LESS_THAN_OR_EQUAL expression			
	| expression GREATER_THAN expression				
	| expression GREATER_THAN_OR_EQUAL expression		
	| expression EQUALS expression						
	| expression NOT_EQUAL expression							
	| expression BINARY_AND expression					
	| expression BINARY_OR expression					
	| expression LOGICAL_AND expression					
	| expression LOGICAL_OR expression		
	| array			
	| cell												
	| function_call										
	| function_handle								
	| lvalue											
    | (INT | FLOAT | IMAGINARY | STRING | END | COLON)	
;

array:
	LEFT_SQUARE_BRACKET expression_list? RIGHT_SQUARE_BRACKET
;

cell:
	LEFT_BRACE expression_list? RIGHT_BRACE
;

function_call:
	function_name LEFT_PARENTHESIS expression_list? RIGHT_PARENTHESIS
;

function_handle
	: AT function_name
	| AT lvalue_arguments statement
;

// Things that can be assigned *to*.
lvalue
	: lvalue DOT lvalue
	| lvalue DOT LEFT_PARENTHESIS expression RIGHT_PARENTHESIS
	| lvalue LEFT_PARENTHESIS expression_list RIGHT_PARENTHESIS
	| lvalue LEFT_BRACE expression_list RIGHT_BRACE
	| variable
	| NOT
;

expression_list:
	expression (COMMA? expression)* (SEMI_COLON expression (COMMA? expression)*)* SEMI_COLON?
;

command_argument:
	ID
;

exception:
	ID
;

function_name:
	ID
;

namespace:
	ID
;

variable:
	ID
;

//// LEXER RULES

// New Line
NL : ('\r' '\n' | '\r' | '\n') -> channel(HIDDEN);

// Multiline statement
ELLIPSIS: '...' -> skip;

// Keywords
BREAK	   	: 'break';
CASE	   	: 'case';
CATCH	   	: 'catch';
CONTINUE   	: 'continue';
ELSE	   	: 'else';
ELSEIF	   	: 'elseif';
END	   		: 'end';
FOR	   		: 'for';
FUNCTION   	: 'function';
GLOBAL	   	: 'global';
IF	   		: 'if';
OTHERWISE  	: 'otherwise';
PERSISTENT 	: 'persistent';
RETURN	   	: 'return';
SWITCH	   	: 'switch';
TRY	   		: 'try';
WHILE	   	: 'while';

// Two Character Operators
ELMENT_WISE_LEFT_DIVIDE		: './';
ELMENT_WISE_POWER			: '.^';
ELMENT_WISE_RIGHT_DIVIDE	: '.\\';
ELMENT_WISE_TIMES			: '.*';
ELMENT_WISE_TRANSPOSE		: '.\'';
EQUALS						: '==' {maybeString = true;};
GREATER_THAN_OR_EQUAL		: '>=';
LESS_THAN_OR_EQUAL			: '<=';
LOGICAL_AND					: '&&';
LOGICAL_OR					: '||';
NOT_EQUAL					: '~=';

// Single Character Operators
ASSIGN			: '=' {maybeString = true;};
BINARY_AND		: '&';
BINARY_OR		: '|';
COLON			: ':';
GREATER_THAN	: '>';
LEFT_DIVIDE		: '/';
LESS_THAN		: '<';
MINUS			: '-';
NOT				: '~';
PLUS			: '+';
POWER			: '^';
RIGHT_DIVIDE	: '\\';
TIMES			: '*';
TRANSPOSE		: '\'';

// Special Characters
AT	: '@';
COMMA: ',' {maybeString = true;};
DOT	: '.';
SEMI_COLON: ';' {maybeString = true;};
LEFT_BRACE	: '{' {maybeString = true;};
LEFT_PARENTHESIS: '(' {maybeString = true;};
LEFT_SQUARE_BRACKET: '[' {maybeString = true;};
RIGHT_BRACE	: '}' {maybeString = false;};
RIGHT_PARENTHESIS: ')' {maybeString = false;};
RIGHT_SQUARE_BRACKET: ']' {maybeString = false;};
SINGLE_QUOTE: '\'';

// Comments
BLOCKCOMMENT: '%{' .*?  '%}' -> channel(HIDDEN);

COMMENT: '%' .*? NL  -> channel(HIDDEN);

THREEDOTS: ('...' NL) -> skip;

// identifiers, strings, numbers, whitespace
ID: [a-zA-Z] [a-zA-Z0-9_]* {maybeString = false;};

IMAGINARY
	: INT 'i'
	| FLOAT 'i'
;

INT: DIGIT+;

FLOAT: DIGIT+ '.' DIGIT* EXPONENT?
     | DIGIT+ EXPONENT
     | '.' DIGIT+ EXPONENT?;

fragment
EXPONENT: ('e'|'E') ('+'|'-')? DIGIT+;

fragment
DIGIT: [0-9];

STRING : {maybeString}? '\'' ( ~('\'' | '\r' | '\n') )* '\'';

WS : [ \t] {maybeString = true;} -> skip;