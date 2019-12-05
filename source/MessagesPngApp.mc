using Toybox.Application as App;
using Toybox.Communications as Comm;
using Toybox.WatchUi as Ui;
using Toybox.System as Sys;
using Toybox.Sensor as Sensor;
using Toybox.Timer as Timer;

class MessagesPng extends App.AppBase {
	const POLL_PERIOD = 5 * 1000; //ms
	var dataTimer;
	var view;
	var mailMethod;
	var phoneMethod;
    function initialize() {
        App.AppBase.initialize();
		view = new MessagesPngView();
		
        mailMethod = method(:onMail);
        phoneMethod = method(:onPhone);
        if(Comm has :registerForPhoneAppMessages) {
            Comm.registerForPhoneAppMessages(phoneMethod);
        } else {
            Comm.setMailboxListener(mailMethod);
        }
    }

    function onStart(state) {
    	// poll the notification service on phone every POLL_PERIOD
        dataTimer = new Timer.Timer();
        dataTimer.start( method(:timerCallback), POLL_PERIOD, true);
        view.requestNotificationCount();
    }

    function onStop(state) {
        dataTimer = null;
        mailMethod = null;
        phoneMethod = null;
    }

    function getInitialView() {
        return [view, new MessagesPngInputDelegate(view)];
    }

    function onMail(mailIter) {
        var mail = mailIter.next();

        while(mail != null) {
           	data = mail.toString();
            mail = mailIter.next();
        }

        Comm.emptyMailbox();
        Ui.requestUpdate();
    }

    function onPhone(msg) {
    	var data = msg.data;
    	if (data != null) {
        	Ui.requestUpdate();
        }
    }

    function timerCallback() {
        view.requestNotificationCount();
    }

}