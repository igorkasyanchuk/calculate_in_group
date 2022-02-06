require_relative "test_helper"

class CalculateInGroupTest < ActiveSupport::TestCase
  test "it has a version number" do
    assert CalculateInGroup::VERSION
  end

  test 'works with age' do
    [3, 10, 20, 30, 40, 50, 60, 100, 1000].each {|e| User.create(age: e)}

    assert_equal ({"young" => 1, "old" => 1}), User.calculate_in_group(:count, :age, "young" => 10, "average" => 25, "old" => 60)
    assert_equal ({"young" => 1, "old" => 1}), User.calculate_in_group(:count, :age, "young" => 10, "average" => 25, "old" => 60)
    assert_equal ({"young" => 3, "old" => 2}), User.calculate_in_group(:count, :age, "young" => 0..25, "old" => 60..100)
    assert_equal ({"young" => 3, "old" => 3}), User.calculate_in_group(:count, :age, "young" => ..25, "old" => 60..)
    assert_equal ({"young" => 1, "old" => 3}), User.calculate_in_group(:count, :age, "young" => [15, 20], "old" => 60..)
    assert_equal ({"young" => 3, "old" => 2, "millenium" => 1 }), User.calculate_in_group(:count, :age, "young" => ..25, "old" => 60..100, "millenium" => 1000)

    # Other agg functions
    assert_equal ({"young" => 11.0, "old" => 80.0}), User.calculate_in_group(:average, :age, "young" => 0..25, "old" => 60..100)
    assert_equal ({"young" => 11.0, "old" => 60.0}), User.calculate_in_group(:average, :age, "young" => 0..25, "old" => 60...100)
    assert_equal ({"young" => 20, "old" => 100}), User.calculate_in_group(:maximum, :age, "young" => 0..25, "old" => 60..100)
    assert_equal ({"young" => 3, "old" => 60}), User.calculate_in_group(:minimum, :age, "young" => 0..25, "old" => 60..100)
    assert_equal ({"young" => 33, "old" => 160}), User.calculate_in_group(:sum, :age, "young" => 0..25, "old" => 60..100)
    assert_equal ({"young" => 33, "old" => 160}), User.calculate_in_group(:sum, :age, {"young" => 0..25, "old" => 60..100})

    # with defaults & nils
    assert_equal ({"young" => 33, "old" => 160, "baby" => 0}), User.calculate_in_group(:sum, :age, {"young" => 0..25, "old" => 60..100, "baby" => ..2}, {default_for_missing: 0})
    assert_equal ({"young" => 33, "old" => 160, "baby" => 0, nil => 1120}), User.calculate_in_group(:sum, :age, {"young" => 0..25, "old" => 60..100, "baby" => ..2}, {default_for_missing: 0, include_nil: true})
    assert_equal ({"young" => 33, "old" => 160, "baby" => 0, 'the rest' => 1120}), User.calculate_in_group(:sum, :age, {"young" => 0..25, "old" => 60..100, "baby" => ..2}, {default_for_missing: 0, include_nil: 'the rest'})
  end

  test 'works with age and nil' do
    [3, 10, 20, 30, 40, 50, 60, 100, 1000].each {|e| User.create(age: e)}
    assert_equal ({"young" => 1, "old" => 1, nil => 7}), User.calculate_in_group(:count, :age, {"young" => 10, "average" => 25, "old" => 60}, {include_nil: true})
    assert_equal ({"young" => 1, "old" => 1, "OTHER" => 7}), User.calculate_in_group(:count, :age, {"young" => 10, "average" => 25, "old" => 60}, {include_nil: "OTHER"})
  end

  test 'works with age and default_for_missing & nil' do
    [3, 10, 20, 30, 40, 50, 60, 100, 1000].each {|e| User.create(age: e)}
    assert_equal 9, User.count
    assert_equal ({"young" => 1, "old" => 1, "average" => 0}), User.calculate_in_group(:count, :age, {"young" => 10, "average" => 25, "old" => 60}, { default_for_missing: 0 })
    assert_equal ({"young" => 1, "old" => 1, "average" => 0, nil => 7}), User.calculate_in_group(:count, :age, {"young" => 10, "average" => 25, "old" => 60}, { default_for_missing: 0, include_nil: true })
    assert_equal ({"young" => 1, "old" => 1, "average" => 0, "OTHER" => 7}), User.calculate_in_group(:count, :age, {"young" => 10, "average" => 25, "old" => 60}, { default_for_missing: 0, include_nil: "OTHER"})
  end

  test 'works with role' do
    ['admin', 'admin', 'user', 'user', 'user', 'moderator'].each {|e| User.create(role: e)}
    assert_equal ({"with_permissions" => 2, "no_permissions" => 3}), User.calculate_in_group(:count, :role, "with_permissions" => "admin", "no_permissions" => "user")
    assert_equal ({"with_permissions" => 3, "no_permissions" => 3}), User.calculate_in_group(:count, :role, "with_permissions" => ["admin", "moderator"], "no_permissions" => "user")
  end

  test 'works with dates' do
    [2.hours.ago, 1.hour.ago, Time.now, 2.hours.from_now].each {|e| User.create(created_at: e)}
    sleep(0.01)
    assert_equal ({"old" => 2, "new" => 1}), User.calculate_in_group(:count, :created_at, { "old" => 12.hours.ago..1.minutes.ago, "new" => Time.now..10.hours.from_now })
    assert_equal ({"old" => 2, "new" => 1}), User.calculate_in_group(:count, :created_at, { "old" => ..1.minutes.ago, "new" => Time.now.. })
    assert_equal ({"old" => 2, "new" => 1, nil => 1}), User.calculate_in_group(:count, :created_at, { "old" => ..1.minutes.ago, "new" => Time.now.. }, {include_nil: true})
  end

  test 'wrong input' do
    assert_raise(ArgumentError) { User.calculate_in_group(:wrong_operation, :created_at, { "old" => ..1.minutes.ago, "new" => Time.now.. }) }
    assert_raise(ArgumentError) { User.calculate_in_group(:count, :not_existing_column, { "old" => ..1.minutes.ago, "new" => Time.now.. }) }
    assert_raise(ArgumentError) { User.calculate_in_group(:count, :not_existing_column) }
    assert_raise(ArgumentError) { User.calculate_in_group(:count, :not_existing_column, "ABC") }
  end

  test 'with relations' do
    a = Account.create
    b = Account.create
    User.create(created_at: 2.hours.ago, account: a)
    User.create(created_at: 1.hour.ago, account: a)
    User.create(created_at: Time.now, account: b)
    User.create(created_at: 2.hours.from_now, account: b)
    sleep(0.01)
    assert_equal ({"old" => 2}), a.users.calculate_in_group(:count, :created_at, { "old" => 12.hours.ago..1.minutes.ago, "new" => Time.now..10.hours.from_now })
  end

  test 'with scopes' do
    [2.hours.ago, 1.hour.ago, Time.now, 2.hours.from_now].each {|e| User.create(created_at: e)}
    sleep(0.01)
    assert_equal ({}), User.admins.calculate_in_group(:count, :created_at, { "old" => 12.hours.ago..1.minutes.ago, "new" => Time.now..10.hours.from_now })
    User.delete_all
    [2.hours.ago, 1.hour.ago, Time.now, 2.hours.from_now].each {|e| User.create(created_at: e, role: "admin")}
    sleep(0.01)
    assert_equal ({"old" => 2, "new" => 1}), User.admins.calculate_in_group(:count, :created_at, { "old" => 12.hours.ago..1.minutes.ago, "new" => Time.now..10.hours.from_now })
  end

  test 'when group is array and different ranges' do
    [3, 10, 20, 30, 50, 60, 100].each {|e| User.create(age: e)}
    #  3.1.0 :001 > a = 0..10
    #  3.1.0 :002 > a.to_a
    #   => [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
    #  3.1.0 :003 > a = 0...10
    #  3.1.0 :004 > a.to_a
    #   => [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]
    assert_equal ({"..10"=>2, "11..49"=>2, "50.."=>3 }), User.calculate_in_group(:count, :age, [..10, 11..49, 50..])
    assert_equal ({"...10"=>1, "11..49"=>2, "50.."=>3}), User.calculate_in_group(:count, :age, [...10, 11..49, 50..])
    assert_equal ({"...10"=>1, "10...50"=>3, "50.."=>3}), User.calculate_in_group(:count, :age, [...10, 10...50, 50..])
  end
end
