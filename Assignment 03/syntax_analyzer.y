%{

#include "symbol_table.h"

#define YYSTYPE symbol_info*

extern FILE *yyin;
int yyparse(void);
int yylex(void);
extern YYSTYPE yylval;

// create your symbol table here.
// You can store the pointer to your symbol table in a global variable
// or you can create an object

symbol_table *table;

int lines = 1;
int error_count = 0;

ofstream outlog;
ofstream outerror;
bool error_status= false;

// you may declare other necessary variables here to store necessary info
// such as current variable type, variable list, function name, return type, function parameter types, parameters names etc.
string current_type;
vector<pair<string,string>> current_params;
string current_func;
string current;
#include <set>
std::set<std::string> processed_functions;
static std::set<std::string> checked_params;


void yyerror(char *s)
{
	outlog<<"At line "<<lines<<" "<<s<<endl<<endl;

    // you may need to reinitialize variables if you find an error
	current_params.clear();
	current_type= "";
}

%}

%token IF ELSE FOR WHILE DO BREAK INT CHAR FLOAT DOUBLE VOID RETURN SWITCH CASE DEFAULT CONTINUE PRINTLN ADDOP MULOP INCOP DECOP RELOP ASSIGNOP LOGICOP NOT LPAREN RPAREN LCURL RCURL LTHIRD RTHIRD COMMA SEMICOLON CONST_INT CONST_FLOAT ID

%nonassoc LOWER_THAN_ELSE
%nonassoc ELSE

%%

start : program
	{
		outlog<<"At line no: "<<lines<<" start : program "<<endl<<endl;
		outlog<<"Symbol Table"<<endl<<endl;
		// Print your whole symbol table here
		table->print_all_scopes(outlog);
		$$=$1;
	}
	;

program : program unit
	{
		outlog<<"At line no: "<<lines<<" program : program unit "<<endl<<endl;
		outlog<<$1->getname()+"\n"+$2->getname()<<endl<<endl;
		
		$$ = new symbol_info($1->getname()+"\n"+$2->getname(),"program");
	}
	| unit
	{
		outlog<<"At line no: "<<lines<<" program : unit "<<endl<<endl;
		outlog<<$1->getname()<<endl<<endl;
		
		$$ = new symbol_info($1->getname(),"program");
	}
	;

unit : var_declaration
	 {
		outlog<<"At line no: "<<lines<<" unit : var_declaration "<<endl<<endl;
		outlog<<$1->getname()<<endl<<endl;
		
		$$ = new symbol_info($1->getname(),"unit");
	 }
     | func_definition
     {
		outlog<<"At line no: "<<lines<<" unit : func_definition "<<endl<<endl;
		outlog<<$1->getname()<<endl<<endl;
		
		$$ = new symbol_info($1->getname(),"unit");
	 }
     ;

func_definition : type_specifier ID LPAREN parameter_list RPAREN
		{	current_func = $2->getname();
			if (table->lookup(new symbol_info($2->getname(), "FUNCTION"))) {
				outerror<< " " <<endl;
				outerror << "At line " << lines << " Multiple declaration of function " << $2->getname() << endl;
				error_count++;
			} else {
				symbol_info* func= new symbol_info($2->getname(), "FUNCTION");
				func->set_as_function($1->getname(),current_params);	
				table->insert(func);
			}		

		}
		compound_statement
		{   
			outlog<<"At line no: "<<lines<<" func_definition : type_specifier ID LPAREN parameter_list RPAREN compound_statement "<<endl<<endl;
			outlog<<$1->getname()<<" "<<$2->getname()<<"("+$4->getname()+")\n"<<$6->getname()<<endl<<endl;
			
			$$ = new symbol_info($1->getname()+" "+$2->getname()+"("+$4->getname()+")\n"+$6->getname(),"func_def");
			symbol_info* func = new symbol_info($2->getname(), "FUNCTION");
			func->set_datatype($1->getname());
			func->set_as_function($1->getname(), current_params);

			current_params.clear();	
			// The function definition is complete.
            // You can now insert necessary information about the function into the symbol table
            // However, note that the scope of the function and the scope of the compound statement are different.
		}
		| type_specifier ID LPAREN RPAREN compound_statement
		{  
			symbol_info* func= new symbol_info($2->getname(), "FUNCTION");
			func->set_as_function($1->getname(),vector<pair<string,string>>());
			table->insert(func);

			outlog<<"At line no: "<<lines<<" func_definition : type_specifier ID LPAREN RPAREN compound_statement "<<endl<<endl;
			outlog<<$1->getname()<<" "<<$2->getname()<<"()\n"<<$5->getname()<<endl<<endl;
			
			$$ = new symbol_info($1->getname()+" "+$2->getname()+"()\n"+$5->getname(),"func_def");	
			// The function definition is complete.
            // You can now insert necessary information about the function into the symbol table
            // However, note that the scope of the function and the scope of the compound statement are different.
		}
 		;

