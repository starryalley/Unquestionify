
# Important Update

## 24/11/2023

Black Friday!

So I saw a great deal of a Garmin Epix gen 2 watch on crazy sale the other day. Looking at my Fenix 6 pro on my wrist, the most exciting feature I am expecting for a upgrade is the native ability to display multi-language, which the Fenix 7 and Epix series do. I have to resist the urge to upgrade because my F6pro is perfectly working every day. I just have to get this project back to live so I can still read some Mandarin Chinese messages on it.


Since Garmin has permanently used the cloud to handle the `makeImageRequest()` API call (see update below on 12/3/2021), I have to write a simple but stupid cache/relay server hosted in the cloud so Garmin's server can reach. Hence I built [unquestionify-relay](https://github.com/starryalley/unquestionify-relay) and deployed it so this app now works again. See the detail in [unquestionify-relay](https://github.com/starryalley/unquestionify-relay) project.


I am not going to release this on the [Garmin Connect IQ](https://apps.garmin.com/en-US/) since this is just a workaround and my hosted cloud service has a limited capacity. If you are building this on your own, replace the following line in `UnquestionifyWidgetView.mc` and fill in your domain for the deployed [unquestionify-relay](https://github.com/starryalley/unquestionify-relay) for this to work again. 

```
hidden const imageServer = "https://fill_in_the_relay_server_domain_here";
```

But Garmin's imaging processing server is acting weird. I can't host the [unquestionify-relay](https://github.com/starryalley/unquestionify-relay) on my own server running at my home using duckdns.org, even though it is publicly accessibly and perfectly valid. I've tried to use Google Cloud but using the east australia region (where I am) also didn't work. It seems that Garmin's server can't resolve or refuse to even connect to some domain. I have to use us-central as the region to finally get it to work. Just FYI.


## 12/3/2021

As of now (March 2021) Garmin Connect Mobile (GCM) version 4.4 has broken the functionality of this widget. See bug report [here](https://forums.garmin.com/developer/connect-iq/i/bug-reports/connect-mobile-4-40-makeimagerequest-localhost-error?CommentSortBy=CreatedDate&CommentSortOrder=Descending).

Currently there is no workaround available and Garmin hasn't made a decision yet if they gonna fix this. If they won't, unfortunately this project will be dead.


# Unquestionify

Unquestionify is a [Garmin Connect IQ](https://apps.garmin.com/en-US/) watch widget, which displays your phone's notifications (selectable from which apps) as a 1-bit monochrome image.

[Available on Garmin Connect IQ](https://apps.garmin.com/en-US/apps/d33523a2-3be6-4689-8f40-af7912063446)


This enables the user to read notifications in any language which is not possible on some garmin Connect IQ devices. For example, Chinese text is display as diamond question marks on Fenix 6 sold in countries other than Taiwan and China.

This project is the watch widget.

## Overview

This is the watch widget. You'll need a companion phone app for this to run correctly. Currently only supports Android.

See [Unquestionify Android Companion App](https://github.com/starryalley/Unquestionify-android)

## Functions

When the widget starts in devices which supports Glance (Fenix 6 series), it pulls the latest notification and display it as a single line text in glance view. In other devices the widget shows current notifications count pulled from phone. Once user enters the widget, it displays a scrollable notification overview consisting of just 1 line.

User can then select each notification and enter detail view, where full text is viewable there. In the menu user can then dismiss current notification or all notifications.

Various display preference is configurable on Android companion app.

## Status

Currently only tested on Fenix 6 Pro and Vivoactive 4s.
