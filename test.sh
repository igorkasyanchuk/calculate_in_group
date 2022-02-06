cp ./test/dummy/config/database.mysql.yml ./test/dummy/config/database.yml
ruby test/calculate_in_group_test.rb
cp ./test/dummy/config/database.sqlite.yml ./test/dummy/config/database.yml
ruby test/calculate_in_group_test.rb
cp ./test/dummy/config/database.pg.yml ./test/dummy/config/database.yml
ruby test/calculate_in_group_test.rb