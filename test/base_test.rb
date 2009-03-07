require "test/unit"
require "../base"

class BaseTest < Test::Unit::TestCase
  def test_create
    dbh = DBI.connect("DBI:Mysql:norm:localhost", "root", "")
    dbh.execute("DELETE FROM base;")
    Base.create(:name => "dope", :address => "dopes house")
    assert_equal dbh.select_one("SELECT COUNT(*) as count FROM base WHERE name = 'dope' AND address = 'dopes house';")[0].to_i, 1, "Object not created"
  end
  
  
end