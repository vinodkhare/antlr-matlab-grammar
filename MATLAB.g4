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
		(xpr_array | xpr_array_index | xpr_cell | xpr_cell_index | xpr_tree | xpr_function | id_var | xpr_field)
|	LEFT_SQUARE_BRACKET (lvalue | NOT) (COMMA (lvalue | NOT))* RIGHT_SQUARE_BRACKET ASSIGN
		(xpr_array | xpr_array_index | xpr_cell | xpr_cell_index | xpr_tree | xpr_function | id_var | xpr_field)
;

st_command:
	id_function command_argument+
;

// if_statement can be multiline or single line
st_if
:	(IF xpr_tree COMMA?
		statement*
	(ELSEIF xpr_tree COMMA?
		statement*)*
	(ELSE
		statement*)?
	END)
|	IF xpr_tree (COMMA | SEMI_COLON) statement (COMMA | SEMI_COLON) END
;

st_for:
	FOR id_for ASSIGN xpr_tree COMMA?
		statement*
	END
;

st_switch:
	SWITCH xpr_tree
		(CASE xpr_tree
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
	WHILE xpr_tree COMMA?
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
:	xpr_array_index
|	xpr_cell_index
|	id_var
|	xpr_field
;

xpr_tree
:	atom_boolean
|	atom_empty_array
|	atom_float
|	atom_imaginary
|	atom_integer
|	atom_string
|	atom_var
|	xpr_array
|	xpr_array_index
|	xpr_cell
|	xpr_cell_index
|	xpr_field
|	xpr_function
|	LEFT_PARENTHESIS xpr_tree RIGHT_PARENTHESIS
|	xpr_tree (ELMENT_WISE_TRANSPOSE | TRANSPOSE)
|	xpr_tree (ELMENT_WISE_POWER | POWER) xpr_tree
|	(PLUS | MINUS | NOT) xpr_tree
|	xpr_tree (ELMENT_WISE_TIMES | ELMENT_WISE_RIGHT_DIVIDE | ELMENT_WISE_LEFT_DIVIDE) xpr_tree
|	xpr_tree (TIMES | RIGHT_DIVIDE | LEFT_DIVIDE) xpr_tree
|	xpr_tree (PLUS | MINUS) xpr_tree
|	xpr_tree COLON xpr_tree
|	xpr_tree LESS_THAN xpr_tree
|	xpr_tree LESS_THAN_OR_EQUAL xpr_tree
|	xpr_tree GREATER_THAN xpr_tree
|	xpr_tree GREATER_THAN_OR_EQUAL xpr_tree
|	xpr_tree EQUALS xpr_tree
|	xpr_tree NOT_EQUAL xpr_tree
|	xpr_tree BINARY_AND xpr_tree
|	xpr_tree BINARY_OR xpr_tree
|	xpr_tree LOGICAL_AND xpr_tree
|	xpr_tree LOGICAL_OR xpr_tree
;

// Apparently MATLAB doesn't care whether you add commas to an array definition or not. E.g.
// [0 0 8]	[[0 0 8] [9 0 8]]	[[0 0 8],[9 0 8]]	[[0 0, 8],[9 0 8]] and
// [0 8 9, 10, 40 50 60] are all valid matlab expressions.
// The caveat is that you can't have two simultaneous commas. That throws an error. 
// E.g. [0,,1] is not allowed.
xpr_array
:	LEFT_SQUARE_BRACKET xpr_tree (COMMA? xpr_tree)* RIGHT_SQUARE_BRACKET
|	LEFT_SQUARE_BRACKET xpr_tree (COMMA? xpr_tree)* (SEMI_COLON xpr_tree (COMMA? xpr_tree)*)* RIGHT_SQUARE_BRACKET
;

xpr_cell
:	LEFT_BRACE xpr_tree (COMMA? xpr_tree)* RIGHT_BRACE
|	LEFT_BRACE xpr_tree (COMMA? xpr_tree)* (SEMI_COLON xpr_tree (COMMA? xpr_tree)*)* RIGHT_BRACE
;

// An array_index expression in MATLAB is an expression that takes an array and indexes it to give
// some subset of the array. This can work on multidimentional arrays or cell arrays.
// 
// SYNTAX
//	identifier (index_express [, indexexpression] ...)
xpr_array_index
:	(xpr_cell_index | id_var) LEFT_PARENTHESIS (atom_index_all | xpr_index) (COMMA (atom_index_all | xpr_index))* RIGHT_PARENTHESIS
;

xpr_cell_index
:	id_var LEFT_BRACE (atom_index_all | xpr_index) (COMMA (atom_index_all | xpr_index))* RIGHT_BRACE
;

// a.b == identifier DOT identifier
// a.b.c == (a.b).c == field_access DOT identifier
// a.b.c.f() == ((a.b).c).f()
xpr_field
:	id_var DOT id_var
|	id_var DOT xpr_array_index
|	id_var DOT xpr_cell_index
|	id_var DOT xpr_function
|	xpr_array_index DOT id_var
|	xpr_array_index DOT xpr_array_index
|	xpr_array_index DOT xpr_cell_index
|	xpr_array_index DOT xpr_function
|	xpr_cell_index DOT id_var
|	xpr_cell_index DOT xpr_array_index
|	xpr_cell_index DOT xpr_cell_index
|	xpr_cell_index DOT xpr_function
|	xpr_field DOT id_var
|	xpr_field DOT xpr_array_index
|	xpr_field DOT xpr_cell_index
|	xpr_field DOT xpr_function
;

xpr_function
:	id_function LEFT_PARENTHESIS (xpr_tree (COMMA xpr_tree)*)? RIGHT_PARENTHESIS
;

// An index expression is any expression that (potentially) evaluates to an index that can be
// used for array/cell access. Index expression evaluate to positive integers or logical arrays.
// Index expressions can use two special syntaxes that are not applicable to expressions not
// used as indices. The first is the keyword `end`. The second is a free standing `:` that
// evaluates to `1:end` implicitly.
xpr_index
:	atom_boolean
|	atom_empty_array
|	atom_end
|	atom_float
|	atom_imaginary
|	atom_integer
|	atom_string
|	atom_var
|	xpr_array
|	xpr_array_index
|	xpr_cell
|	xpr_cell_index
|	xpr_field
|	xpr_function
|	LEFT_PARENTHESIS xpr_tree RIGHT_PARENTHESIS
|	xpr_tree (ELMENT_WISE_TRANSPOSE | TRANSPOSE)
|	xpr_tree (ELMENT_WISE_POWER | POWER) xpr_tree
|	(PLUS | MINUS | NOT) xpr_tree
|	xpr_tree (ELMENT_WISE_TIMES | ELMENT_WISE_RIGHT_DIVIDE | ELMENT_WISE_LEFT_DIVIDE) xpr_tree
|	xpr_tree (TIMES | RIGHT_DIVIDE | LEFT_DIVIDE) xpr_tree
|	xpr_tree (PLUS | MINUS) xpr_tree
|	xpr_tree COLON xpr_tree
|	xpr_tree LESS_THAN xpr_tree
|	xpr_tree LESS_THAN_OR_EQUAL xpr_tree
|	xpr_tree GREATER_THAN xpr_tree
|	xpr_tree GREATER_THAN_OR_EQUAL xpr_tree
|	xpr_tree EQUALS xpr_tree
|	xpr_tree NOT_EQUAL xpr_tree
|	xpr_tree BINARY_AND xpr_tree
|	xpr_tree BINARY_OR xpr_tree
|	xpr_tree LOGICAL_AND xpr_tree
|	xpr_tree LOGICAL_OR xpr_tree
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

atom_empty_array
:	LEFT_SQUARE_BRACKET RIGHT_SQUARE_BRACKET
;

atom_empty_cell
:	LEFT_BRACE RIGHT_BRACE
;

atom_end
:	END
;

atom_float
:	FLOAT
;

atom_imaginary
:	IMAGINARY
;

atom_index_all
:	COLON
;

atom_integer
:	INT
;

atom_string
:	STRING
;

atom_var
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