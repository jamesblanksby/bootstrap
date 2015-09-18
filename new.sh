#! /bin/bash

NC="\033[0m"
BOLD="\033[1m";
ERROR="\033[41;97m";
WHITE="\033[0;97m";
RED="\033[0;31m";
BLUE="\033[0;34m";
YELLOW="\033[0;33m";

PROJECT=${PWD##*/};
REPO_REMOTE="deploy";
SSH_USER="";
SSH_HOST="";

DIR_LOCAL=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd );
DIR_REMOTE="/var/www/html";

echo -e "$YELLOW                _          ";
echo "  ___ _ _  __ _(_)_ _  ___ ";
echo " / -_) ' \/ _\` | | ' \/ -_)";
echo " \___|_||_\__, |_|_||_\___|";
echo "          |___/            ";
echo -e "$NC";

read -p "name ($PROJECT): " PROJECT_2;
while [[ $SSH_USER = "" ]]; do
	read -p "ssh user: " SSH_USER;
done;
while [[ $SSH_HOST = "" ]]; do
	read -p "ssh host: " SSH_HOST;
done;
read -p "remote repo name ($REPO_REMOTE): " REPO_REMOTE_2;

if [[ $PROJECT_2 != "" ]];
	then
	PROJECT=$PROJECT_2;
fi;

if [[ $REPO_REMOTE_2 != "" ]];
	then
	REPO_REMOTE=$REPO_REMOTE_2;
fi;

echo -e "$YELLOW$BOLD";
echo -e "Initialising ...";
echo -e "$NC";

echo -ne "> Checking SSH connection";
CONNECTION=$(ssh -o BatchMode=yes -o ConnectTimeout=5 $SSH_USER@$SSH_HOST echo ok 2>&1);
if [[ $CONNECTION == "ok" ]];
	then
	echo -e "  ${BLUE}[Done]${NC}";
else
	echo -e "  ${RED}[Fail]${NC}";
	exit;
fi;

echo -ne "> Checking for unique project on $SSH_HOST";
ssh -q $SSH_USER@$SSH_HOST [[ -d "$DIR_REMOTE/$PROJECT" ]] && echo -e "  ${RED}[Fail]${NC}" && exit || echo -e "  ${BLUE}[Done]${NC}";

echo -ne "> Creating local git repository";
git init --quiet;
echo -e "  ${BLUE}[Done]${NC}";

echo -ne "> Checking if remote branch exists";
if ! git remote | grep $REPO_REMOTE >/dev/null;
	then
	echo -e "  ${BLUE}[Done]${NC}";

	echo -ne "> Creating remote branch";
  	git remote add $REPO_REMOTE ssh://$SSH_USER@$SSH_HOST$DIR_REMOTE/$PROJECT/$PROJECT.git;
  	echo -e "  ${BLUE}[Done]${NC}";
else
	echo -e "  ${BLUE}[Done]${NC}";
fi;

ssh $SSH_USER@$SSH_HOST /bin/bash <<- EOL
	cd /;

	echo -ne "> Creating remote project directory";
	cd $DIR_REMOTE;
	mkdir -p $PROJECT;
	cd $PROJECT;
	echo -e "  ${BLUE}[Done]${NC}";

	echo -ne "> Creating remote git repository";
	mkdir -p "$PROJECT.git";
	cd "$PROJECT.git";
	git init --bare --quiet;
	echo -e "  ${BLUE}[Done]${NC}";

	echo -ne "> Setting up git deployment hook";
	cd hooks;
	touch post-receive;
	echo "#! /bin/bash" >> post-receive;
	echo "git --work-tree=$DIR_REMOTE/$PROJECT --git-dir=$DIR_REMOTE/$PROJECT/$PROJECT.git checkout -f;" >> post-receive;
	echo "cd $DIR_REMOTE/$PROJECT;" >> post-receive;
	echo "[[ -f composer.json ]] && composer update;" >> post-receive;
	chmod +x post-receive;
	echo -e "  ${BLUE}[Done]${NC}";
EOL

echo -e "$YELLOW$BOLD"
echo "*** Project created successfully ***";
echo -e "$NC";

if [ -d "$DIR_LOCAL" ]
	then
		open $DIR_LOCAL;
else
	echo -e "$ERROR Cannot open $DIR_LOCAL because it does not exist $NC";
	echo -e "";
fi
