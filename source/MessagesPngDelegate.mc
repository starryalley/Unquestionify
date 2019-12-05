using Toybox.WatchUi as Ui;
using Toybox.System as Sys;
using Toybox.Communications as Comm;

class CommListener extends Comm.ConnectionListener {
    function initialize() {
        Comm.ConnectionListener.initialize();
    }

    function onComplete() {
        Sys.println("CommListener.onComplete(): Transmit Complete");
    }

    function onError() {
        Sys.println("CommListener.onError(): Transmit Failed");
    }
}

class MessagesPngInputDelegate extends Ui.BehaviorDelegate {
	var view;
    function initialize(v) {
        Ui.BehaviorDelegate.initialize();
        view = v;
    }

    function onMenu() {
        var menu = new Ui.Menu();
        var delegate;

        menu.addItem("Dismiss", :dismiss);
        delegate = new BaseMenuDelegate(view);
        Ui.pushView(menu, delegate, SLIDE_IMMEDIATE);
		Sys.println("onMenu()");
        return true;
    }

    function onTap(event) {
		Sys.println("onTap:" + event);
        Ui.requestUpdate();
    }
    
    function onNextPage() {
    	Sys.println("onNextPage()");
    	view.next();
    }
    
    function onPreviousPage() {
    	Sys.println("onPreviousPage()");
    	view.prev();
    }
}

class BaseMenuDelegate extends Ui.MenuInputDelegate {
	var view;
    function initialize(v) {
    	view = v;
        Ui.MenuInputDelegate.initialize();
    }

    function onMenuItem(item) {
        var menu = new Ui.Menu();
        var delegate = null;

        if(item == :dismiss) {
        	/*
            menu.addItem("Hello World.", :hello);
            menu.addItem("Ackbar", :trap);
            menu.addItem("Garmin", :garmin);
            delegate = new SendMenuDelegate();
            */
            Sys.println("Dismiss current notification");
            view.dismiss();
        } else if(item == :setListener) {
            menu.setTitle("Listner Type");
            menu.addItem("Mailbox", :mailbox);
            if(Comm has :registerForPhoneAppMessages) {
                menu.addItem("Phone App", :phone);
            }
            menu.addItem("None", :none);
            menu.addItem("Crash if 'Hi'", :phoneFail);
            delegate = new ListnerMenuDelegate();
            Ui.pushView(menu, delegate, SLIDE_IMMEDIATE);
        }

        
    }
}

class SendMenuDelegate extends Ui.MenuInputDelegate {
    function initialize() {
        Ui.MenuInputDelegate.initialize();
    }

    function onMenuItem(item) {
        //var listener = new CommListener();

        if(item == :hello) {
            //Comm.transmit("Hello World.", null, listener);
            Sys.println("clicked");
        } else if(item == :trap) {
            //Comm.transmit("IT'S A TRAP!", null, listener);
        } else if(item == :garmin) {
            //Comm.transmit("ConnectIQ", null, listener);
        }

        Ui.popView(SLIDE_IMMEDIATE);
    }
}

class ListnerMenuDelegate extends Ui.MenuInputDelegate {
    function initialize() {
        Ui.MenuInputDelegate.initialize();
    }

    function onMenuItem(item) {
        if(item == :mailbox) {
            Comm.setMailboxListener(mailMethod);
        } else if(item == :phone) {
            if(Comm has :registerForPhoneAppMessages) {
                Comm.registerForPhoneAppMessages(phoneMethod);
            }
        } else if(item == :none) {
            Comm.registerForPhoneAppMessages(null);
            Comm.setMailboxListener(null);
        } else if(item == :phoneFail) {
            Comm.registerForPhoneAppMessages(phoneMethod);
        }

        Ui.popView(SLIDE_IMMEDIATE);
    }
}

