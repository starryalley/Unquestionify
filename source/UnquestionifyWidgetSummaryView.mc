using Toybox.WatchUi as Ui;
using Toybox.Graphics as Gfx;
using Toybox.Communications as Comm;
using Toybox.System as Sys;
using Toybox.Timer as Timer;

class UnquestionifyWidgetSummaryView extends Ui.View {
    hidden var mainview;
    hidden var timer;
    hidden var started = false;

    function initialize(view) {
        View.initialize();
        mainview = view;
        timer = new Timer.Timer();
    }

    function onShow() {
        // update UI every 3 seconds so we can refresh current notification count
        Sys.println("Widget Summary onShow()");
        Ui.requestUpdate();
        timer.start(method(:onTimer), 1000*3, true);
    }

    function onHide() {
        timer.stop();
    }

    function onTimer() {
        started = true;
        Ui.requestUpdate();
    }

    function onUpdate(dc) {
        dc.setColor(Gfx.COLOR_TRANSPARENT, Gfx.COLOR_BLACK);
        dc.clear();
        dc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_TRANSPARENT);
        var text = "";
        if (!started) {
            text = "Loading...";
        } else if (mainview.initialised) {
            if (mainview.currentNotifications.size() == 0) {
                text = "Unquestionify\nNo message";
            } else {
                text = "Unquestionify\n" + mainview.currentNotifications.size() + " messages";
            }
        } else {
           text = "PhoneApp Unreachable";
        }
        dc.drawText(dc.getWidth()/2, dc.getHeight()/2, Gfx.FONT_SMALL, text,
            Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER);
    }
}

class UnquestionifySummaryInputDelegate extends Ui.BehaviorDelegate {
    var mainview;

    function initialize(view) {
        Ui.BehaviorDelegate.initialize();
        mainview = view;
    }

    function onSelect() {
        Ui.pushView(mainview, new UnquestionifyInputDelegate(mainview), Ui.SLIDE_LEFT);
        return true;
    }
}