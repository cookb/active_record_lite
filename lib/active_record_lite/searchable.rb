require_relative './db_connection'

module Searchable
  def where(params)
    where_keys = params.keys.map { |key| "#{key} = ?" }.join(" AND ")
    where_values = params.values

    results = DBConnection.execute(<<-SQL, *where_values)
      SELECT *
      FROM #{self.table_name}
      WHERE #{where_keys}
    SQL

    parse_all(results)
  end

  def all
    results = DBConnection.execute(<<-SQL)
  		SELECT *
  		FROM #{@table_name}
  	SQL

    parse_all(results)
  end

  def find(id)
    results = DBConnection.execute(<<-SQL, id)
      SELECT *
      FROM #{@table_name}
      WHERE id = ?
  	SQL

  	parse_all(results).first
  end
end