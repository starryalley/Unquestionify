using Toybox.Application as App;
using Toybox.System as Sys;


(:glance)
class Unquestionify extends App.AppBase {

    hidden var view;

    function initialize() {
        App.AppBase.initialize();
        view = new UnquestionifyView();
    }

    function onStart(state) {
        view.requestSession();
    }

    function getInitialView() {
        var deviceSettings = Sys.getDeviceSettings();
        if (deviceSettings has :isGlanceModeEnabled && deviceSettings.isGlanceModeEnabled) {
            Sys.println("Has glance, go directly into main view");
            return [view, new UnquestionifyInputDelegate(view)];
        }
        return [new UnquestionifyWidgetSummaryView(view), new UnquestionifySummaryInputDelegate(view)];
    }

    function getGlanceView() {
        return [new UnquestionifyWidgetGlanceView(view)];
    }
}
