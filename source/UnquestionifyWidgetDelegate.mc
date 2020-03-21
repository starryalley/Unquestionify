using Toybox.WatchUi as Ui;
using Toybox.System as Sys;
using Toybox.Communications as Comm;

(:glance)
class UnquestionifyInputDelegate extends Ui.BehaviorDelegate {
    hidden var view;
    hidden var isVA4 = false;

    function initialize(v) {
        Ui.BehaviorDelegate.initialize();
        view = v;
        var dev = Sys.getDeviceSettings();
        if (dev.partNumber.equals("006-B3224-00") || dev.partNumber.equals("006-B3225-00")) {
            isVA4 = true;
            Sys.println("using VA4");
        }
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
            if (!isVA4) {
                showDismissMenu();
            } else {
                // workaround for VA4 FW bug: there is no onNextPage() and onPreviousPage() support
                if (!view.next()) {
                    view.showNextOverview();
                }
            }
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