parameter_list : parameter_list COMMA type_specifier ID
		{
			for (auto param: current_params){
				if (param.second == $4->getname()){
					outerror<< " " <<endl;
					outerror << "At line no: " << lines << " Multiple declaration of variable " << $4->getname() << " in parameter of " << current_func << endl;
					error_count++;
					error_status=true;
			}
		}
			current_params.push_back({$3->getname(), $4->getname()});
			outlog<<"At line no: "<<lines<<" parameter_list : parameter_list COMMA type_specifier ID "<<endl<<endl;
			outlog<<$1->getname()<<","<<$3->getname()<<" "<<$4->getname()<<endl<<endl;
					
			$$ = new symbol_info($1->getname()+","+$3->getname()+" "+$4->getname(),"param_list");
			
            // store the necessary information about the function parameters
            // They will be needed when you want to enter the function into the symbol table
		}
		| parameter_list COMMA type_specifier
		{
			outlog<<"At line no: "<<lines<<" parameter_list : parameter_list COMMA type_specifier "<<endl<<endl;
			outlog<<$1->getname()<<","<<$3->getname()<<endl<<endl;
			
			$$ = new symbol_info($1->getname()+","+$3->getname(),"param_list");
			
            // store the necessary information about the function parameters
            // They will be needed when you want to enter the function into the symbol table
		}
 		| type_specifier ID
 		{	
			current_params.push_back({$1->getname(), $2->getname()});
			outlog<<"At line no: "<<lines<<" parameter_list : type_specifier ID "<<endl<<endl;
			outlog<<$1->getname()<<" "<<$2->getname()<<endl<<endl;
			
			$$ = new symbol_info($1->getname()+" "+$2->getname(),"param_list");
			
            // store the necessary information about the function parameters
            // They will be needed when you want to enter the function into the symbol table
		}
		| type_specifier
		{
			outlog<<"At line no: "<<lines<<" parameter_list : type_specifier "<<endl<<endl;
			outlog<<$1->getname()<<endl<<endl;
			
			$$ = new symbol_info($1->getname(),"param_list");
			
            // store the necessary information about the function parameters
            // They will be needed when you want to enter the function into the symbol table
		}
 		;

compound_statement : LCURL 
			{ 	table->enter_scope();
				outlog<<"New ScopeTable with ID "<<table->get_current_id()<<" created"<<endl<<endl;
                // Insert parameters into current scope
                for(auto param : current_params) {
                    symbol_info* param_symbol = new symbol_info(param.second, "ID");
                    param_symbol->set_datatype(param.first);
					if (not error_status) {if (!table->insert(param_symbol)){
						outerror<< " " <<endl;
						outerror << "At line " << lines << "Multiple declaration of variable " << param.second <<endl;
						error_count++;}
					}
                }
			}
			statements RCURL
			{
 		    	outlog<<"At line no: "<<lines<<" compound_statement : LCURL statements RCURL "<<endl<<endl;
				outlog<<"{\n"+$3->getname()+"\n}"<<endl<<endl;
				table->print_all_scopes(outlog);
				outlog<<"ScopeTable with ID "<<table->get_current_id()<<" removed"<<endl<<endl;
                table->exit_scope();				
				$$ = new symbol_info("{\n"+$3->getname()+"\n}","comp_stmnt");
				
                // The compound statement is complete.
                // Print the symbol table here and exit the scope
                // Note that function parameters should be in the current scope
 		    }
 		    | LCURL RCURL
 		    { 
 		    	outlog<<"At line no: "<<lines<<" compound_statement : LCURL RCURL "<<endl<<endl;
				outlog<<"{\n}"<<endl<<endl;
				
				$$ = new symbol_info("{\n}","comp_stmnt");
				
				// The compound statement is complete.
                // Print the symbol table here and exit the scope
 		    }
 		    ;
 		    
