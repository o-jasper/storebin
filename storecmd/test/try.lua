local encode, encode_str = unpack(require "storecmd.lib.encode")

print(encode_str("abcdefg,,dsgdsgs.gsgs"))
print(encode_str("abcdefg"))

print(encode_str(2325))
print(encode_str({2325}))

local blorb = {1,2,3, "kitten", "are great", "2235", "35.45", {1}, 5, q=53}
print(encode_str(blorb))
print(encode_str{ alpha=blorb })

print(encode_str{ a={b={c="ska", d=66, ["1"]=35}, neigbours="okey2"}, neighbours="okey"})
