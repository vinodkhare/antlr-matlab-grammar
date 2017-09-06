/*
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */

grammar MATLAB;

//// Parser Rules

matlab_file:
	(statement | function_definition)*
;

function_definition:
	FUNCTION (function_output_arguments ASSIGN)? function_name function_input_arguments?
		statement*
	(RETURN | END)?
;

function_output_arguments:
	LEFT_SQUARE_BRACKET variable_list? RIGHT_SQUARE_BRACKET
;

function_input_arguments:
	LEFT_PARENTHESIS variable_list? RIGHT_PARENTHESIS
;

variable_list:
	variable (COMMA? variable)*
;

statement:
	( ID
	| assignment
	| if_command
	| if_statement
	| for_statement
	| switch_statement
	| while_statement
	| expression_list
	| BREAK
	| CONTINUE
    | RETURN
	| SEMI_COLON
	) SEMI_COLON?
;

assignment
	: LEFT_SQUARE_BRACKET rvalue_list RIGHT_SQUARE_BRACKET ASSIGN expression
	| rvalue ASSIGN expression
;

rvalue_list:
	rvalue (COMMA? rvalue)*
;

if_command:
	IF expression COMMA statement (ELSE statement)? END
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

while_statement:
	WHILE expression
		statement*
	END
;

expression
	: LEFT_PARENTHESIS expression RIGHT_PARENTHESIS		#Parenthesis
	| expression ELMENT_WISE_TRANSPOSE					#ElementWiseTranspose
	| expression ELMENT_WISE_POWER expression			#ElementWisePower	
	| expression TRANSPOSE								#Transpose
	| expression POWER expression						#Power
	| UNARY_PLUS expression								#UnaryPlus
	| UNARY_MINUS expression							#UnaryMinus
	| NOT expression									#Negation
	| expression ELMENT_WISE_TIMES expression			#ElementWiseMultiplication
	| expression ELMENT_WISE_RIGHT_DIVIDE expression	#ElementWiseRightDivision
	| expression ELMENT_WISE_LEFT_DIVIDE expression		#ElementWiseLeftDivision
	| expression TIMES expression						#Multiplication
	| expression RIGHT_DIVIDE expression				#RightDivision
	| expression LEFT_DIVIDE expression					#LeftDivision
	| expression PLUS expression						#Addition
	| expression MINUS expression						#Subtraction
	| expression COLON expression						#Range
	| expression LESS_THAN expression					#LessThan
	| expression LESS_THAN_OR_EQUAL expression			#LessThanOrEqual 
	| expression GREATER_THAN expression				#GreaterThan
	| expression GREATER_THAN_OR_EQUAL expression		#GreaterThanOrEqual
	| expression EQUALS expression						#Equals
	| expression NOT expression							#NotEqual
	| expression BINARY_AND expression					#BinaryAnd
	| expression BINARY_OR expression					#BinaryOr
	| expression LOGICAL_AND expression					#LogicalAnd
	| expression LOGICAL_OR expression					#LogicalOr
	| array												#ArrayAtom
	| cell												#CellAtom
	| function_call										#FunctionCall	
	| function_handle									#FunctionHandle
	| rvalue											#RValueAtom
    | (INT | FLOAT | STRING | END | COLON)				#Atom
;

array:
	LEFT_SQUARE_BRACKET expression_list? RIGHT_SQUARE_BRACKET
;

cell:
	LEFT_BRACE expression_list? RIGHT_BRACE
;

function_call
	: function_name LEFT_PARENTHESIS expression_list? RIGHT_PARENTHESIS
;

function_handle
	: AT function_name
	| AT function_input_arguments statement
;

rvalue
	: rvalue DOT rvalue
	| rvalue LEFT_PARENTHESIS expression_list RIGHT_PARENTHESIS
	| rvalue LEFT_BRACE expression_list RIGHT_BRACE
	| variable
	| NOT
;

expression_list:
	expression (COMMA? expression)* (SEMI_COLON expression (COMMA? expression)*)*
;

function_name:
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
CLEAR	   	: 'clear';

// Two Character Operators
ELMENT_WISE_LEFT_DIVIDE		: './';
ELMENT_WISE_POWER			: '.^';
ELMENT_WISE_RIGHT_DIVIDE	: '.\\';
ELMENT_WISE_TIMES			: '.*';
ELMENT_WISE_TRANSPOSE		: '.\'';
EQUALS						: '==';
GREATER_THAN_OR_EQUAL		: '>=';
LESS_THAN_OR_EQUAL			: '<=';
LOGICAL_AND					: '&&';
LOGICAL_OR					: '||';
NOT_EQUAL					: '~=';

// Single Character Operators
ASSIGN			: '=';
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
UNARY_MINUS		: '-';
UNARY_PLUS		: '+';

// Special Characters
AT	: '@';
COMMA: ',';
DOT	: '.';
SEMI_COLON: ';';
LEFT_BRACE	: '{';
LEFT_PARENTHESIS: '(';
LEFT_SQUARE_BRACKET: '[';
RIGHT_BRACE	: '}';
RIGHT_PARENTHESIS: ')';
RIGHT_SQUARE_BRACKET: ']';
SINGLE_QUOTE: '\'';

// Comments
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