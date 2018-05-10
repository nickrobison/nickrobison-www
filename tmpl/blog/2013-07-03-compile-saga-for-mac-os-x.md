<div class="kcite-section" kcite-section-id="621">
  <p>
    <strong>Update:</strong>
  </p>
  
  <p>
    The good folks over at <a title="THE GIS people" href="www.osgeo.org">OsGeo</a> have worked their magic and turned all the installation steps into magic. So, to get a nice shiny SAGA install, all one needs to do is this:
  </p>
  
  <pre class="brush: bash; title: ; notranslate" title="">

brew tap osgeo/osgeo4mac

brew install saga-gis --with-app --with python

</pre>
  
  <p>
    I&#8217;ll leave the rest of the post up for posterity (or if you really like doing things the hard way), but it should&#8217;ve be necessary.
  </p>
  
  <p>
    <strong>For people who like doing things the hard way:</strong>
  </p>
  
  <p>
    Over the past couple of weeks I&#8217;ve been doing a bunch of work with different geospatial packages, including <a title="SAGA GIS" href="http://www.saga-gis.org/" target="_blank">SAGA</a> which is tremendously powerful, albeit incredibly difficult to compile from source. Which isn&#8217;t really a big deal as most Linux repos have fairly up-to-date versions, but as my primary machine is Macbook Air, I&#8217;d like to be able to run natively and as of right now, there are no prebuilt packages.
  </p>
  
  <p>
    There&#8217;s a pretty good set of compile instructions already available on <a title="SAGA Compile Instructions" href="http://sourceforge.net/apps/trac/saga-gis/wiki/Compiling%20SAGA%20on%20Mac%20OS%20X" target="_blank">Sourceforge</a>, but they&#8217;re based around installing prebuilt OS packages and/or compiling stuff on your own, which can be tricky and is hard to keep updated. By now you&#8217;re thinking, why not just use <a title="Homebrew" href="http://mxcl.github.io/homebrew/" target="_blank">Homebrew</a>? What a great idea, if you&#8217;re not already a Homebrewer, you should be. It&#8217;ll make all the ladies love you, and all your kids will be 6 feet tall and look like David Hasselhoff. Unfortunately, the version that ships with Homebrew is good ol&#8217; 1.6, which is only slightly more modern then the version Moses used to teach the Israelites. So, to the source we go, and with a few modifications we may just have some success.
  </p>
  
  <p>
    Note: These instructions assume that you have a working version of Homebrew, as well as the various packages  (automake, libtool, subversion, etc) and know-how necessary to compile generic software.
  </p>
  
  <p>
    <strong><br /> </strong>
  </p>
  
  <p>
    <strong>1. Install XQuartz</strong>
  </p>
  
  <p>
    The first packge you&#8217;ll need is <a title="XQuartz" href="http://xquartz.macosforge.org/landing/" target="_blank">XQuartz</a>, which you&#8217;ll need to download and install yourself just like a normal OS X package. No magic here.
  </p>
  
  <p>
    <strong>2. Install Basic SAGA Dependencies</strong>
  </p>
  
  <p>
    The first few deps can be installed in one fell swoop:
  </p>
  
  <pre class="brush: bash; title: ; notranslate" title=""> brew install boost jasper libharu </pre>
  
  <p>
    <strong>3. Build GDAL</strong>
  </p>
  
  <p>
    The default GDAL recipe installs an up-to-date and fairly complete version of GDAL, but it&#8217;s missing KML support, which is a big deal for what I do, but  unfortunately GDAL requires libkml 1.3 and Homebrew only uses 1.2, so we need to build from SVN.
  </p>
  
  <pre class="brush: bash; title: ; notranslate" title=""> svn checkout http://libkml.googlecode.com/svn/trunk/ libkml-read-only </pre>
  
  <p>
    As of now, you&#8217;ll need to touchup some of the configure files before compiling:
  </p>
  
  <ul>
    <li>
      <span style="line-height: 15px;">Edit <em>configure.ac</em> and remove the reference to &#8216;-Werror&#8217;</span>
    </li>
    <li>
      Also in <em>configure.ac</em>, replace &#8216;AM_CONFIG_HEADER&#8217; with &#8216;AC_CONFIG_HEADER&#8217;
    </li>
  </ul>
  
  <p>
    Now, build it:
  </p>
  
  <pre class="brush: bash; title: ; notranslate" title="">

