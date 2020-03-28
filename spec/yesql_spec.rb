RSpec.describe Yesql do
  it "has a version number" do
    expect(Yesql::VERSION).not_to be nil
  end

  describe ".queries" do
    let(:queries) { Yesql.queries(load_path: "./spec/sql") }

    describe "#[]" do
      it "returns SQL query string from a file" do
        expect(queries["user_count"]).to eq("select count(*) from users;\n")
      end

      it "returns SQL query string from a nested file" do
        expect(queries["users/count"]).to eq("select count(*) from users;\n")
      end

      it "raises an exception if given query name did not match any file" do
        expect { queries["alien_count"] }.to raise_error(Yesql::QueryNotFound)
      end
    end

    describe "#build" do
      it "works ok without parameters" do
        expect(queries.build("user_count")).to eq("select count(*) from users;\n")
      end

      it "interpolates position arguments into SQL" do
        expect(queries.build("users/find_with_positional_bind_variables", 1)).to eq("select * from users where id = 1 limit 1;\n")
      end

      it "raises an error if number of positional bind variables doesn't match" do
        expect { queries.build("users/find_with_positional_bind_variables", 1, 2) }.to raise_error(Yesql::Queries::VariableCountMismatch)
      end

      it "interpolates named bind variables into SQL" do
        expect(queries.build("users/find_with_named_bind_variables", user_id: 1)).to eq("select * from users where id = 1 limit 1;\n")
      end

      it "raises an exception if any named bind variables are missing" do
        expect { queries.build("users/find_with_named_bind_variables", id_of_user: 1) }.to raise_error(Yesql::Queries::MissingNamedVariable)
      end

      it "converts array bind variables into comma-separated list" do
        expect(queries.build("all_users", columns: ["id", "email"])).to eq("select id, email from users;\n")
      end
    end
  end
end
