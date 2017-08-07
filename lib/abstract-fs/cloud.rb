# THis is cloud storage modification of the file systems to make a hybrid filesystem, that integartes
# Dropbox live synched foldes - commands are passed to the dropbox directly
#
require_relative 'filesys.rb'
require_relative 'dropbox.rb'
require_relative 'localfs.rb'

module Cloud

  module_function

  extend CloudFileSysBase

  def normalize_path(cloud_path)
    CloudFileSysBase.normalize_path(cloud_path)
  end

  def sub_path_of(path,base)
    CloudFileSysBase.sub_path_of(path,base)
  end

  def remote?(cloud_path)
    cloud_path = normalize_path(cloud_path)
    if match = CLOUD_CONFIG.find { |k,v| cloud_path.downcase.start_with?(normalize_path(k).downcase) }
      match[1] == :dropbox
    else
      false
    end
    # CLOUD_CONFIG.each
  end

  def download(cloud_path,local_path)
    if remote?(cloud_path)
      Dropbox.download(cloud_path,local_path)
    else
      LocalFS.download(cloud_path,local_path)
    end
  end

  def upload(local_path, cloud_path)
    if remote?(cloud_path)
      Dropbox.upload(local_path,cloud_path)
    else
      LocalFS.upload(local_path,cloud_path)
    end
  end

  def find(cloud_path)
    if remote?(cloud_path)
      Dropbox.find(cloud_path)
    else
      LocalFS.find(cloud_path)
    end
  end

  def cp(cloud_src_path,cloud_dst_path, overwrite = true)
    if remote?(cloud_src_path) && remote?(cloud_dst_path)
      Dropbox.cp(cloud_src_path,cloud_dst_path, overwrite)
    elsif !remote?(cloud_src_path) && !remote?(cloud_dst_path)
      LocalFS.cp(cloud_src_path,cloud_dst_path, overwrite)
    elsif remote?(cloud_src_path) # and local cloud_dst_path
      Dropbox.download(cloud_src_path, LocalFS.path2local(cloud_dst_path))
      LocalFS.find(cloud_dst_path)
    else
      Dropbox.upload(LocalFS.path2local(cloud_src_path), cloud_dst_path)
    end
  end

  def mv(cloud_src_path,cloud_dst_path, overwrite = true)
    if remote?(cloud_src_path) && remote?(cloud_dst_path)
      Dropbox.mv(cloud_src_path,cloud_dst_path, overwrite)
    elsif !remote?(cloud_src_path) && !remote?(cloud_dst_path)
      LocalFS.mv(cloud_src_path,cloud_dst_path, overwrite)
    elsif remote?(cloud_src_path)
      if Dropbox.download(cloud_src_path, LocalFS.path2local(cloud_dst_path))
        Dropbox.rm(cloud_src_path)
      end
      LocalFS.find(cloud_dst_path)
    else
      ret = if Dropbox.upload(LocalFS.path2local(cloud_src_path), cloud_dst_path)
        LocalFS.rm(cloud_src_path)
      end
      ret
    end
  end

  def rm(cloud_path, notify_on_missing = true)
    if remote?(cloud_path)
      Dropbox.rm(cloud_path, notify_on_missing)
    else
      LocalFS.rm(cloud_path, notify_on_missing)
    end
  end

  def dl(cloud_path)
    if remote?(cloud_path)
      Dropbox.dl(cloud_path)
    else
      LocalFS.dl(cloud_path)
    end
  end

  def thb(cloud_path, size)
    if remote?(cloud_path)
      Dropbox.thb(cloud_path, size)
    else
      LocalFS.thb(cloud_path, size)
    end
  end

  def mkdir(cloud_path)
    if remote?(cloud_path)
      Dropbox.mkdir(cloud_path)
    else
      LocalFS.mkdir(cloud_path)
    end
  end
end
