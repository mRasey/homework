附录A  PL/0编译系统源代码
program pl0 ;  { version 1.0 oct.1989 }
{ PL/0 compiler with code generation }
const norw = 13;          { no. of reserved words }
      txmax = 100;        { length of identifier table }
      nmax = 14;          { max. no. of digits in numbers }
      al = 10;            { length of identifiers }
      amax = 2047;        { maximum address }
      levmax = 3;         { maximum depth of block nesting }
      cxmax = 200;        { size of code array }

type symbol =
     ( nul,ident,number,plus,minus,times,slash,oddsym,eql,neq,lss,
       leq,gtr,geq,lparen,rparen,comma,semicolon,period,becomes,
       beginsym,endsym,ifsym,thensym,whilesym,dosym,callsym,constsym,
       varsym,procsym,readsym,writesym );   {枚举符号类型}
     alfa = packed array[1..al] of char;   {定义长度为10的数组}
     objecttyp = (constant,variable,prosedure);   {}
     symset = set of symbol;   {符号集合}
     fct = ( lit,opr,lod,sto,cal,int,jmp,jpc,red,wrt ); { functions }
     instruction = packed record
                     f : fct;            { function code }
                     l : 0..levmax;      { level }
                     a : 0..amax;        { displacement address }
                   end;
                  {   lit 0, a : load constant a
                      opr 0, a : execute operation a
                      lod l, a : load variable l,a
                      sto l, a : store variable l,a
                      cal l, a : call procedure a at level l
                      int 0, a : increment t-register by a
                      jmp 0, a : jump to a
                      jpc 0, a : jump conditional to a
                      red l, a : read variable l,a
                      wrt 0, 0 : write stack-top
                  }

var   ch : char;      { last character read }
      sym: symbol;    { last symbol read }
      id : alfa;      { last identifier read }
      num: integer;   { last number read }
      cc : integer;   { character count }
      ll : integer;   { line length }
      kk,err: integer;   { 错误编号 }
      cx : integer;   { code allocation index }
      line: array[1..81] of char;   { 存储读入字符 }
      a : alfa;
      code : array[0..cxmax] of instruction;
      word : array[1..norw] of alfa;
      wsym : array[1..norw] of symbol;
      ssym : array[char] of symbol;
      mnemonic : array[fct] of
                   packed array[1..5] of char;
      declbegsys, statbegsys, facbegsys : symset;
      table : array[0..txmax] of
                record
                  name : alfa;
                  case kind: objecttyp of
                    constant : (val:integer );
                    variable,prosedure: (level,adr: integer )
                end;
      fin : text;     { source program file }
      sfile: string;  { source program file name }

procedure error( n : integer );
  begin
    writeln( '****', ' ':cc-1, '^', n:2 );   {*输出错误代码行号*}
    err := err+1   {*出错次数加一*}
  end; { error }

