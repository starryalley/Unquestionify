# Unquestionify

Unquestionify is a [Garmin Connect IQ](https://apps.garmin.com/en-US/) watch app, which displays your phone's notifications (selectable from which apps) as a 1-bit monochrome image.

This enables the user to read notifications in any language which is not possible on some garmin Connect IQ devices. For example, Chinese text is display as diamond question marks on Fenix 6 sold in countries other than Taiwan and China.

This project is the watch app.

## Overview

This is the watch app. You'll need a companion phone app for this to run correctly. Currently only supports Android.

See [Unquestionify Android Companion App](https://github.com/starryalley/Unquestionify-android)

## Functions

When watchapp starts, it pulls current unread notifications from phone, and displays a scrollable notification overview consisting of just 1 line.

User can then select each notification and enter detail view, where full text is viewable there. Notification Dismisal is also supported.

Various display preference is configurable on Android companion app.

## Status

Currently only tested on Fenix 6 Pro and Vivoactive 4s.