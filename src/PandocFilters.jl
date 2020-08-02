# Author: Martin Vuk <martin.vuk@fri.uni-lj.si>
# Copyright: (C) 2016 Martin Vuk
# License: BSD 3-clause


"""
Functions to aid writing python scripts that process the pandoc
AST serialized as JSON.
"""
module PandocFilters

export walk!, toJSONFilter, AST_filter!

using JSON


"""
Function walk! will walk! `Pandoc` document abstract source tree (AST) and apply filter function on each element of the document AST.
Returns a modified tree.

  action must be a function which takes four arguments, `tag, content, format, meta`,
  and should return

  * `nothing` to leave the element unchanged
  * `[]` to delete the element
  * A Pandoc element to replace the element
  * or a list of Pandoc elements which will be spliced into the list the original object belongs to.
"""

function walk!(x :: Any, action :: Function, format, meta)
    return x
end

function walk!(x :: AbstractArray, action :: Function, format, meta)
  array = []
  w!(z) = walk!(z, action, format, meta)
  for item in x
    if (item isa AbstractDict) && haskey(item,"t")
      res = action(item["t"], get(item, "c", nothing), format, meta)
      if res === nothing
        push!(array, w!(item))
      elseif res isa AbstractArray
        for z in res
          push!(array, w!(z))
        end
      else
        push!(array, w!(res))
      end
    else
      push!(array, w!(item))
    end #if
  end #for
  return array
end

function walk!(dict :: AbstractDict, action :: Function, format, meta)
  # Python version (mutating):
  for k in keys(dict)
    dict[k] = walk!(dict[k], action, format, meta)
  end
  return dict
  # Dict(key => walk!(value,action, format, meta) for (key,value) in dict)
end

"""
Converts an action or a list of actions into a filter that reads a JSON-formatted
pandoc document from Base.stdin, transforms it by walk!ing the tree
with the actions, and returns a new JSON-formatted pandoc document
to Base.stdout.  The argument is a list of functions action(key, value, format, meta),
where key is the type of the pandoc object (e.g. "Str", "Para"),
value is the contents of the object (e.g. a string for "Str",
a list of inline elements for "Para"), format is the target
output format (which will be taken for the first command line
argument if present), and meta is the document's metadata.
If the function returns None, the object to which it applies
will remain unchanged.  If it returns an object, the object will
be replaced.    If it returns a list, the list will be spliced in to
the list to which the target object belongs.    (So, returning an
empty list deletes the object.)
"""
function filter(action::Function)
  filter([action])
end

function filter(actions::Array{Function})
  doc = JSON.parse(Base.stdin)
  format = (length(ARGS) <= 0) ? "" : ARGS[1]
  if "meta" in doc
    meta = doc["meta"]
  elseif doc isa AbstractArray  # old API
    meta = doc[1]["test"]
  else
    meta = Dict()
  end

  for action in actions
    doc = walk!(doc, action, format, meta)
  end
  JSON.print(Base.stdout, doc)
end

function AST_filter!(doc, action; format = "")
  AST_filter!(doc, [action]; format = format)
end

function AST_filter!(doc, actions::AbstractVector; format = "")
  if haskey(doc, "meta")
    meta = doc["meta"]
  elseif doc isa AbstractArray  # old API
    meta = doc[1]["test"]
  else
    meta = Dict()
  end

  for action in actions
    walk!(doc, action, format, meta)
  end
end


function elt(eltType, numargs)
    function fun(args...)
        lenargs = length(args)
        if lenargs != numargs
            throw(ArgumentError("$eltType expects $numargs arguments, but given $lenargs"))
        end
        if numargs == 0
            return Dict("t" => eltType)
        elseif numargs == 1
            xs = args[1]
        else
            xs = collect(args)
        end
        return Dict("t" => eltType, "c" => xs)
      end
    return fun
end
# Constructors for block elements


const Plain = elt("Plain", 1)
const Para = elt("Para", 1)
const CodeBlock = elt("CodeBlock", 2)
const RawBlock = elt("RawBlock", 2)
const BlockQuote = elt("BlockQuote", 1)
const OrderedList = elt("OrderedList", 2)
const BulletList = elt("BulletList", 1)
const DefinitionList = elt("DefinitionList", 1)
const Header = elt("Header", 3)
const HorizontalRule = elt("HorizontalRule", 0)
const Table = elt("Table", 5)
const Div = elt("Div", 2)
const Null = elt("Null", 0)

# Constructors for inline elements

const Str = elt("Str", 1)
const Emph = elt("Emph", 1)
const Strong = elt("Strong", 1)
const Strikeout = elt("Strikeout", 1)
const Superscript = elt("Superscript", 1)
const Subscript = elt("Subscript", 1)
const SmallCaps = elt("SmallCaps", 1)
const Quoted = elt("Quoted", 2)
const Cite = elt("Cite", 2)
const Code = elt("Code", 2)
const Space = elt("Space", 0)
const LineBreak = elt("LineBreak", 0)
const Math = elt("Math", 2)
const RawInline = elt("RawInline", 2)
const Link = elt("Link", 3)
const Image = elt("Image", 3)
const Note = elt("Note", 1)
const SoftBreak = elt("SoftBreak", 0)
const Span = elt("Span", 2)

end # module
