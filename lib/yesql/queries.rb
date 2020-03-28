module Yesql
  class Queries
    class VariableCountMismatch < StandardError; end
    class MissingNamedVariable < StandardError; end

    REQUIRED_EXTENSION = ".sql"

    def initialize(load_path:)
      @load_path = load_path
    end

    def [](query_name)
      file_path = file_path(query_name: query_name)

      raise(Yesql::QueryNotFound, "query file not found: '#{file_path}'") unless File.exist?(file_path)
      File.read(file_path)
    end

    def build(query_name, *bind_variables)
      if bind_variables.size == 1 && bind_variables.first.kind_of?(Hash)
        replace_named_bind_variables(self[query_name], bind_variables: bind_variables.first)
      else
        replace_positional_bind_variables(self[query_name], bind_variables: bind_variables)
      end
    end

    private

    def replace_named_bind_variables(query, bind_variables:)
      query.gsub(/(:?):([a-zA-Z]\w*)/) do |match|
        if $1 == ":" # skip postgresql casts
          match # return the whole match
        elsif bind_variables.include?(match = $2.to_sym)
          prepare_bind_variable(bind_variables[match])
        else
          raise MissingNamedVariable, "missing value for :#{match}"
        end
      end
    end

    def replace_positional_bind_variables(query, bind_variables:)
      expected_variables_count = query.count("?")
      provided_variables_count = bind_variables.count

      unless expected_variables_count == provided_variables_count
        raise(VariableCountMismatch, "query has #{expected_variables_count} '?' placeholders but you provided #{provided_variables_count} values")
      end

      query.gsub("?").with_index { |_, index| prepare_bind_variable(bind_variables[index]) }
    end

    def prepare_bind_variable(value)
      if value.kind_of?(Array)
        value.join(", ")
      else
        value
      end
    end

    def file_path(query_name:)
      File.join(@load_path, "#{query_name}#{REQUIRED_EXTENSION}")
    end
  end
end