var_declaration : type_specifier declaration_list SEMICOLON
		 {	
			if ($1->getname()=="void"){
				outerror<< " " <<endl;
				outerror << "At line " << lines << " variable type cannot be void" << endl;
				error_count++;
			}
			
			outlog<<"At line no: "<<lines<<" var_declaration : type_specifier declaration_list SEMICOLON "<<endl<<endl;
			outlog<<$1->getname()<<" "<<$2->getname()<<";"<<endl<<endl;
			
			$$ = new symbol_info($1->getname()+" "+$2->getname()+";","var_dec");

			// Insert necessary information about the variables in the symbol table
		 }
 		 ;

type_specifier : INT
		{
			outlog<<"At line no: "<<lines<<" type_specifier : INT "<<endl<<endl;
			outlog<<"int"<<endl<<endl;
			current_type = "int";
			$$ = new symbol_info("int","type");
	    }
 		| FLOAT
 		{
			outlog<<"At line no: "<<lines<<" type_specifier : FLOAT "<<endl<<endl;
			outlog<<"float"<<endl<<endl;
			current_type = "float";
			$$ = new symbol_info("float","type");
	    }
 		| VOID
 		{
			outlog<<"At line no: "<<lines<<" type_specifier : VOID "<<endl<<endl;
			outlog<<"void"<<endl<<endl;
			current_type = "void";
			$$ = new symbol_info("void","type");
	    }
 		;

declaration_list : declaration_list COMMA ID
{
    symbol_info* var = new symbol_info($3->getname(), "ID");

    // Check for multiple declarations in the current scope
    if (table->lookup_in_current_scope(var)) { // Check only in the current scope
        outerror<< " " <<endl;
		outerror << "At line " << lines << " Multiple declaration of variable " << $3->getname() << endl;
        error_count++;
    } else {
		if (current_type=="void"){
			var->set_datatype("error");
		}else {
        	var->set_datatype(current_type);
		}
		table->insert(var); // Insert into the current scope
    }

    outlog << "At line no: " << lines << " declaration_list : declaration_list COMMA ID " << endl << endl;
    outlog << $1->getname() << "," << $3->getname() << endl << endl;

    $$ = new symbol_info($1->getname() + "," + $3->getname(), "dec_list");
}
| declaration_list COMMA ID LTHIRD CONST_INT RTHIRD
{
    symbol_info* arr = new symbol_info($3->getname(), "ID");
    arr->set_array(stoi($5->getname()));

    // Check for multiple declarations in the current scope
    if (table->lookup_in_current_scope(arr)) { // Check only in the current scope
        outerror<< " " <<endl;
		outerror << "At line " << lines << " Multiple declaration of variable " << $3->getname() << endl;
        error_count++;
    } else {
        arr->set_datatype(current_type);
        table->insert(arr); // Insert into the current scope
    }

    outlog << "At line no: " << lines << " declaration_list : declaration_list COMMA ID LTHIRD CONST_INT RTHIRD " << endl << endl;
    outlog << $1->getname() << "," << $3->getname() << "[" << $5->getname() << "]" << endl << endl;

    $$ = new symbol_info($1->getname() + "," + $3->getname() + "[" + $5->getname() + "]", "dec_list");
}
| ID
{
    symbol_info* var = new symbol_info($1->getname(), "ID");

    // Check for multiple declarations in the current scope
    if (table->lookup_in_current_scope(var)) { // Check only in the current scope
        outerror<< " " <<endl;
		outerror << "At line " << lines << " Multiple declaration of variable " << $1->getname() << endl;
        error_count++;
    } else {
		if (current_type=="void"){
			var->set_datatype("error");
		}else {
        var->set_datatype(current_type);
		}
		table->insert(var); // Insert into the current scope
    }

    outlog << "At line no: " << lines << " declaration_list : ID " << endl << endl;
    outlog << $1->getname() << endl << endl;

    $$ = new symbol_info($1->getname(), "dec_list");
}
| ID LTHIRD CONST_INT RTHIRD
{
    symbol_info* arr = new symbol_info($1->getname(), "ID");
    arr->set_array(stoi($3->getname()));

    // Check for multiple declarations in the current scope
    if (table->lookup_in_current_scope(arr)) { // Check only in the current scope
        outerror<< " " <<endl;
		outerror << "At line " << lines << " Multiple declaration of variable " << $1->getname() << endl;
        error_count++;
    } else {
        arr->set_datatype(current_type);
        table->insert(arr); // Insert into the current scope
    }

    outlog << "At line no: " << lines << " declaration_list : ID LTHIRD CONST_INT RTHIRD " << endl << endl;
    outlog << $1->getname() << "[" << $3->getname() << "]" << endl << endl;

    $$ = new symbol_info($1->getname() + "[" + $3->getname() + "]", "dec_list");
}
;

