<div class="kcite-section" kcite-section-id="359">
  <p>
    Welcome to the brand new, super awesome, incredibly modern, &#8216;cloud based&#8217;, fundamentally reinvented <a title="nickrobison.com" href="http://www.nickrobison.com" target="_blank">NICKROBISON.COM</a>.
  </p>
  
  <p>
    But you&#8217;re thinking, &#8216;it sure looks the same to me&#8217;. That&#8217;s because dear reader, it is the same, only vastly different. For the past year this site has been hosted with <a href="http://www.webhostingpad.com/" target="_blank">Webhostingpad</a>, a budget provider who, while cheap ($75 for 3 years), has been the definition of slow and <em>sometimes</em> steady, also their management tools are pretty awful (though getting better). Most of you are intimately familiar with the ridiculously long waits associated with viewing some of the more visual articles and for those of you who stuck it out, I thank you and I&#8217;ve finally done something about it. I&#8217;ve been using <em><a title="Cloudflare" href="https://www.cloudflare.com/" target="_blank">Cloudflare</a> </em>for a couple of months now as my CDN of choice, and while they&#8217;ve been great it still hasn&#8217;t been enough to overcome the anemic performance of whatever pizza box server from the 90s I&#8217;ve been stuck with. So, last night I switched the entire site over to an <a title="Amazon AWS" href="http://aws.amazon.com/" target="_blank"><em>Amazon AWS</em></a> system consisting of a single Micro Instance with 2 EBS volumes (one for the database and one for the site files). Right now, it&#8217;s running within the &#8216;free&#8217; tier, but when that expires in August the monthly cost will still only be $3.66, which is great for the features I get. I&#8217;ve also taken the time to go through and re-optimize the site itself, stripping out old plugins and cleaning up some of the various errors cropping up in the logs. The result is something that doesn&#8217;t make a T3 line feel like 56k dialup (this is not hyperbole), and also has a ton of expandability for future growth (I&#8217;m an optimist). I think you&#8217;ll all appreciate it, not only are things better and cleaner, they&#8217;re also more bloated and feature-full, let&#8217;s take a short tour hrough the new additions:
  </p>
  
  <ul>
    <li>
      <strong>Social Networks</strong>
    </li>
  </ul>
  
  <p style="padding-left: 30px;">
     In the top right corner of the home page you should see a collection of familiar icons with the phrase &#8216;The &#8216;other&#8217; Networks&#8217; emblazoned above them. I know you have all been dying to join the active community of users we have over here, and now you can through your favorite social networks! (Except Pinterest, because it sucks). You can login/register through the icon on the side, or through the comments box at the end of each post. So now, you can be a part of something without ever leaving the safe confines of something you like better, except Pinterest.
  </p>
  
  <ul>
    <li>
       <strong>Favicon</strong>
    </li>
  </ul>
  
  <p style="padding-left: 30px;">
    There&#8217;s a new icon by the url, sometimes, so now we&#8217;re in the same class as the big boys like Amazon and etsy. Be impressed.
  </p>
  
  <ul>
    <li>
      <span style="line-height: 15px;"><strong>Sharing</strong><br /> </span>
    </li>
  </ul>
  
  <p style="padding-left: 30px;">
    After reading through an especially brilliant article you&#8217;re probably wanting to share it with the rest of the world. And now you can! At the bottom of each article, right before (or after) you leave a particularly insightful comment, you can share it amongst your social circles (yes, even Pinterest). The world just got a whole lot bigger.
  </p>
  
  <ul>
    <li>
      <span style="line-height: 15px;"><strong>For the Lawyers</strong><br /> </span>
    </li>
  </ul>
  
  <p style="padding-left: 30px;">
    As part of the social integration I had to create an official privacy policy, which you can  view under the &#8216;Legal Stuff&#8217; page, next to &#8216;About Me&#8217;. Basically, I use Google Analytics to track hits, so it collects IP addresses and correlates them to location. When you sign in with another social network the site stores your name and email address. With this information I will slowly begin to take over the world. Not really, but sort of. Anyways, you can read it all in excruciating detail, or not.
  </p>
  
  <ul>
    <li>
      <span style="line-height: 15px;"><strong>Header Images</strong><br /> </span>
    </li>
  </ul>
  
  <p style="padding-left: 30px;">
    The header images are all brand new and no longer the weird stock photos that come with the default settings. These photos are all mine (except the cats on the &#8216;legal stuff&#8217; page) and fit the theme of the site much better. At least, that&#8217;s my opinion. I would highly recommend reloading the home page repeatedly to see all the pretty pictures.
  </p>
  
  <p>
    Well, that&#8217;s about it. Thanks for joining us and don&#8217;t forget to pick up your gift bags on the way out. Things are still in a bit of a flux as I sort out various issues that continue to crop up. I think things are pretty stable, but they may not be. Good luck to us all.
  </p>
  
  <p>
    &nbsp;
  </p>
  
  <p>
    <strong>UPDATE:</strong> The first rule of grad school is: If something is working perfectly fine, that&#8217;s probably a good enough reason to muck around and try something &#8216;new&#8217;. To that end, the site has moved once again, this time from Apache to <a title="Nginx" href="http://nginx.org">Nginx</a> [Engine-X]. I had some issues with Apache using all the RAM on the micro instance (you only get 768MB, I have a Pentium II box with twice that) and since I wasn&#8217;t using all of its fancy extensions and rewrite tools it made more sense to change to something a little more resource frugal. I also moved all the backend database connections from ports to sockets and implemented memcached to store session information, so that&#8217;s cool. Also, the site backend is now completely encrypted thanks to the free SSL certs from <a title="StartSSL" href="https://www.startssl.com/" target="_blank">StartSSL</a>, that means your highly sensitive data is now protected from thieving eyes. If you&#8217;re having a difficult time keeping up with all the improvements around here that&#8217;s ok, just be impressed.
  </p>
  
  <blockquote>
    <p>
      The times they are a changin&#8217;
    </p>
    
    <p>
      &#8211; Bob Dylan
    </p>
  </blockquote>
  
  <!-- kcite active, but no citations found -->
</div>

<!-- kcite-section 359 -->