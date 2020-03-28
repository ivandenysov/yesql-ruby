require "yesql/version"
require "yesql/queries"

module Yesql
  class QueryNotFound < StandardError; end

  def self.queries(load_path:)
    Yesql::Queries.new(load_path: load_path)
  end
end