./autogen.sh

CXXFLAGS=&quot;-O3 -pipe -march=core2 -msse4.2 -msse4.1 -mno-avx&quot; ./configure --prefix=/usr/local/Cellar/libkml/1.3

make

make install

brew link libkml

</pre>
  
  <p>
    NOTE: Depending on how old your Mac is, you may have to remove the SSE optimizations from CXXFLAGS, the reason we&#8217;re not using &#8216;-march=native&#8217; is that it <a title="GCC Error" href="https://github.com/mxcl/homebrew/issues/14204" target="_blank">throws an error in GCC 4.2</a>, and no, libkml does not compile correctly using clang. I tried.
  </p>
  
  <p>
    <strong>3. Install wxWidgets</strong>
  </p>
  
  <p>
    <strong></strong>If you&#8217;ve perused the previously mentioned compile notes, you&#8217;re probably wondering why we didn&#8217;t just install wxWidgets along with everything else. The reason is, the provided recipe doesn&#8217;t have the correct compile flags and misses some of the x86_64 features. Which throws errors during the SAGA comple. The simple fix is to edit the recipe:
  </p>
  
  <pre class="brush: bash; title: ; notranslate" title=""> brew edit wxwidgets </pre>
  
  <p>
    And paste the following lines into the &#8216;args&#8217; vector right before &#8220;&#8211;disable-debug&#8221;:
  </p>
  
  <pre class="brush: bash; title: ; notranslate" title="">

&quot;--enable-shared&quot;,

&quot;--enable-monolithic&quot;,

&quot;--enable-macosx_arch=x86_64&quot;,

&quot;--with-macosx-sdk=/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.Platform/Developer/SDKs/MacOSX#{MacOS.version}.sdk&quot;,

</pre>
  
  <p>
    Boom, now just
  </p>
  
  <pre class="brush: bash; title: ; notranslate" title=""> brew install wxwidgets </pre>
  
  <p>
    and you&#8217;re off.
  </p>
  
  <p>
    If you want to put the recipe back the way it belongs, just check it back out from git:
  </p>
  
  <pre class="brush: bash; title: ; notranslate" title="">

cd /usr/local/Library/Formulas

get checkout wxmac.rb

</pre>
  
  <p>
    <b><br /> </b>
  </p>
  
  <p>
    <strong>3. Build SAGA</strong>
  </p>
  
  <p>
    Now you&#8217;re finally ready to build SAGA itself. First, you&#8217;ll need to grab it from subversion
  </p>
  
  <pre class="brush: bash; title: ; notranslate" title=""> svn co svn.code.sf.net/p/saga-gis/code-0/trunk/saga-gis saga-gis </pre>
  
  <p>
    By default, the Makefiles reference some libraries that either don&#8217;t exist, or are named differently on OS X, so you&#8217;ll need to touchup the Makefiles.
  </p>
  
  <ul>
    <li>
      Edit <b>src/saga_core/saga_odbc/Makefile.am</b> and change &#8220;-lodbc&#8221; to &#8220;-liodbc&#8221; (without the quotes).
    </li>
    <li>
      Edit <b>src/saga_core/saga_gui/Makefile.am</b> and delete &#8220;aui,base,&#8221; and &#8220;propgrid,&#8221; from the first AM_LDFLAGS line.
    </li>
  </ul>
  
  <p>
    Now, build the config files.
  </p>
  
  <pre class="brush: bash; title: ; notranslate" title=""> autoreconf -i </pre>
  
  <p>
    With all the various config flags and options, it&#8217;s easiest to build a script to put it all together.
  </p>
  
  <pre class="brush: bash; title: ; notranslate" title="">

vim my-saga-config.sh

