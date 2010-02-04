grammar ceylon;

options {
    //backtrack=true;
    memoize=true;
}

compilationUnit
    : (importDeclaration)*
      (annotation* toplevelDeclaration)+
      EOF
    ;
    
toplevelDeclaration
    : classDeclaration 
    | interfaceDeclaration 
    | converterDeclaration 
    | decoratorDeclaration
    | aliasDeclaration
    ;

importDeclaration  
    : 'import' importElement ('.' importElement)* ('.' '*' | 'alias' typeName)? ';'
    ;
    
importElement
    : LIDENTIFIER | UIDENTIFIER
    ;

block
    : '{' localOrStatement* directiveStatement? '}'
    ;

//we could eliminate the backtracking by requiring
//local declarations to begin with a keyword
localOrStatement
    : //'local' annotation* localDeclaration
      (declarationStart) => annotation* localDeclaration
    | statement
    ;

localDeclaration
    : type memberName initializer? ';'
    ;

inlineClassDeclaration
    : 'new' annotation*
      regularType
      arguments
      satisfiedTypes?
      '{' memberOrStatement* '}'
    ;
    
//we could eliminate the backtracking by requiring
//all member declarations to begin with a keyword
memberOrStatement
    : //modifier  annotation* ( memberDeclaration | toplevelDeclaration )
      (declarationStart) => annotation* ( memberDeclaration | toplevelDeclaration )
    | statement
    ;

//a normal functor expression
functor 
    : ('functor' (annotation* (type|'void'))?)? formalParameters functorBody
    ;

//shortcut functor expression that makes the parameter list 
//optional
specialFunctor
    : ( (typeName | formalParameterStart) => (type|'void')? formalParameters )? functorBody
    ;

//special rule for syntactic predicates
declarationStart
    :  declarationModifier 
    | ( userAnnotation annotation* )? (type|'assign'|'void') LIDENTIFIER
    ;

//by making these things keywords, we reduce the amount of
//backtracking
declarationModifier 
    : 'public'
    | 'package'
    | 'module'
    | 'override'
    | 'optional'
    | 'mutable'
    | 'abstract'
    | 'final'
    | 'static'
    | 'once'
    | 'deprecated'
    | 'volatile'
    ;

//special rule for syntactic predicates
formalParameterStart
    : '(' (declarationStart | ')')
    ;

//we can support enumerations as functor bodies, but
//I think that's just confusing to the reader
functorBody
    : ('{') => block
    | functorBodyExpression
    ;

//Let's limit statements to things that make sense, like
//Java does (we could allow any arbitrary expression if
//we wanted to, but why?)
//Even though it looks like this is non-associative
//assignment, it is actually right associative because
//assignable can be an assignment
statement 
    : //assignable ';'
      postfixExpression 
      (assignmentOp assignable | specialFunctorArguments)? ';'
    | controlStructure
    ;

directiveStatement
    : directive ';'?
    ;

directive
    : 'return' assignable? 
    | 'produce' assignable
    | 'throw' assignable 
    | 'break' 
    | 'found'
    ;

// what I have here now allows method and attribute bodies 
// to omit the braces, just like functor bodies. The cost
// of doing that was the need to add a predicate, and we're
// still not sure if we really want this feature
memberDeclaration
    : voidMethod | methodOrGetter | setter
    ;
    
methodOrGetter
    : type memberName ( (typeParameterStart | formalParameterStart) => methodDefinition | attributeDefinition )
    ;

setter
    : 'assign' memberName block
    ;
    
voidMethod 
    : 'void' memberName methodDefinition
    ;

typeParameterStart
    : '<'
    ;

methodDefinition
    : typeParameters? formalParameters typeConstraints? ( block | ';' )
    ;

attributeDefinition
    : block | initializer ';'
    ;

decoratorDeclaration
    :
        'decorator'
        typeName
        typeParameters?
        formalParameters?
        satisfiedTypes?
        typeConstraints?
        '{' ( annotation* memberDeclaration )* '}'
    ;

