<div class="kcite-section" kcite-section-id="813">
  <p>
    Recently, I&#8217;ve been working on a project that involves a fair amount of GIS work, specifically plotting a bunch of points on a map and finding useful ways to visualize them. It turns out, this is a bit harder than I&#8217;d originally hoped. For starters, GIS software support on OS X is abysmal<sup id="rf1-813"><a href="#fn1-813" title="shout out to the OSGeo guys for their work on porting some popular packages. Keep up the good work!" rel="footnote">1</a></sup> so while it&#8217;s fairly easy to build some nice stuff in QGIS, getting it to compile is a bit hit or miss. Second, if you need to do things programmatically you&#8217;ll need something that exposes nice bindings for your language of choice.
  </p>
  
  <p>
    Enter <a title="GRASS for the MASSES" href="http://grass.osgeo.org/">GRASS</a>. GRASS is the software package that underlies almost every single open source GIS program (and probably plays a significant role in closed-source ones as well), it&#8217;s incredibly powerful and capable of performing just about any operation a budding cartographer could ever hope or dream of. In addition, it may also hold the distinction of being the most unfriendly program that I have ever had the displeasure of using. So, what may sound like an easy task (take some points, throw them on map, plot their densities) turns out to be quite an undertaking, so to spare you the pain, I figured I&#8217;d write up a quick (or not so quick as the case may be) walkthrough.
  </p>
  
  <p>
    So, today dear friends, we&#8217;re going to go through the process of building some nice raster heatmaps and visualize them using Tilemill. I&#8217;m assuming you have a nice CSV file with latitude and longitude pairs that you&#8217;ve acquired from somewhere like Twitter. I&#8217;m also assuming that the end result will be using these maps to display with some sort of web service like OpenStreetMaps or GoogleMaps. This will be become important in a bit, so just keep in mind that you may have to modify a few things as we go along. So without further ado, let&#8217;s get started.
  </p>
  
  <p>
    <strong>Installation</strong>
  </p>
  
  <p>
    Installing GIS software used to be a <a title="Compile SAGA for Mac OS X" href="http://www.nickrobison.com/2013/07/03/compile-saga-for-mac-os-x/">huge</a> pain, but fortunately over the past year or so things have gotten significantly easier. Here&#8217;s a quick rundown of how to get the software installed, but as always, each system has its own quirks so there may be some extra things you need to consider.
  </p>
  
  <p>
    <em>Windows</em>
  </p>
  
  <p>
    This is probably the easiest of them all, again the OSGeo team has done all the hard work for you. Just grab the <a href="http://trac.osgeo.org/osgeo4w/">OsGeo4W</a> installer and select <em>Express Desktop Install</em> on the first page, keep the defaults and it&#8217;ll download and install everything you need. If you feel like being fancy, you can also customize each individual package and dependency, but maybe you should just read a book or browse Reddit instead.
  </p>
  
  <p>
    <em>Linux</em>
  </p>
  
  <p>
    Linux has a great home-field advantage and most software works and feels most natural here. Unfortunately, most of the distribution packages are quite outdated<sup id="rf2-813"><a href="#fn2-813" title="I&rsquo;m pretty sure the version of QGIS shipped with Ubuntu is the same one Moses used to teach the Israelites, but I can&rsquo;t be sure." rel="footnote">2</a></sup> so it&#8217;s a good idea to grab a more up-to-date repository. Here&#8217;s how to do so on Ubuntu:
  </p>
  
  <pre class="brush: bash; title: ; notranslate" title="">

sudo add-apt-repository ppa:ubuntugis/ubuntugis-unstable

sudo apt-get update

sudo apt-get install qgis grass70-core grass70-gui gdal-bin python-gdal

</pre>
  
  <p>
    <em>OS X</em>
  </p>
  
  <p>
    If you&#8217;d like, the OSGeo team has pre-built packages that install without much effort, but because of the huge number of dependencies, and all the funky GUI frameworks, I think the easiest way is to just use homebrew.
  </p>
  
  <p>
    If you&#8217;re not <a title="Do you brew?" href="http://brew.sh">homebrewing</a> yet, well, why not? Once you get it setup and configured you&#8217;ll need the OsGeo4Mac branch in order to get the latest and greatest versions<sup id="rf3-813"><a href="#fn3-813" title="Not to mention ones that actually build" rel="footnote">3</a></sup>, you can leave everything at the defaults, or if you&#8217;re like me and you never met a compile flag you didn&#8217;t love, you can customize all the dependencies to your little heart&#8217;s content, like so:
  </p>
  
  <pre class="brush: bash; title: ; notranslate" title="">

brew tap osgeo/osgeo4mac

brew install gdal --complete --enable-armadillo --enable-opencl --with-libkml --with-python

brew install grass-70 --with-liblas --with-netcdf --with-postgresql

