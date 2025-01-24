
%{
    #include "part3_helpers.hpp"
	using namespace std;
    extern int yylex();
    extern char* yytext;
    extern int yylineno;

    void yyerror(const char* c);
   	void semError(const char* c);
	void operError(string error); 
%}

/* Token Declarations */
%token tk_id
%token tk_int_num
%token tk_real_num
%token tk_ellipsis
%token tk_str
%token tk_void
%token tk_write
%token tk_read
%token tk_return
%token tk_while
%token tk_do
%token tk_int
%token tk_float
%token tk_va_arg
%left tk_or
%left tk_and
%left tk_relop
%left tk_addop
%left tk_mulop
%right tk_assign
%right tk_if 
%right tk_then
%right tk_else
%right tk_not
%left '('
%left ')'
%left '{'
%left '}'
%left ':'
%left ';'


%%

PROGRAM : FDEFS
    {
        for (map<string, Function>::iterator it = functionTable.begin(); it != functionTable.end(); it++){
			int impAddress = it->second.address;
			buffer->backpatch(it->second.callingLines, impAddress);
		}
	}
;

FDEFS : FDEFS FUNC_DEF_API BLK
    {
        if (functionTable[$2.str].implemented){
			SemError("already implemented function '" + $2.str + "'\n");
		}
		else { // if the function is not implemented
			functionTable[$2.str].implemented = true;
		}
		buffer->emit("RETRN");

		// initiallize all parameters
		symbolTable.clear();
		$3.paramTypes.clear();
		currentScopeRegsNumInt = 3;
		currentScopeRegsNumFloat = 3;
		currentScopeOffset = 0;
    }
    | FDEFS FUNC_DEC_API
    {
       if (!functionTable[$2.str].implemented){
			functionTable[$2.str].address = -1;
		}

		// initiallize all parameters
		symbolTable.clear();
		currentScopeRegsNumInt = 3;
		currentScopeRegsNumFloat = 3;
		currentScopeOffset = 0;
    }
    | /* EPSILON */ {}
;

FUNC_DEC_API : TYPE tk_id '(' ')' ';'
    {
        $$ = makeNode("FUNC_DEC_API", NULL, $1);
        concatList($1, $2);
        concatList($1, $3);
        concatList($1, $4);
        concatList($1, $5);
    }
	| TYPE tk_id '(' FUNC_ARGLIST ')' ';'
	{
		$$ = makeNode("FUNC_DEC_API", NULL, $1);
        concatList($1, $2);
        concatList($1, $3);
        concatList($1, $4);
        concatList($1, $5);
		concatList($1, $6);
	}
	| TYPE tk_id '(' FUNC_ARGLIST ',' tk_ellipsis ')' ';'
	{
		$$ = makeNode("FUNC_DEC_API", NULL, $1);
        concatList($1, $2);
        concatList($1, $3);
        concatList($1, $4);
        concatList($1, $5);
		concatList($1, $6);
		concatList($1, $7);
		concatList($1, $8);
	}
;

FUNC_DEF_API : TYPE tk_id '(' ')'
	{
		$$ = makeNode("FUNC_DEF_API", NULL, $1);
        concatList($1, $2);
        concatList($1, $3);
        concatList($1, $4);
	}
	| TYPE tk_id '(' FUNC_ARGLIST ')'
    {
        $$ = makeNode("FUNC_DEF_API", NULL, $1);
        concatList($1, $2);
        concatList($1, $3);
        concatList($1, $4);
        concatList($1, $5);
    }
	| TYPE tk_id '(' FUNC_ARGLIST ',' tk_ellipsis ')'
	{
		$$ = makeNode("FUNC_DEF_API", NULL, $1);
        concatList($1, $2);
        concatList($1, $3);
        concatList($1, $4);
        concatList($1, $5);
		concatList($1, $6);
		concatList($1, $7);
	}
;

FUNC_ARGLIST : FUNC_ARGLIST ',' DCL
    {
        for (int i = tmpParamInOrder.size()-1; i >= 0 ; i--){
			currParamInOrder.push_back(tmpParamInOrder[i]);
		}
		tmpParamInOrder.clear();
		vector<Type> tempParamTypes = $3.paramTypes;
		reverse(tempParamTypes.begin(), tempParamTypes.end());
		$$.paramTypes = merge($1.paramTypes, paramTypesTmp);
		$1.paramTypes.clear();
		$3.paramTypes.clear();

    }
    | DCL
    {
        for (int i = tmpParamInOrder.size()-1; i >= 0; i--){
			currParamInOrder.push_back(tmpParamInOrder[i]);
		}
		tmpParamInsertionOrder.clear();
		$$.paramTypes = $1.paramTypes;
		reverse($$.paramTypes.begin(), $$.paramTypes.end());

    }
;

BLK : '{' SCOPE_OPEN STLIST M SCOPE_CLOSE '}' {}    
;

