grammar MATLAB;

@lexer::members
{
	boolean maybeString = false;
}

//// Parser Rules
matlab_file
:	(def_class | statement | def_function)*
;

// # Definitions
// 
// Definitions are MATLAB language constructs that only 'define' something. A definition when
// evaluated does not result in a value. A definition is a template only.

// Apparently MATLAB doesn't care whether you add commas to an array definition or not. E.g.
// [0 0 8]	[[0 0 8] [9 0 8]]	[[0 0 8],[9 0 8]]	[[0 0, 8],[9 0 8]] and
// [0 8 9, 10, 40 50 60] are all valid matlab expressions.
// The caveat is that you can't have two simultaneous commas. That throws an error. 
// E.g. [0,,1] is not allowed.
def_array
:	LEFT_SQUARE_BRACKET expression (COMMA? expression)* RIGHT_SQUARE_BRACKET
|	LEFT_SQUARE_BRACKET expression (COMMA? expression)* (SEMI_COLON expression (COMMA? expression)*)* RIGHT_SQUARE_BRACKET
;

def_cell
:	LEFT_BRACE expression (COMMA? expression)* RIGHT_BRACE
|	LEFT_BRACE expression (COMMA? expression)* (SEMI_COLON expression (COMMA? expression)*)* RIGHT_BRACE
;

def_class:
	CLASSDEF id_class LESS_THAN id_super (BINARY_AND id_super)*
	(	(PROPERTIES LEFT_PARENTHESIS property_attribute (ASSIGN property_attribute_value)? (COMMA property_attribute (ASSIGN property_attribute_value)?)* RIGHT_PARENTHESIS)?
			id_property*
		END		)*

	(	METHODS (LEFT_PARENTHESIS method_attribute (ASSIGN method_attribute_value)? (COMMA method_attribute (ASSIGN method_attribute_value)?)* RIGHT_PARENTHESIS)?
			def_function*
		END		)*
	(RETURN | END)?
;

def_function
:	FUNCTION (function_returns ASSIGN)? id_function function_params?
		statement*
	(END | RETURN)?
;

def_handle
:	AT id_function
|	AT function_params statement
;

// # Statements

// MATLAB does allow for return values to be specified without a COMMA, e.g. [h w] = size(X); 
// However, it does give a warning saying this is not recommended. Thus we don't parse this kind
// of assignment.
st_assign
:	lvalue ASSIGN 
		(def_array | xpr_array | def_cell | xpr_cell | expression | xpr_function | id_var | xpr_field)
|	LEFT_SQUARE_BRACKET (lvalue | NOT) (COMMA (lvalue | NOT))* RIGHT_SQUARE_BRACKET ASSIGN
		(def_array | xpr_array | def_cell | xpr_cell | expression | xpr_function | id_var | xpr_field)
;

st_command:
	id_function command_argument+
;

// if_statement can be multiline or single line
st_if
:	(IF expression COMMA?
		statement*
	(ELSEIF expression COMMA?
		statement*)*
	(ELSE
		statement*)?
	END)
|	IF expression (COMMA | SEMI_COLON) statement (COMMA | SEMI_COLON) END
;

st_for:
	FOR id_for ASSIGN expression COMMA?
		statement*
	END
;

st_switch:
	SWITCH expression
		(CASE expression
			statement*)*
		(OTHERWISE
			statement*)?
	END
;

st_try:
	TRY COMMA?
		statement*
	(CATCH id_exception?
		statement*)*
	END
;

st_while:
	WHILE expression COMMA?
		statement*
	END
;


method_attribute
:	'Abstract'
|	'Access'
|	'Hidden'
|	'Sealed'
|	'Static'
;

method_attribute_value
:	atom_boolean
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
:	atom_boolean
|	property_access_type
;

property_access_type
:	'private'
|	'public'
|	'protected'
|	'immutable'
;

function_params
:	LEFT_PARENTHESIS (id_var (COMMA id_var)*)? RIGHT_PARENTHESIS
;

function_returns
:	id_var
|	LEFT_SQUARE_BRACKET id_var (COMMA id_var)* RIGHT_SQUARE_BRACKET
;

