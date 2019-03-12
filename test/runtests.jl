using PandocFilters: walk, Plain, Null, Code, Str, _dictify, makeJuliaAST
using Test, JSON
import PandocFilters

PandocFilters.walk(x,y) =walk(x,y, "", Dict{String,Any}())


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