statements : statement
	   {
	    	outlog<<"At line no: "<<lines<<" statements : statement "<<endl<<endl;
			outlog<<$1->getname()<<endl<<endl;
			
			$$ = new symbol_info($1->getname(),"stmnts");
	   }
	   | statements statement
	   {
	    	outlog<<"At line no: "<<lines<<" statements : statements statement "<<endl<<endl;
			outlog<<$1->getname()<<"\n"<<$2->getname()<<endl<<endl;
			
			$$ = new symbol_info($1->getname()+"\n"+$2->getname(),"stmnts");
	   }
	   ;
	   
statement : var_declaration
	  {
	    	outlog<<"At line no: "<<lines<<" statement : var_declaration "<<endl<<endl;
			outlog<<$1->getname()<<endl<<endl;
			
			$$ = new symbol_info($1->getname(),"stmnt");
	  }
	  | func_definition
	  {
	  		outlog<<"At line no: "<<lines<<" statement : func_definition "<<endl<<endl;
            outlog<<$1->getname()<<endl<<endl;

            $$ = new symbol_info($1->getname(),"stmnt");
	  		
	  }
	  | expression_statement
	  {
	    	outlog<<"At line no: "<<lines<<" statement : expression_statement "<<endl<<endl;
			outlog<<$1->getname()<<endl<<endl;
			
			$$ = new symbol_info($1->getname(),"stmnt");
	  }
	  | compound_statement
	  {
	    	outlog<<"At line no: "<<lines<<" statement : compound_statement "<<endl<<endl;
			outlog<<$1->getname()<<endl<<endl;
			
			$$ = new symbol_info($1->getname(),"stmnt");
	  }
	  | FOR LPAREN expression_statement expression_statement expression RPAREN statement
	  {
	    	outlog<<"At line no: "<<lines<<" statement : FOR LPAREN expression_statement expression_statement expression RPAREN statement "<<endl<<endl;
			outlog<<"for("<<$3->getname()<<$4->getname()<<$5->getname()<<")\n"<<$7->getname()<<endl<<endl;
			
			$$ = new symbol_info("for("+$3->getname()+$4->getname()+$5->getname()+")\n"+$7->getname(),"stmnt");
	  }
	  | IF LPAREN expression RPAREN statement %prec LOWER_THAN_ELSE
	  {
	    	outlog<<"At line no: "<<lines<<" statement : IF LPAREN expression RPAREN statement "<<endl<<endl;
			outlog<<"if("<<$3->getname()<<")\n"<<$5->getname()<<endl<<endl;
			
			$$ = new symbol_info("if("+$3->getname()+")\n"+$5->getname(),"stmnt");
	  }
	  | IF LPAREN expression RPAREN statement ELSE statement
	  {
	    	outlog<<"At line no: "<<lines<<" statement : IF LPAREN expression RPAREN statement ELSE statement "<<endl<<endl;
			outlog<<"if("<<$3->getname()<<")\n"<<$5->getname()<<"\nelse\n"<<$7->getname()<<endl<<endl;
			
			$$ = new symbol_info("if("+$3->getname()+")\n"+$5->getname()+"\nelse\n"+$7->getname(),"stmnt");
	  }
	  | WHILE LPAREN expression RPAREN statement
	  {
	    	outlog<<"At line no: "<<lines<<" statement : WHILE LPAREN expression RPAREN statement "<<endl<<endl;
			outlog<<"while("<<$3->getname()<<")\n"<<$5->getname()<<endl<<endl;
			
			$$ = new symbol_info("while("+$3->getname()+")\n"+$5->getname(),"stmnt");
	  }
	  | PRINTLN LPAREN ID RPAREN SEMICOLON
	  {
	    	outlog<<"At line no: "<<lines<<" statement : PRINTLN LPAREN ID RPAREN SEMICOLON "<<endl<<endl;
			outlog<<"printf("<<$3->getname()<<");"<<endl<<endl; 
			
			$$ = new symbol_info("printf("+$3->getname()+");","stmnt");
			symbol_info* var = table->lookup(new symbol_info($3->getname(), "ID"));
			if (!var) {
				outerror<< " " <<endl;
				outerror << "At line " << lines << " Undeclared variable " << $3->getname() << endl;
				error_count++;
				error_status=true;
				}
	  }
	  | RETURN expression SEMICOLON
	  {
	    	outlog<<"At line no: "<<lines<<" statement : RETURN expression SEMICOLON "<<endl<<endl;
			outlog<<"return "<<$2->getname()<<";"<<endl<<endl;
			
			$$ = new symbol_info("return "+$2->getname()+";","stmnt");
	  }
	  ;
	  
