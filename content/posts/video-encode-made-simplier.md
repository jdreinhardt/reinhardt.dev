---
title: "Video Encoding Made Simplier"
date: 2014-07-11T02:18:59.000Z
draft: false
type: "post"
author: "derek"
summary: "FFmpeg allows for ProRes to be generated on a Windows machine freeing the need for a Mac, but it lives in the command line out of reach of many. While not as feature rich as others may be I make the encode as simple as possible so that video encoding can be simple."
tags: ["prores", "encode", "ffmpeg"]
---

I'm proud to announce that I have completed the next version on a pet project I have been working on for a long time. I haven't been working on it non-stop, in fact it sat for a couple of years, but either way it is now here, better than ever.

What is it you ask? A ProRes and H.265 encoder for Windows. I call it Frost.

![Frost Main](https://www.derekreinhardt.com/files/images/frost/frost12main.png)

You can download it at https://www.derekreinhardt.com/frost or https://bitbucket.org/MylarShoe/frost/downloads/

While most codecs can be played on any platform given the right player not all codecs can be written (made) on every platform. The most notorious in the film world is Apple's ProRes codec family which can be played on Windows and Mac, but only created on a Mac. That was until January of 2012 when the open-sourced project [FFmpeg](http://ffmpeg.org) added support for the format. That was a great day finally people were not limited to which operating system they used if they wanted to make ProRes files. 

The way that FFmpeg works is that it is all command-line based, so if you wanted to use FFmpeg to make a file you had to be able to understand something like this
```
ffmpeg -i input.mov -vcodec prores -profile apcn -acodec copy -dcodec copy output.mov
```
which is just the simple input parameters for rendering to ProRes. That makes it not as user-friendly for people not as technically savvy. So, that is when I started developing Frost.

Frost acts as a sort of middle man taking the files you give it, and sending them through FFmpeg to give you a wonderful ProRes or H.265 file for you to use as you wish. It keeps everything self contained though, so once you have Frost set up, all you have to do is push start and you can watch your render happening in real-time at the bottom of the program.

In the beginning all it was was little more than a batch file creator that was then run, and did the renders. It also, was not the most attractive piece of software.

![Frost Old Main](https://www.derekreinhardt.com/files/images/frost/frost01main.png)

It did get the job done though. I got through a couple versions of "old" Frost and just let it sit. I hadn't structured the code very well, so it was hard to build it out. Because of that it had some serious restrictions, the first coming to mind is that it only allowed other .mov files to be rendered. And so it sat.

Then almost two years later (now 2014) I decided to try and fix it. I have a little more programming experience, and I was between jobs, so it just seemed like the right time to do it. When I started looking at my old code I remembered why I had stopped trying to fix it, it was just too clunky. A full rewrite seemed in order, so I began.

The first night I spent a lot of time determining which features I should focus on, which were essential, and how to make the program powerful without being overbearing. I knew that I wanted it to be more tightly integrated with FFmpeg than it was the first time around, so I started coding. The first challenge I realized was that making the back-end for something like this (where the actually lifting and rendering happens) is hard to do, not at the same time as the actual interface. I actually had the interface fully functional before I had the rendering working right. It all works now though, so no worries.

While I was working I decided that I would through in the settings for rendering to H.265 (HEVC) the new codec that is expected to take over for streaming media. Netflix is already using it for their 4K content. Because H.265 is so new there are few if any good interfaces for rendering to it. Once again, FFmpeg built in support last October, so I just had to determine the best flags to get it to work. And even the short version is a doosy.

```
ffmpeg -i input.mp4 -c:v libx265 medium -x265-params crf=22 -c:a copy output.mp4
```

A note to the users. The layout and support for H.265 is still new, so the configurations on the interface are a little clunkier than I'd like, but I'm trying to figure out the best way to condense them.

So now, I've done the full rewrite, and it works great. With the old version it was never able to use the full extents of my CPU for rendering, but with the new version it will use as much processing power as is available, making the renders much faster. It only supports one render at a time right now, but adding support for a render queue is high on the list of features to add.

It is still very much an early version, so I want you to tell me what I should add to it, to make it the most useful for you. Or if you encounter any problems I want to [hear about it](https://www.derekreinhardt.com/contact).

Go to https://www.derekreinhardt.com/frost to download Frost and give it a try. You will need to download a copy of FFmpeg for it to work. But you can do that [here](http://ffmpeg.zeranoe.com/builds). Download the 32-bit or 64-bit Static build. If you aren't sure which one your system supports download the 32-bit to be safe, or the 64-bit to be adventurous. Then copy the ffmpeg.exe file from the bin folder into the folder where you have Frost.exe.