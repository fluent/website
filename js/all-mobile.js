// mobile browsers detect
browserPlatform = {
	platforms: [
		{ uaString:['symbian','midp'], cssFile:'symbian.css' }, // Symbian phones
		{ uaString:['opera','mobi'], cssFile:'opera.css' }, // Opera Mobile
		{ uaString:['msie','ppc'], cssFile:'ieppc.css' }, // IE Mobile <6
		{ uaString:'iemobile', cssFile:'iemobile.css' }, // IE Mobile 6+
		{ uaString:'webos', cssFile:'webos.css' }, // Palm WebOS
		{ uaString:'Android', cssFile:'android.css' }, // Android
		{ uaString:['BlackBerry','/6.0','mobi'], cssFile:'blackberry6.css' },	// Blackberry 6
		{ uaString:['BlackBerry','/7.0','mobi'], cssFile:'blackberry7.css' },	// Blackberry 7+
		{ uaString:'ipad', cssFile:'ipad.css', miscHead:'<meta name="viewport" content="width=device-width" />' }, // iPad
		{ uaString:['safari','mobi'], cssFile:'safari.css', miscHead:'<meta name="viewport" content="width=device-width" />' } // iPhone and other webkit browsers
	],
	options: {
		cssPath:'css/',
		mobileCSS:'allmobile.css'
	},
	init:function(){
		this.checkMobile();
		this.parsePlatforms();
		return this;
	},
	checkMobile: function() {
		if(this.uaMatch('mobi') || this.uaMatch('midp') || this.uaMatch('ppc') || this.uaMatch('webos')) {
			this.attachStyles({cssFile:this.options.mobileCSS});
		}
	},
	parsePlatforms: function() {
		for(var i = 0; i < this.platforms.length; i++) {
			if(typeof this.platforms[i].uaString === 'string') {
				if(this.uaMatch(this.platforms[i].uaString)) {
					this.attachStyles(this.platforms[i]);
					break;
				}
			} else {
				for(var j = 0, allMatch = true; j < this.platforms[i].uaString.length; j++) {
					if(!this.uaMatch(this.platforms[i].uaString[j])) {
						allMatch = false;
					}
				}
				if(allMatch) {
					this.attachStyles(this.platforms[i]);
					break;
				}
			}
		}
	},
	attachStyles: function(platform) {
		var head = document.getElementsByTagName('head')[0], fragment;
		var cssText = '<link rel="stylesheet" href="' + this.options.cssPath + platform.cssFile + '" type="text/css"/>';
		var miscText = platform.miscHead;
		if(platform.cssFile) {
			if(document.body) {
				fragment = document.createElement('div');
				fragment.innerHTML = cssText;
				head.appendChild(fragment.childNodes[0]);
			} else {
				document.write(cssText);
			}
		}
		if(platform.miscHead) {
			if(document.body) {
				fragment = document.createElement('div');
				fragment.innerHTML = miscText;
				head.appendChild(fragment.childNodes[0]);
			} else {
				document.write(miscText);
			}
		}
	},
	uaMatch:function(str) {
		if(!this.ua) {
			this.ua = navigator.userAgent.toLowerCase();
		}
		return this.ua.indexOf(str.toLowerCase()) != -1;
	}
}.init();