grammar MATLAB;

@lexer::members
{
	boolean maybeString = false;
}

//// Parser Rules
matlab_file:
	(class_definition | statement | function_definition)*
;

class_definition:
	CLASSDEF class_name
		PROPERTIES
			property_name*
		END

		METHODS
			function_definition*
		END
	(RETURN | END)?
;

function_definition:
(	FUNCTION LEFT_SQUARE_BRACKET variable (COMMA variable)* RIGHT_SQUARE_BRACKET ASSIGN function_name LEFT_PARENTHESIS variable (COMMA variable)* RIGHT_PARENTHESIS
|	FUNCTION 					 variable 					   ASSIGN function_name LEFT_PARENTHESIS variable (COMMA variable)* RIGHT_PARENTHESIS	
|	FUNCTION 									 					  function_name
)	statement*
	(END | RETURN)?
;

rvalue_arguments
	: LEFT_SQUARE_BRACKET (variable (COMMA? variable)*)? RIGHT_SQUARE_BRACKET
	| variable
;

lvalue_arguments:
	LEFT_PARENTHESIS ((variable | NOT) (COMMA? (variable | NOT))*)? RIGHT_PARENTHESIS
;

statement
:	
(	assignment
|	command
|	if_statement
|	for_statement
|	switch_statement
|	try_statement
|	while_statement
|	function_call
|	property_access
| 	variable
| 	BREAK
| 	CONTINUE
| 	RETURN	
)
(	COMMA | SEMI_COLON	)?
;

property_access:
	array_access DOT variable
|	variable DOT variable
|	property_access DOT variable
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
	FOR for_index ASSIGN expression COMMA?
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
	WHILE expression COMMA?
		statement*
	END
;

// MATLAB does allow for return values to be specified without a COMMA, e.g. [h w] = size(X); 
// However, it does give a warning saying this is not recommended. Thus we don't parse this kind
// of function call.
assignment
:	array_access ASSIGN cell
|	array_access ASSIGN expression
|	array_access ASSIGN function_call
|	array_access ASSIGN variable
|	cell_access ASSIGN cell
|	cell_access ASSIGN expression
|	cell_access ASSIGN function_call
|	cell_access ASSIGN variable
|	property_access ASSIGN array_access
|	property_access ASSIGN variable
|	variable ASSIGN array
|	variable ASSIGN cell
|	variable ASSIGN expression
|	variable ASSIGN function_call
|	variable ASSIGN property_access
|	variable ASSIGN LEFT_SQUARE_BRACKET RIGHT_SQUARE_BRACKET
|	LEFT_SQUARE_BRACKET (array_access | variable | NOT) (COMMA (array_access | variable | NOT))* RIGHT_SQUARE_BRACKET ASSIGN expression
|	LEFT_SQUARE_BRACKET (array_access | variable | NOT) (COMMA (array_access | variable | NOT))* RIGHT_SQUARE_BRACKET ASSIGN function_call
;

// Things that can be assigned
expression
:	expression DOT expression
|	LEFT_PARENTHESIS expression RIGHT_PARENTHESIS
|	expression ELMENT_WISE_TRANSPOSE
|	expression ELMENT_WISE_POWER expression
|	expression TRANSPOSE
|	expression POWER expression
|	PLUS expression
|	MINUS expression
|	NOT expression
|	expression ELMENT_WISE_TIMES expression
|	expression ELMENT_WISE_RIGHT_DIVIDE expression
|	expression ELMENT_WISE_LEFT_DIVIDE expression
|	expression TIMES expression
|	expression RIGHT_DIVIDE expression
|	expression LEFT_DIVIDE expression
|	expression PLUS expression
|	expression MINUS expression
|	expression COLON expression
|	expression LESS_THAN expression
|	expression LESS_THAN_OR_EQUAL expression
|	expression GREATER_THAN expression
|	expression GREATER_THAN_OR_EQUAL expression
|	expression EQUALS expression
|	expression NOT_EQUAL expression
|	expression BINARY_AND expression
|	expression BINARY_OR expression
|	expression LOGICAL_AND expression
|	expression LOGICAL_OR expression
|	array
|	array_access
|	cell
|	function_call
|	function_handle
|	lvalue
|	(INT | FLOAT | IMAGINARY | STRING | END | COLON)
;

// Apparently MATLAB doesn't care whether you add commas to an array definition or not. E.g.
// [0 0 8]	[[0 0 8] [9 0 8]]	[[0 0 8],[9 0 8]]	[[0 0, 8],[9 0 8]] and
// [0 8 9, 10, 40 50 60] are all valid matlab expressions.
// The caveat is that you can't have two simultaneous commas. That throws an error. 
// E.g. [0,,1] is not allowed.
array
:	LEFT_SQUARE_BRACKET expression (COMMA? expression)* RIGHT_SQUARE_BRACKET
|	LEFT_SQUARE_BRACKET expression (COMMA? expression)* (SEMI_COLON expression (COMMA? expression)*)* RIGHT_SQUARE_BRACKET
;

array_access
:	(cell_access | variable) LEFT_PARENTHESIS range (COMMA range)* RIGHT_PARENTHESIS
;

cell
:	LEFT_BRACE expression (COMMA? expression)* RIGHT_BRACE
|	LEFT_BRACE expression (COMMA? expression)* (SEMI_COLON expression (COMMA? expression)*)* RIGHT_BRACE
;

cell_access
:	variable LEFT_BRACE range (COMMA range)* RIGHT_BRACE
;

function_call:
	function_name LEFT_PARENTHESIS (expression (COMMA expression)*)? RIGHT_PARENTHESIS
|	property_access DOT function_call
;

function_handle
	: AT function_name
	| AT lvalue_arguments statement
;

// Things that can be assigned *to*.
lvalue:
	array_access
|	lvalue DOT lvalue
|	lvalue DOT LEFT_PARENTHESIS expression RIGHT_PARENTHESIS
|	lvalue LEFT_BRACE expression_list RIGHT_BRACE
|	variable
|	NOT
;



// ## Ranges in MATLAB
//
// Ranges in MATLAB can be written in the following forms
//
// * `:` - a simple color indicates the 'all' range.
// * `end` - indicates the last element of the array.
// * `A` - a single expression `A`
// * `A:B` - indicates a range from `A` to `B`, where `A` and `B` are any expression including `end`. Floats are accepted, they are incremented by 1.0. E.g. `2.3:4.5` evaluates to `[2.3000    3.3000    4.3000]`.
// * `A:S:B` - indicates a range with a user specified step.
range:
	COLON
|	(expression | END)
|	(expression | END) COLON (expression | END)
|	(expression | END) COLON (expression | END) COLON (expression | END)
;

expression_list:
	expression (COMMA? expression)* (SEMI_COLON expression (COMMA? expression)*)* SEMI_COLON?
;

class_name
	: ID
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

property_name
	: ID
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
BREAK		: 'break';
CASE		: 'case';
CATCH		: 'catch';
CLASSDEF	: 'classdef';
CONTINUE	: 'continue';
ELSE		: 'else';
ELSEIF		: 'elseif';
END			: 'end';
FOR			: 'for';
FUNCTION	: 'function';
GLOBAL		: 'global';
IF			: 'if';
METHODS		: 'methods';
OTHERWISE	: 'otherwise';
PERSISTENT	: 'persistent';
PROPERTIES	: 'properties';
RETURN		: 'return';
SWITCH		: 'switch';
TRY			: 'try';
WHILE		: 'while';

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

STRING : {maybeString}? '\'' ( ~('\'' | '\r' | '\n') | '\'\'')* '\'';

WS : [ \t] {maybeString = true;} -> skip;