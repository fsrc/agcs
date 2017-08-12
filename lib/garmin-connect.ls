# Dependencies
# #############################################
require! {
  https: { request }
  'prelude-ls': { keys, obj-to-pairs, map, join }
  axios
  '@3846masa/axios-cookiejar-support' : axios-cookie-jar-support
  'tough-cookie' : tough
  querystring
  fs : { write-file }
  'async-ls' : { callbacks }
}
{ serial-map } = callbacks
axios-cookie-jar-support(axios)
cookie-jar = new tough.CookieJar()
axios.defaults.jar = cookie-jar
axios.defaults.with-credentials = true
# #############################################

# Alias
# #############################################
say = console.log
# #############################################

# Helpers
# #############################################
format-query = (query) ->
  query
    |> obj-to-pairs
    |> map (pair) -> pair.join('=')
    |> join('&')
# #############################################

# URL and queries
# #############################################
query-login = ->
  format-query(
    'service'                         : 'https%3A%2F%2Fconnect.garmin.com%2Fpost-auth%2Flogin'
    'webhost'                         : 'olaxpw-connect04'
    'source'                          : 'https%3A%2F%2Fconnect.garmin.com%2Fen-US%2Fsignin'
    'redirectAfterAccountLoginUrl'    : 'https%3A%2F%2Fconnect.garmin.com%2Fpost-auth%2Flogin'
    'redirectAfterAccountCreationUrl' : 'https%3A%2F%2Fconnect.garmin.com%2Fpost-auth%2Flogin'
    'gauthHost'                       : 'https%3A%2F%2Fsso.garmin.com%2Fsso'
    'locale'                          : 'en_US'
    'id'                              : 'gauth-widget'
    'cssUrl': 'https%3A%2F%2Fstatic.garmincdn.com%2Fcom.garmin.connect%2Fui%2Fcss%2Fgauth-custom-v1.1-min.css'
    'clientId'                        : 'GarminConnect'
    'rememberMeShown'                 : 'true'
    'rememberMeChecked'               : 'false'
    'createAccountShown'              : 'true'
    'openCreateAccount'               : 'false'
    'usernameShown'                   : 'false'
    'displayNameShown'                : 'false'
    'consumeServiceTicket'            : 'false'
    'initialFocus'                    : 'true'
    'embedWidget'                     : 'false'
    'generateExtraServiceTicket'      : 'false')

query-search = (start, limit) -> format-query(start:start, limit:limit)

url-login             = -> "https://sso.garmin.com/sso/login?#{query-login!}"
url-authenticate      = (ticket) -> "https://connect.garmin.com/post-auth/login?ticket=#{ticket}"
url-search            = (start, limit) -> "https://connect.garmin.com/proxy/activity-search-service-1.2/json/activities?#{query-search(start, limit)}"
url-gpx-activity      = (activity-id) -> "https://connect.garmin.com/modern/proxy/download-service/export/tcx/activity/#{activity-id}"
url-tcx-activity      = (activity-id) -> "https://connect.garmin.com/modern/proxy/download-service/export/tcx/activity/#{activity-id}"
url-original-activity = (activity-id) -> "https://connect.garmin.com/modern/proxy/download-service/files/activity/#{activity-id}"
# #############################################

# Regexes
# #############################################
regex-login-ticket = /ticket=([^\"]+)\"/
# #############################################

# create client
# #############################################
export create-client = -> axios
  # cookie-jar = new CookieJar()
  # axios-create-client(
  #   jar              : cookie-jar
  #   with-credentials : true
  #   headers          :
  #     'User-Agent': 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/1337 Safari/537.36')


# fetch login page
# #############################################
export fetch-login = (client, callback) ->
  client.post(url-login!)
    .then((response) -> callback(null))
    .catch((error) -> callback(error))

# login to garmin sso
# #############################################
export login = (client, username, password, callback) ->
  post-data =
    username              : username
    password              : password
    embed                 : \false
    lt                    : \e1s1
    _event-id             : \submit
    display-name-required : \false

  client.post(url-login!, querystring.stringify(post-data))
    .then((response) ->
      login-response = response.data
      if login-response.includes('Login Successful')
        ticket-match = login-response.match(regex-login-ticket).1
        callback(null, ticket-match)
      else
        callback('Login failed'))

    .catch((error) -> callback(error))

# transfer authentication to connect.garmin.com
# #############################################
export authenticate = (client, ticket, callback) ->
  client.post(url-authenticate(ticket))
    .then((response) -> callback(null, client))
    .catch((error) -> callback(error))

# get list of activities from garmin
# #############################################
export get-activities-list = (client, start, limit, callback) ->
  client.get(url-search(start, limit))
    .then((response) -> callback(null, {
      count: response.data.results.total-found
      activities: map((.activity), response.data.results.activities) }))
    .catch((error) -> callback(error))

# get a list of all activities
# #############################################
export get-all-activities-list = (client, callback) ->
  (err, result) <- get-activities-list(client, 0, 100)
  callback(err, result)

# download activity
# #############################################
export get-activity = (client, pre, post, activity-id, callback) -->
  pre(activity-id) if pre?

  client.get(url-tcx-activity(activity-id))
    .then((response) ->
      post(activity-id, response.data) if post?
      callback(null, response))
    .catch((error) -> callback(error))

# store activities list
# #############################################
export store-activities-list = (path, data, callback) -->
  (err) <- write-file("#{path}/activities-list.json", JSON.stringify(data, null, 2), encoding:\utf8)
  say "Activity list stored: #{path}/activities-list.json" unless err?
  callback(err)

# store activity
# #############################################
export store-activity = (output-directory, activity-id, data, callback) ->
  (err) <- write-file("#{output-directory}/#{activity-id}.tcx", data, encoding:\utf8)
  say "Activity stored: #{output-directory}/#{activity-id}.tcx" unless err?
  callback(err)

# automate login, downloading and storing of all activities
# not allready downloaded
# #############################################
export automation = (bail-if-err, username, password, start, limit, output-directory, callback) ->
  # Create a new client that we can use for our requests
  client = create-client!

  # Make a dummy request to login page so that we get a session
  (err) <- fetch-login(client)
  bail-if-err(err, "Could not fetch login page")
  say "Login page loaded"

  # Login to garmin sso
  (err, ticket) <- login(client, username, password)
  bail-if-err(err, "Could not post to login page")
  say "SSO authenticated"

  # Transfer authentication to garmin connect
  (err) <- authenticate(client, ticket)
  bail-if-err(err, "Could not authenticate on garmin connect")
  say "SSO transfered to connect.garmin.com"

  # Get all activities
  (err, activities-list) <- get-activities-list(client, start, limit)
  bail-if-err(err, "Could not download activities list")
  say "Activities list is downloaded"

  # Store the list of activities in a file
  (err) <- store-activities-list(output-directory, activities-list)
  bail-if-err(err, "Could not store activities list")
  say "Activities list is stored in #{output-directory}"
  activities-ids = map((.activity-id), activities-list.activities)

  # For each activity this will be executed before each download starts
  pre-get-activity = (activity-id) ->
    say "Downloading activity ##{activity-id}"

  # For each activity this will be executed after each download is finished
  post-get-activity = (activity-id, data) ->
    (err) <- store-activity(output-directory, acivitity-id, data)
    say err if err?
    say "Done with ##{activity-id}" if not err?

  # Download all activities
  (err, activity) <- serial-map(get-activity(client, pre-get-activity, post-get-activity), activities-ids)
  bail-if-err(err, "Could not download activity")

  # Inform caller that we are done
  callback!



