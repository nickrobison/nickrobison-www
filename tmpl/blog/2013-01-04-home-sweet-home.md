Welcome to the brand new, super awesome, incredibly modern, cloud based, fundamentally reinvented <a title="nickrobison.com" href="http://www.nickrobison.com" target="_blank">NICKROBISON.COM</a>.

But youre thinking, it sure looks the same to me. Thats because dear reader, it is the same, only vastly different. For the past year this site has been hosted with <a href="http://www.webhostingpad.com/" target="_blank">Webhostingpad</a>, a budget provider who, while cheap ($75 for 3 years), has been the definition of slow and _sometimes_ steady, also their management tools are pretty awful (though getting better). Most of you are intimately familiar with the ridiculously long waits associated with viewing some of the more visual articles and for those of you who stuck it out, I thank you and Ive finally done something about it. Ive been using _<a title="Cloudflare" href="https://www.cloudflare.com/" target="_blank">Cloudflare</a> _for a couple of months now as my CDN of choice, and while theyve been great it still hasnt been enough to overcome the anemic performance of whatever pizza box server from the 90s Ive been stuck with. So, last night I switched the entire site over to an <a title="Amazon AWS" href="http://aws.amazon.com/" target="_blank"><em>Amazon AWS</em></a> system consisting of a single Micro Instance with 2 EBS volumes (one for the database and one for the site files). Right now, its running within the free tier, but when that expires in August the monthly cost will still only be $3.66, which is great for the features I get. Ive also taken the time to go through and re-optimize the site itself, stripping out old plugins and cleaning up some of the various errors cropping up in the logs. The result is something that doesnt make a T3 line feel like 56k dialup (this is not hyperbole), and also has a ton of expandability for future growth (Im an optimist). I think youll all appreciate it, not only are things better and cleaner, theyre also more bloated and feature-full, lets take a short tour hrough the new additions:

* **Social Networks**


 In the top right corner of the home page you should see a collection of familiar icons with the phrase The other Networks emblazoned above them. I know you have all been dying to join the active community of users we have over here, and now you can through your favorite social networks! (Except Pinterest, because it sucks). You can login/register through the icon on the side, or through the comments box at the end of each post. So now, you can be a part of something without ever leaving the safe confines of something you like better, except Pinterest.

*  **Favicon**


Theres a new icon by the url, sometimes, so now were in the same class as the big boys like Amazon and etsy. Be impressed.

* <span style="line-height: 15px;"><strong>Sharing</strong><br /> </span>


After reading through an especially brilliant article youre probably wanting to share it with the rest of the world. And now you can! At the bottom of each article, right before (or after) you leave a particularly insightful comment, you can share it amongst your social circles (yes, even Pinterest). The world just got a whole lot bigger.

* <span style="line-height: 15px;"><strong>For the Lawyers</strong><br /> </span>

As part of the social integration I had to create an official privacy policy, which you can  view under the Legal Stuff page, next to About Me. Basically, I use Google Analytics to track hits, so it collects IP addresses and correlates them to location. When you sign in with another social network the site stores your name and email address. With this information I will slowly begin to take over the world. Not really, but sort of. Anyways, you can read it all in excruciating detail, or not.

* <span style="line-height: 15px;"><strong>Header Images</strong><br /> </span>


The header images are all brand new and no longer the weird stock photos that come with the default settings. These photos are all mine (except the cats on the legal stuff page) and fit the theme of the site much better. At least, thats my opinion. I would highly recommend reloading the home page repeatedly to see all the pretty pictures.

Well, thats about it. Thanks for joining us and dont forget to pick up your gift bags on the way out. Things are still in a bit of a flux as I sort out various issues that continue to crop up. I think things are pretty stable, but they may not be. Good luck to us all.

**UPDATE:** The first rule of grad school is: If something is working perfectly fine, thats probably a good enough reason to muck around and try something new. To that end, the site has moved once again, this time from Apache to [Nginx][1] [Engine-X]. I had some issues with Apache using all the RAM on the micro instance (you only get 768MB, I have a Pentium II box with twice that) and since I wasnt using all of its fancy extensions and rewrite tools it made more sense to change to something a little more resource frugal. I also moved all the backend database connections from ports to sockets and implemented memcached to store session information, so thats cool. Also, the site backend is now completely encrypted thanks to the free SSL certs from <a title="StartSSL" href="https://www.startssl.com/" target="_blank">StartSSL</a>, that means your highly sensitive data is now protected from thieving eyes. If youre having a difficult time keeping up with all the improvements around here thats ok, just be impressed.

> The times they are a changin
> 
> Bob Dylan

[1]: http://nginx.org "Nginx"