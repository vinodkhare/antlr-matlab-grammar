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

functionMFile  : f_def_line f_body RETURNS? ENDS?
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


scriptMFile:   (   statement (';'|NL)
        |   NL
        )*
        EOF
    ;


statement   : ID 
          | assignment
          | expr
          | command_form
          | for_command
          | if_command
          | global_command
          | while_command
          | return_command
            ;	

assignment  : reference '=' expr
            ;

reference   : ID
            | ID '(' argument_list ')'
            ;

argument_list	: ':'
		| expr
		| ':' ',' argument_list
		| expr ',' argument_list
		;


command_form : ID command_args
             ;
command_args : ID+ // FIXME!!
             ;

for_command : FOR ID '=' expr END
            ;

if_command : IF expr END
           ;

global_command	: GLOBAL ID+
		;

while_command : WHILE expr END
              ;

return_command : RETURNS
               ;

expr: '(' expr ')'
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
	| fieldAccess
	| reference
    | (INT | FLOAT | STRING);

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
END	   : 'end';
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

ENDS	  : END SEMI? ;

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

EQ	: '=';

BIN_OR	: '|';
BIN_AND	: '&';

LST	: '<';
GRT	: '>';

COLON	: ':';

PLUS	: '+';
MINUS	: '-';
NEG	: '~';
TIMES	: '*';

LEFTDIV	: '/';
RIGHTDIV: '\\';

EXP	: '^';

CCT	: '\'';

// Other useful language snippets
SEMI	: ';';
LPAREN	: '(';
RPAREN	: ')';
LBRACE	: '{';
RBRACE	: '}';
LSBRACE	: '[';
RSBRACE	: ']';
AT	: '@';
DOT	: '.';
COMMA	: ',';

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

STRING : '\'' ( ~('\'') )* '\'';

WS : [ \t] -> skip;