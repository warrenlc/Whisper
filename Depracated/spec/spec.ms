.TL
Språkspecifikation vers. 2.0 
.AU 
Viktor Norlin och Warren Crutcher
.AU
\*[DY]
.NH
Generella egenskaper
.RS
.IP \[bu] 2 
Språket ska, om möjligt, vara imperativt, interpreterat och statiskt typat.
.IP \[bu] 
Språket ska stödja de "vanliga" datatyperna, så som float, int, bool etc.
.IP \[bu]
Språket ska ha stöd för funktioner. Funktioners returtyp ska vara hårt typat.
.IP \[bu]
Språket är "general purpose", alltså har det inget specifikt syfte utöver att vara ett generellt programspråk.
.RE
.NH
Nedan följer några kodexempel på hur språket skrivs.
.SH
Deklarera variabler
.RS
.IP \[bu] 2
let age -> int = 30;
.IP \[bu]
let height -> float = 5.6;
.IP \[bu]
let name -> string = "John Doe";
.RE
.SH
Funktion som tar två int som argument och returnerar en int
.RS
.IP \[bu] 2
let add -> (num1 -> int, num1 -> int) int {
.PP 
    ...
.RE
.PP
    }
.SH
Funktion som tar inga argument och inte returnerar något
.RS
.IP \[bu] 2
let print -> () void {
.PP
    ...
.RE
.PP
    }
.PP
.SH 
Styrstruktur - if, for och while
.RS
.IP \[bu] 2
let x -> int 10;
.IP \[bu]
let x -> int 5;
.IP \[bu]
if (x > y) {
.RE
.PP    
        print(x);
.PP
    } else {
.PP
        print(y);
.PP
    }
.PP
.PP
.RS
.IP \[bu] 2
for (let i -> int = 0; i < 10; ++i) {
.RE
.PP
        ...
.PP
    }
.PP
.RS
.IP \[bu] 2
for (i -> int in 1 to 10) {
.RE
.PP
        ...
.PP
    }
.RS
.IP \[bu] 2
while (1) {
.RE
.PP
        ...
.PP
    }
.NH
Felhantering
.RS
Vi anser att felhanteringen kommer vara en väldigt viktig del av språkets
utveckling och användbarhet. Just nu är vi osäkra om detaljarna angående s.k. 
"Stack Traces" men vi planerar utveckla den delen löpande under språkets utveckling.
.RE
.NH 
Grammatik
.RS
.SH
Arithmetic and logical grammar
.IP \[bu] 2
<stmt> ::= <term> | <assign>
.IP \[bu]
<term> ::= <factor> | <term> <addop> <factor> | <term> <orop> <factor>
.IP \[bu]
<factor> ::= <atom> | <factor> <mulop> <atom> | <factor> <andop> <atom>
.IP \[bu]
<atom> ::= <number> | <bool> | <variable> | "(" <term> ")" | <addop> <atom> | <notop> <atom>
.IP \[bu]
<number> ::= <integer> | <real>
.IP \[bu]
<integer> ::= <digit> | <digit> <integer>
.IP \[bu]
<real> ::= <integer> "." <integer>
.IP \[bu]
<digit> ::= [0-9]
.IP \[bu]
<variable> ::= <letter> | <letter> <variable>
.IP \[bu]
<letter> ::= [a-z] | [A-Z]
.IP \[bu]
<bool> ::= "true" | "false"
.IP \[bu]
<addop> ::= "+" | "-"
.IP \[bu]
<mulop> ::= "*" | "/"
.IP \[bu]
<orop> ::= "||"
.IP \[bu]
<andop> ::= "&&"
.IP \[bu]
<notop> ::= "!"
.IP \[bu]
<assign> ::= <variable> "=" <term>
.SH
Alternative arithmetic and logical grammar
.IP \[bu] 2
<stmt> ::= <term> | <assign>
.IP \[bu]
<term> ::= <arithmetic_term> | <logical_term>
.IP \[bu]
<arithmetic_term> ::= <arithmetic_factor> | <arithmetic_term> <addop> <arithmetic_factor>
.IP \[bu]
<arithmetic_factor> ::= <arithmetic_atom> | <arithmetic_factor> <mulop> <arithmetic_atom>
.IP \[bu]
<arithmetic_atom> ::= <number> | <variable> | "(" <arithmetic_term> ")" | <addop> <arithmetic_atom>
.IP \[bu]
<logical_term> ::= <logical_factor> | <logical_term> <orop> <logical_factor>
.IP \[bu]
<logical_factor> ::= <logical_atom> | <logical_factor> <andop> <logical_atom>
.IP \[bu]
<logical_atom> ::= <bool> | <variable> | "(" <logical_term> ")" | <notop> <logical_atom>
.IP \[bu]
<number> ::= <integer> | <real>
.IP \[bu]
<integer> ::= <digit> | <digit> <integer>
.IP \[bu]
<real> ::= <integer> "." <integer>
.IP \[bu]
<digit> ::= [0-9]
.IP \[bu]
<variable> ::= <letter> | <letter> <variable>
.IP \[bu]
<letter> ::= [a-z] | [A-Z]
.IP \[bu]
<bool> ::= "true" | "false"
.IP \[bu]
<addop> ::= "+" | "-"
.IP \[bu]
<mulop> ::= "*" | "/"
.IP \[bu]
<orop> ::= "||"
.IP \[bu]
<andop> ::= "&&"
.IP \[bu]
<notop> ::= "!"
.IP \[bu]
<assign> ::= <variable> "=" <term>
.RE
.SH
Problemet med grammatiken ovan är att en variabel kan vara "false", så uttryck som "false=true" blir valid. Även uttryck som "21+false" är valid, då "false" i detta fallet räknas som en variabel och inte en faktisk bool.
.SH
Kopior vs Referenser
.IP
Vi vill att alla variabler som skickas till en funktion
är referenser och inte kopior. Vi vet dock inte om det blir
svårare eller lättare att implementera. Det känns bara mer 
robust att om ett värde skickas till en funktion för att muteras
att värdet faktiskt ändras. 
.IP
Däremot vill vi att det händer per automatik och att programmeraren
inte behöver bestämma manuellt (som i C eller C++)
.SH
Scope
.IP
Språket ska var väldigt statiskt skopat. Globala variabler är inte tillåtet.
Vi tycker att detta kommer göra den funktionella sidan av språket mer ren och
minska sidoeffekter. Tanken är att vi har nästlade Hash där variable namn eller
funktionsnamn blir nyckel och värdet på variabler är nyckelns värde, samt funktionskropp
blir värde till en funkitonsnamns nyckel.
.IP
Vi tycker överlag att vi har svårt att spendera tiden som krävs för att göra en djupgående utredning om det här just
nu i och med att vi har fullt upp med nätverkskursen och duggan för TDP007 nu på onsdag. Efter vi har gjort färdigt både duggan
och labbarna i nätverkskursen kommer vi har mer tid att dyka djupare i de här frågorna.



















