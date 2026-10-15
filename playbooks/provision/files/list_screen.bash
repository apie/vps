#!/bin/bash
screen -list
if [ $? -eq 0 ] && [ -z "$STY" ]
then
        echo -n "Attach screen session? (Y/n)"
        #read answer
        if [ "$answer" == "" ] || [ "$answer" != "${answer#[Yy]}" ] ;then
                screen -UraAd
        fi
fi

