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
