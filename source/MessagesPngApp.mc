using Toybox.Application as App;
using Toybox.System as Sys;
using Toybox.Timer as Timer;

class MessagesPng extends App.AppBase {
    // we poll phone app to know if we have new notification (only when app is running obviously)
    // since it is not reliable for phone to send message to watch in CIQ
    hidden const POLL_PERIOD = 3 * 1000; //ms
    hidden var dataTimer;
    hidden var view;

    function initialize() {
        App.AppBase.initialize();
        view = new MessagesPngView();
    }

    function onStart(state) {
        dataTimer = new Timer.Timer();
        dataTimer.start( method(:timerCallback), POLL_PERIOD, true);
        view.requestSession();
    }

    function onStop(state) {
        dataTimer = null;
    }

    function getInitialView() {
        return [view, new MessagesPngInputDelegate(view)];
    }

    function timerCallback() {
        view.requestNotificationCount();
    }
}