converterDeclaration
    :
        'converter'
        type
        typeName
        typeParameters?
        typeConstraints?
        '(' annotation* type parameterName ')'
    ;

interfaceDeclaration
    :
        'interface'
        typeName
        typeParameters?
        satisfiedTypes?
        typeConstraints?
        '{' memberStub* '}'
    ;

aliasDeclaration
    :
        'alias'
        typeName
        typeParameters?
        satisfiedTypes?
        typeConstraints?
        ';'
    ;

memberStub
    :
        annotation*
        (type | 'void')
        memberName
        (typeParameters?
         formalParameters
         typeConstraints?)?
        ';'
        ;

classDeclaration
    :
        'class'
        typeName
        typeParameters?
        formalParameters?
        extendedType?
        satisfiedTypes?
        typeConstraints?
        '{' instances? memberOrStatement* '}'
    ;

extendedType
    : 'extends' typeName typeParameters? arguments
    ;
    
instances
    : 'instances' instance (',' instance)* ';'
    ;

instance 
    : /*annotation**/ memberName arguments?
    ;

typeConstraint
    : typeName ((('>=' | '<=') type )| formalParameters)
    ;
    
typeConstraints
    : 'where' typeConstraint ('&' typeConstraint)*
    ;
    
satisfiedTypes
    : 'satisfies' type (',' type)*
    ;

type
    : regularType | functorType
    ;

regularType
    : typeName ( (typeParameterStart) => typeParameters )?
    ;

functorType
    : 'functor' annotation* (type|'void') formalParameters
    ;

annotation 
    : declarationModifier | userAnnotation
    ;

userAnnotation 
    : annotationName ( arguments | literal )?
    ;

typeName
    : //( identifier '.' )* 
    UIDENTIFIER ('.' UIDENTIFIER)*
    ;

annotationName
    : //( identifier '.' )* 
    LIDENTIFIER
    ;

memberName 
    : LIDENTIFIER
    ;

typeParameters
    : '<' type (',' type)* '>'
    ;

//for locals and attributes
initializer
    : ('=' | ':=') assignable
    ;

//for parameters
specifier
    : '=' assignable
    ;

literal
    : INTLITERAL
    | FLOATLITERAL
    | CHARLITERAL
    | DATELITERAL
    | TIMELITERAL
    | REGEXPLITERAL
    | stringLiteral
    ;   

stringLiteral
    : SIMPLESTRINGLITERAL
    | LEFTSTRINGLITERAL expression RIGHTSTRINGLITERAL 
    ;

assignable 
    : (functorStart) => functor
    | expression
    ;

functorStart
    : 'functor' | formalParameterStart
    ;

//This one is fully general
//Even though it looks like this is non-associative
//assignment, it is actually right associative because
//assignable can be an assignment
expression 
    : implicationExpression 
      (assignmentOp assignable | specialFunctorArguments)?
    ;

//This one is for use as a functor body
functorBodyExpression
    : implicationExpression 
      ( assignmentOp ( (functorStart) => functor | functorBodyExpression ) )?
    ;
    
assignmentOp
    : '=' //not really an assignment operator, but can be used to init locals
    | ':='
    | '+=' 
    | '-=' 
    | '*=' 
    | '/=' 
    | '%=' 
    | '&=' 
    | '|=' 
    | '^=' 
    | '&&=' 
    | '||=' 
    | '?='
    ;

implicationExpression
    : disjunctionExpression 
      ('=>' disjunctionExpression)?
    ;

//should '^' have a higher precedence?
disjunctionExpression
    :  conjunctionExpression 
       (('||' | '|' '^') conjunctionExpression)?
    ;

conjunctionExpression
    : logicalNegationExpression 
      (('&&' | '&') logicalNegationExpression)*
    ;

