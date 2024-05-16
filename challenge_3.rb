# https://github.com/knowde/knowde-web/blob/master/app/controllers/api/v2/builders_controller.rb
#
class Api::V2::BuildersController < Api::V2::BaseController
  BUILDERIO_PATH = 'https://cdn.builder.io'.freeze
  SECRET_PAGE_REGEXP = %r{/api/v1/query/\w+/secret-page}
  GIVAUDAN = 'givaudan'.freeze

  before_action :doorkeeper_authorize!, if: :secret_page?

  delegate :company, to: :current_user
  delegate :company_competitor, to: :givaudan

  def show
    return head :unauthorized if secret_page? && blacklisted?

    response = HTTParty.get(url, headers: auth_headers)
    render json: response.parsed_response, status: response.code
  rescue HTTParty::Error => e
    Sentry.capture_exception(e)
    render json: { message: e.message }, status: :bad_request
  end

  private

  def secret_page?
    SECRET_PAGE_REGEXP.match?(request.url)
  end

  def givaudan
    @givaudan ||= Company.find_by(seo_url: GIVAUDAN)
  end

  def blacklisted?
    return false unless company_competitor
    return true if company_competitor.competitors.include?(current_user.company_id.to_s)

    domain = Mail::Address.new(current_user.email).domain
    return true if Array(company_competitor.black_listed_domains).include?(domain)

    false
  end

  def auth_headers
    {
      'Authorization' => "Bearer #{ENV['BUILDER_IO_AUTH_TOKEN']}"
    }
  end

  def url
    request.url.gsub("#{request.protocol}#{request.host_with_port}/api/v2/builder", BUILDERIO_PATH)
  end
end
