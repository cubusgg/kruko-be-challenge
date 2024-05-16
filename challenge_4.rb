# https://github.com/knowde/storefronts/blob/main/app/controllers/api/v1/products_controller.rb
# Propose refactoring of the following controller with two basic actions: index, show
module Api
  module V1
    class ProductsController < ApplicationController
      before_action :marketplace_only!, only: :viewed

      def index
        products = ::ResultPageService.new(
          focus_on: ResultPage::PRODUCTS,
          params: permitted_params.merge!(path:),
          storefront_id:,
          request_ip:,
          locale:,
          site:
        ).call

        render json: products
      end

      def show
        policy_scope([:api, :v1, Product.where(storefront_id:)]).find_by!(slug: params[:id]) if preview_mode_for_users?

        product = ResponseService.new(
          resource: :product,
          api_client:,
          storefront:,
          params: show_params,
          uncacheable_params: %i[access_token]
        ).call

        render json: ProductSerializer.new(product, company_id:).to_h
      end
    end
  end
end
