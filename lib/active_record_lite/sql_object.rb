require_relative './associatable'
require_relative './db_connection'
require_relative './mass_object'
require_relative './searchable'

# get String#underscore method to make table_name snake case!
require 'active_support/inflector'

class SQLObject < MassObject
	extend Searchable
	extend Associatable

  def self.set_table_name(table_name)
    @table_name = table_name.to_s.underscore
  end

  def self.table_name
    @table_name
  end

  def save
		self.id ? self.update : self.create
  end

	#private #doesn't work when made private?

  def create #insert
		attr_list = self.class.attributes[1..-1].map do |attr_name|
			self.send("#{attr_name}")
		end

		attr_names = self.class.attributes[1..-1].join(", ")
		question_marks = (["?"] * (self.class.attributes.length - 1)).join(", ")

		DBConnection.execute(<<-SQL, *attr_list)
      INSERT INTO #{self.class.table_name}
			(#{attr_names})
      VALUES (#{question_marks})
		SQL

		self.id = DBConnection.last_insert_row_id
  end

  def update
		attr_list = self.class.attributes.map do |attr_name|
			self.send("#{attr_name}")
		end

		DBConnection.execute(<<-SQL, *attr_list)
			UPDATE #{self.class.table_name}
			SET #{self.attribute_values}
			WHERE id = #{self.id}
		SQL
  end

  def attribute_values
		set_line = self.class.attributes.map { |attr_name| "#{attr_name} = ?" }
		set_line.join(", ")
  end
end
