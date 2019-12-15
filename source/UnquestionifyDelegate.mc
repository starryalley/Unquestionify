using Toybox.WatchUi as Ui;
using Toybox.System as Sys;
using Toybox.Communications as Comm;

class UnquestionifyInputDelegate extends Ui.BehaviorDelegate {
    hidden var view;

    function initialize(v) {
        Ui.BehaviorDelegate.initialize();
        view = v;
    }

    function showDismissMenu() {
        var menu = new Ui.Menu();
        menu.addItem("Dismiss", :dismiss);
        menu.addItem("Dismiss All", :dismissAll);
        Ui.pushView(menu, new BaseMenuDelegate(view), SLIDE_IMMEDIATE);
    }

    function onMenu() {
        Sys.println("onMenu()");
        showDismissMenu();
        return true;
    }

    function onSelect() {
        Sys.println("onSelect()");
        if (!view.showDetail()) {
            showDismissMenu();
        }
        return true;
    }

    function onBack() {
        Sys.println("onBack()");
        return view.showOverview();
    }
    
    function onNextPage() {
        Sys.println("onNextPage()");
        view.next();
        return true;
    }
    
    function onPreviousPage() {
        Sys.println("onPreviousPage()");
        view.prev();
        return true;
    }
}

class BaseMenuDelegate extends Ui.MenuInputDelegate {
    hidden var view;
    function initialize(v) {
        view = v;
        Ui.MenuInputDelegate.initialize();
    }

    function onMenuItem(item) {
        if(item == :dismiss) {
            Sys.println("Dismiss current notification");
            view.dismiss();
        } else if (item == :dismissAll) {
            Sys.println("Dismiss all current notification");
            view.dismissAll();
        }
    }
}
