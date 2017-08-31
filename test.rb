#
# citizentools - API fuer Star Citizen
#
# Copyright 2017 marcus@dankesuper.de
#
# This file is part of citizenzools.

# citizenzools is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# citizenzools is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with citizenzools.  If not, see <http://www.gnu.org/licenses/>.

require "json"
require "minitest/autorun"
require "open-uri"

class TestVakss < Minitest::Test

  def setup
    citizen_json = open('http://localhost:4567/api/v2/citizen/perry_hope').read
    @citizen = JSON.parse(citizen_json)
    org_json = open('http://localhost:4567/api/v2/org/ihope').read
    @org = JSON.parse(org_json)
  end

  # test /citizen

  def test_citizen_moniker_is_perry_hope
    assert_equal "Perry Hope", @citizen["moniker"]
  end

  def test_citizen_record_is_635841
    assert_equal "635841", @citizen["citizen_record"]
  end

  def test_citizen_enlisted_is_20141030
    assert_equal "20141030", @citizen["enlisted"]
  end

  def test_citizen_fluency_is_german_english_turkish
    assert_equal ["German", "English", "Turkish"], @citizen["fluency"]
  end

  def test_citizen_orgs_is_ioh_pakt_avocado_gadvocacy_oppf
    assert_equal [
      {
        "org" => "Isle of Hope",
        "sid" => "IHOPE",
        "type" => "main"
      },
      {
        "org" => "Protection Alliance - Knights of Terra",
        "sid" => "PAKT",
        "type" => "affiliate"
      },
      {
        "org" => "Evocati - NDA",
        "sid" => "AVOCADO",
        "type" => "affiliate"
      },
      {
        "org" => "German Advocacy",
        "sid" => "GADVOCACY",
        "type" => "affiliate"
      },
      {
        "org" => "Operation Pitchfork",
        "sid" => "OPPF",
        "type" => "affiliate"
      }
    ] , @citizen["orgs"]
  end

  # test /org

  def test_org_name_is_isle_of_hope
    assert_equal "Isle of Hope", @org["name"]
  end

  def test_org_members_is_number
    assert_match /\d+/, @org["members"]
  end

  def test_org_archetype_is_corporation
    assert_equal "Corporation", @org["archetype"]
  end

  def test_org_primary_activity_is_social
    assert_equal "Social", @org["primary_activity"]
  end

  def test_org_secondary_activity_is_security
    assert_equal "Security", @org["secondary_activity"]
  end

  def test_org_commitment_is_regular
    assert_equal "Regular", @org["commitment"]
  end

  def test_org_roleplay_is_no
    assert_equal "No", @org["roleplay"]
  end

  def test_org_membership_is_exclusive
    assert_equal "Exclusive", @org["exclusive_membership"]
  end

  def test_org_logo_is_ihope
    assert_match "IHOPE-Logo.png", @org["logo"]
  end

end
