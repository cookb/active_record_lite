class Object
  def self.new_attr_accessor(*attributes)
    @attrs = []
    attributes.each do |attribute|
      @attrs << attribute
      define_method( "#{attribute}=") do |value|
        self.instance_variable_set("@#{attribute.to_sym}", value)
      end

      define_method("#{attribute}") do
        self.instance_variable_get("@#{attribute.to_sym}")
      end
    end
  end

  def self.attrs
    @attrs
  end
end

# class Cat
#   new_attr_accessor(:name, :color, :age)
# end
#
# cat = Cat.new
# cat.name = "Bowser"
# cat.color = "Brown"
# cat.age = 13
# p Cat.attrs
# p cat.name
# p cat.color
# p cat.age