---
title: "Perfecting Lazy"
date: 2014-06-22T00:53:42.000Z
draft: false
type: "post"
author: "derek"
summary: "A first attempting at making my onset life easier with python. I decide to automate most of the tedium to free myself to work on other important matters."
tags: ["dit", "python", "automation"]

---

I just finished up work on a production last week. It was a great project that will is in the editing room right now. I had some fun designing the workflow for this project, and I will probably right about it in the future because it was a system that I had never tried before and it worked near flawlessly. Instead of that though I wanted to write about something a little more technical today.

On this latest production I was working as the DIT (Digital Imaging Technician) while on set. While the roles and responsibilities of this position are large and varied, one of the most important tasks is to secure the footage. That means every byte of data that is recorded by the camera, and audio recorder needs to be backed up, verified, and secured. For me typically that means a lot of manual copying and manually verifying everything. It was a long and tedious process, so I decided to try and automate it.

There is a great utility called rsync in the Unix world that does file synchronization. It does a lot more than what I used it for, but for my purposes it was the simpliest method since it comes preinstalled on Mac. Now what I could have done is just have a bunch of rsync commands typed up like this 

<code>rsync -arv --exclude '/01. RAW Assets' /Volumes/BEYOND_RAID/01.\\ Video\\ Assets/ /Volumes/Beyond_BU01/01.\\ Video\\ Assets</code> 

and just copy them into the terminal to run them when I needed, but that allowed for a lot of user error, so I busted out Python. 

Python is a scripted language that allows for fast development, and testing since the code does not need to be compiled before running. Python also has the added benefit of being preinstalled on Mac, so in an environment where I had little access to the internet it made it the obvious solution (And who wants to write this in bash?).

**A disclaimer for the code you are about to look at. It was all written on set, so it is not very optimized, or clean. I was just trying to get it to work correctly as fast as possible.**

Anyway, my first thought was that I should just make it so that it would backup everything to the Shuttle Drives that we are using. Then I don't have to worry, everything makes its way to the backup drive, as long as it makes it onto the main RAID we were using. The raw footage from the camera was already being backed up to the drive using a program that copied and verified everything for me. (We were using a RED Epic for the shoot with DoubleData as the primary data management system). Lets look at where that one started.
```
import os
os.system("rsync -arv --exclude '/01. RAW Assets' /Volumes/BEYOND_RAID/01.\ Video\ Assets/ /Volumes/Beyond_BU01/01.\ Video\ Assets")
os.system("rsync -arv /Volumes/BEYOND_RAID/02.\ Audio\ Assets/ /Volumes/Beyond_BU01/02.\ Audio\ Assets")    
```
Python is really fast, so we load the OS layer 
<code>import os</code>, then call a system function <code>os.system(...)</code> that is the rsync command. Simple and effective. Then I save that file as backup.py and can run it in the terminal like this <code>python backup.py</code> \n\nThat seemed to easy though. With a Mac you can change the extension of the file and make it run on a double click. You have to make a few changes first to the file. You add this <code>#! /usr/bin/env python</code> to the top of your file, save it. Then in terminal run this <code>chmod u+x backup.py</code> After all that just change the .py to .command and I had a fully functional double click and run program that would backup my assets to a secondary drive.

After doing this I had the programming itch, so I decided to see what else I could automate. I started with getting the sound files from the CF card they were recorded to, to the main RAID. 

I knew that every card that came out of the recorder was titled the same thing, so the first thing I did was have it look for the card. If it found it, it started the copy, if not it asked for the drive to be input (sometimes they weren't named right, so it made the automation still work). I also knew that since we were dumping audio with every video dump, that the card numbers should match, but rather than having it look and check for the mag number I just had it add 1 sequentially. Not ideal, but I was writing this while trying to use it, speed was a factor.

After that it goes through the card and copies every .WAV audio file over to the RAID. This one took a little to get right, but once it was working it never gave me an issue.
```
import os, os.path

path = ""
dest = '/Volumes/BEYOND_RAID/02. Audio Assets/01. RAW Audio/Day 11/'
dest_2 = dest.replace(" ","\ ")

if os.path.exists(\"/Volumes/664 CF\"):	
	path = "/Volumes/664 CF "
else:
	path = raw_input("Enter Drive Path: ")
	clean_path = path[:-1].replace("\\","")

card = ""
for dir in os.listdir(dest):
	card = dir
	card_data = card[-2:].replace(" ","")
	card_num = int(card_data) + 1

	dest_folder = dest_2 + "Card\ " + str(card_num)
	mkdir = "mkdir " + dest_folder
	os.system(mkdir)

	for file in os.listdir(clean_path):
		if file.endswith(".wav") or file.endswith(".WAV"):
		cp = "cp -v " + path[:-1] + "/" + file + " " + dest_folder
		os.system(cp)
```

Once I got that working, things become much easier. I could rest assured that everything was copying to where it needed to go, and that I just had to do a quick manual verify to make sure it all was right. It was about this time that someone asked what I was doing. After explaining, he just laughed and said I was perfectly being as lazy as possible. I said I was optimizing.

Again the itch came. We had an Atomos Samurai Blade attached to the camera recording the edit proxies, so using the audio above as a template I adjusted it to copy the proxies to the RAID. I did change it to actually get the mag name though to copy it into a properly labeled folder.
```
for dir in os.listdir(source):
	if dir == "ProjectInformation.txt":
		print ""
	else:
		mag = dir
```
Not pretty, but this searched through and found the folder name of the latest camera mag that had been copied.

After this, I had all these great scripts that worked, but all had to be run one at a time to get them working properly. I could have that, so I made a script that combined all three of those scripts into one file. I tried to clean up my code when I was doing this, so I broke out my copy and folder creator functions. I also added in some colored notation, so that I could see exactly where in the process I was. The other big thing I did was make it so that I didn't have to manually change the day on each destination folder, just once at the beginning of the file. It worked great.

Once I had all this working, I was free to spend less time focusing on copying files, and more time making sure those files where perfect and verified.

I was free, but I had one last thing I could simplify for myself. At the begining of each day I had to make a bunch of folders for the day, so that everything went where it could easily be found, so I did a quick script that made all those folders for me. 

I know this was long and program-y, but thanks for sticking with it. I promise not everything will be like this. I just wanted to document this process for myself. Below is a link to download a ZIP file with all the scripts, so you can look them over, or use them if you want.

[Download all the Scripts Here](https://dl.dropboxusercontent.com/u/6910936/blog/Scripts.zip)