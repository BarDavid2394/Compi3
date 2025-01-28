
/*
    EE046266: Compilation Methods - Winter 2024-2025
*/

#ifndef _PART3_HELPERS_H_
#define _PART3_HELPERS_H_

#define YYSTYPE yystype
#define LEXICAL_ERROR 1
#define SYNTAX_ERROR 2
#define SEMANTIC_ERROR 3
#define OPERATIONAL_ERROR 4
#define RUNTIME_ERROR 5

#include <string>
#include <sstream>
#include <stdlib.h>
#include <stdio.h>
#include <iostream>
#include <algorithm>
#include <map>
#include <fstream>
#include <vector>

using namespace std;

//void yyerror(const char* c);
void semError(string error);
void operError(string error);


//Defining our primitive types
typedef enum {
	void_t = 0,
	int_ = 1,
	float_ = 2
	} Type;

// Merging list for backpatching use
// Example usage: $$.nextList = merge<int>($1.nextList, $2.nextList);
template <typename T>
static vector<T> merge(vector<T>& list1, vector<T>& list2) {
	vector<T> output = list1;
	output.insert(output.end(), list2.begin(), list2.end());
	return output;
}

// Token's fields struct
typedef struct {
    // Token related attributes
	string name;    // Token's name
	Type type;      // Token's type
	int offset;     // Token's offset in memory
	int quad;       // Linenum that the token's exp will be printed in rsk
	int RegNum;     // I register num the token is assigned to
	string value; // Value of the token (in case it represents a constant)
    // Function related attributes
	vector<Type> paramTypes;  // Function's parameters type
	vector<int>  paramRegs;   // Function's parameters registers number
    vector<string>  paramIds; // List of parameters' id in function's definition
	
	// Exp attributes
	vector<int> nextList;
	vector<int> trueList;
	vector<int> falseList;
	
} yystype;




// Definition of Function class - used in the table that holds the function.
class Function {
	public:
		// Flag to check whether function is defined yet
		bool isDefined;

		// Flag to check whether function is variadic
		bool isVariadic;
		
		// The starting address in the buffer of the function implementation
		int startLineImplementation;

		// The starting index of variadic parameters
		int startIndexVariadicParams;
		
		// The index of the number of variadic parameters parameter
		int indexNumVAParams;
		
		//number of variadic variables
		int numVariadicParams;
		
		// The types of parameters of the function
		vector<Type> paramTypes;

		// List of all the addresses in .rsk file where the function is being called
		vector<int> callingLines;
		
		// List of parameters' id in function's defenition
		vector<string>  paramIds;
	
		// Function's return type
		Type returnType;

};

//Symbols struct, to be used in the symbol table
class Symbol {
	public:
		// Symbol's depth, symbol's type
		map<int,Type> type;
		
		// Symbol's depth, symbol's offset
		map<int,int> offset;
		
		// Depth of most inner symbol
		int depth; 

};

// Turning double number to a string value
static string intToString(double num) {
    stringstream numString;
    numString << num;
    return numString.str();
}

class Buffer {
		vector<string> data;
	public:
		Buffer();

		//Insert a new command to the buffer
		void emit(const string& command);


		//Print buffer's data
		string printBuffer();


		//Insert a new command to the begining of the buffer
		void frontEmit(const string& command);


		//Fill holes in linenum
		void backpatch(vector<int> list, int linenum);


		//Next empty line in the buffer
		int nextQuad();

};

/*******************************************GLOBALS*******************************************/
static Buffer* buffer;                          // CodeGen buffer
static map<string, Symbol> symbolTable;			// Table that contains all symbols defined in prog
static map<string, Function> functionTable;		// Table that contains all functions - each function with it's members
static Buffer mainBuffer; // main function buffer

static int currScopeIntRegNum = 3; //first 3 is reserved for return address, beggining of the stuck and top of the stuck

static int currScopeFloatRegNum = 3; //first 3 is reserved for return address, beggining of the stuck and top of the stuck

static int currScopeDepth = 0; //holds the depth of the current scope

static int currScopeRetType; // holds the return type of this scoped

static int currScopeOffset; // holds the return type of this scoped

static int preScopeOffset; // holds the return type of this scoped

static int currentReturnType; 

static string currentFunctionName = ""; //holds the current funciton name

static int currFuncVarArgCnt = 0; //holds the number of variadic arguments in this curr function

static vector<string> currParamInOrder; // curr order of parameters for the current function
static vector<string> tmpParamInOrder; // temp order of parameters for the current function

/**********************************************************************************************/

#endif
