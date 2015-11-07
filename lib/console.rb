Pry.config.prompt = lambda do |context, nesting, pry| 
  "[sqlserver] #{context} > "
end