//  https://github.com/kayluhb/jquery-html-history
//
// Plugin that provides a "htmlhistory" event on the window object, notifying an application when the URL changes
// This is accomplished by watching the hash, using the hashchange event from HTML5 or a polling interval in older browsers.
// In addition, in some modern browsers, HTML5 History Management is used to support changing the URL's path without reloading the page.
// This plugin also provides a method to navigate to a URL safely, that will use HTML5 History Management to avoid a page load.
// Everything degrades gracefully, and supports RESTful client development.

// Browser Support:
//  Chrome  - Any recent version of Chrome supports everything.
//  Safari  - Any recent version of Safari supports everything.
//  Firefox - Newer versions of Firefox support the hashchange event
//            Firefox 4 betas also support HTML5 History Management
//  Internet Explorer - IE8 supports hashchange
//                      IE6 and 7 receive inferior hashchange support through a polling interval.
//  Others  - Other modern browsers probably support some subset of features.

// This plugin was originally authored by Ben Cherry (bcherry@gmail.com), and is released under an MIT License (do what you want with it).
// Modifications made by Caleb Brown (twitter.com/kayluhb)
// Some of the code in this plugin was adapted from Modernizr, which is also available under an MIT License.
(function($) {
    // can use $(window).bind("htmlhistory", fn) or $(window).htmlhistory(fn)
    var evt = 'htmlhistory', hashevt = 'hashchange', hash = 'onhashchange';
    
    $.fn.htmlhistory = function(handler) {
        return handler ? this.bind(evt, handler) : this.on(evt);
    };
    var his = $.htmlhistory = {
        // default options
        options: {
            useHistory: true, // whether we use HTML5 History Management to change the current path
            useHashchange: true, // whether we use HTML5 Hashchange to listen to the URL hash
            poll: 250, // when using Hashchange in browsers without it, how often to poll the hash (in ms)
            interceptLinks: true, // do we intercept all relative links to avoid some page reloads?
            disableHashLinks: true // do we ensure all links with href=# are not followed (this would mess with our history)?
        },
        // call this once when your app is ready to use htmlhistory
        init: function(options) {
            var lastHash, $win = $(window), $bod = $('body');
            $.extend(his.options, options);
            // Listen to the HTML5 "popstate" event, if supported and desired
            if (his.options.useHistory && his.supportsHistory()) {
                $win.bind("popstate", function(e) {
                    $win.on(evt);
                });
            }
            // Listen to the HTML5 "hashevent" event, if supported and desired
            if (his.options.useHashchange) {
                $win.bind(hashevt, function(e) {
                    $win.on(evt);
                });
                // Hashchange support for older browsers (IE6/7)
                if (!his.supportsHashchange()) {
                    lastHash = window.location.hash;
                    requestInterval(function() {
                        if (lastHash !== window.location.hash) {
                            $win.on(hashevt);
                            lastHash = window.location.hash;
                        }
                    }, his.options.poll);
                }
            }
            // Intercept all relative links on the page, to avoid unneccesary page refreshes
            if (his.options.interceptLinks) {
                $bod.delegate('a[href=^"/"]', 'click', function(e) {
                    his.changeTo($(this).attr('href'));
                    e.preventDefault();
                });
            }
            // Ensure all the href=# links on the page don't mess with things
            if (his.options.disableHashLinks) {
                $bod.delegate('a[href=#]', 'click', function(e) {
                    e.preventDefault();
                });
            }
        },
        // Call to manually navigate the app somewhere
        changeTo: function(path) {
            var $win = $(window);
            // If we're using History Management, just push an entry
            if (his.options.useHistory && his.supportsHistory()) {
                window.history.pushState(null, null, path);
                $win.on(evt);
            } else {
                // Make sure there's a hash (going from foo.com#bar to foo.com would trigger a reload in Firefox, sadly)
                if (path.indexOf("#") < 0) {
                    path = "#" + path;
                }
                // Otherwise, navigate to the new URL.  Might reload the browser.  Might trigger a hashchange.
                window.location.href = path;
            }
        },
        // Simple feature detection for History Management (borrowed from Modernizr)
        supportsHistory: function() {
            return !!(window.history && history.pushState);
        },
        // Simple feature detection for hashchange (adapted from Modernizr)
        supportsHashchange: function() {
            var isSupported = hash in window;
            if (!isSupported && window.setAttribute) {
                window.setAttribute(hash, "return;");
                isSupported = typeof window.onhashchange === "function";
            }
            return isSupported;
        }
    };
}(jQuery));
// requestAnimationFrame() shim by Paul Irish
// http://paulirish.com/2011/requestanimationframe-for-smart-animating/
window.requestAnimFrame = (function() {
    return  window.requestAnimationFrame   || 
            window.webkitRequestAnimationFrame || 
            window.mozRequestAnimationFrame    || 
            window.oRequestAnimationFrame      || 
            window.msRequestAnimationFrame     || 
            function(/* function */ callback, /* DOMElement */ element){
          window.setTimeout(callback, 1000 / 60);
            };
})();
/**
 * Behaves the same as setInterval except uses requestAnimationFrame() where possible for better performance
 * @param {function} fn The callback function
 * @param {int} delay The delay in milliseconds
 */
window.requestInterval = function(fn, delay) {
    if( !window.requestAnimationFrame     && 
        !window.webkitRequestAnimationFrame && 
        !window.mozRequestAnimationFrame    && 
        !window.oRequestAnimationFrame      && 
        !window.msRequestAnimationFrame)
            return window.setInterval(fn, delay);
    var start = new Date().getTime(),
        handle = new Object();
    function loop() {
        var current = new Date().getTime(),
            delta = current - start;
        if(delta >= delay) {
            fn.call();
            start = new Date().getTime();
        }
        handle.value = requestAnimFrame(loop);
    };
    handle.value = requestAnimFrame(loop);
    return handle;
}
