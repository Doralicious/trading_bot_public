using HTTP
using JSON
using StringEncodings
using Unicode
using Makie

HOUR = 3600
DAY = 86400
WEEK = 604800
MONTH = 2629743
YEAR = 31556926

nonce0 = 1.631726849396e12 # millisecond nonce
nonce() = Int64(time()*1000)
#nonce = Int64(1616492376594)

url = "https://api.kraken.com"
uri = "/0/public/OHLC"

url_time = "https://api.kraken.com/0/public/Time"

interval = 5

nonce_this_request = nonce()

headers = [("API-Key", ""),
           ("API-Sign", "")]

function get_ohlc(url_full, headers, pair, interval, since)
    data = Dict("pair" => pair, "interval" => interval, "since" => since)
    data_safe = HTTP.escapeuri(data)
    ohlc_response = HTTP.get(url_full, headers, data_safe)
    ohlc_packed_dict = JSON.parse(decode(ohlc_response.body, "UTF-8"))
    ohlc_packed = ohlc_packed_dict["result"][pair]
    ohlc = Vector{Vector{Float64}}(undef, length(ohlc_packed))
    t = Vector{Float64}(undef, length(ohlc))
    for i = 1:length(ohlc)
        ohlc[i] = JSON.parse.(ohlc_packed[i][2:5])
        t[i] = ohlc_packed[i][1]
    end
    return t, ohlc
end
function current_ohlc(url_full, headers, pair, interval)
    t_all, ohlc_all = get_ohlc(url_full, headers, pair, interval, time()-61*interval)
    return t_all[end], ohlc_all[end]
end

pair = "EOSUSD"
interval = 5
since = time()-DAY
data = Dict("pair" => pair, "interval" => interval, "since" => since)
data_safe = HTTP.escapeuri(data)
url_full = string(url*uri*"?"*data_safe)

t_5m_1d, ohlc_5m_1d = get_ohlc(url_full, headers, pair, interval, time()-DAY)
t_last, ohlc_last = current_ohlc(url_full, headers, pair, interval)
