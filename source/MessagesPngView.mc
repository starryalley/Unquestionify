using Toybox.WatchUi as Ui;
using Toybox.Graphics as Gfx;
using Toybox.Communications as Comm;
using Toybox.System as Sys;

class MessagesPngView extends Ui.View {
    var screenShape;
   	var screenWidth;
   	var screenHeight;
   	var bitmap; // the notification bitmap fetched from phone
    var bufferedBitmap; //not used: BufferedBitmap
	var currentNotifications = []; //as array of string
	var currentNotificationIndex = 0;
	//const ip = "10.42.100.49"; //for office test
	//const ip = "192.168.1.104"; //for home test
	const ip = "127.0.0.1";
	var initialised = false;
	var errmsg;
	
    function initialize() {
        View.initialize();
        bufferedBitmap = new Gfx.BufferedBitmap(
			{
				:width=>260,
				:height=>260,
			});
		//drawBinaryNotification(bufferedBitmap.getDc());
		
		// determine screen shape and dimesion
		var shape = Sys.getDeviceSettings().screenShape;
		if (shape == Sys.SCREEN_SHAPE_ROUND) {
			screenShape = "round";
		} else if (shape == Sys.SCREEN_SHAPE_SEMI_ROUND) {
			screenShape = "semiround";
		} else {
			screenShape = "rect";
		}
		screenWidth = Sys.getDeviceSettings().screenWidth;
		screenHeight = Sys.getDeviceSettings().screenHeight;
    }

    function onLayout(dc) {
        // nothing
    }
    
    // not used: updates width/height/data
    function _decodeJson(json) {
    	// decode 
    	var width = json["width"];
    	var height = json["height"];
    	// converting base64 to byte array
    	data = StringUtil.convertEncodedString(json["data"], {
    		:fromRepresentation => StringUtil.REPRESENTATION_STRING_BASE64,
    		:toRepresentation => StringUtil.REPRESENTATION_BYTE_ARRAY,
    	});
    	Sys.println("Binary image (" + width + "," + height + ") BASE64 size:" + json["data"].length()
    		+ ", decoded = " + data.size());
    }
    
    // not used: reads width/height/data
    function drawBinaryNotification(dc, data) {
    	var screenWidth = dc.getWidth();
    	var screenHeight = dc.getHeight();
    
    	// set black background
    	dc.setColor(Gfx.COLOR_TRANSPARENT, Gfx.COLOR_BLACK);
        dc.clear();
        
    	// data
    	if (data == null) {
    		// no data, draw a horizontal line for no reason
    		dc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_TRANSPARENT);
    		dc.drawText(screenWidth/2, screenHeight/2, Gfx.FONT_MEDIUM, "No DATA", Gfx.TEXT_JUSTIFY_CENTER);
    		Sys.println("drawBinaryNotification(): No data available");
    		return;
    	}
    	
