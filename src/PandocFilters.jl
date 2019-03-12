# Author: Martin Vuk <martin.vuk@fri.uni-lj.si>
# Copyright: (C) 2016 Martin Vuk
# License: BSD 3-clause


"""
Functions to aid writing python scripts that process the pandoc
AST serialized as JSON.
"""
module PandocFilters

using AbstractTrees
import AbstractTrees: children, Leaves, treemap


export walk, toJSONFilter

using JSON

using LightGraphs, MetaGraphs

function build_graph!(G, root)
  
  add_vertex!(G)
  v = nv(G)
  set_prop!(G, v, :elt, root)
  _build_graph!(G, root, v)
end

function _build_graph!(G, parent, vparent)
  
  for child in children(parent)
    add_vertex!(G)
    v = nv(G)
    set_prop!(G, v, Symbol(typeof(child)), child)
    add_edge!(G, vparent, v)
    _build_graph!(G, child, v)
  end
end

function wraptree(root)
  G = MetaGraph(SimpleDiGraph())
  build_graph!(G, root)
  return G
end

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


struct Pandoc <: PandocElement
  meta :: Meta
  blocks :: Vector{Block}
  api_version :: Vector{Int}
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
abstract type ListNumberStyle <: Aux end
for T in [:DefaultStyle, :Example, :Decimal, :LowerRoman, :UpperRoman, :LowerAlpha, :UpperAlpha]
  eval( :( struct $T <: ListNumberStyle end ) )
end

abstract type ListNumberDelim <: Aux end
for T in [:DefaultDelim, :Period, :OneParen, :TwoParens]
  eval( :( struct $T <: ListNumberDelim end ) )
end

abstract type QuoteType <: Aux end
for T in [:SingleQuote, :DoubleQuote]
  eval( :( struct $T <: QuoteType end ) )
end

abstract type Alignment <: Aux end
for T in [:AlignLeft, :AlignRight, :AlignCenter, :AlignDefault]
  eval( :( struct $T <: Alignment end ) )
end
  
abstract type MathType <: Aux end
for T in [:DisplayMath, :InlineMath]
  eval( :( struct $T <: MathType end ) )
end

abstract type CitationMode <: Aux end
for T in [:AuthorInText, :SuppressAuthor, :NormalCitation]
  eval( :( struct $T <: CitationMode end ) )
end


struct Format <: Aux
  contents :: String
end


struct Attr <: Aux
  id :: String
  classes :: Vector{String}
  # kv :: Dict{String, String}
  kv :: Dict{String,Any}
end

function Attr(id, classes, kv::AbstractVector)
  @assert length(kv) == 0
  Attr(id, classes, Dict{String,Any}())
end
  # Base.convert(Attr, x::AbstractVector)
  #   @assert length(x) == 3
  #   id, classes, kv = vector
  #   # id::String, classes::Vector{String}, kv::Vector{Any})
  #   if kv isa AbstractDict
  #     return Attr(id, classes, kv)
  #   end
  #   @assert length(kv)==0
  #   Attr(id, classes, Dict{String,Any}())
  # end

function _dictify(A :: Attr)
  if isempty(A.kv)
    [A.id, A.classes, Any[]]
  else
    [A.id, A.classes, A.kv]
  end
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

function _dictify(T::Target)
  [T.from, T.to]
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
  # contents:: Vector{Tuple{Vector{Inline}, Vector{Block}}}
  contents:: Vector{Vector{Vector{Any}}}
end


struct Header <: Block
  level :: Int
  attr :: Attr
  contents :: Vector{Inline}
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
#       for st3 in subtypes(st2)
#         println( string(st3)[l+1:end] => st3 , ",")
#       end
#     end
#   end
#   println(")")
#   end

const ParseDict = Dict(
  "Alignment" => Alignment,
  "AlignCenter" => AlignCenter,
  "AlignDefault" => AlignDefault,
  "AlignLeft" => AlignLeft,
  "AlignRight" => AlignRight,
  "Attr" => Attr,
  "Citation" => Citation,
  "CitationMode" => CitationMode,
  "AuthorInText" => AuthorInText,
  "NormalCitation" => NormalCitation,
  "SuppressAuthor" => SuppressAuthor,
  "Format" => Format,
  "ListAttributes" => ListAttributes,
  "ListNumberDelim" => ListNumberDelim,
  "DefaultDelim" => DefaultDelim,
  "OneParen" => OneParen,
  "Period" => Period,
  "TwoParens" => TwoParens,
  "ListNumberStyle" => ListNumberStyle,
  "Decimal" => Decimal,
  "DefaultStyle" => DefaultStyle,
  "Example" => Example,
  "LowerAlpha" => LowerAlpha,
  "LowerRoman" => LowerRoman,
  "UpperAlpha" => UpperAlpha,
  "UpperRoman" => UpperRoman,
  "MathType" => MathType,
  "DisplayMath" => DisplayMath,
  "InlineMath" => InlineMath,
  "Meta" => Meta,
  "Pandoc" => Pandoc,
  "QuoteType" => QuoteType,
  "DoubleQuote" => DoubleQuote,
  "SingleQuote" => SingleQuote,
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
  "MetaString" => MetaString,
  )

