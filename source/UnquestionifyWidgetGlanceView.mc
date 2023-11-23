using Toybox.WatchUi as Ui;
using Toybox.Graphics as Gfx;
using Toybox.Communications as Comm;
using Toybox.System as Sys;
using Toybox.Timer as Timer;

(:glance)
class UnquestionifyWidgetGlanceView extends Ui.GlanceView {
    hidden var timer;
    hidden var mainview;
    hidden var started = false;
    hidden var requested = false;
    hidden var width;
    hidden var height;
    hidden var textHeight;

    function initialize(view) {
        GlanceView.initialize();
        mainview = view;
        timer = new Timer.Timer();
    }

    function onShow() {
        Sys.println("Glance view onShow()");
        timer.start( method(:onTimer), 2*1000, true);
    }

    function onHide() {
        timer.stop();
    }

    function onTimer() {
        started = true;
        // when session is acquired and we haven't requested summary image
        if (mainview.initialised && !requested) {
            mainview.requestNotificationSummaryImage();
            mainview.setGlanceDimension(width, height - textHeight, textHeight - 2);
            requested = true;
        }
        Ui.requestUpdate();
    }

    function onUpdate(dc) {
        width = dc.getWidth();
        height = dc.getHeight();
        if (textHeight == null) {
            var dim = dc.getTextDimensions("Dummy", Gfx.FONT_SYSTEM_XTINY);
            textHeight = dim[1];
        }

        Sys.println("Glance onUpdate(): width:" + dc.getWidth() + " height:" + dc.getHeight());
        dc.setColor(0xffecb8, Gfx.COLOR_TRANSPARENT);
        var text = "Loading...";
        if (!started) {
            dc.drawText(dc.getWidth()/2, dc.getHeight()/2, Gfx.FONT_XTINY, text, Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER);
        } else if (mainview.initialised) {
            if (mainview.currentNotifications.size() == 0) {
               text = "Unquestionify\nNo message";
               dc.drawText(dc.getWidth()/2, dc.getHeight()/2, Gfx.FONT_XTINY, text, Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER);
            } else {
               text = mainview.currentNotifications.size() + " messages";
               //Sys.println("Text Height:" + textHeight);
               if (mainview.summaryBitmap != null) {
                   dc.drawText(0, 0, Gfx.FONT_SYSTEM_XTINY, text, Gfx.TEXT_JUSTIFY_LEFT);
                   dc.drawBitmap(0, textHeight, mainview.summaryBitmap);
               } else {
                   // bitmap isn't available
                   text = "Unquestionify\n" + text;
                   dc.drawText(dc.getWidth()/2, dc.getHeight()/2, Gfx.FONT_SYSTEM_XTINY, text, Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER);
               }
            }
        } else {
            text = "PhoneApp Unreachable";
            dc.drawText(dc.getWidth()/2, dc.getHeight()/2, Gfx.FONT_XTINY, text, Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER);
        }
    }
}
