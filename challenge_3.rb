# https://github.com/knowde/knowde-web/blob/master/app/controllers/api/v2/builders_controller.rb
#
class Api::V2::BuildersController < Api::V2::BaseController
  def show
    render json: BuilderPage.call(url: request.url, user: current_user)
  rescue BuilderPage::Unauthorized => e
    render json: e.message, :unauthorized
  rescue BuilderPage::Error => e
    render json: e.message, :not_found
end

class BuilderPage
  BUILDERIO_PATH = 'https://cdn.builder.io'.freeze
  GIVAUDAN = 'givaudan'.freeze
  SECRET_PAGE_REGEXP = %r{/api/v1/query/\w+/secret-page}

  class Unauthorized < StandardError; end
  class Error < StandardError; end

  def initalize(url:, company_seo_url: GIVAUDAN)
    @url = url
    @company_seo_url = company_seo_url
  end

  def self.call(...)
    new(...).call
  end

  def call
    raise Unauthorized, 'Unauthorized' if secret_page? || blacklisted?

    HTTParty.get(BUILDERIO_PATH, headers: auth_headers, format: :json)
  rescue HTTParty::Error => e
    Sentry.capture_exception(e)
    raise Error, 'Page not found'
  end

  private

  def secret_page?
    SECRET_PAGE_REGEXP.match?(url) && user.nil?
  end

  def company
    return @company if defined?(@company)

    @company ||= Company.find_by(seo_url: company_seo_url)
  end

  def blacklisted?
    return true if competitors.include?(user.company_id)
    return true if competitors.pluck(:black_listed_domains).include?(user_domain)

    false
  end

  def competitors
    competitors ||= company.company_competitor
  end

  def user_domain
    domain ||= Mail::Address.new(user.email).domain
  end

  def auth_headers
    { 'Authorization' => "Bearer #{ENV['BUILDER_IO_AUTH_TOKEN']}" }
  end
end
