module TinyTds
  class Error < StandardError
    attr_accessor :source, :severity, :db_error_number, :os_error_number

    def initialize(message)
      super
      @severity = nil
      @db_error_number = nil
      @os_error_number = nil
    end
  end
end
