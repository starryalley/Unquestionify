using Toybox.WatchUi as Ui;
using Toybox.Graphics as Gfx;
using Toybox.Communications as Comm;
using Toybox.System as Sys;

(:glance)
class UnquestionifyWidgetGlanceView extends Ui.GlanceView {

    function initialize() {
        GlanceView.initialize();
    }

    function onLayout(dc) {
        // nothing
    }

    function onUpdate(dc) {
        Sys.println("Glance onUpdate(): width:" + dc.getWidth() + " height:" + dc.getHeight());
        dc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_TRANSPARENT);
        dc.drawText(dc.getWidth()/2, dc.getHeight()/2, Gfx.FONT_SMALL,  "Unquestionify", Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER);
    }
}