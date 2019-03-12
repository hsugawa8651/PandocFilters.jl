# Author: Martin Vuk <martin.vuk@fri.uni-lj.si>
# Copyright: (C) 2016 Martin Vuk
# License: BSD 3-clause


"""
Functions to aid writing python scripts that process the pandoc
AST serialized as JSON.
"""
module PandocFilters

export walk, toJSONFilter

using JSON


"""
Type representing Pandoc elements.
"""
abstract type PandocElement end
abstract type Aux <: PandocElement end

abstract type Block <: PandocElement end
abstract type Inline <: PandocElement end
abstract type MetaValue <: PandocElement end

struct Meta <: Aux
  unMeta :: Dict{String, MetaValue}
end

struct Pandoc <: Aux
  meta :: Meta
  blocks :: Vector{Block}
end

# Meta stuff

struct MetaMap <: MetaValue
  contents :: Dict{String, MetaValue}
end

struct MetaList <: MetaValue
  contents :: Vector{MetaValue}
end

struct MetaBool <: MetaValue
  contents :: Bool
end

struct MetaString <: MetaValue
  contents :: String
end

struct MetaInlines <: MetaValue
  contents :: Vector{Inline}
end

struct MetaBlocks <: MetaValue
  contents :: Vector{Block}
end

# Helpers
@enum ListNumberStyle DefaultStyle Example Decimal LowerRoman UpperRoman LowerAlpha UpperAlpha
@enum ListNumberDelim DefaultDelim Period OneParen TwoParens
@enum QuoteType SingleQuote DoubleQuote
@enum Alignment AlignLeft AlignRight AlignCenter AlignDefault
@enum MathType DisplayMath InlineMath
@enum CitationMode AuthorInText SuppressAuthor NormalCitation

struct Format <: Aux
  contents :: String
end

struct Attr <: Aux
  id :: String
  classes :: Vector{String}
  kv :: Dict{String, String}
end
struct ListAttributes <: Aux
  number :: Int
  style :: ListNumberStyle
  delim :: ListNumberDelim
end

struct TableCell <: Aux
  contents :: Vector{Block}
end

struct Target <: Aux
  from :: String
  to :: String
end

struct Citation <: Aux
  citationID :: String
  citationPrefix :: Vector{Inline}
  citationSuffix :: Vector{Inline}
  citationMode :: CitationMode
  citationNoteNum :: Int
  citationHash :: Int
end


# Constructors for block elements


struct Plain <: Block
  contents :: Vector{Inline}
end

struct Para <: Block
  contents :: Vector{Inline}
end

struct LineBlock <: Block
  contents :: Vector{Vector{Inline}}
end

struct CodeBlock <: Block
  attr :: Attr
  contents :: String
end

struct RawBlock <: Block
  format :: Format
  contents :: String
end

struct BlockQuote <: Block
  contents :: Vector{Block}
end

struct OrderedList <: Block
  attributes :: ListAttributes
  contents :: Vector{Vector{Block}}
end

struct BulletList <: Block
  contents :: Vector{Vector{Block}}
end

struct DefinitionList <: Block
  contents:: Vector{Tuple{Vector{Inline}, Vector{Block}}}
end

struct Header <: Block
  level :: Int
  attr :: Attr
  text :: Vector{Inline}
end

struct HorizontalRule <: Block end

struct Table <: Block
  caption :: Vector{Inline}
  column_alignment :: Vector{Alignment}
  column_relative_widths :: Vector{Float64}
  column_headers :: Vector{TableCell}
  rows :: Vector{Vector{TableCell}}
end

struct Div <: Block
  attr :: Attr
  contents :: Vector{Block}
end

struct Null <: Block end


# Inlines

struct Str <: Inline
  contents :: String
end

struct Emph <: Inline
  contents :: Vector{Inline}
end

struct Strong <: Inline
  contents :: Vector{Inline}
end

struct Strikeout <: Inline
  contents :: Vector{Inline}
end

struct Superscript <: Inline
  contents :: Vector{Inline}
end

struct SmallCaps <: Inline
  contents :: Vector{Inline}
end

struct Quoted <: Inline
  type :: QuoteType
  contents :: Vector{Inline}
end

