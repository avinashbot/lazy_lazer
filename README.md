**lazy lazer**

**features**:
- simple codebase
- doesn't inherit all of the Hash and Enumerable cruft
- super lazy, doesn't even parse attributes until it's necessary

```ruby
class User
  include LazyLazer

  # User.new(first_name: 'John')  #=> Error: missing `id`
  # User.new(id: 1).id?  #=> true
  property :id, required: true

  # user = User.new(id: 1)
  # user.name  #=> Error: not provided `name` on #<...>
  #
  # user = User.new(id: 1, first_name: 'John')
  # user.name  #=> 'John'
  # user.first_name  #=> NoMethodError: ...
  property :name, from: :first_name

  # user = User.new(id: 1)
  # user.email  #=> nil
  property :email, default: nil

  # user = User.new(id: 1)
  # user.preferred_language  #=> :en_US
  property :preferred_language, default: :en_US

  # user = User.new(id: 1, alias: 'Joe')
  # user.alias  #=> 'Joe'
  # user.aka  #=> 'Joe'
  property :alias, from: %i(alias aka other_name)

  # user = User.new(id: 1, first_name: 'John')
  # user.name  #=> 'John'
  # user.first_name  #=> NoMethodError: ...
  property :last_name, default: -> { '<last name>' }

  # user = User.new(id: 1, created_at: 1502834161)
  # user.created_at  #=> 2017-08-15 22:56:13 +0100
  property :created_at, with: ->(time) { Time.at(time) }

  # user = User.new(id: 1, age: '45')
  # user.age  #=> 45
  property :age, with: :to_i

  def reload
    update_attributes!(...) # update your attributes somehow
    fully_loaded = true # model is fully updated, no more lazy loading necessary
    self # a rails convention, totally optional
  end
end
```
