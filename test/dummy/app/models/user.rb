class User < ApplicationRecord
  belongs_to :account, optional: true

  scope :admins, -> { where(role: 'admin') }

  def User.generate_random_users
    Account.create(name: "Roga&Kopyta")
    100.times do
      User.create(name: "John #{rand(1_000_000)}", role: ['admin', 'user', 'moderator'], age: rand(100), account: [Account.first, nil])
    end
  end

end
