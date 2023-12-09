#!/bin/bash
echo -e "\e[34mSending release/0.0.2\e[0m"
echo -e "\e[33m  Release steps\e[0m"
echo -e "\e[35m   Commit current branch: \e[33m[release/0.0.2]\e[0m"
echo -e "\e[33m      - git add .\e[0m"
git add .
echo -e "\e[33m      - git commit -am '[release/0.0.2] news changes' -q\e[0m"
git commit -am '[release/0.0.2] news changes' -q
echo -e "\e[33m      - git push origin release/0.0.2 -q\e[0m"
git push origin release/0.0.2 -q
echo -e "\e[35m   Merge release branch \e[33m[release/0.0.2]\e[35m to \e[33m[master]\e[0m"
echo -e "\e[33m      - git pull origin master -q\e[0m"
git pull origin master -q
echo -e "\e[33m      - git checkout master -q\e[0m"
git checkout master -q
echo -e "\e[33m      - git merge release/0.0.2 -q\e[0m"
git merge release/0.0.2 -q
echo -e "\e[33m      - git push origin master -q\e[0m"
git push origin master -q
echo -e "\e[35m   Checkout to current branch \e[33m[release/0.0.2]\e[0m"
echo -e "\e[33m      - git checkout -B release/0.0.2 -q\e[0m"
git checkout -B release/0.0.2 -q
