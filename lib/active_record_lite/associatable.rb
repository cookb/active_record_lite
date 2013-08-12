require 'active_support/core_ext/object/try'
require 'active_support/inflector'
require_relative './db_connection.rb'

class AssocParams
  attr_reader :other_class_name, :primary_key, :foreign_key
  
  def other_class
    @other_class_name.constantize
  end

  def other_table
    other_class.table_name
  end
end

class BelongsToAssocParams < AssocParams
  def initialize(name, params)
    @other_class_name = ( params[:class_name]  || name.to_s.camelize )
    @primary_key =      ( params[:primary_key] || :id )
    @foreign_key =      ( params[:foreign_key] || "#{name}_id".to_sym )
  end

  def type
    :belongs_to
  end
end

class HasManyAssocParams < AssocParams
  def initialize(name, params, self_class)
    @other_class_name = ( params[:class_name]  || name.to_s.singularize.camelize )
    @primary_key =      ( params[:primary_key] || :id )
    @foreign_key =      ( params[:foreign_key] || "#{self_class.name.underscore}_id".to_sym )
  end

  def type
    :has_many
  end
end

module Associatable
  def assoc_params
    # assoc_params[name] = Class_instance   # saves parameters
    # params = Class.assoc_params[params]
    
    @assoc_params ||= {}
    @assoc_params
  end

  def belongs_to(name, params = {})
    helps = BelongsToAssocParams.new(name, params)
    assoc_params[name] = helps  

    define_method(name) do
      results = DBConnection.execute(<<-SQL, self.send(helps.foreign_key))
        SELECT *
        FROM #{helps.other_table}
        WHERE #{helps.other_table}.#{helps.primary_key} = ?
    	SQL

      helps.other_class.parse_all(results)
    end
  end

  def has_many(name, params = {})
    helps = HasManyAssocParams.new(name, params, self.class)
    assoc_params[name] = helps
    
    define_method(name) do
      results = DBConnection.execute(<<-SQL, self.send(helps.primary_key))
        SELECT *
        FROM #{helps.other_table}
        WHERE #{helps.other_table}.#{helps.foreign_key} = ?
    	SQL

      helps.other_class.parse_all(results)
    end
  end

  def has_one_through(name, assoc1, assoc2) 
    # self.class = Cat
    # name = :house   (has one)
    # assoc1 = :human (through)
    # assoc2 = :house (source)
       
    define_method(name) do
      # get params for first jump (self to assoc1)
      params_1 = self.class.assoc_params[assoc1]
    
      # get params for second jump (assoc1 to assoc2) 
      params_2 = params_1.other_class.assoc_params[assoc2]
      
      # only do has_one_through join if both jumps are belongs_to's  
      if params_1.type == :belongs_to &&
         params_2.type == :belongs_to  
        
        results = DBConnection.execute(<<-SQL, self.send(params_1.foreign_key))
          SELECT #{params_2.other_table}.*
          FROM #{params_1.other_table}
          JOIN #{params_2.other_table}
          ON #{params_1.other_table}.#{params_2.foreign_key} = 
             #{params_2.other_table}.#{params_2.primary_key}
          WHERE #{params_1.other_table}.#{params_1.primary_key} = ?
      	SQL
      	
      	params_2.other_class.parse_all(results)
      end  
    end
  end
end