expression_statement : SEMICOLON
			{
				outlog<<"At line no: "<<lines<<" expression_statement : SEMICOLON "<<endl<<endl;
				outlog<<";"<<endl<<endl;
				
				$$ = new symbol_info(";","expr_stmt");
	        }			
			| expression SEMICOLON 
			{
				outlog<<"At line no: "<<lines<<" expression_statement : expression SEMICOLON "<<endl<<endl;
				outlog<<$1->getname()<<";"<<endl<<endl;
				
				$$ = new symbol_info($1->getname()+";","expr_stmt");
	        }
			;
	  
variable : ID 	
      {
	    outlog<<"At line no: "<<lines<<" variable : ID "<<endl<<endl;
		outlog<<$1->getname()<<endl<<endl;
		
		$$ = new symbol_info($1->getname(),"varbl");
		
		
	    symbol_info* var = table->lookup(new symbol_info($1->getname(), "ID"));
		if (!var) {
			outerror<< " " <<endl;
			outerror << "At line " << lines << " Undeclared variable " << $1->getname() << endl;
			error_count++;
			error_status= true;
	 	}
		else if (var->isArray()){
			outerror<< " " <<endl;
			outerror << "At line no: " << lines << " variable is of array type : " << $1->getname() << endl;
			error_count++;
			error_status = true;
		}
		else if (var->isFunction()){
			outerror<< " " <<endl;
			outerror << "At line no: " << lines << " variable is of function type : " << $1->getname() << endl;
			error_count++;
			error_status = true;
		}		
		if(var) {
        $$->set_datatype(var->get_datatype());
    	}
	  }	
	 | ID LTHIRD expression RTHIRD 
	 {
		symbol_info* arr = table->lookup(new symbol_info($1->getname(), "ID"));
		if (!arr || !arr->isArray()) {
			outerror<< " " <<endl;
			outerror << "At line " << lines << " variable is not of array type: " << $1->getname() << endl;
			error_count++;
			error_status=true;
		}
		if ($3->get_datatype() != "int") {
			outerror<< " " <<endl;
			outerror << "At line no " << lines << " array index is not of integer type : " << $1->getname() << endl;
			error_count++;
			error_status=true;
		}
	 	outlog<<"At line no: "<<lines<<" variable : ID LTHIRD expression RTHIRD "<<endl<<endl;
		outlog<<$1->getname()<<"["<<$3->getname()<<"]"<<endl<<endl;
		
		$$ = new symbol_info($1->getname()+"["+$3->getname()+"]","varbl");
		    if(arr) {
        // Set the datatype for array elements from the array's type
        $$->set_datatype(arr->get_datatype());
    }
	
	 }
	 ;
	 
