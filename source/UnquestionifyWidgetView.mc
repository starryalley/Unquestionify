using Toybox.WatchUi as Ui;
using Toybox.Graphics as Gfx;
using Toybox.Communications as Comm;
using Toybox.System as Sys;
using Toybox.Timer as Timer;

// main app view
(:glance)
class UnquestionifyView extends Ui.View {
    var initialised = false;
    var shown = false;
    var currentNotifications = []; //as array of string
    var summaryBitmap; // not being used now

    // we poll phone app to know if we have new notification (only when app is running obviously)
    // since it is not reliable for phone to send message to watch in CIQ
    hidden const POLL_PERIOD = 3 * 1000; //ms
    hidden var timer;
    hidden var screenShape;
    hidden var screenWidth;
    hidden var screenHeight;
    hidden var bitmap; // the notification bitmap fetched from phone
    hidden var currentNotificationIndex = 0;

    hidden const ip = "127.0.0.1";
    hidden const imageServer = "https://fill_in_the_relay_server_domain_here";

    hidden const appId = "c2842d1b-ad5c-47c6-b28f-cc495abd7d32";
    hidden var errmsg;
    hidden var session = "";
    hidden var relaySession = "";
    hidden var lastTS = 0; //last received message time stamp (from phone)

    hidden var isDetailView = false;
    hidden var detailPage = 0;
    hidden var detailPageCount = 0;

    hidden var fontHeight = 10;
    hidden var linePos = 40;

    function initialize() {
        View.initialize();
        timer = new Timer.Timer();

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
        fontHeight = dc.getFontHeight(Gfx.FONT_XTINY);
        linePos = screenWidth/2 - Math.sqrt((screenWidth/2)*(screenWidth/2)/2) - screenHeight/30;
    }

    function onShow() {
        Sys.println("Mainview onShow()");
        shown = true;
        // when we are in overview page and we have notification, let's show the message
        if (!isDetailView && currentNotifications.size() > 0) {
            requestNotificationImage(getCurrentNotificationId());
        }
        timer.start(method(:onTimer), POLL_PERIOD, true);
    }

    function onHide() {
        shown = false;
        timer.stop();
    }

    function onTimer() {
        requestNotificationCount();
    }

    // not used
    function base64ToByteArray(base64String) {
        // converting base64 to byte array
        return StringUtil.convertEncodedString(base64String, {
            :fromRepresentation => StringUtil.REPRESENTATION_STRING_BASE64,
            :toRepresentation => StringUtil.REPRESENTATION_BYTE_ARRAY,
        });
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

        // draw top/bottom line
        dc.setColor(Gfx.COLOR_DK_GRAY, Gfx.COLOR_TRANSPARENT);
        dc.drawLine(0, linePos, screenWidth, linePos);
        dc.drawLine(0, dc.getHeight() - linePos, screenWidth, dc.getHeight() - linePos);

        // detail view: show next/prev triangle
        if (isDetailView) {
            // show message time (only on page 1 and last page)
            if (detailPage == 0) {
                dc.setColor(0xbdffc9, Gfx.COLOR_TRANSPARENT);
                dc.drawText(dc.getWidth()/2, linePos - fontHeight, Gfx.FONT_XTINY, getCurrentNotificationWhen(), Gfx.TEXT_JUSTIFY_CENTER);
            } else if (detailPage == detailPageCount - 1) {
                dc.setColor(0xbdffc9, Gfx.COLOR_TRANSPARENT);
                dc.drawText(dc.getWidth()/2, dc.getHeight() - linePos, Gfx.FONT_XTINY, getCurrentNotificationWhen(), Gfx.TEXT_JUSTIFY_CENTER);
            }
            dc.setColor(0xffcb2e, Gfx.COLOR_TRANSPARENT);
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
            // show message time
            dc.setColor(0xbdffc9, Gfx.COLOR_TRANSPARENT);
            dc.drawText(dc.getWidth()/2, dc.getHeight() - linePos - fontHeight, Gfx.FONT_XTINY, getCurrentNotificationWhen(), Gfx.TEXT_JUSTIFY_CENTER);
            // show app name on top
            dc.setColor(0xffecb8, Gfx.COLOR_TRANSPARENT);
            dc.drawText(dc.getWidth()/2, linePos - fontHeight, Gfx.FONT_XTINY, Ui.loadResource(Rez.Strings.AppName), Gfx.TEXT_JUSTIFY_CENTER);
            // show current/total notification count in overview page
            dc.drawText(dc.getWidth()/2, dc.getHeight() - linePos, Gfx.FONT_XTINY,
                (currentNotificationIndex + 1) + "/"+ currentNotifications.size(), Gfx.TEXT_JUSTIFY_CENTER);
            // if there are more than 1 page of text for this message, show right arrow
            if (detailPageCount > 0) {
                dc.setColor(0xffcb2e, Gfx.COLOR_TRANSPARENT);
                // right point, upperleft, lowerleft
                dc.fillPolygon([[dc.getWidth()-10, dc.getHeight()/2],
                                [dc.getWidth()-18, dc.getHeight()/2 - 7],
                                [dc.getWidth()-18, dc.getHeight()/2 + 7]]);
            }
        }
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
        if (currentNotifications.size() > 0) {
            requestNotificationDismissal(getCurrentNotificationId());
        }
    }

