require 'fileutils'
require 'colorize'


module CloudFileSysBase

  module_function

  def filesys_type
    "~".red
  end

  def client
    raise "Client not defined."
  end

  def log(*args)
    args[0] = "[+]".cyan + " " + filesys_type + " " + args[0]
    puts args if DEBUG_NOTIFY_CLOUD
  end

  def log_upload(local_path, dropbox_path)
    log "%s %s -> %s " % [ "up".yellow, local_path.green, dropbox_path.yellow ]
  end

  def log_download(dropbox_path, local_path)
    log "%s %s -> %s " % [ "dl".green, dropbox_path.yellow,  local_path.green ]
  end

  def log_cp(dropbox_src_path, dropbox_dst_path)
    log "%s %s -> %s " % [ "cp".yellow, dropbox_src_path.yellow, dropbox_dst_path.light_yellow ]
  end

  def log_mv(dropbox_src_path, dropbox_dst_path)
    log "%s %s -> %s " % [ "mv".light_yellow, dropbox_src_path.blue, dropbox_dst_path.light_yellow ]
  end

  def log_rm(dropbox_path)
    log "%s %s" % [ "rm".light_red,  dropbox_path.blue ]
  end

  def error(*args)
    args[0] = "[-] %s %s ".light_white.on_red % [ filesys_type().yellow.on_red, args[0].to_s ]
    puts args if DEBUG_ERROR_CLOUD
  end

  def normalize_path(path)
    path = path.join("/") if path.is_a? Array
    path = path[1..-1] if path[0] == '/'
    path
  end

  def sub_path_of(path, base)
    b = base.split('/').map{|k| k.empty? ? nil : k }.compact
    p = path.split('/').map{|k| k.empty? ? nil : k }.compact
    while l = b.shift
      if p[0] && p[0].downcase == l.downcase
        p.shift
      else
        return path
      end
    end
    p.join('/')
  end

end
