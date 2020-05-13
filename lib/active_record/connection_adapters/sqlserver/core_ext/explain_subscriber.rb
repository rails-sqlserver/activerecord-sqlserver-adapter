# frozen_string_literal: true

ActiveSupport.on_load(:active_record) do
  silence_warnings do
    # Already defined in Rails
    ActiveRecord::ExplainSubscriber::EXPLAINED_SQLS = /(select|update|delete|insert)\b/i
  end
end