//adding mid-action for scopes 
SCOPE_OPEN : //open a new scope
{
	currScopeDepth++;
}

SCOPE_CLOSE :
{
	for (map<string, Symbol>::iterator it = symbolTable.begin(); it != symbolTable.end(); it++)
	{
		if (it->second.depth == currentBlockDepth)
		{
			it->second.type.erase(currentBlockDepth);
			it->second.offset.erase(currentBlockDepth);
			it->second.depth--;
		}
	}
	currScopeDepth --;
}

DCL : tk_id ':' TYPE
    {
        $$ = makeNode("DCL", NULL, $1);
        concatList($1, $2);
        concatList($1, $3);
    }
	| tk_id ',' DCL
    {
        $$ = makeNode("DCL", NULL, $1);
        concatList($1, $2);
        concatList($1, $3);
    }
;

TYPE : tk_int
    {
        $$.type = int_ ; 
    }
    | tk_float
    {
        $$.type = float_ ;
    }
    | tk_void
    {
        $$.type = void_t;
    }
;

STLIST : STLIST STMT M
    {
        buffer->backpatch($2.nextList, $3.quad);
    }
    | /* EPSILON */ {}
;

STMT : DCL ';'
    {
        $$ = makeNode("STMT", NULL, $1);
        concatList($1, $2);
    }
	| ASSN {}
	| EXP ';' {}
	| CNTRL 
	{
		$$.nextList = $1.nextList;
	}
	| READ {}
	| WRITE {} 
    | RETURN {}
	| BLK {}
;

RETURN : tk_return EXP ';'
    {
        $$ = makeNode("RETURN", NULL, $1);
        concatList($1, $2);
        concatList($1, $3);
    }
	| tk_return ';'
    {
        $$ = makeNode("RETURN", NULL, $1);
        concatList($1, $2);
    }
;


WRITE : tk_write '(' EXP ')' ';'
	{
		$$ = makeNode("WRITE", NULL, $1);
 		concatList($1, $2);
		concatList($1, $3);
		concatList($1, $4);
		concatList($1, $5);
	}
	| tk_write '(' tk_str ')' ';'
	{
 		$$ = makeNode("WRITE", NULL, $1);
 		concatList($1, $2);
		concatList($1, $3);
		concatList($1, $4);
		concatList($1, $5);
	}
;


READ : tk_read '(' LVAL ')' ';'
	{
		if ($3.type == void_t){
			semError("Can not read type void");
		}
 		if($3.type == int_){
			int tempReg = currScopeIntRegsNum++;
			buffer->emit("READI I" + intToString(tempReg));
			buffer->emit("STORI I" + intToString(tempReg) + " I" + intToString($3.regNum) + " 0");
		}
		else if($3.type == float_){
			int tempReg = currScopeFloatRegsNum++;
			buffer->emit("READF F" + intToString(tempReg));
			buffer->emit("STORF F" + intToString(tempReg) + " F" + intToString($3.regNum) + " 0");
		}
	}
;


ASSN : LVAL tk_assign EXP ';'
	{
		Type lvalType = $1.type; //type of LVAL
		Type rvalType = $3.type; //type of EXP

		// check that the types are equal
		if (lvalType != rvalType) {
			semError("incompatible type of argument ");
		}
		else if (lvalType == void_t) {
			semError("void type cannot be used for this action");
		}
		
		// varaible type is int
		if(lvalType == int_ ){ 
			buffer->emit("STORI I" + intToString($3.regNum) + " I" + intToString($1.regNum) + " 0");
		}

		//variable type is float
		if(lvalType == float_ ){ 
			buffer->emit("STORF F" + intToString($3.regNum) + " F" + intToString($1.regNum) + " 0");
		}
		
	}
;


LVAL : tk_id
	{
		// validate variable decleration
		if (symbolTable.find($1.str) == symbolTable.end()) {
			semError("Variable '" + $1.str + "' is not declared" );
		}
		int depth = symbolTable[$1.str].depth;
		$$.type = symbolTable[$1.str].type[depth];
		
		if ($$.type == void_t) {
			semError("Cannot use variable '" + $1.str + "' of type void");
		}

		// Allocate a register for the memory offset calulation
		$$.offset = symbolTable[$1.str].offset[depth];
		if ($$.type == float_t) {
    		$$.regNum = currScopeFloatRegsNum++;
    		buffer->emit("ADD2F F" + intToString($$.regNum) + " F1 " + intToString($$.offset));
		} else {
    		$$.regNum = currScopeIntRegsNum++;
    		buffer->emit("ADD2I I" + intToString($$.regNum) + " I1 " + intToString($$.offset));
		}
	}
;