import Base.convert
function Base.convert(::Type{T}, x::AbstractVector) where {T <: PandocElement}
  try
    fieldcount(T) == 1 ? T(x)  : T(x...)
  catch E
    println("Error converting $x to $T")
    rethrow(E)
  end
end


# function Base.iterate(x::T, state=1) where {T <: PandocElement}
#   n = fieldcount(T) 
#   n < state && return nothing
#   return getproperty(x, fieldnames(T)[state]), state+1
# end

# function Base.getindex(x::T, i::Int) where {T <: PandocElement}
#   getproperty(x, fieldnames(T)[i])
# end

# Base.IteratorSize(::Type{T}) where {T <: PandocElement} = HasLength()
# length(x::T) where {T <: PandocElement} = fieldcount(T) 


const StringDict = Dict( value => key for (key, value) in ParseDict)


# _vector(x::Any) = x
# function _vector(x :: PandocElement)
#   vec = []
#   for f in fieldnames(typeof(x))
#     push!(vec, getproperty(x, f))
#   end
#   vec
# end

function children(x::PandocElement)
  T = typeof(x)
  if fieldcount(T) == 0
    return ()
  else
    return [ getproperty(x, f) for f in fieldnames(T) ]
  end
end

# function transform(x, f::Function)
#   T = typeof(x)
#   y = f(x)
#   if x != y
#     return y #modified x, done
#   elseif x isa AbstractVector # recurse deeper
#   #   return [ transform(z, f) for z in x ]
#   # elseif x isa PandocElement 
#   #   return T([ transform(z, f) for z in _vector(x)]...)
#   elseif x isa AbstractVector # recurse deeper
#     return [ transform(z, f) for z in x ]
#   elseif x isa PandocElement 
#     return T([ transform(z, f) for z in x]...)
#   else
#     return x
#   end
# end



function _dictify(x :: Any)
  throw(error("Uncaught _dictify $x"))
end

_dictify(x :: String) = x
_dictify(x :: Int) = x
_dictify(x :: Float64) = x

function _dictify(P :: Pandoc)
  Dict("blocks" => _dictify(P.blocks), "pandoc-api-version" => P.api_version, "meta" => _dictify(P.meta))
end

function _dictify(M :: Meta)
  Dict( key => _dictify(value) for (key, value) in M.unMeta)
end

function _dictify(x :: AbstractDict)
  Dict( key => _dictify(value) for (key, value) in x)
end

function _dictify(x :: AbstractArray)
  _dictify.(x)
end

function _dictify(x :: PandocElement)
  T = typeof(x)
  n = fieldcount(T)
  if n == 0
    return Dict( "t" => StringDict[T])
  elseif n == 1
    return Dict( "t" => StringDict[T], "c" => _dictify(children(x)[]))
  else
    return Dict( "t" => StringDict[T], "c" => [ _dictify(y) for y in children(x)])
  end
end


function makeJuliaAST(dict, format = ""; transform::Function = (elt, format, meta) -> elt)
  api = convert(Vector{Int}, dict["pandoc-api-version"])
  meta = Meta(_makeJuliaAST(dict["meta"], x -> transform(x, format, :no_meta_yet)))
  blocks = _makeJuliaAST(dict["blocks"], x -> transform(x, format, meta))
  return Pandoc(meta, blocks, api)
end

_makeJuliaAST(x :: Any, f) = x

function _makeJuliaAST(x :: Vector{T}, f) where {T}
  array = T[]
  for z in x
    out = _makeJuliaAST(z, f)
    if out !== nothing
      push!(array, out)
    end
  end
  array
end

function _makeJuliaAST(dict :: AbstractDict, f)
  if !haskey(dict, "t")    
    return Dict( key => _makeJuliaAST(value, f) for (key, value) in dict)
  end
  T = ParseDict[ dict["t"]]
  n = fieldcount(T)

  if !haskey(dict, "c")
    @assert n == 0
    return f(T())
  end
  contents = _makeJuliaAST(dict["c"], f)
  contents === nothing && return nothing
  if n == 1
    return f(T(contents))
  else
    try
      return f(T(contents...))
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

  Dict(key=>walk(value,action, format, meta) for (key,value) in dict)
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