expression : logic_expression
	   {
	    	outlog<<"At line no: "<<lines<<" expression : logic_expression "<<endl<<endl;
			outlog<<$1->getname()<<endl<<endl;
			
			$$ = new symbol_info($1->getname(),"expr");
			$$->set_datatype($1->get_datatype());
	   }
	   | variable ASSIGNOP logic_expression 	
	   {
	    	outlog<<"At line no: "<<lines<<" expression : variable ASSIGNOP logic_expression "<<endl<<endl;
			outlog<<$1->getname()<<"="<<$3->getname()<<endl<<endl;

			$$ = new symbol_info($1->getname()+"="+$3->getname(),"expr");
// In expression rule for assignments
			// outerror << "I am var 1: "<< $1->getname() << " " <<$1->get_datatype() << endl;
			// outerror << "I am var 2: "<< $3-> getname() <<" " <<$3->get_datatype() << endl;
			if (not error_status){
				if ($1->get_datatype() != $3->get_datatype()){
				outerror<< " " <<endl;
				outerror << "At line no " << lines << " Warning: Assignment of " << $3->get_datatype() << " value into variable of " << $1->get_datatype() << " type " << endl;
				error_count++;
				error_status=true;			
			}
			
		}
		error_status=false;
	   }
	   ;
			
logic_expression : rel_expression
	     {
	    	outlog<<"At line no: "<<lines<<" logic_expression : rel_expression "<<endl<<endl;
			outlog<<$1->getname()<<endl<<endl;
			
			$$ = new symbol_info($1->getname(),"lgc_expr");
			$$->set_datatype($1->get_datatype());
	     }	
		 | rel_expression LOGICOP rel_expression 
		 {
	    	outlog<<"At line no: "<<lines<<" logic_expression : rel_expression LOGICOP rel_expression "<<endl<<endl;
			outlog<<$1->getname()<<$2->getname()<<$3->getname()<<endl<<endl;
			
			$$ = new symbol_info($1->getname()+$2->getname()+$3->getname(),"lgc_expr");
			$$->set_datatype("int");
	     }	
		 ;
			
rel_expression	: simple_expression
		{
	    	outlog<<"At line no: "<<lines<<" rel_expression : simple_expression "<<endl<<endl;
			outlog<<$1->getname()<<endl<<endl;
			
			$$ = new symbol_info($1->getname(),"rel_expr");
			$$->set_datatype($1->get_datatype());
	    }
		| simple_expression RELOP simple_expression
		{
	    	outlog<<"At line no: "<<lines<<" rel_expression : simple_expression RELOP simple_expression "<<endl<<endl;
			outlog<<$1->getname()<<$2->getname()<<$3->getname()<<endl<<endl;
			
			$$ = new symbol_info($1->getname()+$2->getname()+$3->getname(),"rel_expr");
			$$->set_datatype("int");
	    }
		;
				
simple_expression : term
          {
	    	outlog<<"At line no: "<<lines<<" simple_expression : term "<<endl<<endl;
			outlog<<$1->getname()<<endl<<endl;
			
			$$ = new symbol_info($1->getname(),"simp_expr");
			$$->set_datatype($1->get_datatype());
			
	      }
		  | simple_expression ADDOP term 
		  {
	    	outlog<<"At line no: "<<lines<<" simple_expression : simple_expression ADDOP term "<<endl<<endl;
			outlog<<$1->getname()<<$2->getname()<<$3->getname()<<endl<<endl;
			
			$$ = new symbol_info($1->getname()+$2->getname()+$3->getname(),"simp_expr");
			$$->set_datatype($1->get_datatype());
	      }
		  ;
					