CNTRL : tk_if BEXP tk_then M STMT N tk_else M STMT
	{
 		buffer->backpatch($2.trueList, $4.quad);
		buffer->backpatch($2.falseList, $8.quad);
		$$.nextList = merge<int>($5.nextList, $6.nextList);
		$$.nextList = merge<int>($$.nextList, $9.nextList);
		$5.nextList.clear();
		$6.nextList.clear();
		$9.nextList.clear();
	}
	| tk_if BEXP tk_then M STMT
	{
 		buffer->backpatch($2.trueList, $4.quad);
		$$.nextList = merge<int>($2.falseList, $5.nextList);
		$2.falseList.clear();
		$5.nextList.clear();
	}
	| tk_while M BEXP tk_do M STMT
	{	
		buffer->backpatch($3.trueList, $5.quad);
		buffer->backpatch($6.nextList, $2.quad);
		$$.nextList = $3.falseList;
		// adds UJUMP command to buffer to return to the while expression check
		buffer->emit("UJUMP " + intToString($2.quad));
	}
;


BEXP : BEXP tk_or BEXP
	{
 		$$ = makeNode("BEXP", NULL, $1);
 		concatList($1, $2);
		concatList($1, $3);
	}
	| BEXP tk_and BEXP
	{
 		$$ = makeNode("BEXP", NULL, $1);
 		concatList($1, $2);
		concatList($1, $3);
	}
	| tk_not BEXP
	{
 		$$ = makeNode("BEXP", NULL, $1);
 		concatList($1, $2);
	}
	| EXP tk_relop EXP
	{
 		$$ = makeNode("BEXP", NULL, $1);
 		concatList($1, $2);
		concatList($1, $3);
	}
	| '(' BEXP ')'
	{
 		$$ = makeNode("BEXP", NULL, $1);
 		concatList($1, $2);
		concatList($1, $3);
	}
;


EXP : EXP tk_addop EXP
	{
 		$$ = makeNode("EXP", NULL, $1);
 		concatList($1, $2);
		concatList($1, $3);
	}
	| EXP tk_mulop EXP
	{
 		$$ = makeNode("EXP", NULL, $1);
 		concatList($1, $2);
		concatList($1, $3);
	}
	| '(' EXP ')'
	{
		$$ = makeNode("EXP", NULL, $1);
 		concatList($1, $2);
		concatList($1, $3);
	}
	| '(' TYPE ')' EXP
	{
 		$$ = makeNode("EXP", NULL, $1);
 		concatList($1, $2);
		concatList($1, $3);
		concatList($1, $4);
	}
	| tk_id
	{
 		$$ = makeNode("EXP", NULL, $1);
	}
	| NUM
	{
		$$ = makeNode("EXP", NULL, $1);
	}
	| CALL
	{
 		$$ = makeNode("EXP", NULL, $1);
	}
	| VA_MATERIALISE
	{
		$$ = makeNode("EXP", NULL, $1);	
	}
;


NUM : tk_int_num
	{
		$$.type = int_;
		$$.value = $1.str;
	}
	| tk_real_num
	{
		$$.type = float_;
		$$.value = $1.str;	
	}
;


CALL : tk_id '(' CALL_ARGS ')'
	{
 		$$ = makeNode("CALL", NULL, $1);
 		concatList($1, $2);
		concatList($1, $3);
		concatList($1, $4);
	}
;

VA_MATERIALISE : tk_va_arg '(' TYPE ',' EXP ')'
				{
					$$ = makeNode("VA_MATERIALISE", NULL, $1);
 					concatList($1, $2);
					concatList($1, $3);
					concatList($1, $4);
					concatList($1, $5);
					concatList($1, $6);
				}
;

CALL_ARGS : CALL_ARGLIST
	{
 		$$.paramTypes = $1.paramTypes;	
		$$.paramRegs = $1.paramRegs;
		$1.paramTypes.clear();
		$1.paramRegs.clear();
	}
	| /* EPSILON */ {}
;


CALL_ARGLIST : CALL_ARGLIST ',' EXP
	{
 		$$.paramRegs = $1.paramRegs;
		$$.paramTypes = $1.paramTypes;
		$$.paramRegs.push_back($3.regNum);
		$$.paramTypes.push_back($3.type);
		$1.paramTypes.clear();
		$1.paramRegs.clear();
	}
	|  EXP
	{
		$$.paramRegs.push_back($1.regNum);
		$$.paramTypes.push_back($1.type);
	}
;

M : /* EPSILON */ 
	{
		$$.quad = buffer->nextquad();
	}
;
 

N : /* EPSILON */ 
	{
		$$.nextList.push_back(buffer->nextquad());
		buffer->emit("UJUMP ");
	}
;

%%


void yyerror(const char* c)
{
    printf("Syntax error: '%s' in line number %d\n", yytext, yylineno);
    exit(SYNTAX_ERROR);
}

void semError(string error){
	printf("Semantic error: '%s' in line number %d\n", error, yylineno);
    exit(SEMANTIC_ERROR);
}
void operError(string error){
	printf("Operational error: '%s\n', error);
    exit(OPERATIONAL_ERROR);
} 