{*词法分析过程*}
procedure getsym;
var i,j,k : integer;
{*读取下一个字符*}
procedure getch;
    begin
      if cc = ll  { get character to end of line }
      then begin { read next line }
             if eof(fin)   {*如果读到文件的末尾*}
             then begin
                   writeln('program incomplete');   {*输出“program incomplete”*}
                   close(fin);   {*关闭文件输入*}
                   exit;   {*退出程序*}
                  end;
             ll := 0;   {*行缓冲区长度置0*}
             cc := 0;   {*缓冲区指针置于行首*}
             write(cx:4,' ');  { print code address }
             while not eoln(fin) do   {*如果没有读到行末就一直循环*}
               begin
                 ll := ll+1;   {*行缓冲区长度加一*}
                 read(fin,ch);   {*读入一个字符*}
                 write(ch);   {*输出读取的字符到文件*}
                 line[ll] := ch   {*把读到的字符存入行缓冲区的相应位置*}
               end;
             writeln;   {*输出一行*}
             readln(fin);   {*从文件中读入一行*}
             ll := ll+1;   {*行缓冲区长度加一*}
             line[ll] := ' ' { process end-line }
           end;
      cc := cc+1;   {*缓冲区指针往后挪一位*}
      ch := line[cc]   {*从缓冲区读出指针当前指向的字符给ch*}
    end; { getch }
  begin { procedure getsym;   }
    while ch = ' ' do   {*如果ch是‘ ’则一直循环*}
      getch;   {*读入一个字符*}
    if ch in ['a'..'z']   {*如果字符是a到z之间的符号*}
    then begin  { identifier of reserved word }
           k := 0;   {*将缓冲区指针置为0*}
           repeat
             if k < al   {*如果k小于字符最大长度就读取整个字符，否则就取前一部分*}
             then begin
                   k := k+1;
                   a[k] := ch
                 end;
             getch   {*读取下一个字符*}
           until not( ch in ['a'..'z','0'..'9']);   {*循环直到读到不在a到z之间的字符*}
           if k >= kk        { kk : last identifier length }
           then kk := k   {*将kk的值置为k*}
           else repeat
                  a[kk] := ' ';   {*将a[k]元素之后的未使用空间全部置为‘’*}
                  kk := kk-1
               until kk = k;
           id := a;   {*标识符设为a*}
           i := 1;   {*i指向第一个保留字*}
           j := norw;   {*j指向最后一个保留字*} { binary search reserved word table }
           repeat
             k := (i+j) div 2;   {*使用二分查找的方法查找标识符在保留字表中的位置*}
             if id <= word[k]
             then j := k-1;
             if id >= word[k]
             then i := k+1
           until i > j;
           if i-1 > j
           then sym := wsym[k]   {*把sym置为找到的保留字的值*}
           else sym := ident   {*如果没有找到就将sym置为ident，表示是标识符*}
         end
    else if ch in ['0'..'9']   {*如果ch是一个数字*}
         then begin  { number }
                k := 0;   {*k表示数字位置为0*}
                num := 0;   {*数字初始值为0*}
                sym := number;   {*表示是一个数字*}
                repeat
                  num := 10*num+(ord(ch)-ord('0'));   {*循环读取所有连续的数字并计算组合为同一个数字*}
                  k := k+1;
                  getch
                until not( ch in ['0'..'9']);
                if k > nmax   {*如果k大于规定的最大的位数*}
                then error(30)   {*抛出异常30*}
              end
         else if ch = ':'   {*如果ch是：*}
              then begin
                    getch;   {*读取下一个字符*}
                    if ch = '='   {*如果ch是=*}
                    then begin
                          sym := becomes;   {*将sym的值置为赋值类型*}
                          getch   {*读取下一个字符*}
                        end
                    else sym := nul   {*如果ch不是=，则sym置为非法字符*}
                   end
              else if ch = '<'   {*如果ch是<*}
                   then begin
                          getch;   {*读取下一个字符*}
                          if ch = '='   {*如果ch是=*}
                          then begin
                                 sym := leq;   {*sym置为小于等于号*}
                                 getch   {*读取下一个字符*}
                               end
                          else if ch = '>'   {*如果ch是>*}
                               then begin
                                     sym := neq;   {*sym置为不等于号*}
                                     getch   {*读取下一个字符*}
                                   end
                          else sym := lss   {*否则则将sym置为小于号*}
                        end
                   else if ch = '>'   {*如果ch是>*}
                        then begin
                               getch;   {*获取下一个字符*}
                               if ch = '='   {*如果ch是=*}
                               then begin
                                      sym := geq;   {*则将sym置为等于等于号*}
                                      getch   {*获取下一个字符*}
                                    end
                               else sym := gtr   {*否则则将sym置为大于号*}
                             end
                        else begin
                               sym := ssym[ch];   {*否则则从符号表中查到它的类型赋给sym*}
                               getch   {*读取下一个字符*}
                             end
  end; { getsym }

{*将生成的代码写入目标代码数组*}
procedure gen( x: fct; y,z : integer );
  begin
    if cx > cxmax   {*如果当前代码行号大于最大的代码行号*}
    then begin
           writeln('program too long');   {*输出“program too long”*}
           close(fin);   {*关闭文件输入*}
           exit   {*程序退出*}
         end;
    with code[cx] do   {*将操作类型和两个操作数赋值给当前数组位置*}
      begin
        f := x;
        l := y;
        a := z
      end;
    cx := cx+1
  end; { gen }

{*测试当前单词是否合法*}
{*s1:当语法分析进入或退出某一语法单元时，当前单词符合应属于的集合*}
{*s2:在某一出错状态下，可恢复语法分析正常工作的补充单词集合*}
procedure test( s1,s2 :symset; n: integer );
  begin
    if not ( sym in s1 )   {*如果sym不在s1集合里*}
    then begin
           error(n);   {*抛出异常n*}
           s1 := s1+s2;   {*把s2集合补充进s1集合*}
           while not( sym in s1) do   {*循环找到下一个合法的符号继续语法分析*}
             getsym
           end
  end; { test }

