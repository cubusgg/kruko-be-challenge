# Fix and refactor the following controller
class CommentsController < ApplicationController
  def index
    Comment.joins(:author).where(authors: { username: params[:username] })
  end
end
