require 'dbd/mysql'
require 'dbi'

class Base
  # Class variables
  @@connection = DBI.connect("DBI:Mysql:norm:localhost", "root", "")
  @@attributes = {}
  
  # Define instance variables from table
  @@connection.execute("DESCRIBE base;").each do |row|
    eval("attr_accessor :#{row[0]}")
    case row[1]
    when /^varchar/
      eval("@@attributes[\"#{row[0]}\"] = \"String\"")
    when /^int/
      eval("@@attributes[\"#{row[0]}\"] = \"Integer\"")
    end
  end

  # Instance methods
  
  # Initializes new objects with values matching the attributes passed in.
  def initialize(attributes)
    attributes.each do |key, value|
      eval("@#{key} = #{format_ruby(key, value)}")
    end
  end
  
  # Updates an individual object
  def update(changes)
    changes.each do |key, value|
      eval("@#{key} = #{format_ruby(key, value)}")
    end
    return self
  end
  
  # Class methods
  class << self
    # Creates a new object and saves it to the database.
    def create(attributes)
      columns = attributes.keys.join(", ")
      values = attributes.collect {|k, v| "#{format_mysql(k, v)}"}.join(", ")
      @@connection.execute("INSERT INTO base (#{columns}) VALUES (#{values});")
      new(attributes)
    end
    
    # Selects new object from the database that have matching attributes to those passed in.
    def select(attributes)
      condition = attributes.collect {|k, v| "#{k} = #{format_mysql(k, v)}"}.join(" AND ")
      results = @@connection.execute("SELECT * FROM base WHERE (#{condition});")
      objects = []
      results.fetch_hash do |row|
        objects << new(row)
      end
      objects
    end
    
    # Updates attributes for objects with attributes matching 'selection' to match those in 'changes'.
    def update(selection, changes)
      where_condition = selection.collect {|k, v| "#{k} = #{format_mysql(k, v)}"}.join(" AND ")
      set_condition = changes.collect {|k, v| "#{k} = #{format_mysql(k, v)}"}.join(", ")
      # Find the objects that will be updated
      results = @@connection.execute("SELECT * FROM base WHERE (#{where_condition});")
      # Update each object
      objects = []
      results.fetch_hash do |row|
        object = new(row)
        object.update(changes)
        objects << object
      end
      # Update the database
      @@connection.execute("UPDATE base SET #{set_condition} WHERE #{where_condition};")
      objects
    end
    
    # Class accessor for attributes.
    def attributes
      @@attributes
    end
    
    private

    def format_mysql(key, value)
      case @@attributes[key.to_s]
      when "Integer"
        value.to_s
      when "String"
        "'#{value}'"
      end
    end
  end
  
  private 

  def format_ruby(key, value)
    case @@attributes[key.to_s]
    when "Integer"
      value.to_i
    when "String"
      "\"#{value}\""
    end    
  end
end