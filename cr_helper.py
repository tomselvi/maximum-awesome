import ConfigParser
from optparse import OptionParser
import os
import sys
import getpass
import re
import fcntl, termios, struct, os
import subprocess
import textwrap

def getTerminalSize():
    env = os.environ
    def ioctl_GWINSZ(fd):
        cr = struct.unpack('hh', fcntl.ioctl(fd, termios.TIOCGWINSZ, '1234'))
        return cr
    cr = ioctl_GWINSZ(0) or ioctl_GWINSZ(1) or ioctl_GWINSZ(2)
    if not cr:
        try:
            fd = os.open(os.ctermid(), os.O_RDONLY)
            cr = ioctl_GWINSZ(fd)
            os.close(fd)
        except:
            pass
    if not cr:
        cr = (env.get('LINES', 25), env.get('COLUMNS', 80))

        ### Use get(key[, default]) instead of a try/catch
        #try:
        #    cr = (env['LINES'], env['COLUMNS'])
        #except:
        #    cr = (25, 80)
    return int(cr[1]), int(cr[0])

parser = OptionParser()
parser.add_option("-m", "--message", action="store", dest="message",
                  help="commit & issue message", default=None, metavar="MESSAGE")

(options, args) = parser.parse_args()
(width, height) = getTerminalSize()
message = options.message
if message is not None:
  if (message.startswith('"') and message.endswith('"')) or (message.startswith("'") and message.endswith("'")): message = message[1:-1]

# Error out if we aren't in a repo
if os.system('git rev-parse 2> /dev/null') != 0:
  print "Error: You must be in a valid Git repository!"
  sys.exit()

# Or find it to store/find some special files
gitdir = ".git"
while not os.path.isdir(gitdir): gitdir = "../" + gitdir
config = ConfigParser.RawConfigParser()
if not os.path.isfile(gitdir+"/.ghcr"):
  config.add_section('codereview')
  github_repo = raw_input("Enter the Pivotal Tracker project ID (ie: 1207456): ")
  config.set('codereview', 'github_repo', github_repo)
  with open(gitdir+"/.ghcr", 'wb') as configfile:
    config.write(configfile)
else:
  config.read(gitdir+"/.ghcr")
  github_repo = config.get('codereview', 'github_repo')

if message is None: message = raw_input("Enter a Git commit message: ")
issues = raw_input("Enter Pivotal Tracker stories involved, comma seperated: ")
issues = re.findall("\d+", issues)
_message = ""
if len(issues) > 0: _message += "["+",".join(issues)+"] "
message = _message+message
commit_command = 'git commit -m "'+message+'"'
for issue in issues: commit_command += ' -m "https://www.pivotaltracker.com/n/projects/'+github_repo+'/stories/'+issue+'"'
proc = subprocess.Popen(commit_command, shell=True)
(commit_response, err) = proc.communicate()
if err is not None:
  print "="*width
  print "Error: Issue commiting, do you have anything staged?"
  sys.exit()
proc = subprocess.Popen('git review', shell=True)
(cr_response, err) = proc.communicate()
if err is not None:
  print "="*width
  print "Error: Issue uploading to CR, check your network status and credentials!"
  sys.exit()
