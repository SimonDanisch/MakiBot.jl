using PyCall
@pyimport telethon as TelegramClient
Client = TelegramClient.TelegramClient

@pyimport telethon.tl.functions.channels as C
@pyimport telethon.tl.functions.contacts as Co
@pyimport telethon.tl.types as Types


test = "149.154.167.40:443"
production = "149.154.167.50:443"

api_id = 163897
api_hash = "******************************"
phone = "*************"

client = Client(
    "Test", api_id, api_hash, proxy = nothing,
    connection_mode = TelegramClient.ConnectionMode[:TCP_ABRIDGED],
    spawn_read_thread = true,
    update_workers = 0,
    server_address = "149.154.167.40",
    port = 443,
)

client[:connect]()
# client[:disconnect]()


if !client[:is_user_authorized]()
    client[:sign_in](phone = phone)
    me = client[:sign_in](code = 29167)  # Put whatever code you received here.
end

# channel = client[:get_entity]("JuliaPlots")
# x = client(C.JoinChannelRequest(channel))

function process_text(text)
    println("make new module")
    mod = eval(:(module $(gensym("Code")) end))
    result = nothing
    eval(mod, :(using MakiE))
    result = eval(mod, :(include_string($text)))
    println(typeof(result))
    result
end


function process_message(client, msg)
    if msg[:out]
        text = msg[:message]
        if startswith(text, "julia")
            try
                text = replace(text, "julia", "")
                result = process_text(text)
                if isa(result, Scene)
                    mktempdir() do path
                        center!(result)
                        name = joinpath(path, "plot.png")
                        save(name, result)
                        client[:send_file]("JuliaPlots", name)
                    end
                end
            catch e
                println(e)
                client[:send_message]("JuliaPlots", string(e))
            end
        end
    end
end

const isinstance = py"isinstance"


using MakiE
update = client[:updates][:poll]()
msg = update[:message]
msg[:out]
process_message(client, msg)
# isinstance(update, Types.UpdateNewMessage)
runloop = true
@async while runloop
    update = client[:updates][:poll]()
    if isinstance(update, Types.UpdateNewMessage)
        msg = update[:message]
        println(msg[:message])
        process_message(client, msg)
    end
end



client[:send_message]("JuliaPlots", "test")

using MakiE

julia
scene = Scene()
N = 32
function xy_data(x,y,i, N)
    x = ((x/N)-0.5f0)*i
    y = ((y/N)-0.5f0)*i
    r = sqrt(x*x + y*y)
    res = Float32(sin(r)/r)
    isnan(res) ? 1f0 : res
end

surf_func(i) = [Float32(xy_data(x, y, i, 32)) + 0.5 for x=1:32, y=1:32]


name = joinpath(path, "tmp.png")
save(name, scene)

julia
scene = Scene()
N = 32
function xy_data(x,y,i, N)
    x = ((x/N)-0.5f0)*i
    y = ((y/N)-0.5f0)*i
    r = sqrt(x*x + y*y)
    res = Float32(sin(r)/r)
    isnan(res) ? 1f0 : res
end

surf_func(i) = [Float32(xy_data(x, y, i, 32)) + 0.5 for x=1:32, y=1:32]

z = surf_func(20)
r = linspace(-1, 1, 32)
surface(r, r, z)
axis(linspace(-1.1, 1.1, 5), linspace(-1.1, 1.1, 5), linspace(extrema(z)..., 5))
scene

mktempdir() do path
    scene = Scene()
    z = surf_func(20)
    r = linspace(-1, 1, 32)
    surface(r, r, z)
    axis(linspace(-1.1, 1.1, 5), linspace(-1.1, 1.1, 5), linspace(extrema(z)..., 5))
    center!(scene)
    name = joinpath(path, "tmp.png")
    save(name, scene)
    client[:send_file]("******", name)
end
