using Toybox.WatchUi as Ui;
using Toybox.Graphics as Gfx;
using Toybox.Communications as Comm;
using Toybox.System as Sys;

class UnquestionifyView extends Ui.View {
    hidden var screenShape;
    hidden var screenWidth;
    hidden var screenHeight;
    hidden var bitmap; // the notification bitmap fetched from phone
    hidden var bufferedBitmap; //not used: BufferedBitmap
    hidden var currentNotifications = []; //as array of string
    hidden var currentNotificationIndex = 0;

    hidden const ip = "127.0.0.1";

    hidden const appId = "c569ccc1-be51-4860-bbcd-2b45a138d64b";
    hidden var initialised = false;
    hidden var errmsg;
    hidden var session = "";
    hidden var lastTS = 0; //last received message time stamp (from phone)

    hidden var isDetailView = false;
    hidden var detailPage = 0;
    hidden var detailPageCount = 0;

    function initialize() {
        View.initialize();
        bufferedBitmap = new Gfx.BufferedBitmap(
            {
                :width=>260,
                :height=>260,
            });

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

    // not used
    function base64ToByteArray(base64String) {
        // converting base64 to byte array
        return StringUtil.convertEncodedString(base64String, {
            :fromRepresentation => StringUtil.REPRESENTATION_STRING_BASE64,
            :toRepresentation => StringUtil.REPRESENTATION_BYTE_ARRAY,
        });
    }

    // not used. data as ByteArray. This will trigger watchdog so won't use
    function drawBinaryNotification(dc, data) {
        var screenWidth = dc.getWidth();
        var screenHeight = dc.getHeight();

        // set black background
        dc.setColor(Gfx.COLOR_TRANSPARENT, Gfx.COLOR_BLACK);
        dc.clear();

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
                // will show only when app first starts
                Sys.println("Loading...");
                drawNativeNotification(dc, "Loading...");
            } else {
                // bitmap is null, no error, and initialised. That means images are loading or no notifications
                var msg;
                if (currentNotifications.size() == 0) {
                    msg = "No Messages";
                    drawNativeNotification(dc, msg);
                } else {
                    msg = "Loading\n" + currentNotifications.size() + " messages";
                    drawNativeNotification(dc, msg);
                }
                Sys.println(msg);
            }
            return;
        }

        // show bitmap at center of screen
        var x = (dc.getWidth() - bitmap.getWidth()) / 2;
        var y = (dc.getHeight() - bitmap.getHeight()) / 2;
        dc.drawBitmap(x, y, bitmap);
        Sys.println("Drawing bitmap [" + bitmap.getWidth() + "x" + bitmap.getHeight() + "] at (" + x + "," + y + ")");

        // draw top bottom line
        dc.setColor(Gfx.COLOR_DK_GRAY, Gfx.COLOR_TRANSPARENT);
        dc.drawLine(0, 25, screenWidth, 25);
        dc.drawLine(0, dc.getHeight() - 25, screenWidth, dc.getHeight() - 25);

