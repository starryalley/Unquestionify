
# Important Update

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
