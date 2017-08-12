# AGCS
Another Garmin Connect Scraper connects to connect.garmin.com and downloads one or more acitivites stored on the site. This makes is possible for you to more easily extract your tracked activities for other usage. The code is written in LiveScript for Node.JS and is tested with node 8.2.1.

## Getting started
Follow these instructions to get it up and running. 

### Prerequisites
You will need node.js `version 8.2.1` - I won't give you the instructions to install that here.

### Installing
For CLI usage: `npm install -g`

For module usage: `npm install --save agcs`

And require the agcs module like so `agcs = require("agcs")`

## Running the tests
.. no tests to be found

## Documentation

### Using from CLI

    agcs --help

### Using from code
The code is written in LiveScript so the function names are written in LiveScript naming convention. However, the corresponding JavaScript names are written within parenteses.

#### create-client (createClient)
Creates a axios client with a cookie jar that you need to pass to other functions.

#### fetch-login (fetchLogin)
Requests the login page and fills the cookie jar with session cookie and other stuff that sso.garmin.com requires.

#### login (login)
Posts your username and password to sso.garmin.com and login your session.

#### authenticate (authenticate)
Transfers the sso.garmin.com session to connect.garmin.com by posting a ticket fetched from the login post to the connect.garmin.com site.

#### get-activities-list (getActivitiesList)
Downloads a JSON object with the activities within the span you've chosen.

#### get-all-activities-list (getAllActivitiesList)
Downloads a JSON object with all the activities in the account.

#### get-activity (getActivity)
Downloads a single activity.

#### store-activities-list (storeActivitiesList)
Writes the JSON object with the activities list to file (activities-list.json).

#### store-activity (storeActivity)
Writes the activity data to a file.

#### automation (automation)
Does everything that you would normally want to do to have all your activities downloaded.