term :	unary_expression //term can be void because of un_expr->factor
     {
	    	outlog<<"At line no: "<<lines<<" term : unary_expression "<<endl<<endl;
			outlog<<$1->getname()<<endl<<endl;
			
			$$ = new symbol_info($1->getname(),"term");
			$$->set_datatype($1->get_datatype());
			
	 }
     |  term MULOP unary_expression
     {
				if ($2->getname()=="%") {
					if ($1->get_datatype() != "int" || $3->get_datatype() != "int") {
					outerror<< " " <<endl;
					outerror << "At line " << lines << " Modulus requires integer operands" << endl;
					error_count++;
				}
			}
				if ($3->getname() =="0") {
					outerror<< " " <<endl;
					outerror << "At line "<< lines << " Modulus by 0" << endl;
					error_count++;
				}		
	    	outlog<<"At line no: "<<lines<<" term : term MULOP unary_expression "<<endl<<endl;
			outlog<<$1->getname()<<$2->getname()<<$3->getname()<<endl<<endl;
			
			$$ = new symbol_info($1->getname()+$2->getname()+$3->getname(),"term");	
			$$->set_datatype($1->get_datatype());
	}	
	 
     ;

unary_expression : ADDOP unary_expression  // un_expr can be void because of factor
		 {
	    	outlog<<"At line no: "<<lines<<" unary_expression : ADDOP unary_expression "<<endl<<endl;
			outlog<<$1->getname()<<$2->getname()<<endl<<endl;
			
			$$ = new symbol_info($1->getname()+$2->getname(),"un_expr");
	     }
		 | NOT unary_expression 
		 {
	    	outlog<<"At line no: "<<lines<<" unary_expression : NOT unary_expression "<<endl<<endl;
			outlog<<"!"<<$2->getname()<<endl<<endl;
			
			$$ = new symbol_info("!"+$2->getname(),"un_expr");
	     }
		 | factor 
		 {
	    	outlog<<"At line no: "<<lines<<" unary_expression : factor "<<endl<<endl;
			outlog<<$1->getname()<<endl<<endl;
			
			$$ = new symbol_info($1->getname(),"un_expr");
			$$->set_datatype($1->get_datatype());
	     }
		 ;
	
factor	: variable
    {
	    outlog<<"At line no: "<<lines<<" factor : variable "<<endl<<endl;
		outlog<<$1->getname()<<endl<<endl;
			
		$$ = new symbol_info($1->getname(),"fctr");
		$$->set_datatype($1->get_datatype());
	}
	|  ID LPAREN argument_list RPAREN
{
    outlog << "At line no: " << lines << " factor : ID LPAREN argument_list RPAREN " << endl << endl;
    outlog << $1->getname() << "(" << $3->getname() << ")" << endl << endl;

    $$ = new symbol_info($1->getname() + "(" + $3->getname() + ")", "fctr");

    symbol_info* func = table->lookup(new symbol_info($1->getname(), "FUNCTION"));

    if (processed_functions.find($1->getname()) != processed_functions.end()) {
        processed_functions.erase($1->getname());
    } else {
        processed_functions.insert($1->getname());

        if (!func || !func->isFunction()) {
			outerror<< " " <<endl;
            outerror << "At line " << lines << " Undeclared function: " << $1->getname() << endl;
            error_count++;
            error_status = true;
        } else {
            $$->set_datatype(func->get_datatype());

            // Check for void type
            if (func->get_datatype() == "void") {
				outerror<< " " <<endl;
                outerror << "At line " << lines << " Operation on void type" << endl;
                error_count++;
                error_status = true;
            }

            // Check for parameter mismatches
            vector<pair<string, string>> params = func->get_parameters();
            vector<pair<string, string>> args = $3->get_parameters();

            if (args.size() != params.size()) {
				outerror<< " " <<endl;
                outerror << "At line " << lines << " Inconsistencies in number of arguments in function call " << func->getname() << endl;
                error_count++;
            } else {
                for (int i = 0; i < args.size(); i++) {
                    if (not error_status){if (args[i].first != params[i].first) {
                        outerror<< " " <<endl;
						outerror << "At line " << lines << " argument " << i + 1 << " type mismatch in function call: " << func->getname() << endl;
                        error_count++;}
                    }
                }
            }
        }
    }
}
	| LPAREN expression RPAREN
	{
	   	outlog<<"At line no: "<<lines<<" factor : LPAREN expression RPAREN "<<endl<<endl;
		outlog<<"("<<$2->getname()<<")"<<endl<<endl;
		
		$$ = new symbol_info("("+$2->getname()+")","fctr");
		$$->set_datatype($2->get_datatype());
	}
	| CONST_INT 
	{
	    outlog<<"At line no: "<<lines<<" factor : CONST_INT "<<endl<<endl;
		outlog<<$1->getname()<<endl<<endl;
			
		$$ = new symbol_info($1->getname(),"fctr");
		$$->set_datatype("int");
	}
	| CONST_FLOAT
	{
	    outlog<<"At line no: "<<lines<<" factor : CONST_FLOAT "<<endl<<endl;
		outlog<<$1->getname()<<endl<<endl;
			
		$$ = new symbol_info($1->getname(),"fctr");
		$$->set_datatype("float");
	}
	| variable INCOP 
	{
	    outlog<<"At line no: "<<lines<<" factor : variable INCOP "<<endl<<endl;
		outlog<<$1->getname()<<"++"<<endl<<endl;
			
		$$ = new symbol_info($1->getname()+"++","fctr");
	}
	| variable DECOP
	{
	    outlog<<"At line no: "<<lines<<" factor : variable DECOP "<<endl<<endl;
		outlog<<$1->getname()<<"--"<<endl<<endl;
			
		$$ = new symbol_info($1->getname()+"--","fctr");
	}
	;
	