    function dismissAll() {
        if (currentNotifications.size() > 0) {
            requestAllNotificationDismissal();
        }
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
        System.println("Request session:" + screenWidth + "x" + screenHeight + ". IP:" + ip);
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

    function setGlanceDimension(width, height, textHeight) {
        System.println("Set Glance Dimension:" + width + "x" + height + ", text height:" + textHeight);
        errmsg = null;
        Comm.makeWebRequest(
            "http://" + ip + ":8080/set_glance_dimension",
            {
                "session" => session,
                "width" => width,
                "height" => height,
                "textHeight" => textHeight,
            },
            {
                :method => Comm.HTTP_REQUEST_METHOD_GET,
                :responseType => Comm.HTTP_RESPONSE_CONTENT_TYPE_JSON
            },
            method(:onReceiveGlanceDone)
        );
    }

    function onReceiveGlanceDone(responseCode, json) {
        if( responseCode == 200) {
            Sys.println("Glance dimension set!");
        } else {
            Sys.println("Unable to set glance dimension:" + responseCode);
        }
    }

    function onReceivedSession(responseCode, json) {
        if( responseCode == 200 && json.hasKey("session") && json.hasKey("relay_session")) {
            session = json["session"];
            relaySession = json["relay_session"];
            Sys.println("=== session starts ===");
            requestNotificationCount();
            Ui.requestUpdate();
        } else {
            setError("Phone App\nUnreachable", json);
            Ui.requestUpdate();
            if (responseCode == 200) {
                setError("Unexpected Data\nReceived", json);
                Sys.println("request session returned malformed data");
            } else {
                setError("Phone App\nUnreachable", json);
                Sys.println("request session failed. Response code:" + responseCode);
            }
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
        Sys.println("Requesting notification count");
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

            initialised = true;

            // request notification image (will update display)
            if (changed) {
                if (currentNotifications != null && currentNotifications.size() > 0) {
                    Sys.println("[NEW MESSAGE] Total " + currentNotifications.size() + " notifications");
                    detailPageCount = getCurrentNotificationPageCount();
                    if (shown) {
                        // this can only happen in overview page (isDetailView==false)
                        /*
                        if (isDetailView) {
                            // detail view
                            requestNotificationImageAtPage(getCurrentNotificationId(),
                                detailPage, method(:onReceiveImage));
                        } else {*/
                            // overview
                            requestNotificationImage(getCurrentNotificationId());
                        //}
                    }
                } else {
                    // changed to no notification
                    Sys.println("[ALL CLEARED]");
                    bitmap = null;
                    detailPageCount = 0; //reset to default value
                    if (shown) {
                        Ui.requestUpdate();
                    }
                }
            }
            // this will only enter when we first communicated successfully with phone app
            if (shown) {
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
        bitmap = null;
        Sys.println("Request overview image");
        requestNotificationImageAtPage(id, -1, method(:onReceiveImage));
    }

    // requesting notification as image. page -1 means overview
    function requestNotificationImageAtPage(id, page, callback) {
        errmsg = null;
        var params = {
            "session" => relaySession
        };
        //Sys.println("makeImageRequest => " + imageServer + "/notifications/" + id + "/" + page + "?session=" + relaySession);
        Comm.makeImageRequest(
            imageServer + "/notifications/" + id + "/" + page,
            params,
            {
                :palette=>[
                    0xFF000000, //black
                    0xFFFFFFFF //AARRGGBB - white
                ],
                // the below 2 lines will make the image the size of maxWidth * maxHeight, different from pre-GCM 4.40
                // :maxWidth=>screenWidth,
                // :maxHeight=>screenHeight
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
            Sys.println("request image failed. Response code:" + responseCode);
        }
    }

    // requesting notification summary with width/height (for glance view)
    function requestNotificationSummaryImage() {
        errmsg = null;
        var params = {
            "session" => relaySession
        };
        //Sys.println("makeImageRequest => " + imageServer + "/notifications/summary/0");
        Comm.makeImageRequest(
            imageServer + "/notifications/summary/0",
            params,
            {
                :palette=>[
                    0xFF000000, //black
                    0xFFFFFFFF //AARRGGBB - white
                ]
            },
            method(:onReceiveSummaryImage)
        );
    }

    function onReceiveSummaryImage(responseCode, data) {
        if (responseCode == 200) {
            Sys.println("Summary Image received successfully");
            summaryBitmap = data;
        } else {
            Sys.println("Summary Image request failed:" + responseCode + ", data:" + data);
            summaryBitmap = null;
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
