class QcRuleDecorator < ApplicationDecorator
  delegate_all

  def as_json(opts = {})
    { id: model.id,
      worker: model.worker, # @deprecated
      name: model.name,
      is_active: model.is_active,
    }.as_json(opts)
  end
end
