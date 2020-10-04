class Payment < ActiveRecord::Base
  enum status: %i[unresolved created charge_in_progress paid charge_failed reverted delivered expired cancelled]
end