</pre>
  
  <p>
    and add the following lines:
  </p>
  
  <pre class="brush: bash; title: ; notranslate" title="">

FEATURES=&quot;--enable-debug --disable-openmp --prefix=/usr/local/Cellar/saga-core/2.1.0 --exec-prefix=/usr/local/Cellar/saga-core/2.1.0&quot;

CXX=&quot;/usr/bin/clang&quot;

CXXFLAGS=&quot;-O3 -march=native&quot;

DEFINES=&quot;-D_FILE_OFFSET_BITS=64 -DWXUSINGDLL -D__WXMAC__ -D__WXOSX__ -D__WXOSX_COCOA__&quot;

GDAL_H=&quot;-I/usr/local/include&quot;

PROJ_H=&quot;-I/usr/local/include&quot;

GDAL_SRCH=&quot;-L/usr/local/lib&quot;

PROJ_SRCH=&quot;-L/usr/local/lib&quot;

LINK_MISC=&quot;-arch x86_64 -mmacosx-version-min=10.7 -isysroot /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX10.7.sdk -lstdc++&quot;

./configure $FEATURES CXXFLAGS=&quot;$CXXFLAGS&quot; CXX=&quot;$CXX&quot; CPPFLAGS=&quot;$DEFINES $GDAL_H $PROJ_H&quot; LDFLAGS=&quot;$GDAL_SRCH $PROJ_SRCH $LINK_MISC&quot;

</pre>
  
  <p>
    This will link to the appropriate libraries, use the correct SDK, and install the files in the correct location, super fancy right? The last step before building is to add a missing header from the <em>proj </em>library, while it&#8217;s not included in the homebrew build, we can extract it from the downloaded tarball:
  </p>
  
  <pre class="brush: bash; title: ; notranslate" title="">

tar -zxvf /Library/Caches/Homebrew/proj-4.8.0.tar.gz ./proj-4.8.0/src/projects.h

mv /proj-4.8.0/src/projects.h {SAGA_DIR}/src/modules_projection/pj_proj4/pj_proj4/projects.h

rm -rf proj-4.8.0/

</pre>
  
  <p>
    Now, make like the wind:
  </p>
  
  <pre class="brush: bash; title: ; notranslate" title="">

chmod +x my-saga-conf.sh

./my-saga-conf.sh

make

make install

brew link saga

</pre>
  
  <p>
    Once that finishes you should have a working install, but since this is a fancy Apple computer, you&#8217;re probably wanting a nice Application bundle. Lucky for you, there&#8217;s a script for that.
  </p>
  
  <pre class="brush: bash; title: ; notranslate" title="">

wget http://web.fastermac.net/~MacPgmr/SAGA/create_saga_app.sh

wget http://web.fastermac.net/~MacPgmr/SAGA/saga_gui.icns

chmod +x create_saga_app.sh

./create_saga_app.sh /usr/local/bin/saga_gui SAGA

ln -s {SAGA_DIR}/SAGA.app /Applications/SAGA.app

</pre>
  
  <p>
    And that ladies and gentlemen, is how we do that. You now have a slick, up to date , and working copy of SAGA on your lovely OS X installation. There&#8217;s one minor caveat, if you&#8217;re like me and had grand visions of using <a title="RSAGA" href="http://cran.r-project.org/web/packages/RSAGA/index.html" target="_blank">RSAGA</a> to run spatial statistics, you&#8217;ll find that it only supports SAGA versions up to 2.0.8; which don&#8217;t compile on the latest version of Xcode as they no longer support the Carbon SDK. If you really need R integration, you&#8217;re stuck with a Linux or Windows (gasp) VM.
  </p>
  
  <p>
    FINAL NOTE: These directions worked for me and should work across platforms, and yes, there are probably better and more efficient ways to do this, but my motto is &#8216;when in doubt, add another compile flag&#8217;.
  </p>
  
  <p>
    Go forth and be spatial!
  </p>
  
  <!-- kcite active, but no citations found -->
</div>

<!-- kcite-section 621 -->