class Quote < ApplicationRecord
  attr_readonly [ :filename, :name ]
end