logicalNegationExpression
    : '!' logicalNegationExpression
    | equalityExpression
    ;

equalityExpression
    : comparisonExpression
      (('=='|'!='|'===') comparisonExpression)?
    ;

comparisonExpression
    : defaultExpression
      (('<=>'|'<'|'>'|'<='|'>='|'in'|'is') defaultExpression)?
    ;

//should we reverse the precedence order 
//of '?' and 'exists'/'nonempty'?
defaultExpression
    : existenceEmptinessExpression 
      ('?' defaultExpression)?
    ;

existenceEmptinessExpression
    : dateCompositionExpression ('exists' | 'nonempty')?
    ;

//I wonder if it would it be cleaner to give 
//'..' a higher precedence than '->'
rangeIntervalEntryExpression
    : dateCompositionExpression
      (('..'|'->') dateCompositionExpression)?
    ;

dateCompositionExpression
    :  additiveExpression 
       ('@' additiveExpression)?
    ;

additiveExpression
    : multiplicativeExpression
      (('+' | '-') multiplicativeExpression)*
    ;

multiplicativeExpression 
    : exponentiationExpression
      (('*' | '/' | '%') exponentiationExpression)*
    ;

exponentiationExpression
    : postfixExpression ('**' postfixExpression)?
    ;

postfixExpression
    : unaryExpression ('--' | '++')*
    ;

unaryExpression 
    : ('$'|'-'|'++'|'--') unaryExpression
    | primary
    ;

primary
    : base selector*
    ;
    
base 
    : regularType
    | memberName
    | literal
    | parExpression
    | enumeration
    | 'this' 
    | 'super' 
    | 'null'
    | 'none'
    | inlineClassDeclaration
    | '#' ( regularType | memberName )
    ;

enumeration
    : '{' ( assignable (',' assignable)* )? '}'
    ;

selector 
    : ('.' | '^.' | '?.' | '*.') memberName
    | '#' memberName
    | arguments
    | elementSelector
    ;

elementSelector
    : '[' elementsSpec ']'
    ;

elementsSpec
    : assignable ( '...' | (',' assignable)* | '..' assignable )
    |  '...' assignable	
    ;

arguments 
    : positionalArguments | namedArguments
    ;
    
specialFunctorArguments 
    : specialFunctorArgument+
    ;

specialFunctorArgument
    : parameterName specialFunctor
    ;
      
namedArgument
    : parameterName specifier
    ;
    
parameterName
    : LIDENTIFIER
    ;

varargArguments
    : assignable (',' assignable)*
    ;

namedArguments
    : '{' ((namedArgument ';') => namedArgument ';')* varargArguments? '}'
    ;

parExpression 
    : '(' assignable ')'
    ;
    
positionalArguments
    : '(' (assignable (',' assignable)*)? ')'
    ;

formalParameters
    : '(' (formalParameterSpec (',' formalParameterSpec)*)? ')'
    ;

// FIXME: This accepts more than the language spec: named arguments
// and varargs arguments can appear in any order.  We'll have to
// enforce the rule that the ... appears at the end of the parapmeter
// list in a later pass of the compiler.
formalParameterSpec
    : formalParameter (specifier | '...')?
    ;

formalParameter
    : annotation* type parameterName 
      ( '->' type parameterName | '..' parameterName )?
    ;

// Control structures.

// Backtracking here is needed for exactly the same reason as localOrStatement.
condition
    : ('exists' | 'nonempty')? ( (declarationStart) => variable specifier | expression )
    | 'is' type ( (memberName '=') => memberName specifier | expression )
    ;
	
controlStructure
    : ifElse | switchCaseElse | doWhile | forFail | tryCatchFinally
    ;
    
ifElse
    : 'if' '(' condition ')' block ('else' 'if' block)* ('else' block)?
    ;
    
switchCaseElse
    : 'switch' '(' expression ')' ( '{' cases '}' | cases ';' )
    ;
    
