require_relative 'test_helper.rb'

class TestDropbox < Test::Unit::TestCase

  def setup

  end

  def teardown

  end

  def test_connection_and_account
    assert_equal 'tomek.drazek@gmail.com', Dropbox.account['email']
  end

  def test_remote_operations
    tmp_path = File.expand_path("../fixtures/duck.jpg", __FILE__)
    output_1 = File.join(DROPBOX_SPACE_ROOT,'duck-go.jpg')
    output_2 = File.join(DROPBOX_SPACE_ROOT,'Sub', 'duck-go.jpg')
    output_3 = File.join(DROPBOX_SPACE_ROOT,'Sub', 'duck-ab.jpg')
    assert_equal 99445, Dropbox.upload(tmp_path,output_1)['bytes']
    assert_not_nil Dropbox.mv(output_1, output_2)
    assert_not_nil Dropbox.cp(output_2, output_3)
    assert_equal true, Dropbox.rm(File.join(DROPBOX_SPACE_ROOT,'Sub/'))['is_deleted']
  end

  def test_download_upload
    tmp_path = File.expand_path("../fixtures/duck.jpg", __FILE__)
    tmp_out_path = File.expand_path("../fixtures/duck.jpg", __FILE__)
    invalid_path = File.join(DROPBOX_SPACE_ROOT,'goose.jpg')
    output_path = File.join(DROPBOX_SPACE_ROOT, 'duck-out.jpg')
    assert_true File.exists?(tmp_path)
    # Upload the file:
    assert_equal 99445, Dropbox.upload(tmp_path,output_path)['bytes']
    # Check of the file:
    assert_nil Dropbox.find(invalid_path)
    # Download of the file:
    assert_equal 99445, Dropbox.download(output_path,tmp_out_path)['bytes']
    # Removal of the file and folder:
    assert_nil Dropbox.rm(invalid_path, false)
    assert_nil Dropbox.rm(invalid_path)
    assert_equal true, Dropbox.rm(output_path)['is_deleted']
  end


end
