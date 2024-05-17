# Fix and refactor the following controller
class MyController < ApplicationController
  def options
    Hash[*permitted_params]
  end

  private

  def permitted_params
    params.require(:first_option, :second_option, :third_option).permit!
  end
end
