Recently, I&#8217;ve been working on a project that involves a fair amount of GIS work, specifically plotting a bunch of points on a map and finding useful ways to visualize them. It turns out, this is a bit harder than I&#8217;d originally hoped. For starters, GIS software support on OS X is abysmal<sup id="rf1-813"><a href="#fn1-813" title="shout out to the OSGeo guys for their work on porting some popular packages. Keep up the good work!" rel="footnote">1</a></sup> so while it&#8217;s fairly easy to build some nice stuff in QGIS, getting it to compile is a bit hit or miss. Second, if you need to do things programmatically you&#8217;ll need something that exposes nice bindings for your language of choice.

Enter [GRASS][1]. GRASS is the software package that underlies almost every single open source GIS program (and probably plays a significant role in closed-source ones as well), it&#8217;s incredibly powerful and capable of performing just about any operation a budding cartographer could ever hope or dream of. In addition, it may also hold the distinction of being the most unfriendly program that I have ever had the displeasure of using. So, what may sound like an easy task (take some points, throw them on map, plot their densities) turns out to be quite an undertaking, so to spare you the pain, I figured I&#8217;d write up a quick (or not so quick as the case may be) walkthrough.

So, today dear friends, we&#8217;re going to go through the process of building some nice raster heatmaps and visualize them using Tilemill. I&#8217;m assuming you have a nice CSV file with latitude and longitude pairs that you&#8217;ve acquired from somewhere like Twitter. I&#8217;m also assuming that the end result will be using these maps to display with some sort of web service like OpenStreetMaps or GoogleMaps. This will be become important in a bit, so just keep in mind that you may have to modify a few things as we go along. So without further ado, let&#8217;s get started.

**Installation**

Installing GIS software used to be a [huge][2] pain, but fortunately over the past year or so things have gotten significantly easier. Here&#8217;s a quick rundown of how to get the software installed, but as always, each system has its own quirks so there may be some extra things you need to consider.

_Windows_

This is probably the easiest of them all, again the OSGeo team has done all the hard work for you. Just grab the [OsGeo4W][3] installer and select _Express Desktop Install_ on the first page, keep the defaults and it&#8217;ll download and install everything you need. If you feel like being fancy, you can also customize each individual package and dependency, but maybe you should just read a book or browse Reddit instead.

_Linux_

Linux has a great home-field advantage and most software works and feels most natural here. Unfortunately, most of the distribution packages are quite outdated<sup id="rf2-813"><a href="#fn2-813" title="I&rsquo;m pretty sure the version of QGIS shipped with Ubuntu is the same one Moses used to teach the Israelites, but I can&rsquo;t be sure." rel="footnote">2</a></sup> so it&#8217;s a good idea to grab a more up-to-date repository. Here&#8217;s how to do so on Ubuntu:


sudo apt-get update

sudo apt-get install qgis grass70-core grass70-gui gdal-bin python-gdal


_OS X_

If you&#8217;d like, the OSGeo team has pre-built packages that install without much effort, but because of the huge number of dependencies, and all the funky GUI frameworks, I think the easiest way is to just use homebrew.

If you&#8217;re not [homebrewing][4] yet, well, why not? Once you get it setup and configured you&#8217;ll need the OsGeo4Mac branch in order to get the latest and greatest versions<sup id="rf3-813"><a href="#fn3-813" title="Not to mention ones that actually build" rel="footnote">3</a></sup>, you can leave everything at the defaults, or if you&#8217;re like me and you never met a compile flag you didn&#8217;t love, you can customize all the dependencies to your little heart&#8217;s content, like so:


brew install gdal --complete --enable-armadillo --enable-opencl --with-libkml --with-python

brew install grass-70 --with-liblas --with-netcdf --with-postgresql


Now, grab a cup of coffee and wait for everything to compile.<sup id="rf4-813"><a href="#fn4-813" title="Observant readers will notice that I left out the QGIS install, that&rsquo;s not because QGIS and I are on the outs, but just that I&rsquo;ve had mixed success actually getting it to compile. If you&rsquo;re feeling adventurous by all means give it a go, but since it&rsquo;s not absolutely necessary for this tutorial, I&rsquo;ve left it out. " rel="footnote">4</a></sup>

**Ingest the data**

Great, now that we&#8217;ve got the software installed let&#8217;s load the data.

Fire up the GRASS GUI and take a look at the first screen. GRASS has a couple of concepts that are important to keep in mind.

1. Everything happens in a _location, _which is basically a project set within a certain geographic boundary. This is where you keep all the maps and resources that your project requires. A location also has a specific projection and coordinate system, so if you&#8217;re working on a project with data in different coordinate systems, you&#8217;ll need multiple locations, even if the datasets are in the same geographic region (we&#8217;ll get to enjoy this little <del>bug</del> feature soon enough).
2. Within each location is one or more _mapsets, _a mapset is a collection of GIS resources for a specific purpose. For example, if multiple people are working on the same project, they may each have their mapsets, with their own resources. Or, if you&#8217;re working on a project that involves both vector data (like points and shapefiles) and maybe some raster data (like satellite images) you could keep those in two different mapsets. For this project, we&#8217;ll keep everything in one set, just to make it easier.

So now let&#8217;s load some data, but before we do that, we need to know a few details. First, we have to decide what projection system we want to display our data in. Since the goal of this project is to overlay the heatmap on web maps such as Google, we would probably choose that projection system (EPSG: 3857). Not so fast, Google&#8217;s project is actually quite wonky (in order to preserve angles for streetview) and is difficult to project into. Recent software libraries (like the proj4 engine, which is what everything else uses) have some added parameters to compensate for this, but in my experience GRASS (even the recent version 7 betas, which is what I&#8217;m using in this tutorial) doesn&#8217;t do the conversion correctly. So instead, we&#8217;ll want to use something else, and then either re-project on the fly, or do the projection using proj4 directly (we&#8217;ll get to this later). I recommended using EPSG 3395, and here&#8217;s why; a lot of the data that involves coordinate pairs (like Twitter data or GPS coordinates) uses the [WGS84][5] coordinate system, while this works great for plotting points on a map, it&#8217;s not very useful for doing more advanced analysis since the unit scale changes in relation to your distance from the equator  So, if we choose EPSG 3395 (which is WGS84 projected) we can project the data into a constant scale, but not worry about other artifacts that might crop up from converting between completely different coordinate systems.

