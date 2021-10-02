using HTTP
using JSON
using Base64
using Nettle
using StringEncodings
using Unicode

using PyCall
b64 = pyimport("base64")
hmac = pyimport("hmac")
hashlib = pyimport("hashlib")
urlparse = pyimport("urllib.parse")

nonce0 = 1.631726849396e12 # millisecond nonce
nonce() = Int64(time()*1000)
#nonce = Int64(1616492376594)

url = "https://api.kraken.com"
uri = "/0/private/GetWebSocketsToken"

# Real
key = ""
secret = ""


# Kraken documentation examples
#secret = "FRs+gtq09rR7OFtKj9BGhyOGS3u5vtY/EdiIBO9kD8NFtRX7w7LeJDSrX6cq1D8zmQmGkWFjksuhBvKOAWJohQ=="
#secret = "kQH5HW/8p1uGOVjbgWA7FunAmGO8lsSUXNsu3eow76sz84Q18fWxnyRzBHCd3pd5nE9qa99HAZtuZuj6F1huXg=="

nonce_this_request = nonce()

#nonce_this_request = nonce()
#=data = Dict(
    "nonce" => "1616492376594",
    "ordertype" => "limit",
    "pair" => "XBTUSD",
    "price" => 37500,
    "type" => "buy",
    "volume" => 1.25
)=#
data = Dict("nonce" => nonce_this_request)
data_safe = HTTP.escapeuri(data)
#data_safe = "nonce=1616492376594&ordertype=limit&pair=XBTUSD&price=37500&type=buy&volume=1.25"
data_enc = cat(encode(string(nonce_this_request), "UTF-8"), encode(data_safe, "UTF-8"), dims = 1)

#sha256 = encode(hexdigest("sha256", data_enc), "UTF-8")
sha256 = codeunits(hashlib.sha256(data_enc).digest())
sec_dec = base64decode(secret)
uri_enc = encode(uri, "UTF-8")
message = cat(uri_enc, sha256, dims = 1)
macer = hmac.new(sec_dec, message, hashlib.sha512)
mac = codeunits(macer.digest())

sig = base64encode(mac)

message = cat(encode(uri, "UTF-8"), sha256, dims = 1)


#headers = [("API-Key", "S13rqMOKjZbbVwGYPbZRiGp5LojaL7kXlUW/+H3x3fAQjbuQXvQKxUgh"),
#           ("API-Sign", data_prepped)]
headers = [("API-Key", key),
           ("API-Sign", sig)]

token_response = HTTP.post(string(url, uri), headers, data_safe)
token_dirty = decode(token_response.body, "UTF-8")
preamble = "{\"error\":[],\"result\":{\"token\":\""
postamble = ",\"expires\":900}}"
token_dirty = replace(token_dirty, preamble => "")
token = replace(token_dirty, postamble => "")

ws_url = "ws-auth.kraken.com"
HTTP.WebSockets.open(ws_url) do ws
    println(ws)
end
#={
  "event": "subscribe",
  "subscription":
  {
    "name": "julia_crypto_sail",
    "token": token
  }
}=#