procedure block( lev,tx : integer; fsys : symset );
  var  dx : integer;  { data allocation index }
       tx0: integer;  { initial table index }
       cx0: integer;  { initial code index }

  procedure enter( k : objecttyp );
    begin  { enter object into table }
      tx := tx+1;   {*符号表指针往后挪动一位*}
      with table[tx] do
        begin
          name := id;   {*name是符号的名字*}
          kind := k;   {*kind记录符号类型*}
          case k of   {*对不同的类型进行不同的操作*}
            constant : begin   {*如果是常量*}
                      if num > amax   {*如果常量的值大于规定的最大值*}
                      then begin
                            error(30);   {*抛出错误30*}
                            num := 0   {*将常量设为0*}
                           end;
                      val := num   {*如果是合法字符就加入符号表中*}
                    end;
            variable : begin   {*如果是变量*}
                      level := lev;   {*记下所属层次号*}
                      adr := dx;   {*记下在当前层次的偏移量*}
                      dx := dx+1   {*将偏移量加一*}
                    end;
            prosedure: level := lev;   {*如果是过程，则记下当前的层次*}
          end
        end
    end; { enter }

{*id:要找的符号*}
{*返回值：找到的符号的位置，未找到则返回0*}
function position ( id : alfa ): integer;   {*在符号表中查找符号所在的位置*}
  var i : integer;
  begin
    table[0].name := id;   {*把id放入符号表的0号位置*}
    i := tx;   {*从符号表指针的当前位置，从后往前找*}
    while table[i].name <> id do   {*如果没有找到就一直往前寻找*}
       i := i-1;
    position := i   {*返回找到的符号的位置*}
  end;  { position }

{*处理常量声明过程*}
procedure constdeclaration;
    begin
      if sym = ident   {*如果第一个符号是标识符*}
      then begin
             getsym;   {*获取下一个符号*}
             if sym in [eql,becomes]   {*如果符号是等号或者赋值号*}
             then begin
                    if sym = becomes   {*如果符号是赋值号*}
                    then error(1);   {*抛出异常1*}
                    getsym;   {*获取下一个符号*}
                    if sym = number   {*如果符号是数字*}
                    then begin
                           enter(constant);   {*将常量加入符号表*}
                           getsym   {*获取下一个符号*}
                         end
                    else error(2)   {*如果不是数字，抛出异常2*}
                  end
             else error(3)   {*如果不是等号或者赋值号，则抛出异常3*}
           end
      else error(4)   {*如果第一个符号不是标识符，则抛出异常4*}
    end; { constdeclaration }

  {*变量声明过程*}
  procedure vardeclaration;
    begin
      if sym = ident   {*如果第一个符号是标识符*}
      then begin
             enter(variable);   {*将变量加入符号表*}
             getsym   {*获取下一个符号*}
           end
      else error(4)   {*如果第一个符号不是标识符，则抛出异常4*}
    end; { vardeclaration }

  {*列出当前层的Pcode*}
  procedure listcode;
    var i : integer;
    begin
      for i := cx0 to cx-1 do   {*从开始位置到当前位置减一*}
        with code[i] do
          writeln( i:4, mnemonic[f]:7,l:3, a:5)   {*输出代码行号，操作类型和l操作数，a操作数*}
    end; { listcode }

