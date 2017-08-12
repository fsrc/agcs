require! {
  './garmin-connect': { automation }
  'yargs'
}
say = console.log

DEFAULT-USERNAME = '$AGCS_USERNAME'
DEFAULT-PASSWORD = '$AGCS_PASSWORD'
DEFAULT-OUTPUT-DIR = '$PWD'

argv = yargs
  .usage("Usage: $0 [options]")
  .option("username",  { alias: 'u' describe: 'Garmin connect username', default: DEFAULT-USERNAME })
  .option("password",  { alias: 'p' describe: 'Garmin connect password', default: DEFAULT-PASSWORD })
  .option("directory", { alias: 'd' describe: 'Output directory', default: DEFAULT-OUTPUT-DIR })
  .option("start",     { alias: 's' describe: 'Start position in activities list', default: '0' })
  .option("limit",     { alias: 'l' describe: 'Number of activities from start position', default: '10' })
  .help()
  .argv

username = argv.username if argv.username?
password = argv.password if argv.password?
directory = argv.directory if argv.directory?
start = parseInt(argv.start) if argv.start?
limit = parseInt(argv.limit) if argv.limit?

username = process.env.AGCS_USERNAME if not username and process.env.AGCS_USERNAME
password = process.env.AGCS_PASSWORD if not password and process.env.AGCS_PASSWORD
directory= process.env.AGCS_PATH if not directory and process.env.AGCS_PATH

bail-if = (condition, msg) ->
  if condition
    say msg
    process.exit(255)

directory = process.env.PWD if directory == DEFAULT-OUTPUT-DIR

bail-if username == DEFAULT-USERNAME , "Username missing. Use --help for more information."
bail-if password == DEFAULT-PASSWORD, "Password missing. Use --help for more information."

# Simplify error handeling with this function
bail-if-err = (err, msg) ->
  if err?
    say err
    say msg
    process.exit(255)

(err) <- automation(bail-if-err, username, password, start, limit, directory)

