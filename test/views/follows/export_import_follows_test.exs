defmodule Bonfire.UI.Social.Graph.ExportImportFollowsTest do
  use Bonfire.UI.Social.Graph.ConnCase, async: true

  alias Bonfire.Social.Graph.Follows
  alias Bonfire.Social.Graph.Import

  setup do
    account = fake_account!()
    me = fake_user!(account)

    conn = conn(user: me, account: account)

    {:ok, conn: conn, account: account, user: me}
  end

  test "export and then import follows with valid CSV data works", %{user: user, conn: conn} do
    # Create users to follow
    followee1 = fake_user!("Followee1")
    followee2 = fake_user!("Followee2")

    # Create initial follows
    assert {:ok, _follow1} = Follows.follow(user, followee1)
    assert {:ok, _follow2} = Follows.follow(user, followee2)

    # Verify follows exist
    assert Follows.following?(user, followee1)
    assert Follows.following?(user, followee2)

    # Test export via controller
    Logger.metadata(action: info("export follows via controller"))

    conn =
      conn
      |> assign(:current_user, user)
      |> get("/settings/export/csv/following")

    assert conn.status == 200
    assert get_resp_header(conn, "content-type") == ["text/csv; charset=utf-8"]

    # Write exported CSV to file
    csv_path = "/tmp/test_exported_follows.csv"
    File.write!(csv_path, conn.resp_body)

    # Create a new user to test import
    import_user = fake_user!("ImportUser")

    # Verify new user has no follows initially
    refute Follows.following?(import_user, followee1)
    refute Follows.following?(import_user, followee2)

    Logger.metadata(action: info("import exported CSV"))

    # Import the exported CSV
    assert %{ok: 2} = Import.import_from_csv_file(:following, import_user.id, csv_path)

    assert %{success: 2} = Oban.drain_queue(queue: :import)

    # Verify follows were imported correctly
    assert Follows.following?(import_user, followee1)
    assert Follows.following?(import_user, followee2)

    File.rm(csv_path)
  end

  test "import follows handles invalid CSV data gracefully", %{user: user} do
    # Create invalid CSV file
    csv_path = "/tmp/test_invalid_follows.csv"
    invalid_content = "Account address\ninvalid_url\nnot_a_url_at_all\n"
    File.write!(csv_path, invalid_content)

    Logger.metadata(action: info("import invalid CSV"))

    # Import should handle errors gracefully
    # assert %{ok: 2} = 
    Import.import_from_csv_file(:following, user.id, csv_path)

    assert %{discard: 2} = Oban.drain_queue(queue: :import)

    File.rm(csv_path)
  end

  test "import follows with mixed valid/invalid CSV data", %{user: user} do
    # Create user to follow
    followee = fake_user!("ValidFollowee")

    # Create CSV with mixed valid and invalid data
    csv_path = "/tmp/test_mixed_follows.csv"

    mixed_content = """
    Account address
    #{Bonfire.Me.Characters.character_url(followee)}
    invalid_url
    not_a_url
    """

    File.write!(csv_path, mixed_content)

    Logger.metadata(action: info("import mixed CSV"))

    # Verify no follows exist initially
    refute Follows.following?(user, followee)

    # Import should handle partial success
    # %{ok: 1, error: 2} = 
    Import.import_from_csv_file(:following, user.id, csv_path)

    assert %{success: 1, discard: 2} = Oban.drain_queue(queue: :import)

    # Valid entry should be imported
    assert Follows.following?(user, followee)

    File.rm(csv_path)
  end
end
