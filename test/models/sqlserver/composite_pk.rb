# frozen_string_literal: true

class SSCompositePkWithoutIdentity < ActiveRecord::Base
  self.table_name = :sst_composite_without_identity
end

class SSCompositePkWithIdentity < ActiveRecord::Base
  self.table_name = :sst_composite_with_identity
end
