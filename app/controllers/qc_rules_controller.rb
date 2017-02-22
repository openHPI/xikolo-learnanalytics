class QcRulesController < ApplicationController
  responders Responders::ApiResponder,
             Responders::DecorateResponder,
             Responders::HttpCacheResponder,
             Responders::PaginateResponder

  respond_to :json

  def index
    rules = QcRule.all
    unless params[:show_all].present?# and params[:show_all] == true
      rules.where! is_active: true
    end

    respond_with rules
  end

  def show
    respond_with QcRule.find params[:id]
  end

  def create
    rule = QcRule.create rule_params
    rule.is_active = params[:is_active] if params[:is_active]
    rule.save
    respond_with rule
  end

  def update
    q = QcRule.find(params[:id])
    q.update_attributes(rule_params)
    respond_with q
  end

  private

  def rule_params
    params.permit(:worker, :is_active)
  end

end