    	var offsetx = screenWidth/2 - width/2;
    	var offsety = screenHeight/2 - height/2;
    	var k = 0;
    	// foreground: white
    	//var byte = data[0];
    	dc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_TRANSPARENT);
    	for (var y = 0; y < height; y++) {
    		for (var x = 0; x < width; x++, k++) {
    			//if (k > 0 && k%8 == 0) {
    				//update current byte
    				//byte = data[k/8];
    			//}
    			// check if the bit is set
    			if (data[k/8] & (1 << (k%8))) {
    				// draw this point)
    				dc.drawPoint(offsetx + x, offsety + y);
    			}
    		}
    	}
    	
    }
    
    function drawNativeNotification(dc, text) {
    	// show current/totoal notification count
	    dc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_TRANSPARENT);
		dc.drawText(dc.getWidth()/2, dc.getHeight()/2, Gfx.FONT_SMALL,  text, Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER);
    }
    
    function drawBitmapNotification(dc) {
    	// set black background
    	dc.setColor(Gfx.COLOR_TRANSPARENT, Gfx.COLOR_BLACK);
        dc.clear();
    	// bitmap should contain the actual bitmap. If not, this means the following 3 things...
    	if (bitmap == null) {
    		// no data, draw a horizontal line for no reason
    		if (errmsg != null) {
    			// error case
    			Sys.println("Error:" + errmsg);
    			drawNativeNotification(dc, errmsg);
    		} else if (!initialised) {
    			// only when app first starts
    			Sys.println("Loading...");
    			drawNativeNotification(dc, "Loading...");
    		} else {
    			// no error and initialised => no notification
				Sys.println("No notification");
				drawNativeNotification(dc, "No Notification");
    		}
    		return;
    	}
    	
    	// show bitmap at center of screen
		var x = (dc.getWidth() - bitmap.getWidth()) / 2;
		var y = (dc.getHeight() - bitmap.getHeight()) / 2;
	    dc.drawBitmap(x, y, bitmap);
	    Sys.println("Drawing bitmap at " + x.toString() + "," + y.toString());
	    // show current/totoal notification count
	    dc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_TRANSPARENT);
		dc.drawText(dc.getWidth()/2, dc.getHeight() - 20, Gfx.FONT_XTINY, (currentNotificationIndex + 1) + "/"+ currentNotifications.size() , Gfx.TEXT_JUSTIFY_CENTER);
	}

	// show the next notification
	function next() {
		if (currentNotifications.size() <= 1) {
			return;
		}
		currentNotificationIndex = (currentNotificationIndex + 1) % currentNotifications.size();
		requestNotificationImage(currentNotifications[currentNotificationIndex]);
	}
	
	// show the previous notification
	function prev() {
		if (currentNotifications.size() <= 1) {
			return;
		}
		currentNotificationIndex = (currentNotificationIndex + currentNotifications.size() - 1) % currentNotifications.size();
		requestNotificationImage(currentNotifications[currentNotificationIndex]);
	}
	
	// dimiss current notification on phone
	function dismiss() {
		if (currentNotifications.size() <= 0) {
			return;
		}
		requestNotificationDismissal(currentNotifications[currentNotificationIndex]);
	}

	// UI update
    function onUpdate(dc) {
        //dc.drawBitmap(0, 0, bufferedBitmap);
		drawBitmapNotification(dc);
    }
    
    // requesting notification info from companion app
    function requestNotificationCount() {
        Comm.makeWebRequest(
            "http://" + ip + ":8080/get_info",
			{
			},
			{
                :method => Comm.HTTP_REQUEST_METHOD_GET, 
                :headers => {"Content-Type" => Comm.REQUEST_CONTENT_TYPE_URL_ENCODED},
                :responseType => Comm.HTTP_RESPONSE_CONTENT_TYPE_JSON
            },
            method(:onReceivedNotificationCount)
        );
    }
    
    // callback for notification count
    function onReceivedNotificationCount(responseCode, json) {
    	if( responseCode == 200 ) {
    		errmsg = null;
    		var oldCount = currentNotifications.size();
    		var oldCurrentId = "";
    		var changed = false;
    		if (oldCount > 0 && currentNotificationIndex < oldCount) {
    			oldCurrentId = currentNotifications[currentNotificationIndex];
    		}
    		
    		// replace with the latest array of id
	    	currentNotifications = json["notification"];
	    	// flag to know if we have communicated successfully with phone app
	    	initialised = true;
	   		// when notification count changes, we reset index to point to the first notification
	    	if (currentNotifications.size() != oldCount) {
	    		changed = true;
	    		Sys.println("Reset current notification index to 0");
	    		currentNotificationIndex = 0;
	    	} else if (currentNotifications.size() > 0 && !oldCurrentId.equals(currentNotifications[currentNotificationIndex])){
	    		// when count remains the same, let's check if current notification changed
	    		changed = true;
	    	}
	    	Sys.println("Total " + currentNotifications.size() + " notifications");
	    	// request notification image (will update display)
	    	if (currentNotifications.size() > 0) {
	    		if (changed) {
	    			Sys.println("Requesting new notification update...");
	    			requestNotificationImage(currentNotifications[currentNotificationIndex]);
	    		}
	    	} else {
	    		// no notification
	    		bitmap = null;
	    		Ui.requestUpdate();
	    	}
	    }
	    else {
	    	bitmap = null;
	    	errmsg = "Error code:" + responseCode;
	    	Ui.requestUpdate();
	    	Sys.println("request notification failed. Response code:" + responseCode);
	    	
	    }
    }
    
    // requesting to dismiss a notification
    function requestNotificationDismissal(id) {
    	Comm.makeWebRequest(
            "http://" + ip + ":8080/dismiss",
			{
				"id" => id,
			},
			{
                :method => Comm.HTTP_REQUEST_METHOD_GET, 
                :headers => {"Content-Type" => Comm.REQUEST_CONTENT_TYPE_URL_ENCODED},
                :responseType => Comm.HTTP_RESPONSE_CONTENT_TYPE_JSON
            },
            method(:onReceivedDismissal)
        );
    }
    
    // callabck for dismissing a notification
    function onReceivedDismissal(responseCode, json) {
    	if (responseCode == 200) {
    		Sys.println("notification dismissed");
    		// now update current count
    		requestNotificationCount();
    	} else {
    		Sys.println("failed to dismiss notification:" + json["error"]);
    	}
    }
        
    // requesting a notification as an image
 	function requestNotificationImage(id) {
 		bitmap = null;
 		var params = {
			"width" => screenWidth,
			"height" => screenHeight,
			"shape" => screenShape
		};
		// add parameter id if it isn't null
 		if (id != null) {
 			params["id"] = id;
 		} 
        Comm.makeImageRequest(
            "http://" + ip + ":8080/notification",
			params,
			{
                :palette=>[
			    	0xFF000000,
			    	//0xFFAAAAAA,
				   	0xFFFFFFFF
			    ],
                :maxWidth=>screenWidth,
                :maxHeight=>screenHeight
            },
            method(:onReceiveImage)
        );
        
    }

    // callback receiving a bitmap and saving to 'bitmap'
    function onReceiveImage(responseCode, data) {
        if( responseCode == 200 ) {
        	bitmap = data;
        	Ui.requestUpdate();
        }
        else {
        	bitmap = null;
        	Sys.println("request image failed. Response code:" + responseCode);
         }
    }
}