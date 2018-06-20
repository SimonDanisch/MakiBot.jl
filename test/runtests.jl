using OhMyREPL
ENV["JULIA_REVISE"] = "manual"
using Revise

function process_text(text)
    println(text)
    result = nothing
    revise()
    try
        result = eval(Main, :(include_string($text)))
    catch e
        bt = catch_backtrace()
        Base.showerror(STDERR, e)
        Base.show_backtrace(STDERR, bt)
    end
    eval(Main, Expr(:call, display, result))
end

@async begin
    server = listen(2001)
    while true
        sock = accept(server)
        @async while isopen(sock)
            try
                process_text(readstring(sock))
            catch e
                println(e)
            end
        end
    end
end
