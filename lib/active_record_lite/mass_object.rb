class MassObject
  def self.set_attrs(*attributes)
    @attributes = []

    attributes.each do |attribute|
      @attributes << attribute.to_sym
      attr_accessor(attribute.to_sym)
    end
  end

  def self.attributes
    @attributes
  end

  def self.parse_all(results)
    results.map { |row_hash| self.new(row_hash) }
  end

  def initialize(params = {})
    params.each do |attr_name, value|
      if self.class.attributes.include?(attr_name.to_sym)
        self.send("#{attr_name.to_sym}=", value)
      else
        raise "mass assignment to unregistered attribute #{attr_name}"
      end
    end

  end
end

# class MyClass < MassObject
#   set_attrs :x, :y
# end
#
# my_obj = MyClass.new(:x => :x_val, :y => :y_val)
# p my_obj.x
# p my_obj.y
# p MyClass.attributes