So, now we need to ingest the data (which is WGS84) and convert it to WGS84-projected in order to do the analysis (remember GRASS only allows 1 coordinate system, per location). Here&#8217;s how:

1. Define a location to hold the point data. Click the _Location Wizard_ button on the right side of the opening GRASS screen,  give it a location name, a location title, and click _Next_. For this part, we&#8217;ll use _heat_pts,_ to indicate the point data.
2. Since we know the projection system we want to use (WGS84) and we know the EPSG code (4326, memorize that) we want to use the _Select EPSG code of spatial reference system _choice. The other options are quite useful if you have data in an existing data format that defines its own projection (such as a shapefile), or if you don&#8217;t know the correct EPSG code and need to look it up. Click _Next._
3. Enter the code (4326) in the _EPSG code_ box and click _Next. _You should see something like this:<figure id="attachment_819" style="width: 300px" class="wp-caption aligncenter">

<img class="size-medium wp-image-819" src="https://files.nickrobison.com/images/2014/09/Screen-Shot-2014-09-02-at-2.16.06-PM-300x213.png" alt="Note the warning about the changing dimensions, GRASS really wants projected coordinates, and wants you to know about it." width="300" height="213" srcset="https://files.nickrobison.com/images/2014/09/Screen-Shot-2014-09-02-at-2.16.06-PM-300x213.png 300w, https://files.nickrobison.com/images/2014/09/Screen-Shot-2014-09-02-at-2.16.06-PM.png 1022w" sizes="(max-width: 300px) 100vw, 300px" /><figcaption class="wp-caption-text">Note the warning about the changing dimensions, GRASS really wants projected coordinates, and wants you to know about it.</figcaption></figure> 

4. Click _OK_ on the warning box and you should see a final screen that gives all the relevant information about the location. If you&#8217;d like, you can copy down the proj4 string, they&#8217;re often times a useful reference in telling other software (like Tilemilll, hint, hint) how to display your data. Click _Finish_.

5. Finally, if should give you an option to define the region and extents before you load any data, this doesn&#8217;t really matter when working with vector data, but it matters a great deal with rasters. Often times, it&#8217;s easiest to load your data and then have GRASS calculate that data for you. So for now, we&#8217;ll just click _No_._

_ 

6. Go ahead and click _OK_ to create a new mapset, if you&#8217;d like, you can keep everything in _PERMANENT_, the default GRASS set, but that&#8217;s up to you.

7. Finally, click _Start GRASS__ _and revel in its GUI goodness.<figure id="attachment_820" style="width: 300px" class="wp-caption aligncenter">

<img class="size-medium wp-image-820" src="https://files.nickrobison.com/images/2014/09/Screen-Shot-2014-09-02-at-2.22.44-PM-300x141.png" alt="Hello 1997, it's good to see you again." width="300" height="141" srcset="https://files.nickrobison.com/images/2014/09/Screen-Shot-2014-09-02-at-2.22.44-PM-300x141.png 300w, https://files.nickrobison.com/images/2014/09/Screen-Shot-2014-09-02-at-2.22.44-PM-1024x482.png 1024w, https://files.nickrobison.com/images/2014/09/Screen-Shot-2014-09-02-at-2.22.44-PM.png 1343w" sizes="(max-width: 300px) 100vw, 300px" /><figcaption class="wp-caption-text">Hello 1997, it&#8217;s good to see you again.</figcaption></figure> 

8. I know right, you haven&#8217;t gotten this excited about an interface since you fired up Windows 95 for the first time. Actually, that&#8217;s probably the last time the interface was updated, but since we&#8217;re true nerds we&#8217;re not deterred by what we see, so we press on. Now we need to load our data. Since it&#8217;s simply a collection of point values we need to tell GRASS to read the file and turn each line into a unique point. To do so,  select _ASCII points or GRASS ASCII format [v.in.ascii]_ under the _File -> Import vector data_ menu.