statement
:	(	st_assign
	|	st_command
	|	st_if
	|	st_for
	|	st_switch
	|	st_try
	|	st_while
	|	xpr_function
	|	xpr_field
	| 	id_var
	| 	BREAK
	| 	CONTINUE
	| 	RETURN	)
(	COMMA | SEMI_COLON	)?
;

// Things that can be assigned *to*.
lvalue
:	xpr_array
|	xpr_cell
|	id_var
|	xpr_field
;

expression
:	LEFT_PARENTHESIS expression RIGHT_PARENTHESIS
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
|	def_array
|	xpr_array
|	atom_boolean
|	def_cell
|	xpr_cell
|	atom_empty_array
|	atom_empty_cell
|	xpr_function
|	def_handle
|	id_var
|	xpr_field
;

// An array expression in MATLAB is an expression that takes an array and indexes it to give
// some subset of the array. This can work on multidimentional arrays or cell arrays.
// 
// SYNTAX
//	identifier (index_express [, indexexpression] ...)
xpr_array
:	(xpr_cell | id_var) LEFT_PARENTHESIS xpr_index (COMMA xpr_index)* RIGHT_PARENTHESIS
;

xpr_cell
:	id_var LEFT_BRACE xpr_index (COMMA xpr_index)* RIGHT_BRACE
;

// a.b == identifier DOT identifier
// a.b.c == (a.b).c == field_access DOT identifier
// a.b.c.f() == ((a.b).c).f()
xpr_field
:	id_var DOT id_var
|	id_var DOT xpr_array
|	id_var DOT xpr_cell
|	id_var DOT xpr_function
|	xpr_array DOT id_var
|	xpr_array DOT xpr_array
|	xpr_array DOT xpr_cell
|	xpr_array DOT xpr_function
|	xpr_cell DOT id_var
|	xpr_cell DOT xpr_array
|	xpr_cell DOT xpr_cell
|	xpr_cell DOT xpr_function
|	xpr_field DOT id_var
|	xpr_field DOT xpr_array
|	xpr_field DOT xpr_cell
|	xpr_field DOT xpr_function
;

xpr_function
:	id_function LEFT_PARENTHESIS (expression (COMMA expression)*)? RIGHT_PARENTHESIS
;

// An index expression is any expression that (potentially) evaluates to an index that can be
// used for array/cell access. Index expression evaluate to positive integers or logical arrays.
// Index expressions can use two special syntaxes that are not applicable to expressions not
// used as indices. The first is the keyword `end`. The second is a free standing `:` that
// evaluates to `1:end` implicitly.
xpr_index
:	COLON
|	(	INT
	|	END
	|	STRING
	|	atom_boolean
	|	atom_empty_array
	|	id_var
	|	xpr_array
	|	LEFT_PARENTHESIS xpr_index RIGHT_PARENTHESIS
	|	xpr_index (TIMES | LEFT_DIVIDE | RIGHT_DIVIDE) xpr_index
	|	xpr_index (PLUS | MINUS) xpr_index
	)
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
|	xpr_index
|	xpr_index COLON xpr_index
|	xpr_index COLON xpr_index COLON xpr_index
;

command_argument
:	ID
;

// ID of a class
id_class
:	ID
;

// ID of an exception in a try/catch statement
id_exception:
	ID
;

// The ID of the index variable for a 'for' loop
id_for
:	ID
;

// ID of a function
id_function
:	ID
;

// ID of a property in a class
id_property
:	ID
;

// ID of a superclass from which a class is derived
id_super
:	ID
;

// ID of a variable
id_var
:	ID
;

atom_boolean
:	'true'
|	'false'
;

atom_float
:	FLOAT
;

atom_imaginary
:	IMAGINARY
;

atom_integer
:	INT
;

atom_string
:	STRING
;

atom_empty_array
:	LEFT_SQUARE_BRACKET RIGHT_SQUARE_BRACKET
;

atom_empty_cell
:	LEFT_BRACE RIGHT_BRACE
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