        // detail view: show next/prev triangle
        if (isDetailView) {
            dc.setColor(0xd13f00, Gfx.COLOR_TRANSPARENT);
            if (detailPage < detailPageCount - 1) {
                // show next triangle
                // lower point, upperleft, upperright
                dc.fillPolygon([[dc.getWidth()/2, dc.getHeight() - 10],
                                [dc.getWidth()/2 - 7, dc.getHeight() - 18],
                                [dc.getWidth()/2 + 7, dc.getHeight() - 18]]);
            }
            if (detailPage > 0) {
                // show prev triangle
                // upper point, lowerleft, lowerright
                dc.fillPolygon([[dc.getWidth()/2, 10],
                                [dc.getWidth()/2 - 7, 18],
                                [dc.getWidth()/2 + 7, 18]]);
            }
            // show left arrow
            // left point, upperright, lowerright
            dc.fillPolygon([[10, dc.getHeight()/2],
                            [18, dc.getHeight()/2 - 7],
                            [18, dc.getHeight()/2 + 7]]);
            Sys.println("Detail Page " + (detailPage + 1) + "/" + detailPageCount);
        // overview: show current/total count
        } else {
            dc.setColor(0xd17d00, Gfx.COLOR_TRANSPARENT);
            // show app name on top
            dc.drawText(dc.getWidth()/2, 8, Gfx.FONT_XTINY, Ui.loadResource(Rez.Strings.AppName), Gfx.TEXT_JUSTIFY_CENTER);
            // show current/total notification count in overview page
            dc.drawText(dc.getWidth()/2, dc.getHeight() - 20, Gfx.FONT_XTINY, 
                (currentNotificationIndex + 1) + "/"+ currentNotifications.size(), Gfx.TEXT_JUSTIFY_CENTER);
            // if there are more than 1 page of text for this message, show right arrow
            if (detailPageCount > 0) {
                dc.setColor(0xd13f00, Gfx.COLOR_TRANSPARENT);
                // right point, upperleft, lowerleft
                dc.fillPolygon([[dc.getWidth()-10, dc.getHeight()/2],
                                [dc.getWidth()-18, dc.getHeight()/2 - 7],
                                [dc.getWidth()-18, dc.getHeight()/2 + 7]]);
            }
        }
        dc.setColor(Gfx.COLOR_YELLOW, Gfx.COLOR_TRANSPARENT);
        dc.drawText(dc.getWidth()/2, 25, Gfx.FONT_XTINY, getCurrentNotificationWhen(), Gfx.TEXT_JUSTIFY_CENTER);
    }

    function showDetail() {
        if (!isDetailView) {
            Sys.println("Show detail view...");
            if (detailPageCount > 0) {
                isDetailView = true;
                // reset detail page to first page, and request first page
	            detailPage = 0;
	            requestNotificationImageAtPage(getCurrentNotificationId(),
                    detailPage, method(:onReceiveImage));
                return true; // mean we are entering detail view
            }
        }
        return false; // means we are not entering detail view
    }

    function showOverview() {
        if (isDetailView) {
            isDetailView = false;
            var id = getCurrentNotificationId();
            if (!id.equals("")) {
                // show last overview notification if possible
                requestNotificationImage(id);
            } else {
                // if not, let's request current status now
                requestNotificationCount();
            }
            return true;
        }
        return false;
    }

    // show the next notification
    function next() {
        if (isDetailView) {
            if (detailPage + 1 == detailPageCount) {
                Sys.println("No next detail page: "+ (detailPage + 1) + "/" + detailPageCount);
                return;
            }
            requestNotificationImageAtPage(getCurrentNotificationId(),
                detailPage + 1, method(:onReceiveNextDetailImage));
        } else {
            if (currentNotifications.size() <= 1) {
                return;
            }
            currentNotificationIndex = (currentNotificationIndex + 1) % currentNotifications.size();
            detailPageCount = getCurrentNotificationPageCount();
            requestNotificationImage(getCurrentNotificationId());
        }
    }

    // show the previous notification
    function prev() {
        if (isDetailView) {
            if (detailPage == 0) {
                Sys.println("No prev detail page: "+ (detailPage + 1) + "/" + detailPageCount);
                return;
            } 
            requestNotificationImageAtPage(getCurrentNotificationId(),
                detailPage - 1, method(:onReceivePrevDetailImage));
        } else {
            if (currentNotifications.size() <= 1) {
                return;
            }
            currentNotificationIndex = (currentNotificationIndex + currentNotifications.size() - 1) % currentNotifications.size();
            detailPageCount = getCurrentNotificationPageCount();
            requestNotificationImage(getCurrentNotificationId());
        }
    }

    // dimiss current notification on phone
    function dismiss() {
        if (currentNotifications.size() <= 0) {
            return;
        }
        requestNotificationDismissal(getCurrentNotificationId());
    }

    function dismissAll() {
        if (currentNotifications.size() <= 0) {
            return;
        }
        requestAllNotificationDismissal();
    }

    // UI update
    function onUpdate(dc) {
        drawBitmapNotification(dc);
    }


    function setError(errText, json) {
        bitmap = null;
        errmsg = errText;
        if (json != null) {
            Sys.println("Server response:" + json["error"]);
        }
    }

    function requestSession() {
        errmsg = null;
        Comm.makeWebRequest(
            "http://" + ip + ":8080/request_session",
            {
                "appid" => appId,
                "width" => screenWidth,
                "height" => screenHeight,
                "shape" => screenShape,
            },
            {
                :method => Comm.HTTP_REQUEST_METHOD_GET, 
                :responseType => Comm.HTTP_RESPONSE_CONTENT_TYPE_JSON
            },
            method(:onReceivedSession)
        );
    }

    function onReceivedSession(responseCode, json) {
        if( responseCode == 200 ) {
            session = json["session"];
            Sys.println("=== session starts ===");
            if (!initialised) {
                requestNotificationCount();
            }
            Ui.requestUpdate();
        } else {
            setError("Phone App\nUnreachable", json);
            Ui.requestUpdate();
            Sys.println("request session failed. Response code:" + responseCode);
        }
    }

    // requesting notification info from companion app
    function requestNotificationCount() {
        if (isDetailView) {
            return;
        }
        if (session.equals("")) {
            requestSession();
            return;
        }
        errmsg = null;
        Comm.makeWebRequest(
            "http://" + ip + ":8080/notifications",
            {
                "session" => session,
            },
            {
                :method => Comm.HTTP_REQUEST_METHOD_GET, 
                :responseType => Comm.HTTP_RESPONSE_CONTENT_TYPE_JSON
            },
            method(:onReceivedNotificationCount)
        );
    }

    function onReceivedNotificationCount(responseCode, json) {
        if( responseCode == 200 ) {
            var oldCount = currentNotifications.size();
            var oldCurrentId = "";
            var changed = false;
            if (oldCount > 0 && currentNotificationIndex < oldCount) {
                oldCurrentId = getCurrentNotificationId();
            }

            var ts = json["timestamp"];
            if (ts != lastTS) {
                changed = true;
                // reset to newest notification (first one)
                currentNotificationIndex = 0;
                lastTS = ts;
            }
            // replace with the latest array of id
            currentNotifications = json["notification"];

            // request notification image (will update display)
            if (changed) {
                if (currentNotifications.size() > 0) {
                    Sys.println("[NEW MESSAGE] Total " + currentNotifications.size() + " notifications");
                    detailPageCount = getCurrentNotificationPageCount();
                    requestNotificationImage(getCurrentNotificationId());
                } else {
                    // changed to no notification
                    Sys.println("[ALL CLEARED]");
                    bitmap = null;
                    detailPageCount = 0; //reset to default value
                    Ui.requestUpdate();
                }
            }
            // this will only enter when we first communicated successfully with phone app
            if (!initialised) {
                initialised = true;
                Ui.requestUpdate();
            }
        } else {
            setError("Error [" + responseCode + "]", json);
            Ui.requestUpdate();
            Sys.println("request notification failed. Response code:" + responseCode);
        }
    }

    // requesting to dismiss a notification
    function requestNotificationDismissal(id) {
        errmsg = null;
        Comm.makeWebRequest(
            "http://" + ip + ":8080/notifications/" + id,
            {
                "session" => session,
            },
            {
                :method => Comm.HTTP_REQUEST_METHOD_DELETE, 
                :responseType => Comm.HTTP_RESPONSE_CONTENT_TYPE_JSON
            },
            method(:onReceivedDismissal)
        );
    }

    // requesting to dismiss all notification
    function requestAllNotificationDismissal() {
        errmsg = null;
        Comm.makeWebRequest(
            "http://" + ip + ":8080/notifications",
            {
                "session" => session,
            },
            {
                :method => Comm.HTTP_REQUEST_METHOD_DELETE, 
                :responseType => Comm.HTTP_RESPONSE_CONTENT_TYPE_JSON
            },
            method(:onReceivedDismissalAll)
        );
    }

    // callabck for dismissing a notification
    function onReceivedDismissal(responseCode, json) {
        if (responseCode == 200) {
            Sys.println("notification dismissed");

            // show No notification
            // == 1 because we didn't update our local copy yet
            if (currentNotifications.size() <= 1) {
                errmsg = null;
                bitmap = null;
                currentNotifications = [];
                currentNotificationIndex = 0;
                Ui.requestUpdate();
            }
            // now exit detail view to overview
            showOverview();
        } else {
            setError("Dismiss Error [" + responseCode + "]", json);
        }
    }

    // callabck for dismissing all notification
    function onReceivedDismissalAll(responseCode, json) {
        if (responseCode == 200) {
            isDetailView = false;
            errmsg = null;
            bitmap = null;
            currentNotifications = [];
            currentNotificationIndex = 0;
            Ui.requestUpdate();
        } else {
            setError("Dismiss Error [" + responseCode + "]", json);
        }
    }

    // requesting a overview notification
    function requestNotificationImage(id) {
        requestNotificationImageAtPage(id, -1, method(:onReceiveImage));
    }

    // requesting notification as iamge. page -1 means overview
    function requestNotificationImageAtPage(id, page, callback) {
        errmsg = null;
        bitmap = null;
        var params = {
            "session" => session,
            "page" => page
        };
        Comm.makeImageRequest(
            "http://" + ip + ":8080/notifications/" + id,
            params,
            {
                :palette=>[
                    0xFF000000, //black
                    0xFFFFFFFF //AARRGGBB - white
                ],
                :maxWidth=>screenWidth,
                :maxHeight=>screenHeight
            },
            callback
        );
        
    }

    // callback receiving a bitmap and saving to 'bitmap'
    function onReceiveImage(responseCode, data) {
        // real device (vivoactive 4s) will return responseCode == 0 even if server side returns 204
        // with json content. In simulator it is 404. WTF.
        if( responseCode == 200 ) {
            bitmap = data;
            Ui.requestUpdate();
        } else if (responseCode == 404) {
            Sys.println("request image returns 404...");
            // maybe notification is dismissed by user between poll period
            //requestNotificationCount();
        } else if (responseCode == 204) {
            //no content, meaning that no such page (detail view)
            Sys.println("request image failed with no content.");
        } else {
            //bitmap = null;
            //errmsg = "Img Error [" + responseCode + "]";
            Sys.println("request image failed. Response code:" + responseCode);
            //Ui.requestUpdate();
         }
    }

    function onReceivePrevDetailImage(responseCode, data) {
        if (responseCode == 200) {
            detailPage -= 1;
            Sys.println("previous page " + detailPage + " shown");
        } else {
            showOverview();
        }
        onReceiveImage(responseCode, data);
    }

    function onReceiveNextDetailImage(responseCode, data) {
        if (responseCode == 200) {
            detailPage += 1;
            Sys.println("next page " + detailPage + " shown");
        } else {
            showOverview();
        }
        onReceiveImage(responseCode, data);
    }

    function getCurrentNotificationId() {
        if (currentNotifications.size() > 0 && currentNotificationIndex < currentNotifications.size()) {
            return currentNotifications[currentNotificationIndex]["id"];
        }
        return "";
    }

    function getCurrentNotificationWhen() {
        if (currentNotifications.size() > 0 && currentNotificationIndex < currentNotifications.size()) {
            return currentNotifications[currentNotificationIndex]["when"];
        }
        return "";
    }

    function getCurrentNotificationPageCount() {
        if (currentNotifications.size() > 0 && currentNotificationIndex < currentNotifications.size()) {
            return currentNotifications[currentNotificationIndex]["pages"];
        }
        return 1;
    }
}