procedure statement( fsys : symset );
var i,cx1,cx2: integer;
{*表达式处理程序*}
{fsys：如果出错可以用来回复语法分析的符号集合}
procedure expression( fsys: symset);
      var addop : symbol;
      {*项处理过程*}
      procedure term( fsys : symset);
        var mulop: symbol ;
        {*因子处理过程*}
        procedure factor( fsys : symset );
          var i : integer;
          begin
            test( facbegsys, fsys, 24 );   {*检测token是否在项因子集合中*}
            while sym in facbegsys do   {*如果sym在项因子集合中*}
              begin
                if sym = ident   {*如果sym是标识符*}
                then begin
                       i := position(id);   {将id在表中的位置赋给i}
                       if i= 0   {如果i是0，表示不再表中}
                       then error(11)   {*抛出异常11*}
                       else
                         with table[i] do   {*如果在表中则取table[i]*}
                           case kind of
                             constant : gen(lit,0,val);   {如果是常量则生成lit指令}
                             variable : gen(lod,lev-level,adr);   {如果是变量则生成lod指令}
                             prosedure: error(21)   {*如果是过程则抛出异常21*}
                           end;
                       getsym   {获取下一个token}
                     end
                else if sym = number   {*如果sym是数字*}
                     then begin
                            if num > amax   {*如果num大于规定的最大数字*}
                            then begin
                                   error(30);   {*抛出异常30*}
                                   num := 0   {*将num置为0*}
                                 end;
                            gen(lit,0,num);   {*生成lit代码*}
                            getsym   {*获取下一个token*}
                          end
                     else if sym = lparen   {*如果sym是左括号*}
                          then begin
                                 getsym;   {*获取下一个token*}
                                 expression([rparen]+fsys);   {*递归分析子表达式*}
                                 if sym = rparen  {*如果sym是右括号*}
                                 then getsym   {*获取下一个token*}
                                 else error(22)   {*抛出异常22*}
                               end;
                test(fsys,[lparen],23)   {*测试token是否在项因子集合中*}
              end
          end; { factor }
          begin { procedure term( fsys : symset);
                  var mulop: symbol ;    }
            factor( fsys+[times,slash]);   {*调用factor分析子程序*}
            while sym in [times,slash] do   {*如果sym是乘法或者除法*}
              begin
                mulop := sym;   {*保存当前运算符*}
                getsym;   {*获取下一个token*}
                factor( fsys+[times,slash] );   {*调用factor分析云算法后的因子*}
                if mulop = times   {*如果是乘法*}
                then gen( opr,0,4 )   {*生成opr指令*}
                else gen( opr,0,5)   {*否则生成除法指令*}
              end
          end; { term }
          begin { procedure expression( fsys: symset);
                  var addop : symbol; }
            if sym in [plus, minus]   {*如果token以加号或者减号开始*}
            then begin
                   addop := sym;   {*保存加号或者减号字符*}
                   getsym;   {*获取下一个token*}
                   term( fsys+[plus,minus]);   {*调用项处理程序*}
                   if addop = minus   {*如果是减号*}
                   then gen(opr,0,1)   {*生成取反指令*}
                 end
            else term( fsys+[plus,minus]);   {*如果不是以加号或者减号开始，则调用项处理程序*}
            while sym in [plus,minus] do   {*如果token是加号或者减号*}
              begin
                addop := sym;   {*保存token*}
                getsym;   {*获取下一个标识符*}
                term( fsys+[plus,minus] );   {*调用项处理程序处理当前token*}
                if addop = plus   {*如果保存的token是加号*}
                then gen( opr,0,2)   {*生成加法指令*}
                else gen( opr,0,3)   {*否则生成减法指令*}
              end
          end; { expression }

    {*条件处理程序*}
    {*fsys：可用来恢复语法分析的符号集合*}
    procedure condition( fsys : symset );
      var relop : symbol;
      begin
        if sym = oddsym   {*如果token是odd运算符*}
        then begin
               getsym;   {*获取下一个token*}
               expression(fsys);   {*对odd表达式进行处理*}
               gen(opr,0,6)   {生成odd指令}
             end
        else begin   {*如果不是odd运算*}
             expression( [eql,neq,lss,gtr,leq,geq]+fsys);
             if not( sym in [eql,neq,lss,leq,gtr,geq])   {*如果token不是比较运算符*}
               then error(20)   {*抛出异常20*}
               else begin   {*如果是条件运算符*}
                      relop := sym;   {*保存当前操作符*}
                      getsym;   {*获取下一个token*}
                      expression(fsys);   {*对表达式右部进行判断*}
                      case relop of   {*按照操作符类型生成代码*}
                        eql : gen(opr,0,8);   {*如果是等号就生成8号指令*}
                        neq : gen(opr,0,9);   {*如果是等号就生成9号指令*}
                        lss : gen(opr,0,10);   {如果是小于号就生成10号指令}
                        geq : gen(opr,0,11);   {*如果是大于等于就生成11号指令*}
                        gtr : gen(opr,0,12);   {*如果是大于号就生成12号指令*}
                        leq : gen(opr,0,13);   {*如果是小于等于就生成13号指令*}
                      end
                    end
             end
      end; { condition }
    begin { procedure statement( fsys : symset );
      var i,cx1,cx2: integer; }
      if sym = ident   {*如果是以标识符开头则可能是赋值语句*}
      then begin
             i := position(id);   {*从符号表中找到对应的id的位置赋值给i*}
             if i= 0   {*如果i为0表示没有找到*}
             then error(11)   {*抛出异常11*}
             else if table[i].kind <> variable   {*如果发现不是一个变量类型*}
                  then begin { giving value to non-variation }
                         error(12);   {*抛出异常12*}
                         i := 0   {*将i置为0*}
                       end;
             getsym;   {*获取下一个token*}
             if sym = becomes   {*如果token是一个赋值语句*}
             then getsym   {*获取下一个token*}
             else error(13);   {*否则抛出异常13*}
             expression(fsys);   {*对右部表达式进行分析*}
             if i <> 0   {*如果i不为0*}
             then
               with table[i] do   {*从表中取出第i个符号*}
                  gen(sto,lev-level,adr)   {*生成赋值代码*}
          end
      else if sym = callsym   {*如果token是一个函数调用符号*}
      then begin
             getsym;   {*获取下一个token*}
             if sym <> ident   {*如果token不为标识符*}
             then error(14)   {*抛出异常14*}
             else begin
                    i := position(id);   {*从符号表中取出id的位置赋给i*}
                    if i = 0   {*如果i为0*}
                    then error(11)   {*抛出异常11*}
                    else
                      with table[i] do   {*从符号表中取出第i个符号项*}
                        if kind = prosedure   {*如果是一个过程*}
                        then gen(cal,lev-level,adr)   {*生成方法调用指令*}
                        else error(15);   {*否则抛出异常15*}
                    getsym   {*获取下一个token*}
                  end
           end
      else if sym = ifsym   {*如果token表示一个if判断语句*}
           then begin
                  getsym;   {*获取下一个token*}
                  condition([thensym,dosym]+fsys);   {*对token进行条件语句处理*}
                  if sym = thensym   {*如果token是一个then*}
                  then getsym   {*获取下一个token*}
                  else error(16);   {*否则抛出异常16*}
                  cx1 := cx;   {*记下当前代码指针的位置*}
                  gen(jpc,0,0);   {*生成跳转语句*}
                  statement(fsys);   {*对循环体进行分析*}
                  code[cx1].a := cx   {*上一行指令的跳转位置设为当前指令的位置*}
                end
           else if sym = beginsym   {*如果token是一个begin标识符*}
                then begin
                       getsym;   {*获取下一个token*}
                       statement([semicolon,endsym]+fsys);   {*对begin和end之间的代码进行分析*}
                       while sym in ([semicolon]+statbegsys) do
                         begin
                           if sym = semicolon   {*如果token是一个分号*}
                           then getsym   {*获取下一个token*}
                           else error(10);   {*否则抛出异常10*}
                           statement([semicolon,endsym]+fsys)   {*分析分号后面的代码*}
                         end;
                       if sym = endsym   {*如果token是end*}
                       then getsym   {*获得下一个token*}
                       else error(17)   {*抛出异常*}
                     end
                else if sym = whilesym   {*如果token是一个while代码块*}
                     then begin
                            cx1 := cx;   {*记下当前代码指针的位置*}
                            getsym;   {*获取下一个token*}
                            condition([dosym]+fsys);   {*分析条件语句*}
                            cx2 := cx;   {*记下当前代码指针的位置*}
                            gen(jpc,0,0);   {*生成跳转语句*}
                            if sym = dosym   {*如果token是一个do标识符*}
                            then getsym   {*获取下一个token*}
                            else error(18);   {*否则抛出异常18*}
                            statement(fsys);   {*分析do后面代码块的内容*}
                            gen(jmp,0,cx1);   {*生成跳转指令*}
                            code[cx2].a := cx   {*将上一行生成代码的位置设为当前代码指针的位置*}
                          end
                     else if sym = readsym   {*如果是一个read标识符*}
                          then begin
                                 getsym;   {*获取下一个token*}
                                 if sym = lparen   {*如果是一个左括号*}
                                 then
                                   repeat
                                     getsym;   {*获取下一个token*}
                                     if sym = ident   {*如果token是一个标识符*}
                                     then begin
                                            i := position(id);   {*从符号表中找到对应id的位置*}
                                            if i = 0   {*如果i是0*}
                                            then error(11)   {*抛出异常11*}
                                            else if table[i].kind <> variable   {*如果i的位置不是一个变量*}
                                                 then begin
                                                        error(12);   {*抛出异常12*}
                                                        i := 0   {*将i设为0*}
                                                      end
                                                 else with table[i] do   {*对于第i个位置的符号*}
                                                       gen(red,lev-level,adr)   {*生成read指令*}
                                         end
                                     else error(4);   {*抛出异常4*}
                                     getsym;   {*获取下一个token*}
                                   until sym <> comma   {*如果token不是一个逗号*}
                                 else error(40);   {*抛出异常40*}
                                 if sym <> rparen   {*如果token不是一个右括号*}
                                 then error(22);   {*抛出异常22*}
                                 getsym   {*获取下一个token*}
                               end
                          else if sym = writesym   {*如果token是一个write标识符*}
                               then begin
                                      getsym;   {*获取下一个token*}
                                      if sym = lparen   {*如果token是一个左括号*}
                                      then begin
                                             repeat
                                               getsym;   {*获取下一个token*}
                                               expression([rparen,comma]+fsys);   {*对后面的表达式进行分析*}
                                               gen(wrt,0,0);   {*生成write指令*}
                                             until sym <> comma;   {*知道token不为逗号*}
                                             if sym <> rparen   {如果token是右括号}
                                             then error(22);   {*抛出异常22*}
                                             getsym   {*获取下一个token*}
                                           end
                                      else error(40)   {*抛出异常40*}
                                    end;
      test(fsys,[],19)
    end; { statement }
  begin  {   procedure block( lev,tx : integer; fsys : symset );
    var  dx : integer;  /* data allocation index */
    tx0: integer;  /*initial table index */
    cx0: integer;  /* initial code index */              }
    dx := 3;   {*设置数据位置分配初始值为3*}
    tx0 := tx;   {*记录当前符号表指针的位置*}
    table[tx].adr := cx;   {*将当前代码指针的位置赋值给符号表指针当前所指的位置*}
    gen(jmp,0,0); { jump from declaration part to statement part }
    if lev > levmax   {*如果层数大于规定的层数*}
    then error(32);   {*抛出异常32*}

    repeat
      if sym = constsym   {*如果token是一个常量声明符号*}
      then begin
             getsym;   {*获取下一个token*}
             repeat
               constdeclaration;   {*进行常量声明分析*}
               while sym = comma do   {*如果token是一个逗号*}
                 begin
                   getsym;   {*获取下一个token*}
                   constdeclaration   {*进行常量声明分析*}
                 end;
               if sym = semicolon   {*如果token是一个分号*}
               then getsym   {*获取下一个token*}
               else error(5)   {*否则抛出异常5*}
             until sym <> ident   {*循环直到token不是一个标识符*}
           end;
      if sym = varsym   {*如果token是一个变量声明*}
      then begin
             getsym;   {*获取下一个token*}
             repeat
               vardeclaration;   {*进行变量声明分析*}
               while sym = comma do   {*如果token是逗号就一直循环*}
                 begin
                   getsym;   {*获取下一个token*}
                   vardeclaration   {*进行变量声明分析*}
                 end;
               if sym = semicolon   {*如果token是分号*}
               then getsym   {*获取下一个token*}
               else error(5)   {*否则抛出异常5*}
             until sym <> ident;   {*循环直到token不为标识符*}
           end;
      while sym = procsym do   {*如果token是过程标志就一直循环*}
        begin
          getsym;   {*获取下一个token*}
          if sym = ident   {*如果token是一个标识符*}
          then begin
                 enter(prosedure);   {*将过程记录进符号表*}
                 getsym   {*获取下一个token*}
               end
          else error(4);   {*否则抛出异常4*}
          if sym = semicolon   {*如果token是分号*}
          then getsym   {*获取下一个token*}
          else error(5);   {*否则抛出异常5*}
          block(lev+1,tx,[semicolon]+fsys);  {*递归调用语法分析过程，当前层次加一，同时传递表头索引、合法单词符*}
          if sym = semicolon   {*如果token是分号*}
          then begin
                 getsym;   {*获取下一个token*}
                 test( statbegsys+[ident,procsym],fsys,6)  {*检测token是否合法，如果不合法则用fsys恢复语法，同时抛出6号错误*}
               end
          else error(5)   {*否则抛出5号错误*}
        end;
      test( statbegsys+[ident],declbegsys,7)   {*检测token是否合法，如果不合法用declbegsys恢复语法，同时抛出7号错误*}
    until not ( sym in declbegsys );   {*循环直到token不在声明标识符中*}
    code[table[tx0].adr].a := cx;  { back enter statement code's start adr. }
    with table[tx0] do   {*从符号表中取出记录的符号表指针指向的位置*}
      begin
        adr := cx;   {*将当前代码指针的位置记在表中*} { code's start address }
      end;
    cx0 := cx;   {记录下当前代码指针的位置}
    gen(int,0,dx);   {*生成分配空间指令，分配长度为dx*} { topstack point to operation area }
    statement( [semicolon,endsym]+fsys);   {*分析当前语句块*}
    gen(opr,0,0);   {*生成0号代码指令*} { return }
    test( fsys, [],8 );   {*测试当前状态是否合法，如果不合法抛出异常8*}
    listcode;   {*列出当前生成的代码*}
  end { block };

{*pcode解释运行过程*}
procedure interpret;
  const stacksize = 500;   {*栈长度设为500*}
  var p,b,t: integer; { program-,base-,topstack-register }
     i : instruction;   {*存放当前运行的指令*}{ instruction register }
     s : array[1..stacksize] of integer;   {*s为栈式计算机的数据区*} { data store }
  {*根据数据链求出数据基地址函数*}
  function base( l : integer ): integer;
    var b1 : integer;
    begin { find base l levels down }
      b1 := b;
      while l > 0 do
        begin
          b1 := s[b1];
          l := l-1
        end;
      base := b1
    end; { base }
  begin
    writeln( 'START PL/0' );
    t := 0;   {*程序开始运行时栈顶寄存器置0*}
    b := 1;   {*数据段基址为1*}
    p := 0;   {*从0号代码开始执行程序*}
    s[1] := 0;
    s[2] := 0;
    s[3] := 0;   {*数据段中SL,DL,RA三个单元均为0，标识为主程序*}
    repeat
      i := code[p];   {*取出当前执行代码*}
      p := p+1;   {*p指向后一行代码*}
      with i do
        case f of   {*根据指令类型进行操作*}
        {   lit 0, a : load constant a
            opr 0, a : execute operation a
            lod l, a : load variable l,a
            sto l, a : store variable l,a
            cal l, a : call procedure a at level l
            int 0, a : increment t-register by a
            jmp 0, a : jump to a
            jpc 0, a : jump conditional to a
            red l, a : read variable l,a
            wrt 0, 0 : write stack-top
        }
          lit : begin
                  t := t+1;   {*栈长度加一*}
                  s[t]:= a;   {*栈顶设为a*}
              end;
          opr : case a of { operator }
                  0 : begin { return }
                        t := b-1;   {*返回上一层*}
                        p := s[t+3];   {*获取返回地址代码*}
                        b := s[t+2];   {*获取数据段基地址*}
                     end;
                  1 : s[t] := -s[t];   {*将栈顶数据取反*}
                  2 : begin
                        t := t-1;   {*将栈顶两个数据相加存储在栈顶*}
                        s[t] := s[t]+s[t+1]
                     end;
                  3 : begin
                        t := t-1;   {*将栈顶两个数据相减存储在栈顶*}
                        s[t] := s[t]-s[t+1]
                     end;
                  4 : begin
                        t := t-1;   {*将栈顶两个数据相减存储在栈顶*}
                        s[t] := s[t]*s[t+1]
                     end;
                  5 : begin
                        t := t-1;   {*将栈顶两个数据相除存储在栈顶*}
                        s[t] := s[t]div s[t+1]
                     end;
                  6 : s[t] := ord(odd(s[t]));   {*判断栈顶是否为奇数，将结果存储在栈顶*}
                  8 : begin
                        t := t-1;   {*判断栈顶两个数据是否相等，将结果存储在栈顶*}
                        s[t] := ord(s[t]=s[t+1])
                    end;
                  9 : begin
                        t := t-1;   {*判断栈顶两个数据是否不等，将结果存储在栈顶*}
                        s[t] := ord(s[t]<>s[t+1])
                     end;
                  10: begin
                        t := t-1;   {*判断栈顶两个数据的大小关系，将结果存储在栈顶*}
                        s[t] := ord(s[t]< s[t+1])
                     end;
                  11: begin
                        t := t-1;   {*判断栈顶两个数据的大小关系，将结果存储在栈顶*}
                        s[t] := ord(s[t] >= s[t+1])
                     end;
                  12: begin
                        t := t-1;   {*判断栈顶两个数据的大小关系，将结果存储在栈顶*}
                        s[t] := ord(s[t] > s[t+1])
                     end;
                  13: begin
                        t := t-1;   {*判断栈顶两个数据的大小关系，将结果存储在栈顶*}
                        s[t] := ord(s[t] <= s[t+1])
                     end;
                end;
          lod : begin
                  t := t+1;   {*将数据加载至栈顶*}
                  s[t] := s[base(l)+a]
              end;
          sto : begin
                  s[base(l)+a] := s[t];  { writeln(s[t]); }
                  t := t-1
              end;
          cal : begin  { generate new block mark }
                  s[t+1] := base(l);   {*在栈顶压入静态链SL*}
                  s[t+2] := b;   {*然后压入当前数据区基址，作动态链DL*}
                  s[t+3] := p;   {*最后压入当前的断点，作为返回地址RA*}
                  b := t+1;   {*把当前数据区基址指向SL所在位置*}
                  p := a;   {*跳转到a准备从a开始执行指令*}
              end;
          int : t := t+a;   {*申请长度为a的空间*}
          jmp : p := a;   {*跳转到a的位置准备执行代码*}
          jpc : begin
                  if s[t] = 0   {*如果栈顶为0，则跳转到a位置*}
                  then p := a;
                  t := t-1;   {*否则弹出栈顶*}
              end;
          red : begin
                  writeln('??:');   {*读取基地址偏移为a的位置的数据*}
                  readln(s[base(l)+a]);
              end;
          wrt : begin
                  writeln(s[t]);   {*写出当前栈顶的数据*}
                  t := t+1
              end
        end { with,case }
    until p = 0;
    writeln('END PL/0');
  end; { interpret }

begin { main }
  writeln('please input source program file name : ');
  readln(sfile);
  assign(fin,sfile);
  reset(fin);
  for ch := 'A' to ';' do
    ssym[ch] := nul;
  word[1] := 'begin        '; word[2] := 'call         ';
  word[3] := 'const        '; word[4] := 'do           ';
  word[5] := 'end          '; word[6] := 'if           ';
  word[7] := 'odd          '; word[8] := 'procedure    ';
  word[9] := 'read         '; word[10]:= 'then         ';
  word[11]:= 'var          '; word[12]:= 'while        ';
  word[13]:= 'write        ';

  wsym[1] := beginsym;      wsym[2] := callsym;
  wsym[3] := constsym;      wsym[4] := dosym;
  wsym[5] := endsym;        wsym[6] := ifsym;
  wsym[7] := oddsym;        wsym[8] := procsym;
  wsym[9] := readsym;       wsym[10]:= thensym;
  wsym[11]:= varsym;        wsym[12]:= whilesym;
  wsym[13]:= writesym;

  ssym['+'] := plus;        ssym['-'] := minus;
  ssym['*'] := times;       ssym['/'] := slash;
  ssym['('] := lparen;      ssym[')'] := rparen;
  ssym['='] := eql;         ssym[','] := comma;
  ssym['.'] := period;
  ssym['<'] := lss;         ssym['>'] := gtr;
  ssym[';'] := semicolon;

  mnemonic[lit] := 'LIT  '; mnemonic[opr] := 'OPR  ';
  mnemonic[lod] := 'LOD  '; mnemonic[sto] := 'STO  ';
  mnemonic[cal] := 'CAL  '; mnemonic[int] := 'INT  ';
  mnemonic[jmp] := 'JMP  '; mnemonic[jpc] := 'JPC  ';
  mnemonic[red] := 'RED  '; mnemonic[wrt] := 'WRT  ';

  declbegsys := [ constsym, varsym, procsym ];
  statbegsys := [ beginsym, callsym, ifsym, whilesym];
  facbegsys := [ ident, number, lparen ];
  err := 0;
  cc := 0;
  cx := 0;
  ll := 0;
  ch := ' ';
  kk := al;
  getsym;
  block( 0,0,[period]+declbegsys+statbegsys );
  if sym <> period
  then error(9);
  if err = 0
  then interpret
  else write('ERRORS IN PL/0 PROGRAM');
  writeln;
  close(fin)
end.
