using PandocFilters: walk, Plain, Null, Code, Str, _dictify, makeJuliaAST
using Test, JSON
import PandocFilters

PandocFilters.walk(x,y) =walk(x,y, "", Dict{String,Any}())

function wraptree(T)
  

end
# function compare_dicts(d1, d2)
#   diff = setdiff(keys(d1), keys(d2))
#   isempty(diff) || return diff
#   for k in keys(d1)
#     if d1[k] != d2[k]
#       if typeof(d1[k]) != typeof(d2[k])
#         println()
#       if d1[k] isa AbstractDict && d2[k] isa AbstractDict
#         return compare_dicts(d1[k],d2[k])
#       end
#       if d1[k] isa AbstractArray && d2[k] isa AbstractDict

#     end
#   end
#   return []
# end

@testset "Types" begin
  rawpara = raw"""{
    "t": "Para",
    "c": [{
        "t": "Str",
        "c": "Brief"
    }, {
        "t": "Space"
    }, {
        "t": "Str",
        "c": "mathematical"
    }] }"""
  para = JSON.parse(rawpara)
  p_in = copy(para)
  out =  makeJuliaAST(para)
  @test para == p_in # para unchanged
  @test PandocFilters._dictify(out) == para
end

@testset "JSON" begin
  para = JSON.parse(raw"""{
  "t": "Para",
  "c": [{
      "t": "Str",
      "c": "Brief"
  }, {
      "t": "Space"
  }, {
      "t": "Str",
      "c": "mathematical"
  }] }""")
  j_para = JSON.json(para)
  p_in = copy(para)
  j_test_no_change = JSON.json(_dictify(makeJuliaAST(para)))
  # Check para wasn't mutated
  @test para == p_in 

  # Test the json was unchanged
  @test j_para == j_test_no_change
  j_test_no_space = JSON.json(_dictify(walk(para, (t,c,f,m) -> t == "Space" ? [] : nothing)))

  j_no_space = raw"""{"c":[{"c":"Brief","t":"Str"},{"c":"mathematical","t":"Str"}],"t":"Para"}"""
  @test j_no_space == j_test_no_space
  
end

@testset "MANUAL" begin
  str = open("MANUAL.JSON", "r") do f
    read(f, String)
  end
  j_manual = JSON.parse(str)
  j_test_no_change = _dictify(makeJuliaAST(j_manual))
  @test j_manual == j_test_no_change
  
end

using PandocFilters
using PandocFilters: walk, Plain, Null, Code, Str, _dictify, makeJuliaAST
using Test, JSON
str = open("test/MANUAL.JSON", "r") do f
  read(f, String)
end;
j_manual = JSON.parse(str);
AST = makeJuliaAST(j_manual);
struct EmptyArray end
dict = Dict{Any, Int}()

for c in PandocFilters.Leaves(AST)
  if c isa AbstractArray && length(c) == 0
    c = EmptyArray()
  end
  dict[typeof(c)] = get(dict, typeof(c), 0) + 1
end

# super slow
import LazyJSON
j_manual_lazy = LazyJSON.parse(str);
AST2 = makeJuliaAST(j_manual_lazy);