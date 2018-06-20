using PyCall, MakiE
@pyimport telepot
@pyimport pprint as Print
token = "**************************"
bot = telepot.Bot(token)
response = bot[:getUpdates]()
# last_id = last(response)["update_id"]
# responses = bot[:getUpdates](offset = last_id + 1)
# msg = first(response)["message"]
# msg = get_message(response[1])
# user =
# bot[:sendMessage](user, "hehe")
# process_message(bot, msg)
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

function process_message(bot, msg)
    isa(msg, Bool) && return
    userid = get_user(msg)
    text = msg["text"]
    println(text)
    if startswith(text, "#julia")
        try
            result = process_text(text)
            if isa(result, Scene)
                mktempdir() do path
                    center!(result)
                    name = joinpath(path, "plot.png")
                    save(name, result)
                    bot[:sendPhoto](userid, pybuiltin("open")(name, "rb"))
                end
            elseif isa(result, MakiE.VideoStream)
                vid = MakiE.finish(result, "mp4")
                bot[:sendVideo](userid, pybuiltin("open")(vid, "rb"))
            end
        catch e
            println(e)
            bot[:sendMessage](userid, string(e))
        end
    end
end

function get_message(response)
    haskey(response, "message") && return response["message"]
    haskey(response, "channel_post") && return response["channel_post"]
end


global runloop = Base.RefValue{Bool}(true)
function poll_updates()
    last_id = nothing
    while runloop[]
        responses = bot[:getUpdates](offset = last_id)
        if isempty(responses)
            sleep(0.1)
        else
            for response in responses
                last_id = response["update_id"] + 1
                msg = get_message(response)
                process_message(bot, msg)
            end
        end
    end
    println("end loop")
end
@async poll_updates()
runloop[] = true
