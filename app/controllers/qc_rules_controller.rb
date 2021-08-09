# frozen_string_literal: true

class QcRulesController < ApplicationController
  responders Responders::DecorateResponder,
    Responders::HttpCacheResponder,
    Responders::PaginateResponder

  respond_to :json

  def index
    rules = QcRule.all

    rules.where!(is_active: true) if params[:show_all].blank?

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
    rule = QcRule.find(params[:id])
    rule.update(rule_params)
    respond_with rule
  end

  private

  def rule_params
    params.permit(:worker, :is_active)
  end
end