struct Cite <: Inline
  citation :: Vector{Citation}
  contents :: Vector{Inline}
end 

struct Code <: Inline
  attr :: Attr
  contents :: String
end

struct Space <: Inline end
struct SoftBreak <: Inline end
struct HardBreak <: Inline end

struct Math <: Inline
  type :: MathType
  contents :: String
end

struct RawInline <: Inline
  format :: Format
  contents :: String
end

struct Link <: Inline
  attr :: Attr
  alt_text :: Vector{Inline}
  target :: Target
end

struct Image <: Inline
  attr :: Attr
  alt_text :: Vector{Inline}
  target :: Target
end

struct Note <: Inline
  contents :: Vector{Block}
end

struct Span <: Inline
  attr :: Attr
  contents :: Vector{Inline}
end



# @eval PandocFilters begin
#   println("Dict(")
#   using InteractiveUtils
#   l = length("PandocFilters.")
#   for st in subtypes(PandocElement)
#     for st2 in subtypes(st)
#       println( string(st2)[l+1:end] => st2 , ",")
#     end
#   end
#   println(")")
#   end

const ParseDict = Dict(
  "Attr" => Attr,
"Citation" => Citation,
"Format" => Format,
"ListAttributes" => ListAttributes,
"Meta" => Meta,
"Pandoc" => Pandoc,
"TableCell" => TableCell,
"Target" => Target,
"BlockQuote" => BlockQuote,
"BulletList" => BulletList,
"CodeBlock" => CodeBlock,
"DefinitionList" => DefinitionList,
"Div" => Div,
"Header" => Header,
"HorizontalRule" => HorizontalRule,
"LineBlock" => LineBlock,
"Null" => Null,
"OrderedList" => OrderedList,
"Para" => Para,
"Plain" => Plain,
"RawBlock" => RawBlock,
"Table" => Table,
"Cite" => Cite,
"Code" => Code,
"Emph" => Emph,
"HardBreak" => HardBreak,
"Image" => Image,
"Link" => Link,
"Math" => Math,
"Note" => Note,
"Quoted" => Quoted,
"RawInline" => RawInline,
"SmallCaps" => SmallCaps,
"SoftBreak" => SoftBreak,
"Space" => Space,
"Span" => Span,
"Str" => Str,
"Strikeout" => Strikeout,
"Strong" => Strong,
"Superscript" => Superscript,
"MetaBlocks" => MetaBlocks,
"MetaBool" => MetaBool,
"MetaInlines" => MetaInlines,
"MetaList" => MetaList,
"MetaMap" => MetaMap,
"MetaString" => MetaString
)
  
for (str, T) in ParseDict
  S = Symbol(str)
  if fieldcount(T) > 1
    eval( :( Base.convert(::$S, x::AbstractVector) = $S(x...) ) )
    eval( :( $S(x) = $S(x...)  ))
    # eval( :( Base.convert($S, x::AbstractVector) = $S(x...)  ))
  end
end

const StringDict = Dict( value => key for (key, value) in ParseDict)

function _vector(x :: PandocElement)
  vec = []
  for f in fieldnames(typeof(x))
    push!(vec, getproperty(x, f))
  end
  vec
end

function _dictify(x :: Any)
  throw(error("Uncaught _dictify"))
end

_dictify(x :: String) = x
function _dictify(x :: AbstractArray)
  _dictify.(x)
end

function _dictify(x :: PandocElement)
  T = typeof(x)
  n = fieldcount(T)
  if n == 0
    return Dict( "t" => StringDict[T])
  elseif n == 1
    return Dict( "t" => StringDict[T], "c" => _dictify(_vector(x)[]))
  else
    return Dict( "t" => StringDict[T], "c" => [ _dictify(y) for y in _vector(x)])
  end
end


makeJuliaAST(x :: Any) = x

makeJuliaAST(x :: AbstractArray) = makeJuliaAST.(x)

function makeJuliaAST(dict :: AbstractDict)
  if !haskey(dict, "t")
    return Dict( key => makeJuliaAST(value) for (key, value) in dict)
  end
  T = ParseDict[ dict["t"]]
  n = fieldcount(T)

  if !haskey(dict, "c")
    @assert n == 0
    return T()
  end
  contents = makeJuliaAST(dict["c"])
  if n == 1
    return T(contents)
  else
    try
      return T(contents...)
    catch E
      println("Tried to splat construct T=$T")
      println("With contents=$contents")
      rethrow(E)
    end
  end
