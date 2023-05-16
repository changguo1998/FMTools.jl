export @must, @hadbetter, @balancedthreads

"""
```
@must cond [text]
```

throw error with `text` when `cond` is false
"""
macro must(cond, text="")
    if isempty(text)
        text = "Condition not satisfied: "*string(cond)
    end
    return :(
        if !($(esc(cond)))
            error($(esc(text)))
        end
    )
end

"""
```
@hadbetter cond [text]
```

throw warning with `text` when `cond` is false
"""
macro hadbetter(cond, text="")
    return :(
        if !($(esc(cond)))
            @warn($text)
        end
    )
end

#=
"""
```
@debuginfo msg
```

print extra info when `DEBUG`` flag is `true`
"""
macro debuginfo(text)
    global DEBUG
    return quote
        let
            local dbg = DEBUG
            if dbg
                @info($text)
            end
        end
    end
end

function setDEBUG!(flag::Bool)
    global DEBUG = flag
    return nothing
end
=#

# = = = = = = = = = =
# = multithreading
# = = = = = = = = = =

function _threadsfor(iter, lbody)
    lidx = iter.args[1]         # index
    range = iter.args[2]
    quote
        let
        local _range, lenr, _lk, _unarranged, threadsfor_tasklist
        _range = $(esc(range))
        lenr = length(_range)
        _lk = ReentrantLock()
        _unarranged = trues(lenr)
        threadsfor_tasklist = Vector{Task}(undef, lenr)
        for i = eachindex(_range)
            threadsfor_tasklist[i] = @task let
            while true
                i = nothing
                lock(_lk)
                try
                    i = findfirst(_unarranged)
                    if !isnothing(i)
                        _unarranged[i] = false
                    end
                finally
                    unlock(_lk)
                end
                if isnothing(i)
                    break
                end
                local $(esc(lidx)) = @inbounds _range[i]
                $(esc(lbody))
            end
            end
        end
        Threads.@threads for t in threadsfor_tasklist
            schedule(t)
        end
        while true
            i = nothing
            lock(_lk)
            try
                i = findfirst(_t->istaskstarted(_t) && (!istaskdone(_t)), threadsfor_tasklist)
            finally
                unlock(_lk)
            end
            if isnothing(i)
                break
            else
                wait(threadsfor_tasklist[i])
            end
        end
        end
        nothing
    end
end

"""
@balancedthreads for ... end

similar to @threads, but use a inner queue to balance the multithreading calculation
"""
macro balancedthreads(ex)
    if !(isa(ex, Expr) && ex.head === :for)
        throw(ArgumentError("@balancedthreads requires a `for` loop expression"))
    end
    if !(ex.args[1] isa Expr && ex.args[1].head === :(=))
        throw(ArgumentError("nested outer loops are not currently supported by @balancedthreads"))
    end
    return _threadsfor(ex.args[1], ex.args[2])
end