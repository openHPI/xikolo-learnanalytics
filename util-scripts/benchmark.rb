require 'benchmark'
require 'active_record'
require 'activerecord-import'
require 'data_mapper'
require 'pg'

# Create the table first in the Postgres Database 'lanalytics-perf-test'
# CREATE TABLE users
# (
#   user_id uuid NOT NULL,
#   node_id integer,
#   score integer
# )
# WITH (
#   OIDS=FALSE
# );
# ALTER TABLE users
#   OWNER TO postgres;

ActiveRecord::Base.establish_connection(
  adapter:  'postgresql', # or 'postgresql' or 'sqlite3'
  database: 'lanalytics-perf-test',
  # username: 'DB_USER',
  # password: 'DB_PASS',
  # host:     'localhost'
)

class User < ActiveRecord::Base
end


CONN = ActiveRecord::Base.connection
TIMES = 10000

def do_inserts
    TIMES.times { User.create(:user_id => 'a593fdde-e172-4546-8e7a-123456789012', :node_id => 2, :score => 3) }
end

def raw_sql
    TIMES.times { CONN.execute "INSERT INTO users (score, node_id, user_id) VALUES(3.0, 2, 'a593fdde-e172-4546-8e7a-123456789012')" }
end

def mass_insert
    inserts = []
    TIMES.times do
        inserts.push "(3.0, 2, 'a593fdde-e172-4546-8e7a-123456789012')"
    end
    sql = "INSERT INTO users (score, node_id, user_id) VALUES #{inserts.join(", ")}"
    CONN.execute sql
end

def activerecord_extensions_mass_insert(validate = true)
    columns = [:score, :node_id, :user_id]
    values = []
    TIMES.times do
        values.push [3, 2, 'a593fdde-e172-4546-8e7a-123456789012']
    end

    User.import columns, values, :validate => validate
end

puts "Testing various insert methods for #{TIMES} inserts\n"
puts "    user     system      total        real\n"
puts "ActiveRecord without transaction:"
puts base = Benchmark.measure { do_inserts }

puts "ActiveRecord with transaction:"
puts bench = Benchmark.measure { ActiveRecord::Base.transaction { do_inserts } }
puts sprintf("  %2.2fx faster than base", base.real / bench.real)

puts "Raw SQL without transaction:"
puts bench = Benchmark.measure { raw_sql }
puts sprintf("  %2.2fx faster than base", base.real / bench.real)

puts "Raw SQL with transaction:"
puts bench = Benchmark.measure { ActiveRecord::Base.transaction { raw_sql } }
puts sprintf("  %2.2fx faster than base", base.real / bench.real)

puts "Single mass insert:"
puts bench = Benchmark.measure { mass_insert }
puts sprintf("  %2.2fx faster than base", base.real / bench.real)

puts "ActiveRecord::Extensions mass insert:"
puts bench = Benchmark.measure { activerecord_extensions_mass_insert }
puts sprintf("  %2.2fx faster than base", base.real / bench.real)

puts "ActiveRecord::Extensions mass insert without validations:"
puts bench = Benchmark.measure { activerecord_extensions_mass_insert(true)  }
puts sprintf("  %2.2fx faster than base", base.real / bench.real)

# DataMapper.setup(:default, 'postgres://user:password@localhost/lanalytics-perf-test')
# class User
#   include DataMapper::Resource

#   property :user_id, UUID    # An auto-increment integer key
#   property :node_id, Integer
#   property :score, Integer
# end

# def datamapper_do_inserts
#   TIMES.times { User.create(:user_id => 'a593fdde-e172-4546-8e7a-123456789012', :node_id => 2, :score => 3) }
# end

# puts "DataMapper without transaction:"
# puts bench = Benchmark.measure { datamapper_do_inserts }
# puts sprintf("  %2.2fx faster than base", base.real / bench.real)