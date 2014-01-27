silence_warnings do
  # Already defined in Rails
  ActiveRecord::ExplainSubscriber::EXPLAINED_SQLS = /(select|update|delete|insert)\b/i
end
