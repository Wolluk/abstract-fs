# Cloud Storage Abstraction Layer

## Setting it up

1. Install RVM and ruby 2.3.1

   ```shell
   rvm use 2.3.1
   ```

2. Create a gemset for rvm called `abstract-fs` using 2.3.1 installed:

   ```shell
   rvm gemset create abstract-fs
   ```

3. Connect to own dropbox account (this used be done over API v1 with https://github.com/dropbox/dropbox-sdk-ruby, but it's not longer valid. You need to find a way to process it with API v2.

4. Create a configuration file `config/config.rb`:

   ```ruby
   unless defined? DROPBOX_APP_KEY
     DROPBOX_APP_KEY = 'xxxxxx' # replace with own key
     DROPBOX_APP_SECRET = 'yyyyy' # replace with secret
     DROPBOX_APP_MODE = 'dropbox' 
     DROPBOX_TOKEN = "ttttttt" # replace with token
     DROPBOX_SPACE_ROOT = '/Temp/abstract-fs'
   end

   # Dropbox connection tuning:
   DROPBOX_NO_OF_RETRIES = 20
   DROPBOX_RETRY_DELAY = 1 # sec

   LOCAL_STORAGE = File.absolute_path(__FILE__ + "/../../data")
   CLOUD_DROPBOX = File.join(DROPBOX_SPACE_ROOT, 'Dropbox')

   CLOUD_CONFIG = {
     CLOUD_DROPBOX => :dropbox
   }

   # This allows us to
   DEBUG_ERROR_CLOUD = true
   DEBUG_NOTIFY_CLOUD = true
   DEBUG_CHUNKING = false
   DROPBOX_UL_CHUNK_SIZE = 1024 * 1024 # 1 MiB

   ```

   ​

## The concept

The adapter makes a common storage space, which integrates with one single storage. All paths are references from the root of the storage. For specific cloud implementation, like a dropbox we provide additional parameter that points to particular subfolder within the storage `DROPBOX_SPACE_ROOT` or for local storage it's `LOCAL_STORAGE` . So this virtual file system maps automatically a path referenced to the appropriate location. 

The `CLOUD_CONFIG` variable specifies which locations (and it's substructures) are allocated to what particular storage type. The default `CLOUD_CONFIG` is to use local storage unless dropbox entries are specified. 

## Testing

There are now two tests:

1. `dropbox_test.rb` is pure API test over the abstraction layer
2. `cloud_test.rb` test compatiblity remote versus local storage (to be extended)

There should be one more test to add, that ensures the API can survive multithreaded operations, while multiple queries are running at the same time. Some libraries failed to pass this, unfortunately there is no testing routine written for that yet.

## Materials & References

https://stackoverflow.com/questions/37563345/dropbox-api-v2-sdk-for-ruby

https://www.dropbox.com/developers/reference/migration-guide

https://rubygems.org/gems/dropbox_api

https://github.com/waits/dropbox-sdk-ruby

https://github.com/Jesus/dropbox_api

https://github.com/futuresimple/dropbox-api - this one failed on multithreading support in the past.

## Goals

1. Port the Dropbox adaptor to the new API, ensure it covers functionality
2. Add a testing routine for multithreaded and multprocess access to test library on larger load and simultaneous  connections.
3. Invent, document and use new authentication methods provided by v2 API (remember, it's a server back-end library so it can work on permanent tokens).
4. Implement the same connector for Amazon S3, Google Drive, Box.com and other API
5. Enrich cloud adapter to support multiple clouds with mutual connectivity such as direct or cached file transfer between S3 and dropbox etc. 
