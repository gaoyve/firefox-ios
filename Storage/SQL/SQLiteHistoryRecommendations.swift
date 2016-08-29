/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared
import XCGLogger
import Deferred

extension SQLiteHistory: HistoryRecommendations {
    
    public func getHighlights() -> Deferred<Maybe<Cursor<Site>>> {
        let limit = 19
        let microsecondsPerMinute: Timestamp = 60_000_000 // 1000 * 1000 * 60
        let thirtyMinutesAgo = NSDate.nowMicroseconds() - 30 * microsecondsPerMinute
        let bookmarkLimit = 1
        let historyLimit = limit - bookmarkLimit

        let recentHistory = [
           	"SELECT \(TableHistory).id AS historyID, url, title, guid, COALESCE(sum(1), 0) AS visitCount, max(\(TableVisits).date) AS visitDate",
            "FROM \(TableHistory)",
            "LEFT JOIN \(TableVisits) ON \(TableVisits).siteID = \(TableHistory).id",
            "WHERE title NOT NULL AND title != '' AND is_deleted = 0",
            "GROUP BY url",
            "ORDER BY visitDate DESC",
            "LIMIT \(historyLimit)"
        ].joinWithSeparator(" ")

        let recentHistoryWithIcons = [
            "SELECT historyID, url, title, guid, visitCount, visitDate, iconID, iconURL, iconDate, iconType, iconWidth",
            "FROM ( \(recentHistory) )",
            "LEFT JOIN \(ViewHistoryIDsWithWidestFavicons) ON \(ViewHistoryIDsWithWidestFavicons).id = historyID",
            "WHERE visitCount <= 3 AND visitDate < \(thirtyMinutesAgo)"
        ].joinWithSeparator(" ")

        return self.db.runQuery(recentHistoryWithIcons, args: nil, factory: SQLiteHistory.iconHistoryColumnFactory)
    }
}