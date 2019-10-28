+++
title = "Migrating to Hugo and S3"
date = "2018-05-01T20:21:19-06:00"
author = "derek"
cover = ""
tags = ["s3", "aws", "hugo"]
keywords = ["", ""]
description = "When hosting costs have got you down, the only logical thing to do is migrate your entire website. This is my journey from a shared webhost to a static S3 website."
showFullContent = false
+++

#### Background
For many years I was using A Small Orange for my webhosting. The price was great, and it gave me more than enough features to work with. I hosted a number of small sites on my account, this one included. Then a couple of months ago my renewal notice came my price was going up from $50 a year to $86. This was a little too high for me with the relatively low amount of traffic that I got on any of my sites, so I started look at other options. I started with other shared hosts or even some of the smaller VPS hosts, and A Small Orange's rate seemed more and more in line with what I could expect. During this time I was in the middle of getting AWS certified and was looking at the possibilities of using S3. It was an appealing option, but it required a static html website which meant migrating because my now former site ran on a [Ghost](https://ghost.org/) backend. So, I started looking at static website generators. I first found [Jekyll](https://jekyllrb.com/) (which runs all Github pages) and started playing with it. It was very cool, but I had some weird issues getting it working, so I kept looking and found [Hugo](https://gohugo.io/). Hugo solved all the issues I had with Jekyll and within 30 minutes I had a very rough version of my site up and working. I especially liked the fact that I didn't have to setup a Ruby environment to compile; Hugo is a single binary you run from the site directory and you are done.

#### Migrating
I spent a couple of hours tweaking the theme I found to my liking, and then it was time to migrate the content from Ghost to Hugo. This was relatively straight forward. Ghost and Hugo both use Markdown as the format you write your posts in, so I went into Ghost and did an export of all content which gave me a single JSON file with everything inside. Hugo uses a different header in the markdown file. Ghost stores all the header information in it's own database. Hugo doesn't do any of that instead opting to parse the markdown into the predefined templates, so it requires a header of what each file is at the top. This is the header I used on this post
```
---
title: "Migrating to Hugo and S3"
date: 2018-05-01T22:21:19-06:00
draft: false
type: "post"
author: "derek"
summary: "When hosting costs have got you down, the only logical thing to do is migrate your entire website. This is my journey from a shared webhost to a static S3 website."
tags: ["s3", "aws", "hugo"]
---
```
The entire header starts and ends with <code>---</code>. Then each field is used to define what it is. The summary is a field I added to add a custom summary to the front page. I regert the way I exported from Ghost purely because the entire markdown was a single line, so it took longer to reformat it, than it would have to copy it from the Ghost editor, but highsight is 20/20.

After I had all my content migrated, and the theme modifications complete. I thought I was ready to go. Running my site using <code>hugo server -d</code> all the links worked, the posts looked good, so I went and uploaded it to my S3 bucket. After turning on static site, and setting my bucket policy to 
```
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "PublicReadGetObject",
            "Effect": "Allow",
            "Principal": "*",
            "Action": "s3:GetObject",
            "Resource": "arn:aws:s3:::www.derekreinhardt.com/*"
        }
    ]
}
```
I navigated to the URL and it didn't work. Now this may not be a problem with S3, but I could not get my site to work off of relative links. It would also attempt to add the full relative link to the end of the page I was on, which pretty much broke navigation. This required me to set my baseURL in my Hugo <code>config.toml</code> and a few more random locations in templates to make all links full paths. The other issue with this was because S3 has no <code>.htaccess</code> to support cleaner links I had to change all links into any page include <code>index.html</code> at the end. After all this the site was finally working.

#### Cloudfront and HTTPS
When I decided to migrate I decided it was time to convert my site to support HTTPS. The nice thing is that with a site hosted on S3 it's really easy to add HTTPS to a site by using CloudFront in front of the bucket. I created a new Web Distribution using my S3 bucket as the origin. As a note, if you plan on doing this the name of the bucket must match the URL you plan on having visitors go to. You will notice about I granted Public Read to allow objects on the <code>www.derekreinhardt.com</code> bucket. You can find plenty of in depth tutorials on how to configure a S3 bucket behind CloudFront, but the key things to change is the Viewer Protocol Policy, Alternate Domain Names, the SSL Certificate, and the Default Root Object. For Viewer Protocol I changed it to HTTPS only since I only wanted traffic over HTTPS. Alternate Domains are both the naked domain (<code>derekreinhardt.com</code>) and the final URL (<code>www.derekreinhardt.com</code>). If you plan on using your naked domain as the main URL you probably don't need to worry about this. The Default Root Object is the name of the root file, so for me it is <code>index.html</code>. The SSL Certificate requires a bit more work. You need to select Custom SSL Certificate, and then it will take you to a page to request a certificate. For the Domain Name enter both the naked as well as specific or wildcard depending on where you plan on having your site. I entered both <code>derekreinhardt.com</code> and <code>*.derekreinhardt.com</code> since any subdomains I have will also be hosted using AWS. You will have to verify ownership of the domain either through email or a TXT record in your domain registrar. If you don't know how to do the second one the email works pretty well as well. Once ownership is verified Amazon will issue the certificate which happens pretty quickly. You may need to refresh your CloudFront configuration, but when it shows you are basically there. The last step is to take the Distribution domain name and add a CNAME record to the distribution. Since mine is hosted on <code>www.derekreinhardt.com</code> I also added a Redirect from my naked domain to my <code>www.</code> domain. My registrar handles getting the HTTP traffic to <code>http://www.derekreinhardt.com</code> and then CloudFront does the forwarding to <code>https://www.derekreinhardt.com</code>. After that I felt like I had a functional site hosted in S3 using CloudFront for SSL.

#### Updating Content
At this point everything was working great, but in order to add new content I needed to rebuild the site manually and upload it back to S3, which was less than ideal. I wanted to write new content and not have to worry about building and re-uploading it all. I found [this post](https://stackoverflow.com/questions/32530352/best-strategy-to-deploy-static-site-to-s3-on-github-push) on StackOverflow talking about using a commit to Github to trigger a recompile and upload to S3. I liked this idea a lot, so I set up the trigger, and had it successfully trigger a lambda function inside of AWS. I tried looking around to find a function already written to do what I wanted, but none of the ones I looked at worked 100% and also did everything. I ended up sticking a couple functions together to build something that works. When the function is triggered I extract both git and hugo from binaries and do a pull on the repository holding my site. Once the site and modules are downloaded I run Hugo on the repository and copy all the new files from the lambda into the user defined S3 bucket. From here everything should be great. You can look at my function and use it yourself from [my Github](https://github.com/jdreinhardt/hugo_to_s3_lambda/) or if you just want to download the ready to use function it is [here](https://github.com/jdreinhardt/hugo_to_s3_lambda/releases/download/v1.0/lambda_script.zip). You will need to specify the Environment variables GIT_REPO and S3_BUCKET for the function to work.

#### Lessons Learned
While this was a fun project, it was not something I something I would recommend for everyone. Static websites by their very nature are more limited in what they can do. Now that I have it working it has been pretty smooth going, and best of all my AWS bill for my site on S3 using CloudFront for SSL and CDN distribution is less than $0.50 a month. That may go up if I start getting a lot of traffic, but still much more reasonable over my old shared host.