</pre>
  
  <p>
    Now, grab a cup of coffee and wait for everything to compile.<sup id="rf4-813"><a href="#fn4-813" title="Observant readers will notice that I left out the QGIS install, that&rsquo;s not because QGIS and I are on the outs, but just that I&rsquo;ve had mixed success actually getting it to compile. If you&rsquo;re feeling adventurous by all means give it a go, but since it&rsquo;s not absolutely necessary for this tutorial, I&rsquo;ve left it out. " rel="footnote">4</a></sup>
  </p>
  
  <p>
    <strong>Ingest the data</strong>
  </p>
  
  <p>
    Great, now that we&#8217;ve got the software installed let&#8217;s load the data.
  </p>
  
  <p>
    Fire up the GRASS GUI and take a look at the first screen. GRASS has a couple of concepts that are important to keep in mind.
  </p>
  
  <ol>
    <li>
      Everything happens in a <em>location, </em>which is basically a project set within a certain geographic boundary. This is where you keep all the maps and resources that your project requires. A location also has a specific projection and coordinate system, so if you&#8217;re working on a project with data in different coordinate systems, you&#8217;ll need multiple locations, even if the datasets are in the same geographic region (we&#8217;ll get to enjoy this little <del>bug</del> feature soon enough).
    </li>
    <li>
      Within each location is one or more <em>mapsets, </em>a mapset is a collection of GIS resources for a specific purpose. For example, if multiple people are working on the same project, they may each have their mapsets, with their own resources. Or, if you&#8217;re working on a project that involves both vector data (like points and shapefiles) and maybe some raster data (like satellite images) you could keep those in two different mapsets. For this project, we&#8217;ll keep everything in one set, just to make it easier.
    </li>
  </ol>
  
  <p>
    So now let&#8217;s load some data, but before we do that, we need to know a few details. First, we have to decide what projection system we want to display our data in. Since the goal of this project is to overlay the heatmap on web maps such as Google, we would probably choose that projection system (EPSG: 3857). Not so fast, Google&#8217;s project is actually quite wonky (in order to preserve angles for streetview) and is difficult to project into. Recent software libraries (like the proj4 engine, which is what everything else uses) have some added parameters to compensate for this, but in my experience GRASS (even the recent version 7 betas, which is what I&#8217;m using in this tutorial) doesn&#8217;t do the conversion correctly. So instead, we&#8217;ll want to use something else, and then either re-project on the fly, or do the projection using proj4 directly (we&#8217;ll get to this later). I recommended using EPSG 3395, and here&#8217;s why; a lot of the data that involves coordinate pairs (like Twitter data or GPS coordinates) uses the <a title="WGS84" href="https://www.google.com/url?sa=t&rct=j&q=&esrc=s&source=web&cd=1&cad=rja&uact=8&ved=0CCAQFjAA&url=http%3A%2F%2Fen.wikipedia.org%2Fwiki%2FWorld_Geodetic_System&ei=1AYGVPn_KdPJgwTNnYKQDw&usg=AFQjCNG6hY1N2uckXgX7a2giTmhcx_5GrA&bvm=bv.74115972,d.eXY">WGS84</a> coordinate system, while this works great for plotting points on a map, it&#8217;s not very useful for doing more advanced analysis since the unit scale changes in relation to your distance from the equator  So, if we choose EPSG 3395 (which is WGS84 projected) we can project the data into a constant scale, but not worry about other artifacts that might crop up from converting between completely different coordinate systems.
  </p>
  
  <p>
    So, now we need to ingest the data (which is WGS84) and convert it to WGS84-projected in order to do the analysis (remember GRASS only allows 1 coordinate system, per location). Here&#8217;s how:
  </p>
  
  <ol>
    <li>
      Define a location to hold the point data. Click the <em>Location Wizard</em> button on the right side of the opening GRASS screen,  give it a location name, a location title, and click <em>Next</em>. For this part, we&#8217;ll use <em>heat_pts,</em> to indicate the point data.
    </li>
    <li>
      Since we know the projection system we want to use (WGS84) and we know the EPSG code (4326, memorize that) we want to use the <em>Select EPSG code of spatial reference system </em>choice. The other options are quite useful if you have data in an existing data format that defines its own projection (such as a shapefile), or if you don&#8217;t know the correct EPSG code and need to look it up. Click <em>Next.</em>
    </li>
    <li>
      Enter the code (4326) in the <em>EPSG code</em> box and click <em>Next. </em>You should see something like this:
    </li>
  </ol><figure id="attachment_819" style="width: 300px" class="wp-caption aligncenter">
  
  <a href="http://www.nickrobison.com/wp-content/uploads/2014/09/Screen-Shot-2014-09-02-at-2.16.06-PM.png"><img class="size-medium wp-image-819" src="http://www.nickrobison.com/wp-content/uploads/2014/09/Screen-Shot-2014-09-02-at-2.16.06-PM-300x213.png" alt="Note the warning about the changing dimensions, GRASS really wants projected coordinates, and wants you to know about it." width="300" height="213" srcset="https://www.nickrobison.com/wp-content/uploads/2014/09/Screen-Shot-2014-09-02-at-2.16.06-PM-300x213.png 300w, https://www.nickrobison.com/wp-content/uploads/2014/09/Screen-Shot-2014-09-02-at-2.16.06-PM.png 1022w" sizes="(max-width: 300px) 100vw, 300px" /></a><figcaption class="wp-caption-text">Note the warning about the changing dimensions, GRASS really wants projected coordinates, and wants you to know about it.</figcaption></figure> 
  
  <p>
    4. Click <em>OK</em> on the warning box and you should see a final screen that gives all the relevant information about the location. If you&#8217;d like, you can copy down the proj4 string, they&#8217;re often times a useful reference in telling other software (like Tilemilll, hint, hint) how to display your data. Click <em>Finish</em>.
  </p>
  
  <p>
    5. Finally, if should give you an option to define the region and extents before you load any data, this doesn&#8217;t really matter when working with vector data, but it matters a great deal with rasters. Often times, it&#8217;s easiest to load your data and then have GRASS calculate that data for you. So for now, we&#8217;ll just click <em>No</em>.<em><br /> </em>
  </p>
  
  <p>
    6. Go ahead and click <em>OK</em> to create a new mapset, if you&#8217;d like, you can keep everything in <em>PERMANENT</em>, the default GRASS set, but that&#8217;s up to you.
  </p>
  
  <p>
    7. Finally, click <i>Start GRASS</i><em> </em>and revel in its GUI goodness.
  </p><figure id="attachment_820" style="width: 300px" class="wp-caption aligncenter">
  
  <a href="http://www.nickrobison.com/wp-content/uploads/2014/09/Screen-Shot-2014-09-02-at-2.22.44-PM.png"><img class="size-medium wp-image-820" src="http://www.nickrobison.com/wp-content/uploads/2014/09/Screen-Shot-2014-09-02-at-2.22.44-PM-300x141.png" alt="Hello 1997, it's good to see you again." width="300" height="141" srcset="https://www.nickrobison.com/wp-content/uploads/2014/09/Screen-Shot-2014-09-02-at-2.22.44-PM-300x141.png 300w, https://www.nickrobison.com/wp-content/uploads/2014/09/Screen-Shot-2014-09-02-at-2.22.44-PM-1024x482.png 1024w, https://www.nickrobison.com/wp-content/uploads/2014/09/Screen-Shot-2014-09-02-at-2.22.44-PM.png 1343w" sizes="(max-width: 300px) 100vw, 300px" /></a><figcaption class="wp-caption-text">Hello 1997, it&#8217;s good to see you again.</figcaption></figure> 
  
  <p>
    8. I know right, you haven&#8217;t gotten this excited about an interface since you fired up Windows 95 for the first time. Actually, that&#8217;s probably the last time the interface was updated, but since we&#8217;re true nerds we&#8217;re not deterred by what we see, so we press on. Now we need to load our data. Since it&#8217;s simply a collection of point values we need to tell GRASS to read the file and turn each line into a unique point. To do so,  select <em>ASCII points or GRASS ASCII format [v.in.ascii]</em> under the <em>File -> Import vector data</em> menu.
  </p>
  
  <p>
    On the <em>Required </em>screen, load your input file, and give the resulting map layer a name (since my data is a bunch of Tweets from the Atlanta metro area, I&#8217;m going to be super clever and call my layer <em>atlanta_pts</em>, but you can do whatever floats your boat). Make sure the <em>Add created map[s] into layer tree</em> stays selected.
  </p><figure id="attachment_823" style="width: 300px" class="wp-caption aligncenter">
  
  <a href="http://www.nickrobison.com/wp-content/uploads/2014/09/Screen-Shot-2014-09-02-at-2.30.29-PM.png"><img class="size-medium wp-image-823" src="http://www.nickrobison.com/wp-content/uploads/2014/09/Screen-Shot-2014-09-02-at-2.30.29-PM-300x266.png" alt="Yours should look something like this." width="300" height="266" srcset="https://www.nickrobison.com/wp-content/uploads/2014/09/Screen-Shot-2014-09-02-at-2.30.29-PM-300x266.png 300w, https://www.nickrobison.com/wp-content/uploads/2014/09/Screen-Shot-2014-09-02-at-2.30.29-PM.png 691w" sizes="(max-width: 300px) 100vw, 300px" /></a><figcaption class="wp-caption-text">Yours should look something like this.</figcaption></figure> 
  
  <p>
    For the next step, we need to know the format of our data, mine looks like this:
  </p>
  
  <pre class="brush: bash; title: ; notranslate" title="">

id|lon|lat
30953|-84.34088988456551|33.73738463926367
1047391|-84.37350085502241|33.83837966067272
1561491|-84.40617218844126|33.71876940960077
1810701|-84.38021346457639|33.76925580504283
2083571|-84.41194434775504|33.7856184006737
3956151|-84.43781233345071|33.80593333398135
4359371|-84.32801349864327|33.75361426020218
5161921|-84.30200782720981|33.83737260488842
5753742|-84.42793996359265|33.67073527455402

</pre>
  
  <p>
    There are a couple of things to note:
  </p>
  
  <ul>
    <li>
      It has a header, so we need to tell GRASS to skip one line.
    </li>
    <li>
      The columns are separated by pipes, not tabs or commas.<sup id="rf5-813"><a href="#fn5-813" title="GRASS really doesn&rsquo;t like commas, so I make sure to use pipes, but maybe you&rsquo;re a nicer person than me, and can get away with it." rel="footnote">5</a></sup>
    </li>
    <li>
      It&#8217;s in a longitude/latitude sequence.
    </li>
  </ul>
  
  <p>
    On the <em>Input Format</em> tab, make sure the <em>Input file format </em>is set to <em>point</em> and that the <em>Field separator</em> is set correctly (here, it needs to be pipes).
  </p><figure id="attachment_825" style="width: 300px" class="wp-caption aligncenter">
  
  <a href="http://www.nickrobison.com/wp-content/uploads/2014/09/Screen-Shot-2014-09-02-at-2.36.25-PM.png"><img class="size-medium wp-image-825" src="http://www.nickrobison.com/wp-content/uploads/2014/09/Screen-Shot-2014-09-02-at-2.36.25-PM-300x266.png" alt="Pretty simple so far." width="300" height="266" srcset="https://www.nickrobison.com/wp-content/uploads/2014/09/Screen-Shot-2014-09-02-at-2.36.25-PM-300x266.png 300w, https://www.nickrobison.com/wp-content/uploads/2014/09/Screen-Shot-2014-09-02-at-2.36.25-PM.png 691w" sizes="(max-width: 300px) 100vw, 300px" /></a><figcaption class="wp-caption-text">Pretty simple so far.</figcaption></figure> 
  
  <p>
    The <em>Points</em> screen is where things get tricky. To be safe, leave everything at the defaults, unless you specifically need to change it.
  </p>
  
  <ul>
    <li>
      Set <em>Number of header lines to to skip at top of input file (points mode)</em> to 1.
    </li>
    <li>
      Set <em>Number of column used as X coordinate (points mode)</em> to 2.
    </li>
    <li>
      Set <em>Number of column used as Y coordinate (points mode) </em> to 3.
    </li>
  </ul>
  
  <p>
    Hold up, where did X/Y come from? All I have is lat/lon. Correct, but now we&#8217;re dealing with projected coordinate systems and they don&#8217;t think in terms of geography, they think in terms of geometry, so everything is X/Y. Here&#8217;s really what you need to know:
  </p>
  
  <p>
    Longitude = X coordinate
  </p>
  
  <p>
    Latitude = Y coordinate
  </p>
  
  <p>
    Keep that straight and you&#8217;ll be in Cartesian heaven.
  </p><figure id="attachment_826" style="width: 296px" class="wp-caption aligncenter">
  
  <a href="http://www.nickrobison.com/wp-content/uploads/2014/09/Screen-Shot-2014-09-02-at-2.42.24-PM.png"><img class="size-medium wp-image-826" src="http://www.nickrobison.com/wp-content/uploads/2014/09/Screen-Shot-2014-09-02-at-2.42.24-PM-296x300.png" alt="Or, how I learned to stop worrying and love the defaults." width="296" height="300" srcset="https://www.nickrobison.com/wp-content/uploads/2014/09/Screen-Shot-2014-09-02-at-2.42.24-PM-296x300.png 296w, https://www.nickrobison.com/wp-content/uploads/2014/09/Screen-Shot-2014-09-02-at-2.42.24-PM.png 691w" sizes="(max-width: 296px) 100vw, 296px" /></a><figcaption class="wp-caption-text">Or, how I learned to stop worrying and love the defaults.</figcaption></figure> 
  
  <p>
    Feel free to check out the other tabs, tweak some settings, or read the man pages (yeah right). Me, I&#8217;m too impatient so I&#8217;m just going to click <em>Run</em> and move on.
  </p>
  
  <p>
    That&#8217;ll run for a brief moment (depending on how much data you have) and once it&#8217;s done you may have a blank screen. If so, don&#8217;t panic, in the <em>Layer Manager</em> window, click the little funky icon (I have no idea what the symbology means) next to the layer called <em>atlanta_points@[mapset name]</em> and select <em>Zoom to selected map(s). </em>Here&#8217;s what it looks like for me:
  </p><figure id="attachment_827" style="width: 300px" class="wp-caption aligncenter">
  
  <a href="http://www.nickrobison.com/wp-content/uploads/2014/09/Screen-Shot-2014-09-02-at-3.03.42-PM.png"><img class="size-medium wp-image-827" src="http://www.nickrobison.com/wp-content/uploads/2014/09/Screen-Shot-2014-09-02-at-3.03.42-PM-300x140.png" alt="Seems like a lot of work thus far...." width="300" height="140" srcset="https://www.nickrobison.com/wp-content/uploads/2014/09/Screen-Shot-2014-09-02-at-3.03.42-PM-300x140.png 300w, https://www.nickrobison.com/wp-content/uploads/2014/09/Screen-Shot-2014-09-02-at-3.03.42-PM-1024x480.png 1024w, https://www.nickrobison.com/wp-content/uploads/2014/09/Screen-Shot-2014-09-02-at-3.03.42-PM.png 1333w" sizes="(max-width: 300px) 100vw, 300px" /></a><figcaption class="wp-caption-text">Seems like a lot of work thus far&#8230;.</figcaption></figure> 
  
  <p>
    Congrats! You now have point data in GRASS. Now, let&#8217;s get to the fun part, building the heatmaps.
  </p>
  
  <p>
    <strong>Rasterize.</strong>
  </p>
  
  <p>
    Now we have data, but remember, it&#8217;s in geographic WGS84, and we need projected WGS84. So now, we need to create a new location with the correct projection and somehow load our point data into it. Fortunately, GRASS allows you to re-project data from one location, to another and it handles all the backend calculations. So let&#8217;s do that.
  </p>
  
  <ol>
    <li>
      Under <em>Settings -> GRASS Working Environment</em> select <em>Create new location.</em>
    </li>
    <li>
      Follow the same process as above, but give it a different name, and enter EPSG code <em>3395</em> which is the projected version of WGS84. I&#8217;m calling my location <em>heatmap</em> because I&#8217;m not very creative, but you shouldn&#8217;t sink down to my level. Click <em>Finish</em> and when prompted switch to the new location. If it asks you to store the current settings you can say no, because we shouldn&#8217;t have to open our <em>heat_pts</em> location again. Finally, when prompted to set the default region and extents you need to say no, because we&#8217;re going to have GRASS do that for us based on our existing point data (we&#8217;ll come back to this later).
    </li>
    <li>
      Now we need to import our point data and reproject it into our new coordinate system. In the top menu navigate to <em>Vector -> Develop Vector Map</em> and select <em>Reproject vector map from different GRASS location [v.proj].</em><sup id="rf6-813"><a href="#fn6-813" title="At this point, you may be curious as to the weird codes at the end of the command names. Those represent that actual commands that the gui is running. V is for vector functions, R for raster, this comes in really handy if you&rsquo;re automating things, or if you&rsquo;re not sure which function to run on your data." rel="footnote">6</a></sup>
    </li>
    <li>
      Under the <em>Required </em>tab set <em>Location containing input vector map</em> to the location we loaded the point data into (e.g. <em>heat_pts).</em>
    </li>
    <li>
      Under <em>Source</em> set the correct <em>Mapset</em> and <em>input vector</em>. You can leave everything else at the defaults and click <em>Run.</em>
    </li>
  </ol><figure id="attachment_828" style="width: 300px" class="wp-caption aligncenter">
  
  <a href="http://www.nickrobison.com/wp-content/uploads/2014/09/Screen-Shot-2014-09-02-at-3.20.43-PM.png"><img class="size-medium wp-image-828" src="http://www.nickrobison.com/wp-content/uploads/2014/09/Screen-Shot-2014-09-02-at-3.20.43-PM-300x266.png" alt="Pretty straight forward." width="300" height="266" srcset="https://www.nickrobison.com/wp-content/uploads/2014/09/Screen-Shot-2014-09-02-at-3.20.43-PM-300x266.png 300w, https://www.nickrobison.com/wp-content/uploads/2014/09/Screen-Shot-2014-09-02-at-3.20.43-PM.png 646w" sizes="(max-width: 300px) 100vw, 300px" /></a><figcaption class="wp-caption-text">Pretty straight forward.</figcaption></figure> 
  
  <p>
    6. Once that&#8217;s finished you can follow the same process above to zoom to the selected layer and you should see exactly what we saw in the other location.
  </p>
  
  <p>
    7. Now we&#8217;re almost ready to generate the heatmap, but first we need to tell GRASS what region of data we&#8217;re interested in, and how many individual &#8216;cells&#8217; to process. While a clever user would probably have some fancy method for doing this themselves, I tend to trust robots more than my own brain so I&#8217;ll just let GRASS figure it out. To do so, select <em>Settings -> Region -> Set Region [g.region]. </em>In the window that opens, we want to set <em>[multiple] Set region to match vector map(s)</em> to the vector layer that we just imported, then click <em>Run</em>.
  </p><figure id="attachment_829" style="width: 300px" class="wp-caption aligncenter">
  
  <a href="http://www.nickrobison.com/wp-content/uploads/2014/09/Screen-Shot-2014-09-02-at-3.25.59-PM.png"><img class="size-medium wp-image-829" src="http://www.nickrobison.com/wp-content/uploads/2014/09/Screen-Shot-2014-09-02-at-3.25.59-PM-300x288.png" alt="What's old, is new again." width="300" height="288" srcset="https://www.nickrobison.com/wp-content/uploads/2014/09/Screen-Shot-2014-09-02-at-3.25.59-PM-300x288.png 300w, https://www.nickrobison.com/wp-content/uploads/2014/09/Screen-Shot-2014-09-02-at-3.25.59-PM.png 690w" sizes="(max-width: 300px) 100vw, 300px" /></a><figcaption class="wp-caption-text">What&#8217;s old, is new again.</figcaption></figure> 
  
  <p>
    We can verify that this actually worked by running <em>Settings -> Region -> Display Region [g.region -p]</em> and viewing the resulting output. What we&#8217;re interested in is the <em>rows </em>and <em>cols</em> values. Basically, we don&#8217;t want them to be 0. If when we generate the heatmap it comes out looking like a single color square, that means we didn&#8217;t set the region correctly and GRASS is assuming we want everything merged down into a single cell, which doesn&#8217;t work. It&#8217;s also important to note that GRASS can&#8217;t set a region based on geographic coordinates (because the distance is always changing), so if you run the <em>Set Region </em>command and it doesn&#8217;t have any effect, it may be that you&#8217;ve set your location&#8217;s coordinate system to a non-projected system.
  </p><figure id="attachment_830" style="width: 268px" class="wp-caption aligncenter">
  
  <a href="http://www.nickrobison.com/wp-content/uploads/2014/09/Screen-Shot-2014-09-02-at-3.26.20-PM.png"><img class="size-medium wp-image-830" src="http://www.nickrobison.com/wp-content/uploads/2014/09/Screen-Shot-2014-09-02-at-3.26.20-PM-268x300.png" alt="Are they 0? Nope? Good. Move on." width="268" height="300" srcset="https://www.nickrobison.com/wp-content/uploads/2014/09/Screen-Shot-2014-09-02-at-3.26.20-PM-268x300.png 268w, https://www.nickrobison.com/wp-content/uploads/2014/09/Screen-Shot-2014-09-02-at-3.26.20-PM.png 639w" sizes="(max-width: 268px) 100vw, 268px" /></a><figcaption class="wp-caption-text">Are they 0? Nope? Good. Move on.</figcaption></figure> 
  
  <p>
    8. Now, we&#8217;re ready to make the heatmap. Yes, dear reader you&#8217;re probably right. ArcGIS could&#8217;ve done this in 1/4th the time. But look on the bright side, yes you&#8217;ve spent all this time fussing with a GUI only a mother could love, but now you can take that $2700/year that you save in licensing fees and go buy beer, a lot of beer.<sup id="rf7-813"><a href="#fn7-813" title="Or, you could just go get an intern to do all of this for you." rel="footnote">7</a></sup> That aside, in the <em>Raster</em> top menu, select <em>Generate Surface -> Gaussian kernel density surface [v.kernel]</em>. In the <em>Required</em> tab we need to set all the options. Since we only have 1 vector layer, that should be selected for us already. Next, we want to give our output layer a name, so set <em>Name for output raster/vector map</em> to something useful (I&#8217;m using <em>heatmap_500).</em>
  </p>
  
  <p>
    Finally, we need to set <em>Kernel radius in map units.</em> Here&#8217;s where things get tricky, this final option is telling GRASS how big of an area to consider when figuring out how much to weight each individual point. There are a number of factors to consider when making this decision and they&#8217;re definitely outside the scope of this article, but a helpful question to ask, is what types of effects are you looking for? Are you looking for effects on a city block level? A county level? Regional? The answer to that question is going to determine how big or small to set the radius. For this project, I&#8217;m thinking 500m should give me the results I&#8217;m looking for. Remember, the radius is in <em>map units</em>, which is determined by the coordinate system you chose. Here, the units are in meters, so I&#8217;m choosing 500. Simple enough.
  </p><figure id="attachment_831" style="width: 300px" class="wp-caption aligncenter">
  
  <a href="http://www.nickrobison.com/wp-content/uploads/2014/09/Screen-Shot-2014-09-02-at-3.45.04-PM.png"><img class="size-medium wp-image-831" src="http://www.nickrobison.com/wp-content/uploads/2014/09/Screen-Shot-2014-09-02-at-3.45.04-PM-300x274.png" alt="Click on the other tabs at your own peril. There's a lot you can screw up in very little time." width="300" height="274" srcset="https://www.nickrobison.com/wp-content/uploads/2014/09/Screen-Shot-2014-09-02-at-3.45.04-PM-300x274.png 300w, https://www.nickrobison.com/wp-content/uploads/2014/09/Screen-Shot-2014-09-02-at-3.45.04-PM.png 670w" sizes="(max-width: 300px) 100vw, 300px" /></a><figcaption class="wp-caption-text">Click on the other tabs at your own peril. There&#8217;s a lot you can screw up in very little time.</figcaption></figure> 
  
  <p>
    You can leave everything else at the defaults and then click <em>Run</em>. Now, go get some more coffee because this could take a while<sup id="rf8-813"><a href="#fn8-813" title="On my 2012 Macbook Air it takes about 11 minutes to build the heatmap." rel="footnote">8</a></sup>.
  </p>
  
  <p>
    9. Once it&#8217;s done processing and you&#8217;re all hopped up on caffeine, take that jittery mouse and try to click on this icon in the <em>Layer Manager </em>window:
  </p><figure id="attachment_834" style="width: 36px" class="wp-caption aligncenter">
  
  <a href="http://www.nickrobison.com/wp-content/uploads/2014/09/Screen-Shot-2014-09-02-at-3.58.08-PM.png"><img class="size-full wp-image-834" src="http://www.nickrobison.com/wp-content/uploads/2014/09/Screen-Shot-2014-09-02-at-3.58.08-PM.png" alt="What do you call this?" width="36" height="33" /></a><figcaption class="wp-caption-text">What do you call this?</figcaption></figure> 
  
  <p>
    I have no idea how to describe that icon, but if you hover over all the options, the tooltip you want is <em>Add Raster Map Layer</em>. Click it, and select the raster map it just generated (it should be the only one in the mapset). Boom, we have map, people!
  </p>
  
  <p>
    10. Now, the default color ramp is pretty compressed and makes it hard to see things, so we should change that. Again, click the layer dropdown menu (the one to the right of the name) and select <i>Set color table</i>.
  </p><figure id="attachment_833" style="width: 266px" class="wp-caption aligncenter">
  
  <a href="http://www.nickrobison.com/wp-content/uploads/2014/09/Screen-Shot-2014-09-02-at-4.05.35-PM.png"><img class="size-medium wp-image-833" src="http://www.nickrobison.com/wp-content/uploads/2014/09/Screen-Shot-2014-09-02-at-4.05.35-PM-266x300.png" alt="Click it." width="266" height="300" srcset="https://www.nickrobison.com/wp-content/uploads/2014/09/Screen-Shot-2014-09-02-at-4.05.35-PM-266x300.png 266w, https://www.nickrobison.com/wp-content/uploads/2014/09/Screen-Shot-2014-09-02-at-4.05.35-PM.png 537w" sizes="(max-width: 266px) 100vw, 266px" /></a><figcaption class="wp-caption-text">Click it.</figcaption></figure> 
  
  <p>
    Next, click on the <em>Define</em> tab and select which ever option you want under the <em>Name of color table</em> dropdown. (Personally, I like the <em>bgyr</em>). Click <em>Run</em> and revel in the colored goodness.
  </p><figure id="attachment_835" style="width: 278px" class="wp-caption aligncenter">
  
  <a href="http://www.nickrobison.com/wp-content/uploads/2014/09/Screen-Shot-2014-09-02-at-4.07.55-PM.png"><img class="size-medium wp-image-835" src="http://www.nickrobison.com/wp-content/uploads/2014/09/Screen-Shot-2014-09-02-at-4.07.55-PM-278x300.png" alt="Designer's choice." width="278" height="300" srcset="https://www.nickrobison.com/wp-content/uploads/2014/09/Screen-Shot-2014-09-02-at-4.07.55-PM-278x300.png 278w, https://www.nickrobison.com/wp-content/uploads/2014/09/Screen-Shot-2014-09-02-at-4.07.55-PM.png 714w" sizes="(max-width: 278px) 100vw, 278px" /></a><figcaption class="wp-caption-text">Designer&#8217;s choice.</figcaption></figure> <figure id="attachment_836" style="width: 300px" class="wp-caption aligncenter"><a href="http://www.nickrobison.com/wp-content/uploads/2014/09/Screen-Shot-2014-09-02-at-4.08.57-PM.png"><img class="size-medium wp-image-836" src="http://www.nickrobison.com/wp-content/uploads/2014/09/Screen-Shot-2014-09-02-at-4.08.57-PM-300x241.png" alt="I love map." width="300" height="241" srcset="https://www.nickrobison.com/wp-content/uploads/2014/09/Screen-Shot-2014-09-02-at-4.08.57-PM-300x241.png 300w, https://www.nickrobison.com/wp-content/uploads/2014/09/Screen-Shot-2014-09-02-at-4.08.57-PM.png 914w" sizes="(max-width: 300px) 100vw, 300px" /></a><figcaption class="wp-caption-text">I love map.</figcaption></figure> 
  
  <p>
    11. Do me a favor, in the layer drop-down, go ahead and run the <em>Report Raster Statistics </em>command for me. Let it churn for a few minutes and tell me, does it look something like this?
  </p><figure id="attachment_837" style="width: 268px" class="wp-caption aligncenter">
  
  <a href="http://www.nickrobison.com/wp-content/uploads/2014/09/Screen-Shot-2014-09-02-at-4.13.51-PM.png"><img class="size-medium wp-image-837 " src="http://www.nickrobison.com/wp-content/uploads/2014/09/Screen-Shot-2014-09-02-at-4.13.51-PM-268x300.png" alt="The only time I see numbers that small, is when I get my grad school stipend. (rimshot)" width="268" height="300" srcset="https://www.nickrobison.com/wp-content/uploads/2014/09/Screen-Shot-2014-09-02-at-4.13.51-PM-268x300.png 268w, https://www.nickrobison.com/wp-content/uploads/2014/09/Screen-Shot-2014-09-02-at-4.13.51-PM.png 639w" sizes="(max-width: 268px) 100vw, 268px" /></a><figcaption class="wp-caption-text">The only time I see numbers that small, is when I get my grad school stipend. (rimshot)</figcaption></figure> 
  
  <p>
    Yeah, that&#8217;s what I thought, there&#8217;s no way we can export those numbers of a GeoTIFF, if we tried, it would just vomit floats all over invalid memory space (trust me on this). The problem with a density function is that as the scale increases the resulting numbers done the opposite. But no problem, we can deal with that, we just need to rescale everything back to integers and we&#8217;ll be dandy.
  </p>
  
  <p>
    12. Now, before you get all excited and start madly running that <i>Rescale</i> command you&#8217;ve heard so much about, take a deep breath and remember, <em>Rescale</em> only works on integers, you have to use <em>Recode</em> for floats. They&#8217;re pretty much the same, only not, which is just how GRASS likes it. So, fire it up by running <em>Raster ->Change Category Values and Labels -> Recode [r.recode]</em>. The inputs raster should be selected (since it&#8217;s the only one in the mapset) and we can set <em>Name for output raster map</em> to something clever, like <em>heatmap_500_recode. </em>((Yes, I am available for hire as a creative naming consultant, if you&#8217;d like I can even go <em>full valley</em> and name everything with an ly. heatmap.ly, heatmap.ly_500. Client&#8217;s choice, of course.))
  </p>
  
  <p>
    Now the tricky part (there&#8217;s always a tricky part). GRASS expects a specific formatting of values in order to know how to handle the input data, if you need more complex formatting you should take a look at the manual <a title="GRASS Recoding" href="http://grass.osgeo.org/grass65/manuals/r.recode.html">page</a>, otherwise just follow this layout:
  </p>
  
  <pre class="brush: bash; title: ; notranslate" title="">

old_low:old_high:new_low:new_high

</pre>
  
  <p>
    In looking back at the statistics that we just ran on my heatmap layer, I can see that my minimum value is 0.0 and my maximum is 0.000125. For me to fit this into an integer field I need the following line:
  </p>
  
  <pre class="brush: bash; title: ; notranslate" title="">

0.0:0.000125:0.0:125

</pre>
  
  <p>
    Once you&#8217;ve set your values correctly, go ahead and click <em>Run</em>, when it finishes, should see something that looks identical to the first raster we generated (before we changed the color table), but if we run the <em>Report Raster Statistics </em>command, we should see a nice ramp of integer values, which will play very nicely with other GIS programs.
  </p><figure id="attachment_838" style="width: 268px" class="wp-caption aligncenter">
  
  <a href="http://www.nickrobison.com/wp-content/uploads/2014/09/Screen-Shot-2014-09-02-at-4.31.59-PM.png"><img class="size-medium wp-image-838" src="http://www.nickrobison.com/wp-content/uploads/2014/09/Screen-Shot-2014-09-02-at-4.31.59-PM-268x300.png" alt="Much better." width="268" height="300" srcset="https://www.nickrobison.com/wp-content/uploads/2014/09/Screen-Shot-2014-09-02-at-4.31.59-PM-268x300.png 268w, https://www.nickrobison.com/wp-content/uploads/2014/09/Screen-Shot-2014-09-02-at-4.31.59-PM.png 639w" sizes="(max-width: 268px) 100vw, 268px" /></a><figcaption class="wp-caption-text">Much better.</figcaption></figure> 
  
  <p>
    13. Ok, but now our colors are all messed up, but we have a couple of options on how to fix that. We could just repeat our earlier process, run the <em>Set color table</em> command, and reapply the color ramp. Or, we could do something else. Take a look at our heatmap; right now it&#8217;s just a giant see of blue (or green, depending on your color ramp) which looks really ugly and really isn&#8217;t that useful, there&#8217;s a lot of data that&#8217;s being obscured. What would be nice, would be to remove everything below a certain value and only display areas of high concentration. So let&#8217;s do that.
  </p>
  
  <p>
    There are a couple of ways to go about this, but since our end goal is an image that we can integrate with other programs, what would be ideal would be to remove parts of the raster by setting their values to NULL and then make the display programs handle the appropriate ignoring. Well that&#8217;s pretty easy, in the <em>Raster </em>top menu, select <em>Develop Raster Map -> Manage NULL Values [r.null]</em>. In the resulting menu make sure <em>heatmap_500_recoded</em> is selected, click <em>Modify</em> and place your mouse cursor in the <em>[multiple] List of cell values to be set to NULL:</em> box.<em> </em>Now we have to make a decision, we have to decided how much of the image to chop out<sup id="rf9-813"><a href="#fn9-813" title="While I may say &lsquo;remove&rsquo;, &lsquo;chop&rsquo;, &lsquo;exorcise&rsquo; in reality we&rsquo;re not removing anything from the image (the size and content stays the same), all we&rsquo;re doing is modifying the raster table to indicate which points have a NULL value. After all, a rose by another other name&hellip;." rel="footnote">9</a></sup>, for me, I want as little visual clutter as possible, and to only show areas of high concentration, so I&#8217;m going to choose to set the first 20 levels to NULL, but only you can decide which values are most appropriate for your respective datasets. Enter your values and click <em>Run </em>((If your colors come out looking strange, just reapply the color table.)).
  </p><figure id="attachment_846" style="width: 300px" class="wp-caption aligncenter">
  
  <a href="http://www.nickrobison.com/wp-content/uploads/2014/09/Screen-Shot-2014-09-04-at-3.21.21-PM.png"><img class="size-medium wp-image-846" src="http://www.nickrobison.com/wp-content/uploads/2014/09/Screen-Shot-2014-09-04-at-3.21.21-PM-300x240.png" alt="Drop is like it's hot." width="300" height="240" srcset="https://www.nickrobison.com/wp-content/uploads/2014/09/Screen-Shot-2014-09-04-at-3.21.21-PM-300x240.png 300w, https://www.nickrobison.com/wp-content/uploads/2014/09/Screen-Shot-2014-09-04-at-3.21.21-PM.png 648w" sizes="(max-width: 300px) 100vw, 300px" /></a><figcaption class="wp-caption-text">Drop is like it&#8217;s hot.</figcaption></figure> 
  
  <p>
    Once it&#8217;s done, we can make things a bit clearer by deselecting our original heatmap layer (<em>heatmap_500</em>), and changing the opacity of our new recoded layer down to about 70% (<em>Change opacity level</em> in the layer drop-down). Here&#8217;s what it looks like for me:
  </p><figure id="attachment_847" style="width: 300px" class="wp-caption aligncenter">
  
  <a href="http://www.nickrobison.com/wp-content/uploads/2014/09/Screen-Shot-2014-09-04-at-3.36.18-PM.png"><img class="size-medium wp-image-847" src="http://www.nickrobison.com/wp-content/uploads/2014/09/Screen-Shot-2014-09-04-at-3.36.18-PM-300x241.png" alt="Oh that's real nice." width="300" height="241" srcset="https://www.nickrobison.com/wp-content/uploads/2014/09/Screen-Shot-2014-09-04-at-3.36.18-PM-300x241.png 300w, https://www.nickrobison.com/wp-content/uploads/2014/09/Screen-Shot-2014-09-04-at-3.36.18-PM.png 914w" sizes="(max-width: 300px) 100vw, 300px" /></a><figcaption class="wp-caption-text">Oh that&#8217;s real nice.</figcaption></figure> 
  
  <p>
    Now, we&#8217;re ready to output and visualize.
  </p>
  
  <p>
    <strong>Make flat picture</strong>
  </p>
  
  <p>
    Now that&#8217;ve got our map built and beautified, it&#8217;s time to output it as a GeoTIFF so the rest of the world can share in our joy.
  </p>
  
  <p>
    1. In the <em>File</em> top menu, select <em>Export raster map -> Common export formats [r.out.gdal]. </em>In the <em>Required</em> tab, make sure the recoded layer is selected and give it an output location.
  </p>
  
  <p>
    2. In the <em>Creation</em> tab, you can pretty much leave everything at the defaults, but if you&#8217;re planning on importing the GeoTIFF into any ESRI products, you&#8217;ll probably want to pass a few options to improve <a title="GRASS ESRI Compatibility" href="http://grass.osgeo.org/grass64/manuals/r.out.gdal.html">compatibility</a>. In the <em>[multiple] Creation option(s) to pass to the output format driver</em> field, enter:
  </p>
  
  <pre class="brush: bash; title: ; notranslate" title="">

INTERLEAVE=PIXEL, TWF=YES

</pre>
  
  <p>
    Go ahead and click <i>Run </i>and let it do its thing.
  </p><figure id="attachment_841" style="width: 300px" class="wp-caption aligncenter">
  
  <a href="http://www.nickrobison.com/wp-content/uploads/2014/09/Screen-Shot-2014-09-02-at-4.48.41-PM.png"><img class="size-medium wp-image-841" src="http://www.nickrobison.com/wp-content/uploads/2014/09/Screen-Shot-2014-09-02-at-4.48.41-PM-300x210.png" alt="When ESRI's happy, everyone's happy." width="300" height="210" srcset="https://www.nickrobison.com/wp-content/uploads/2014/09/Screen-Shot-2014-09-02-at-4.48.41-PM-300x210.png 300w, https://www.nickrobison.com/wp-content/uploads/2014/09/Screen-Shot-2014-09-02-at-4.48.41-PM-1024x717.png 1024w, https://www.nickrobison.com/wp-content/uploads/2014/09/Screen-Shot-2014-09-02-at-4.48.41-PM.png 1075w" sizes="(max-width: 300px) 100vw, 300px" /></a><figcaption class="wp-caption-text">When ESRI&#8217;s happy, everyone&#8217;s happy.</figcaption></figure> 
  
  <p>
    3. By now, you should have nice (albeit massive) tif file ready to be sucked into your favorite GIS program. So congrats, you&#8217;ve now generated a heatmap in GRASS, pat yourself on the back, because you&#8217;ve now proven yourself to be among the elite in the GIS world. But since we&#8217;re in the groove, let&#8217;s not stop there, let&#8217;s take it a step further. Let&#8217;s actually make a map.
  </p>
  
  <p>
    For now, let&#8217;s use <a title="TileMill" href="https://www.mapbox.com/tilemill/">TileMill</a>, as it&#8217;s free, cross-platform, and lets you output really pretty maps.
  </p>
  
  <p>
    Download it, install it, open it, and click <em>New Project.</em><sup id="rf10-813"><a href="#fn10-813" title="take a moment to marvel at what a GUI is supposed to look like." rel="footnote">10</a></sup> Give it a name, description, and click <em>Add</em>.
  </p><figure id="attachment_842" style="width: 300px" class="wp-caption aligncenter">
  
  <a href="http://www.nickrobison.com/wp-content/uploads/2014/09/Screen-Shot-2014-09-02-at-4.55.24-PM.png"><img class="size-medium wp-image-842" src="http://www.nickrobison.com/wp-content/uploads/2014/09/Screen-Shot-2014-09-02-at-4.55.24-PM-300x238.png" alt="Ahh, so nice and modern." width="300" height="238" srcset="https://www.nickrobison.com/wp-content/uploads/2014/09/Screen-Shot-2014-09-02-at-4.55.24-PM-300x238.png 300w, https://www.nickrobison.com/wp-content/uploads/2014/09/Screen-Shot-2014-09-02-at-4.55.24-PM-1024x813.png 1024w, https://www.nickrobison.com/wp-content/uploads/2014/09/Screen-Shot-2014-09-02-at-4.55.24-PM.png 1138w" sizes="(max-width: 300px) 100vw, 300px" /></a><figcaption class="wp-caption-text">Ahh, so nice and modern.</figcaption></figure> 
  
  <p>
    If the project doesn&#8217;t open automatically, just click on its icon.
  </p>
  
  <p>
    The new project that we&#8217;ve created is really, really basic. It just has a base map of country outlines and very little in way of style. We can fix this, but started with an <em>OSM Bright</em> project which will let us place some basemaps under our new heatmap for a nice maps-on-maps effect. That&#8217;s what I&#8217;m going to do (since I&#8217;ve already done it for another project), and you can do so as well, if you follow <a title="OSM Bright Instructions" href="https://www.mapbox.com/tilemill/docs/guides/osm-bright-mac-quickstart/">these instructions</a>.
  </p>
  
  <p>
    4. In our nice new project we need to
  </p>
  
  <p>
    +init=epsg:3395
  </p>
  
  <p>
    <strong>Tile it up</strong>
  </p>
  
  <p>
    Ok, so you&#8217;ve gotten it into <em>TileMill</em> and everything&#8217;s all nice and shinny. But what if you want to serve this up on the web? Easy, you can either add it as a layer in <a title="Mapnik" href="http://mapnik.org/">Mapnik</a>, or your tileserver of <a title="A stache for your tiles." href="http://tilestache.org/">choice</a>. But we can simulate what they would look like using the <em>gdal2tiles.py</em> command. So let&#8217;s do that.
  </p>
  
  <p>
    1. Before we can do that, we need to add a transparency layer to our GeoTIFF file. To do so, open a <a title="The Real Terminal" href="http://iterm2.com/">terminal</a> window, navigate to the folder you saved your heatmap, and issue the following command:
  </p>
  
  <pre class="brush: bash; title: ; notranslate" title="">

gdal_translate -of vrt -expand rgba [name of your outputted heatmap].tif temp.vrt

</pre>
  
  <p>
    That should create a GDAL virtual file that encodes all the required information for processing into tiles.
  </p>
  
  <p>
    2. Now we need to actually generate the tiles, you can take a look at all the possible commands by running:
  </p>
  
  <pre class="brush: bash; title: ; notranslate" title="">

gdal2tiles.py -h

</pre>
  
  <p>
    or, you can just run this command to get going:
  </p>
  
  <pre class="brush: bash; title: ; notranslate" title="">

gdal2tiles.py -z 2-10 -v temp.vrt tiles

</pre>
  
  <p>
    It&#8217;s important to note that we set the newly created <em>.vrt</em> file as the input, not the original GeoTIFF, this is because we need the explicit alpha channel that&#8217;s isn&#8217;t correctly generated in GRASS (even with the <em>ALPHA=YES</em> option). We also specified tiling at zoom levels 2-10, and set the output to the <em>tiles </em>directory. Let it run for a bit (more coffee, perhaps?) and when it&#8217;s done, in the tiles folder you should have 2 html files, one using <em>Google Maps</em> as the base-layer and the other with <em>OpenLayers</em>. Open one up and make sure everything looks the way you&#8217;d expect.
  </p>
  
  <p>
    <strong>Make the machines do it</strong>
  </p>
  
  <p>
    Well dear friends, we have reached the end. You&#8217;ve walk through the fire and come through unscathed. Of course, this seems like a lot of work to go through, especially if you have to do this more than once. I agree, so I whipped up a quick script to help you out. You can grab it from my Github <a title="GrassMaps Script" href="https://github.com/nickrobison/GrassMaps">repo</a>. It&#8217;s pretty basic right now, but I&#8217;m hoping to add to it and make it more useful, but we&#8217;ll see.
  </p>
  
  <p>
    Drop a note in the comments if you have any problems and I&#8217;ll see if I can help out.
  </p>
  
  <p>
    Happy mapping!
  </p>
  
  <hr class="footnotes" />
  
  <ol class="footnotes">
    <li id="fn1-813">
      <p>
        shout out to the OSGeo guys for their work on porting some popular packages. Keep up the good work!&nbsp;<a href="#rf1-813" class="backlink" title="Jump back to footnote 1 in the text.">&#8617;</a>
      </p>
    </li>
    
    <li id="fn2-813">
      <p>
        I&#8217;m pretty sure the version of QGIS shipped with Ubuntu is the same one Moses used to teach the Israelites, but I can&#8217;t be sure.&nbsp;<a href="#rf2-813" class="backlink" title="Jump back to footnote 2 in the text.">&#8617;</a>
      </p>
    </li>
    
    <li id="fn3-813">
      <p>
        Not to mention ones that actually build&nbsp;<a href="#rf3-813" class="backlink" title="Jump back to footnote 3 in the text.">&#8617;</a>
      </p>
    </li>
    
    <li id="fn4-813">
      <p>
        Observant readers will notice that I left out the QGIS install, that&#8217;s not because QGIS and I are on the outs, but just that I&#8217;ve had mixed success actually getting it to compile. If you&#8217;re feeling adventurous by all means give it a go, but since it&#8217;s not absolutely necessary for this tutorial, I&#8217;ve left it out. &nbsp;<a href="#rf4-813" class="backlink" title="Jump back to footnote 4 in the text.">&#8617;</a>
      </p>
    </li>
    
    <li id="fn5-813">
      <p>
        GRASS really doesn&#8217;t like commas, so I make sure to use pipes, but maybe you&#8217;re a nicer person than me, and can get away with it.&nbsp;<a href="#rf5-813" class="backlink" title="Jump back to footnote 5 in the text.">&#8617;</a>
      </p>
    </li>
    
    <li id="fn6-813">
      <p>
        At this point, you may be curious as to the weird codes at the end of the command names. Those represent that actual commands that the gui is running. V is for vector functions, R for raster, this comes in really handy if you&#8217;re automating things, or if you&#8217;re not sure which function to run on your data.&nbsp;<a href="#rf6-813" class="backlink" title="Jump back to footnote 6 in the text.">&#8617;</a>
      </p>
    </li>
    
    <li id="fn7-813">
      <p>
        Or, you could just go get an intern to do all of this for you.&nbsp;<a href="#rf7-813" class="backlink" title="Jump back to footnote 7 in the text.">&#8617;</a>
      </p>
    </li>
    
    <li id="fn8-813">
      <p>
        On my 2012 Macbook Air it takes about 11 minutes to build the heatmap.&nbsp;<a href="#rf8-813" class="backlink" title="Jump back to footnote 8 in the text.">&#8617;</a>
      </p>
    </li>
    
    <li id="fn9-813">
      <p>
        While I may say &#8216;remove&#8217;, &#8216;chop&#8217;, &#8216;exorcise&#8217; in reality we&#8217;re not removing anything from the image (the size and content stays the same), all we&#8217;re doing is modifying the raster table to indicate which points have a NULL value. After all, a rose by another other name&#8230;.&nbsp;<a href="#rf9-813" class="backlink" title="Jump back to footnote 9 in the text.">&#8617;</a>
      </p>
    </li>
    
    <li id="fn10-813">
      <p>
        take a moment to marvel at what a GUI is supposed to look like.&nbsp;<a href="#rf10-813" class="backlink" title="Jump back to footnote 10 in the text.">&#8617;</a>
      </p>
    </li>
  </ol>
  
  <!-- kcite active, but no citations found -->
</div>

<!-- kcite-section 813 -->