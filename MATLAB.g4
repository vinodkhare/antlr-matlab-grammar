grammar MATLAB;

@lexer::members
{
	boolean maybeString = false;
}

//// Parser Rules
matlab_file:
	( def_class | statement | def_function )*
;

// # Definitions
// 
// Definitions are MATLAB language constructs that only 'define' something. A definition when
// evaluated does not result in a value. A definition is a template only.

def_class
:	CLASSDEF 
	(	LEFT_PARENTHESIS 
		( attrib_class_boolean ( ASSIGN atom_boolean )? | attrib_class_meta ( ASSIGN atom_meta )? )*
		RIGHT_PARENTHESIS
	)?
	id_class 
	LESS_THAN 
	id_super (BINARY_AND id_super)*

	(	PROPERTIES
		(	LEFT_PARENTHESIS
			(	attrib_property_boolean ( ASSIGN atom_boolean )?
			|	attrib_property_access  ( ASSIGN atom_access )?
			)+	// One or more attributes
			RIGHT_PARENTHESIS
		)?	// Zero or one property attribute blocks
		id_property*
		END
	)*	// Zero or more property blocks
	
	(	METHODS
		(	LEFT_PARENTHESIS
			(	attrib_method_boolean ( ASSIGN atom_boolean )?
			|	attrib_method_access  ( ASSIGN atom_access )?
			)+	// One or more attributes
			RIGHT_PARENTHESIS
		)?	// Zero or one property attribute blocks
		( def_function | def_function_access )*
		END
	)*	// Zero or more property blocks

	( RETURN | END )?
;

def_function:
	FUNCTION (function_returns ASSIGN)? id_function function_params?
	statement*
	(END | RETURN)?
;

def_function_access:
	FUNCTION (function_returns ASSIGN)? ('get' | 'set') DOT id_property function_params?
	statement*
	(END | RETURN)?
;

attrib_class_boolean
:	'Abstract'
|	'ConstructOnLoad'
|	'HandleCompatible'
|	'Hidden'
|	'Sealed'
;

attrib_class_meta
:	'AllowedSubclasses'
|	'InferiorClasses'
;

attrib_property_boolean
:	'AbortSet'
|	'Abstract'
|	'Constant'
|	'Dependent'
|	'GetObservable'
|	'Hidden'
|	'NonCopyable'
|	'SetObservable'
|	'Transient'
;

attrib_property_access
:	'Access'
|	'GetAccess'
|	'SetAccess'	
;

attrib_method_boolean
:	'Abstract'
|	'Hidden'
|	'Sealed'
|	'Static'
;

attrib_method_access
:	'Access'
;

atom_access
:	'public'
|	'protected'
|	'private'
|	atom_meta
;

// # Statements

// MATLAB does allow for return values to be specified without a COMMA, e.g. [h w] = size(X); 
// However, it does give a warning saying this is not recommended. Thus we don't parse this kind
// of assignment.
st_assign
:	( id_var | xpr_array_index | xpr_cell_index | xpr_field )
  	ASSIGN 
	( atom_empty_cell | xpr_tree | xpr_handle )

| 	LEFT_SQUARE_BRACKET 
	( NOT | id_var | xpr_array_index | xpr_cell_index | xpr_field ) 
	( COMMA ( NOT | id_var | xpr_array_index | xpr_cell_index | xpr_field ) )* 
  	RIGHT_SQUARE_BRACKET

	ASSIGN 
	
	( atom_empty_cell | xpr_tree | xpr_handle )
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

function_params
:	LEFT_PARENTHESIS (id_var (COMMA id_var)*)? RIGHT_PARENTHESIS
;

function_returns
:	id_var
|	LEFT_SQUARE_BRACKET id_var (COMMA id_var)* RIGHT_SQUARE_BRACKET
;

statement:
	(	st_assign
	| 	st_command
	| 	st_if
	| 	st_for
	| 	st_switch
	| 	st_try
	| 	st_while
	| 	xpr_function
	| 	xpr_field
	| 	xpr_tree
	| 	id_var
	| 	BREAK
	| 	CONTINUE
	| 	RETURN
	)
( COMMA | SEMI_COLON )?
;

// ## Expression Trees
//
// Expression trees model a generic expression in MATLAB. The difference between `xpr_tree` and
// `xpr_tree_` (with underscore) is that `xpr_tree_` includes the `end` keyword can can be used
// for array or cell indexing. To make this work we also need `xpr_array_` and `xpr_cell_` which
// are analogous.
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

