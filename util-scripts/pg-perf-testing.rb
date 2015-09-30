require 'pg'

# Output a table of current connections to the DB
conn = PG.connect( dbname: 'lanalytics-perf-test' )

10000.times do |i|
  conn.exec( "INSERT INTO \"USER\"(user_id, user_birthday, user_country, user_language) VALUES ('#{"a593fdde-e172-4546-8e7a-%012d" % i}', '#{"%02d" % (i%30)}.#{"%02d" % (i%12)}.#{"%04d" % i}', '#{(i%2 == 0) ? 'Germany' : 'Cuba'}', '#{(i%2 == 0) ? 'en' : 'de'}');" )
end


# 10.times do | i |
#   conn.exec( "INSERT INTO \"User\"(user_name, user_id) VALUES ('User #{i}', '#{"a593fdde-e172-4546-8e7a-%012d" % i}');" )
# end