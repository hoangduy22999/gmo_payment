class PaymentService < ApplicationService

  def initialize(options = {})
    @payment_amount = options[:payment_amount]
    @payment_method = options[:payment_method]
    @order_id = options[:order_id]
    @user = Order.find_by_order_id(options[:order_id]).user

    @locale = options.fetch(:locale, Gmo::Const::DEFAULT_LOCALE)
    @linkplus_payment = Gmo::Const::GMO_API[:linkplus_payment]
    @shop_id = Gmo::Const::GMO_CONFIG[:shop_id]
    @shop_pass = Gmo::Const::GMO_CONFIG[:shop_pass]
    @payment_config_id = Gmo::Const::GMO_CONFIG[:payment_config_id]
    @redirect_purchased = Gmo::Const::GMO_API[:redirect_purchased]
  end
  attr_reader :payment_amount, :payment_method, :order_id, :locale, :user, :shop_id, :shop_pass, :payment_config_id,
              :linkplus_payment, :redirect_purchased

  def call
    request_get_url
  end

  private

  def request_get_url
    response_ary = {}

    begin
      uri = URI.parse(linkplus_payment)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = uri.scheme === 'https'
      headers = { "Content-Type": 'application/json;charset=UTF-8' }

      response = http.post(uri.path, payment_request_params.to_json, headers)
      statusCode = response.code
      result = response.body

      if statusCode == '200'
        response_ary[:link_url] = JSON.parse(result)['LinkUrl']
      else
        unless result.include? 'errInfo'
          response_ary[:link_url] = JSON.parse(result)['LinkUrl']
          return response_ary
        end
        message = Gmo::Payment::APIError.new(result, locale).message
        response_ary[:errInfo] = JSON.parse(result)[0]['errInfo']
        response_ary[:message] = message
      end
    end

    response_ary
  end

  def payment_request_params
    payload = {
      "configid": payment_config_id,
      "transaction": {
        "OrderID": order_id,
        "Amount": payment_amount,
        "RetryMax": 5,
        "ExpireDays": 0,
        "RetUrl": redirect_purchased,
        "PayMethods": [payment_method]
      },
      "geturlparam": {
        "ShopID": shop_id,
        "ShopPass": shop_pass
        # wait for upload テンプレート
        # "GuideMailSendFlag": "1",
        # "SendMailAddress": user&.email,
        # "CustomerName": user&.name,
        # "TemplateNo": "1"
      },
      "displaysetting": {
        "TemplateID": 'designB',
        "Lang": 'ja'
      },
      "#{payment_method}": gmo_payload_config[payment_method.to_sym]
    }
  end

  def gmo_payload_config
    {
      credit: {
        JobCd: 'AUTH',
        TdFlag: '0' # 3DS 使用しない
      },
      sb: {
        JobCd: 'AUTH'
      },
      au: {
        JobCd: 'AUTH',
        Commodity: NKF.nkf('-w -X', Order.find_by(order_id: order_id).product.first_name.to_s).tr("A-Z0-9","Ａ-Ｚ０-９").to_s,
        ServiceName: 'アイドルプリンス',
        # Todo お問い合わせ先の電話番号に変更
        ServiceTel: '0000-0000-0000'
      },
      docomo: {
        JobCd: 'AUTH'
      },
      paypay: {
        JobCd: 'AUTH'
      }
    }
  end
end
