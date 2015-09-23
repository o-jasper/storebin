local _, encode_str = unpack(require "storecmd.lib.encode")
local _, decode_str = unpack(require "storecmd.lib.decode")

local assert_eq = unpack(require "storebin.test.lib")

local prstf = false

local function t(data)
   local ek = encode_str(data)
   assert_eq(data, decode_str(ek))
end

t{[3.3] = 1}

t("b�")

t{["b�"] = {1,2}}

t("abcdefg,,dsgdsgs.gsgs")

t("abcdefg")

t{q={r=1, s=2, t=3}}
t(2325)
t{q=1}
t({2325})

local blorb = {1,2,3, "kittens", "are great", "2235", "35.45", {1}, 5, q=53}
t(blorb)

t{ alpha=blorb }

t{ a={b={c="ska", d=66, ["1"]=35}, neigbours="okey2"}, neighbours="okey"}