cases 
    : caseNull caseStmt+ caseElse?
    ;
    
caseNull
    : 'case' 'null' block
    ;
    
caseStmt 
    : 'case' '(' caseExprs ')' block
    ;
    
caseExprs
    : expression (',' expression)* | 'is' type
    ;
    
caseElse
    : 'else' block
    ;
    
forFail
    : 'for' '(' forIterator ')' block ('fail' block)?
    ;

forIterator
    : formalParameter 'in' expression
    ;
    
controllingVariable
    : annotation* type LIDENTIFIER ( ('->'|'..') type LIDENTIFIER )?
    ;
    
doWhile
    :   
    ('do' ('(' doIterator ')')? block? )?  
    'while' '(' condition ')' (block | ';')
    ;

doIterator
    : variable initializer
    ;

tryCatchFinally
    :
    'try' ('(' resource ')')?
    block
    ('catch' '(' variable ')' block)*
    ('finally' block)?
    ;
    
resource
    : (declarationStart) => variable specifier 
    | expression
    ;

variable
    : annotation* type memberName
    ;

// Lexer

INTLITERAL
    : ('0' .. '9')('0' .. '9')*
    | '\'' HexDigit HexDigit HexDigit HexDigit '\''
    | '\'' HexDigit HexDigit '\''
    ;

fragment
Digit 
    : '0'..'9'
    ;

fragment
Digit2
    : Digit Digit
    ;

// FIXME: Doesn't allow ISO date format.
DATELITERAL
    : '\'' Digit Digit? '/' Digit Digit '/' Digit Digit Digit Digit  '\''
    ;

TIMELITERAL
    : '\'' Digit Digit? ':' Digit Digit (':' Digit Digit ( ':' Digit Digit Digit)?)? '\''
    ;

fragment
HexDigit
    :   ('0'..'9'|'a'..'f'|'A'..'F')
    ;

FLOATLITERAL
    :   ('0' .. '9')+ '.' ('0' .. '9')+ Exponent?  
    |   '.' ( '0' .. '9' )+ Exponent?  
    |   ('0' .. '9')+ Exponent  
    ;

fragment 
Exponent    
    :   ( 'e' | 'E' ) ( '+' | '-' )? ( '0' .. '9' )+ 
    ;

CHARLITERAL
    :   '\'' 
        (    ~( '\'' | '\r' | '\n' | '\\')
        | EscapeSequence
        ) 
        '\''
    ; 

/*

SIMPLESTRINGLITERAL
    :   ('"' | '}$')
        (    ~( '\r' | '\n' | '"' | '\\' | '$' | '{' )   
        | EscapeSequence
        )*
        ('"' | '${')
    ;
*/

SIMPLESTRINGLITERAL
    :   ('"')
        StringPart
        ('"')
    ;

LEFTSTRINGLITERAL
    : '"'
        StringPart
        '${'
    ;

RIGHTSTRINGLITERAL
    : '}$'
        StringPart
        '"'
    ;

fragment
NonStringChars
    :    '$' | '{' | '\\' | '"'
    ;

fragment
StringPart
    :    ( ~ NonStringChars | EscapeSequence) *
    ;
    
fragment
EscapeSequence 
    :   '\\' (
            'b' 
        |   't' 
        |   'n' 
        |   'f' 
        |   'r' 
        |   '\"' 
        |   '\''
        |   '$'
        |   '{'
        |   '}' 
        )          
    ;     

REGEXPLITERAL
    : '`' (~( '`' | '\\') | RegexEscapeSequence)* '`'
    ;

fragment
RegexEscapeSequence
    :    ('\\' ~ '\n')
    ;

WS  
    :   (
            ' '
        |    '\r'
        |    '\t'
        |    '\u000C'
        |    '\n'
        ) 
        {
            skip();
        }          
    ;

LINE_COMMENT
    :   '//' ~('\n'|'\r')*  ('\r\n' | '\r' | '\n') 
        {
            skip();
        }
    |   '//' ~('\n'|'\r')*
        {
            skip();
        }
    ;   

