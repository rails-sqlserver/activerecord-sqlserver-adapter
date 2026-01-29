class ApplicationController < ActionController::Base
  def index
    render html: '<h1>Rendered Minitest::Spec</h1>'.html_safe, layout: false
  end
end
