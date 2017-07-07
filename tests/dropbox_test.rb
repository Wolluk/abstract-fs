require_relative 'test_helper.rb'

class TestDropbox < Test::Unit::TestCase

  def setup; end

  def teardown; end

  def test_connection_and_account
    assert_not_nil Dropbox.account['email']
  end

  def test_remote_operations
    tmp_path = File.expand_path("../fixtures/duck.jpg", __FILE__)
    output_1 = File.join(DROPBOX_SPACE_ROOT, 'duck-go.jpg')
    output_2 = File.join(DROPBOX_SPACE_ROOT, 'Sub', 'duck-go.jpg')
    output_3 = File.join(DROPBOX_SPACE_ROOT, 'Sub', 'duck-ab.jpg')
    assert_equal 99445, Dropbox.upload(tmp_path, output_1)['bytes']
    assert_not_nil Dropbox.mv(output_1, output_2)
    assert_not_nil Dropbox.cp(output_2, output_3)
    assert_equal true, Dropbox.rm(File.join(DROPBOX_SPACE_ROOT, 'Sub'))['is_deleted']
  end

  def test_download_upload
    tmp_path = File.expand_path("../fixtures/duck.jpg", __FILE__)
    tmp_out_path = File.expand_path("../fixtures/duck.jpg", __FILE__)
    invalid_path = File.join(DROPBOX_SPACE_ROOT, 'goose.jpg')
    output_path = File.join(DROPBOX_SPACE_ROOT, 'duck-out.jpg')
    assert_true File.exist?(tmp_path)
    # Upload the file:
    assert_equal 99445, Dropbox.upload(tmp_path, output_path)['bytes']
    # Check of the file:
    assert_nil Dropbox.find(invalid_path)
    # Download of the file:
    assert_equal 99445, Dropbox.download(output_path, tmp_out_path)['bytes']
    # Removal of the file and folder:
    assert_nil Dropbox.rm(invalid_path, false)
    assert_nil Dropbox.rm(invalid_path)
    assert_equal true, Dropbox.rm(output_path)['is_deleted'] # does not pass due the API change
  end

  def test_meta_data
    tmp_path = File.expand_path("../fixtures/duck.jpg", __FILE__)
    output_path = File.join(DROPBOX_SPACE_ROOT, 'duck-out.jpg')
    assert_equal 99445, Dropbox.upload(tmp_path, output_path)['bytes']
    meta = Dropbox.find(output_path)
    assert_not_nil meta
    assert_equal 99445, meta['bytes']
    assert_equal output_path, meta['path']
    assert_false meta['is_dir']

    assert_true DateTime.now > DateTime.parse(meta['modified'])
    assert_true DateTime.now > DateTime.parse(meta['created'])
    assert_true DateTime.now > DateTime.parse(meta['client_ctime'])
    assert_true DateTime.now > DateTime.parse(meta['client_mtime'])
    assert_equal 'image/jpeg', meta['mime_type']
    assert_not_nil meta['thumb_exists']
    # read_only applies to shared folders only,
    # and always has: https://www.dropbox.com/developers-v1/core/docs#metadata
    # I think this test is incorrect
    assert_false meta['read_only']
  end

  # This is incremental update for web-hook reported changes
  # Web hook reports an update and we read all changed files since last check-up (delta)
  # This API is highly used by the remote hot-folder feature. 
  def test_incremental_update
    client = Dropbox.client
    cursor_pos = nil # Read all changes
    tmp_path = File.expand_path("../fixtures/duck.jpg", __FILE__)
    output_path = File.join(DROPBOX_SPACE_ROOT, 'incr-test', 'duck-out.jpg')
    output_dir = File.join(DROPBOX_SPACE_ROOT, 'incr-test')
    delta = client.delta(cursor_pos, output_dir)
    assert_not_nil delta
    assert_not_nil delta['entries']
    assert_not_nil delta['cursor']
    cursor_pos = delta['cursor']
    assert_equal 99445, Dropbox.upload(tmp_path,output_path)['bytes']
    delta = client.delta(cursor_pos, output_dir) # Read incremental changes only
    assert_not_nil delta
    assert_not_nil delta['entries']
    assert_equal 1, delta['entries'].count
    Dropbox.rm(output_path)
  end
end
