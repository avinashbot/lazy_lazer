<div align="center">
  <img src="https://raw.githubusercontent.com/avinashbot/lazy_lazer/master/logo.png" width="500"><br>
</div>

```ruby
require 'lazy_lazer'

class User
  include LazyLazer

  property :id, required: true
  property :email, default: 'unknown@example.com'
  property :created_at, from: 'creation_time_utc', with: ->(time) { Time.at(time) }
  property :age, with: :to_i

  property :favorite_ice_cream

  def lazer_reload
    self.fully_loaded = true # mark model as fully updated
    { favorite_ice_cream: %w[vanilla strawberry chocolate].sample }
  end
end

user = User.new(id: 152, creation_time_utc: 1500000000, age: '21')

user.id          #=> 152
user.email       #=> "unknown@example.com"
user.created_at  #=> 2017-07-14 03:40:00 +0100
user.age         #=> 21

user.favorite_ice_cream         #=> "chocolate"
user.reload.favorite_ice_cream  #=> "vanilla"
```

<div align="center">
licensed under [mit](https://github.com/avinashbot/lazy_lazer/blob/master/LICENSE.txt) -
created for [redd](https://github.com/avinashbot/redd) -
logo font is [zaguatica](https://www.behance.net/gallery/3588289/Zaguatica)
</div>