On the _Required _screen, load your input file, and give the resulting map layer a name (since my data is a bunch of Tweets from the Atlanta metro area, I&#8217;m going to be super clever and call my layer _atlanta_pts_, but you can do whatever floats your boat). Make sure the _Add created map[s] into layer tree_ stays selected.<figure id="attachment_823" style="width: 300px" class="wp-caption aligncenter">

<img class="size-medium wp-image-823" src="https://files.nickrobison.com/images/2014/09/Screen-Shot-2014-09-02-at-2.30.29-PM-300x266.png" alt="Yours should look something like this." width="300" height="266" srcset="https://files.nickrobison.com/images/2014/09/Screen-Shot-2014-09-02-at-2.30.29-PM-300x266.png 300w, https://files.nickrobison.com/images/2014/09/Screen-Shot-2014-09-02-at-2.30.29-PM.png 691w" sizes="(max-width: 300px) 100vw, 300px" /><figcaption class="wp-caption-text">Yours should look something like this.</figcaption></figure> 

For the next step, we need to know the format of our data, mine looks like this:

30953|-84.34088988456551|33.73738463926367
1047391|-84.37350085502241|33.83837966067272
1561491|-84.40617218844126|33.71876940960077
1810701|-84.38021346457639|33.76925580504283
2083571|-84.41194434775504|33.7856184006737
3956151|-84.43781233345071|33.80593333398135
4359371|-84.32801349864327|33.75361426020218
5161921|-84.30200782720981|33.83737260488842
5753742|-84.42793996359265|33.67073527455402


There are a couple of things to note:

* It has a header, so we need to tell GRASS to skip one line.
* The columns are separated by pipes, not tabs or commas.<sup id="rf5-813"><a href="#fn5-813" title="GRASS really doesn&rsquo;t like commas, so I make sure to use pipes, but maybe you&rsquo;re a nicer person than me, and can get away with it." rel="footnote">5</a></sup>
* It&#8217;s in a longitude/latitude sequence.

On the _Input Format_ tab, make sure the _Input file format _is set to _point_ and that the _Field separator_ is set correctly (here, it needs to be pipes).<figure id="attachment_825" style="width: 300px" class="wp-caption aligncenter">

<img class="size-medium wp-image-825" src="https://files.nickrobison.com/images/2014/09/Screen-Shot-2014-09-02-at-2.36.25-PM-300x266.png" alt="Pretty simple so far." width="300" height="266" srcset="https://files.nickrobison.com/images/2014/09/Screen-Shot-2014-09-02-at-2.36.25-PM-300x266.png 300w, https://files.nickrobison.com/images/2014/09/Screen-Shot-2014-09-02-at-2.36.25-PM.png 691w" sizes="(max-width: 300px) 100vw, 300px" /><figcaption class="wp-caption-text">Pretty simple so far.</figcaption></figure> 

The _Points_ screen is where things get tricky. To be safe, leave everything at the defaults, unless you specifically need to change it.

* Set _Number of header lines to to skip at top of input file (points mode)_ to 1.
* Set _Number of column used as X coordinate (points mode)_ to 2.
* Set _Number of column used as Y coordinate (points mode) _ to 3.

Hold up, where did X/Y come from? All I have is lat/lon. Correct, but now we&#8217;re dealing with projected coordinate systems and they don&#8217;t think in terms of geography, they think in terms of geometry, so everything is X/Y. Here&#8217;s really what you need to know:

Longitude = X coordinate

Latitude = Y coordinate

Keep that straight and you&#8217;ll be in Cartesian heaven.<figure id="attachment_826" style="width: 296px" class="wp-caption aligncenter">

<img class="size-medium wp-image-826" src="https://files.nickrobison.com/images/2014/09/Screen-Shot-2014-09-02-at-2.42.24-PM-296x300.png" alt="Or, how I learned to stop worrying and love the defaults." width="296" height="300" srcset="https://files.nickrobison.com/images/2014/09/Screen-Shot-2014-09-02-at-2.42.24-PM-296x300.png 296w, https://files.nickrobison.com/images/2014/09/Screen-Shot-2014-09-02-at-2.42.24-PM.png 691w" sizes="(max-width: 296px) 100vw, 296px" /><figcaption class="wp-caption-text">Or, how I learned to stop worrying and love the defaults.</figcaption></figure> 

Feel free to check out the other tabs, tweak some settings, or read the man pages (yeah right). Me, I&#8217;m too impatient so I&#8217;m just going to click _Run_ and move on.

That&#8217;ll run for a brief moment (depending on how much data you have) and once it&#8217;s done you may have a blank screen. If so, don&#8217;t panic, in the _Layer Manager_ window, click the little funky icon (I have no idea what the symbology means) next to the layer called _atlanta_points@[mapset name]_ and select _Zoom to selected map(s). _Here&#8217;s what it looks like for me:<figure id="attachment_827" style="width: 300px" class="wp-caption aligncenter">

<img class="size-medium wp-image-827" src="https://files.nickrobison.com/images/2014/09/Screen-Shot-2014-09-02-at-3.03.42-PM-300x140.png" alt="Seems like a lot of work thus far...." width="300" height="140" srcset="https://files.nickrobison.com/images/2014/09/Screen-Shot-2014-09-02-at-3.03.42-PM-300x140.png 300w, https://files.nickrobison.com/images/2014/09/Screen-Shot-2014-09-02-at-3.03.42-PM-1024x480.png 1024w, https://files.nickrobison.com/images/2014/09/Screen-Shot-2014-09-02-at-3.03.42-PM.png 1333w" sizes="(max-width: 300px) 100vw, 300px" /><figcaption class="wp-caption-text">Seems like a lot of work thus far&#8230;.</figcaption></figure> 

Congrats! You now have point data in GRASS. Now, let&#8217;s get to the fun part, building the heatmaps.

**Rasterize.**

Now we have data, but remember, it&#8217;s in geographic WGS84, and we need projected WGS84. So now, we need to create a new location with the correct projection and somehow load our point data into it. Fortunately, GRASS allows you to re-project data from one location, to another and it handles all the backend calculations. So let&#8217;s do that.

1. Under _Settings -> GRASS Working Environment_ select _Create new location._
2. Follow the same process as above, but give it a different name, and enter EPSG code _3395_ which is the projected version of WGS84. I&#8217;m calling my location _heatmap_ because I&#8217;m not very creative, but you shouldn&#8217;t sink down to my level. Click _Finish_ and when prompted switch to the new location. If it asks you to store the current settings you can say no, because we shouldn&#8217;t have to open our _heat_pts_ location again. Finally, when prompted to set the default region and extents you need to say no, because we&#8217;re going to have GRASS do that for us based on our existing point data (we&#8217;ll come back to this later).
3. Now we need to import our point data and reproject it into our new coordinate system. In the top menu navigate to _Vector -> Develop Vector Map_ and select _Reproject vector map from different GRASS location [v.proj]._<sup id="rf6-813"><a href="#fn6-813" title="At this point, you may be curious as to the weird codes at the end of the command names. Those represent that actual commands that the gui is running. V is for vector functions, R for raster, this comes in really handy if you&rsquo;re automating things, or if you&rsquo;re not sure which function to run on your data." rel="footnote">6</a></sup>
4. Under the _Required _tab set _Location containing input vector map_ to the location we loaded the point data into (e.g. _heat_pts)._
5. Under _Source_ set the correct _Mapset_ and _input vector_. You can leave everything else at the defaults and click _Run._<figure id="attachment_828" style="width: 300px" class="wp-caption aligncenter">

<img class="size-medium wp-image-828" src="https://files.nickrobison.com/images/2014/09/Screen-Shot-2014-09-02-at-3.20.43-PM-300x266.png" alt="Pretty straight forward." width="300" height="266" srcset="https://files.nickrobison.com/images/2014/09/Screen-Shot-2014-09-02-at-3.20.43-PM-300x266.png 300w, https://files.nickrobison.com/images/2014/09/Screen-Shot-2014-09-02-at-3.20.43-PM.png 646w" sizes="(max-width: 300px) 100vw, 300px" /><figcaption class="wp-caption-text">Pretty straight forward.</figcaption></figure> 

6. Once that&#8217;s finished you can follow the same process above to zoom to the selected layer and you should see exactly what we saw in the other location.

7. Now we&#8217;re almost ready to generate the heatmap, but first we need to tell GRASS what region of data we&#8217;re interested in, and how many individual &#8216;cells&#8217; to process. While a clever user would probably have some fancy method for doing this themselves, I tend to trust robots more than my own brain so I&#8217;ll just let GRASS figure it out. To do so, select _Settings -> Region -> Set Region [g.region]. _In the window that opens, we want to set _[multiple] Set region to match vector map(s)_ to the vector layer that we just imported, then click _Run_.<figure id="attachment_829" style="width: 300px" class="wp-caption aligncenter">

<img class="size-medium wp-image-829" src="https://files.nickrobison.com/images/2014/09/Screen-Shot-2014-09-02-at-3.25.59-PM-300x288.png" alt="What's old, is new again." width="300" height="288" srcset="https://files.nickrobison.com/images/2014/09/Screen-Shot-2014-09-02-at-3.25.59-PM-300x288.png 300w, https://files.nickrobison.com/images/2014/09/Screen-Shot-2014-09-02-at-3.25.59-PM.png 690w" sizes="(max-width: 300px) 100vw, 300px" /><figcaption class="wp-caption-text">What&#8217;s old, is new again.</figcaption></figure> 

We can verify that this actually worked by running _Settings -> Region -> Display Region [g.region -p]_ and viewing the resulting output. What we&#8217;re interested in is the _rows _and _cols_ values. Basically, we don&#8217;t want them to be 0. If when we generate the heatmap it comes out looking like a single color square, that means we didn&#8217;t set the region correctly and GRASS is assuming we want everything merged down into a single cell, which doesn&#8217;t work. It&#8217;s also important to note that GRASS can&#8217;t set a region based on geographic coordinates (because the distance is always changing), so if you run the _Set Region _command and it doesn&#8217;t have any effect, it may be that you&#8217;ve set your location&#8217;s coordinate system to a non-projected system.<figure id="attachment_830" style="width: 268px" class="wp-caption aligncenter">

<img class="size-medium wp-image-830" src="https://files.nickrobison.com/images/2014/09/Screen-Shot-2014-09-02-at-3.26.20-PM-268x300.png" alt="Are they 0? Nope? Good. Move on." width="268" height="300" srcset="https://files.nickrobison.com/images/2014/09/Screen-Shot-2014-09-02-at-3.26.20-PM-268x300.png 268w, https://files.nickrobison.com/images/2014/09/Screen-Shot-2014-09-02-at-3.26.20-PM.png 639w" sizes="(max-width: 268px) 100vw, 268px" /><figcaption class="wp-caption-text">Are they 0? Nope? Good. Move on.</figcaption></figure> 

8. Now, we&#8217;re ready to make the heatmap. Yes, dear reader you&#8217;re probably right. ArcGIS could&#8217;ve done this in 1/4th the time. But look on the bright side, yes you&#8217;ve spent all this time fussing with a GUI only a mother could love, but now you can take that $2700/year that you save in licensing fees and go buy beer, a lot of beer.<sup id="rf7-813"><a href="#fn7-813" title="Or, you could just go get an intern to do all of this for you." rel="footnote">7</a></sup> That aside, in the _Raster_ top menu, select _Generate Surface -> Gaussian kernel density surface [v.kernel]_. In the _Required_ tab we need to set all the options. Since we only have 1 vector layer, that should be selected for us already. Next, we want to give our output layer a name, so set _Name for output raster/vector map_ to something useful (I&#8217;m using _heatmap_500)._

Finally, we need to set _Kernel radius in map units._ Here&#8217;s where things get tricky, this final option is telling GRASS how big of an area to consider when figuring out how much to weight each individual point. There are a number of factors to consider when making this decision and they&#8217;re definitely outside the scope of this article, but a helpful question to ask, is what types of effects are you looking for? Are you looking for effects on a city block level? A county level? Regional? The answer to that question is going to determine how big or small to set the radius. For this project, I&#8217;m thinking 500m should give me the results I&#8217;m looking for. Remember, the radius is in _map units_, which is determined by the coordinate system you chose. Here, the units are in meters, so I&#8217;m choosing 500. Simple enough.<figure id="attachment_831" style="width: 300px" class="wp-caption aligncenter">

<img class="size-medium wp-image-831" src="https://files.nickrobison.com/images/2014/09/Screen-Shot-2014-09-02-at-3.45.04-PM-300x274.png" alt="Click on the other tabs at your own peril. There's a lot you can screw up in very little time." width="300" height="274" srcset="https://files.nickrobison.com/images/2014/09/Screen-Shot-2014-09-02-at-3.45.04-PM-300x274.png 300w, https://files.nickrobison.com/images/2014/09/Screen-Shot-2014-09-02-at-3.45.04-PM.png 670w" sizes="(max-width: 300px) 100vw, 300px" /><figcaption class="wp-caption-text">Click on the other tabs at your own peril. There&#8217;s a lot you can screw up in very little time.</figcaption></figure> 

You can leave everything else at the defaults and then click _Run_. Now, go get some more coffee because this could take a while<sup id="rf8-813"><a href="#fn8-813" title="On my 2012 Macbook Air it takes about 11 minutes to build the heatmap." rel="footnote">8</a></sup>.

9. Once it&#8217;s done processing and you&#8217;re all hopped up on caffeine, take that jittery mouse and try to click on this icon in the _Layer Manager _window:<figure id="attachment_834" style="width: 36px" class="wp-caption aligncenter">

<img class="size-full wp-image-834" src="https://files.nickrobison.com/images/2014/09/Screen-Shot-2014-09-02-at-3.58.08-PM.png" alt="What do you call this?" width="36" height="33" /><figcaption class="wp-caption-text">What do you call this?</figcaption></figure> 

I have no idea how to describe that icon, but if you hover over all the options, the tooltip you want is _Add Raster Map Layer_. Click it, and select the raster map it just generated (it should be the only one in the mapset). Boom, we have map, people!

10. Now, the default color ramp is pretty compressed and makes it hard to see things, so we should change that. Again, click the layer dropdown menu (the one to the right of the name) and select _Set color table_.<figure id="attachment_833" style="width: 266px" class="wp-caption aligncenter">

<img class="size-medium wp-image-833" src="https://files.nickrobison.com/images/2014/09/Screen-Shot-2014-09-02-at-4.05.35-PM-266x300.png" alt="Click it." width="266" height="300" srcset="https://files.nickrobison.com/images/2014/09/Screen-Shot-2014-09-02-at-4.05.35-PM-266x300.png 266w, https://files.nickrobison.com/images/2014/09/Screen-Shot-2014-09-02-at-4.05.35-PM.png 537w" sizes="(max-width: 266px) 100vw, 266px" /><figcaption class="wp-caption-text">Click it.</figcaption></figure> 

Next, click on the _Define_ tab and select which ever option you want under the _Name of color table_ dropdown. (Personally, I like the _bgyr_). Click _Run_ and revel in the colored goodness.<figure id="attachment_835" style="width: 278px" class="wp-caption aligncenter">

<img class="size-medium wp-image-835" src="https://files.nickrobison.com/images/2014/09/Screen-Shot-2014-09-02-at-4.07.55-PM-278x300.png" alt="Designer's choice." width="278" height="300" srcset="https://files.nickrobison.com/images/2014/09/Screen-Shot-2014-09-02-at-4.07.55-PM-278x300.png 278w, https://files.nickrobison.com/images/2014/09/Screen-Shot-2014-09-02-at-4.07.55-PM.png 714w" sizes="(max-width: 278px) 100vw, 278px" /><figcaption class="wp-caption-text">Designer&#8217;s choice.</figcaption></figure> <figure id="attachment_836" style="width: 300px" class="wp-caption aligncenter"><img class="size-medium wp-image-836" src="https://files.nickrobison.com/images/2014/09/Screen-Shot-2014-09-02-at-4.08.57-PM-300x241.png" alt="I love map." width="300" height="241" srcset="https://files.nickrobison.com/images/2014/09/Screen-Shot-2014-09-02-at-4.08.57-PM-300x241.png 300w, https://files.nickrobison.com/images/2014/09/Screen-Shot-2014-09-02-at-4.08.57-PM.png 914w" sizes="(max-width: 300px) 100vw, 300px" /><figcaption class="wp-caption-text">I love map.</figcaption></figure> 

11. Do me a favor, in the layer drop-down, go ahead and run the _Report Raster Statistics _command for me. Let it churn for a few minutes and tell me, does it look something like this?<figure id="attachment_837" style="width: 268px" class="wp-caption aligncenter">

<img class="size-medium wp-image-837 " src="https://files.nickrobison.com/images/2014/09/Screen-Shot-2014-09-02-at-4.13.51-PM-268x300.png" alt="The only time I see numbers that small, is when I get my grad school stipend. (rimshot)" width="268" height="300" srcset="https://files.nickrobison.com/images/2014/09/Screen-Shot-2014-09-02-at-4.13.51-PM-268x300.png 268w, https://files.nickrobison.com/images/2014/09/Screen-Shot-2014-09-02-at-4.13.51-PM.png 639w" sizes="(max-width: 268px) 100vw, 268px" /><figcaption class="wp-caption-text">The only time I see numbers that small, is when I get my grad school stipend. (rimshot)</figcaption></figure> 

Yeah, that&#8217;s what I thought, there&#8217;s no way we can export those numbers of a GeoTIFF, if we tried, it would just vomit floats all over invalid memory space (trust me on this). The problem with a density function is that as the scale increases the resulting numbers done the opposite. But no problem, we can deal with that, we just need to rescale everything back to integers and we&#8217;ll be dandy.

12. Now, before you get all excited and start madly running that _Rescale_ command you&#8217;ve heard so much about, take a deep breath and remember, _Rescale_ only works on integers, you have to use _Recode_ for floats. They&#8217;re pretty much the same, only not, which is just how GRASS likes it. So, fire it up by running _Raster ->Change Category Values and Labels -> Recode [r.recode]_. The inputs raster should be selected (since it&#8217;s the only one in the mapset) and we can set _Name for output raster map_ to something clever, like _heatmap\_500\_recode. _((Yes, I am available for hire as a creative naming consultant, if you&#8217;d like I can even go _full valley_ and name everything with an ly. heatmap.ly, heatmap.ly_500. Client&#8217;s choice, of course.))

Now the tricky part (there&#8217;s always a tricky part). GRASS expects a specific formatting of values in order to know how to handle the input data, if you need more complex formatting you should take a look at the manual [page][21], otherwise just follow this layout:



In looking back at the statistics that we just ran on my heatmap layer, I can see that my minimum value is 0.0 and my maximum is 0.000125. For me to fit this into an integer field I need the following line:



Once you&#8217;ve set your values correctly, go ahead and click _Run_, when it finishes, should see something that looks identical to the first raster we generated (before we changed the color table), but if we run the _Report Raster Statistics_ command, we should see a nice ramp of integer values, which will play very nicely with other GIS programs.<figure id="attachment_838" style="width: 268px" class="wp-caption aligncenter">

<img class="size-medium wp-image-838" src="https://files.nickrobison.com/images/2014/09/Screen-Shot-2014-09-02-at-4.31.59-PM-268x300.png" alt="Much better." width="268" height="300" srcset="https://files.nickrobison.com/images/2014/09/Screen-Shot-2014-09-02-at-4.31.59-PM-268x300.png 268w, https://files.nickrobison.com/images/2014/09/Screen-Shot-2014-09-02-at-4.31.59-PM.png 639w" sizes="(max-width: 268px) 100vw, 268px" /><figcaption class="wp-caption-text">Much better.</figcaption></figure> 

13. Ok, but now our colors are all messed up, but we have a couple of options on how to fix that. We could just repeat our earlier process, run the _Set color table_ command, and reapply the color ramp. Or, we could do something else. Take a look at our heatmap; right now it&#8217;s just a giant see of blue (or green, depending on your color ramp) which looks really ugly and really isn&#8217;t that useful, there&#8217;s a lot of data that&#8217;s being obscured. What would be nice, would be to remove everything below a certain value and only display areas of high concentration. So let&#8217;s do that.

There are a couple of ways to go about this, but since our end goal is an image that we can integrate with other programs, what would be ideal would be to remove parts of the raster by setting their values to NULL and then make the display programs handle the appropriate ignoring. Well that&#8217;s pretty easy, in the _Raster _top menu, select _Develop Raster Map -> Manage NULL Values [r.null]_. In the resulting menu make sure _heatmap\_500\_recoded_ is selected, click _Modify_ and place your mouse cursor in the _[multiple] List of cell values to be set to NULL:_ box._ _Now we have to make a decision, we have to decided how much of the image to chop out<sup id="rf9-813"><a href="#fn9-813" title="While I may say &lsquo;remove&rsquo;, &lsquo;chop&rsquo;, &lsquo;exorcise&rsquo; in reality we&rsquo;re not removing anything from the image (the size and content stays the same), all we&rsquo;re doing is modifying the raster table to indicate which points have a NULL value. After all, a rose by another other name&hellip;." rel="footnote">9</a></sup>, for me, I want as little visual clutter as possible, and to only show areas of high concentration, so I&#8217;m going to choose to set the first 20 levels to NULL, but only you can decide which values are most appropriate for your respective datasets. Enter your values and click _Run _((If your colors come out looking strange, just reapply the color table.)).<figure id="attachment_846" style="width: 300px" class="wp-caption aligncenter">

<img class="size-medium wp-image-846" src="https://files.nickrobison.com/images/2014/09/Screen-Shot-2014-09-04-at-3.21.21-PM-300x240.png" alt="Drop is like it's hot." width="300" height="240" srcset="https://files.nickrobison.com/images/2014/09/Screen-Shot-2014-09-04-at-3.21.21-PM-300x240.png 300w, https://files.nickrobison.com/images/2014/09/Screen-Shot-2014-09-04-at-3.21.21-PM.png 648w" sizes="(max-width: 300px) 100vw, 300px" /><figcaption class="wp-caption-text">Drop is like it&#8217;s hot.</figcaption></figure> 

Once it&#8217;s done, we can make things a bit clearer by deselecting our original heatmap layer (_heatmap_500_), and changing the opacity of our new recoded layer down to about 70% (_Change opacity level_ in the layer drop-down). Here&#8217;s what it looks like for me:<figure id="attachment_847" style="width: 300px" class="wp-caption aligncenter">

<img class="size-medium wp-image-847" src="https://files.nickrobison.com/images/2014/09/Screen-Shot-2014-09-04-at-3.36.18-PM-300x241.png" alt="Oh that's real nice." width="300" height="241" srcset="https://files.nickrobison.com/images/2014/09/Screen-Shot-2014-09-04-at-3.36.18-PM-300x241.png 300w, https://files.nickrobison.com/images/2014/09/Screen-Shot-2014-09-04-at-3.36.18-PM.png 914w" sizes="(max-width: 300px) 100vw, 300px" /><figcaption class="wp-caption-text">Oh that&#8217;s real nice.</figcaption></figure> 

Now, we&#8217;re ready to output and visualize.

**Make flat picture**

Now that&#8217;ve got our map built and beautified, it&#8217;s time to output it as a GeoTIFF so the rest of the world can share in our joy.

1. In the _File_ top menu, select _Export raster map -> Common export formats [r.out.gdal]._ In the _Required_ tab, make sure the recoded layer is selected and give it an output location.

2. In the _Creation_ tab, you can pretty much leave everything at the defaults, but if you&#8217;re planning on importing the GeoTIFF into any ESRI products, you&#8217;ll probably want to pass a few options to improve [compatibility][25]. In the _[multiple] Creation option(s) to pass to the output format driver_ field, enter:



Go ahead and click _Run _and let it do its thing.<figure id="attachment_841" style="width: 300px" class="wp-caption aligncenter">

<img class="size-medium wp-image-841" src="https://files.nickrobison.com/images/2014/09/Screen-Shot-2014-09-02-at-4.48.41-PM-300x210.png" alt="When ESRI's happy, everyone's happy." width="300" height="210" srcset="https://files.nickrobison.com/images/2014/09/Screen-Shot-2014-09-02-at-4.48.41-PM-300x210.png 300w, https://files.nickrobison.com/images/2014/09/Screen-Shot-2014-09-02-at-4.48.41-PM-1024x717.png 1024w, https://files.nickrobison.com/images/2014/09/Screen-Shot-2014-09-02-at-4.48.41-PM.png 1075w" sizes="(max-width: 300px) 100vw, 300px" /><figcaption class="wp-caption-text">When ESRI&#8217;s happy, everyone&#8217;s happy.</figcaption></figure> 

3. By now, you should have nice (albeit massive) tif file ready to be sucked into your favorite GIS program. So congrats, you&#8217;ve now generated a heatmap in GRASS, pat yourself on the back, because you&#8217;ve now proven yourself to be among the elite in the GIS world. But since we&#8217;re in the groove, let&#8217;s not stop there, let&#8217;s take it a step further. Let&#8217;s actually make a map.

For now, let&#8217;s use [TileMill][27], as it&#8217;s free, cross-platform, and lets you output really pretty maps.

Download it, install it, open it, and click _New Project._<sup id="rf10-813"><a href="#fn10-813" title="take a moment to marvel at what a GUI is supposed to look like." rel="footnote">10</a></sup> Give it a name, description, and click _Add_.<figure id="attachment_842" style="width: 300px" class="wp-caption aligncenter">

<img class="size-medium wp-image-842" src="https://files.nickrobison.com/images/2014/09/Screen-Shot-2014-09-02-at-4.55.24-PM-300x238.png" alt="Ahh, so nice and modern." width="300" height="238" srcset="https://files.nickrobison.com/images/2014/09/Screen-Shot-2014-09-02-at-4.55.24-PM-300x238.png 300w, https://files.nickrobison.com/images/2014/09/Screen-Shot-2014-09-02-at-4.55.24-PM-1024x813.png 1024w, https://files.nickrobison.com/images/2014/09/Screen-Shot-2014-09-02-at-4.55.24-PM.png 1138w" sizes="(max-width: 300px) 100vw, 300px" /><figcaption class="wp-caption-text">Ahh, so nice and modern.</figcaption></figure> 

If the project doesn&#8217;t open automatically, just click on its icon.

The new project that we&#8217;ve created is really, really basic. It just has a base map of country outlines and very little in way of style. We can fix this, but started with an _OSM Bright_ project which will let us place some basemaps under our new heatmap for a nice maps-on-maps effect. That&#8217;s what I&#8217;m going to do (since I&#8217;ve already done it for another project), and you can do so as well, if you follow [these instructions][29].

4. In our nice new project we need to

+init=epsg:3395

**Tile it up**

Ok, so you&#8217;ve gotten it into _TileMill_ and everything&#8217;s all nice and shinny. But what if you want to serve this up on the web? Easy, you can either add it as a layer in [Mapnik][30], or your tileserver of [choice][31]. But we can simulate what they would look like using the _gdal2tiles.py_ command. So let&#8217;s do that.

1. Before we can do that, we need to add a transparency layer to our GeoTIFF file. To do so, open a [terminal][32] window, navigate to the folder you saved your heatmap, and issue the following command:



That should create a GDAL virtual file that encodes all the required information for processing into tiles.

2. Now we need to actually generate the tiles, you can take a look at all the possible commands by running:



or, you can just run this command to get going:



It&#8217;s important to note that we set the newly created _.vrt_ file as the input, not the original GeoTIFF, this is because we need the explicit alpha channel that&#8217;s isn&#8217;t correctly generated in GRASS (even with the _ALPHA=YES_ option). We also specified tiling at zoom levels 2-10, and set the output to the _tiles _directory. Let it run for a bit (more coffee, perhaps?) and when it&#8217;s done, in the tiles folder you should have 2 html files, one using _Google Maps_ as the base-layer and the other with _OpenLayers_. Open one up and make sure everything looks the way you&#8217;d expect.

**Make the machines do it**

Well dear friends, we have reached the end. You&#8217;ve walk through the fire and come through unscathed. Of course, this seems like a lot of work to go through, especially if you have to do this more than once. I agree, so I whipped up a quick script to help you out. You can grab it from my Github [repo][33]. It&#8217;s pretty basic right now, but I&#8217;m hoping to add to it and make it more useful, but we&#8217;ll see.

Drop a note in the comments if you have any problems and I&#8217;ll see if I can help out.

Happy mapping!

<hr class="footnotes" />

<ol class="footnotes">
<li id="fn1-813">
shout out to the OSGeo guys for their work on porting some popular packages. Keep up the good work!<a href="#rf1-813" class="backlink" title="Jump back to footnote 1 in the text.">&#8617;</a>
</li>

<li id="fn2-813">
I&#8217;m pretty sure the version of QGIS shipped with Ubuntu is the same one Moses used to teach the Israelites, but I can&#8217;t be sure.<a href="#rf2-813" class="backlink" title="Jump back to footnote 2 in the text.">&#8617;</a>
</li>

<li id="fn3-813">
Not to mention ones that actually build<a href="#rf3-813" class="backlink" title="Jump back to footnote 3 in the text.">&#8617;</a>
</li>

<li id="fn4-813">
Observant readers will notice that I left out the QGIS install, that&#8217;s not because QGIS and I are on the outs, but just that I&#8217;ve had mixed success actually getting it to compile. If you&#8217;re feeling adventurous by all means give it a go, but since it&#8217;s not absolutely necessary for this tutorial, I&#8217;ve left it out. <a href="#rf4-813" class="backlink" title="Jump back to footnote 4 in the text.">&#8617;</a>
</li>

<li id="fn5-813">
GRASS really doesn&#8217;t like commas, so I make sure to use pipes, but maybe you&#8217;re a nicer person than me, and can get away with it.<a href="#rf5-813" class="backlink" title="Jump back to footnote 5 in the text.">&#8617;</a>
</li>

<li id="fn6-813">
At this point, you may be curious as to the weird codes at the end of the command names. Those represent that actual commands that the gui is running. V is for vector functions, R for raster, this comes in really handy if you&#8217;re automating things, or if you&#8217;re not sure which function to run on your data.<a href="#rf6-813" class="backlink" title="Jump back to footnote 6 in the text.">&#8617;</a>
</li>

<li id="fn7-813">
Or, you could just go get an intern to do all of this for you.<a href="#rf7-813" class="backlink" title="Jump back to footnote 7 in the text.">&#8617;</a>
</li>

<li id="fn8-813">
On my 2012 Macbook Air it takes about 11 minutes to build the heatmap.<a href="#rf8-813" class="backlink" title="Jump back to footnote 8 in the text.">&#8617;</a>
</li>

<li id="fn9-813">
While I may say &#8216;remove&#8217;, &#8216;chop&#8217;, &#8216;exorcise&#8217; in reality we&#8217;re not removing anything from the image (the size and content stays the same), all we&#8217;re doing is modifying the raster table to indicate which points have a NULL value. After all, a rose by another other name&#8230;.<a href="#rf9-813" class="backlink" title="Jump back to footnote 9 in the text.">&#8617;</a>
</li>

<li id="fn10-813">
take a moment to marvel at what a GUI is supposed to look like.<a href="#rf10-813" class="backlink" title="Jump back to footnote 10 in the text.">&#8617;</a>
</li>
</ol>

[1]: http://grass.osgeo.org/ "GRASS for the MASSES"
[2]: http://www.nickrobison.com/2013/07/03/compile-saga-for-mac-os-x/ "Compile SAGA for Mac OS X"
[3]: http://trac.osgeo.org/osgeo4w/
[4]: http://brew.sh "Do you brew?"
[5]: https://www.google.com/url?sa&#61;t&#38;rct&#61;j&#38;q&#61;&#38;esrc&#61;s&#38;source&#61;web&#38;cd&#61;1&#38;cad&#61;rja&#38;uact&#61;8&#38;ved&#61;0CCAQFjAA&#38;url&#61;http%3A%2F%2Fen.wikipedia.org%2Fwiki%2FWorld_Geodetic_System&#38;ei&#61;1AYGVPn_KdPJgwTNnYKQDw&#38;usg&#61;AFQjCNG6hY1N2uckXgX7a2giTmhcx_5GrA&#38;bvm&#61;bv.74115972,d.eXY "WGS84"
[6]: https://files.nickrobison.com/images/2014/09/Screen-Shot-2014-09-02-at-2.16.06-PM.png
[7]: https://files.nickrobison.com/images/2014/09/Screen-Shot-2014-09-02-at-2.22.44-PM.png
[8]: https://files.nickrobison.com/images/2014/09/Screen-Shot-2014-09-02-at-2.30.29-PM.png
[9]: https://files.nickrobison.com/images/2014/09/Screen-Shot-2014-09-02-at-2.36.25-PM.png
[10]: https://files.nickrobison.com/images/2014/09/Screen-Shot-2014-09-02-at-2.42.24-PM.png
[11]: https://files.nickrobison.com/images/2014/09/Screen-Shot-2014-09-02-at-3.03.42-PM.png
[12]: https://files.nickrobison.com/images/2014/09/Screen-Shot-2014-09-02-at-3.20.43-PM.png
[13]: https://files.nickrobison.com/images/2014/09/Screen-Shot-2014-09-02-at-3.25.59-PM.png
[14]: https://files.nickrobison.com/images/2014/09/Screen-Shot-2014-09-02-at-3.26.20-PM.png
[15]: https://files.nickrobison.com/images/2014/09/Screen-Shot-2014-09-02-at-3.45.04-PM.png
[16]: https://files.nickrobison.com/images/2014/09/Screen-Shot-2014-09-02-at-3.58.08-PM.png
[17]: https://files.nickrobison.com/images/2014/09/Screen-Shot-2014-09-02-at-4.05.35-PM.png
[18]: https://files.nickrobison.com/images/2014/09/Screen-Shot-2014-09-02-at-4.07.55-PM.png
[19]: https://files.nickrobison.com/images/2014/09/Screen-Shot-2014-09-02-at-4.08.57-PM.png
[20]: https://files.nickrobison.com/images/2014/09/Screen-Shot-2014-09-02-at-4.13.51-PM.png
[21]: http://grass.osgeo.org/grass65/manuals/r.recode.html "GRASS Recoding"
[22]: https://files.nickrobison.com/images/2014/09/Screen-Shot-2014-09-02-at-4.31.59-PM.png
[23]: https://files.nickrobison.com/images/2014/09/Screen-Shot-2014-09-04-at-3.21.21-PM.png
[24]: https://files.nickrobison.com/images/2014/09/Screen-Shot-2014-09-04-at-3.36.18-PM.png
[25]: http://grass.osgeo.org/grass64/manuals/r.out.gdal.html "GRASS ESRI Compatibility"
[26]: https://files.nickrobison.com/images/2014/09/Screen-Shot-2014-09-02-at-4.48.41-PM.png
[27]: https://www.mapbox.com/tilemill/ "TileMill"
[28]: https://files.nickrobison.com/images/2014/09/Screen-Shot-2014-09-02-at-4.55.24-PM.png
[29]: https://www.mapbox.com/tilemill/docs/guides/osm-bright-mac-quickstart/ "OSM Bright Instructions"
[30]: http://mapnik.org/ "Mapnik"
[31]: http://tilestache.org/ "A stache for your tiles."
[32]: http://iterm2.com/ "The Real Terminal"
[33]: https://github.com/nickrobison/GrassMaps "GrassMaps Script"