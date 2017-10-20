module MakiBot

using PyCall, MakiE
@pyimport telepot

include("samples.jl")

function get_user(msg)
    if haskey(msg, "from")
        from = msg["from"]
        haskey(from, "id") && return from["id"]
    else
        if haskey(msg, "chat")
            from = msg["chat"]
            haskey(from, "id") && return from["id"]
        end
    end
    error("No user found")
end

function process_text(text)
    println("make new module")
    mod = eval(:(module $(gensym("Code")) end))
    result = nothing
    eval(mod, :(using MakiE))
    result = eval(mod, :(include_string($text)))
    println(typeof(result))
    result
end

function process_julia(userid, bot, text)
    try
        result = process_text(text)
        if isa(result, Scene)
            mktempdir() do path
                name = joinpath(path, "plot.png")
                save(name, result)
                bot[:sendPhoto](userid, pybuiltin("open")(name, "rb"))
            end
        elseif isa(result, MakiE.VideoStream)
            vid = MakiE.finish(result, "gif")
            bot[:sendVideo](userid, pybuiltin("open")(vid, "rb"))
        end
    catch e
        println(e)
        bot[:sendMessage](userid, string(e))
    end
end

function process_message(bot, msg)
    isa(msg, Bool) && return
    userid = get_user(msg)
    text = msg["text"]
    println(text)
    if startswith(text, "#julia")
        process_julia(userid, bot, text)
    elseif text == "/start"
        for elem in all_samples
            process_julia(userid, bot, elem)
        end
    end
end

function get_message(response)
    haskey(response, "message") && return response["message"]
    haskey(response, "channel_post") && return response["channel_post"]
end


const makibot = Base.RefValue{PyCall.PyObject}()
const runloop = Base.RefValue(true)
const event_loop_task = Base.RefValue{Task}()
const last_id = Base.RefValue{Union{Void, Int}}(nothing)

function run_event_loop(bot = makibot[])
    runloop[] = true
    event_loop_task[] = @async begin
        while runloop[]
            responses = bot[:getUpdates](offset = last_id[])
            if isempty(responses)
                sleep(0.1)
            else
                bot[:sendMessage](userid, "Welcome to MakiBot! You can now write snippets like:")
                for response in responses
                    last_id[] = response["update_id"] + 1
                    msg = get_message(response)
                    process_message(bot, msg)
                end
            end
        end
        println("stopped event loop")
    end
end

function startbot()
    if !haskey(ENV, "MAKIE_BOT_TOKEN")
        error("Please create and export environment variable MAKIE_BOT_TOKEN with a valid telegram bot API token")
    end
    token = ENV["MAKIE_BOT_TOKEN"]
    makibot[] = telepot.Bot(token)
    makibot[]
end

end # module
