# Setting it up

1. Install RVM and ruby 2.3.1

   ```shell
   rvm use 2.3.1
   ```

2. Create a gemset for rvm called `abstract-fs` using 2.3.1 installed:

   ```shell
   rvm create gemset abstract-fs
   ```

3. Connect to own dropbox account (this used be done over API v1 with https://github.com/dropbox/dropbox-sdk-ruby, but its not longer valid. You need to find a way to process it with API v2.

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

   ```

   ​

## Testing

There are now two tests:

1. `dropbox_test.rb` is pure API test over the abstraction layer
2. `cloud_test.rb` test compatiblity remote versus local storage (to be extended)

There should be one more test to add, that ensures the API can survive multithreaded operations, while multiple queries are running at the same time. Some libraries failed to pass this, unfortunately there is no testing routine written for that yet. 