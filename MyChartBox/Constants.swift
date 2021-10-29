//
//  Constants.swift
//  MyChartBox
//
//  Created by Paul Willmott on 11/07/2020.
//  Copyright © 2020 Paul Willmott. All rights reserved.
//

import Foundation

enum TABLE {
  static let VERSION              = "VERSION"
  static let ARTIST               = "ARTIST"
  static let LABEL                = "LABEL"
  static let CHART                = "CHART"
  static let CHART_LISTING        = "CHART_LISTING"
  static let CHART_ENTRY          = "CHART_ENTRY"
  static let TRACK_OVERRIDE       = "TRACK_OVERRIDE"
  static let COLLECTION           = "COLLECTION"
  static let PLAY_COUNT           = "PLAY_COUNT"
  static let MUSIC_TRACK          = "MUSIC_TRACK"
  static let ALBUM_PLAY_COUNT     = "ALBUM_PLAY_COUNT"
}

enum VERSION {
  static let VERSION_ID           = "VERSION_ID"
  static let VERSION_NUMBER       = "VERSION_NUMBER"
}

enum ARTIST {
  static let ARTIST_ID            = "ARTIST_ID"
  static let UKCHART_NAME         = "UKCHART_NAME"
  static let ARTIST_NAME          = "ARTIST_NAME"
  static let SORT_NAME            = "SORT_NAME"
}

enum LABEL {
  static let LABEL_ID             = "LABEL_ID"
  static let UKCHART_NAME         = "UKCHART_NAME"
}

enum CHART {
  static let CHART_ID             = "CHART_ID"
  static let CHART_NAME           = "CHART_NAME"
  static let UKCHART_ID           = "UKCHART_ID"
}

enum CHART_LISTING {
  static let CHART_LISTING_ID     = "CHART_LISTING_ID"
  static let CHART_ID             = "CHART_ID"
  static let ARTIST_ID            = "ARTIST_ID"
  static let UKCHART_TITLE        = "UKCHART_TITLE"
  static let LABEL_ID             = "LABEL_ID"
  static let CATALOGUE_NUMBER     = "CATALOGUE_NUMBER"
  static let PRODUCT_TYPE         = "PRODUCT_TYPE"
}

enum CHART_ENTRY {
  static let CHART_ENTRY_ID       = "CHART_ENTRY_ID"
  static let CHART_DATE           = "CHART_DATE"
  static let CHART_LISTING_ID     = "CHART_LISTING_ID"
  static let POSITION             = "POSITION"
  static let LAST_POSITION        = "LAST_POSITION"
  static let HIGHEST_POSITION     = "HIGHEST_POSITION"
  static let WEEKS_ON_CHART       = "WEEKS_ON_CHART"
  static let CHART_ID             = "CHART_ID"
}

enum MUSIC_TRACK {
  static let MUSIC_PID            = "MUSIC_PID"
  static let VOLUME_ADJUSTMENT    = "VOLUME_ADJUSTMENT"
}

enum TRACK_OVERRIDE {
  static let TRACK_OVERRIDE_ID    = "TRACK_OVERRIDE_ID"
  static let CHART_LISTING_ID     = "CHART_LISTING_ID"
  static let SIDE_INDEX           = "SIDE_INDEX"
  static let ITUNES_TRACK_ID      = "ITUNES_TRACK_ID"
  static let NOT_THIS_TRACK       = "NOT_THIS_TRACK"
  static let MUSIC_PID            = "MUSIC_PID"
}

enum COLLECTION {
  static let COLLECTION_ID        = "COLLECTION_ID"
  static let COLLECTION_NAME      = "COLLECTION_NAME"
  static let SORT_NAME            = "SORT_NAME"
  static let LINKS                = "LINKS"
}

enum PLAY_COUNT {
  static let YEAR_NUMBER          = "YEAR_NUMBER"
  static let PLAY_COUNT           = "PLAY_COUNT"
  static let CHART_ID             = "CHART_ID"
}

enum ALBUM_PLAY_COUNT {
  static let ALBUM_ID             = "ALBUM_ID"
  static let PLAY_COUNT           = "PLAY_COUNT"
}

// Preferences' Keys

enum DEFAULT {
  static let VERSION              = "Version"
  static let DATABASE_PATH        = "DatabasePath"
  static let LIBRARY_PATH         = "LibraryPath"
  static let TOP_LIMIT            = "TopLimit"
  static let ANNOUNCER            = "Announcer"
  static let SHUFFLE              = "Shuffle"
  static let REPEAT               = "Repeat"
  static let SHUFFLE_FROM         = "ShuffleFrom"
  static let SHUFFLE_TO           = "ShuffleTo"
  static let ALBUM_SHUFFLE_FROM   = "AlbumShuffleFrom"
  static let ALBUM_SHUFFLE_TO     = "AlbumShuffleTo"
  static let MAX_RUNTIME          = "MaxRuntime"
  static let TARGET_TIME_HOUR     = "TargetTimeHour"
  static let TARGET_TIME_MINUTES  = "TargetTimeMinutes"
  static let BASE_INTERVAL        = "BaseInterval"
  static let VARIANCE             = "Variance"
  static let METHOD               = "Method"
  static let CHART                = "Chart"
  static let MAXLOADS             = "MaxLoads"
  static let MODE                 = "Mode"
  static let TOP_LIMIT_ALBUMS     = "TopLimitAlbums"
  static let SKIP_BONUS_TRACKS    = "SkipBonusTracks"
  static let SKIP_LIVE_TRACKS     = "SkipLiveTracks"
  static let SKIP_DEMO_TRACKS     = "SkipDemoTracks"
  static let SKIP_RECENTLY_PLAYED = "SkipRecentlyPlayed"
  static let ONLY_PLAY_CHRISTMAS_SONGS_IN_DECEMBER = "OnlyPlayChristmasSongsInDecember"
  static let SKIP_RE_ENTRIES      = "SkipReEntries"
}

extension StringProtocol {
    func index<S: StringProtocol>(of string: S, options: String.CompareOptions = []) -> Index? {
        range(of: string, options: options)?.lowerBound
    }
    func endIndex<S: StringProtocol>(of string: S, options: String.CompareOptions = []) -> Index? {
        range(of: string, options: options)?.upperBound
    }
    func indices<S: StringProtocol>(of string: S, options: String.CompareOptions = []) -> [Index] {
        var indices: [Index] = []
        var startIndex = self.startIndex
        while startIndex < endIndex,
            let range = self[startIndex...]
                .range(of: string, options: options) {
                indices.append(range.lowerBound)
                startIndex = range.lowerBound < range.upperBound ? range.upperBound :
                    index(range.lowerBound, offsetBy: 1, limitedBy: endIndex) ?? endIndex
        }
        return indices
    }
    func ranges<S: StringProtocol>(of string: S, options: String.CompareOptions = []) -> [Range<Index>] {
        var result: [Range<Index>] = []
        var startIndex = self.startIndex
        while startIndex < endIndex,
            let range = self[startIndex...]
                .range(of: string, options: options) {
                result.append(range)
                startIndex = range.lowerBound < range.upperBound ? range.upperBound :
                    index(range.lowerBound, offsetBy: 1, limitedBy: endIndex) ?? endIndex
        }
        return result
    }
}
