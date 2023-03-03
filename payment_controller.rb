module Api
  module V1
    class Payments::PaymentController < Api::V1::BaseController
      skip_before_action :verify_authenticity_token, only: :redirect
      def order
        order = Order.new({
                            order_id: Time.now.to_time.to_i.to_s
                          })

        if order.update(order_params)
          order_id = order.order_id
          payment_amount = order_params[:payment_amount]
          payment_method = order_params[:payment_method]

          result = PaymentService.call({ payment_amount:, payment_method:,
                                         order_id: })

          if result[:errInfo].present?
            render json: { errors: { code: result[:errInfo], message: result[:message] } }, status: result[:error]
          else
            render json: { link_payment: result[:link_url], order_id: }, status: :ok
          end
        else
          json = {
            success: false,
            erros: order.errors.full_messages
          }
          render json:
        end
      end

      def status
        order_id = params[:order_id]

        order = Order.find_by(order_id:)

        if order.present?
          json = { status: order.status }
          render json:
        else
          render json: { errors: { code: 404, message: 'Order not found' } }, status: 404
        end
      end

      def redirect
        return unless params['result'].present?

        decode = Base64.decode64(params['result'].split('.')[0])
        params = JSON.parse(decode)
        result = params['transactionresult']['Result']
        order_id = params['transactionresult']['OrderID']
        payment_method = params['transactionresult']['Paymethod']
        purchased_url = Gmo::Const::GMO_API[:shop_purchased]
        order = Order.find_by_order_id(order_id)

        order.update_attributes(status: result)

        redirect_to "#{purchased_url}?target_screen=PAYMENT_RESULT&order_id=#{order_id}"
      end

      private

      def order_params
        params.require(:order).permit(:user_id, :product_id, :payment_amount, :payment_method)
      end
    end
  end
end
