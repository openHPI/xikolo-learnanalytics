class Job < ActiveRecord::Base
  default_scope {order('updated_at DESC')}

end