MULTI_COMMENT
        :       '/*'
                {
                        $channel=HIDDEN;
                }
                (       ~('/'|'*')
                        |       ('/' ~'*') => '/'
                        |       ('*' ~'/') => '*'
                        |       MULTI_COMMENT
                )*
                '*/'
        ;


ASSIGN
    :   'assign'
    ;
    
BREAK
    :   'break'
    ;
    
CASE
    :   'case'
    ;

CATCH
    :   'catch'
    ;

CLASS
    :   'class'
    ;

DECORATOR
    :   'decorator'
    ;

DO
    :   'do'
    ;
    
ELSE
    :   'else'
    ;            

EXISTS
    :   'exists'
    ;

FINALLY
    :   'finally'
    ;

FOR
    :   'for'
    ;

FOUND
    :   'found'
    ;
    
IF
    :   'if'
    ;

SATISFIES
    :   'satisfies'
    ;

IMPORT
    :   'import'
    ;

INTERFACE
    :   'interface'
    ;
    
NONE
    :   'none'
    ;

NULL
    :   'null'
    ;

NONEMPTY
    :   'nonempty'
    ;

PRODUCE
    :   'produce'
    ;

RETURN
    :   'return'
    ;

SUPER
    :   'super'
    ;

SWITCH
    :   'switch'
    ;

THIS
    :   'this'
    ;

THROW
    :   'throw'
    ;

TRY
    :   'try'
    ;

VOID
    :   'void'
    ;

WHILE
    :   'while'
    ;

LPAREN
    :   '('
    ;

RPAREN
    :   ')'
    ;

LBRACE
    :   '{'
    ;

RBRACE
    :   '}'
    ;

LBRACKET
    :   '['
    ;

RBRACKET
    :   ']'
    ;

SEMI
    :   ';'
    ;

COMMA
    :   ','
    ;

DOT
    :   '.'
    ;

ELLIPSIS
    :   '...'
    ;

EQ
    :   '='
    ;

BANG
    :   '!'
    ;

TILDE
    :   '~'
    ;

QUES
    :   '?'
    ;

COLON
    :   ':'
    ;
    
COLONEQ
    :   ':='
    ;

EQEQ
    :   '=='
    ;

AMPAMP
    :   '&&'
    ;

BARBAR
    :   '||'
    ;

PLUSPLUS
    :   '++'
    ;

SUBSUB
    :   '--'
    ;

PLUS
    :   '+'
    ;

SUB
    :   '-'
    ;

STAR
    :   '*'
    ;

SLASH
    :   '/'
    ;

AMP
    :   '&'
    ;

BAR
    :   '|'
    ;

CARET
    :   '^'
    ;

PERCENT
    :   '%'
    ;

AT
    :   '@'
    ;

BANGEQ
    :   '!='
    ;

GT
    :   '>'
    ;

LT
    :   '<'
    ;        

ENTRY
    :   '->'
    ;

RANGE
    :   '..'
    ;
    
COMPARE
    :   '<=>'
    ;
    
IN
    :   'in'
    ;

IS
    :   'is'
    ;

HASH
    :   '#'
    ;

PLUSEQ
    :   '+='
    ;
    
CONVERTER
    :  'converter'
    ;
    
LIDENTIFIER 
    :   LIdentifierPart IdentifierPart*
    ;

UIDENTIFIER 
    :   UIdentifierPart IdentifierPart*
    ;

// FIXME: Unicode identifiers
fragment
LIdentifierPart
    :   '_'
    |   'a'..'z'
    ;       
                       
// FIXME: Unicode identifiers
fragment
UIdentifierPart
    :   'A'..'Z'
    ;       
                       
fragment 
IdentifierPart
    :   LIdentifierPart 
    |   UIdentifierPart
    |   '0'..'9'
    ;
