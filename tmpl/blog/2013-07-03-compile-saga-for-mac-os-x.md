**Update:**

The good folks over at [OsGeo][1] have worked their magic and turned all the installation steps into magic. So, to get a nice shiny SAGA install, all one needs to do is this:


brew install saga-gis --with-app --with python


I'll leave the rest of the post up for posterity (or if you really like doing things the hard way), but it should've be necessary.

**For people who like doing things the hard way:**

Over the past couple of weeks I've been doing a bunch of work with different geospatial packages, including <a title="SAGA GIS" href="http://www.saga-gis.org/" target="_blank">SAGA</a> which is tremendously powerful, albeit incredibly difficult to compile from source. Which isn't really a big deal as most Linux repos have fairly up-to-date versions, but as my primary machine is Macbook Air, I'd like to be able to run natively and as of right now, there are no prebuilt packages.

There's a pretty good set of compile instructions already available on <a title="SAGA Compile Instructions" href="http://sourceforge.net/apps/trac/saga-gis/wiki/Compiling%20SAGA%20on%20Mac%20OS%20X" target="_blank">Sourceforge</a>, but they're based around installing prebuilt OS packages and/or compiling stuff on your own, which can be tricky and is hard to keep updated. By now you're thinking, why not just use <a title="Homebrew" href="http://mxcl.github.io/homebrew/" target="_blank">Homebrew</a>? What a great idea, if you're not already a Homebrewer, you should be. It'll make all the ladies love you, and all your kids will be 6 feet tall and look like David Hasselhoff. Unfortunately, the version that ships with Homebrew is good ol' 1.6, which is only slightly more modern then the version Moses used to teach the Israelites. So, to the source we go, and with a few modifications we may just have some success.

Note: These instructions assume that you have a working version of Homebrew, as well as the various packages  (automake, libtool, subversion, etc) and know-how necessary to compile generic software.

**

** 

**1. Install XQuartz**

The first packge you'll need is <a title="XQuartz" href="http://xquartz.macosforge.org/landing/" target="_blank">XQuartz</a>, which you'll need to download and install yourself just like a normal OS X package. No magic here.

**2. Install Basic SAGA Dependencies**

The first few deps can be installed in one fell swoop:


**3. Build GDAL**

The default GDAL recipe installs an up-to-date and fairly complete version of GDAL, but it's missing KML support, which is a big deal for what I do, but  unfortunately GDAL requires libkml 1.3 and Homebrew only uses 1.2, so we need to build from SVN.


As of now, you'll need to touchup some of the configure files before compiling:

* <span style="line-height: 15px;">Edit <em>configure.ac</em> and remove the reference to '-Werror'</span>
* Also in _configure.ac_, replace 'AM\_CONFIG\_HEADER' with 'AC\_CONFIG\_HEADER'

Now, build it:


CXXFLAGS=&quot;-O3 -pipe -march=core2 -msse4.2 -msse4.1 -mno-avx&quot; ./configure --prefix=/usr/local/Cellar/libkml/1.3

make

make install

brew link libkml


NOTE: Depending on how old your Mac is, you may have to remove the SSE optimizations from CXXFLAGS, the reason we're not using '-march=native' is that it <a title="GCC Error" href="https://github.com/mxcl/homebrew/issues/14204" target="_blank">throws an error in GCC 4.2</a>, and no, libkml does not compile correctly using clang. I tried.

**3. Install wxWidgets**

****If you've perused the previously mentioned compile notes, you're probably wondering why we didn't just install wxWidgets along with everything else. The reason is, the provided recipe doesn't have the correct compile flags and misses some of the x86_64 features. Which throws errors during the SAGA comple. The simple fix is to edit the recipe:


And paste the following lines into the 'args' vector right before &#8220;-disable-debug&#8221;:


&quot;--enable-monolithic&quot;,

&quot;--enable-macosx_arch=x86_64&quot;,

&quot;--with-macosx-sdk=/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.Platform/Developer/SDKs/MacOSX#{MacOS.version}.sdk&quot;,


Boom, now just


and you're off.

If you want to put the recipe back the way it belongs, just check it back out from git:


get checkout wxmac.rb


**

** 

**3. Build SAGA**

Now you're finally ready to build SAGA itself. First, you'll need to grab it from subversion


By default, the Makefiles reference some libraries that either don't exist, or are named differently on OS X, so you'll need to touchup the Makefiles.

* Edit **src/saga\_core/saga\_odbc/Makefile.am** and change &#8220;-lodbc&#8221; to &#8220;-liodbc&#8221; (without the quotes).
* Edit **src/saga\_core/saga\_gui/Makefile.am** and delete &#8220;aui,base,&#8221; and &#8220;propgrid,&#8221; from the first AM_LDFLAGS line.

Now, build the config files.


With all the various config flags and options, it's easiest to build a script to put it all together.



and add the following lines:


CXX=&quot;/usr/bin/clang&quot;

CXXFLAGS=&quot;-O3 -march=native&quot;

DEFINES=&quot;-D_FILE_OFFSET_BITS=64 -DWXUSINGDLL -D__WXMAC__ -D__WXOSX__ -D__WXOSX_COCOA__&quot;

GDAL_H=&quot;-I/usr/local/include&quot;

PROJ_H=&quot;-I/usr/local/include&quot;

GDAL_SRCH=&quot;-L/usr/local/lib&quot;

PROJ_SRCH=&quot;-L/usr/local/lib&quot;

LINK_MISC=&quot;-arch x86_64 -mmacosx-version-min=10.7 -isysroot /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX10.7.sdk -lstdc++&quot;

./configure $FEATURES CXXFLAGS=&quot;$CXXFLAGS&quot; CXX=&quot;$CXX&quot; CPPFLAGS=&quot;$DEFINES $GDAL_H $PROJ_H&quot; LDFLAGS=&quot;$GDAL_SRCH $PROJ_SRCH $LINK_MISC&quot;


This will link to the appropriate libraries, use the correct SDK, and install the files in the correct location, super fancy right? The last step before building is to add a missing header from the _proj _library, while it's not included in the homebrew build, we can extract it from the downloaded tarball:


mv /proj-4.8.0/src/projects.h {SAGA_DIR}/src/modules_projection/pj_proj4/pj_proj4/projects.h

rm -rf proj-4.8.0/


Now, make like the wind:


./my-saga-conf.sh

make

make install

brew link saga


Once that finishes you should have a working install, but since this is a fancy Apple computer, you're probably wanting a nice Application bundle. Lucky for you, there's a script for that.


wget http://web.fastermac.net/~MacPgmr/SAGA/saga_gui.icns

chmod +x create_saga_app.sh

./create_saga_app.sh /usr/local/bin/saga_gui SAGA

ln -s {SAGA_DIR}/SAGA.app /Applications/SAGA.app


And that ladies and gentlemen, is how we do that. You now have a slick, up to date , and working copy of SAGA on your lovely OS X installation. There's one minor caveat, if you're like me and had grand visions of using <a title="RSAGA" href="http://cran.r-project.org/web/packages/RSAGA/index.html" target="_blank">RSAGA</a> to run spatial statistics, you'll find that it only supports SAGA versions up to 2.0.8; which don't compile on the latest version of Xcode as they no longer support the Carbon SDK. If you really need R integration, you're stuck with a Linux or Windows (gasp) VM.

FINAL NOTE: These directions worked for me and should work across platforms, and yes, there are probably better and more efficient ways to do this, but my motto is 'when in doubt, add another compile flag'.

Go forth and be spatial!

[1]: www.osgeo.org "THE GIS people"