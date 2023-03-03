# encoding: Windows-31J
require "net/https"
require "uri"
require "kconv"

# リクエスト先URL
uri = URI.parse("https://kt01.smbc-gp.co.jp/mulpayconsole/shop/tshop00004406/")

# リクエストパラメータマップの生成
params = {
  ShopID:   "tshop00004406",
  ShopPass: "5UgtRNzQyc6b!pS",
  OrderID:  "SampleOrderID",
  JobCd:    "AUTH",
  Amount:   "100",
  Tax:      "10",
  TdFlag:   "1",
  Tds2Type: "1"
}

# リクエスト
response = Net::HTTP.post_form(uri, params)

# レスポンスチェック
statusCode = response.code

if statusCode == "200" then
  # レスポンスのエラーチェック
  # レスポンスのパース
  sjisResponseBody = Kconv.tosjis(response.body)
  responseAry = {}
  for set in sjisResponseBody.split("&") do
    paramAry = set.split("=")
    responseAry[paramAry[0]] = paramAry[1]
  end

  if Hash[responseAry].key?("ErrCode") then
    # エラー
    puts Hash[responseAry]
    return
  end
else
  # HTTPステータスエラー
  return
end

puts sjisResponseBody
