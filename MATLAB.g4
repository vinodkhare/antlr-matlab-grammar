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
	CLASSDEF class_name LESS_THAN super_class_name (BINARY_AND super_class_name)*
	(	(PROPERTIES LEFT_PARENTHESIS property_attribute (ASSIGN property_attribute_value)? (COMMA property_attribute (ASSIGN property_attribute_value)?)* RIGHT_PARENTHESIS)?
			property_name*
		END		)*

	(	METHODS (LEFT_PARENTHESIS method_attribute (ASSIGN method_attribute_value)? (COMMA method_attribute (ASSIGN method_attribute_value)?)* RIGHT_PARENTHESIS)?
			function_definition*
		END		)*
	(RETURN | END)?
;

class_name
:	ID
;

super_class_name
:	ID
;

method_attribute
:	'Abstract'
|	'Access'
|	'Hidden'
|	'Sealed'
|	'Static'
;

method_attribute_value
:	bool
|	property_access_type
;

property_attribute
:	'AbortSet'
|	'Abstract'
|	'Access'
|	'Constant'
|	'Dependent'
|	'GetAccess'
|	'GetObservable'
|	'Hidden'
|	'NonCopyable'
|	'SetAccess'
|	'SetObservable'
|	'Transient'
;

property_attribute_value
:	bool
|	property_access_type
;

property_access_type
:	'private'
|	'public'
|	'protected'
|	'immutable'
;

function_definition
:	FUNCTION (function_returns ASSIGN)? function_name function_params?
		statement*
	(END | RETURN)?
;

function_handle_definition
:	AT function_name
|	AT function_params statement
;

function_params
:	LEFT_PARENTHESIS (identifier (COMMA identifier)*)? RIGHT_PARENTHESIS
;

function_returns
:	identifier
|	LEFT_SQUARE_BRACKET identifier (COMMA identifier)* RIGHT_SQUARE_BRACKET
;

statement
:	(	assignment
	|	command
	|	if_statement
	|	for_statement
	|	switch_statement
	|	try_statement
	|	while_statement
	|	function_call
	|	property_access
	| 	identifier
	| 	BREAK
	| 	CONTINUE
	| 	RETURN	)
(	COMMA | SEMI_COLON	)?
;

command:
	function_name command_argument+
;

// if_statement can be multiline or single line
if_statement
:	(IF expression COMMA?
		statement*
	(ELSEIF expression COMMA?
		statement*)*
	(ELSE
		statement*)?
	END)
|	IF expression (COMMA | SEMI_COLON) statement (COMMA | SEMI_COLON) END
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
// of assignment.
assignment
:	lvalue ASSIGN 
		(array | array_access | cell | cell_access | expression | function_call | identifier | property_access)
|	LEFT_SQUARE_BRACKET (lvalue | NOT) (COMMA (lvalue | NOT))* RIGHT_SQUARE_BRACKET ASSIGN
		(array | array_access | cell | cell_access | expression | function_call | identifier | property_access)
;

// Things that can be assigned *to*.
lvalue
:	array_access
|	cell_access
|	identifier
|	property_access
;

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
|	bool
|	cell
|	cell_access
|	empty_array
|	empty_cell
|	function_call
|	function_handle_definition
|	identifier
|	literal
|	property_access
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
:	(cell_access | identifier) LEFT_PARENTHESIS range (COMMA range)* RIGHT_PARENTHESIS
;

cell
:	LEFT_BRACE expression (COMMA? expression)* RIGHT_BRACE
|	LEFT_BRACE expression (COMMA? expression)* (SEMI_COLON expression (COMMA? expression)*)* RIGHT_BRACE
;

cell_access
:	identifier LEFT_BRACE range (COMMA range)* RIGHT_BRACE
;

function_call:
	function_name LEFT_PARENTHESIS (expression (COMMA expression)*)? RIGHT_PARENTHESIS
|	identifier DOT function_call
|	property_access DOT function_call
;

literal
:	INT
|	FLOAT
|	IMAGINARY
|	STRING
|	bool
|	empty_array
;

property_access:
	array_access DOT identifier
|	identifier DOT identifier
|	property_access DOT identifier
;

// ## Ranges in MATLAB
//
// Ranges in MATLAB can be written in the following forms
//
// * `:` - a simple color indicates the 'all' range.
// * `end` - indicates the last element of the array.
// * `A` - a single expression `A`
// * `A:B` - indicates a range from `A` to `B`, where `A` and `B` are any expression including
// `end`. Floats are accepted, they are incremented by 1.0. E.g. `2.3:4.5` evaluates to
// `[2.3000    3.3000    4.3000]`. 
// * `A:S:B` - indicates a range with a user specified step.
//
// There is an additional complication here. The special keyword `end` can be used in any range
// expression but does not have a meaning outside of array or cell access. E.g. if `a = randn(100, 1)`,
// then `a(end / 10)` is a valid expression. But the expression end / 10 itself outside of array
// or cell access doesn't have a meaning. Thus, we need two kinds of expressions - those that can
// be used in array/cell access that those that can be independent.
//
// This means that the `expression` parser rule must be duplicated with the addition of `end`.
// However, the fact that `end` is always a positive scalar int can help prune the rule definition.
range
:	COLON
|	(expression | END)
|	(expression | END) COLON (expression | END)
|	(expression | END) COLON (expression | END) COLON (expression | END)
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

property_name
:	ID
;

bool
:	'true'
|	'false'
;

empty_array
:	LEFT_SQUARE_BRACKET RIGHT_SQUARE_BRACKET
;

empty_cell
:	LEFT_BRACE RIGHT_BRACE
;

identifier
:	ID
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
AT						: '@';
COMMA					: ',' {maybeString = true;};
DOT						: '.';
SEMI_COLON				: ';' {maybeString = true;};
LEFT_BRACE				: '{' {maybeString = true;};
LEFT_PARENTHESIS		: '(' {maybeString = true;};
LEFT_SQUARE_BRACKET		: '[' {maybeString = true;};
RIGHT_BRACE				: '}' {maybeString = false;};
RIGHT_PARENTHESIS		: ')' {maybeString = false;};
RIGHT_SQUARE_BRACKET	: ']' {maybeString = false;};

// Comments
BLOCKCOMMENT	: '%{' .*?  '%}' -> channel(HIDDEN);

COMMENT			: '%' .*? NL  -> channel(HIDDEN);

THREEDOTS		: ('...' NL) -> skip;

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