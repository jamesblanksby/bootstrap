#! /bin/bash

NC="\033[0m"
BOLD="\033[1m";
RED="\033[41;97m";
BLUE="\033[0;34m";
YELLOW="\033[0;33m";

SSH_USER="b";
SSH_HOST="blanks.by";

LOCAL_DIR="/Users/blanksby/Dropbox/Server";

REMOTE_REPO="/var/repo";
REMOTE_DIR="/var/www/blanks.by/public_html";

echo -e "$YELLOW                _          ";
echo "  ___ _ _  __ _(_)_ _  ___ ";
echo " / -_) ' \/ _\` | | ' \/ -_)";
echo " \___|_||_\__, |_|_||_\___|";
echo "          |___/            ";
echo -e "$NC";

if [ -n "$1" ]
	then

		echo "Initialising ...";

		PROJECT=$1;
		if [ -d "$LOCAL_DIR/$PROJECT" ]
			then
				echo -e \\r;
				echo -e "$RED Specified project already exists $NC";
				echo -e \\r;
				exit;
		fi;

		ssh $SSH_USER@$SSH_HOST /bin/bash <<- EOL
			if [ -d "$REMOTE_DIR/$PROJECT" ] && [ -d "$REMOTE_REPO/$PROJECT.git" ]
				then
					echo -e \\r;
					echo -e "$RED Specified project already exists $NC";
					echo -e \\r;
					exit;
			fi
		EOL

		echo -e \\r;
		echo -e "${BLUE}${BOLD}Creating project: $PROJECT$NC"\\r\\n;

		cd /;
		
		echo -ne "Creating local project directory";
		cd $LOCAL_DIR;
		mkdir $PROJECT;
		echo -e "  ${BLUE}[Done]${NC}";
		
		echo -ne "Creating local git repository";
		cd $PROJECT;
		git init --quiet;
		echo -e "  ${BLUE}[Done]${NC}";

		git remote add development ssh://b@blanks.by$REMOTE_REPO/$PROJECT.git;

		rm -rf $LOCAL_DIR/$PROJECT;

		echo -ne "Connecting to $SSH_HOST";

		ssh $SSH_USER@$SSH_HOST /bin/bash <<- EOL
			echo -e "  ${BLUE}[Done]${NC}";

			cd /;

			echo -ne "Creating remote project directory";
			cd $REMOTE_DIR;
			mkdir $PROJECT;
			echo -e "  ${BLUE}[Done]${NC}";

			echo -ne "Creating remote git repository";
			cd $REMOTE_REPO;
			mkdir "$PROJECT.git";
			cd "$PROJECT.git";
			git init --bare --quiet;
			echo -e "  ${BLUE}[Done]${NC}";

			echo -ne "Setting up git deployment hook";
			cd hooks;
			touch post-receive;
			echo "#!/bin/sh" >> post-receive;
			echo "git --work-tree=$REMOTE_DIR/$PROJECT --git-dir=$REMOTE_REPO/$PROJECT.git checkout -f" >> post-receive;
			chmod +x post-receive;
			echo -e "  ${BLUE}[Done]${NC}";

			rm -rf "$REMOTE_REPO/$PROJECT.git" $REMOTE_DIR/$PROJECT;
		EOL

		echo -e "$BLUE$BOLD"
		echo "*** Project created successfully ***";
		echo -e "$NC";

		if [ -d "$LOCAL_DIR/$PROJECT" ]
			then
				open $LOCAL_DIR/$PROJECT;
		else
			echo -e "$RED Cannot open $LOCAL_DIR/$PROJECT because it does not exist $NC";
			echo -e \\r;
		fi
else
	echo -e \\r;
	echo -e "$RED No project name given $NC";
	echo -e \\r;
fi