xpr_tree_
:	atom_boolean
|	atom_empty_array
|	atom_end
|	atom_float
|	atom_imaginary
|	atom_integer
|	atom_string
|	atom_var
|	xpr_array_
|	xpr_array_index
|	xpr_cell_
|	xpr_cell_index
|	xpr_field
|	xpr_function
|	LEFT_PARENTHESIS xpr_tree_ RIGHT_PARENTHESIS
|	xpr_tree_ (ELMENT_WISE_TRANSPOSE | TRANSPOSE)
|	xpr_tree_ (ELMENT_WISE_POWER | POWER) xpr_tree_
|	(PLUS | MINUS | NOT) xpr_tree_
|	xpr_tree_ (ELMENT_WISE_TIMES | ELMENT_WISE_RIGHT_DIVIDE | ELMENT_WISE_LEFT_DIVIDE) xpr_tree_
|	xpr_tree_ (TIMES | RIGHT_DIVIDE | LEFT_DIVIDE) xpr_tree_
|	xpr_tree_ (PLUS | MINUS) xpr_tree_
|	xpr_tree_ COLON xpr_tree_
|	xpr_tree_ LESS_THAN xpr_tree_
|	xpr_tree_ LESS_THAN_OR_EQUAL xpr_tree_
|	xpr_tree_ GREATER_THAN xpr_tree_
|	xpr_tree_ GREATER_THAN_OR_EQUAL xpr_tree_
|	xpr_tree_ EQUALS xpr_tree_
|	xpr_tree_ NOT_EQUAL xpr_tree_
|	xpr_tree_ BINARY_AND xpr_tree_
|	xpr_tree_ BINARY_OR xpr_tree_
|	xpr_tree_ LOGICAL_AND xpr_tree_
|	xpr_tree_ LOGICAL_OR xpr_tree_
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

xpr_array_
:	LEFT_SQUARE_BRACKET xpr_tree_ (COMMA? xpr_tree_)* RIGHT_SQUARE_BRACKET
|	LEFT_SQUARE_BRACKET xpr_tree_ (COMMA? xpr_tree_)* (SEMI_COLON xpr_tree_ (COMMA? xpr_tree_)*)* RIGHT_SQUARE_BRACKET
;

xpr_cell
:	LEFT_BRACE (xpr_tree | xpr_handle) (COMMA? (xpr_tree | xpr_handle))* RIGHT_BRACE
|	LEFT_BRACE (xpr_tree | xpr_handle) (COMMA? (xpr_tree | xpr_handle))* (SEMI_COLON (xpr_tree | xpr_handle) (COMMA? (xpr_tree | xpr_handle))*)* RIGHT_BRACE
;

xpr_cell_
:	LEFT_BRACE xpr_tree_ (COMMA? xpr_tree_)* RIGHT_BRACE
|	LEFT_BRACE xpr_tree_ (COMMA? xpr_tree_)* (SEMI_COLON xpr_tree_ (COMMA? xpr_tree_)*)* RIGHT_BRACE
;

// An array_index expression in MATLAB is an expression that takes an array and indexes it to give
// some subset of the array. This can work on multidimentional arrays or cell arrays.
// 
// SYNTAX
//	identifier (index_express [, indexexpression] ...)
xpr_array_index
:	(xpr_cell_index | id_var) LEFT_PARENTHESIS (atom_index_all | xpr_tree_) (COMMA (atom_index_all | xpr_tree_))* RIGHT_PARENTHESIS
;

xpr_cell_index
:	id_var LEFT_BRACE (atom_index_all | xpr_tree_) (COMMA (atom_index_all | xpr_tree_))* RIGHT_BRACE
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
:	id_function LEFT_PARENTHESIS ((xpr_tree | xpr_handle) (COMMA (xpr_tree | xpr_handle))*)? RIGHT_PARENTHESIS
;

xpr_handle
:	AT id_function
|	AT function_params statement
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

atom_meta
:	QUESTION id_class
|	LEFT_BRACE (QUESTION id_class (COMMA? QUESTION id_class)*)? RIGHT_BRACE
;

atom_string
:	STRING
;

atom_var
:	ID
;

//// LEXER RULES

// Match all newline characters
NL : ('\r' '\n' | '\r' | '\n') -> channel(HIDDEN);

// Match comments and send them to the HIDDEN channel
BLOCKCOMMENT	: '%{' .*?  '%}' -> channel(HIDDEN);
COMMENT			: '%' .*? NL  -> channel(HIDDEN);

// Match whitespace characters and skip
WS : [ \t] { maybeString = true; } -> skip;

// Match the multiline break and skip it
ELLIPSIS: '...' NL -> skip;

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
ASSIGN			: '=' { maybeString = true; };
BINARY_AND		: '&';
BINARY_OR		: '|';
COLON			: ':';
GREATER_THAN	: '>' { maybeString = true; };
LEFT_DIVIDE		: '/';
LESS_THAN		: '<' { maybeString = true; };
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
QUESTION				: '?';
RIGHT_BRACE				: '}' {maybeString = false;};
RIGHT_PARENTHESIS		: ')' {maybeString = false;};
RIGHT_SQUARE_BRACKET	: ']' {maybeString = false;};

// Atoms - identifiers, strings, numbers, whitespace
ID: [a-zA-Z] [a-zA-Z0-9_]* { maybeString = false; };

IMAGINARY
:	INT 'i'
|	FLOAT 'i'
;

INT: DIGIT+;

FLOAT
:	DIGIT+ '.' DIGIT* EXPONENT?
|	DIGIT+			  EXPONENT
|		   '.' DIGIT+ EXPONENT?
;

fragment
EXPONENT: ('e'|'E') ('+'|'-')? DIGIT+;

fragment
DIGIT: [0-9];

STRING : {maybeString}? '\'' ( ~('\'' | '\r' | '\n') | '\'\'')* '\'';

