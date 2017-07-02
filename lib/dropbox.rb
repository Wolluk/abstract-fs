require 'dropbox_sdk'

require_relative 'filesys'

module Dropbox
  @@dbx_client = nil

  module_function

  extend CloudFileSysBase

  def filesys_type
    "DBX:".black.on_light_cyan
  end

  def client
    @@dbx_client = @@dbx_client || DropboxClient.new(DROPBOX_TOKEN)
  end

  def account
    client.account_info
  end

  def with_retry(&block)
    tries ||= DROPBOX_NO_OF_RETRIES
    yield
  rescue DropboxError => ex
    if ex.http_response.is_a? Net::HTTPServiceUnavailable
      sleep(DROPBOX_RETRY_DELAY + DROPBOX_NO_OF_RETRIES - tries)
      retry unless (tries -= 1).zero?
    else
      raise ex
    end
  end

  def download(dropbox_path,local_path)
    dropbox_path=normalize_path(dropbox_path)
    log_download(dropbox_path, local_path)
    contents, metadata = with_retry do
      client.get_file_and_metadata(dropbox_path)
    end
    FileUtils.mkdir_p(File.dirname(local_path))
    File.open(local_path, 'w') {|f| f.write(contents) }
    raise "File size mismatch" unless metadata['bytes']==File.size(local_path)
    metadata # small change in API, we have confirmation here also that size match!
  rescue Exception => ex
    error "Download failed: %s." % ex.message
    nil
  end

  def upload(local_path, dropbox_path)
    dropbox_path = normalize_path(dropbox_path)
    log_upload(local_path, dropbox_path)
    file = File.open(local_path)
    uploader = with_retry {  client.get_chunked_uploader(file,file.size) }
    res = nil
    loop do
      res = with_retry { uploader.upload }
      break if res.nil?
    end
    with_retry { uploader.finish(dropbox_path, true) }
  rescue Exception => ex
    error "Upload failed: %s." % ex.message
    nil
  end

  def normalize_path(path)
    path = path.join("/") if path.is_a? Array
    path = path[1..-1] if path[0]=='/'
    path
  end

  def find(dropbox_path)
    dropbox_path = normalize_path(dropbox_path)
    meta = with_retry do
      client.metadata(dropbox_path)
    end
    return nil if meta && meta['is_deleted']
    meta
  rescue Exception => ex
    nil
  end

  def cp(dropbox_src_path,dropbox_dst_path, overwrite = true)
    dropbox_src_path=normalize_path(dropbox_src_path)
    dropbox_dst_path=normalize_path(dropbox_dst_path)
    rm(dropbox_dst_path, false) if overwrite
    log_cp(dropbox_src_path, dropbox_dst_path)
    with_retry do
      client.file_copy(dropbox_src_path, dropbox_dst_path)
    end
  rescue Exception => ex
    error "Copy failed: %s" % ex.message
    nil
  end

  def mv(dropbox_src_path,dropbox_dst_path, overwrite = true)
    dropbox_src_path = normalize_path(dropbox_src_path)
    dropbox_dst_path = normalize_path(dropbox_dst_path)
    rm(dropbox_dst_path, false) if overwrite
    log_mv(dropbox_src_path, dropbox_dst_path)
    with_retry do
      client.file_move(dropbox_src_path, dropbox_dst_path)
    end
  rescue Exception => ex
    error "Move failed: %s." % ex.message
    nil
  end

  def rm(dropbox_path, notify_on_missing = false)
    dropbox_path=normalize_path(dropbox_path)
    log_rm(dropbox_path) unless notify_on_missing
    with_retry do
      client.file_delete(dropbox_path)
    end
  rescue Exception => ex
    nil
  end

  # Direct link
  def dl(dropbox_path)
    with_retry do
      client.media(dropbox_path)
    end
  rescue Exception => ex
    error "URL failed: %s." % ex.message
    nil
  end

  # Thumbnail of the image
  def thb(dropbox_path, size)
    with_retry do
      client.thumbnail(dropbox_path, size)
    end
  rescue Exception => ex
    error "Thumbnail failed: %s." % ex.message
    nil
  end

  def mkdir(dropbox_path)
    with_retry do
      client.file_create_folder(dropbox_path)
    end
  rescue Exception => ex
    error "Make dir failed: %s." % ex.message
    nil
  end
end