end


"""
Function walk will walk `Pandoc` document abstract source tree (AST) and apply filter function on each elemnet of the document AST.
Returns a modified tree.
"""

function walk(x :: Any, action :: Function, format, meta)
    return x
end

function walk(x :: AbstractArray, action :: Function, format, meta)
  array = []
  w(z) = walk(z, action, format, meta)
  for item in x
    if (item isa AbstractDict) && haskey(item,"t")
      res = action(item["t"], get(item, "c", nothing), format, meta)
      if res === nothing
        push!(array, w(item))
      elseif res isa AbstractArray
        for z in res
          push!(array, w(z))
        end
      else
        push!(array, w(res))
      end
    else
      push!(array, w(item))
    end #if
  end #for
  return array
end

function walk(dict :: AbstractDict, action :: Function, format, meta)
  # Python version (mutating):
  # for k in keys(dict)
  #   dict[k] = walk(dict[k], action, format, meta)
  # end
  # return dict
  typ = dict["t"]
  T = ParseDict[typ]
  # parsed = Base.Meta.parse(typ)
  # @show parsed
  # @show dump(parsed)

  # T = eval(parsed)
  if !haskey(dict, "c")
    return T()
  end

  contents = walk(dict["c"], action, format, meta)
  # if contents isa AbstractArray
  #   return T(contents...)
  # else
  return T(contents)
  # end
  # Dict(key=>walk(value,action, format, meta) for (key,value) in dict)
end


"""
Converts an action or a list of actions into a filter that reads a JSON-formatted
pandoc document from stdin, transforms it by walking the tree
with the actions, and returns a new JSON-formatted pandoc document
to stdout.  The argument is a list of functions action(key, value, format, meta),
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
  doc = JSON.parse(STDIN)
  format = (length(ARGS) <= 0) ? "" : ARGS[1]
  if "meta" in doc
    meta = doc["meta"]
  elseif doc isa AbstractArray  # old API
    meta = doc[1]["test"]
  else
    meta = Dict()
  end

  for action in actions
    doc = walk(doc, action, format, meta)
  end
  JSON.print(STDOUT, doc)
end


function elt(eltType, numargs)
    function fun(args...)
        lenargs = length(args)
        if lenargs != numargs
            error("$eltType expects $numargs arguments, but given $lenargs")
        end
        if numargs == 0
            xs = []
        elseif numargs == 1
            xs = args[1]
        else
            xs = collect(args)
        end
        return Dict("t" => eltType, "c" => xs)
      end
    return fun
end




# Plain = elt("Plain", 1)
# Para = elt("Para", 1)
# CodeBlock = elt("CodeBlock", 2)
# RawBlock = elt("RawBlock", 2)
# BlockQuote = elt("BlockQuote", 1)
# OrderedList = elt("OrderedList", 2)
# BulletList = elt("BulletList", 1)
# DefinitionList = elt("DefinitionList", 1)
# Header = elt("Header", 3)
# HorizontalRule = elt("HorizontalRule", 0)
# Table = elt("Table", 5)
# Div = elt("Div", 2)
# Null = elt("Null", 0)

# # Constructors for inline elements

# Str = elt("Str", 1)
# Emph = elt("Emph", 1)
# Strong = elt("Strong", 1)
# Strikeout = elt("Strikeout", 1)
# Superscript = elt("Superscript", 1)
# Subscript = elt("Subscript", 1)
# SmallCaps = elt("SmallCaps", 1)
# Quoted = elt("Quoted", 2)
# Cite = elt("Cite", 2)
# Code = elt("Code", 2)
# Space = elt("Space", 0)
# LineBreak = elt("LineBreak", 0)
# Math = elt("Math", 2)
# RawInline = elt("RawInline", 2)
# Link = elt("Link", 3)
# Image = elt("Image", 3)
# Note = elt("Note", 1)
# SoftBreak = elt("SoftBreak", 0)
# Span = elt("Span", 2)
end # module
