from binascii import hexlify, unhexlify
from Crypto.Cipher import *
from Crypto import Random
import base64

import ConfigParser
from optparse import OptionParser
import os
import sys
import getpass
import re
import subprocess
import textwrap

def enc(key, data):
  key_size = 16
  block_size = 8
  iv_size = 8
  mode = Blowfish.MODE_CBC
  key += (key_size - len(key) % key_size) * chr(key_size - len(key) % key_size)
  pad = lambda data: data + (block_size - len(data) % block_size) * chr(block_size - len(data) % block_size)
  data = pad(data)
  iv = Random.new().read(iv_size)
  cipher = Blowfish.new(key, mode, iv)
  return base64.b64encode(iv + cipher.encrypt(data))

def dec(key, data):
  key_size = 16
  block_size = 8
  iv_size = 8
  mode = Blowfish.MODE_CBC
  key += (key_size - len(key) % key_size) * chr(key_size - len(key) % key_size)
  data = base64.b64decode(data)
  iv = data[:iv_size]
  strippad = lambda data: data[0:-ord(data[-1])]
  cipher = Blowfish.new(key, mode, iv)
  return strippad(cipher.decrypt(data[iv_size:]))

parser = OptionParser()
parser.add_option("-m", "--message", action="store", dest="message",
                  help="commit & issue message", default=None, metavar="MESSAGE")
parser.add_option("-g", "--github_issues", action="store", dest="issues",
                  help="Pivotal Tracker stories involved with commit", default=None, metavar="ISSUES")
parser.add_option("-c", "--codereview_issue", action="store", dest="issue",
                  help="if set, will publish as a patch-set to issue", default=None, metavar="ISSUE")

(options, args) = parser.parse_args()
message = options.message
if message is not None:
  if (message.startswith('"') and message.endswith('"')) or (message.startswith("'") and message.endswith("'")): message = message[1:-1]
issues = options.issues
issue = options.issue

# Error out if we aren't in a repo
if os.system('git rev-parse 2> /dev/null') != 0:
  print "Error: You must be in a valid Git repository!"
  sys.exit()

# Or find it to store/find some special files
gitdir = ".git"
while not os.path.isdir(gitdir): gitdir = "../" + gitdir
config = ConfigParser.RawConfigParser()
key = getpass.getpass("Enter your system password: ")
if not os.path.isfile(gitdir+"/.ghcr"):
  config.add_section('codereview')
  review_server = raw_input("Enter your CodeReview host (ie: cr.dev.fusi.io): ")
  github_repo = raw_input("Enter the Pivotal Tracker project ID (ie: 1207456): ")
  username = raw_input("Enter your CodeReview username: ")
  password = getpass.getpass("Enter your CodeReview password: ")
  config.set('codereview', 'review_server', review_server)
  config.set('codereview', 'github_repo', github_repo)
  config.set('codereview', 'username', username)
  config.set('codereview', 'password', hexlify(enc(key, password)))

  with open(gitdir+"/.ghcr", 'wb') as configfile:
    config.write(configfile)
else:
  config.read(gitdir+"/.ghcr")
  review_server = config.get('codereview', 'review_server')
  github_repo = config.get('codereview', 'github_repo')
  username = config.get('codereview', 'username')
  password = dec(key, unhexlify(config.get('codereview', 'password')))

if issue is not None:
  if message is None: message = raw_input("Enter a patch-set message: ")
  proc = subprocess.Popen('python ~/.settings/upload.py --assume_yes --server '+review_server+' --email '+username+' --password '+password+' --title "'+message+'" --issue '+issue+' HEAD', stdout=subprocess.PIPE, shell=True)
  (cr_response, err) = proc.communicate()
  try:
    cr_url = re.findall(r"http:\/\/\S+", cr_response)[0]
  except Exception:
    print "Error: Issue uploading to CR, check your network status and credentials!"
  print "Success! Staging published as patch set, view your updated CR at: "+cr_url
  sys.exit()

if message is None: message = raw_input("Enter a Git commit message: ")
if issues is None: issues = raw_input("Enter Pivotal Tracker stories involved, comma seperated: ")
issues = re.findall("\d+", issues)
message = "["+",".join(issues)+"] "+message
proc = subprocess.Popen('python ~/.settings/upload.py --assume_yes --server '+review_server+' --email '+username+' --password '+password+' --title "'+message+'" HEAD', stdout=subprocess.PIPE, shell=True)
(cr_response, err) = proc.communicate()
if err is not None:
  print "Error: Issue uploading to CR, check your network status and credentials!"
  print cr_response
  sys.exit()
try:
  cr_url = re.findall(r"http:\/\/\S+", cr_response)[0]
except Exception:
  print "Error: Issue uploading to CR, check your network status and credentials!"
  sys.exit()
commit_command = 'git commit -m "'+message+'" -m "'+cr_url+'"'
for issue in issues: commit_command += ' -m "https://www.pivotaltracker.com/n/projects/'+github_repo+'/stories/'+issue+'"'
proc = subprocess.Popen(commit_command, stdout=subprocess.PIPE, shell=True)
(commit_response, err) = proc.communicate()
if err is not None:
  print "Error: Issue commiting, do you have anything staged?"
  sys.exit()
print "Success! Type 'git log' to see your new commit, CR available at: "+cr_url
