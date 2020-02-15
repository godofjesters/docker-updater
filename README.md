# docker-updater
bash script to update all docker containers on your computer (JQ REQUIRED INSTALL)

I'm a beginning scripter and programmer so this is just something I felt was a needed project. Any feedback, please email to jestergod+docup@digital-dreamer.org

This is a simple script for keeping your docker containers up to date.

The script will stop the containers, store the different flags that they were created with temporarily, remove the container, pull a new copy, start it back up and finally prune the list to remove old images.

This script was written with JQ installed and using JQ commands. Someone with a better handle of bash and breaking down JSON style config files are welcome to modify this to suit their needs.