argument_list : arguments
			  {
					outlog<<"At line no: "<<lines<<" argument_list : arguments "<<endl<<endl;
					outlog<<$1->getname()<<endl<<endl;
						
					$$ = new symbol_info($1->getname(),"arg_list");
					$$->set_parameters($1->get_parameters());
			  }
			  |
			  {
					outlog<<"At line no: "<<lines<<" argument_list :  "<<endl<<endl;
					outlog<<""<<endl<<endl;
						
					$$ = new symbol_info("","arg_list");
					$$->set_parameters(vector<pair<string, string>>());
			  }
			  ;
	
arguments : arguments COMMA logic_expression
		  {
				outlog<<"At line no: "<<lines<<" arguments : arguments COMMA logic_expression "<<endl<<endl;
				outlog<<$1->getname()<<","<<$3->getname()<<endl<<endl;
				vector<pair<string, string>> params = $1->get_parameters();
				params.push_back({$3->get_datatype(), $3->getname()});
						
				$$ = new symbol_info($1->getname()+","+$3->getname(),"arg");
				$$->set_parameters(params);
		  }
	      | logic_expression
	      {
				outlog<<"At line no: "<<lines<<" arguments : logic_expression "<<endl<<endl;
				outlog<<$1->getname()<<endl<<endl;
				vector<pair<string, string>> params;
				params.push_back({$1->get_datatype(), $1->getname()});
						
				$$ = new symbol_info($1->getname(),"arg");
				$$->set_parameters(params);
		  }
	      ;
 

%%

int main(int argc, char *argv[])
{
	if(argc != 2) 
	{
		cout<<"Please input file name"<<endl;
		return 0;
	}
	yyin = fopen(argv[1], "r");
	outlog.open("my_log.txt", ios::trunc);
	outerror.open("my_error.txt", ios::trunc);
	
	if(yyin == NULL)
	{
		cout<<"Couldn't open file"<<endl;
		return 0;
	}
	// Enter the global or the first scope here
	table= new symbol_table(11);
	outlog << "New ScopeTable with ID 1 created" << endl << endl;

	yyparse();
	
	outlog<<endl<<"Total lines: "<<lines<<endl;
	outlog<<endl<<"Total error: "<<error_count<<endl;
	outerror<<endl<<"Total error: "<<error_count<<endl;
	
	outlog.close();
	outerror.close();
	
	fclose(yyin);
	
	return 0;
}