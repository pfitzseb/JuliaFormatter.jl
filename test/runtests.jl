# fmt
import JuliaFormatter
using CSTParser
using Test

fmt(s, i = 4, m = 80) = JuliaFormatter.format_text(s, indent = i, margin = m)

function run_nest(text::String, print_width::Int)
    d = JuliaFormatter.Document(text)
    s = JuliaFormatter.State(d, 4, print_width)
    x = CSTParser.parse(text, true)
    t = JuliaFormatter.pretty(x, s)
    JuliaFormatter.nest!(t, s)
    s
end

@testset "All" begin

    @testset "basic" begin
        @test fmt("a") == "a"
        @test fmt("a  #foo") == "a  #foo"
        @test fmt("") == ""
    end

    @testset "nofmt" begin
        str = "# nofmt\n module Foo a \n end"
        @test fmt(str) == str
    end

    @testset "tuples" begin
        @test fmt("a,b") == "a, b"
        @test fmt("a ,b") == "a, b"
        @test fmt("(a,b)") == "(a, b)"
        @test fmt("(a ,b)") == "(a, b)"
        @test fmt("( a, b)") == "(a, b)"
        @test fmt("(a, b )") == "(a, b)"
        @test fmt("(a, b ,)") == "(a, b,)"
        @test fmt("""(a,    b ,
                            c)""") == "(a, b, c)"
    end

    @testset "curly" begin
        @test fmt("X{a,b}") == "X{a,b}"
        @test fmt("X{ a,b}") == "X{a,b}"
        @test fmt("X{a ,b}") == "X{a,b}"
        @test fmt("X{a, b}") == "X{a,b}"
        @test fmt("X{a,b }") == "X{a,b}"
        @test fmt("X{a,b }") == "X{a,b}"

        str = """
        mutable struct Foo{A<:Bar,Union{B<:Fizz,C<:Buzz},<:Any}
            a::A
        end"""
        @test fmt(str) == str

        str = """
        struct Foo{A<:Bar,Union{B<:Fizz,C<:Buzz},<:Any}
            a::A
        end"""
        @test fmt(str) == str
    end

    @testset "where op" begin
        str = "Atomic{T}(value) where {T<:AtomicTypes} = new(value)"
        @test fmt(str) == str

        str = "Atomic{T}(value) where T <: AtomicTypes = new(value)"
        @test fmt(str) == str
    end

    @testset "unary ops" begin
        @test fmt("! x") == "!x"
        @test fmt("x ...") == "x..."
    end

    @testset "binary ops" begin
        @test fmt("a+b*c") == "a + b * c"
        @test fmt("a +b*c") == "a + b * c"
        @test fmt("a+ b*c") == "a + b * c"
        @test fmt("a+b *c") == "a + b * c"
        @test fmt("a+b* c") == "a + b * c"
        @test fmt("a+b*c ") == "a + b * c"
        @test fmt("a:b") == "a:b"
        @test fmt("a : b") == "a:b"
        @test fmt("a: b") == "a:b"
        @test fmt("a :b") == "a:b"
        @test fmt("a +1 :b -1") == "a+1:b-1"
        @test fmt("a:b:c") == "a:b:c"
        @test fmt("a :b:c") == "a:b:c"
        @test fmt("a: b:c") == "a:b:c"
        @test fmt("a:b :c") == "a:b:c"
        @test fmt("a:b: c") == "a:b:c"
        @test fmt("a:b:c ") == "a:b:c"
        @test fmt("a::b:: c") == "a::b::c"
        @test fmt("a :: b::c") == "a::b::c"
        @test fmt("2n") == "2n"

        str = "!(typ <: ArithmeticTypes)"
        @test fmt(str) == str
    end

    @testset "op chain" begin
        @test fmt("a+b+c+d") == "a + b + c + d"
    end

    @testset "comparison chain" begin
        @test fmt("a<b==c≥d") == "a < b == c ≥ d"
    end

    @testset "single line block" begin
        @test fmt("(a;b;c)") == "(a; b; c)"
    end

    @testset "func call" begin
        @test fmt("func(a, b, c)") == "func(a, b, c)"
        @test fmt("func(a,b,c)") == "func(a, b, c)"
        @test fmt("func(a,b,c,)") == "func(a, b, c,)"
        @test fmt("func(a,b,c, )") == "func(a, b, c,)"
        @test fmt("func( a,b,c    )") == "func(a, b, c)"
        @test fmt("func(a, b, c) ") == "func(a, b, c)"
        @test fmt("func(a, b; c)") == "func(a, b; c)"
        @test fmt("func(  a, b; c)") == "func(a, b; c)"
        @test fmt("func(a  ,b; c)") == "func(a, b; c)"
        @test fmt("func(a=1,b; c=1)") == "func(a = 1, b; c = 1)"
    end

    @testset "begin" begin
        str = """
        begin
            arg
        end"""
        @test fmt("""
                    begin
                    arg
                    end""") == str
        @test fmt("""
                    begin
                        arg
                    end""") == str
        @test fmt("""
                    begin
                        arg
                    end""") == str
        @test fmt("""
                    begin
                            arg
                    end""") == str
        str = """
        begin
            begin
                arg
            end
        end"""
        @test fmt("""
                    begin
                    begin
                    arg
                    end
                    end""") == str
        @test fmt("""
                    begin
                                begin
                    arg
                    end
                    end""") == str
        @test fmt("""
                    begin
                                begin
                    arg
                            end
                    end""") == str
    end

    @testset "quote" begin
        str = """
        quote
            arg
        end"""
        @test fmt("""
        quote
            arg
        end""") == str
        @test fmt("""
        quote
        arg
        end""") == str
        @test fmt("""
        quote
                arg
            end""") == str

        str = """:(a = 10; b = 20; c = a * b)"""
        @test fmt(":(a = 10; b = 20; c = a * b)") == str

        str = """
        :(endidx = ndigits;
        while endidx > 1 && digits[endidx] == UInt8('0')
            endidx -= 1
        end;
        if endidx > 1
            print(out, '.')
            unsafe_write(out, pointer(digits) + 1, endidx - 1)
        end)"""

        str_ = """
    :(endidx = ndigits;
                while endidx > 1 && digits[endidx] == UInt8('0')
                    endidx -= 1
                end;
                if endidx > 1
                    print(out, '.')
                    unsafe_write(out, pointer(digits) + 1, endidx - 1)
                end)"""
        @test fmt(str_) == str
        @test fmt(str) == str
    end

    @testset "do" begin
        str = """
        map(args) do x
            y = 20
            return x * y
        end"""

        @test fmt("""
        map(args) do x
          y = 20
                            return x * y
            end""") == str
    end

    @testset "for" begin
        str = """
        for iter in I
            arg
        end"""
        @test fmt("""
        for iter in I
            arg
        end""") == str
        @test fmt("""
        for iter in I
        arg
        end""") == str
        @test fmt("""
        for iter in I
          arg
        end""") == str

        str = """
        for iter in I, iter2 in I2
            arg
        end"""
        @test fmt("""
        for iter in I, iter2 in I2
            arg
        end""") == str
        @test fmt("""
        for iter in I, iter2 in I2
        arg
        end""") == str
        @test fmt("""
        for iter in I, iter2 in I2
                arg
            end""") == str
    end

    @testset "while" begin
        str = """
        while cond
            arg
        end"""
        @test fmt("""
        while cond
            arg
        end""") == str
        @test fmt("""
        while cond
        arg
        end""") == str
        @test fmt("""
        while cond
                arg
            end""") == str
    end

    @testset "let" begin
        str = """
        let x = X
            arg
        end"""
        @test fmt("""
        let x=X
            arg
        end""") == str
        @test fmt("""
        let x=X
        arg
        end""") == str
        @test fmt("""
        let x=X
            arg
        end""") == str

        str = """
        let x = X, y = Y
            arg
        end"""
        @test fmt("""
        let x = X, y = Y
            arg
        end""") == str
        @test fmt("""
        let x = X, y = Y
        arg
        end""") == str

        str = """
        y, back = let
            body
        end"""
        @test fmt("""
        y,back = let
          body
        end""") == str

        # TODO: This should probably be aligned to match up with `a` ?
        str = """
        let x = a,
            # comment
        b,
        c
            body
        end"""
        @test fmt("""
        let x = a,
            # comment
               b,
              c
           body
           end""") == str
    end

    @testset "structs" begin
        str = """
        struct name
            arg
        end"""
        @test fmt("""
        struct name
            arg
        end""") == str
        @test fmt("""
        struct name
        arg
        end""") == str
        @test fmt("""
        struct name
                arg
            end""") == str


        str = """
        mutable struct name
            arg
        end"""
        @test fmt("""
        mutable struct name
            arg
        end""") == str
        @test fmt("""
        mutable struct name
        arg
        end""") == str
        @test fmt("""
        mutable struct name
                arg
            end""") == str
    end

    @testset "try" begin
        str = """
        try
            arg
        catch
            arg
        end"""
        @test fmt("""
        try
            arg
        catch
            arg
        end""") == str

        @test fmt("""
        try
        arg
        catch
        arg
        end""") == str

        @test fmt("""
        try
                arg
            catch
                arg
            end""") == str

        str = """
        try
            arg
        catch
            arg
        end"""
        @test fmt("""
        try
            arg
        catch
            arg
        end""") == str

        @test fmt("""
        try
        arg
        catch
        arg
        end""") == str

        @test fmt("""
        try
                arg
            catch
                arg
            end""") == str

        str = """
        try
            arg
        catch err
            arg
        end"""

        @test fmt("""
        try
            arg
        catch err
            arg
        end""") == str

        @test fmt("""
        try
        arg
        catch err
        arg
        end""") == str

        @test fmt("""
        try
                arg
            catch err
                arg
            end""") == str
    end

    @testset "docs" begin
        str = """
        \"""
        doc
        \"""
        function f()
            20
        end"""

        @test fmt("""
        \"""doc
        \"""
        function f()
            20
        end""") == str

        @test fmt("""
        \"""
        doc\"""
        function f()
            20
        end""") == str

        @test fmt("""
        \"""doc\"""
        function f()
            20
        end""") == str

        @test fmt("""
        "doc
        "
        function f()
            20
        end""") == str

        @test fmt("""
        "
        doc"
        function f()
            20
        end""") == str

        @test fmt("""
        "doc"
        function f()
            20
        end""") == str

        # test aligning to function identation
        @test fmt("""
            "doc"
        function f()
            20
        end""") == str

        str = """\"""
                 doc for Foo
                 \"""
                 Foo"""
        @test fmt("\"\"\"doc for Foo\"\"\"\nFoo") == str

        str = """
        \"""
        doc
        \"""
        function f()    #  comment
            20
        end"""
        @test fmt(str) == str
    end

    @testset "strings" begin
        str = """
        \"""
        Interpolate using `\\\$`
        \"""
        a"""
        @test fmt(str) == str

        str = """error("foo\\n\\nbar")"""
        @test fmt(str) == str

        # nesting

        str = """
        \"""
        \\\\
        \"""
        x"""
        @test fmt("\"\\\\\" x") == str

        str = """
        begin
            s = \"\"\"This is a multiline string.
                    This is another line.
                          Look another 1 that is indented a bit.

                          cool!\"\"\"
        end"""
        str_ = """
        begin
        s = \"\"\"This is a multiline string.
                This is another line.
                      Look another 1 that is indented a bit.

                      cool!\"\"\"
        end"""
        @test fmt(str_) == str


        str = """
        begin
            begin
                throw(ErrorException(\"""An error occured formatting \$filename. :-(

                                     Please file an issue at https://github.com/domluna/JuliaFormatter.jl/issues
                                     with a link to a gist containing the contents of the file. A gist
                                     can be created at https://gist.github.com/.\"""))
            end
        end"""
        str_ = """
        begin
        begin
           throw(ErrorException(\"""An error occured formatting \$filename. :-(

                                Please file an issue at https://github.com/domluna/JuliaFormatter.jl/issues
                                with a link to a gist containing the contents of the file. A gist
                                can be created at https://gist.github.com/.\"""))
           end
        end"""
        @test fmt(str_) == str


        str = """
        foo() = llvmcall(\"""
                         llvm1
                         llvm2
                         \""")"""
        @test fmt(str) == str

        str_ = """
        foo() =
          llvmcall(\"""
                   llvm1
                   llvm2
                   \""")"""
        @test fmt(str, 2, 10) == str_

        str = """
        str = \"""
        begin
            arg
        end\"""
        """
        @test fmt(str) == str

        str = """
        str = \"""
              begin
                  arg
              end\"""
        """
        @test fmt(str) == str
    end

    @testset "notcode" begin
        str = """
        module Foo
        # comment 0
        # comment 1
        begin

            # comment 2
            # comment 3

            begin



                # comment 4
                # comment 5
                a = 10
            end

        end

        end"""
        @test fmt(str) == str

        str_ = """
        module Foo
        # comment 0
        # comment 1
        begin

        # comment 2
        # comment 3

        begin



        # comment 4
        # comment 5
        a = 10
        end

        end

        end"""
        str = """
        module Foo
        # comment 0
        # comment 1
        begin

        # comment 2
        # comment 3

            begin



        # comment 4
        # comment 5
                a = 10
            end

        end

        end"""

        @test fmt(str_) == str

        str = "# comment 0\n\n\n\n\na = 1\n\n# comment 1\n\n\n\n\nb = 2\n\n\nc = 3\n\n# comment 2\n\n"
        @test fmt(str) == str

        str = """
        #=
        hello
        world
        =#
        const a = \"hi there\""""
        @test fmt(str) == str

        str = """
        if a
            # comment above var
            var = 10
            # comment below var
        else
            something_else()
        end"""
        @test fmt(str) == str

        str = """
        begin
            a = 10 # foo
            b = 20           # foo
        end    # trailing comment"""
        str_ = """
        begin
        a = 10 # foo
        b = 20           # foo
        end    # trailing comment"""
        @test fmt(str_) == str
    end

    @testset "pretty" begin
        str = """function foo end"""
        @test fmt("""
            function  foo
            end""") == str

        str = """function foo() end"""
        @test fmt("""
                     function  foo()
            end""") == str

        str = """function foo()
                     10
                     20
                 end"""
        @test fmt("""function foo() 10;  20 end""") == str

        str = """abstract type AbstractFoo end"""
        @test fmt("""abstract type
                     AbstractFoo
                end""") == str

        str = """for i = 1:10
                     1
                     2
                     3
                 end"""
        @test fmt("""for i=1:10 1; 2; 3 end""") == str

        str = """while true
                     1
                     2
                     3
                 end"""
        @test fmt("""while true 1; 2; 3 end""") == str

        str = """try
                     a
                 catch e
                     b
                 end"""
        @test fmt("""try a catch e b end""") == str

        str = """try
                     a1
                     a2
                 catch e
                     b1
                     b2
                 finally
                     c1
                     c2
                 end"""
        @test fmt("""try a1;a2 catch e b1;b2 finally c1;c2 end""") == str

        str = """map(a) do b, c
                     e
                 end"""
        @test fmt("""map(a) do b,c
                     e end""") == str

        str = """let a = b, c = d
                     e1
                     e2
                     e3
                 end"""
        @test fmt("""let a=b,c=d\ne1; e2; e3 end""") == str

        str = """let a, b
                     e
                 end"""
        @test fmt("""let a,b
                     e end""") == str

        str = """return a, b, c"""
        @test fmt("""return a,b,
                     c""") == str

        str = """begin
                     a
                     b
                     c
                 end"""
        @test fmt("""begin a; b; c end""") == str

        str = """begin end"""
        @test fmt("""begin \n            end""") == str

        str = """quote
                     a
                     b
                     c
                 end"""
        @test fmt("""quote a; b; c end""") == str

        str = """quote end"""
        @test fmt("""quote \n end""") == str

        str = """if cond1
                     e1
                     e2
                 end"""
        @test fmt("if cond1 e1;e2 end") == str

        str = """if cond1
                     e1
                     e2
                 else
                     e3
                     e4
                 end"""
        @test fmt("if cond1 e1;e2 else e3;e4 end") == str

        str = """begin
                     if cond1
                         e1
                         e2
                     elseif cond2
                         e3
                         e4
                     elseif cond3
                         e5
                         e6
                     else
                         e7
                         e8
                     end
                 end"""
        @test fmt("begin if cond1 e1; e2 elseif cond2 e3; e4 elseif cond3 e5;e6 else e7;e8  end end") == str

        str = """if cond1
                     e1
                     e2
                 elseif cond2
                     e3
                     e4
                 end"""
        @test fmt("if cond1 e1;e2 elseif cond2 e3; e4 end") == str

        str = """
        [a b c]"""
        @test fmt("[a   b         c   ]") == str

        str = """
        [a; b; c]"""
        @test fmt("[a;   b;         c;   ]") == str

        str = """
        T[a b c]"""
        @test fmt("T[a   b         c   ]") == str

        str = """
        T[a; b; c]"""
        @test fmt("T[a;   b;         c;   ]") == str

        str = """
        T[a; b; c; e d f]"""
        @test fmt("T[a;   b;         c;   e  d    f   ]") == str

        str = """T[e for e in x]"""
        @test fmt("T[e  for e in x  ]") == str

        str = """struct Foo end"""
        @test fmt("struct Foo\n      end") == str

        str = """
        struct Foo
            body
        end"""
        @test fmt("struct Foo\n    body  end") == str

        str = """macro foo() end"""
        @test fmt("macro foo()\n      end") == str

        str = """macro foo end"""
        @test fmt("macro foo\n      end") == str

        str = """
        macro foo()
            body
        end"""
        @test fmt("macro foo()\n    body  end") == str

        str = """mutable struct Foo end"""
        @test fmt("mutable struct Foo\n      end") == str

        str = """
        mutable struct Foo
            body
        end"""
        @test fmt("mutable struct Foo\n    body  end") == str

        str = """
        module Foo
        body
        end"""
        @test fmt("module Foo\n    body  end") == str

        str = """
        module Foo end"""
        @test fmt("module Foo\n    end") == str

        str = """
        if cond1
        elseif cond2
        elseif cond3
        elseif cond4
        elseif cond5
        elseif cond6
        elseif cond7
        else
        end"""
        @test fmt(str) == str

        str = """
        try
        catch
        finally
        end"""
        @test fmt(str) == str

        str = """
        (args...; kwargs) -> begin
            body
        end"""
        @test fmt(str) == str

        @test fmt("ref[a: (b + c)]") == "ref[a:(b+c)]"
    end

    @testset "nesting" begin
        str = """
        function f(
            arg1::A,
            key1 = val1;
            key2 = val2
        ) where {
            A,
            F{
              B,
              C
            }
        }
            10
            20
        end"""
        @test fmt(
            "function f(arg1::A,key1=val1;key2=val2) where {A,F{B,C}} 10; 20 end",
            4,
            1
        ) == str

        str = """
        function f(
            arg1::A,
            key1 = val1;
            key2 = val2
        ) where {
            A,
            F{B,C}
        }
            10
            20
        end"""
        @test fmt(
            "function f(arg1::A,key1=val1;key2=val2) where {A,F{B,C}} 10; 20 end",
            4,
            17
        ) == str

        str = """
        function f(
            arg1::A,
            key1 = val1;
            key2 = val2
        ) where {A,F{B,C}}
            10
            20
        end"""
        @test fmt(
            "function f(arg1::A,key1=val1;key2=val2) where {A,F{B,C}} 10; 20 end",
            4,
            18
        ) == str

        str = """
        a |
        b |
        c |
        d"""
        @test fmt("a | b | c | d", 4, 1) == str


        str = """
        a, b, c, d"""
        @test fmt("a, b, c, d", 4, 10) == str

        str = """a,\nb,\nc,\nd"""
        @test fmt("a, b, c, d", 4, 9) == str

        str = """(a, b, c, d)"""
        @test fmt("(a, b, c, d)", 4, 12) == str

        str = """
        (
         a,
         b,
         c,
         d
        )"""
        @test fmt("(a, b, c, d)", 4, 11) == str

        str = """{a, b, c, d}"""
        @test fmt("{a, b, c, d}", 4, 12) == str

        str = """
        {
         a,
         b,
         c,
         d
        }"""
        @test fmt("{a, b, c, d}", 4, 11) == str

        str = """[a, b, c, d]"""
        @test fmt("[a, b, c, d]", 4, 12) == str

        str = """
        [
         a,
         b,
         c,
         d
        ]"""
        @test fmt("[a, b, c, d]", 4, 11) == str

        str = """
        cond ?
        e1 :
        e2"""
        @test fmt("cond ? e1 : e2", 4, 1) == str

        str = """
        cond ? e1 :
        e2"""
        @test fmt("cond ? e1 : e2", 4, 12) == str

        str = """
        cond1 ? e1 :
        cond2 ? e2 :
        cond3 ? e3 :
        e4"""
        @test fmt("cond1 ? e1 : cond2 ? e2 : cond3 ? e3 : e4", 4, 13) == str

        str = """
        export a,
               b"""
        @test fmt("export a,b", 4, 1) == str

        str = """
        using a,
              b"""
        @test fmt("using a,b", 4, 1) == str

        str = """
        using M: a,
                 b"""
        @test fmt("using M:a,b", 4, 1) == str

        str = """
        import M1.M2.M3: a,
                         b"""
        @test fmt("import M1.M2.M3:a,b", 4, 1) == str

        str = """
        foo() =
            (one, x -> (true, false))"""
        @test fmt("foo() = (one, x -> (true, false))", 4, 30) == str

        str = """
        foo() =
            (
             one,
             x -> (
                 true,
                 false
             )
            )"""
        @test fmt("foo() = (one, x -> (true, false))", 4, 20) == str

        str = """
        @somemacro function (fcall_ |
                             fcall_)
            body_
        end"""
        @test fmt("@somemacro function (fcall_ | fcall_) body_ end", 4, 1) == str

        str = "Val(x) = (@_pure_meta; Val{x}())"
        @test fmt("Val(x) = (@_pure_meta ; Val{x}())", 4, 80) == str

        str = "(a; b; c)"
        @test fmt("(a;b;c)", 4, 100) == str
        @test fmt("(a;b;c)", 4, 1) == str

        str = "(x for x in 1:10)"
        @test fmt("(x   for x  in  1 : 10)", 4, 100) == str
        @test fmt("(x   for x  in  1 : 10)", 4, 1) == str

        # indent for TupleH with no parens
        str = """
        function foo()
            arg1,
            arg2
        end"""
        @test fmt("function foo() arg1, arg2 end", 4, 1) == str

        str = """
        function foo()
            # comment
            arg
        end"""
        @test fmt(str, 4, 1) == str

        # don't nest < 2 args

        str = "A where {B}"
        @test fmt(str, 4, 1) == str

        str = "foo(arg1)"
        @test fmt(str, 4, 1) == str

        str = "[arg1]"
        @test fmt(str, 4, 1) == str

        str = "{arg1}"
        @test fmt(str, 4, 1) == str

        str = "(arg1)"
        @test fmt(str, 4, 1) == str

        str_ = """
        begin
        if foo
        elseif baz
        elseif (a || b) && c
        elseif bar
        else
        end
        end"""

        str = """
        begin
            if foo
            elseif baz
            elseif (a ||
                    b) && c
            elseif bar
            else
            end
        end"""
        @test fmt(str_, 4, 21) == str
        @test fmt(str_, 4, 19) == str

        str = """
        begin
            if foo
            elseif baz
            elseif (a ||
                    b) &&
                   c
            elseif bar
            else
            end
        end"""
        @test fmt(str_, 4, 18) == str

        str = """
        begin
            if foo
            elseif baz
            elseif (a || b) &&
                   c
            elseif bar
            else
            end
        end"""
        @test fmt(str_, 4, 23) == str
        @test fmt(str_, 4, 22) == str

        str = """
        begin
            if foo
            elseif baz
            elseif (a || b) && c
            elseif bar
            else
            end
        end"""
        @test fmt(str_, 4, 24) == str

        # https://github.com/domluna/JuliaFormatter.jl/issues/9#issuecomment-481607068
        str = """
        this_is_a_long_variable_name = Dict{Symbol,Any}(
            :numberofpointattributes => NAttributes,
            :numberofpointmtrs => NMTr,
            :numberofcorners => NSimplex,
            :firstnumber => Cint(1),
            :mesh_dim => Cint(3),
        )"""

        str_ = """this_is_a_long_variable_name = Dict{Symbol,Any}(:numberofpointattributes => NAttributes, 
               :numberofpointmtrs => NMTr, :numberofcorners => NSimplex, :firstnumber => Cint(1), 
               :mesh_dim => Cint(3),)"""
        @test fmt(str_, 4, 80) == str

        str = """this_is_a_long_variable_name = Dict{
             Symbol,
             Any
        }(
             :numberofpointattributes => NAttributes,
             :numberofpointmtrs => NMTr,
             :numberofcorners => NSimplex,
             :firstnumber => Cint(1),
             :mesh_dim => Cint(3),
        )"""
        @test fmt(str_, 5, 1) == str

        str = """
        this_is_a_long_variable_name = (
            :numberofpointattributes => NAttributes,
            :numberofpointmtrs => NMTr,
            :numberofcorners => NSimplex,
            :firstnumber => Cint(1),
            :mesh_dim => Cint(3),
        )"""

        str_ = """this_is_a_long_variable_name = (:numberofpointattributes => NAttributes, 
               :numberofpointmtrs => NMTr, :numberofcorners => NSimplex, :firstnumber => Cint(1), 
               :mesh_dim => Cint(3),)"""
        @test fmt(str_, 4, 80) == str

        str = """
        begin
            a && b
            a || b
        end"""
        @test fmt(str, 4, 1) == str

        str = """
        begin
            a &&
            b ||
            c &&
            d
        end"""
        @test fmt("begin\n a && b || c && d\nend", 4, 1) == str

        str = """
        func(a, \"""this
                is another
                multi-line
                string.
                Longest line
                \""", foo(b, c))"""
        @test fmt(str, 4, 100) == str

        str_ = """
        func(
            a,
            \"""this
            is another
            multi-line
            string.
            Longest line
            \""",
            foo(
                b,
                c
            )
        )"""
        @test fmt(str, 4, 1) == str_

        str = """
        func(
            a,
            \"""this
            is another
            multi-line
            string.
            Longest line
            \""",
            foo(b, c)
        )"""
        @test fmt(str, 4, 31) == str


        # Ref
        str = "a[1+2]"
        @test fmt("a[1 + 2]", 4, 1) == str

        str = "a[(1+2)]"
        @test fmt("a[(1 + 2)]", 4, 1) == str

        str_ = "(a + b + c + d)"
        @test fmt(str_, 4, 15) == str_

        str = "(a + b + c +\n d)"
        @test fmt(str_, 4, 14) == str
        @test fmt(str_, 4, 12) == str

        str = "(a + b +\n c + d)"
        @test fmt(str_, 4, 11) == str
        @test fmt(str_, 4, 8) == str

        str = "(a +\n b +\n c + d)"
        @test fmt(str_, 4, 7) == str

        str = "(a +\n b +\n c +\n d)"
        @test fmt(str_, 4, 1) == str

        str_ = "(a <= b <= c <= d)"
        @test fmt(str_, 4, 18) == str_

        str = "(a <= b <= c <=\n d)"
        @test fmt(str_, 4, 17) == str
        @test fmt(str_, 4, 15) == str

        str = "(a <= b <=\n c <= d)"
        @test fmt(str_, 4, 14) == str
        @test fmt(str_, 4, 10) == str

        str = "(a <=\n b <=\n c <= d)"
        @test fmt(str_, 4, 9) == str
        @test fmt(str_, 4, 8) == str

        str = "(a <=\n b <=\n c <=\n d)"
        @test fmt(str_, 4, 7) == str
        @test fmt(str_, 4, 1) == str
    end

    @testset "nesting line offset" begin
        str = "a - b + c * d"
        s = run_nest(str, 100)
        @test s.line_offset == length(str)
        s = run_nest(str, length(str) - 1)
        @test s.line_offset == 5
        s = run_nest(str, 1)
        @test s.line_offset == 1

        str = "c ? e1 : e2"
        s = run_nest(str, 100)
        @test s.line_offset == length(str)
        s = run_nest(str, length(str) - 1)
        @test s.line_offset == 2
        s = run_nest(str, 8)
        @test s.line_offset == 2
        s = run_nest(str, 1)
        @test s.line_offset == 2

        str = "c1 ? e1 : c2 ? e2 : c3 ? e3 : c4 ? e4 : e5"
        s = run_nest(str, 100)
        @test s.line_offset == length(str)
        s = run_nest(str, length(str) - 1)
        @test s.line_offset == 32
        s = run_nest(str, 30)
        @test s.line_offset == 22
        s = run_nest(str, 20)
        @test s.line_offset == 12
        s = run_nest(str, 10)
        @test s.line_offset == 2
        s = run_nest(str, 1)
        @test s.line_offset == 2

        str = "f(a, b, c) where {A,B,C}"
        s = run_nest(str, 100)
        @test s.line_offset == length(str)
        s = run_nest(str, length(str) - 1)
        @test s.line_offset == 15
        s = run_nest(str, 14)
        @test s.line_offset == 1
        s = run_nest(str, 1)
        @test s.line_offset == 1

        str = "f(a, b, c) where Union{A,B,C}"
        s = run_nest(str, 100)
        @test s.line_offset == length(str)
        s = run_nest(str, length(str) - 1)
        @test s.line_offset == 20
        s = run_nest(str, 19)
        @test s.line_offset == 1
        s = run_nest(str, 1)
        @test s.line_offset == 1

        str = "f(a, b, c) where A"
        s = run_nest(str, 100)
        @test s.line_offset == length(str)
        s = run_nest(str, 1)
        @test s.line_offset == 9

        str = "f(a, b, c) where A <: S"
        s = run_nest(str, 100)
        @test s.line_offset == length(str)
        s = run_nest(str, 1)
        @test s.line_offset == 14

        str = "f(a, b, c) where Union{A,B,Union{C,D,E}}"
        s = run_nest(str, 100)
        @test s.line_offset == length(str)
        s = run_nest(str, length(str) - 1)
        @test s.line_offset == 31
        s = run_nest(str, 30)
        @test s.line_offset == 1
        s = run_nest(str, 1)
        @test s.line_offset == 1

        str = "f(a, b, c) where {A,{B, C, D},E}"
        s = run_nest(str, 100)
        @test s.line_offset == length(str)
        s = run_nest(str, 1)
        @test s.line_offset == 1

        str = "(a, b, c, d)"
        s = run_nest(str, 100)
        @test s.line_offset == length(str)
        s = run_nest(str, length(str) - 1)
        @test s.line_offset == 1

        str = "a, b, c, d"
        s = run_nest(str, 100)
        @test s.line_offset == length(str)
        s = run_nest(str, length(str) - 1)
        @test s.line_offset == 0

        str = """
        splitvar(arg) =
            @match arg begin
                ::T_ => (nothing, T)
                name_::T_ => (name, T)
                x_ => (x, :Any)
            end"""
        s = run_nest(str, 96)
        @test s.line_offset == 3
        s = run_nest(str, 1)
        @test s.line_offset == 7

        str = "prettify(ex; lines = false) = ex |> (lines ? identity : striplines) |> flatten |> unresolve |> resyntax |> alias_gensyms"
        s = run_nest(str, 80)
        @test s.line_offset == 17

        str = "foo() = a + b"
        s = run_nest(str, length(str))
        @test s.line_offset == length(str)
        s = run_nest(str, length(str) - 1)
        @test s.line_offset == 9
        s = run_nest(str, 1)
        @test s.line_offset == 5

        str_ = """
        @Expr(:scope_block, begin
                    body1
                    @Expr :break loop_cont
                    body2
                    @Expr :break loop_exit2
                    body3
                end)"""

        str = """
        @Expr(:scope_block, begin
            body1
            @Expr :break loop_cont
            body2
            @Expr :break loop_exit2
            body3
        end)"""
        @test fmt(str_, 4, 100) == str

        str = """
        @Expr(
            :scope_block,
            begin
                body1
                @Expr :break loop_cont
                body2
                @Expr :break loop_exit2
                body3
            end
        )"""
        @test fmt(str_, 4, 50) == str


        str = "export @esc, isexpr, isline, iscall, rmlines, unblock, block, inexpr, namify, isdef"
        s = run_nest(str, length(str))
        @test s.line_offset == length(str)
        s = run_nest(str, length(str) - 1)
        @test s.line_offset == 12

        # https://github.com/domluna/JuliaFormatter.jl/issues/9#issuecomment-481607068
        str = """this_is_a_long_variable_name = Dict{Symbol,Any}(:numberofpointattributes => NAttributes, 
               :numberofpointmtrs => NMTr, :numberofcorners => NSimplex, :firstnumber => Cint(1), 
               :mesh_dim => Cint(3),)"""
        s = run_nest(str, 80)
        @test s.line_offset == 1

        str = """this_is_a_long_variable_name = (:numberofpointattributes => NAttributes, 
               :numberofpointmtrs => NMTr, :numberofcorners => NSimplex, :firstnumber => Cint(1), 
               :mesh_dim => Cint(3),)"""
        s = run_nest(str, 80)
        @test s.line_offset == 1
    end

    @testset "additional length" begin
        str = """
        f(
          a,
          @g(b, c),
          d
        )"""
        @test fmt("f(a, @g(b, c), d)", 4, 11) == str

        str = """
        f(
          a,
          @g(
             b,
             c
          ),
          d
        )"""
        @test fmt("f(a, @g(b, c), d)", 4, 10) == str

        str = """
        (
         a,
         (
          b,
          c
         ),
         d
        )"""
        @test fmt("(a, (b, c), d)", 4, 7) == str

        str = """
        (
         a,
         {
          b,
          c
         },
         d
        )"""
        @test fmt("(a, {b, c}, d)", 4, 6) == str

        str = """
        a,
        (
         b,
         c
        ),
        d"""
        @test fmt("a, (b, c), d", 4, 6) == str

        str = """
        a,
        (b, c),
        d"""
        @test fmt("a, (b, c), d", 4, 7) == str

        str = """
        (
         var1,
         var2
        ) && var3"""
        @test fmt("(var1,var2) && var3", 4, 10) == str

        str = """
        (
         var1,
         var2
        ) && var3"""
        @test fmt("(var1,var2) && var3", 4, 19) == str

        str = """
        (var1, var2) ?
        (var3, var4) :
        var5"""
        @test fmt("(var1,var2) ? (var3,var4) : var5", 4, 14) == str

        str = """
        (
         var1,
         var2
        ) ?
        (
         var3,
         var4
        ) :
        var5"""
        @test fmt("(var1,var2) ? (var3,var4) : var5", 4, 13) == str

        str = """
        (var1, var2) ? (var3, var4) :
        var5"""
        @test fmt("(var1,var2) ? (var3,var4) : var5", 4, 29) == str

        str = """
        (var1, var2) ?
        (var3, var4) : var5"""
        @test fmt("(var1,var2) ? (var3,var4) : var5", 4, 28) == str

        str = """
        f(
          var1::A,
          var2::B
        ) where {A,B}"""
        @test fmt("f(var1::A, var2::B) where {A,B}", 4, 30) == str

        str = """
        f(
          var1::A,
          var2::B
        ) where {
            A,
            B
        }"""
        @test fmt("f(var1::A, var2::B) where {A,B}", 4, 12) == str

        str = "foo(a, b, c)::Rtype where {A,B} = 10"
        @test fmt(str, 4, length(str)) == str

        str_ = """
        foo(a, b, c)::Rtype where {A,B} =
            10"""
        @test fmt(str, 4, 35) == str_
        @test fmt(str, 4, 33) == str_

        str_ = """
        foo(a, b, c)::Rtype where {
            A,
            B
        } = 10"""
        @test fmt(str, 4, 32) == str_
        @test fmt(str, 4, 19) == str_

        str_ = """
        foo(
            a,
            b,
            c
        )::Rtype where {
            A,
            B
        } = 10"""
        @test fmt(str, 4, 18) == str_

        str = "keytype(::Type{<:AbstractDict{K,V}}) where {K,V} = K"
        @test fmt(str, 4, 52) == str

        str_ = "transcode(::Type{THISISONESUPERLONGTYPE1234567}) where {T<:Union{Int32,UInt32}} = transcode(T, String(Vector(src)))"
        str = """
        transcode(::Type{THISISONESUPERLONGTYPE1234567}) where {T<:Union{
          Int32,
          UInt32
        }} = transcode(T, String(Vector(src)))"""
        @test fmt(str_, 2, 80) == str
        @test fmt(str_, 2, 38) == str

        str = """
        transcode(::Type{THISISONESUPERLONGTYPE1234567}) where {T<:Union{
          Int32,
          UInt32
        }} =
          transcode(T, String(Vector(src)))"""
        @test fmt(str_, 2, 37) == str

        str_ = "transcode(::Type{T}, src::AbstractVector{UInt8}) where {T<:Union{Int32,UInt32}} = transcode(T, String(Vector(src)))"
        str = """
        transcode(
          ::Type{T},
          src::AbstractVector{UInt8}
        ) where {T<:Union{Int32,UInt32}} = transcode(T, String(Vector(src)))"""
        @test fmt(str_, 2, 80) == str
        @test fmt(str_, 2, 68) == str

        str = """
        transcode(
          ::Type{T},
          src::AbstractVector{UInt8}
        ) where {T<:Union{Int32,UInt32}} =
          transcode(T, String(Vector(src)))"""
        @test fmt(str_, 2, 67) == str
    end

# @testset "meta-format" begin
#     str = String(read("./runtests.jl"))
#     str = fmt(str)
#
# end

end

